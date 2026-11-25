# Astéroïdes de l'anneau 13 « Jade Temple » (25 nov.), au kit low-poly de Ropilot (ropilot.model, px = 8,
# sans picots : ils sont posés dans Studio sur la roche seulement). Même méthode que asteroids_r1.py.
# Silhouette propre à l'anneau : un bloc de roche brute (socle évasé + ceinture de jade à 7-9 pans) qui porte
# un petit temple carré à deux gradins, avec un escalier taillé qui monte au sommet plat (on y marche).
#   V1 Soft Rock   : roche de jade vert, temple de pierre sculptée, second lobe rocheux portant une arche en
#                    ruine (deux piliers et un linteau), pilier brisé et chapiteau tombé au sommet, motifs
#                    en escalier gravés en jade clair, rainures, éclats de jade, mousse
#   V2 Silver Rock : jade sombre, escalier sur le côté, grosses grappes de cristaux d'argent (une au sommet
#                    comme un trésor sur l'autel), filons d'argent, motifs en escalier, un pilier brisé
#   V3 Gold Rock   : jade très sombre, bandeaux et motifs en escalier en or gravé, grappes de cristaux d'or,
#                    pépites, fentes lumineuses orange (néon), escalier en façade
# Attention au kit : la peinture est appliquée au build() suivant et s'accumule ; peindre puis construire.
# Gradins carrés = prismes à 4 pans, turn = 0 : side0 = avant (-Y), side1 = +X, side2 = +Y, side3 = -X ;
# demi-largeur = rayon x 0.707.
# À lancer avec ropilot_blender_run_python, puis join_rock() par collection (_Asteroid, _Ore, _Glow),
# ropilot_blender_import et réglage dans Studio (voir asteroids_r1.py). Couleurs plus foncées que voulu.
import math
import random

BODY = ("bot", "mid", "top", "lobe", "bump")

GLYPH = ["....######....",
         "....#....#....",
         "..###....###..",
         "..#........#..",
         "###........###"]


def cluster(m, pre, host, face, uv, big, role1, role2, n=4, seed=1):
    rnd = random.Random(seed)
    m.crystal(pre + "0", radius=0.75 * big, height=3.2 * big, at=m.surface(host, face, uv, sink=0.3), role=role1, sides=6, tip=0.3, solo=True)
    offs = [(0.9, 0.3), (-0.8, 0.5), (0.2, -0.9), (-0.6, -0.6), (0.9, -0.6)]
    for i in range(1, n):
        du, dv = offs[i - 1]
        m.crystal(pre + str(i), radius=(0.4 + rnd.random() * 0.2) * big, height=(1.4 + rnd.random() * 1.0) * big,
                  at=m.surface(host, face, (uv[0] + du * big, uv[1] + dv * big), sink=0.3),
                  role=role2 if i % 2 else role1, sides=6, tip=0.3, solo=True,
                  rot=(rnd.uniform(-25, 25), rnd.uniform(-25, 25), 0))


def nuggets(m, specs):
    S = m.surface
    for name, host, face, uv, s, rot in specs:
        m.box(name, size=(1.6 * s, 1.4 * s, 1.1 * s), at=S(host, face, uv, sink=0.35 * s), role="gold", chamfer=0.35 * s,
              taper=0.75, rot=(0, 0, rot), solo=True)


def cracks(m, segs, role="glow"):
    S = m.surface
    for i, (host, face, a, b) in enumerate(segs):
        du, dv = b[0] - a[0], b[1] - a[1]
        m.box(f"crack{i}", size=(math.hypot(du, dv), 0.28, 0.12), at=S(host, face, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), sink=0.06),
              role=role, rot=(0, 0, math.degrees(math.atan2(dv, du))), solo=True)


def stairs(m, pre, d, s0, s1, z0, z1, n, width, role):
    """Escalier taillé qui monte vers le centre dans la direction d ((0, -1) = avant) : marche i de s0 vers s1."""
    dx, dy = d
    for i in range(n):
        si = s0 - (s0 - s1) * i / n
        depth = si - s1 + 0.3
        c = (si + s1 - 0.3) / 2
        h = (z1 - z0) * (i + 1) / n
        size = (depth, width, h + 0.05) if dx else (width, depth, h + 0.05)
        m.box(f"{pre}{i}", size=size, at=(dx * c, dy * c, z0 + h / 2 - 0.05), role=role, solo=True)


