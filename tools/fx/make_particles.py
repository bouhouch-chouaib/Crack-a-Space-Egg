# Textures de particules des biomes (blanches, teintées dans Roblox) : flocon, éclat carré, fragment de coquille.
# Usage : python tools/fx/make_particles.py <dossier de sortie>
import math
import sys
from PIL import Image, ImageDraw, ImageFilter

out = sys.argv[1]
S = 128


def snowflake():
    img = Image.new("RGBA", (S * 4, S * 4), (255, 255, 255, 0))
    d = ImageDraw.Draw(img)
    c = S * 2
    for k in range(6):
        a = k * math.pi / 3
        x, y = c + math.cos(a) * S * 1.7, c + math.sin(a) * S * 1.7
        d.line([(c, c), (x, y)], fill=(255, 255, 255, 255), width=22)
        # petites branches
        for t in (0.45, 0.72):
            bx, by = c + math.cos(a) * S * 1.7 * t, c + math.sin(a) * S * 1.7 * t
            for s in (-1, 1):
                b = a + s * math.pi / 4
                d.line([(bx, by), (bx + math.cos(b) * S * 0.45, by + math.sin(b) * S * 0.45)], fill=(255, 255, 255, 255), width=16)
    d.ellipse([c - 34, c - 34, c + 34, c + 34], fill=(255, 255, 255, 255))
    img = img.resize((S, S), Image.LANCZOS)
    glow = img.filter(ImageFilter.GaussianBlur(4))
    base = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    base.alpha_composite(glow)
    base.alpha_composite(img)
    return base


def shard():
    # Carré net à léger halo : effet « pixel » qui scintille (The Rift)
    img = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([34, 34, S - 34, S - 34], fill=(255, 255, 255, 255))
    halo = img.filter(ImageFilter.GaussianBlur(10))
    out_img = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    out_img.alpha_composite(halo)
    out_img.alpha_composite(halo)
    out_img.alpha_composite(img)
    return out_img


def shell():
    # Demi-coquille d'œuf : bas de l'œuf, cassé en zigzag sur le haut
    W = S * 4
    egg = Image.new("L", (W, W), 0)
    d = ImageDraw.Draw(egg)
    d.ellipse([90, 20, W - 90, W - 20], fill=255)
    cut = Image.new("L", (W, W), 0)
    dc = ImageDraw.Draw(cut)
    pts = [(0, W)]
    teeth = 7
    for k in range(teeth * 2 + 1):
        x = k * W / (teeth * 2)
        y = W * 0.42 + (-45 if k % 2 else 45)
        pts.append((x, y))
    pts.append((W, W))
    dc.polygon(pts, fill=255)
    mask = Image.new("L", (W, W), 0)
    mask.paste(egg, (0, 0), cut)
    img = Image.new("RGBA", (W, W), (255, 255, 255, 0))
    img.putalpha(mask)
    img = img.resize((S, S), Image.LANCZOS)
    return img.filter(ImageFilter.GaussianBlur(0.6))


snowflake().save(out + "/FxSnow.png")
shard().save(out + "/FxShard.png")
shell().save(out + "/FxShell.png")
print("ok")
