# Effets « anime » en 4 calques blancs (méthode du 25 nov., voir docs/Mecaniques.md) :
#   Glow (halo doux), Rim (silhouette extérieure), Mid (milieu), Core (cœur très clair).
# Chaque calque est une planche d'animation 4x4 (16 étapes, 1024 px, 256 px par étape), en blanc sur
# transparent : le jeu empile les 4 planches (une ParticleEmitter par calque, mêmes réglages) et colore
# chacune (Rim saturé, Mid plus clair, Core presque blanc, Glow saturé et transparent).
# Les effets en boucle bouclent parfaitement (étape 16 -> étape 1).
#
# Usage : python tools/fx/layered_fx.py <dossier de sortie> [nom ...]
#   -> <dossier>/<Nom>_<Calque>.png  +  <dossier>/_apercu_<Nom>.png (calques colorés empilés)
import math
import sys

import numpy as np
from PIL import Image

FRAME = 256  # pixels par étape dans la planche
SS = 2  # suréchantillonnage (bords nets mais lissés)
R = FRAME * SS
TAU = math.pi * 2
LAYERS = ("Glow", "Rim", "Mid", "Core")

# grille de coordonnées : x vers la droite, y vers le haut, de -1 à 1
_ax = (np.arange(R) + 0.5) / R * 2 - 1
X, Y = np.meshgrid(_ax, -_ax)
RAD = np.hypot(X, Y)
ANG = np.arctan2(Y, X)


# OUTILS -------------------------------------------------------------------------------------------


