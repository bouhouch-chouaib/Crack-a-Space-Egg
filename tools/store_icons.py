# Icônes des produits et passes Robux (512 x 512), composées à partir des planches d'icônes du jeu
# (ropilot_generate_ui_art, style « simulator ») : fond arrondi en dégradé, icône, badge texte.
# Usage : python store_icons.py <planche1.png> <planche2.png> <planche3.png> <dossier_sortie>

import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

S1, S2, S3, OUT = sys.argv[1:5]
os.makedirs(OUT, exist_ok=True)
FONT = "C:/Windows/Fonts/ariblk.ttf"


def grid(path, names, cols=3, rows=3):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    out = {}
    for i, n in enumerate(names):
        c, r = i % cols, i // cols
        cell = im.crop((c * w // cols, r * h // rows, (c + 1) * w // cols, (r + 1) * h // rows))
        bbox = cell.getchannel("A").point(lambda a: 255 if a > 40 else 0).getbbox()
        out[n] = cell.crop(bbox) if bbox else cell
    return out


ICONS = {}
ICONS.update(grid(S1, ["Home", "Lock", "Warning", "Freezing", "Snowflake", "WindTunnel", "Lightning", "Star", "Hourglass"]))
ICONS.update(grid(S2, ["Hatch", "Mouse", "Tap", "ArrowUp", "Cross", "Lifebuoy", "Fire", "Galaxy", "Eye"]))
third = Image.open(S3).convert("RGBA")
w3, h3 = third.size
for n, box in (("Rift", (0, 0, w3 // 2, h3 // 2 + 60)), ("Sparkles", (w3 // 2, 0, w3, h3 // 2 + 60))):
    cell = third.crop(box)
    ICONS[n] = cell.crop(cell.getchannel("A").point(lambda a: 255 if a > 40 else 0).getbbox())


def background(c1, c2):
    n = 512
    bg = Image.new("RGBA", (n, n))
    d = ImageDraw.Draw(bg)
    for y in range(n):
        t = y / n
        d.line([(0, y), (n, y)], fill=tuple(int(c1[i] * (1 - t) + c2[i] * t) for i in range(3)) + (255,))
    # rayons doux depuis le centre
    rays = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rays)
    for k in range(12):
        a0 = k * 30
        rd.pieslice([-200, -200, n + 200, n + 200], a0, a0 + 12, fill=(255, 255, 255, 34))
    bg = Image.alpha_composite(bg, rays)
    glow = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([96, 96, 416, 416], fill=(255, 255, 255, 90))
    bg = Image.alpha_composite(bg, glow.filter(ImageFilter.GaussianBlur(50)))
    mask = Image.new("L", (n, n), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, n - 1, n - 1], radius=90, fill=255)
    out = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    out.paste(bg, (0, 0), mask)
    ImageDraw.Draw(out).rounded_rectangle([6, 6, n - 7, n - 7], radius=86, outline=(22, 22, 32, 255), width=12)
    return out


def paste_icon(img, name, size, center):
    ic = ICONS[name]
    s = size / max(ic.size)
    ic = ic.resize((int(ic.width * s), int(ic.height * s)), Image.LANCZOS)
    img.alpha_composite(ic, (int(center[0] - ic.width / 2), int(center[1] - ic.height / 2)))


def badge(img, text, center, size, fill=(255, 255, 255), angle=-8):
    font = ImageFont.truetype(FONT, size)
    tmp = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    d = ImageDraw.Draw(tmp)
    bbox = d.textbbox((0, 0), text, font=font, stroke_width=max(6, size // 7))
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text((256 - tw / 2 - bbox[0], 256 - th / 2 - bbox[1]), text, font=font, fill=fill + (255,), stroke_width=max(6, size // 7), stroke_fill=(22, 22, 32, 255))
    tmp = tmp.rotate(angle, resample=Image.BICUBIC)
    img.alpha_composite(tmp, (int(center[0] - 256), int(center[1] - 256)))


def make(fname, colors, icon, text=None, icon2=None, text_size=120, text_color=(255, 255, 255)):
    img = background(*colors)
    if text:
        paste_icon(img, icon, 330, (236, 220))
        if icon2:
            paste_icon(img, icon2, 170, (388, 130))
        badge(img, text, (300, 392), text_size, text_color)
    else:
        paste_icon(img, icon, 380, (256, 256))
        if icon2:
            paste_icon(img, icon2, 180, (390, 120))
    img.save(os.path.join(OUT, fname + ".png"))


CYAN, ORANGE, PURPLE, GREEN, BLUE, GOLD, RED, PINK = (
    ((90, 220, 255), (20, 110, 220)), ((255, 190, 80), (230, 90, 30)), ((200, 120, 255), (110, 40, 200)),
    ((130, 240, 110), (30, 150, 70)), ((110, 180, 255), (40, 70, 200)), ((255, 230, 110), (230, 150, 20)),
    ((255, 120, 120), (190, 30, 60)), ((255, 140, 220), (200, 40, 150)))
YELLOW = (255, 230, 90)
MONEY = (140, 255, 120)

# Passes
make("pass_JetXP2x", CYAN, "WindTunnel", "x2")
make("pass_TurboJetpack", ORANGE, "Fire", "+25%", text_size=96, text_color=YELLOW)
make("pass_FastHatch", PURPLE, "Hatch", "x2", icon2="Hourglass")
make("pass_Money2x", GREEN, "Sparkles", "$x2", text_color=MONEY, text_size=110)
make("pass_BaseSlots", BLUE, "Home", "+5")
make("pass_VIP", GOLD, "Star", "VIP", text_size=110, text_color=YELLOW)
# Potions
make("potion_Luck", PURPLE, "Sparkles", "x2", icon2="Star")
make("potion_Money", GREEN, "Sparkles", "$x2", text_color=MONEY, text_size=110)
make("potion_JetXP", CYAN, "WindTunnel", "x2", icon2="Lightning")
make("potion_Meteor", RED, "Fire", "", icon2="Galaxy")
# Offre et paquets d'argent
make("featured_Starter", GOLD, "Star", "$$$", icon2="Sparkles", text_color=MONEY, text_size=100)
for i in range(1, 6):
    make(f"money_{i}", GREEN, "Sparkles", "$" * min(i, 3) + ("+" if i > 3 else ""), text_color=MONEY, text_size=130 - i * 6)
# Foreuses (palier 2 à 11)
DRILL = [None, None, ((240, 170, 120), (170, 90, 40)), ((200, 215, 235), (110, 130, 170)), ((120, 200, 255), (30, 110, 220)),
         ((140, 255, 170), (40, 170, 90)), ((220, 150, 255), (130, 60, 220)), ((255, 225, 110), (220, 150, 20)),
         ((170, 245, 255), (60, 170, 220)), ((255, 160, 120), (220, 80, 40)), ((255, 150, 230), (200, 60, 170)),
         ((170, 255, 245), (40, 190, 180))]
for tier in range(2, 12):
    make(f"drill_{tier}", DRILL[tier], "Lightning", f"T{tier}", text_size=120)
# Faire éclore tout de suite (rareté 1 à 7)
RARITY = [((210, 215, 225), (130, 140, 160)), ((150, 245, 140), (50, 160, 70)), ((120, 190, 255), (40, 90, 220)),
          ((210, 140, 255), (120, 50, 210)), ((255, 220, 110), (230, 140, 20)), ((255, 140, 200), (210, 40, 120)),
          ((140, 255, 245), (60, 90, 230))]
for r in range(1, 8):
    make(f"hatch_{r}", RARITY[r - 1], "Hatch", "NOW", icon2="Lightning", text_size=105, text_color=YELLOW)
print("ok", len(os.listdir(OUT)))