def pillar(m, pre, x, y, z0, h, shaft, cap, broken=False):
    """Pilier : socle carré, fût à 8 pans, chapiteau (sauf s'il est brisé). Renvoie la hauteur du haut."""
    m.box(pre + "b", size=(1.7, 1.7, 0.45), at=(x, y, z0 + 0.19), role=cap, chamfer=0.1, solo=True)
    m.prism(pre + "s", radius=0.62, height=h + 0.1, at=(x, y, z0 + 0.4 + h / 2), role=shaft, sides=8, solo=True)
    if broken:
        return z0 + 0.4 + h
    m.box(pre + "t", size=(1.7, 1.7, 0.45), at=(x, y, z0 + 0.4 + h + 0.2), role=cap, chamfer=0.1, solo=True)
    return z0 + 0.4 + h + 0.42


def glyphs(m, specs, role, cell=0.25):
    for host, face, uv in specs:
        m.stamp(host, face, uv, GLYPH, {"#": role}, cell=cell)


def moss(m, host, face, pts, seed, role="moss", role2="mossd"):
    for i, (uv, r) in enumerate(pts):
        m.blob(host, face, uv, r, role, rough=0.45, seed=seed + i)
        m.blob(host, face, (uv[0] + r * 0.2, uv[1] - r * 0.2), r * 0.45, role2, rough=0.45, seed=seed + 50 + i)


def rock_v1():
    m = ropilot.model("Rock_R13_V1", px=8, reset=True, symmetric=False)
    m.palette(
        stone=dict(color="#77705E", noise=0.035, mottle=("#655E4E", 0.25, 3), shade=0.18, top=0.12),
        stoned=dict(color="#565042", noise=0.035, shade=0.18, top=0.1),
        stonel=dict(color="#8C8572", noise=0.03, shade=0.12, top=0.12),
        jade=dict(color="#1E7254", noise=0.03, mottle=("#196448", 0.25, 4), shade=0.2, top=0.15),
        jaded=dict(color="#155240", noise=0.03, shade=0.18, top=0.12),
        jadel=dict(color="#2A8A68", noise=0.025, mottle=("#237A5C", 0.2, 4), shade=0.12, top=0.12),
        gem=dict(color="#34B07E", noise=0.02, shade=0.1, top=0.2),
        carve="#72C49E", stgroove="#46403A",
        moss=dict(color="#4A8A34", noise=0.04), mossd="#386E28")
    S = m.surface
    # roche brute (socle + ceinture de jade), temple à deux gradins, lobe rocheux qui porte l'arche
    m.prism("bot", radius=5.2, height=3.0, at=(0, 0, 1.5), role="stoned", sides=7, taper=1.45, turn=10)
    m.prism("mid", radius=7.6, height=3.0, at=(0, 0, 4.5), role="jade", sides=7, turn=10)
    m.prism("top", radius=7.0, height=2.0, at=(0, 0, 7.0), role="stone", sides=4, taper=0.82)
    m.prism("top2", radius=5.4, height=1.4, at=(0, 0, 8.7), role="jadel", sides=4, taper=0.85)
    m.prism("lobeB", radius=3.4, height=2.0, at=(5.6, 4.4, 1.9), role="stoned", sides=6, taper=1.4, turn=20)
    m.prism("lobeM", radius=4.6, height=2.4, at=(5.6, 4.4, 4.1), role="jade", sides=6, turn=20)
    m.prism("lobeT", radius=4.6, height=1.4, at=(5.6, 4.4, 6.0), role="stone", sides=6, taper=0.72, turn=20)
    stairs(m, "bumpS", (0, -1), 6.6, 3.0, 6.0, 9.4, 4, 2.8, "stonel")
    m.box("bumpA", size=(4.6, 3.6, 2.4), at=S("mid", "side2", (0, 0.2), sink=1.3), role="jade", chamfer=0.8, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.2, 3.4, 2.2), at=S("bot", "side4", (0.3, 0.2), sink=1.0), role="stoned", chamfer=0.7, taper=0.65)
    m.box("bumpC", size=(4.0, 3.2, 2.2), at=S("mid", "side5", (0.4, -0.3), sink=1.1), role="jaded", chamfer=0.7, taper=0.65, rot=(0, 0, -10))
    m.box("bumpD", size=(3.8, 3.0, 2.0), at=S("bot", "side1", (0, 0.3), sink=0.9), role="stoned", chamfer=0.6, taper=0.65, rot=(0, 0, 12))
    # arche sur le lobe, pilier brisé et chapiteau tombé au sommet
    top = pillar(m, "arA", 4.1, 4.4, 6.7, 2.6, "jadel", "stone")
    pillar(m, "arB", 7.1, 4.4, 6.7, 2.6, "jadel", "stone")
    m.box("arL", size=(5.0, 1.4, 0.8), at=(5.6, 4.4, top + 0.38), role="stonel", chamfer=0.15, solo=True)
    pillar(m, "plA", -1.9, 1.9, 9.4, 1.5, "jade", "stone", broken=True)
    m.box("plCap", size=(1.7, 1.7, 0.45), at=S("top2", "top", (0.6, 2.0), sink=0.05), role="stone", chamfer=0.1, rot=(0, 0, 28), solo=True)
    # éclats de jade
    for i, (host, face, uv, r, h) in enumerate([("top2", "top", (2.0, -1.6), 0.42, 1.5), ("top2", "top", (2.6, -1.0), 0.3, 1.0),
                                                 ("mid", "side0", (-2.0, 0.4), 0.36, 1.2), ("lobeT", "top", (-0.4, -1.5), 0.36, 1.2),
                                                 ("mid", "side3", (1.4, 0.3), 0.36, 1.2), ("mid", "side6", (0.6, 0.6), 0.3, 1.0)]):
        m.crystal(f"gem{i}", radius=r, height=h, at=S(host, face, uv), role="gem", sides=5, tip=0.35, solo=True)
    # gravures (motif en escalier), rainures, mousse
    glyphs(m, [("top", "side0", (-2.9, 0)), ("top", "side0", (2.9, 0)), ("top", "side1", (0, 0)),
               ("top", "side2", (0, 0)), ("top", "side3", (0, 0))], "stgroove", cell=0.2)
    glyphs(m, [("mid", "side1", (0, 0)), ("mid", "side4", (0, 0)), ("lobeM", "side3", (0, 0))], "carve")
    for i in range(4):
        m.line("top2", f"side{i}", [(-4.0, 0.1), (4.0, 0.1)], "carve", width=2)
    moss(m, "top2", "top", [((2.2, 2.2), 1.0), ((-2.4, -2.2), 0.9)], 1)
    moss(m, "lobeT", "top", [((1.0, 0.8), 0.9)], 10)
    for i in (0, 2, 3, 5, 6):
        moss(m, "mid", f"side{i}", [((1.4 if i % 2 else -1.2, 1.0), 0.9)], 20 + i)
    m.build()
    return m


