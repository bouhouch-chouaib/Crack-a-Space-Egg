# Décors du couloir, suite (biomes 4 à 8). À exécuter dans le même espace de noms que corridor_kit.py :
#   exec(open(".../corridor_kit_2.py").read(), CK)
import math
import random


def ball(m, name, r, at, role, sides=8, squash=1.0, roles=None, turn=0):
    # boule low-poly : trois prismes empilés (pas de sphère lisse dans ce style)
    x, y, z = at
    h1, h2 = 0.55 * r * squash, 0.7 * r * squash
    rs = roles or (role, role, role)
    m.prism(name + "a", radius=r * 0.62, height=h1, at=(x, y, z - h2 / 2 - h1 / 2), role=rs[0], sides=sides, taper=1 / 0.62, turn=turn)
    m.prism(name, radius=r, height=h2, at=(x, y, z), role=rs[1], sides=sides, turn=turn)
    m.prism(name + "c", radius=r, height=h1, at=(x, y, z + h2 / 2 + h1 / 2), role=rs[2], sides=sides, taper=0.62, turn=turn)
    return name


def chain(m, pre, points, role, width, taper=0.85, roles=None):
    # suite de poutres : branches, tiges, crocs recourbés
    w = width
    for i in range(len(points) - 1):
        r = roles[i % len(roles)] if roles else role
        m.beam("%s%d" % (pre, i), points[i], points[i + 1], role=r, width=w, taper=taper)
        w *= taper


# 4. NEBULA -------------------------------------------------------------------------------------------

@model
def Puff():
    # nuage de nébuleuse en blocs arrondis, étoiles de cristal
    m = M("Puff")
    m.palette(pink=plain("#C873C9", shade=0.14, top=0.2), pinkl=plain("#E3A2DF", shade=0.1, top=0.2), violet=plain("#8E5CC4", shade=0.16),
              white=plain("#E8D8EE", shade=0.1, top=0.1), star=plain("#E8C24A", top=0.25), glow=glow("#FFD84A"))
    m.box("c0", size=(7.0, 5.0, 4.4), at=(0, 0, 5.2), role="pink", chamfer=1.5)
    m.box("c1", size=(5.0, 4.2, 3.6), at=(3.8, 0.3, 4.4), role="violet", chamfer=1.2)
    m.box("c2", size=(4.6, 4.0, 3.4), at=(-3.8, -0.2, 4.2), role="pinkl", chamfer=1.1)
    m.box("c3", size=(4.4, 3.8, 3.4), at=(0.8, 0, 8.2), role="pinkl", chamfer=1.1)
    m.box("c4", size=(3.2, 3.0, 2.6), at=(-2.4, 0.4, 7.6), role="white", chamfer=0.9)
    m.box("c5", size=(3.4, 3.0, 2.2), at=(1.6, -1.6, 3.0), role="violet", chamfer=0.8)
    m.box("c6", size=(3.0, 2.6, 2.0), at=(-1.8, 1.4, 2.6), role="pink", chamfer=0.7)
    # traînée d'étoiles
    for i, (x, y, z, s) in enumerate(((4.6, -1.2, 9.6, 1.0), (-4.8, -0.8, 8.8, 0.7), (5.6, 0.6, 7.0, 0.5), (0.2, -0.6, 12.0, 1.2))):
        m.crystal("star%d" % i, radius=0.42 * s, height=1.9 * s, at=(x, y, z - 0.95 * s), role="glow", sides=4, tip=0.5, base_tip=0.5, solo=True)
        m.box("starx%d" % i, size=(1.7 * s, 0.3 * s, 0.3 * s), at=(x, y, z), role="glow", solo=True)
    for i, (x, y, z) in enumerate(((-5.4, 1.0, 5.6), (5.6, -1.8, 2.6), (-2.6, -2.0, 10.2))):
        m.crystal("gem%d" % i, radius=0.4, height=1.1, at=(x, y, z), role="star", sides=6, tip=0.4, base_tip=0.4, solo=True)
    m.build()
    return m


