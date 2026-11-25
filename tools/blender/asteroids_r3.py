# Astéroïdes de l'anneau 3 « Magma Field » (25 nov.), au kit low-poly de Ropilot (ropilot.model, px = 8, sans
# picots : ils sont posés dans Studio sur la roche seulement), même méthode que asteroids_r1.py.
# Silhouette propre à l'anneau : roche volcanique à 7 pans qui se referme en haut, petits cônes volcaniques
# sur le dessus (cratère de lave en néon) et une grappe de colonnes de basalte hexagonales sur le côté.
#   V1 Soft Rock   : roche noire-brune, fissures de lave orange (néon fin) avec halo peint, deux petits cônes
#                    fumants à cratère de lave, colonnes de basalte en lobe
#   V2 Silver Rock : roche volcanique plus sombre, filons d'argent peints, grosses grappes de cristaux
#                    d'argent, quelques colonnes de basalte, un petit cône éteint (sans néon : le néon reste à l'or)
#   V3 Gold Rock   : roche presque noire, grappes de cristaux d'or, pépites, fentes de lave lumineuses (néon),
#                    colonnes de basalte, un cône
# À lancer avec ropilot_blender_run_python (exec dans un espace de noms à part), puis build_all().
# Chaque collection est fusionnée en « _Asteroid » (roche, colonnes comprises), « _Ore » (décor) et « _Glow » (néon).
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


def columns(m, pre, cx, cy, spec, role="basalt", seed=1):
    # colonnes de basalte hexagonales debout (noms « lobe… » : elles font partie de la roche, on y marche)
    rnd = random.Random(seed)
    for i, (dx, dy, h, r) in enumerate(spec):
        m.prism(f"lobe{pre}{i}", radius=r, height=h, at=(cx + dx, cy + dy, 0.4 + h / 2), role=role, sides=6,
                taper=1.0, turn=rnd.uniform(0, 60))


def cone(m, name, host, face, uv, r, h, role, lava=True):
    # petit cône volcanique ; cratère de lave en néon (rôle glow) ou cratère éteint peint plus tard
    m.prism(name, radius=r, height=h, at=m.surface(host, face, uv, sink=0.3), role=role, sides=7, taper=0.42)
    if lava:
        m.prism(name + "lava", radius=r * 0.3, height=0.2, at=m.surface(name, "top", (0, 0), sink=0.12), role="glow", sides=7, solo=True)


def cracks(m, pre, items, width=0.32):
    for i, (host, face, a, b) in enumerate(items):
        du, dv = b[0] - a[0], b[1] - a[1]
        m.box(f"{pre}{i}", size=(math.hypot(du, dv), width, 0.12), at=m.surface(host, face, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), sink=0.06),
              role="glow", rot=(0, 0, math.degrees(math.atan2(dv, du))), solo=True)


def halo(m, items, color, width=4):
    # halo sombre-orangé peint autour des fentes de lave
    for host, face, a, b in items:
        m.line(host, face, [a, b], color, width=width)


def rock_v1():
    m = ropilot.model("Rock_R3_V1", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#4A3B34", noise=0.035, mottle=("#3B2E28", 0.25, 4), shade=0.2, top=0.15),
        rockd=dict(color="#352A25", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#5C4A40", noise=0.03, shade=0.12, top=0.12),
        basalt=dict(color="#3A3534", noise=0.025, shade=0.2, top=0.22, rim=-0.15),
        ash=dict(color="#57504C", noise=0.03, shade=0.15, top=0.1),
        ember="#B44A1C", soot="#231B18",
        glow=dict(color="#FF6A14", glow=True))
    S = m.surface
    m.prism("bot", radius=5.2, height=2.8, at=(0, 0, 1.4), role="rockd", sides=7, taper=1.42, turn=12)
    m.prism("mid", radius=7.4, height=3.4, at=(0, 0, 4.5), role="rock", sides=7, taper=1.0, turn=12)
    m.prism("top", radius=7.4, height=2.6, at=(0, 0, 7.5), role="rockl", sides=7, taper=0.64, turn=12, shear=(-0.5, 0.6))
    columns(m, "C", -7.0, -3.4, [(0, 0, 10.0, 1.35), (1.7, 1.2, 8.2, 1.25), (-1.2, 1.7, 6.8, 1.2), (-0.4, -1.8, 5.4, 1.1),
                                 (1.6, -1.2, 7.2, 1.1), (-2.1, -0.4, 4.4, 1.0)], seed=2)
    m.box("bumpA", size=(5.0, 4.2, 2.8), at=S("mid", "side2", (0, 0.2), sink=1.3), role="rock", chamfer=0.8, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.4, 3.6, 2.4), at=S("mid", "side5", (0.3, -0.3), sink=1.2), role="rockd", chamfer=0.7, taper=0.65)
    m.box("bumpC", size=(4.0, 3.2, 2.2), at=S("bot", "side1", (0, 0.3), sink=1.0), role="rockd", chamfer=0.7, taper=0.65)
    cone(m, "coneA", "top", "top", (1.5, 0.8), 2.2, 2.4, "ash")
    cone(m, "coneB", "top", "top", (-1.4, -1.6), 1.3, 1.4, "ash")
    cr = [("mid", "side0", (-1.6, -1.0), (1.2, 1.2)), ("mid", "side3", (-1.4, 0.9), (1.4, -0.8)),
          ("mid", "side6", (-1.0, -1.2), (0.8, 1.0)), ("top", "side2", (-1.0, -0.3), (1.0, 0.4)),
          ("bot", "side4", (-0.8, -0.2), (0.9, 0.3)), ("top", "side5", (-0.8, 0.4), (0.9, -0.3))]
    cracks(m, "lava", cr, width=0.3)
    m.build()
    halo(m, cr, "ember", width=5)
    m.circle("coneA", "top", (0, 0), 0.75, "soot")
    m.circle("coneB", "top", (0, 0), 0.5, "soot")
    m.blob("top", "top", (-1.8, 2.0), 1.0, "ash", seed=3)
    m.blob("mid", "side1", (0.5, -0.6), 0.9, "soot", seed=4)
    return m


