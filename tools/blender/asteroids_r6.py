# Astéroïdes de l'anneau 6 « The Rift » (25 nov.), au kit low-poly de Ropilot (ropilot.model, px = 8, sans
# picots : ils sont posés dans Studio sur la roche seulement, comme tools/apply-studs.lua).
# Même méthode que tools/blender/asteroids_r1.py. Zone : roche bleu nuit fendue, failles cyan lumineuses,
# éclats qui flottent au-dessus, motifs géométriques peints. Silhouette anguleuse (6 à 7 pans), coupée en deux.
#   V1 Soft Rock   : bloc bleu nuit à 6 pans, fendu : un éclat penché s'en détache le long d'une faille cyan,
#                    losanges et chevrons peints, éclats bleu clair qui flottent au-dessus de la faille
#   V2 Silver Rock : roche bleu nuit plus sombre, grosses grappes de cristaux d'argent, filons d'argent,
#                    une faille cyan et un éclat d'argent flottant
#   V3 Gold Rock   : roche bleu-noir avec un pic plat, grappes de cristaux d'or, pépites, fentes lumineuses or,
#                    une petite faille cyan sur le dessus, deux éclats d'or flottants
# Les couleurs sont plus foncées que voulu : l'import les éclaircit.
import math
import random

BODY = ("bot", "mid", "top", "lobe", "bump")


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


def slit(m, name, host, face, a, b, role="glow", w=0.28):
    # fente lumineuse : une plaque fine posée sur une face, de a vers b (coordonnées u, v de la face)
    du, dv = b[0] - a[0], b[1] - a[1]
    m.box(name, size=(math.hypot(du, dv), w, 0.12), at=m.surface(host, face, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), sink=0.06),
          role=role, rot=(0, 0, math.degrees(math.atan2(dv, du))), solo=True)


def shard(m, name, at, r, h, role, tilt=(0, 0, 0)):
    # éclat qui flotte : cristal pointu des deux côtés
    m.crystal(name, radius=r, height=h, at=at, role=role, sides=4, tip=0.45, base_tip=0.45, taper=1.0, rot=tilt, solo=True)


