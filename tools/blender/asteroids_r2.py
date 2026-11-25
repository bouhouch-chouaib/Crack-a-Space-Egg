# Astéroïdes de l'anneau 2 « Ice Ring » (25 nov.), au kit low-poly de Ropilot (ropilot.model, px = 8, sans
# picots : ils sont posés dans Studio sur la roche seulement), même méthode que asteroids_r1.py.
# Silhouette propre à l'anneau : bloc de glace à 6 pans presque droit, plateau de neige plat qui déborde
# (croûte de neige) avec des glaçons qui pendent dessous, et une aiguille de glace sur le côté.
#   V1 Soft Rock   : bloc de glace bleu pâle, plateau de neige tassée, croûte qui déborde, glaçons, givre peint,
#                    second lobe en aiguille de glace, petits cristaux de glace
#   V2 Silver Rock : glace bleu profond, neige en plaques, filons d'argent peints, grosses grappes de cristaux
#                    d'argent prises dans la glace, quelques glaçons
#   V3 Gold Rock   : glace bleu nuit, grappes de cristaux d'or, pépites, fentes lumineuses orange (néon),
#                    croûte de neige et glaçons
# À lancer avec ropilot_blender_run_python (exec dans un espace de noms à part), puis build_all().
# Chaque collection est fusionnée en « _Asteroid » (roche), « _Ore » (décor) et « _Glow » (néon).
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


def icicles(m, pre, crust, r, angles, sides, turn, cx=0.0, cy=0.0, seed=1, role="icicle"):
    # glaçons qui pendent sous la croûte de neige : posés sur sa face du dessous, au milieu de chaque pan
    rnd = random.Random(seed)
    k = 0
    for i in angles:
        a = math.radians(turn + (i + 0.5) * 360.0 / sides)
        for j, off in enumerate((-0.28, 0.0, 0.3)):
            b = a + off * 2 * math.pi / sides
            u, v = cx + r * math.cos(b), -(cy + r * math.sin(b))
            m.crystal(f"{pre}{k}", radius=0.24 + rnd.random() * 0.12, height=(1.0 + rnd.random() * 0.8) * (1.4 if j == 1 else 1.0),
                      at=m.surface(crust, "bottom", (u, v), sink=0.1), role=role, sides=5, tip=0.5, solo=True)
            k += 1


