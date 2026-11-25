# Astéroïdes de l'anneau 12 « Mushroom Moon » (25 nov.), au kit low-poly de Ropilot (ropilot.model, px = 8,
# sans picots : ils sont posés dans Studio sur la roche seulement). Même méthode que asteroids_r1.py.
# Silhouette propre à l'anneau : petite lune à 8-9 pans au dôme haut, champignons qui dépassent du dessus.
#   V1 Soft Rock   : lune violette à deux lobes, plaques de mousse verte, cratères, butte moussue, amanites
#                    rouges à pois blancs, champignons violets, petits champignons à chapeau turquoise lumineux (néon)
#   V2 Silver Rock : roche violet sombre, grosses grappes de cristaux d'argent, filons d'argent, une amanite,
#                    deux champignons turquoise lumineux (néon), mousse
#   V3 Gold Rock   : roche violet très sombre, grappes de cristaux d'or, pépites, fentes lumineuses orange (néon),
#                    une amanite, un champignon violet, mousse
# Attention au kit : la peinture est appliquée au build() suivant et s'accumule ; peindre puis construire.
# À lancer avec ropilot_blender_run_python, puis join_rock() par collection (_Asteroid, _Ore, _Glow),
# ropilot_blender_import et réglage dans Studio (voir asteroids_r1.py). Couleurs plus foncées que voulu.
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


def shroom(m, pre, host, face, uv, s, cap, stem="stem", dots=None, sides=8):
    """Champignon : pied crème, chapeau en tronc de pyramide ; pois peints si dots (amanite)."""
    S = m.surface
    h = 1.5 * s
    m.prism(pre + "s", radius=0.36 * s, height=h + 0.2, at=S(host, face, uv, sink=0.2), role=stem, sides=6, taper=0.85, solo=True)
    m.prism(pre + "c", radius=1.15 * s, height=0.8 * s, at=S(host, face, uv, sink=-(h - 0.25 * s)), role=cap, sides=sides, taper=0.38, solo=True)
    if dots:
        for i in range(0, sides, 2):
            m.circle(pre + "c", f"side{i}", (0.15 * s * (1 if i % 4 else -1), -0.05 * s), 0.17 * s + 0.05, dots)
        m.circle(pre + "c", "top", (0, 0), 0.16 * s + 0.05, dots)


def moss(m, host, face, pts, seed, role="moss", role2="mossd"):
    for i, (uv, r) in enumerate(pts):
        m.blob(host, face, uv, r, role, rough=0.45, seed=seed + i)
        m.blob(host, face, (uv[0] + r * 0.2, uv[1] - r * 0.2), r * 0.45, role2, rough=0.45, seed=seed + 50 + i)