@model
def Planet():
    # petite planète à anneau, lune et cratères
    m = M("Planet")
    m.palette(land=plain("#7C63C8", mottle=("#5F49A6", 0.25, 5)), landd=plain("#5A4599"), landl=plain("#9E86DE", top=0.2),
              ring=plain("#D9B24A", top=0.2), ringd=plain("#B5892E"), crater="#4C3A86", moon=plain("#D6C6E6"), glow=glow("#FFD84A"),
              stand=plain("#5B4A7A"))
    m.prism("foot", radius=2.2, height=0.8, at=(0, 0, 0.4), role="stand", sides=8, taper=0.8)
    m.prism("pole", radius=0.5, height=2.4, at=(0, 0, 1.9), role="stand", sides=6)
    ball(m, "p", 3.8, (0, 0, 6.6), "land", sides=10, roles=("landd", "land", "landl"))
    m.prism("ring", radius=6.4, height=0.35, at=(0, 0, 6.6), role="ring", sides=14, rot=(18, 10, 0))
    m.prism("ringIn", radius=5.0, height=0.5, at=(0, 0, 6.6), role="ringd", sides=14, rot=(18, 10, 0))
    ball(m, "moon", 1.1, (4.8, -1.6, 10.6), "moon", sides=7)
    m.crystal("spark", radius=0.35, height=1.0, at=(-4.4, -1.0, 10.8), role="glow", sides=4, tip=0.5, base_tip=0.5, solo=True)
    m.box("sparkx", size=(0.9, 0.2, 0.2), at=(-4.4, -1.0, 11.3), role="glow", solo=True)
    m.build()
    for i in (0, 3, 6, 8):
        m.circle("p", "side%d" % i, (0.2 * (i % 3 - 1), 0.1), 0.6, "crater")
    m.circle("pc", "side2", (0, 0), 0.5, "crater")
    return m


# 5. DEVOURER BELT ------------------------------------------------------------------------------------

@model
def Fang():
    # mâchoire de pierre : un grand croc recourbé et des dents, bave verte lumineuse
    m = M("Fang")
    m.palette(gum=plain("#6E3550", mottle=("#55283E", 0.25, 4), shade=0.2), gumd=plain("#4E2439"),
              bone=plain("#CDBE9E", shade=0.16, top=0.12, streaks=("#A89877", 0.2, "v")), boned=plain("#A8987A"),
              rock=plain("#4A444C", mottle=("#38333A", 0.25, 4)), glow=glow("#7CE83A"))
    S = m.surface
    m.prism("base", radius=4.6, height=2.0, at=(0, 0, 1.0), role="rock", sides=7, taper=0.86, turn=12)
    m.box("gum", size=(7.6, 4.4, 2.6), at=(0, 0, 3.0), role="gum", chamfer=0.9, taper=0.86)
    m.box("gumBack", size=(5.4, 2.6, 1.8), at=(0, 1.0, 4.8), role="gumd", chamfer=0.6, taper=0.8)
    # grand croc recourbé vers l'avant
    pts = [(0, 0.6, 4.0), (0, 0.4, 7.2), (0, -0.4, 10.0), (0, -1.6, 12.2), (0, -3.0, 13.6)]
    chain(m, "fang", pts, "bone", 2.6, taper=0.72, roles=("bone", "boned"))
    for i, (x, h, r) in enumerate(((-2.7, 3.4, 0.95), (2.7, 3.0, 0.9), (-1.4, 2.2, 0.7), (1.5, 2.4, 0.7), (-3.4, 1.8, 0.6), (3.4, 1.6, 0.55))):
        m.prism("tooth%d" % i, radius=r, height=h, at=(x, -1.2 + abs(x) * 0.25, 4.1 + h / 2), role="bone" if i % 2 == 0 else "boned", sides=5,
                taper=0.12, shear=(0, -0.3))
    # bave
    for i, (x, l) in enumerate(((-0.9, 1.8), (1.1, 1.2), (2.4, 0.9))):
        m.box("drool%d" % i, size=(0.3, 0.2, l), at=(x, -2.3, 3.6 - l / 2), role="glow", solo=True)
    m.crystal("drop", radius=0.3, height=0.8, at=(-0.9, -2.3, 1.4), role="glow", sides=5, tip=0.3, base_tip=0.5, solo=True)
    m.build()
    m.blob("gum", "front", (-1.6, 0.2), 0.8, "gumd", seed=3)
    m.blob("gum", "front", (2.0, -0.2), 0.6, "gumd", seed=6)
    return m


