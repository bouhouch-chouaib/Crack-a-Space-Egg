# Skybox de l'espace avec la planète géante, calculée direction par direction : aucun raccord
# entre les 6 faces, même quand la planète ou son halo passent d'une face à l'autre.
# Usage : python render_sky.py <dossier_sortie> [taille]   (taille par défaut 1024)
#
# Orientation des faces (mesurée dans Roblox, vue de l'intérieur, image à l'endroit) :
#   Ft = -Z, Bk = +Z, Lf = +X, Rt = -X, Up = +Y, Dn = -Y
#   u = gauche -> droite, v = haut -> bas, dans [-1, 1]
#   Ft (u, -v, -1)   Lf (1, -v, u)   Bk (-u, -v, 1)   Rt (-1, -v, -u)
#   Up (-v, 1, -u)   Dn (v, -1, -u)
# La planète est vers -Z (derrière le vaisseau, au centre des anneaux), un peu sous l'horizon.

import os
import sys

import numpy as np
from PIL import Image

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
N = int(sys.argv[2]) if len(sys.argv) > 2 else 1024

FACES = {
    "ft": lambda u, v: (u, -v, -np.ones_like(u)),
    "bk": lambda u, v: (-u, -v, np.ones_like(u)),
    "lf": lambda u, v: (np.ones_like(u), -v, u),
    "rt": lambda u, v: (-np.ones_like(u), -v, -u),
    "up": lambda u, v: (-v, np.ones_like(u), -u),
    "dn": lambda u, v: (v, -np.ones_like(u), -u),
}


def norm(v):
    v = np.asarray(v, dtype=np.float64)
    return v / np.linalg.norm(v)


def rgb(r, g, b):
    return np.array([r, g, b], dtype=np.float64) / 255.0


# BRUIT 3D (valeur, lissé) --------------------------------------------------------------------
rng = np.random.default_rng(7)
PERM = rng.permutation(256)
PERM = np.concatenate([PERM, PERM])
VALS = rng.random(256)


def vnoise(p):
    """p : (..., 3). Bruit de valeur 3D dans [0, 1]."""
    pi = np.floor(p).astype(np.int64)
    pf = p - pi
    w = pf * pf * (3 - 2 * pf)
    xi, yi, zi = (pi[..., 0] & 255), (pi[..., 1] & 255), (pi[..., 2] & 255)

    def h(dx, dy, dz):
        return VALS[PERM[PERM[PERM[xi + dx] + yi + dy] + zi + dz] & 255]

    x0 = h(0, 0, 0) * (1 - w[..., 0]) + h(1, 0, 0) * w[..., 0]
    x1 = h(0, 1, 0) * (1 - w[..., 0]) + h(1, 1, 0) * w[..., 0]
    x2 = h(0, 0, 1) * (1 - w[..., 0]) + h(1, 0, 1) * w[..., 0]
    x3 = h(0, 1, 1) * (1 - w[..., 0]) + h(1, 1, 1) * w[..., 0]
    y0 = x0 * (1 - w[..., 1]) + x1 * w[..., 1]
    y1 = x2 * (1 - w[..., 1]) + x3 * w[..., 1]
    return y0 * (1 - w[..., 2]) + y1 * w[..., 2]


def fbm(p, octaves=5, lac=2.03, gain=0.5):
    s, a, tot = 0.0, 1.0, 0.0
    for i in range(octaves):
        s = s + a * vnoise(p * (lac ** i) + i * 17.31)
        tot += a
        a *= gain
    return s / tot


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def ramp(x, stops):
    """x : (...), stops : [(pos, couleur)] -> (..., 3)"""
    pos = np.array([s[0] for s in stops])
    cols = np.array([s[1] for s in stops])
    out = np.empty(x.shape + (3,))
    for c in range(3):
        out[..., c] = np.interp(x, pos, cols[:, c])
    return out