def rock_v2():
    m = ropilot.model("Rock_R13_V2", px=8, reset=True, symmetric=False)
    m.palette(
        stone=dict(color="#5A5446", noise=0.035, mottle=("#4C473B", 0.25, 3), shade=0.18, top=0.12),
        stoned=dict(color="#423D33", noise=0.035, shade=0.18, top=0.1),
        stonel=dict(color="#6C6656", noise=0.03, shade=0.12, top=0.12),
        jade=dict(color="#174E3C", noise=0.03, mottle=("#124232", 0.25, 4), shade=0.2, top=0.15),
        jaded=dict(color="#103A2C", noise=0.03, shade=0.18, top=0.12),
        jadel=dict(color="#1F6048", noise=0.025, shade=0.12, top=0.12),
        carve="#5AA684", stgroove="#34302A", moss=dict(color="#4A8A34", noise=0.04), mossd="#386E28",
        vein="#E4ECF6",
        silver=dict(color="#E6EEF8", noise=0.02, shade=0.1, top=0.2),
        silverd=dict(color="#A8B8D0", noise=0.02, shade=0.1, top=0.15))
    S = m.surface
    m.prism("bot", radius=6.0, height=3.2, at=(0, 0, 1.6), role="stoned", sides=8, taper=1.42, turn=12)
    m.prism("mid", radius=9.6, height=3.4, at=(0, 0, 4.9), role="jade", sides=8, turn=12)
    m.prism("top", radius=8.6, height=2.0, at=(0, 0, 7.6), role="stone", sides=4, taper=0.82)
    m.prism("top2", radius=6.6, height=1.4, at=(0, 0, 9.3), role="jadel", sides=4, taper=0.85)
    stairs(m, "bumpS", (-1, 0), 8.0, 3.7, 6.6, 10.0, 4, 3.0, "stonel")
    m.box("bumpA", size=(4.8, 3.8, 2.6), at=S("mid", "side1", (0, 0.2), sink=1.4), role="jaded", chamfer=0.8, taper=0.65, rot=(0, 0, 12))
    m.box("bumpB", size=(4.4, 3.4, 2.4), at=S("bot", "side3", (0, 0.3), sink=1.0), role="stoned", chamfer=0.7, taper=0.65)
    m.box("bumpC", size=(4.0, 3.2, 2.2), at=S("bot", "side6", (0, 0.2), sink=1.0), role="stoned", chamfer=0.7, taper=0.65, rot=(0, 0, -15))
    cluster(m, "sA", "top2", "top", (0.6, -0.6), 2.2, "silver", "silverd", 5, 1)
    cluster(m, "sB", "mid", "side0", (0.4, 0.0), 1.5, "silver", "silverd", 4, 2)
    cluster(m, "sC", "mid", "side3", (-0.3, 0.2), 1.5, "silverd", "silver", 4, 3)
    cluster(m, "sD", "bumpA", "top", (0, 0), 1.1, "silver", "silverd", 3, 4)
    cluster(m, "sE", "mid", "side5", (0.4, 0.0), 1.4, "silver", "silverd", 4, 5)
    cluster(m, "sF", "top", "side2", (2.4, 0), 1.0, "silver", "silverd", 3, 6)
    cluster(m, "sG", "mid", "side7", (-0.4, -0.2), 1.2, "silverd", "silver", 3, 11)
    cluster(m, "sH", "top", "side0", (-2.4, 0), 1.0, "silver", "silverd", 3, 12)
    pillar(m, "plA", 2.4, 2.4, 10.0, 1.8, "jade", "stone", broken=True)
    glyphs(m, [("top", "side0", (2.4, 0)), ("top", "side1", (0, 0)), ("top", "side2", (-2.4, 0)),
               ("top", "side3", (2.6, 0))], "stgroove", cell=0.2)
    glyphs(m, [("mid", "side2", (0, 0)), ("mid", "side6", (0, 0))], "carve")
    for host, face, pts, w in [("mid", "side0", [(-3.0, -1.4), (-1.6, -0.2), (-0.8, 0.1), (0.2, 1.5)], 3),
                               ("mid", "side1", [(-3.2, 1.2), (-1.6, 0.2), (-0.6, -1.4)], 3),
                               ("mid", "side3", [(1.4, -1.4), (2.0, 0.0), (3.4, 0.8)], 3),
                               ("mid", "side4", [(-3.0, 1.0), (-1.0, 0.0), (0.4, 0.2), (3.0, -1.2)], 3),
                               ("mid", "side5", [(-3.2, -1.0), (-2.0, 0.4), (-1.6, 1.5)], 2),
                               ("mid", "side6", [(1.6, 1.4), (2.4, 0.2), (3.4, -1.2)], 3),
                               ("mid", "side7", [(1.2, 1.2), (2.4, 0.4), (3.4, 0.6)], 2),
                               ("top2", "side2", [(-2.6, -0.4), (-0.8, 0.2), (1.6, -0.2)], 2),
                               ("bot", "side1", [(-1.2, 0.6), (0.4, -0.2), (1.4, 0.2)], 2)]:
        m.line(host, face, pts, "vein", width=w)
    moss(m, "top2", "top", [((-2.4, 2.4), 0.9)], 3)
    for i in (2, 4, 6):
        moss(m, "mid", f"side{i}", [((-1.4, 1.1), 0.8)], 20 + i)
    m.build()
    return m