def rock_v2():
    m = ropilot.model("Rock_R3_V2", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#3F3330", noise=0.035, mottle=("#322825", 0.25, 4), shade=0.2, top=0.15),
        rockd=dict(color="#2E2421", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#524440", noise=0.03, shade=0.12, top=0.12),
        basalt=dict(color="#36302F", noise=0.025, shade=0.2, top=0.22, rim=-0.15),
        ash=dict(color="#4E4744", noise=0.03, shade=0.15, top=0.1),
        ember="#6E3420", soot="#1E1715",
        vein="#E4ECF6",
        silver=dict(color="#E6EEF8", noise=0.02, shade=0.1, top=0.2),
        silverd=dict(color="#A8B8D0", noise=0.02, shade=0.1, top=0.15))
    S = m.surface
    m.prism("bot", radius=5.8, height=3.2, at=(0, 0, 1.6), role="rockd", sides=7, taper=1.4, turn=20)
    m.prism("mid", radius=8.3, height=3.8, at=(0, 0, 5.1), role="rock", sides=7, taper=1.0, turn=20)
    m.prism("top", radius=8.3, height=3.0, at=(0, 0, 8.5), role="rockl", sides=7, taper=0.62, turn=20, shear=(0.6, -0.5))
    columns(m, "C", 7.6, 3.2, [(0, 0, 10.6, 1.35), (-1.4, 1.6, 8.6, 1.25), (1.5, 1.2, 7.0, 1.15), (0.4, -1.8, 5.8, 1.1)], seed=5)
    m.box("bumpA", size=(5.4, 4.4, 3.0), at=S("mid", "side1", (0, 0.2), sink=1.4), role="rock", chamfer=0.9, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.8, 3.8, 2.4), at=S("top", "side4", (0.3, -0.2), sink=1.1), role="rockl", chamfer=0.8, taper=0.65)
    m.box("bumpC", size=(4.2, 3.4, 2.4), at=S("bot", "side3", (0, 0.3), sink=1.0), role="rockd", chamfer=0.7, taper=0.65)
    cone(m, "coneA", "top", "top", (-1.8, 1.4), 1.6, 1.6, "ash", lava=False)
    cluster(m, "sA", "top", "top", (1.0, -0.6), 2.1, "silver", "silverd", 5, 1)
    cluster(m, "sB", "mid", "side5", (0.5, 0.0), 1.5, "silver", "silverd", 4, 2)
    cluster(m, "sC", "mid", "side3", (-0.4, 0.3), 1.4, "silverd", "silver", 4, 3)
    cluster(m, "sD", "bumpA", "top", (0, 0), 1.1, "silver", "silverd", 3, 4)
    cluster(m, "sE", "top", "side6", (0, 0), 1.1, "silver", "silverd", 3, 5)
    cluster(m, "sG", "lobeC0", "top", (0, 0), 0.8, "silverd", "silver", 3, 11)
    m.build()
    m.line("mid", "side0", [(-2, -1.5), (-0.6, -0.2), (0.4, 0.1), (1.8, 1.4)], "vein", width=3)
    m.line("mid", "side2", [(-1.8, 1.2), (-0.4, 0.2), (1.6, -0.8)], "vein", width=3)
    m.line("mid", "side6", [(-1.6, -1.2), (0, 0), (0.8, 1.4)], "vein", width=2)
    m.line("top", "side1", [(-1.2, -0.6), (0.2, 0.2), (1.2, 0.4)], "vein", width=2)
    m.line("mid", "side4", [(-1.6, 0.8), (0, 0.2), (1.6, -1)], "vein", width=2)
    m.circle("coneA", "top", (0, 0), 0.6, "soot")
    m.line("mid", "side3", [(0.6, -1.4), (1.6, -0.6)], "ember", width=3)
    return m