@model
def Eye():
    # œil géant sur sa tige : il regarde le couloir
    m = M("Eye")
    m.palette(stalk=plain("#5A3F5E", mottle=("#44304A", 0.25, 4), shade=0.2), stalkd=plain("#44304A"),
              white=plain("#D6D2C4", shade=0.14, top=0.1), vein="#B0505A", iris=plain("#4E9A2E", shade=0.1), irisl=plain("#7CC043"),
              lid=plain("#5A3F5E"), rock=plain("#4A444C", mottle=("#38333A", 0.25, 4)), glow=glow("#7CE83A"), pupil="#15131A")
    m.prism("base", radius=3.4, height=1.6, at=(0, 0, 0.8), role="rock", sides=7, taper=0.82, turn=8)
    chain(m, "stalk", [(0, 0.4, 1.4), (0.5, 0.6, 3.6), (0.2, 0.3, 5.6)], "stalk", 2.2, taper=0.85, roles=("stalk", "stalkd"))
    ball(m, "eye", 3.6, (0, 0, 8.6), "white", sides=10)
    # iris et pupille : disques posés sur l'avant du globe
    m.prism("iris", radius=2.1, height=0.5, at=(0, -3.35, 8.6), role="iris", sides=10, rot=(90, 0, 0))
    m.prism("irisIn", radius=1.4, height=0.6, at=(0, -3.4, 8.6), role="irisl", sides=10, rot=(90, 0, 0))
    m.prism("pupil", radius=0.75, height=0.7, at=(0, -3.45, 8.6), role="glow", sides=4, rot=(90, 0, 0), solo=True)
    m.box("lidTop", size=(7.0, 5.2, 1.6), at=(0, -0.2, 11.4), role="lid", chamfer=0.6, taper=0.7, rot=(14, 0, 0))
    m.box("lidLow", size=(6.2, 4.6, 1.0), at=(0, -0.2, 5.9), role="lid", chamfer=0.4, taper=1.2)
    for i, (x, h) in enumerate(((-2.2, 1.4), (-0.7, 1.8), (0.8, 1.7), (2.3, 1.3))):
        m.prism("lash%d" % i, radius=0.3, height=h, at=(x, -1.6, 12.3 + h / 2), role="stalkd", sides=4, taper=0.1, shear=(x * 0.15, -0.3))
    for i, (x, y, r) in enumerate(((-3.0, 0.8, 0.5), (2.9, -0.6, 0.4))):
        m.crystal("wart%d" % i, radius=r, height=r * 2.2, at=(x, y, 1.2), role="glow", sides=5, tip=0.4, solo=True)
    m.build()
    for i in (1, 2, 8, 9):
        m.line("eye", "side%d" % i, [(-1.0, 0.8), (0.2, 0.1), (0.9, -0.7)], "vein", width=1)
    return m


# 6. THE RIFT -----------------------------------------------------------------------------------------