def rock_v1():
    m = ropilot.model("Rock_R2_V1", px=8, reset=True, symmetric=False)
    m.palette(
        ice=dict(color="#6E9FC8", noise=0.03, mottle=("#5C8DB8", 0.2, 4), shade=0.2, top=0.15),
        iced=dict(color="#4F7DA8", noise=0.03, shade=0.18, top=0.12),
        icel=dict(color="#8DB8DA", noise=0.025, shade=0.12, top=0.15),
        snow=dict(color="#D6E2EE", noise=0.025, mottle=("#C4D4E6", 0.2, 4), shade=0.12, top=0.1),
        frost="#BFD6EA", crack="#3E6890",
        icicle=dict(color="#A6D2EE", noise=0.02, shade=0.1, top=0.2),
        shard=dict(color="#7FC4EA", noise=0.02, shade=0.1, top=0.2))
    S = m.surface
    m.prism("bot", radius=5.2, height=2.6, at=(0, 0, 1.3), role="iced", sides=6, taper=1.4, turn=0)
    m.prism("mid", radius=7.3, height=3.4, at=(0, 0, 4.3), role="ice", sides=6, taper=0.96, turn=0, shear=(0.3, -0.2))
    m.prism("top", radius=7.0, height=2.2, at=(0.3, -0.2, 7.1), role="icel", sides=6, taper=0.9, turn=0, shear=(0.2, -0.1))
    m.prism("topcrust", radius=7.1, height=0.6, at=(0.5, -0.3, 8.5), role="snow", sides=6, taper=0.92, turn=0)
    m.prism("lobeB", radius=3.4, height=2.2, at=(-5.6, 3.6, 1.6), role="iced", sides=5, taper=1.35, turn=15)
    m.prism("lobeM", radius=4.4, height=2.6, at=(-5.6, 3.6, 4.0), role="ice", sides=5, taper=0.9, turn=15)
    m.prism("lobeT", radius=4.0, height=1.8, at=(-5.6, 3.6, 6.2), role="icel", sides=5, taper=0.55, turn=15, shear=(-0.5, 0.4))
    m.prism("lobecap", radius=2.6, height=0.5, at=(-6.1, 4.0, 7.3), role="snow", sides=5, taper=0.85, turn=15)
    m.box("bumpA", size=(5.0, 4.2, 2.8), at=S("mid", "side0", (0, 0.0), sink=1.3), role="ice", chamfer=0.8, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.6, 3.6, 2.4), at=S("mid", "side4", (0.4, -0.4), sink=1.2), role="iced", chamfer=0.7, taper=0.65, rot=(0, 0, -15))
    m.box("bumpC", size=(4.0, 3.2, 2.2), at=S("bot", "side2", (0, 0.3), sink=1.0), role="iced", chamfer=0.7, taper=0.65)
    m.prism("drift1", radius=2.6, height=1.2, at=S("topcrust", "top", (-1.8, 1.6), sink=0.5), role="snow", sides=7, taper=0.5, shear=(0.3, 0.2))
    m.prism("drift2", radius=1.7, height=0.8, at=S("topcrust", "top", (2.4, 2.2), sink=0.4), role="snow", sides=6, taper=0.5, turn=20)
    icicles(m, "ic", "topcrust", 6.0, [0, 1, 2, 3, 4, 5], 6, 0, seed=3)
    shards = [("topcrust", "top", (2.2, -1.8), 0.45, 1.6), ("topcrust", "top", (2.9, -1.0), 0.3, 1.0), ("topcrust", "top", (1.5, -2.6), 0.28, 0.9),
              ("mid", "side1", (0.9, 0.3), 0.34, 1.2), ("bumpA", "top", (0.5, 0.2), 0.3, 1.0), ("mid", "side3", (-0.8, 0.5), 0.32, 1.1),
              ("lobecap", "top", (0.3, 0.2), 0.4, 1.4), ("lobecap", "top", (-0.5, -0.4), 0.28, 0.9)]
    for i, (host, face, uv, r, h) in enumerate(shards):
        m.crystal(f"shard{i}", radius=r, height=h, at=S(host, face, uv), role="shard", sides=5, tip=0.35, solo=True)
    m.build()
    m.line("mid", "side1", [(-1.6, -1.0), (-0.4, 0.0), (0.4, -0.2), (1.4, 0.9)], "crack", width=2)
    m.line("mid", "side5", [(-1.2, 0.8), (0.0, -0.2), (1.2, -1.0)], "crack", width=2)
    m.line("top", "side3", [(-1.4, -0.5), (0.2, 0.1), (1.2, -0.3)], "crack", width=2)
    m.blob("mid", "side3", (0.6, -0.8), 0.8, "frost", seed=2)
    m.blob("mid", "side2", (-1.2, 0.6), 0.6, "frost", seed=7)
    m.blob("lobeM", "side1", (0, 0.4), 0.7, "frost", seed=4)
    m.blob("topcrust", "top", (-2.6, -1.8), 1.1, "#C4D4E6", seed=5)
    return m