def rock_v1():
    m = ropilot.model("Rock_R6_V1", px=8, reset=True, symmetric=False)
    m.palette(
        rift=dict(color="#24315A", noise=0.03, mottle=("#1C2850", 0.2, 4), shade=0.2, top=0.15),
        riftd=dict(color="#18213F", noise=0.03, shade=0.18, top=0.12),
        riftl=dict(color="#31437A", noise=0.025, shade=0.12, top=0.14),
        line="#5E80DA", lined="#4562B0",
        shardc=dict(color="#6C8CE8", noise=0.02, shade=0.1, top=0.25),
        glow=dict(color="#18C8E8", glow=True))
    S = m.surface
    m.prism("bot", radius=5.0, height=3.0, at=(0, 0, 1.5), role="riftd", sides=6, taper=1.45, turn=10)
    m.prism("mid", radius=7.2, height=3.4, at=(0, 0, 4.7), role="rift", sides=6, taper=1.0, turn=10)
    m.prism("top", radius=7.2, height=2.8, at=(0, 0, 7.8), role="riftl", sides=6, taper=0.66, turn=10, shear=(0.6, 0.5))
    # l'éclat qui se détache, penché vers l'extérieur
    m.prism("lobeB", radius=2.8, height=2.4, at=(-7.6, -5.7, 1.75), role="riftd", sides=5, taper=1.4, turn=20, rot=(8, -11, 0))
    m.prism("lobeM", radius=3.9, height=2.6, at=(-7.9, -5.9, 4.15), role="rift", sides=5, taper=1.0, turn=20, rot=(8, -11, 0))
    m.prism("lobeT", radius=3.9, height=2.0, at=(-8.3, -6.2, 6.35), role="riftl", sides=5, taper=0.55, turn=20, rot=(8, -11, 0))
    m.box("bumpA", size=(5.0, 4.2, 2.6), at=S("mid", "side1", (0, 0.3), sink=1.6), role="rift", chamfer=0.8, taper=0.6, rot=(0, 0, 20))
    m.box("bumpB", size=(4.4, 3.6, 2.4), at=S("mid", "side3", (0.4, -0.5), sink=1.4), role="riftd", chamfer=0.7, taper=0.6, rot=(0, 0, -15))
    m.box("bumpC", size=(4.4, 3.6, 2.0), at=S("top", "top", (2.2, 1.6), sink=1.2), role="riftl", chamfer=0.7, taper=0.55, rot=(0, 0, 30))
    # la faille entre le bloc et l'éclat : une lame cyan au fond de la fente
    m.box("fault", size=(2.6, 3.6, 5.0), at=(-5.0, -3.75, 3.4), role="glow", rot=(0, 0, -143), solo=True)
    # la faille continue en zigzag sur le dessus et sur les flancs
    slit(m, "crack0", "top", "top", (-3.6, -2.6), (-2.0, -0.6), w=0.36)
    slit(m, "crack1", "top", "top", (-2.0, -0.6), (-2.6, 1.0), w=0.36)
    slit(m, "crack2", "top", "top", (-2.6, 1.0), (-1.0, 2.6), w=0.3)
    slit(m, "crack3", "mid", "side2", (-1.8, -1.2), (-0.2, 0.4))
    slit(m, "crack4", "mid", "side2", (-0.2, 0.4), (1.4, -0.2))
    slit(m, "crack5", "mid", "side4", (-1.2, 1.0), (1.4, -0.9))
    # éclats qui flottent au-dessus de la faille
    shard(m, "fl0", (-4.6, -3.4, 9.6), 0.6, 2.0, "shardc", (15, 10, 0))
    shard(m, "fl1", (-2.8, -4.6, 8.8), 0.42, 1.4, "shardc", (-20, 15, 0))
    shard(m, "fl2", (-6.2, -1.8, 9.2), 0.36, 1.2, "shardc", (10, -25, 0))
    for i, (host, face, uv, r, h) in enumerate([("top", "top", (1.2, -1.6), 0.4, 1.4), ("top", "top", (1.8, -2.3), 0.28, 0.9),
                                                ("lobeT", "top", (0.2, 0.3), 0.35, 1.2), ("bumpA", "top", (0.5, 0.2), 0.3, 1.0)]):
        m.crystal(f"sp{i}", radius=r, height=h, at=S(host, face, uv), role="shardc", sides=4, tip=0.45, solo=True)
    m.build()
    # motifs géométriques : losanges et chevrons
    def diamond(part, face, c, r, col):
        x, y = c
        m.line(part, face, [(x - r, y), (x, y + r), (x + r, y), (x, y - r), (x - r, y)], col, width=2)
    diamond("top", "top", (-0.4, 2.4), 1.2, "line")
    diamond("top", "top", (-0.4, 2.4), 0.5, "lined")
    diamond("mid", "side0", (0.2, 0.1), 1.1, "line")
    diamond("mid", "side5", (-0.3, 0.2), 0.9, "line")
    m.line("mid", "side2", [(-2.4, -0.2), (-1.6, 0.6), (-0.8, -0.2)], "lined", width=2)
    m.line("mid", "side4", [(0.4, 0.8), (1.2, 1.6), (2.0, 0.8)], "lined", width=2)
    diamond("lobeM", "side2", (0, 0.1), 0.8, "line")
    return m