@model
def Hourglass():
    # sablier géant fêlé, sable cyan qui s'échappe
    m = M("Hourglass")
    m.palette(gold=plain("#B8892E", top=0.22, rim=-0.2), goldd=plain("#8F6820"), glass=dict(color="#3F7FA8", noise=0.02, shade=0.08, top=0.2),
              glassl=dict(color="#69AFD4", noise=0.02, shade=0.08), sand=plain("#2FA8B8"), dark=plain("#2C3454"), glow=glow("#39E4F0"),
              glowM=glow("#E04FD0"))
    m.prism("foot", radius=4.4, height=0.9, at=(0, 0, 0.45), role="goldd", sides=8)
    m.prism("foot2", radius=3.8, height=0.7, at=(0, 0, 1.25), role="gold", sides=8, taper=0.85)
    m.prism("lower", radius=3.1, height=4.4, at=(0, 0, 3.8), role="glass", sides=8, taper=0.22)
    m.prism("sandLow", radius=2.9, height=1.6, at=(0, 0, 2.5), role="sand", sides=8, taper=0.75)
    m.prism("neck", radius=0.8, height=0.9, at=(0, 0, 6.3), role="gold", sides=8)
    m.prism("upper", radius=0.7, height=4.4, at=(0, 0, 8.9), role="glassl", sides=8, taper=3.1 / 0.7)
    m.prism("top2", radius=3.8, height=0.7, at=(0, 0, 11.45), role="gold", sides=8, taper=1 / 0.85)
    m.prism("top", radius=4.4, height=0.9, at=(0, 0, 12.25), role="goldd", sides=8)
    for i in range(4):
        a = math.radians(45 + i * 90)
        x, y = math.cos(a) * 3.6, math.sin(a) * 3.6
        m.beam("post%d" % i, (x, y, 1.5), (x, y, 11.2), role="gold", width=0.5)
        m.prism("knob%d" % i, radius=0.5, height=0.6, at=(x, y, 6.3), role="goldd", sides=6)
    m.box("stream", size=(0.3, 0.3, 2.4), at=(0, 0, 5.2), role="glow", solo=True)
    # fêlure et éclats qui flottent
    m.box("crack0", size=(0.2, 1.8, 0.12), at=m.surface("upper", "side6", (0.1, 0.4), sink=0.05), role="glowM", rot=(0, 0, 25), solo=True)
    m.box("crack1", size=(0.2, 1.2, 0.12), at=m.surface("upper", "side6", (-0.3, -0.5), sink=0.05), role="glowM", rot=(0, 0, -40), solo=True)
    for i, (x, y, z, s) in enumerate(((4.6, -1.6, 9.6, 0.9), (5.4, -0.6, 7.4, 0.6), (-4.8, -1.2, 5.4, 0.7))):
        m.box("shard%d" % i, size=(s, s, s), at=(x, y, z), role="glow" if i != 1 else "glowM", rot=(20 * i, 30, 15), solo=True)
    m.build()
    return m


@model
def Glitch():
    # pile de cubes de pixels qui se décalent, écran fendu
    m = M("Glitch")
    m.palette(dark=plain("#2C3454", shade=0.2, tiles=(4, 0.12)), darkl=plain("#3E4A76", tiles=(4, 0.12)), cyan=plain("#2FA8C8"),
              mag=plain("#B83FB0"), glow=glow("#39E4F0"), glowM=glow("#E04FD0"), white="#D8E6F0")
    rnd = random.Random(11)
    m.box("base", size=(6.4, 5.6, 1.6), at=(0, 0, 0.8), role="dark", chamfer=0.3)
    z = 1.6
    sizes = [(5.0, 4.6, 2.6), (4.0, 3.8, 2.4), (3.2, 3.0, 2.2), (2.4, 2.2, 2.0), (1.6, 1.6, 1.6)]
    for i, (sx, sy, sz) in enumerate(sizes):
        ox, oy = rnd.uniform(-1.0, 1.0), rnd.uniform(-0.6, 0.6)
        m.box("cube%d" % i, size=(sx, sy, sz), at=(ox, oy, z + sz / 2), role=("darkl", "cyan", "dark", "mag", "darkl")[i], rot=(0, 0, rnd.uniform(-18, 18)))
        z += sz + (0.35 if i >= 2 else 0)
    # pixels qui s'échappent sur les côtés
    for i in range(9):
        s = rnd.choice((0.5, 0.7, 0.9))
        side = 1 if i % 2 else -1
        m.box("pix%d" % i, size=(s, s, s), at=(side * rnd.uniform(3.2, 5.2), rnd.uniform(-1.6, 1.0), rnd.uniform(2.0, 12.0)),
              role="glow" if i % 3 else "glowM", solo=True)
    m.box("scan0", size=(5.4, 0.2, 0.3), at=(0.2, -2.4, 3.2), role="glow", solo=True)
    m.box("scan1", size=(3.6, 0.2, 0.25), at=(-0.6, -2.0, 6.2), role="glowM", solo=True)
    m.build()
    m.stamp("cube0", "front", (0, 0), ["#.#.#", ".#.#.", "#.#.#"], {"#": "white"}, cell=0.4)
    m.rect("cube1", "front", (-0.8, 0.2), (0.6, 0.6), "white")
    m.rect("cube1", "front", (0.8, 0.2), (0.6, 0.6), "white")
    return m


