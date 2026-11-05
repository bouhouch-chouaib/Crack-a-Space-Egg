# Textures de lumière blanches (teintées dans Roblox par ImageColor3) : rayons, halo, étincelle
import math
import sys
from PIL import Image, ImageFilter

out = sys.argv[1]


def rays(size=512, count=12):
    img = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    px = img.load()
    c = size / 2
    for y in range(size):
        for x in range(size):
            dx, dy = x - c + 0.5, y - c + 0.5
            r = math.hypot(dx, dy) / c
            if r > 1:
                continue
            a = math.atan2(dy, dx)
            # rayons en pointe, bords doux
            s = (math.cos(a * count) + 1) / 2
            s = min(1.0, max(0.0, (s - 0.18) / 0.5)) ** 0.7
            fade = min(1.0, (1 - r) * 1.6) ** 0.8 * min(1.0, r * 5)
            px[x, y] = (255, 255, 255, int(255 * s * fade))
    return img.filter(ImageFilter.GaussianBlur(1.2))


def glow(size=256):
    img = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    px = img.load()
    c = size / 2
    for y in range(size):
        for x in range(size):
            r = math.hypot(x - c + 0.5, y - c + 0.5) / c
            a = min(1.0, max(0.0, 1 - r) ** 1.3 * 1.25)
            px[x, y] = (255, 255, 255, int(255 * a))
    return img


def sparkle(size=128):
    img = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    px = img.load()
    c = size / 2
    for y in range(size):
        for x in range(size):
            dx, dy = abs(x - c + 0.5) / c, abs(y - c + 0.5) / c
            # étoile à 4 branches : |x|^0.5 + |y|^0.5 < 1 (astroïde), plus un petit halo
            v = dx ** 0.5 + dy ** 0.5
            star = 1.0 if v < 0.75 else max(0.0, 1 - (v - 0.75) / 0.12)
            halo = max(0.0, 1 - math.hypot(dx, dy) / 0.55) ** 2 * 0.6
            a = min(1.0, star + halo)
            px[x, y] = (255, 255, 255, int(255 * a))
    return img.filter(ImageFilter.GaussianBlur(0.8))


rays().save(out + "/FxRays.png")
glow().save(out + "/FxGlow.png")
sparkle().save(out + "/FxSparkle.png")
print("ok")