def rock_v2():
    m = ropilot.model("Rock_R2_V2", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#41698F", noise=0.03, mottle=("#365C80", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#2F5174", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#5682A8", noise=0.025, shade=0.12, top=0.12),
        snow=dict(color="#D2DEEA", noise=0.025, shade=0.12, top=0.1),
        vein="#E4ECF6",
        icicle=dict(color="#9CCBEA", noise=0.02, shade=0.1, top=0.2),
        silver=dict(color="#E6EEF8", noise=0.02, shade=0.1, top=0.2),
        silverd=dict(color="#A8B8D0", noise=0.02, shade=0.1, top=0.15))
    S = m.surface
    m.prism("bot", radius=5.8, height=3.0, at=(0, 0, 1.5), role="rockd", sides=7, taper=1.38, turn=10)
    m.prism("mid", radius=8.3, height=4.0, at=(0, 0, 5.0), role="rock", sides=7, taper=0.95, turn=10, shear=(-0.4, 0.3))
    m.prism("top", radius=7.9, height=2.2, at=(-0.4, 0.3, 8.1), role="rockl", sides=7, taper=0.95, turn=10)
    m.prism("topcrust", radius=8.0, height=0.7, at=(-0.4, 0.3, 9.55), role="snow", sides=7, taper=0.9, turn=10)
    m.box("bumpA", size=(5.4, 4.4, 3.0), at=S("mid", "side2", (0, 0.2), sink=1.4), role="rock", chamfer=0.9, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.6, 3.8, 2.4), at=S("mid", "side5", (0.3, -0.3), sink=1.2), role="rockd", chamfer=0.8, taper=0.65)
    m.box("bumpC", size=(4.2, 3.4, 2.4), at=S("bot", "side4", (0, 0.3), sink=1.0), role="rockd", chamfer=0.7, taper=0.65)
    icicles(m, "ic", "topcrust", 6.95, [0, 1, 3, 4, 6], 7, 10, seed=5)
    cluster(m, "sA", "topcrust", "top", (1.0, -0.6), 2.1, "silver", "silverd", 5, 1)
    cluster(m, "sB", "mid", "side0", (0.5, 0.0), 1.5, "silver", "silverd", 4, 2)
    cluster(m, "sC", "mid", "side4", (-0.4, 0.3), 1.4, "silverd", "silver", 4, 3)
    cluster(m, "sD", "bumpA", "top", (0, 0), 1.1, "silver", "silverd", 3, 4)
    cluster(m, "sE", "top", "side6", (0, 0), 1.0, "silver", "silverd", 3, 5)
    cluster(m, "sG", "mid", "side2", (0.6, -0.2), 1.0, "silverd", "silver", 3, 11)
    cluster(m, "sH", "topcrust", "top", (-3.2, 2.4), 1.2, "silverd", "silver", 3, 12)
    m.build()
    m.line("mid", "side1", [(-2, -1.5), (-0.6, -0.2), (0.4, 0.1), (1.8, 1.4)], "vein", width=3)
    m.line("mid", "side3", [(-1.8, 1.2), (-0.4, 0.2), (1.6, -0.8)], "vein", width=3)
    m.line("mid", "side6", [(-1.6, -1.2), (0, 0), (0.8, 1.4)], "vein", width=2)
    m.line("top", "side2", [(-1.2, -0.4), (0.2, 0.2), (1.2, 0.4)], "vein", width=2)
    m.line("mid", "side5", [(-1.6, 0.8), (0, 0.2), (1.6, -1)], "vein", width=2)
    m.blob("mid", "side3", (0.8, 1.2), 0.9, "snow", seed=2)
    m.blob("bot", "side1", (0, 0.4), 0.7, "snow", seed=6)
    return m