def ss(a, b, v):
    """smoothstep de a à b"""
    t = np.clip((v - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def blur(img, sigma):
    """flou gaussien par FFT (bords non bouclés : on rembourre)"""
    pad = int(sigma * 3)
    p = np.pad(img, pad)
    n0, n1 = p.shape
    f0 = np.fft.fftfreq(n0)[:, None]
    f1 = np.fft.fftfreq(n1)[None, :]
    k = np.exp(-2 * (math.pi * sigma) ** 2 * (f0**2 + f1**2))
    out = np.real(np.fft.ifft2(np.fft.fft2(p) * k))
    return out[pad:-pad, pad:-pad] if pad else out


def tile_noise(n, freq, seed, octaves=3):
    """bruit fractal qui se répète (périodique) sur n x n, valeurs 0..1"""
    rng = np.random.default_rng(seed)
    f0 = np.fft.fftfreq(n)[:, None] * n
    f1 = np.fft.fftfreq(n)[None, :] * n
    fr = np.hypot(f0, f1)
    total = np.zeros((n, n))
    amp = 1.0
    for o in range(octaves):
        c = freq * (2**o)
        spec = (rng.normal(size=(n, n)) + 1j * rng.normal(size=(n, n))) * np.exp(-((fr / c) ** 2))
        spec[0, 0] = 0
        layer = np.real(np.fft.ifft2(spec))
        layer /= np.abs(layer).max() + 1e-9
        total += layer * amp
        amp *= 0.5
    total -= total.min()
    return total / (total.max() + 1e-9)


def sample(tex, u, v):
    """lecture bilinéaire d'une texture périodique, u et v en tuiles (1 = une tuile)"""
    n = tex.shape[0]
    fu = (u % 1) * n
    fv = (v % 1) * n
    i0 = np.floor(fu).astype(int) % n
    j0 = np.floor(fv).astype(int) % n
    i1 = (i0 + 1) % n
    j1 = (j0 + 1) % n
    a = fu - np.floor(fu)
    b = fv - np.floor(fv)
    return (tex[j0, i0] * (1 - a) * (1 - b) + tex[j0, i1] * a * (1 - b) + tex[j1, i0] * (1 - a) * b + tex[j1, i1] * a * b)


def bands(d, rim=0.0, mid=0.3, core=0.62, soft=0.025, glow_sigma=0.05, glow_gain=1.0):
    """calques cel-shading à partir d'un champ de densité (plus c'est grand, plus c'est au cœur)"""
    r = ss(max(rim - soft, 1e-3), rim + soft, d)  # rien hors de la forme (d = 0)
    m = ss(mid - soft, mid + soft, d)
    c = ss(core - soft, core + soft, d)
    g = np.clip(blur(r, glow_sigma * R) * 1.6 * glow_gain, 0, 1)
    return {"Glow": g, "Rim": r, "Mid": m, "Core": c}


def seg_dist(px, py, ax, ay, bx, by):
    """distance de chaque pixel au segment AB"""
    dx, dy = bx - ax, by - ay
    L = dx * dx + dy * dy + 1e-12
    t = np.clip(((px - ax) * dx + (py - ay) * dy) / L, 0, 1)
    return np.hypot(px - (ax + t * dx), py - (ay + t * dy))


def star4(cx, cy, size, rot=0.0):
    """étoile à 4 branches (champ 0..1, 1 au centre)"""
    c, s = math.cos(rot), math.sin(rot)
    dx = (X - cx) * c + (Y - cy) * s
    dy = -(X - cx) * s + (Y - cy) * c
    v = np.sqrt(np.abs(dx) / size + 1e-9) + np.sqrt(np.abs(dy) / size + 1e-9)
    return np.clip(1 - v / 1.0, 0, 1)


def heart(cx, cy, size):
    x = (X - cx) / size
    y = (Y - cy) / size * 1.1 + 0.25
    v = (x * x + y * y - 1) ** 3 - x * x * y**3
    return np.clip(-v * 3, 0, 1) ** 0.5


# EFFETS -------------------------------------------------------------------------------------------
# chaque effet : fonction(t, i) -> dict de 4 calques (t de 0 à 1 sur la boucle, i = numéro d'étape)

NZ = 256
NOISE_A = tile_noise(NZ, 3, 11)
NOISE_B = tile_noise(NZ, 6, 23)
NOISE_C = tile_noise(NZ, 2, 37, octaves=2)


def fx_impact(t, i):
    """impact du forage : étoile de pointes + onde de choc + éclair central (une seule fois)"""
    rng = np.random.default_rng(5)
    n = 11
    angles = np.sort(rng.uniform(0, TAU, n))
    lengths = rng.uniform(0.55, 1.0, n)
    grow = 1 - (1 - min(1, t / 0.28)) ** 3  # les pointes jaillissent vite
    thin = max(0.0, 1 - max(0, t - 0.2) / 0.8)  # puis s'amincissent
    d = np.zeros_like(X)
    for a, L in zip(angles, lengths):
        L = L * (0.35 + 0.6 * grow)
        da = np.angle(np.exp(1j * (ANG - a)))
        w = 0.27 * thin * (1 - RAD / L)  # largeur angulaire qui se réduit vers la pointe
        sp = np.where(RAD < L, 1 - np.abs(da) / np.maximum(w, 1e-4), 0)
        d = np.maximum(d, np.clip(sp, 0, 1) * np.clip(1 - RAD / L, 0, 1) ** 0.3)
    # onde de choc : anneau qui s'élargit et s'amincit
    rr = 0.15 + 0.78 * (1 - (1 - t) ** 2.2)
    th = 0.09 * (1 - t) ** 1.3 + 0.005
    ring = np.clip(1 - np.abs(RAD - rr) / th, 0, 1) * (1 - t) ** 0.6
    d = np.maximum(d, ring * 0.85)
    # éclair central qui gonfle puis se résorbe
    br = 0.42 * math.sin(math.pi * min(1, t / 0.55)) if t < 0.55 else 0
    blob = np.clip(1 - RAD / max(br, 1e-4), 0, 1) if br > 0 else 0 * RAD
    d = np.maximum(d, blob ** 0.6)
    fade = 1 if t < 0.7 else max(0, 1 - (t - 0.7) / 0.3)
    return bands(d * (0.35 + 0.65 * fade), rim=0.05, mid=0.32, core=0.62, glow_sigma=0.045)


def _flame_field(t, width=0.7, wild=1.25):
    """champ de flamme qui monte (aura de combat) : enveloppe en goutte + bruit qui défile"""
    yy = (Y + 1) / 2  # 0 en bas, 1 en haut
    w = width * (1 - yy**1.4 * 0.8)  # large en bas, pointue en haut
    xs = X + (sample(NOISE_C, X * 0.6, Y * 0.6 - t) - 0.5) * 0.45 * yy * wild
    env = 1 - (np.abs(xs) / np.maximum(w, 0.04)) ** 2
    env = env - np.clip(0.16 - yy, 0, 1) * 7  # bas arrondi, loin du bord de l'étape
    n = sample(NOISE_C, X * 1.0, Y * 1.0 - t * 2) * 0.7 + sample(NOISE_A, X * 1.2, Y * 1.2 - t * 3) * 0.3
    # les langues de feu se détachent vers le haut
    return env * 0.9 + (n - 0.5) * (0.5 + yy * 1.7) * wild - yy * 0.32 - np.clip(yy - 0.85, 0, 1) * 5


def fx_flame(t, i):
    d = _flame_field(t)
    return bands(d, rim=0.0, mid=0.32, core=0.72, glow_sigma=0.04)


def fx_wisp(t, i):
    """fumée / esprit : volutes lentes et courbes, trouées"""
    yy = (Y + 1) / 2
    xs = X + np.sin(TAU * (yy * 1.2 - t)) * 0.12 * yy
    w = 0.55 * (1 - yy**1.3 * 0.55)
    env = 1 - (np.abs(xs) / np.maximum(w, 0.05)) ** 2
    env = env - np.clip(0.16 - yy, 0, 1) * 7 - np.clip(yy - 0.85, 0, 1) * 6
    n = sample(NOISE_C, X * 0.9 + 0.3 * np.sin(TAU * t), Y * 0.9 - t) * 0.6 + sample(NOISE_A, X * 1.4, Y * 1.4 - t * 2) * 0.4
    d = env + (n - 0.5) * 1.5 - yy * 0.7
    return bands(d, rim=0.0, mid=0.4, core=0.82, soft=0.05, glow_sigma=0.05)


def _bolt(rng, ax, ay, bx, by, depth=5, disp=0.18):
    pts = [(ax, ay), (bx, by)]
    for _ in range(depth):
        nxt = [pts[0]]
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            mx, my = (x0 + x1) / 2, (y0 + y1) / 2
            L = math.hypot(x1 - x0, y1 - y0)
            nx, ny = -(y1 - y0) / (L + 1e-9), (x1 - x0) / (L + 1e-9)
            o = rng.uniform(-1, 1) * disp * L
            nxt += [(mx + nx * o, my + ny * o), (x1, y1)]
        pts = nxt
    return pts


def fx_electric(t, i):
    """arcs électriques autour de la créature (nouveaux toutes les 2 étapes)"""
    rng = np.random.default_rng(100 + i // 2)
    dist = np.full_like(X, 9.0)
    for _ in range(4):
        a0 = rng.uniform(0, TAU)
        a1 = a0 + rng.uniform(0.6, 1.4) * rng.choice([-1, 1])
        r0, r1 = rng.uniform(0.5, 0.8), rng.uniform(0.55, 0.9)
        pts = _bolt(rng, r0 * math.cos(a0), r0 * math.sin(a0) * 1.1, r1 * math.cos(a1), r1 * math.sin(a1) * 1.1)
        # petite branche
        k = len(pts) // 2
        bx, by = pts[k]
        br = _bolt(rng, bx, by, bx * 1.25 + rng.uniform(-0.15, 0.15), by * 1.25 + rng.uniform(-0.15, 0.15), depth=3)
        for p in (pts, br):
            for (x0, y0), (x1, y1) in zip(p, p[1:]):
                dist = np.minimum(dist, seg_dist(X, Y, x0, y0, x1, y1))
    d = np.clip(1 - dist / 0.065, 0, 1)
    return bands(d, rim=0.02, mid=0.35, core=0.68, soft=0.04, glow_sigma=0.035, glow_gain=1.3)


def _rising(t, count, seed, shape, size_rng, sway=0.08, speed=1):
    """objets qui montent en boucle (bulles, spores, cœurs) : densité + reflets"""
    rng = np.random.default_rng(seed)
    d = np.zeros_like(X)
    hi = np.zeros_like(X)
    for k in range(count):
        x0 = rng.uniform(-0.7, 0.7)
        ph = rng.uniform(0, 1)
        s = rng.uniform(*size_rng)
        sp = speed * rng.choice([1, 1, 2])  # vitesse entière : boucle parfaite
        y = ((ph + t * sp) % 1) * 1.7 - 0.85
        x = x0 + math.sin(TAU * (t * sp + ph)) * sway
        life = math.sin(math.pi * ((ph + t * sp) % 1))  # grossit en bas, rétrécit en haut
        s = s * min(1.0, life * 1.8)  # nul aux deux bouts : jamais coupé par le bord de l'étape
        if shape == "bubble":
            r = np.hypot(X - x, Y - y)
            ringd = np.clip(1 - np.abs(r - s) / (s * 0.22), 0, 1)
            fill = np.clip(1 - r / s, 0, 1) * 0.28
            d = np.maximum(d, np.maximum(ringd, fill))
            hi = np.maximum(hi, np.clip(1 - np.hypot(X - x + s * 0.4, Y - y - s * 0.4) / (s * 0.28), 0, 1))
        elif shape == "heart":
            d = np.maximum(d, heart(x, y, s))
        else:  # spore : boule douce
            r = np.hypot(X - x, Y - y)
            d = np.maximum(d, np.clip(1 - r / s, 0, 1) ** 0.8)
    return d, hi


def fx_bubbles(t, i):
    d, hi = _rising(t, 14, 7, "bubble", (0.07, 0.15), sway=0.06)
    L = bands(d, rim=0.12, mid=0.55, core=0.95, glow_sigma=0.03)
    L["Core"] = np.maximum(L["Core"], ss(0.3, 0.4, hi))
    return L


def fx_spores(t, i):
    d, _ = _rising(t, 16, 9, "spore", (0.06, 0.12), sway=0.1)
    return bands(d, rim=0.05, mid=0.4, core=0.75, glow_sigma=0.04, glow_gain=1.4)


def fx_hearts(t, i):
    d, _ = _rising(t, 10, 13, "heart", (0.1, 0.17), sway=0.07)
    return bands(d, rim=0.05, mid=0.35, core=0.8, glow_sigma=0.035)


def fx_stardust(t, i):
    """étoiles qui tournent autour de la créature en laissant une traînée (une orbite inclinée)"""
    d = np.zeros_like(X)
    n = 5
    for k in range(n):
        tilt = (k - 2) * 0.22
        for back in range(9):  # traînée : étoiles de plus en plus petites derrière
            a = TAU * (t + k / n) - back * 0.09
            x = math.cos(a) * 0.72
            y = math.sin(a) * 0.22 + tilt + math.cos(a) * tilt * 0.4
            s = (0.22 if back == 0 else 0.075 * (1 - back / 9)) * (0.75 + 0.25 * math.sin(a))
            if back == 0:
                d = np.maximum(d, star4(x, y, s, rot=a * 0.5))
            else:
                d = np.maximum(d, np.clip(1 - np.hypot(X - x, Y - y) / s, 0, 1) * (0.75 - back * 0.06))
    return bands(d, rim=0.04, mid=0.35, core=0.62, glow_sigma=0.04, glow_gain=1.3)


def fx_glitch(t, i):
    """pavés et lignes de balayage qui sautent (changent toutes les 2 étapes)"""
    rng = np.random.default_rng(300 + i // 2)
    d = np.zeros_like(X)
    for _ in range(16):
        a = rng.uniform(0, TAU)
        r = rng.uniform(0.35, 0.85)
        cx, cy = math.cos(a) * r, math.sin(a) * r
        w, h = rng.uniform(0.04, 0.2), rng.uniform(0.03, 0.09)
        box = np.clip(np.minimum(w - np.abs(X - cx), h - np.abs(Y - cy)) / 0.015, 0, 1)
        d = np.maximum(d, box * rng.uniform(0.5, 1.0))
    for _ in range(3):  # lignes horizontales qui traversent
        y = rng.uniform(-0.8, 0.8)
        line = np.clip(1 - np.abs(Y - y) / 0.012, 0, 1) * (np.abs(X) < rng.uniform(0.5, 0.9))
        d = np.maximum(d, line * 0.7)
    return bands(d, rim=0.05, mid=0.55, core=0.9, soft=0.02, glow_sigma=0.03)


def fx_shards(t, i):
    """éclats de cristal qui tournent autour (orbite inclinée, ceux de derrière plus petits)"""
    d = np.zeros_like(X)
    n = 7
    for k in range(n):
        a = TAU * (t + k / n)
        x = math.cos(a) * 0.7
        y = math.sin(a) * 0.25 + 0.05 * math.sin(3 * a + k)
        depth = 0.65 + 0.35 * (-math.sin(a))  # devant = plus gros
        L, W = 0.3 * depth, 0.11 * depth
        rot = a * 2 + k
        c, s = math.cos(rot), math.sin(rot)
        dx = (X - x) * c + (Y - y) * s
        dy = -(X - x) * s + (Y - y) * c
        dia = 1 - (np.abs(dx) / W + np.abs(dy) / L)
        d = np.maximum(d, np.clip(dia * 1.6, 0, 1) * (0.55 + 0.45 * depth))
    return bands(d, rim=0.03, mid=0.32, core=0.7, glow_sigma=0.035)


# Au sol (posés à plat sous la créature) ---------------------------------------------------------


def fx_pulse(t, i):
    """ondes qui partent du centre (deux à la fois, décalées d'une demi-boucle)"""
    d = np.zeros_like(X)
    for off in (0, 0.5):
        p = (t + off) % 1
        r = 0.15 + p * 0.8
        th = 0.06 * (1 - p) + 0.012
        d = np.maximum(d, np.clip(1 - np.abs(RAD - r) / th, 0, 1) * (1 - p) ** 0.7)
    return bands(d, rim=0.06, mid=0.4, core=0.7, glow_sigma=0.03)


def fx_rune(t, i):
    """cercle magique : deux cercles, graduations et losanges qui tournent (symétrie 8 : boucle)"""
    sym = 8
    rot = TAU / sym * t
    a = ANG - rot
    d = np.zeros_like(X)
    d = np.maximum(d, np.clip(1 - np.abs(RAD - 0.88) / 0.025, 0, 1))
    d = np.maximum(d, np.clip(1 - np.abs(RAD - 0.7) / 0.018, 0, 1))
    tick = np.abs(np.angle(np.exp(1j * a * 32))) < 0.5
    d = np.maximum(d, ((RAD > 0.72) & (RAD < 0.8) & tick) * 0.9)
    # losanges sur l'anneau intérieur, tournant en sens inverse
    a2 = ANG + rot
    seg = np.angle(np.exp(1j * a2 * sym)) / sym  # angle local autour de chaque losange
    lx = seg * 0.79
    ly = RAD - 0.79
    dia = 1 - (np.abs(lx) / 0.06 + np.abs(ly) / 0.06)
    d = np.maximum(d, np.clip(dia * 3, 0, 1))
    # étoile intérieure (deux carrés)
    for k in range(2):
        rr = RAD * np.maximum(np.abs(np.cos(a + k * math.pi / 4)), np.abs(np.sin(a + k * math.pi / 4)))
        d = np.maximum(d, np.clip(1 - np.abs(rr - 0.45) / 0.015, 0, 1) * 0.8)
    pulse = 0.85 + 0.15 * math.sin(TAU * t)
    return bands(d * pulse, rim=0.05, mid=0.45, core=0.8, soft=0.03, glow_sigma=0.025)


def fx_gear(t, i):
    """engrenage qui tourne (12 dents : un douzième de tour par boucle)"""
    teeth = 12
    a = ANG - TAU / teeth * t
    tooth = (np.cos(a * teeth) > 0.1).astype(float)
    outer = 0.78 + 0.12 * tooth
    # épaisseur en dégradé : bord coloré, ligne claire au milieu de la couronne
    d = np.clip(np.minimum(outer - RAD, RAD - 0.6) / 0.07, 0, 1)
    # rayons
    sa = np.abs(np.angle(np.exp(1j * a * 6))) / 6 * RAD  # distance au rayon le plus proche
    d = np.maximum(d, np.clip((0.035 - sa) / 0.035, 0, 1) * ((RAD < 0.62) & (RAD > 0.18)) * 0.8)
    d = np.maximum(d, np.clip(1 - np.abs(RAD - 0.2) / 0.045, 0, 1))
    return bands(d, rim=0.05, mid=0.45, core=0.85, soft=0.03, glow_sigma=0.025)


# Éclosion d'œuf --------------------------------------------------------------------------------


def _triangle(cx, cy, size, rot):
    """éclat de coquille : triangle pointu (champ 0..1)"""
    d = np.full_like(X, 9.0)
    pts = [(math.cos(rot + k * TAU / 3) * size * (1.5 if k == 0 else 0.8), math.sin(rot + k * TAU / 3) * size * (1.5 if k == 0 else 0.8)) for k in range(3)]
    inside = np.ones_like(X, dtype=bool)
    for k in range(3):
        (x0, y0), (x1, y1) = pts[k], pts[(k + 1) % 3]
        cross = (x1 - x0) * (Y - cy - y0) - (y1 - y0) * (X - cx - x0)
        inside &= cross > 0
        d = np.minimum(d, seg_dist(X - cx, Y - cy, x0, y0, x1, y1))
    return np.where(inside, np.clip(d / (size * 0.35), 0, 1), 0)


def fx_hatch(t, i):
    """l'œuf éclate : boule de lumière au bord en nuage qui se creuse en anneau, grosses pointes, éclats
    de coquille qui volent (une seule fois)"""
    # boule en nuage qui enfle, puis se creuse depuis le centre et se disperse
    R = 0.2 + 0.62 * (1 - (1 - t) ** 2.5)
    n = sample(NOISE_C, ANG / TAU * 7, t * 0.6 + RAD * 0.3)
    rr = RAD / (R * (0.82 + n * 0.36))
    hole = R * 0.95 * ss(0.3, 1.0, t) ** 0.8
    puff = np.minimum((1 - rr) * 3, (RAD - hole) / (R * 0.22))
    d = np.clip(puff, 0, 1) * (1 - ss(0.7, 1.0, t) * 0.7)
    # grosses pointes (8) qui jaillissent puis s'effilent
    grow = 1 - (1 - min(1, t / 0.25)) ** 3
    thin = max(0.0, 1 - max(0, t - 0.1) / 0.35)  # disparues avant que la boule se creuse
    for k in range(8):
        a = TAU * k / 8 + 0.2
        L = (0.75 + 0.2 * (k % 2)) * (0.3 + 0.7 * grow)
        da = np.angle(np.exp(1j * (ANG - a)))
        w = 0.32 * thin * np.clip(1 - RAD / L, 0, 1)
        sp = np.where(RAD < L, 1 - np.abs(da) / np.maximum(w, 1e-4), 0)
        d = np.maximum(d, np.clip(sp, 0, 1) * np.clip(1 - RAD / L, 0, 1) ** 0.25 * thin)
    # cœur blanc du début
    if t < 0.3:
        d = np.maximum(d, np.clip(1 - RAD / (0.3 * math.sin(math.pi * t / 0.3) + 1e-4), 0, 1) ** 0.5)
    # éclats de coquille qui volent en tournant
    rng = np.random.default_rng(42)
    for k in range(9):
        a = TAU * k / 9 + rng.uniform(-0.2, 0.2)
        r = 0.15 + rng.uniform(0.55, 0.78) * (1 - (1 - t) ** 2)
        s = rng.uniform(0.07, 0.11) * (1 - 0.5 * t)
        d = np.maximum(d, _triangle(math.cos(a) * r, math.sin(a) * r, s, a + t * rng.uniform(4, 9)) * (1 - ss(0.8, 1, t)))
    return bands(d, rim=0.05, mid=0.33, core=0.66, glow_sigma=0.05)


def fx_hatch_ring(t, i):
    """onde de choc au sol (à plat) : anneau à bord dentelé qui s'élargit et se brise en morceaux"""
    r = 0.12 + 0.8 * (1 - (1 - t) ** 2.2)
    th = 0.09 * (1 - t) ** 0.8 + 0.01
    band = np.clip(1 - np.abs(RAD - r) / th, 0, 1)
    # dents vers l'extérieur
    spk = np.abs(np.cos(ANG * 9)) ** 3 * 0.14 * (1 - t)
    teeth = np.where(RAD > r, np.clip(1 - (RAD - r) / np.maximum(spk + th, 1e-4), 0, 1), 0)
    d = np.maximum(band, teeth * 0.8)
    # traînée douce à l'intérieur
    d = np.maximum(d, np.clip(1 - (r - RAD) / 0.25, 0, 1) * (RAD < r) * 0.3 * (1 - t))
    # se brise en morceaux à la fin
    breaks = sample(NOISE_C, ANG / TAU * 3, 0.37)
    d = d * ss(t * 0.9 - 0.05, t * 0.9 + 0.05, breaks + 0.15)
    return bands(d, rim=0.06, mid=0.4, core=0.72, glow_sigma=0.03)


def fx_converge(t, i):
    """énergie aspirée vers l'œuf : traits qui filent vers le centre (en boucle)"""
    rng = np.random.default_rng(77)
    d = np.zeros_like(X)
    for k in range(16):
        a = TAU * k / 16 + rng.uniform(-0.15, 0.15)
        ph = rng.uniform(0, 1)
        sp = int(rng.choice([1, 2]))
        p = (ph + t * sp) % 1
        head = 0.7 - 0.58 * p  # la queue reste dans l'étape (jamais coupée par son bord)
        L = 0.25 * (1 - 0.5 * p)
        ca, sa = math.cos(a), math.sin(a)
        # le trait s'amincit vers sa queue
        along = (X * ca + Y * sa - head) / L
        across = np.abs(-X * sa + Y * ca)
        w = 0.042 * np.clip(1 - along, 0, 1)
        line = np.clip(1 - across / np.maximum(w, 1e-4), 0, 1) * (along >= 0) * (along <= 1)
        vis = min(1.0, p / 0.12) * min(1.0, (1 - p) / 0.12)
        d = np.maximum(d, line * vis)
    # pas de point au centre : c'est l'œuf qui est au centre
    return bands(d, rim=0.05, mid=0.4, core=0.7, glow_sigma=0.03, glow_gain=1.3)


# Jetpack --------------------------------------------------------------------------------------


def fx_thrust(t, i):
    """flamme de tuyère (en boucle) : la tuyère est en haut de l'étape ; le jet sort étroit, gonfle,
    puis se termine en langues de feu qui vacillent ; le bruit défile vers le bas"""
    u = (0.88 - Y) / 1.76  # 0 à la tuyère, 1 en bas de l'étape
    uc = np.clip(u, 0, 1)
    w = 0.12 + 0.3 * np.sin(math.pi * np.clip(u / 0.95, 0, 1)) ** 0.8 * (1 - uc * 0.45)
    sway = (sample(NOISE_C, X * 0.5, Y * 0.5 + t * 2) - 0.5) * 0.25 * uc
    env = 1 - (np.abs(X + sway) / np.maximum(w, 0.04)) ** 2
    length = 0.8 + 0.06 * math.sin(TAU * t * 3) + 0.04 * math.sin(TAU * t * 5)  # la flamme vacille
    env = env - np.clip(u - length, 0, 1) * 7 - np.clip(-u, 0, 1) * 30
    n = sample(NOISE_C, X * 1.2, Y * 1.0 + t * 3) * 0.65 + sample(NOISE_A, X * 1.6, Y * 1.4 + t * 4) * 0.35
    d = env * 0.95 + (n - 0.5) * (0.25 + uc * 1.3) - uc * 0.3
    return bands(d, rim=0.0, mid=0.3, core=0.74, glow_sigma=0.04)


# Mutations rares ----------------------------------------------------------------------------------


def fx_gleam(t, i):
    """reflet de créature mutée (en boucle) : un trait de lumière en biais qui balaie la silhouette une fois
    par boucle, et des étoiles qui s'allument et s'éteignent tour à tour sur elle"""
    d = np.zeros_like(X)
    # trait de lumière : il traverse pendant le premier tiers de la boucle, dans une ellipse (le corps)
    body = (X / 0.72) ** 2 + ((Y + 0.05) / 0.85) ** 2 < 1
    p = t / 0.45
    if p < 1:
        pos = -1.3 + 2.6 * p
        diag = (X + Y) / math.sqrt(2)
        band = np.clip(1 - np.abs(diag - pos) / 0.16, 0, 1)
        thin = np.clip(1 - np.abs(diag - pos - 0.27) / 0.05, 0, 1) * 0.8  # second trait fin
        d = np.maximum(d, np.maximum(band, thin) * body * math.sin(math.pi * p) ** 0.5)
    # étoiles qui scintillent tour à tour (phases réparties sur la boucle)
    spots = [(-0.32, 0.42), (0.36, 0.18), (-0.1, -0.3), (0.28, -0.45), (0.05, 0.62), (-0.45, -0.05)]
    for k, (x, y) in enumerate(spots):
        ph = (t - k / len(spots)) % 1
        s = 0.34 * max(0.0, math.sin(math.pi * min(1.0, ph / 0.3))) if ph < 0.3 else 0.0
        if s > 0.004:
            d = np.maximum(d, star4(x, y, s, rot=0.4 * ph))
    return bands(d, rim=0.05, mid=0.35, core=0.65, glow_sigma=0.035, glow_gain=1.2)


# Achat dans la boutique -------------------------------------------------------------------------


def fx_celebrate(t, i):
    """achat : éclair, soleil de rayons (longs et courts) qui grandit en tournant, anneau qui s'élargit,
    étoiles qui jaillissent en scintillant (une seule fois)"""
    d = np.zeros_like(X)
    e = 1 - (1 - t) ** 2.2
    fade = 1 - ss(0.65, 1.0, t)
    rot = 0.6 * t
    for k in range(12):
        a = TAU * k / 12 + rot
        L = (0.97 if k % 2 == 0 else 0.68) * (0.35 + 0.65 * e)
        da = np.angle(np.exp(1j * (ANG - a)))
        w = 0.3 * np.clip(1 - RAD / L, 0, 1) ** 0.7 * (1 - 0.5 * t)  # larges pointes de soleil
        ray = np.where((RAD < L) & (RAD > 0.12 * e), 1 - np.abs(da) / np.maximum(w, 1e-4), 0)
        d = np.maximum(d, np.clip(ray, 0, 1) * np.clip(1 - RAD / L, 0, 1) ** 0.3 * fade)
    # anneau
    rr = 0.2 + 0.72 * e
    d = np.maximum(d, np.clip(1 - np.abs(RAD - rr) / (0.035 * (1 - t) + 0.006), 0, 1) * (1 - ss(0.5, 0.9, t)))
    # étoiles qui jaillissent et scintillent
    rng = np.random.default_rng(12)
    for k in range(9):
        a = TAU * k / 9 + rng.uniform(-0.2, 0.2) + 0.15
        r = 0.18 + rng.uniform(0.45, 0.7) * e
        tw = 0.75 + 0.25 * math.sin(TAU * (t * 3 + k * 0.37))
        s = rng.uniform(0.15, 0.23) * tw * min(1, t / 0.1) * (1 - ss(0.75, 1, t))
        if s > 0.004:
            d = np.maximum(d, star4(math.cos(a) * r, math.sin(a) * r, s, rot=0.3 * k))
    # éclair au centre
    if t < 0.35:
        d = np.maximum(d, np.clip(1 - RAD / (0.4 * math.sin(math.pi * t / 0.35) + 1e-4), 0, 1) ** 0.5)
    return bands(d, rim=0.05, mid=0.35, core=0.68, glow_sigma=0.04, glow_gain=1.2)


# Rugissement du monstre -------------------------------------------------------------------------


def fx_roar(t, i):
    """rugissement : trois ondes en dents de scie qui partent l'une après l'autre, lignes de vitesse
    et éclats au centre (une seule fois)"""
    d = np.zeros_like(X)
    for n, start in enumerate((0.0, 0.16, 0.32)):
        p = (t - start) / 0.68
        if p <= 0 or p >= 1:
            continue
        e = 1 - (1 - p) ** 2
        r = 0.12 + 0.78 * e
        teeth = 22 + n * 4
        saw = np.abs(((ANG / TAU * teeth + n * 0.3) % 1) - 0.5) * 2  # 0..1 en triangle
        rr = r + (saw - 0.5) * 0.07 * (1 - p * 0.5)
        th = 0.055 * (1 - p) ** 0.8 + 0.008
        d = np.maximum(d, np.clip(1 - np.abs(RAD - rr) / th, 0, 1) * (1 - ss(0.75, 1, p)))
    # lignes de vitesse qui partent du centre
    if t < 0.7:
        k = ss(0.0, 0.1, t) * (1 - ss(0.4, 0.7, t))
        rng = np.random.default_rng(55)
        for n in range(18):
            a = TAU * n / 18 + rng.uniform(-0.12, 0.12)
            L0 = 0.25 + 0.5 * t
            L1 = min(0.97, L0 + rng.uniform(0.15, 0.3))
            ca, sa = math.cos(a), math.sin(a)
            along = X * ca + Y * sa
            across = np.abs(-X * sa + Y * ca)
            s = (along - L0) / (L1 - L0)
            w = 0.02 * np.clip(1 - np.abs(s - 0.5) * 2, 0, 1)
            d = np.maximum(d, np.clip(1 - across / np.maximum(w, 1e-4), 0, 1) * (s >= 0) * (s <= 1) * k)
    # éclair au centre (la gueule)
    if t < 0.35:
        d = np.maximum(d, np.clip(1 - RAD / (0.28 * math.sin(math.pi * t / 0.35) + 1e-4), 0, 1) ** 0.5)
    return bands(d, rim=0.05, mid=0.35, core=0.7, glow_sigma=0.035)


# Bonus x2 XP ------------------------------------------------------------------------------------


def fx_powerup(t, i):
    """bonus attrapé : tourbillon à 3 bras qui s'ouvre en tournant, lignes de vitesse et étoiles qui
    jaillissent, éclair au centre (une seule fois)"""
    d = np.zeros_like(X)
    e = 1 - (1 - t) ** 2.5
    # tourbillon : bras en spirale dans une couronne qui s'élargit et se creuse
    r_out = 0.25 + 0.58 * e  # reste dans l'étape
    r_in = 0.75 * ss(0.2, 1.0, t) * r_out
    rot = TAU * 0.45 * e
    arm = np.cos(3 * (ANG + RAD * 4.2 - rot))
    ring = ss(r_in - 0.02, r_in + 0.06, RAD) * (1 - ss(r_out - 0.08, r_out, RAD))
    d = np.maximum(d, np.clip((arm - 0.35) / 0.4, 0, 1) * ring * (1 - ss(0.7, 1, t)))
    # lignes de vitesse
    if t > 0.1:
        k = ss(0.1, 0.25, t) * (1 - ss(0.6, 0.95, t))
        a0 = 0.62 + 0.25 * e
        rng = np.random.default_rng(31)
        for n in range(14):
            a = TAU * n / 14 + rng.uniform(-0.1, 0.1)
            L0 = a0 * rng.uniform(0.85, 1.0)
            L1 = min(0.97, L0 + 0.22 * (1 - t))
            ca, sa = math.cos(a), math.sin(a)
            along = X * ca + Y * sa
            across = np.abs(-X * sa + Y * ca)
            s = (along - L0) / max(L1 - L0, 1e-3)
            w = 0.022 * np.clip(1 - s, 0, 1)
            d = np.maximum(d, np.clip(1 - across / np.maximum(w, 1e-4), 0, 1) * (s >= 0) * (s <= 1) * k)
    # étoiles qui jaillissent
    for n in range(6):
        a = TAU * n / 6 + 0.3
        r = 0.15 + 0.62 * e
        s = 0.26 * (1 - ss(0.55, 1, t)) * min(1, t / 0.12)
        if s > 0.005:
            d = np.maximum(d, star4(math.cos(a) * r, math.sin(a) * r, s, rot=t * 3))
    # éclair au centre
    if t < 0.3:
        d = np.maximum(d, np.clip(1 - RAD / (0.35 * math.sin(math.pi * t / 0.3) + 1e-4), 0, 1) ** 0.5)
    return bands(d, rim=0.05, mid=0.35, core=0.66, glow_sigma=0.04, glow_gain=1.2)


# Morsure du monstre -----------------------------------------------------------------------------


def _poly_any(cx, cy, pts):
    """polygone convexe dans n'importe quel sens de rotation : champ 0..1, 1 au centre"""
    pos = np.ones_like(X, dtype=bool)
    neg = np.ones_like(X, dtype=bool)
    dist = np.full_like(X, 9.0)
    n = len(pts)
    for k in range(n):
        (x0, y0), (x1, y1) = pts[k], pts[(k + 1) % n]
        cross = (x1 - x0) * (Y - cy - y0) - (y1 - y0) * (X - cx - x0)
        pos &= cross > 0
        neg &= cross < 0
        dist = np.minimum(dist, seg_dist(X - cx, Y - cy, x0, y0, x1, y1))
    size = max(math.hypot(x, y) for x, y in pts)
    return np.where(pos | neg, np.clip(dist / (size * 0.4), 0, 1), 0)


def fx_bite(t, i):
    """morsure : deux rangées de crocs qui se referment, éclair au contact, puis trois entailles
    d'énergie qui s'ouvrent et s'effacent (une seule fois ; pas de sang : c'est pour les enfants)"""
    d = np.zeros_like(X)
    close = min(1.0, t / 0.3) ** 2  # les mâchoires claquent vite
    gone = 1 - ss(0.38, 0.5, t)
    if gone > 0:
        for top in (True, False):
            sgn = 1 if top else -1
            base = sgn * (0.72 - 0.62 * close)  # mâchoire entière dans l'étape dès le début
            for k in range(7):
                x = -0.72 + k * 0.24
                y = base + sgn * 0.1 * (x / 0.72) ** 2  # arc en sourire
                L = 0.32 if k in (1, 5) else 0.24  # deux crocs plus longs
                w = 0.11
                pts = [(x - w, y), (x + w, y), (x, y - sgn * L)]
                d = np.maximum(d, _poly_any(0, 0, pts) * gone)
            # gencive : bande le long de l'arc
            gum_y = base + sgn * 0.1 * (X / 0.72) ** 2 + sgn * 0.05
            band = np.clip(1 - np.abs(Y - gum_y) / 0.06, 0, 1) * (np.abs(X) < 0.85)
            d = np.maximum(d, band * 0.55 * gone)
    # éclair au contact
    if 0.25 < t < 0.6:
        k = math.sin(math.pi * (t - 0.25) / 0.35)
        d = np.maximum(d, np.clip(1 - RAD / (0.45 * k + 1e-4), 0, 1) ** 0.5)
        for a in range(8):
            ang = TAU * a / 8 + 0.4
            da = np.angle(np.exp(1j * (ANG - ang)))
            Lr = 0.9 * k
            sp = np.where(RAD < Lr, 1 - np.abs(da) / np.maximum(0.2 * np.clip(1 - RAD / max(Lr, 1e-4), 0, 1), 1e-4), 0)
            d = np.maximum(d, np.clip(sp, 0, 1) * k)
    # trois entailles en biais qui s'ouvrent puis s'amincissent
    if t > 0.35:
        reveal = min(1.0, (t - 0.35) / 0.15)
        thin = 1 - ss(0.6, 1.0, t)
        ca, sa = math.cos(math.radians(-35)), math.sin(math.radians(-35))
        for k in (-1, 0, 1):
            ox, oy = -sa * k * 0.28, ca * k * 0.28
            ax = (X - ox) * ca + (Y - oy) * sa
            ay = -(X - ox) * sa + (Y - oy) * ca
            Lh = 0.62 - abs(k) * 0.1
            s = (ax + Lh) / (2 * Lh)
            yc = 0.1 * (ax / Lh) ** 2
            wth = 0.075 * np.sin(math.pi * np.clip(s, 0, 1)) * thin + 1e-4
            cut = np.clip(1 - np.abs(ay - yc) / wth, 0, 1) * (s >= 0) * (s <= reveal)
            d = np.maximum(d, cut)
    return bands(d, rim=0.05, mid=0.35, core=0.68, glow_sigma=0.045)


# Roche qui casse --------------------------------------------------------------------------------


def _polygon(cx, cy, pts):
    """polygone convexe (points autour de cx, cy) : champ 0..1, 1 au centre"""
    inside = np.ones_like(X, dtype=bool)
    dist = np.full_like(X, 9.0)
    n = len(pts)
    for k in range(n):
        (x0, y0), (x1, y1) = pts[k], pts[(k + 1) % n]
        cross = (x1 - x0) * (Y - cy - y0) - (y1 - y0) * (X - cx - x0)
        inside &= cross > 0
        dist = np.minimum(dist, seg_dist(X - cx, Y - cy, x0, y0, x1, y1))
    size = max(math.hypot(x, y) for x, y in pts)
    return np.where(inside, np.clip(dist / (size * 0.45), 0, 1), 0)


def fx_shatter(t, i):
    """la roche cède : éclair central, fissures en zigzag qui partent du centre, puis éclats anguleux
    qui volent en tournant et rapetissent (une seule fois)"""
    rng = np.random.default_rng(21)
    d = np.zeros_like(X)
    # éclair central (court)
    if t < 0.35:
        r = 0.42 * math.sin(math.pi * min(1, t / 0.35))
        d = np.maximum(d, np.clip(1 - RAD / max(r, 1e-4), 0, 1) ** 0.5)
    # fissures en zigzag (les premières étapes)
    if t < 0.45:
        grow = 1 - (1 - min(1, t / 0.2)) ** 2
        fade = 1 - max(0, t - 0.2) / 0.25
        dist = np.full_like(X, 9.0)
        for k in range(7):
            a = TAU * k / 7 + rng.uniform(-0.3, 0.3)
            L = rng.uniform(0.55, 0.9) * grow
            pts = _bolt(rng, 0, 0, math.cos(a) * L, math.sin(a) * L, depth=4, disp=0.25)
            for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
                dist = np.minimum(dist, seg_dist(X, Y, x0, y0, x1, y1))
        d = np.maximum(d, np.clip(1 - dist / (0.05 * fade + 0.005), 0, 1) * fade)
    else:
        for k in range(7):  # garde le hasard identique d'une étape à l'autre
            rng.uniform(size=1)
    # éclats anguleux qui volent
    rng2 = np.random.default_rng(8)
    fly = 1 - (1 - t) ** 2
    for k in range(11):
        a = TAU * k / 11 + rng2.uniform(-0.25, 0.25)
        r = 0.08 + rng2.uniform(0.45, 0.7) * fly
        s = rng2.uniform(0.12, 0.19) * (1 - 0.55 * t)
        rot = rng2.uniform(0, TAU) + t * rng2.uniform(-7, 7)
        nv = rng2.integers(3, 6)
        pts = []
        for v in range(nv):
            av = rot + TAU * v / nv + rng2.uniform(-0.3, 0.3)
            rv = s * rng2.uniform(0.6, 1.2)
            pts.append((math.cos(av) * rv, math.sin(av) * rv))
        appear = ss(0.05, 0.15, t)
        d = np.maximum(d, _polygon(math.cos(a) * r, math.sin(a) * r, pts) * appear * (1 - ss(0.85, 1, t)))
    return bands(d, rim=0.05, mid=0.35, core=0.68, glow_sigma=0.04)


def fx_dust(t, i):
    """nuage de poussière façon dessin animé : boules qui s'écartent, ombrées (reflet en haut à gauche),
    rongées par le bruit jusqu'à disparaître (une seule fois). Calques : Rim = silhouette, Mid = partie
    éclairée, Core = reflet, Glow = ombre douce autour"""
    rng = np.random.default_rng(3)
    sil = np.zeros_like(X)
    lit = np.zeros_like(X)
    hi = np.zeros_like(X)
    spread = 1 - (1 - t) ** 2.4
    for k in range(13):
        a = TAU * k / 13 + rng.uniform(-0.2, 0.2)
        r0 = rng.uniform(0.05, 0.2)
        rr = r0 + rng.uniform(0.35, 0.58) * spread
        cx, cy = math.cos(a) * rr, math.sin(a) * rr * 0.8
        s = rng.uniform(0.13, 0.22) * (0.55 + 0.7 * spread)
        sil = np.maximum(sil, 1 - np.hypot(X - cx, Y - cy) / s)
        lit = np.maximum(lit, 1 - np.hypot(X - cx + s * 0.2, Y - cy - s * 0.2) / (s * 0.78))
        hi = np.maximum(hi, 1 - np.hypot(X - cx + s * 0.38, Y - cy - s * 0.38) / (s * 0.3))
    # rongé par le bruit : les boules se trouent puis s'effacent
    n = sample(NOISE_C, X * 0.9, Y * 0.9) * 0.7 + sample(NOISE_A, X * 1.1, Y * 1.1) * 0.3
    eat = ss(0.25, 1.0, t)
    alive = ss(eat - 0.05, eat + 0.05, n * 0.9 + 0.1)
    soft = 0.03
    rim = ss(0, soft, sil) * alive
    mid = ss(0, soft, lit) * rim
    core = ss(0, soft, hi) * rim * (1 - ss(0.5, 0.8, t))
    glow = np.clip(blur(rim, 0.04 * R) * 1.2, 0, 1) * 0.8
    return {"Glow": glow, "Rim": rim, "Mid": mid, "Core": core}


EFFECTS = {
    "Impact": fx_impact,
    "Flame": fx_flame,
    "Wisp": fx_wisp,
    "Electric": fx_electric,
    "Bubbles": fx_bubbles,
    "Spores": fx_spores,
    "Hearts": fx_hearts,
    "Stardust": fx_stardust,
    "Glitch": fx_glitch,
    "Shards": fx_shards,
    "Pulse": fx_pulse,
    "Rune": fx_rune,
    "Gear": fx_gear,
    "Hatch": fx_hatch,
    "HatchRing": fx_hatch_ring,
    "Converge": fx_converge,
    "Shatter": fx_shatter,
    "Dust": fx_dust,
    "Thrust": fx_thrust,
    "Bite": fx_bite,
    "PowerUp": fx_powerup,
    "Roar": fx_roar,
    "Celebrate": fx_celebrate,
    "Gleam": fx_gleam,
}

# couleurs de l'aperçu (Rim, Mid) — en jeu ce sont celles de chaque créature
PREVIEW = {
    "Impact": ((255, 150, 40), (255, 230, 120)),
    "Flame": ((255, 70, 20), (255, 190, 60)),
    "Wisp": ((90, 220, 210), (190, 255, 245)),
    "Electric": ((150, 90, 255), (120, 220, 255)),
    "Bubbles": ((40, 170, 230), (150, 235, 255)),
    "Spores": ((60, 200, 120), (190, 255, 150)),
    "Hearts": ((255, 80, 160), (255, 180, 220)),
    "Stardust": ((255, 180, 40), (255, 240, 150)),
    "Glitch": ((255, 40, 220), (60, 255, 255)),
    "Shards": ((60, 150, 255), (170, 230, 255)),
    "Pulse": ((255, 196, 40), (255, 240, 160)),
    "Rune": ((40, 200, 140), (255, 220, 100)),
    "Gear": ((200, 130, 40), (255, 210, 120)),
    "Hatch": ((255, 196, 40), (255, 240, 170)),
    "Shatter": ((255, 120, 40), (255, 220, 150)),
    "Dust": ((120, 105, 100), (190, 175, 165)),
    "Thrust": ((255, 90, 20), (255, 200, 70)),
    "Bite": ((200, 40, 255), (255, 170, 240)),
    "PowerUp": ((170, 70, 255), (235, 190, 255)),
    "Roar": ((255, 70, 40), (255, 190, 150)),
    "Celebrate": ((255, 170, 20), (255, 240, 140)),
    "Gleam": ((255, 180, 30), (255, 245, 180)),
    "HatchRing": ((170, 90, 255), (225, 200, 255)),
    "Converge": ((255, 70, 160), (255, 200, 230)),
}


def render(name, fn, out):
    sheets = {k: np.zeros((FRAME * 4, FRAME * 4)) for k in LAYERS}
    for i in range(16):
        t = i / 16
        L = fn(t, i)
        for k in LAYERS:
            a = L[k].reshape(FRAME, SS, FRAME, SS).mean(axis=(1, 3))  # réduction lissée
            r, c = divmod(i, 4)
            sheets[k][r * FRAME:(r + 1) * FRAME, c * FRAME:(c + 1) * FRAME] = a
    for k in LAYERS:
        a = (np.clip(sheets[k], 0, 1) * 255).astype(np.uint8)
        img = np.dstack([np.full_like(a, 255)] * 3 + [a])
        Image.fromarray(img, "RGBA").save(f"{out}/{name}_{k}.png", optimize=True)
    # aperçu : calques colorés empilés sur fond sombre
    rim, mid = PREVIEW.get(name, ((255, 255, 255), (255, 255, 255)))
    cols = {"Glow": (rim, 0.55), "Rim": (rim, 1.0), "Mid": (mid, 1.0), "Core": ((255, 255, 250), 1.0)}
    bg = np.zeros((FRAME * 4, FRAME * 4, 3)) + np.array([22, 20, 34]) / 255
    for k in LAYERS:
        col, op = cols[k]
        a = np.clip(sheets[k], 0, 1)[..., None] * op
        bg = bg * (1 - a) + np.array(col)[None, None, :] / 255 * a
    Image.fromarray((bg * 255).astype(np.uint8), "RGB").save(f"{out}/_apercu_{name}.png")


if __name__ == "__main__":
    out = sys.argv[1]
    names = sys.argv[2:] or list(EFFECTS)
    for n in names:
        render(n, EFFECTS[n], out)
        print(n, "ok")