def rock_v1():
    m = ropilot.model("Rock_R12_V1", px=8, reset=True, symmetric=False)
    m.palette(
        moon=dict(color="#5E4282", noise=0.03, mottle=("#503672", 0.22, 4), shade=0.2, top=0.15),
        moond=dict(color="#432E60", noise=0.03, shade=0.18, top=0.12),
        moonl=dict(color="#74569A", noise=0.025, shade=0.12, top=0.12),
        crater=dict(color="#4A3268", noise=0.03), craterd="#33224A",
        moss=dict(color="#4E9A3A", noise=0.04), mossd="#3A7A2C",
        mossg=dict(color="#4E9A3A", noise=0.05, mottle=("#3A7A2C", 0.3, 3), shade=0.12, top=0.12),
        stem=dict(color="#E6D8C0", noise=0.02, shade=0.12),
        red=dict(color="#C4262E", noise=0.02, shade=0.12, top=0.12),
        violet=dict(color="#8A44C8", noise=0.02, shade=0.12, top=0.12),
        dot="#F4ECE0", glow=dict(color="#18C8C0", glow=True))
    S = m.surface
    m.prism("bot", radius=5.0, height=3.0, at=(0, 0, 1.5), role="moond", sides=8, taper=1.45, turn=12)
    m.prism("mid", radius=7.4, height=3.2, at=(0, 0, 4.6), role="moon", sides=8, taper=1.0, turn=12)
    m.prism("top", radius=7.4, height=3.2, at=(0, 0, 7.8), role="moonl", sides=8, taper=0.58, turn=12, shear=(-0.6, 0.5))
    m.prism("lobeB", radius=3.2, height=2.2, at=(-4.6, -4.4, 1.9), role="moond", sides=7, taper=1.4, turn=20)
    m.prism("lobeM", radius=4.4, height=2.2, at=(-4.6, -4.4, 4.1), role="moon", sides=7, taper=1.0, turn=20)
    m.prism("lobeT", radius=4.4, height=2.0, at=(-4.6, -4.4, 6.2), role="moonl", sides=7, taper=0.6, turn=20, shear=(-0.3, -0.3))
    m.box("bumpA", size=(5.2, 4.2, 2.8), at=S("mid", "side2", (0, 0.2), sink=1.4), role="moon", chamfer=0.9, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.4, 3.6, 2.2), at=S("bot", "side6", (0, 0.3), sink=1.0), role="moond", chamfer=0.7, taper=0.65)
    m.box("bumpC", size=(4.6, 3.6, 2.0), at=S("top", "top", (2.0, 1.6), sink=1.0), role="mossg", chamfer=0.8, taper=0.6, rot=(0, 0, 30))
    m.box("bumpD", size=(4.0, 3.2, 2.2), at=S("mid", "side5", (0.5, -0.3), sink=1.1), role="moon", chamfer=0.7, taper=0.65, rot=(0, 0, -20))
    shroom(m, "amA", "top", "top", (-1.2, -1.0), 1.8, "red", dots="dot")
    shroom(m, "amB", "top", "top", (0.9, -2.4), 0.9, "red", dots="dot")
    shroom(m, "amC", "lobeT", "top", (0.4, 0.2), 1.1, "red", dots="dot")
    shroom(m, "viA", "bumpC", "top", (0, 0), 0.9, "violet")
    shroom(m, "viB", "top", "top", (-3.0, 1.4), 0.8, "violet")
    for i, (host, face, uv, s) in enumerate([("mid", "side1", (0.6, 0.2), 0.8), ("mid", "side1", (-0.7, -0.4), 0.61),
                                              ("lobeM", "side3", (0, 0), 0.72), ("mid", "side6", (-0.5, 0.1), 0.72),
                                              ("top", "top", (2.8, -1.2), 0.72), ("lobeT", "top", (-1.4, -0.8), 0.65)]):
        shroom(m, f"gl{i}", host, face, uv, s, "glow", sides=6)
    moss(m, "top", "top", [((-1.6, 2.4), 1.6), ((2.4, -0.6), 1.2), ((-3.2, -1.6), 1.0)], 1)
    for i in range(8):
        moss(m, "top", f"side{i}", [((0.4 if i % 2 else -0.6, 0.6), 1.0)], 10 + i)
        m.blob("mid", f"side{i}", (-0.8 if i % 2 else 0.9, 1.2), 0.8, "moss", rough=0.45, seed=30 + i)
    moss(m, "lobeT", "top", [((0.8, -1.2), 1.0)], 40)

    def crater(part, face, at, r):
        m.circle(part, face, at, r, "crater")
        m.circle(part, face, (at[0] + r * 0.08, at[1] - r * 0.1), r * 0.72, "craterd")
        m.circle(part, face, (at[0] - r * 0.25, at[1] + r * 0.3), r * 0.22, "moonl")
    crater("mid", "side3", (0.4, -0.4), 1.0)
    crater("mid", "side7", (-0.5, -0.2), 1.1)
    crater("mid", "side0", (0.6, -0.5), 0.8)
    crater("lobeM", "side5", (0, -0.2), 0.8)
    crater("top", "top", (1.2, 2.4), 0.8)
    m.build()
    return m