# 7. THE NEST -----------------------------------------------------------------------------------------

def egg(m, name, r, at, role, roled, rolel, sides=8):
    # œuf low-poly : base ronde, ventre large, sommet qui se resserre
    x, y, z = at
    m.prism(name + "a", radius=r * 0.6, height=r * 0.5, at=(x, y, z + r * 0.25), role=roled, sides=sides, taper=1 / 0.6)
    m.prism(name, radius=r, height=r * 0.9, at=(x, y, z + r * 0.95), role=role, sides=sides, taper=0.9)
    m.prism(name + "c", radius=r * 0.9, height=r * 0.8, at=(x, y, z + r * 1.8), role=rolel, sides=sides, taper=0.62)
    m.prism(name + "d", radius=r * 0.56, height=r * 0.4, at=(x, y, z + r * 2.4), role=rolel, sides=sides, taper=0.4)
    return name


def twigs(m, pre, r, z, n, role, roled, seed=1, width=0.5, lift=0.6):
    rnd = random.Random(seed)
    for i in range(n):
        a = i / n * math.tau + rnd.uniform(-0.15, 0.15)
        b = a + rnd.uniform(0.7, 1.1)
        r1, r2 = r * rnd.uniform(0.9, 1.08), r * rnd.uniform(0.9, 1.08)
        m.beam("%s%d" % (pre, i), (math.cos(a) * r1, math.sin(a) * r1, z + rnd.uniform(0, lift)), (math.cos(b) * r2, math.sin(b) * r2, z + rnd.uniform(0, lift)),
               role=role if i % 2 else roled, width=width * rnd.uniform(0.8, 1.2))


@model
def Nest():
    # nid de brindilles tressées, trois œufs dont un doré, plumes
    m = M("Nest")
    m.palette(twig=plain("#7A5636", streaks=("#5E4128", 0.3, "u")), twigd=plain("#5A3F28", streaks=("#46301E", 0.3, "u")), straw=plain("#B8924E"),
              shell=plain("#C9BEA4", shade=0.14, top=0.12), shelld=plain("#A89C82"), shelll=plain("#DDD4BC"), spot="#8A6A4E",
              gold=plain("#C9952B", top=0.25), goldd=plain("#9E7320"), goldl=plain("#E4B84A"), feather=plain("#D8D2C4"), glow=glow("#FFCF4A"))
    m.prism("bowl", radius=5.6, height=1.6, at=(0, 0, 0.8), role="twigd", sides=10, taper=1.14)
    m.prism("bowlIn", radius=4.8, height=0.5, at=(0, 0, 1.75), role="straw", sides=10)
    twigs(m, "tw", 5.9, 1.2, 14, "twig", "twigd", seed=2, width=0.7, lift=1.3)
    twigs(m, "tx", 6.3, 0.4, 10, "twigd", "twig", seed=5, width=0.55, lift=0.8)
    egg(m, "eggA", 1.7, (-2.0, -0.4, 1.8), "shell", "shelld", "shelll")
    egg(m, "eggB", 1.9, (2.0, -0.2, 1.8), "gold", "goldd", "goldl")
    egg(m, "eggC", 1.5, (0, 2.2, 1.8), "shell", "shelld", "shelll", sides=7)
    m.crystal("shine", radius=0.3, height=0.9, at=(3.2, -1.2, 7.2), role="glow", sides=4, tip=0.5, base_tip=0.5, solo=True)
    m.beam("fe0", (-5.2, -2.6, 2.2), (-6.6, -3.6, 5.0), role="feather", width=0.9, depth=0.15, taper=0.3)
    m.beam("fe1", (4.6, 3.4, 2.2), (6.2, 4.4, 4.4), role="feather", width=0.7, depth=0.15, taper=0.3)
    m.build()
    for name, n in (("eggA", 8), ("eggC", 7)):
        for i in range(0, n, 2):
            m.circle(name, "side%d" % i, (0.1, 0.1), 0.3, "spot")
    return m