# RÉGLAGES -----------------------------------------------------------------------------------
PLANET_DIR = norm([0.0, -0.14, -1.0])  # vers -Z, un peu sous l'horizon
PLANET_ANG = np.radians(38)  # rayon apparent : 72° de diamètre, elle domine tout l'arrière
LIGHT = norm([-0.85, 0.42, 0.32])  # lumière d'en haut à gauche : un croissant de nuit à droite
TILT = np.radians(-9)  # axe de la planète légèrement penché (bandes en biais, plus dynamique)
HALO_W = np.radians(7)  # largeur du halo d'atmosphère

BANDS = [  # couleurs des bandes, du pôle sud au pôle nord
    (-1.00, rgb(70, 44, 120)),
    (-0.78, rgb(118, 70, 170)),
    (-0.60, rgb(236, 128, 120)),
    (-0.45, rgb(255, 196, 140)),
    (-0.30, rgb(250, 150, 96)),
    (-0.16, rgb(255, 226, 180)),
    (-0.02, rgb(232, 112, 92)),
    (0.10, rgb(255, 214, 160)),
    (0.24, rgb(246, 150, 110)),
    (0.38, rgb(255, 232, 196)),
    (0.52, rgb(214, 110, 140)),
    (0.68, rgb(150, 86, 182)),
    (0.84, rgb(96, 60, 150)),
    (1.00, rgb(70, 44, 120)),
]
NIGHT = rgb(46, 22, 78)  # côté nuit : violet profond, jamais noir
RIM = rgb(120, 235, 255)  # liseré d'atmosphère côté jour
RIM2 = rgb(255, 120, 220)  # vers le côté nuit
STORM = (np.radians(9), np.radians(-20), np.radians(9))  # latitude, longitude, rayon du cyclone

MOONS = [  # direction, rayon apparent, couleur claire, couleur sombre
    (norm([-0.72, 0.30, -0.62]), np.radians(3.2), rgb(200, 236, 255), rgb(60, 70, 120)),
    (norm([0.66, 0.42, -0.62]), np.radians(1.7), rgb(255, 220, 170), rgb(90, 60, 80)),
]


def planet_frame():
    """Repère de la planète : axe nord penché, vue depuis l'origine."""
    up = np.array([0.0, 1.0, 0.0])
    fwd = PLANET_DIR
    right = np.cross(fwd, up)
    right /= np.linalg.norm(right)
    north = np.cross(right, fwd)
    # penche l'axe autour de la ligne de visée
    n2 = north * np.cos(TILT) + right * np.sin(TILT)
    r2 = np.cross(fwd, n2)
    return r2 / np.linalg.norm(r2), n2


RIGHT, NORTH = planet_frame()


def sphere_hit(d, center, ang):
    """Rayons d (..., 3) depuis l'origine vers une sphère vue sous le rayon apparent ang.
    Renvoie (masque, normale, angle au centre)."""
    R = np.sin(ang)  # sphère à distance 1
    b = d @ center
    disc = b * b - (1 - R * R)
    hit = (disc > 0) & (b > 0)
    t = b - np.sqrt(np.maximum(disc, 0))
    p = d * t[..., None]
    n = (p - center) / R
    gamma = np.arccos(np.clip(b, -1, 1))
    return hit, n, gamma