def rock_v2():
    m = ropilot.model("Rock_R6_V2", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#1F2A4E", noise=0.03, mottle=("#182243", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#151C36", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#2B3A69", noise=0.025, shade=0.12, top=0.14),
        line="#4A66B8",
        vein="#E4ECF6",
        silver=dict(color="#E6EEF8", noise=0.02, shade=0.1, top=0.2),
        silverd=dict(color="#A8B8D0", noise=0.02, shade=0.1, top=0.15),
        glow=dict(color="#18C8E8", glow=True))
    S = m.surface
    # bloc à 7 pans, dessus en plateau penché, une marche taillée sur le côté
    m.prism("bot", radius=5.8, height=3.2, at=(0, 0, 1.6), role="rockd", sides=7, taper=1.4, turn=12)
    m.prism("mid", radius=8.1, height=3.8, at=(0, 0, 5.1), role="rock", sides=7, taper=1.0, turn=12)
    m.prism("top", radius=8.1, height=3.0, at=(0, 0, 8.5), role="rockl", sides=7, taper=0.64, turn=12, shear=(-0.9, 0.5))
    m.box("bumpA", size=(5.6, 4.6, 3.0), at=S("mid", "side2", (0, 0.2), sink=1.5), role="rock", chamfer=0.8, taper=0.6, rot=(0, 0, 15))
    m.box("bumpB", size=(5.0, 4.0, 2.4), at=S("top", "side5", (0.3, -0.2), sink=1.2), role="rockl", chamfer=0.7, taper=0.6)
    m.box("bumpC", size=(4.4, 3.6, 2.4), at=S("bot", "side4", (0, 0.3), sink=1.0), role="rockd", chamfer=0.6, taper=0.6)
    cluster(m, "sA", "top", "top", (1.0, -0.6), 2.1, "silver", "silverd", 5, 1)
    cluster(m, "sB", "mid", "side0", (0.5, 0.0), 1.5, "silver", "silverd", 4, 2)
    cluster(m, "sC", "mid", "side4", (-0.4, 0.3), 1.4, "silverd", "silver", 4, 3)
    cluster(m, "sD", "bumpA", "top", (0, 0), 1.1, "silver", "silverd", 3, 4)
    cluster(m, "sE", "top", "side6", (0, 0), 1.1, "silver", "silverd", 3, 5)
    cluster(m, "sG", "mid", "side2", (0.7, -0.3), 1.0, "silverd", "silver", 3, 11)
    # la faille cyan de la zone, en zigzag sur le dessus et un flanc
    slit(m, "crack0", "top", "top", (-4.0, 1.6), (-2.4, 0.2), w=0.34)
    slit(m, "crack1", "top", "top", (-2.4, 0.2), (-2.8, -1.6), w=0.34)
    slit(m, "crack2", "mid", "side3", (-1.6, 1.0), (0.0, -0.4))
    slit(m, "crack3", "mid", "side3", (0.0, -0.4), (1.4, 0.6))
    # éclats d'argent qui flottent
    shard(m, "fl0", (-3.4, 1.2, 12.6), 0.7, 2.2, "silver", (15, -10, 0))
    shard(m, "fl1", (-5.2, -0.6, 11.4), 0.45, 1.5, "silverd", (-20, 20, 0))
    m.build()
    m.line("mid", "side1", [(-2, -1.5), (-0.6, -0.2), (0.4, 0.1), (1.8, 1.4)], "vein", width=3)
    m.line("mid", "side5", [(-1.8, 1.2), (-0.4, 0.2), (1.6, -0.8)], "vein", width=3)
    m.line("mid", "side6", [(-1.6, -1.2), (0, 0), (0.8, 1.4)], "vein", width=2)
    m.line("top", "side1", [(-1.2, -0.8), (0.2, 0.2), (1.2, 0.5)], "vein", width=2)
    m.line("top", "side3", [(-1.4, 0.4), (0, -0.2), (1.2, 0.4)], "line", width=2)
    m.line("top", "top", [(2.4, 2.6), (3.4, 1.6), (4.4, 2.6)], "line", width=2)
    return m