@model
def BigEgg():
    # œuf géant qui se fend : lumière dans la fissure, éclats de coquille
    m = M("BigEgg")
    m.palette(twig=plain("#7A5636", streaks=("#5E4128", 0.3, "u")), twigd=plain("#5A3F28"), shell=plain("#C9BEA4", shade=0.14, top=0.12),
              shelld=plain("#A89C82"), shelll=plain("#DDD4BC"), spot=plain("#8A6A4E"), spotc="#8A6A4E", glow=glow("#FFCF4A"), straw=plain("#B8924E"))
    m.prism("nest", radius=4.6, height=1.4, at=(0, 0, 0.7), role="twigd", sides=9, taper=1.1)
    twigs(m, "tw", 4.9, 0.9, 11, "twig", "twigd", seed=8, width=0.6, lift=0.9)
    egg(m, "egg", 3.6, (0, 0, 1.2), "shell", "shelld", "shelll", sides=9)
    # fissure en zigzag sur l'avant
    zig = [(-1.4, 6.6), (-0.5, 5.6), (-1.0, 4.6), (0.2, 3.8), (-0.3, 2.9), (0.8, 2.3)]
    for i in range(len(zig) - 1):
        (x0, z0), (x1, z1) = zig[i], zig[i + 1]
        m.beam("crack%d" % i, (x0, -3.55, z0), (x1, -3.55, z1), role="glow", width=0.34, depth=0.3)
    m.box("chipA", size=(1.4, 0.3, 1.2), at=(2.8, -3.6, 1.6), role="shelll", rot=(20, 10, 30), solo=True)
    m.box("chipB", size=(1.0, 0.3, 0.9), at=(-3.4, -3.2, 1.4), role="shell", rot=(-15, 20, -20), solo=True)
    for i, (a, z, r) in enumerate(((0.6, 5.0, 0.55), (2.2, 6.6, 0.45), (3.7, 4.2, 0.6), (5.0, 6.0, 0.5), (1.4, 8.0, 0.4))):
        m.prism("spot%d" % i, radius=r, height=0.25, at=(math.cos(a) * 3.2, math.sin(a) * 3.2, z), role="spot", sides=6,
                rot=(90, 0, math.degrees(a) - 90), solo=True)
    m.build()
    return m


# 8. STAR REEF ----------------------------------------------------------------------------------------

def coral(m, pre, x, y, h, role, tip, seed, width=0.9):
    rnd = random.Random(seed)
    m.beam(pre + "t", (x, y, 0.8), (x + rnd.uniform(-0.4, 0.4), y, h * 0.55), role=role, width=width, taper=0.85)
    top = (x, y, h * 0.5)
    for i in range(4):
        a = i / 4 * math.tau + rnd.uniform(-0.4, 0.4)
        l = h * rnd.uniform(0.35, 0.55)
        mid = (top[0] + math.cos(a) * l * 0.5, top[1] + math.sin(a) * l * 0.35, top[2] + l * 0.45)
        end = (mid[0] + math.cos(a) * l * 0.2, mid[1] + math.sin(a) * l * 0.15, mid[2] + l * 0.6)
        m.beam("%sb%d" % (pre, i), top, mid, role=role, width=width * 0.75, taper=0.85)
        m.beam("%sc%d" % (pre, i), mid, end, role=role, width=width * 0.6, taper=0.8)
        m.prism("%sk%d" % (pre, i), radius=width * 0.55, height=width * 0.7, at=(end[0], end[1], end[2] + width * 0.2), role=tip, sides=6, taper=0.7)