def render(d):
    """d : (H, W, 3) directions unitaires -> image (H, W, 3) dans [0, 1]."""
    # --- ciel : nébuleuses + étoiles ---
    neb1 = fbm(d * 1.6 + 3.0, 6)
    neb2 = fbm(d * 2.6 + 11.0, 6)
    neb3 = fbm(d * 5.0 + 23.0, 4)
    base = rgb(10, 6, 24)
    col = np.broadcast_to(base, d.shape).copy()
    pink = smoothstep(0.52, 0.78, neb1)[..., None] * rgb(150, 40, 120)
    blue = smoothstep(0.55, 0.80, neb2)[..., None] * rgb(30, 70, 170)
    violet = smoothstep(0.45, 0.75, neb1 * 0.5 + neb3 * 0.5)[..., None] * rgb(70, 30, 120)
    col += (pink + blue + violet) * 0.75
    # nébuleuse plus dense autour de la planète (elle « baigne » dans une lueur)
    around = np.clip(d @ PLANET_DIR, 0, 1) ** 6
    col += around[..., None] * rgb(90, 40, 110) * 0.55
    # étoiles : points fins + quelques grosses étoiles avec halo
    s = vnoise(d * N * 0.9)
    stars = smoothstep(0.975, 1.0, s) * 1.6
    s2 = vnoise(d * N * 0.22 + 41.0)
    big = smoothstep(0.988, 1.0, s2) * 2.4
    tint = ramp(vnoise(d * 40.0 + 5.0), [(0, rgb(170, 200, 255)), (0.5, rgb(255, 255, 255)), (1, rgb(255, 220, 190))])
    col += (stars + big)[..., None] * tint

    # --- halo d'atmosphère autour de la planète ---
    hit, n, gamma = sphere_hit(d, PLANET_DIR, PLANET_ANG)
    outside = gamma - PLANET_ANG
    halo = np.exp(-np.clip(outside, 0, None) / (HALO_W * 0.35)) * (outside > 0)
    halo_wide = np.exp(-np.clip(outside, 0, None) / (HALO_W * 1.6)) * (outside > 0)
    # le halo est plus fort du côté éclairé
    side = (d - PLANET_DIR * (d @ PLANET_DIR)[..., None])
    side_n = side / np.maximum(np.linalg.norm(side, axis=-1, keepdims=True), 1e-9)
    lit_side = np.clip(side_n @ LIGHT * 0.5 + 0.6, 0.15, 1.0)
    hcol = RIM * lit_side[..., None] + RIM2 * (1 - lit_side[..., None])
    col += (halo * 1.1 + halo_wide * 0.35)[..., None] * hcol * lit_side[..., None]

    # --- planète ---
    if hit.any():
        nn = n[hit]
        lat = np.arcsin(np.clip(nn @ NORTH, -1, 1))
        lon = np.arctan2(nn @ RIGHT, -(nn @ PLANET_DIR))
        # cyclone : tourbillon qui tord les coordonnées autour de son centre
        slat, slon, srad = STORM
        dl = lat - slat
        dn = (lon - slon) * np.cos(slat)
        rr = np.sqrt(dl * dl + (dn * 0.62) ** 2) / srad
        swirl = np.exp(-rr * rr * 1.3) * 4.5
        ca, sa = np.cos(swirl), np.sin(swirl)
        dl2 = dl * ca - dn * sa
        dn2 = dl * sa + dn * ca
        lat_w = slat + dl2
        # bandes, déformées par de la turbulence étirée dans le sens des longitudes
        q = np.stack([lon * 2.2, lat * 9.0, np.zeros_like(lat)], -1)
        turb = fbm(q + 7.0, 5) - 0.5
        fine = fbm(np.stack([lon * 7.0, lat * 34.0, np.ones_like(lat)], -1), 4) - 0.5
        y = np.sin(lat_w) + turb * 0.16 + fine * 0.05
        surf = ramp(np.clip(y, -1, 1), BANDS)
        # stylisé : léger aplat des bandes (cartoon) mélangé au dégradé
        steps = np.round(np.clip(y, -1, 1) * 11) / 11
        surf = surf * 0.55 + ramp(steps, BANDS) * 0.45
        # cœur du cyclone : œil sombre, anneaux clairs
        eye = np.exp(-(rr / 0.28) ** 2)
        ringc = np.exp(-((rr - 0.62) / 0.16) ** 2)
        surf = surf * (1 - eye[..., None] * 0.8) + eye[..., None] * rgb(200, 50, 60) * 0.8
        surf = surf * (1 - ringc[..., None] * 0.5) + ringc[..., None] * rgb(255, 240, 210) * 0.5
        # liserés sombres entre les bandes (trait cartoon)
        edge = np.abs(np.clip(y, -1, 1) * 11 - np.round(np.clip(y, -1, 1) * 11))
        line = smoothstep(0.5, 0.42, edge) * 0.0 + smoothstep(0.42, 0.5, edge)
        surf = surf * (1 - line[..., None] * 0.18)
        # éclairage cel : terminateur net mais doux, côté nuit violet
        lam = nn @ LIGHT
        day = smoothstep(-0.08, 0.22, lam)
        shade = 0.72 + 0.28 * smoothstep(0.2, 0.9, lam)
        pc = surf * shade[..., None] * day[..., None] + NIGHT * (1 - day[..., None]) * (0.6 + 0.4 * surf)
        # reflet de la lumière (spéculaire doux) et liseré d'atmosphère au bord
        mu = np.clip(nn @ (-PLANET_DIR), 0, 1)
        fres = (1 - mu) ** 3
        rim = RIM * np.clip(lam + 0.35, 0, 1)[..., None] + RIM2 * np.clip(0.4 - lam, 0, 0.4)[..., None]
        pc = pc + fres[..., None] * rim * 1.15
        spec = np.clip(nn @ norm(LIGHT - PLANET_DIR), 0, 1) ** 40 * 0.25
        pc = pc + spec[..., None]
        col[hit] = pc

    # --- lunes ---
    for mdir, mang, mlight, mdark in MOONS:
        mh, mn, mg = sphere_hit(d, mdir, mang)
        mo = mg - mang
        glow = np.exp(-np.clip(mo, 0, None) / (mang * 0.4)) * (mo > 0)
        col += glow[..., None] * mlight * 0.35
        if mh.any():
            nn = mn[mh]
            lam = nn @ LIGHT
            cr = fbm(nn * 6.0 + 3.3, 4)
            craters = smoothstep(0.55, 0.7, cr) * 0.25
            day = smoothstep(-0.05, 0.25, lam)
            c = mlight * (1 - craters[..., None]) * day[..., None] + mdark * (1 - day[..., None])
            mu = np.clip(nn @ (-mdir), 0, 1)
            c = c + ((1 - mu) ** 3)[..., None] * mlight * 0.4
            col[mh] = c
    return np.clip(col, 0, 1)


