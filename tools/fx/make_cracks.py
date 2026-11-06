# Fissures (blanches sur fond transparent, teintées dans Roblox par Decal.Color3) : 3 variantes
# de fissures qui se ramifient depuis un point, à poser sur les faces de l'astéroïde.
# Usage : python tools/fx/make_cracks.py <dossier de sortie>
import math
import random
import sys
from PIL import Image, ImageDraw, ImageFilter

out = sys.argv[1]
S = 512


def branch(d, x, y, angle, length, width, depth, rnd):
    if depth == 0 or length < 12 or width < 2:
        return
    steps = rnd.randint(3, 5)
    pts = [(x, y)]
    for _ in range(steps):
        angle += rnd.uniform(-0.55, 0.55)
        x += math.cos(angle) * length / steps
        y += math.sin(angle) * length / steps
        pts.append((x, y))
    d.line(pts, fill=255, width=int(width), joint="curve")
    for _ in range(rnd.randint(1, 2)):
        k = rnd.randint(1, len(pts) - 1)
        bx, by = pts[k]
        branch(d, bx, by, angle + rnd.choice((-1, 1)) * rnd.uniform(0.5, 1.1), length * 0.6, width * 0.62, depth - 1, rnd)


for v in range(3):
    rnd = random.Random(17 + v * 31)
    mask = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(mask)
    cx, cy = S / 2 + rnd.uniform(-40, 40), S / 2 + rnd.uniform(-40, 40)
    for k in range(rnd.randint(3, 5)):
        a = k / 4 * math.tau + rnd.uniform(-0.4, 0.4)
        branch(d, cx, cy, a, rnd.uniform(150, 220), rnd.uniform(12, 16), 4, rnd)
    # Lueur autour des fissures, puis le trait net par-dessus
    glow = mask.filter(ImageFilter.GaussianBlur(9)).point(lambda p: min(255, int(p * 1.6)))
    alpha = Image.new("L", (S, S), 0)
    alpha.paste(glow)
    core = mask.filter(ImageFilter.GaussianBlur(1))
    alpha = Image.composite(core, alpha, core)
    img = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    img.putalpha(alpha)
    img.save(out + "/FxCrack%d.png" % (v + 1))
print("ok")