def rock_v3():
    m = ropilot.model("Rock_R13_V3", px=8, reset=True, symmetric=False)
    m.palette(
        stone=dict(color="#46413A", noise=0.035, mottle=("#3A3630", 0.25, 3), shade=0.18, top=0.12),
        stoned=dict(color="#332F29", noise=0.035, shade=0.18, top=0.1),
        stonel=dict(color="#57514A", noise=0.03, shade=0.12, top=0.12),
        jade=dict(color="#103A2C", noise=0.03, mottle=("#0C3024", 0.25, 4), shade=0.2, top=0.15),
        jaded=dict(color="#0B2A20", noise=0.03, shade=0.18, top=0.12),
        jadel=dict(color="#174A38", noise=0.025, shade=0.12, top=0.12),
        goldp="#E8A824",
        gold=dict(color="#FFC83A", noise=0.025, shade=0.12, top=0.25),
        goldd=dict(color="#E09A1E", noise=0.025, shade=0.12, top=0.2),
        glow=dict(color="#F0A020", glow=True))
    S = m.surface
    m.prism("bot", radius=6.6, height=3.6, at=(0, 0, 1.8), role="stoned", sides=9, taper=1.4, turn=6)
    m.prism("mid", radius=10.6, height=3.8, at=(0, 0, 5.5), role="jade", sides=9, turn=6)
    m.prism("top", radius=9.6, height=2.2, at=(0, 0, 8.5), role="stone", sides=4, taper=0.82)
    m.prism("top2", radius=7.4, height=1.6, at=(0, 0, 10.4), role="jadel", sides=4, taper=0.85)
    stairs(m, "bumpS", (0, -1), 9.0, 4.1, 7.4, 11.2, 4, 3.2, "stonel")
    m.box("bumpA", size=(5.0, 4.0, 2.8), at=S("mid", "side2", (0, 0.2), sink=1.4), role="jaded", chamfer=0.9, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.8, 3.8, 2.6), at=S("bot", "side4", (0, 0.3), sink=1.1), role="stoned", chamfer=0.8, taper=0.65)
    m.box("bumpC", size=(4.4, 3.4, 2.4), at=S("bot", "side7", (0, 0.2), sink=1.0), role="stoned", chamfer=0.7, taper=0.65, rot=(0, 0, -15))
    cluster(m, "gcA", "top2", "top", (0.4, 0.6), 2.0, "gold", "goldd", 5, 7)
    cluster(m, "gcB", "mid", "side0", (-1.6, 0.0), 1.4, "gold", "goldd", 4, 8)
    cluster(m, "gcC", "mid", "side4", (0.3, 0.2), 1.5, "goldd", "gold", 4, 9)
    cluster(m, "gcD", "bumpA", "top", (0, 0), 1.1, "gold", "goldd", 3, 10)
    cluster(m, "gcE", "mid", "side6", (0.3, -0.2), 1.3, "gold", "goldd", 4, 12)
    cluster(m, "gcF", "top", "side1", (2.4, 0), 1.0, "gold", "goldd", 3, 13)
    nuggets(m, [("n1", "top2", "top", (-2.6, -2.2), 1.3, 20), ("n2", "mid", "side1", (0.6, -0.4), 1.3, -10),
                ("n3", "mid", "side8", (0.4, 0.4), 1.2, 35), ("n4", "bumpC", "top", (0, 0), 1.0, 10),
                ("n5", "top", "side3", (-2.8, 0), 1.1, -25), ("n6", "bot", "side1", (0, 0.2), 1.0, 5),
                ("n7", "top2", "top", (2.6, -2.4), 1.0, 40)])
    cracks(m, [("mid", "side3", (-1.4, -1.3), (1.2, 1.0)), ("mid", "side5", (-1.2, 1.0), (1.4, -1.0)),
               ("mid", "side7", (-1.2, -0.9), (1.3, 1.0)), ("mid", "side8", (-2.4, 1.2), (-1.0, -1.0))])
    # or gravé : bandeaux et motifs en escalier
    for i in range(4):
        m.line("top", f"side{i}", [(-6.8, -0.8), (6.8, -0.8)], "goldp", width=3)
        m.line("top2", f"side{i}", [(-5.0, 0.2), (5.0, 0.2)], "goldp", width=2)
    glyphs(m, [("top", "side0", (-3.4, 0.3)), ("top", "side0", (3.4, 0.3)), ("top", "side1", (-2.0, 0.3)),
               ("top", "side2", (0, 0.3)), ("top", "side3", (2.0, 0.3))], "goldp", cell=0.2)
    glyphs(m, [("mid", "side2", (1.2, -0.6)), ("mid", "side7", (-2.2, 0.0))], "goldp")
    m.build()
    return m


def join_rock(c):
    col = bpy.data.collections[c]
    groups = {"_Asteroid": [], "_Ore": [], "_Glow": []}
    for o in list(col.all_objects):
        if o.type != "MESH":
            continue
        if "glow" in o.material_slots[0].material.name:
            groups["_Glow"].append(o)
        elif o.name.startswith(BODY):
            groups["_Asteroid"].append(o)
        else:
            groups["_Ore"].append(o)
    for suffix, objs in groups.items():
        if objs:
            with bpy.context.temp_override(active_object=objs[0], selected_editable_objects=objs, object=objs[0]):
                bpy.ops.object.join()
            objs[0].name = c + suffix


def build_all():
    for f in (rock_v1, rock_v2, rock_v3):
        f()
    for c in ("Rock_R13_V1", "Rock_R13_V2", "Rock_R13_V3"):
        join_rock(c)