@model
def Coral():
    # massif de corail : deux coraux branchus, éponge, étoile de mer
    m = M("Coral")
    m.palette(rock=plain("#2F7C86", mottle=("#245F68", 0.25, 4)), rockd=plain("#245F68"), pink=plain("#C8546C"), pinkl=plain("#E88A9A"),
              orange=plain("#D9822E"), orangel=plain("#EDB05A"), violet=plain("#8A5CC4"), star=plain("#E0B03A", top=0.2), glow=glow("#5CF0DC"),
              sand=plain("#C9B88A"))
    m.prism("base", radius=5.0, height=1.8, at=(0, 0, 0.9), role="rock", sides=8, taper=0.84, turn=10)
    m.box("rockA", size=(3.2, 2.6, 2.0), at=(-3.0, 1.6, 1.4), role="rockd", chamfer=0.6, taper=0.7)
    coral(m, "A", -1.4, 0.4, 12.5, "pink", "pinkl", 3, width=1.1)
    coral(m, "B", 2.4, -0.6, 9.0, "orange", "orangel", 7, width=0.9)
    # éponge en tubes
    for i, (x, y, h, r) in enumerate(((-3.6, -1.6, 3.4, 0.8), (-2.7, -2.4, 2.4, 0.65), (-4.3, -0.6, 2.0, 0.6))):
        m.prism("tube%d" % i, radius=r, height=h, at=(x, y, 1.2 + h / 2), role="violet", sides=7, taper=1.15)
        m.prism("tubeIn%d" % i, radius=r * 0.6, height=0.2, at=(x, y, 1.25 + h), role="glow", sides=7, solo=True)
    # étoile de mer posée sur le rocher
    for i in range(5):
        a = i / 5 * math.tau + 0.3
        m.beam("arm%d" % i, (3.4, -2.6, 1.9), (3.4 + math.cos(a) * 1.4, -2.6 + math.sin(a) * 1.4, 1.75), role="star", width=0.6, depth=0.3, taper=0.3)
    m.build()
    return m


@model
def Clam():
    # bénitier géant entrouvert sur sa perle lumineuse, algues
    m = M("Clam")
    m.palette(shell=plain("#C97E94", streaks=("#A85E74", 0.3, "v")), shelld=plain("#A85E74"), shelll=plain("#E6A8B8"), inner=plain("#E8D8E0"),
              rock=plain("#2F7C86", mottle=("#245F68", 0.25, 4)), weed=plain("#3F9A5A"), weedl=plain("#6CC47A"), glow=glow("#F4F0FF"),
              glowT=glow("#5CF0DC"))
    m.prism("base", radius=4.8, height=1.4, at=(0, 0, 0.7), role="rock", sides=8, taper=0.86)
    m.box("low", size=(7.4, 5.4, 2.0), at=(0, 0, 2.2), role="shelld", chamfer=0.8, taper=1.12)
    m.box("lowIn", size=(6.4, 4.6, 0.4), at=(0, 0, 3.3), role="inner", chamfer=0.1)
    m.box("upp", size=(7.4, 5.4, 1.8), at=(0, 1.9, 6.4), role="shell", chamfer=0.8, taper=0.86, rot=(-48, 0, 0))
    for i, x in enumerate((-2.8, -1.4, 0, 1.4, 2.8)):
        m.box("rib%d" % i, size=(0.7, 4.6, 0.5), at=m.surface("upp", "top", (x, 0), sink=0.1), role="shelll", chamfer=0.15)
        m.prism("scal%d" % i, radius=0.7, height=0.9, at=(x, -2.75, 3.0), role="shelll", sides=5, taper=0.4)
    ball(m, "pearl", 1.3, (0, -0.4, 4.7), "glow", sides=8)
    for i, (x, y, h) in enumerate(((-4.4, 1.8, 8.6), (-3.8, 2.6, 6.2), (4.3, 2.0, 7.4))):
        chain(m, "weed%d_" % i, [(x, y, 0.8), (x + 0.5, y, h * 0.35), (x - 0.4, y, h * 0.7), (x + 0.3, y, h)], "weed", 0.7, taper=0.8,
              roles=("weed", "weedl"))
    for i, (x, y, z, s) in enumerate(((2.6, -1.8, 7.2, 0.5), (3.2, -1.2, 9.0, 0.35), (-1.8, -2.0, 8.4, 0.4))):
        m.crystal("bub%d" % i, radius=s, height=s * 2, at=(x, y, z), role="glowT", sides=6, tip=0.5, base_tip=0.5, solo=True)
    m.build()
    return m