def rock_v2():
    m = ropilot.model("Rock_R12_V2", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#463462", noise=0.03, mottle=("#3A2A54", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#322444", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#584276", noise=0.025, shade=0.12, top=0.12),
        moss=dict(color="#4A9238", noise=0.04), mossd="#36722A",
        stem=dict(color="#E6D8C0", noise=0.02, shade=0.12),
        red=dict(color="#C4262E", noise=0.02, shade=0.12, top=0.12), dot="#F4ECE0",
        vein="#E4ECF6",
        silver=dict(color="#E6EEF8", noise=0.02, shade=0.1, top=0.2),
        silverd=dict(color="#A8B8D0", noise=0.02, shade=0.1, top=0.15),
        glow=dict(color="#18C8C0", glow=True))
    S = m.surface
    m.prism("bot", radius=5.6, height=3.2, at=(0, 0, 1.6), role="rockd", sides=8, taper=1.42, turn=20)
    m.prism("mid", radius=8.0, height=3.6, at=(0, 0, 5.0), role="rock", sides=8, taper=1.0, turn=20)
    m.prism("top", radius=8.0, height=3.4, at=(0, 0, 8.5), role="rockl", sides=8, taper=0.56, turn=20, shear=(0.7, -0.5))
    m.box("bumpA", size=(5.4, 4.4, 3.0), at=S("mid", "side2", (0, 0.2), sink=1.4), role="rock", chamfer=0.9, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.8, 4, 2.4), at=S("top", "side5", (0.3, -0.2), sink=1.1), role="rockl", chamfer=0.8, taper=0.65)
    m.box("bumpC", size=(4.2, 3.4, 2.4), at=S("bot", "side6", (0, 0.3), sink=1.0), role="rockd", chamfer=0.7, taper=0.65)
    cluster(m, "sA", "top", "top", (0.8, -0.4), 2.2, "silver", "silverd", 5, 1)
    cluster(m, "sB", "mid", "side0", (0.5, 0.0), 1.5, "silver", "silverd", 4, 2)
    cluster(m, "sC", "mid", "side4", (-0.4, 0.2), 1.4, "silverd", "silver", 4, 3)
    cluster(m, "sD", "bumpA", "top", (0, 0), 1.1, "silver", "silverd", 3, 4)
    cluster(m, "sE", "top", "side7", (0, 0), 1.1, "silver", "silverd", 3, 5)
    cluster(m, "sG", "mid", "side6", (0.6, -0.2), 1.1, "silverd", "silver", 3, 11)
    cluster(m, "sH", "top", "side2", (0, 0), 1.1, "silver", "silverd", 3, 12)
    shroom(m, "amA", "top", "top", (-2.8, 1.6), 1.1, "red", dots="dot")
    shroom(m, "gl0", "mid", "side1", (0.4, 0.0), 0.75, "glow", sides=6)
    shroom(m, "gl1", "top", "top", (-3.2, -1.2), 0.7, "glow", sides=6)
    moss(m, "top", "top", [((-2.4, 2.4), 1.4), ((-3.4, -1.6), 1.0)], 3)
    for i in (1, 3, 5, 6):
        moss(m, "top", f"side{i}", [((0.6 if i % 2 else -0.6, 0.6), 0.9)], 20 + i)
    m.line("mid", "side1", [(-2, -1.4), (-0.6, -0.2), (0.4, 0.1), (1.8, 1.2)], "vein", width=3)
    m.line("mid", "side3", [(-1.8, 1.2), (-0.4, 0.2), (1.6, -0.8)], "vein", width=3)
    m.line("mid", "side5", [(-1.6, -1.2), (0, 0), (0.8, 1.4)], "vein", width=2)
    m.line("mid", "side7", [(-1.6, 0.8), (0, 0.2), (1.6, -1)], "vein", width=3)
    m.line("top", "side3", [(-1.2, -0.8), (0.2, 0.2), (1.2, 0.5)], "vein", width=2)
    m.line("bot", "side2", [(-1.2, 0.6), (0.4, -0.2), (1.4, 0.2)], "vein", width=2)
    m.build()
    return m


