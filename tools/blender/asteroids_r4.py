# Astéroïdes de l'anneau 4 « Nebula » (25 nov.), au kit low-poly de Ropilot (ropilot.model, px = 8, sans
# picots : ils sont posés dans Studio sur la roche seulement), même méthode que asteroids_r1.py.
# Silhouette propre à l'anneau : corps à 9 pans en étages tournés les uns par rapport aux autres (effet de
# tourbillon), une petite terrasse surélevée sur le dessus et des aiguilles de cristaux de nébuleuse.
#   V1 Soft Rock   : roche violette et rose poudré, terrasse, second lobe, aiguilles de cristaux violets et cyan,
#                    petites étoiles incrustées (peintes), taches roses
#   V2 Silver Rock : roche violet sombre, filons d'argent peints, grosses grappes de cristaux d'argent,
#                    un petit cristal violet et des étoiles
#   V3 Gold Rock   : roche prune très sombre, grappes de cristaux d'or, pépites, fentes lumineuses orange (néon),
#                    étoiles
# À lancer avec ropilot_blender_run_python (exec dans un espace de noms à part), puis build_all().
# Chaque collection est fusionnée en « _Asteroid » (roche), « _Ore » (décor) et « _Glow » (néon).
# Les couleurs sont plus foncées que voulu : l'import les éclaircit.
import math
import random

BODY = ("bot", "mid", "top", "lobe", "bump")
STAR = ["...#...", "...#...", "..###..", "###o###", "..###..", "...#...", "...#..."]


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


def stars(m, spots, color="star"):
    # petites étoiles incrustées (pixel art), cellule fixe pour garder la taille
    for host, face, uv in spots:
        m.stamp(host, face, uv, STAR, {"#": color, "o": "#FFFFFF"}, cell=0.2)


def glow_cracks(m, pre, items, width=0.36):
    for i, (host, face, a, b) in enumerate(items):
        du, dv = b[0] - a[0], b[1] - a[1]
        m.box(f"{pre}{i}", size=(math.hypot(du, dv), width, 0.12), at=m.surface(host, face, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), sink=0.06),
              role="glow", rot=(0, 0, math.degrees(math.atan2(dv, du))), solo=True)


def rock_v1():
    m = ropilot.model("Rock_R4_V1", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#7E4F96", noise=0.03, mottle=("#6A3F84", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#5E3A78", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#A86C9E", noise=0.025, mottle=("#B97FAE", 0.2, 4), shade=0.12, top=0.15),
        pink="#D0609E", dust="#5C3A8C",
        star="#F6D76A",
        violet=dict(color="#8A3FD6", noise=0.02, shade=0.1, top=0.25),
        cyan=dict(color="#22A2C8", noise=0.02, shade=0.1, top=0.25))
    S = m.surface
    m.prism("bot", radius=5.2, height=2.6, at=(0, 0, 1.3), role="rockd", sides=9, taper=1.42, turn=0)
    m.prism("mid", radius=7.4, height=3.2, at=(0, 0, 4.2), role="rock", sides=9, taper=1.0, turn=20)
    m.prism("top", radius=7.4, height=2.4, at=(0, 0, 7.0), role="rockl", sides=9, taper=0.74, turn=0, shear=(0.4, 0.3))
    m.prism("topstep", radius=3.0, height=1.3, at=(-1.4, 1.6, 8.75), role="rockl", sides=7, taper=0.78, turn=10)
    m.prism("lobeB", radius=3.2, height=2.0, at=(5.0, -4.0, 1.5), role="rockd", sides=7, taper=1.4, turn=12)
    m.prism("lobeM", radius=4.4, height=2.4, at=(5.0, -4.0, 3.7), role="rock", sides=7, taper=1.0, turn=30)
    m.prism("lobeT", radius=4.4, height=1.8, at=(5.0, -4.0, 5.8), role="rockl", sides=7, taper=0.66, turn=12, shear=(0.3, -0.3))
    m.box("bumpA", size=(5.0, 4.0, 2.6), at=S("mid", "side3", (0, 0.1), sink=1.3), role="rock", chamfer=0.8, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.4, 3.6, 2.4), at=S("mid", "side6", (0.3, -0.3), sink=1.2), role="rockd", chamfer=0.7, taper=0.65)
    m.box("bumpC", size=(4.0, 3.2, 2.2), at=S("bot", "side1", (0, 0.3), sink=1.0), role="rockd", chamfer=0.7, taper=0.65)
    neb = [("topstep", "top", (0.2, 0.0), 0.8, 3.8, "violet"), ("topstep", "top", (1.2, 0.7), 0.45, 2.0, "cyan"),
           ("topstep", "top", (-0.9, -0.7), 0.42, 1.8, "violet"), ("topstep", "top", (-0.9, 0.8), 0.36, 1.4, "cyan"),
           ("lobeT", "top", (0.2, 0.1), 0.7, 3.0, "cyan"),
           ("lobeT", "top", (-1.0, 0.5), 0.4, 1.7, "violet"), ("lobeT", "top", (0.9, -0.7), 0.36, 1.4, "violet"),
           ("top", "top", (3.0, -1.6), 0.35, 1.3, "violet"), ("mid", "side0", (1.2, 0.4), 0.3, 1.1, "cyan"),
           ("bumpA", "top", (0.4, 0.3), 0.3, 1.1, "violet"), ("mid", "side5", (-0.8, 0.4), 0.32, 1.1, "violet")]
    for i, (host, face, uv, r, h, role) in enumerate(neb):
        m.crystal(f"neb{i}", radius=r, height=h, at=S(host, face, uv), role=role, sides=5, tip=0.35, solo=True)
    m.build()
    m.blob("top", "top", (1.8, -2.4), 1.3, "pink", seed=2)
    m.blob("mid", "side2", (0.4, 0.2), 1.0, "pink", seed=3)
    m.blob("mid", "side7", (-0.4, -0.4), 0.9, "dust", seed=4)
    m.blob("lobeM", "side4", (0, 0.2), 0.8, "pink", seed=5)
    stars(m, [("top", "top", (-3.0, -2.0)), ("top", "top", (2.6, 1.8)), ("mid", "side1", (-0.8, 0.6)), ("mid", "side4", (0.6, -0.4)),
              ("mid", "side8", (0.2, 0.5)), ("lobeM", "side2", (0.4, -0.3)), ("top", "side6", (0, 0)), ("bot", "side5", (0, 0.2))])
    return m