def rock_v3():
    m = ropilot.model("Rock_R2_V3", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#2C4A6E", noise=0.03, mottle=("#243E5E", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#1F3654", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#3C5E86", noise=0.025, shade=0.12, top=0.12),
        snow=dict(color="#CCD8E6", noise=0.025, shade=0.12, top=0.1),
        icicle=dict(color="#94C4E6", noise=0.02, shade=0.1, top=0.2),
        gold=dict(color="#FFC83A", noise=0.025, shade=0.12, top=0.25),
        goldd=dict(color="#E09A1E", noise=0.025, shade=0.12, top=0.2),
        glow=dict(color="#F0A020", glow=True))
    S = m.surface
    m.prism("bot", radius=6.4, height=3.4, at=(0, 0, 1.7), role="rockd", sides=8, taper=1.38, turn=5)
    m.prism("mid", radius=9.0, height=4.4, at=(0, 0, 5.6), role="rock", sides=8, taper=0.95, turn=5, shear=(0.4, 0.4))
    m.prism("top", radius=8.55, height=2.4, at=(0.4, 0.4, 9.0), role="rockl", sides=8, taper=0.95, turn=5)
    m.prism("topcrust", radius=8.8, height=0.7, at=(0.4, 0.4, 10.55), role="snow", sides=8, taper=0.9, turn=5)
    m.box("bumpA", size=(6, 4.8, 3.2), at=S("mid", "side3", (0, 0.2), sink=1.5), role="rock", chamfer=1.0, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(5.2, 4.2, 2.6), at=S("mid", "side6", (0.3, -0.2), sink=1.2), role="rockl", chamfer=0.9, taper=0.65)
    m.box("bumpC", size=(4.6, 3.6, 2.6), at=S("bot", "side5", (0, 0.3), sink=1.1), role="rockd", chamfer=0.8, taper=0.65)
    icicles(m, "ic", "topcrust", 7.75, [0, 1, 3, 4, 6, 7], 8, 5, seed=7)
    cluster(m, "gA", "topcrust", "top", (-0.8, 0.6), 1.8, "gold", "goldd", 5, 7)
    cluster(m, "gB", "mid", "side0", (0.4, 0.1), 1.4, "gold", "goldd", 4, 8)
    cluster(m, "gC", "mid", "side5", (-0.3, 0.2), 1.3, "goldd", "gold", 4, 9)
    cluster(m, "gD", "mid", "side7", (0.2, -0.2), 1.1, "gold", "goldd", 3, 10)
    cluster(m, "gE", "topcrust", "top", (3.2, 2.6), 1.2, "goldd", "gold", 3, 13)
    for name, host, face, uv, s, rot in [("n1", "topcrust", "top", (2.6, -1.8), 1.5, 20), ("n2", "mid", "side2", (-0.6, -0.4), 1.3, -10),
                                         ("n3", "mid", "side6", (0.9, 0.9), 1.0, 35), ("n4", "bumpA", "top", (0, 0), 1.1, 10),
                                         ("n5", "top", "side4", (0, 0), 1.0, -25), ("n6", "bot", "side1", (0, 0.2), 1.0, 5)]:
        m.box(name, size=(1.6 * s, 1.4 * s, 1.1 * s), at=S(host, face, uv, sink=0.35 * s), role="gold", chamfer=0.35 * s, taper=0.75, rot=(0, 0, rot), solo=True)
    cracks = [("mid", "side1", (-1.5, -1.2), (1.4, 1.3)), ("mid", "side4", (-1.4, 1.0), (1.5, -0.9)),
              ("mid", "side2", (0.4, 0.6), (2.0, 1.4)), ("bot", "side3", (-1.0, -0.3), (1.0, 0.4))]
    for i, (host, face, a, b) in enumerate(cracks):
        du, dv = b[0] - a[0], b[1] - a[1]
        m.box(f"crack{i}", size=(math.hypot(du, dv), 0.42, 0.14), at=S(host, face, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), sink=0.06),
              role="glow", rot=(0, 0, math.degrees(math.atan2(dv, du))), solo=True)
    m.build()
    m.blob("mid", "side3", (-1.0, 1.4), 0.8, "snow", seed=3)
    m.blob("mid", "side7", (1.0, 1.4), 0.8, "snow", seed=8)
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
    for c in ("Rock_R2_V1", "Rock_R2_V2", "Rock_R2_V3"):
        join_rock(c)
