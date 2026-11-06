# Textures plein écran du gel (ColdFx.client) : givre léger, givre épais, fissures de glace, vignette.
# Usage : python cold_textures.py <dossier_sortie>
# Images 1024 x 576 (16:9), fond transparent, à importer dans Roblox (Asset Manager ou upload_image).

import math
import os
import random
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
W, H = 1024, 576
rng = np.random.default_rng(3)
random.seed(3)

# bruit de valeur 2D lissé (répété sur plusieurs échelles)
PERM = rng.permutation(256)
PERM = np.concatenate([PERM, PERM])
VALS = rng.random(256)


def vnoise(x, y):
    xi, yi = np.floor(x).astype(int), np.floor(y).astype(int)
    xf, yf = x - xi, y - yi
    u, v = xf * xf * (3 - 2 * xf), yf * yf * (3 - 2 * yf)
    xi &= 255
    yi &= 255

    def h(dx, dy):
        return VALS[PERM[PERM[xi + dx] + yi + dy] & 255]

    a = h(0, 0) * (1 - u) + h(1, 0) * u
    b = h(0, 1) * (1 - u) + h(1, 1) * u
    return a * (1 - v) + b * v


def fbm(x, y, oct_=5):
    s, a, t = 0.0, 1.0, 0.0
    for i in range(oct_):
        s = s + a * vnoise(x * 2 ** i + i * 13.7, y * 2 ** i + i * 7.1)
        t += a
        a *= 0.5
    return s / t


def ridged(x, y, oct_=5):
    s, a, t = 0.0, 1.0, 0.0
    for i in range(oct_):
        n = 1 - np.abs(vnoise(x * 2.1 ** i + i * 5.3, y * 2.1 ** i + i * 3.9) * 2 - 1)
        s = s + a * n * n
        t += a
        a *= 0.55
    return s / t


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


ys, xs = np.mgrid[0:H, 0:W].astype(np.float64)
nx, ny = xs / W, ys / H
ar = W / H
# distance au bord le plus proche (0 au bord, ~0.5 au centre), corrigée de l'aspect
edge = np.minimum(np.minimum(nx, 1 - nx) * ar, np.minimum(ny, 1 - ny)) / (0.5)
# angle autour du centre : les cristaux poussent du bord vers le centre
ang = np.arctan2((ny - 0.5), (nx - 0.5) * ar)


# distance au centre, 0 au centre, 1 dans les coins : le givre part des coins et des bords
rell = np.sqrt(((nx - 0.5) / 0.5) ** 2 + ((ny - 0.5) / 0.5) ** 2) / math.sqrt(2)


def frost(cut, name, strength):
    n = fbm(xs / 90, ys / 90, 5)
    fern = ridged(xs / 55 + np.cos(ang) * 3, ys / 55 + np.sin(ang) * 3, 6)
    streak = 0.5 + 0.5 * np.sin(ang * 140 + n * 9)
    field = rell + (n - 0.5) * 0.3 + fern * 0.16 + streak * 0.04
    alpha = smoothstep(cut - 0.08, cut + 0.06, field)
    # cristaux plus opaques et brillants sur les arêtes
    crystal = smoothstep(0.55, 0.9, fern) * alpha
    a = np.clip(alpha * (0.55 + 0.45 * fern) * strength + crystal * 0.25, 0, 1)
    base = np.stack([0.80 + 0.2 * fern, 0.90 + 0.1 * fern, np.ones_like(fern)], -1)
    rgb = np.clip(base * (0.85 + 0.15 * crystal[..., None]), 0, 1)
    img = np.concatenate([rgb, a[..., None]], -1)
    Image.fromarray((img * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, name))


def vignette(name):
    r = np.sqrt(((nx - 0.5) * ar) ** 2 + (ny - 0.5) ** 2) / math.sqrt((0.5 * ar) ** 2 + 0.25)
    a = smoothstep(0.45, 1.0, r) ** 1.3
    img = np.zeros((H, W, 4))
    img[..., 0], img[..., 1], img[..., 2] = 0.04, 0.10, 0.25
    img[..., 3] = a
    Image.fromarray((img * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, name))


def cracks(name):
    S = 2  # dessin en double résolution puis réduit (traits nets)
    im = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
    glow = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
    dr, dg = ImageDraw.Draw(im), ImageDraw.Draw(glow)
    cx, cy = W * S * 0.52, H * S * 0.48

    def branch(x, y, angle, length, width, depth):
        pts = [(x, y)]
        for _ in range(int(length / 40)):
            angle += random.uniform(-0.12, 0.12)
            x += math.cos(angle) * 40
            y += math.sin(angle) * 40
            pts.append((x, y))
            if depth < 2 and random.random() < 0.08:
                branch(x, y, angle + random.choice([-1, 1]) * random.uniform(0.5, 1.1), length * 0.45, max(1, width * 0.6), depth + 1)
        dg.line(pts, fill=(170, 225, 255, 160), width=int(width * 4))
        dr.line(pts, fill=(255, 255, 255, 255), width=int(width))

    for k in range(11):
        a = k / 11 * math.tau + random.uniform(-0.2, 0.2)
        branch(cx, cy, a, random.uniform(900, 1500), random.uniform(5, 8), 0)
    # anneaux brisés autour de l'impact
    for rad in (70, 150, 260):
        for k in range(10):
            a0 = random.uniform(0, math.tau)
            seg = [(cx + math.cos(a0 + t * 0.22) * rad, cy + math.sin(a0 + t * 0.22) * rad) for t in range(3)]
            dg.line(seg, fill=(170, 225, 255, 120), width=14)
            dr.line(seg, fill=(255, 255, 255, 230), width=4)
    glow = glow.filter(ImageFilter.GaussianBlur(10))
    out = Image.alpha_composite(glow, im).resize((W, H), Image.LANCZOS)
    out.save(os.path.join(OUT, name))


def arrow(name):
    """Grosse flèche vers la droite : remplissage vert clair, contour sombre (style cartoon)."""
    S = 4
    n = 256 * S
    im = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    pts = [(0.10, 0.38), (0.55, 0.38), (0.55, 0.18), (0.92, 0.50), (0.55, 0.82), (0.55, 0.62), (0.10, 0.62)]
    P = [(x * n, y * n) for x, y in pts]
    d.polygon(P, fill=(22, 22, 32, 255))
    # remplissage un peu en retrait du contour
    c = (0.5 * n, 0.5 * n)
    inner = [(c[0] + (x - c[0]) * 0.84, c[1] + (y - c[1]) * 0.80) for x, y in P]
    d.polygon(inner, fill=(120, 255, 160, 255))
    hi = [(c[0] + (x - c[0]) * 0.84, c[1] + (y - c[1]) * 0.80 - 0.035 * n) for x, y in P[:4]]
    d.line(hi, fill=(220, 255, 230, 255), width=int(0.025 * n))
    im.resize((256, 256), Image.LANCZOS).save(os.path.join(OUT, name))


os.makedirs(OUT, exist_ok=True)
arrow("cold_arrow.png")
frost(0.80, "cold_frost_light.png", 0.85)
frost(0.46, "cold_frost_heavy.png", 1.0)
vignette("cold_vignette.png")
cracks("cold_cracks.png")
print("ok")