def rock_v3():
    m = ropilot.model("Rock_R3_V3", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#352A27", noise=0.035, mottle=("#2A211E", 0.25, 4), shade=0.2, top=0.15),
        rockd=dict(color="#261E1B", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#463936", noise=0.03, shade=0.12, top=0.12),
        basalt=dict(color="#302B2A", noise=0.025, shade=0.2, top=0.22, rim=-0.15),
        ash=dict(color="#4A4240", noise=0.03, shade=0.15, top=0.1),
        ember="#A8441A", soot="#1A1412",
        gold=dict(color="#FFC83A", noise=0.025, shade=0.12, top=0.25),
        goldd=dict(color="#E09A1E", noise=0.025, shade=0.12, top=0.2),
        glow=dict(color="#FF7A18", glow=True))
    S = m.surface
    m.prism("bot", radius=6.4, height=3.6, at=(0, 0, 1.8), role="rockd", sides=7, taper=1.4, turn=5)
    m.prism("mid", radius=9.0, height=4.4, at=(0, 0, 5.8), role="rock", sides=7, taper=1.0, turn=5)
    m.prism("top", radius=9.0, height=3.4, at=(0, 0, 9.7), role="rockl", sides=7, taper=0.6, turn=5, shear=(0.6, 0.8))
    columns(m, "C", -8.0, 4.0, [(0, 0, 11.4, 1.4), (1.6, 1.5, 9.4, 1.3), (-1.7, 1.0, 7.6, 1.2), (-0.6, -1.8, 6.0, 1.15)], seed=8)
    m.box("bumpA", size=(6, 4.8, 3.2), at=S("mid", "side3", (0, 0.2), sink=1.5), role="rock", chamfer=1.0, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(5.2, 4.2, 2.6), at=S("top", "side1", (0.3, -0.2), sink=1.2), role="rockl", chamfer=0.9, taper=0.65)
    m.box("bumpC", size=(4.6, 3.6, 2.6), at=S("bot", "side5", (0, 0.3), sink=1.1), role="rockd", chamfer=0.8, taper=0.65)
    cone(m, "coneA", "top", "top", (2.4, 1.6), 1.5, 1.5, "ash")
    cluster(m, "gA", "top", "top", (-0.8, -0.6), 1.8, "gold", "goldd", 5, 7)
    cluster(m, "gB", "mid", "side0", (0.4, 0.1), 1.4, "gold", "goldd", 4, 8)
    cluster(m, "gC", "mid", "side5", (-0.3, 0.2), 1.3, "goldd", "gold", 4, 9)
    cluster(m, "gD", "mid", "side2", (0.2, -0.2), 1.1, "gold", "goldd", 3, 10)
    cluster(m, "gE", "lobeC0", "top", (0, 0), 0.8, "goldd", "gold", 3, 13)
    for name, host, face, uv, s, rot in [("n1", "top", "top", (2.2, -2.2), 1.4, 20), ("n2", "mid", "side4", (-0.6, -0.4), 1.3, -10),
                                         ("n3", "mid", "side6", (0.5, 0.6), 1.2, 35), ("n4", "bumpA", "top", (0, 0), 1.1, 10),
                                         ("n5", "top", "side3", (0, 0), 1.1, -25), ("n6", "bot", "side1", (0, 0.2), 1.0, 5)]:
        m.box(name, size=(1.6 * s, 1.4 * s, 1.1 * s), at=S(host, face, uv, sink=0.35 * s), role="gold", chamfer=0.35 * s, taper=0.75, rot=(0, 0, rot), solo=True)
    cr = [("mid", "side1", (-1.5, -1.2), (1.4, 1.3)), ("mid", "side4", (0.4, 1.0), (1.8, 0.2)),
          ("mid", "side6", (-1.2, -0.8), (-0.2, 1.2)), ("top", "side5", (-1.0, -0.4), (1.0, 0.4))]
    cracks(m, "crack", cr, width=0.36)
    m.build()
    halo(m, cr, "ember", width=5)
    m.circle("coneA", "top", (0, 0), 0.6, "soot")
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
    for c in ("Rock_R3_V1", "Rock_R3_V2", "Rock_R3_V3"):
        join_rock(c)