def face_dirs(name):
    t = (np.arange(N) + 0.5) / N * 2 - 1
    u, v = np.meshgrid(t, t)
    x, y, z = FACES[name](u, v)
    d = np.stack([x, y, z], -1)
    return d / np.linalg.norm(d, axis=-1, keepdims=True)


def preview(path, yaw_deg=0.0, pitch_deg=8.0, fov_deg=70.0, w=960, h=540):
    """Vue en perspective depuis le vaisseau (yaw 0 = vers -Z), pour juger le rendu."""
    yaw, pitch = np.radians(yaw_deg), np.radians(pitch_deg)
    fwd = np.array([np.sin(yaw) * np.cos(pitch), np.sin(pitch), -np.cos(yaw) * np.cos(pitch)])
    right = np.cross(fwd, [0, 1, 0])
    right /= np.linalg.norm(right)
    up = np.cross(right, fwd)
    th = np.tan(np.radians(fov_deg) / 2)
    xs = (np.arange(w) + 0.5) / w * 2 - 1
    ys = (np.arange(h) + 0.5) / h * 2 - 1
    X, Y = np.meshgrid(xs * th * w / h, -ys * th)
    d = fwd + X[..., None] * right + Y[..., None] * up
    d /= np.linalg.norm(d, axis=-1, keepdims=True)
    img = render(d)
    Image.fromarray((np.power(img, 1 / 1.05) * 255 + 0.5).astype(np.uint8)).save(path)


os.makedirs(OUT, exist_ok=True)
if len(sys.argv) > 3 and sys.argv[3] == "preview":
    preview(os.path.join(OUT, "preview_back.png"), 0, 8)
    preview(os.path.join(OUT, "preview_side.png"), -60, 10)
    sys.exit(0)
for name in FACES:
    img = np.zeros((N, N, 3))
    step = 256
    for r0 in range(0, N, step):
        d = face_dirs(name)[r0:r0 + step]
        img[r0:r0 + step] = render(d)
    # gamma léger pour garder des couleurs vives
    out = (np.power(img, 1 / 1.05) * 255 + 0.5).astype(np.uint8)
    Image.fromarray(out).save(os.path.join(OUT, f"sky_{name}.png"))
    print("face", name)
print("ok")