def rock_v2():
    m = ropilot.model("Rock_R4_V2", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#5A3B72", noise=0.03, mottle=("#4A2F60", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#432B58", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#7A4E82", noise=0.025, shade=0.12, top=0.12),
        pink="#9A4C86", star="#F6D76A",
        violet=dict(color="#8A3FD6", noise=0.02, shade=0.1, top=0.25),
        vein="#E4ECF6",
        silver=dict(color="#E6EEF8", noise=0.02, shade=0.1, top=0.2),
        silverd=dict(color="#A8B8D0", noise=0.02, shade=0.1, top=0.15))
    S = m.surface
    m.prism("bot", radius=5.8, height=3.0, at=(0, 0, 1.5), role="rockd", sides=9, taper=1.4, turn=0)
    m.prism("mid", radius=8.2, height=3.8, at=(0, 0, 4.9), role="rock", sides=9, taper=1.0, turn=20)
    m.prism("top", radius=8.2, height=2.8, at=(0, 0, 8.2), role="rockl", sides=9, taper=0.72, turn=0, shear=(-0.5, 0.4))
    m.prism("topstep", radius=3.2, height=1.3, at=(1.2, -1.4, 10.25), role="rockl", sides=7, taper=0.78, turn=10)
    m.box("bumpA", size=(5.4, 4.4, 3.0), at=S("mid", "side2", (0, 0.2), sink=1.4), role="rock", chamfer=0.9, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.8, 3.8, 2.4), at=S("top", "side6", (0.3, -0.2), sink=1.1), role="rockl", chamfer=0.8, taper=0.65)
    m.box("bumpC", size=(4.2, 3.4, 2.4), at=S("bot", "side4", (0, 0.3), sink=1.0), role="rockd", chamfer=0.7, taper=0.65)
    cluster(m, "sA", "topstep", "top", (0.0, 0.0), 2.0, "silver", "silverd", 5, 1)
    cluster(m, "sB", "mid", "side0", (0.5, 0.0), 1.5, "silver", "silverd", 4, 2)
    cluster(m, "sC", "mid", "side5", (-0.4, 0.3), 1.4, "silverd", "silver", 4, 3)
    cluster(m, "sD", "bumpA", "top", (0, 0), 1.1, "silver", "silverd", 3, 4)
    cluster(m, "sE", "top", "side3", (0, 0), 1.1, "silver", "silverd", 3, 5)
    cluster(m, "sG", "top", "top", (-3.0, 2.0), 1.1, "silverd", "silver", 3, 11)
    m.crystal("neb0", radius=0.4, height=1.6, at=S("top", "top", (-2.6, -2.4)), role="violet", sides=5, tip=0.35, solo=True)
    m.crystal("neb1", radius=0.3, height=1.1, at=S("mid", "side7", (0.6, 0.4)), role="violet", sides=5, tip=0.35, solo=True)
    m.build()
    m.line("mid", "side1", [(-2, -1.5), (-0.6, -0.2), (0.4, 0.1), (1.8, 1.4)], "vein", width=3)
    m.line("mid", "side3", [(-1.8, 1.2), (-0.4, 0.2), (1.6, -0.8)], "vein", width=3)
    m.line("mid", "side6", [(-1.6, -1.2), (0, 0), (0.8, 1.4)], "vein", width=2)
    m.line("top", "side1", [(-1.2, -0.6), (0.2, 0.2), (1.2, 0.4)], "vein", width=2)
    m.line("mid", "side8", [(-1.6, 0.8), (0, 0.2), (1.6, -1)], "vein", width=2)
    m.blob("mid", "side4", (0.4, 0.4), 0.9, "pink", seed=3)
    stars(m, [("top", "top", (2.8, 2.6)), ("mid", "side2", (1.4, -1.0)), ("mid", "side4", (-1.0, -0.8)), ("top", "side7", (0, 0)), ("bot", "side6", (0, 0.2))])
    return m