def rock_v3():
    m = ropilot.model("Rock_R6_V3", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#1A2240", noise=0.03, mottle=("#141B34", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#10162C", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#253259", noise=0.025, shade=0.12, top=0.14),
        line="#3E58A6",
        gold=dict(color="#FFC83A", noise=0.025, shade=0.12, top=0.25),
        goldd=dict(color="#E09A1E", noise=0.025, shade=0.12, top=0.2),
        glow=dict(color="#F0A020", glow=True),
        glowc=dict(color="#18C8E8", glow=True))
    S = m.surface
    # gros bloc à 7 pans, dessus en plateau avec un ressaut (pic plat) d'un côté
    m.prism("bot", radius=6.4, height=3.6, at=(0, 0, 1.8), role="rockd", sides=7, taper=1.4, turn=30)
    m.prism("mid", radius=9.0, height=4.4, at=(0, 0, 5.8), role="rock", sides=7, taper=1.0, turn=30)
    m.prism("top", radius=9.0, height=3.6, at=(0, 0, 9.8), role="rockl", sides=7, taper=0.6, turn=30, shear=(0.7, 0.7))
    m.prism("lobeP", radius=3.0, height=3.0, at=(-2.8, 2.6, 12.4), role="rockl", sides=5, taper=0.5, turn=10, rot=(-8, -10, 0))
    m.box("bumpA", size=(6, 4.8, 3.2), at=S("mid", "side3", (0, 0.2), sink=1.5), role="rock", chamfer=0.9, taper=0.6, rot=(0, 0, 15))
    m.box("bumpB", size=(5.2, 4.2, 2.6), at=S("top", "side6", (0.3, -0.2), sink=1.2), role="rockl", chamfer=0.8, taper=0.6)
    m.box("bumpC", size=(4.6, 3.6, 2.6), at=S("bot", "side5", (0, 0.3), sink=1.1), role="rockd", chamfer=0.7, taper=0.6)
    cluster(m, "gA", "top", "top", (1.4, -1.0), 1.8, "gold", "goldd", 5, 7)
    cluster(m, "gB", "mid", "side0", (0.4, 0.1), 1.4, "gold", "goldd", 4, 8)
    cluster(m, "gC", "mid", "side4", (-0.3, 0.2), 1.3, "goldd", "gold", 4, 9)
    cluster(m, "gD", "mid", "side6", (0.2, -0.2), 1.1, "gold", "goldd", 3, 10)
    cluster(m, "gE", "lobeP", "top", (0, 0), 0.8, "gold", "goldd", 3, 12)
    for name, host, face, uv, s, rot in [("n1", "top", "top", (3.2, 1.6), 1.5, 20), ("n2", "mid", "side2", (-0.6, -0.4), 1.3, -10),
                                         ("n3", "mid", "side5", (0.5, 0.6), 1.2, 35), ("n4", "bumpA", "top", (0, 0), 1.1, 10),
                                         ("n5", "top", "side3", (0, 0), 1.2, -25), ("n6", "bot", "side1", (0, 0.2), 1.0, 5)]:
        m.box(name, size=(1.6 * s, 1.4 * s, 1.1 * s), at=S(host, face, uv, sink=0.35 * s), role="gold", chamfer=0.35 * s, taper=0.75, rot=(0, 0, rot), solo=True)
    # fentes lumineuses : or sur les flancs, une petite faille cyan de la zone sur le dessus
    slit(m, "crack0", "mid", "side1", (-1.5, -1.2), (0.0, 0.2))
    slit(m, "crack1", "mid", "side1", (0.0, 0.2), (1.4, 1.3))
    slit(m, "crack2", "mid", "side3", (-1.4, 1.0), (1.5, -0.9))
    slit(m, "crack3", "mid", "side5", (-1.2, -0.8), (1.3, 0.9))
    slit(m, "crack4", "top", "top", (-1.2, -3.2), (0.4, -1.6), role="glowc", w=0.34)
    slit(m, "crack5", "top", "top", (0.4, -1.6), (-0.2, 0.0), role="glowc", w=0.34)
    # éclat d'or qui flotte
    shard(m, "fl0", (-1.0, 0.4, 15.4), 0.7, 2.2, "gold", (15, 10, 0))
    shard(m, "fl1", (-4.6, 0.6, 14.0), 0.45, 1.4, "goldd", (-20, -15, 0))
    m.build()
    m.line("mid", "side2", [(-2.0, 1.4), (-1.0, 0.4), (0.0, 1.4)], "line", width=2)
    m.line("mid", "side6", [(-1.6, -1.4), (-0.6, -0.4), (0.4, -1.4)], "line", width=2)
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
        f().build()
    for c in ("Rock_R6_V1", "Rock_R6_V2", "Rock_R6_V3"):
        join_rock(c)