def rock_v3():
    m = ropilot.model("Rock_R12_V3", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#3C2A52", noise=0.03, mottle=("#30223F", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#2A1E3A", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#4C3866", noise=0.025, shade=0.12, top=0.12),
        moss=dict(color="#4A9238", noise=0.04), mossd="#36722A",
        stem=dict(color="#E6D8C0", noise=0.02, shade=0.12),
        red=dict(color="#C4262E", noise=0.02, shade=0.12, top=0.12), dot="#F4ECE0",
        violet=dict(color="#8A44C8", noise=0.02, shade=0.12, top=0.12),
        gold=dict(color="#FFC83A", noise=0.025, shade=0.12, top=0.25),
        goldd=dict(color="#E09A1E", noise=0.025, shade=0.12, top=0.2),
        glow=dict(color="#F0A020", glow=True))
    S = m.surface
    m.prism("bot", radius=6.4, height=3.6, at=(0, 0, 1.8), role="rockd", sides=9, taper=1.4, turn=5)
    m.prism("mid", radius=9.0, height=4.2, at=(0, 0, 5.7), role="rock", sides=9, taper=1.0, turn=5)
    m.prism("top", radius=9.0, height=3.6, at=(0, 0, 9.6), role="rockl", sides=9, taper=0.56, turn=5, shear=(-0.6, -0.7))
    m.box("bumpA", size=(6, 4.8, 3.2), at=S("mid", "side3", (0, 0.2), sink=1.5), role="rock", chamfer=1.0, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(5.2, 4.2, 2.6), at=S("top", "side7", (0.3, -0.2), sink=1.2), role="rockl", chamfer=0.9, taper=0.65)
    m.box("bumpC", size=(4.6, 3.6, 2.6), at=S("bot", "side5", (0, 0.3), sink=1.1), role="rockd", chamfer=0.8, taper=0.65)
    cluster(m, "gcA", "top", "top", (0.6, 0.4), 1.9, "gold", "goldd", 5, 7)
    cluster(m, "gcB", "mid", "side0", (0.4, 0.1), 1.4, "gold", "goldd", 4, 8)
    cluster(m, "gcC", "mid", "side5", (-0.3, 0.2), 1.3, "goldd", "gold", 4, 9)
    cluster(m, "gcD", "bumpA", "top", (0, 0), 1.1, "gold", "goldd", 3, 10)
    cluster(m, "gcE", "top", "side2", (0, 0), 1.0, "gold", "goldd", 3, 12)
    cluster(m, "gcF", "mid", "side7", (0.3, -0.2), 1.2, "gold", "goldd", 4, 13)
    nuggets(m, [("n1", "top", "top", (2.8, -2.0), 1.5, 20), ("n2", "mid", "side2", (-0.6, -0.4), 1.3, -10),
                ("n3", "mid", "side8", (0.5, 0.6), 1.2, 35), ("n4", "bumpC", "top", (0, 0), 1.0, 10),
                ("n5", "top", "side4", (0, 0), 1.2, -25), ("n6", "bot", "side1", (0, 0.2), 1.0, 5),
                ("n7", "top", "top", (-1.2, -3.0), 1.1, 40)])
    cracks(m, [("mid", "side1", (-1.5, -1.2), (1.4, 1.1)), ("mid", "side4", (-1.4, 1.0), (1.5, -0.9)),
               ("mid", "side6", (-1.2, -0.8), (1.3, 0.9)), ("top", "side0", (-1.0, -0.3), (1.0, 0.3))])
    shroom(m, "amA", "top", "top", (-3.0, 1.0), 1.2, "red", dots="dot")
    shroom(m, "viA", "top", "top", (-2.6, -1.8), 0.8, "violet")
    moss(m, "top", "top", [((-2.6, 0.6), 1.6), ((3.0, 1.8), 1.0)], 5)
    for i in (1, 3, 6, 8):
        moss(m, "top", f"side{i}", [((0.6 if i % 2 else -0.6, 0.6), 0.9)], 30 + i)
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
    for c in ("Rock_R12_V1", "Rock_R12_V2", "Rock_R12_V3"):
        join_rock(c)