def rock_v3():
    m = ropilot.model("Rock_R4_V3", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#42294F", noise=0.03, mottle=("#36213F", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#301D3A", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#5A3866", noise=0.025, shade=0.12, top=0.12),
        star="#F6D76A",
        gold=dict(color="#FFC83A", noise=0.025, shade=0.12, top=0.25),
        goldd=dict(color="#E09A1E", noise=0.025, shade=0.12, top=0.2),
        glow=dict(color="#F0A020", glow=True))
    S = m.surface
    m.prism("bot", radius=6.4, height=3.4, at=(0, 0, 1.7), role="rockd", sides=9, taper=1.4, turn=0)
    m.prism("mid", radius=9.0, height=4.2, at=(0, 0, 5.5), role="rock", sides=9, taper=1.0, turn=20)
    m.prism("top", radius=9.0, height=3.2, at=(0, 0, 9.2), role="rockl", sides=9, taper=0.7, turn=0, shear=(0.6, 0.6))
    m.prism("topstep", radius=3.4, height=1.4, at=(-1.4, -1.0, 11.5), role="rockl", sides=7, taper=0.78, turn=10)
    m.box("bumpA", size=(6, 4.8, 3.2), at=S("mid", "side3", (0, 0.2), sink=1.5), role="rock", chamfer=1.0, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(5.2, 4.2, 2.6), at=S("top", "side7", (0.3, -0.2), sink=1.2), role="rockl", chamfer=0.9, taper=0.65)
    m.box("bumpC", size=(4.6, 3.6, 2.6), at=S("bot", "side6", (0, 0.3), sink=1.1), role="rockd", chamfer=0.8, taper=0.65)
    cluster(m, "gA", "topstep", "top", (0.0, 0.0), 1.8, "gold", "goldd", 5, 7)
    cluster(m, "gB", "mid", "side0", (0.4, 0.1), 1.4, "gold", "goldd", 4, 8)
    cluster(m, "gC", "mid", "side5", (-0.3, 0.2), 1.3, "goldd", "gold", 4, 9)
    cluster(m, "gD", "mid", "side7", (0.2, -0.2), 1.1, "gold", "goldd", 3, 10)
    cluster(m, "gE", "top", "top", (3.4, 2.4), 1.1, "goldd", "gold", 3, 13)
    for name, host, face, uv, s, rot in [("n1", "top", "top", (2.6, -2.2), 1.4, 20), ("n2", "mid", "side2", (-0.6, -0.4), 1.3, -10),
                                         ("n3", "mid", "side8", (0.5, 0.6), 1.2, 35), ("n4", "bumpA", "top", (0, 0), 1.1, 10),
                                         ("n5", "top", "side4", (0, 0), 1.1, -25), ("n6", "bot", "side1", (0, 0.2), 1.0, 5)]:
        m.box(name, size=(1.6 * s, 1.4 * s, 1.1 * s), at=S(host, face, uv, sink=0.35 * s), role="gold", chamfer=0.35 * s, taper=0.75, rot=(0, 0, rot), solo=True)
    glow_cracks(m, "crack", [("mid", "side1", (-1.5, -1.2), (1.4, 1.3)), ("mid", "side4", (-1.4, 1.0), (1.5, -0.9)),
                             ("mid", "side6", (-1.2, -0.8), (1.3, 0.9)), ("top", "side2", (-1.0, -0.3), (1.0, 0.4))])
    m.build()
    stars(m, [("top", "top", (-3.4, 2.4)), ("mid", "side3", (1.6, 1.0)), ("mid", "side6", (-1.6, 1.2)), ("top", "side5", (0, 0)), ("bot", "side3", (0, 0.2))])
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
    for c in ("Rock_R4_V1", "Rock_R4_V2", "Rock_R4_V3"):
        join_rock(c)
