# Astéroïdes de l'anneau 5 « Devourer Belt » (25 nov.), au kit low-poly de Ropilot (ropilot.model, px = 8, sans
# picots : ils sont posés dans Studio sur la roche seulement), même méthode que asteroids_r1.py.
# Silhouette propre à l'anneau : roche à 8 pans qui penche, avec une rangée de gros crocs de pierre cartoon
# plantés en mâchoire sur un bord du dessus, des traces de morsures (encoches peintes en festons sombres)
# et de la bave verte qui coule sur les flancs. Menaçant mais jamais gore.
#   V1 Soft Rock   : roche gris-brun rongée, mâchoire de crocs crème, second lobe avec deux crocs, morsures,
#                    coulures de bave verte lumineuse (néon fin) avec gouttes
#   V2 Silver Rock : roche plus sombre, filons d'argent peints, grosses grappes de cristaux d'argent,
#                    trois crocs, morsures, bave peinte (sans néon : le néon reste à l'or)
#   V3 Gold Rock   : roche presque noire, grappes de cristaux d'or, pépites, fentes lumineuses orange (néon),
#                    trois crocs, morsures, bave peinte
# À lancer avec ropilot_blender_run_python (exec dans un espace de noms à part), puis build_all().
# Chaque collection est fusionnée en « _Asteroid » (roche), « _Ore » (décor : crocs, cristaux) et « _Glow » (néon).
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


def fangs(m, pre, items, role="tooth"):
    # gros crocs de pierre : cône à 5 pans un peu penché, posé sur une face
    for i, (host, face, uv, r, h, tilt) in enumerate(items):
        m.prism(f"{pre}{i}", radius=r, height=h, at=m.surface(host, face, uv, sink=0.35), role=role, sides=6, taper=0.16,
                rot=tilt, solo=True)


def molars(m, pre, items, role="tooth"):
    # petites dents carrées entre les crocs
    for i, (host, face, uv, s) in enumerate(items):
        m.box(f"{pre}{i}", size=(1.3 * s, 1.0 * s, 1.1 * s), at=m.surface(host, face, uv, sink=0.3), role=role, chamfer=0.25 * s, taper=0.8, solo=True)


def bite(m, host, face, at, r, color="bite", rim="bitel"):
    # trace de morsure : festons de cercles sombres en arc, liseré clair au-dessus
    for k in (-1, 0, 1):
        m.circle(host, face, (at[0] + k * r * 1.2, at[1] + 0.12), r * 0.8, rim)
    for k in (-1, 0, 1):
        m.circle(host, face, (at[0] + k * r * 1.2, at[1]), r * 0.72, color)


def drool(m, pre, items, role="glow"):
    # coulures de bave : filet vertical (pièce fine) et goutte au bout
    for i, (host, face, u, v0, length) in enumerate(items):
        m.box(f"{pre}{i}", size=(0.48, length, 0.12), at=m.surface(host, face, (u, v0 - length / 2), sink=0.06), role=role, solo=True)
        m.box(f"{pre}{i}d", size=(0.8, 0.8, 0.2), at=m.surface(host, face, (u, v0 - length - 0.1), sink=0.08), role=role,
              chamfer=0.15, solo=True)


def rock_v1():
    m = ropilot.model("Rock_R5_V1", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#564B42", noise=0.035, mottle=("#463C34", 0.25, 4), shade=0.2, top=0.15),
        rockd=dict(color="#3F362F", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#6A5D51", noise=0.03, shade=0.12, top=0.12),
        tooth=dict(color="#C9BC98", noise=0.025, shade=0.15, top=0.2),
        bite="#241E1A", bitel="#7E7062", slime="#3E8A22",
        glow=dict(color="#58D020", glow=True))
    S = m.surface
    m.prism("bot", radius=5.4, height=2.8, at=(0, 0, 1.4), role="rockd", sides=8, taper=1.42, turn=8)
    m.prism("mid", radius=7.6, height=3.4, at=(0, 0, 4.5), role="rock", sides=8, taper=1.0, turn=8, shear=(-0.3, 0.4))
    m.prism("top", radius=7.6, height=2.4, at=(-0.3, 0.4, 7.4), role="rockl", sides=8, taper=0.7, turn=8, shear=(-0.6, 0.5))
    m.prism("lobeB", radius=3.2, height=2.0, at=(5.6, 3.0, 1.4), role="rockd", sides=6, taper=1.4, turn=0)
    m.prism("lobeM", radius=4.2, height=2.6, at=(5.6, 3.0, 3.7), role="rock", sides=6, taper=1.0, turn=0)
    m.prism("lobeT", radius=4.2, height=1.8, at=(5.6, 3.0, 5.9), role="rockl", sides=6, taper=0.62, turn=0, shear=(0.4, 0.2))
    m.box("bumpA", size=(5.0, 4.2, 2.8), at=S("mid", "side4", (0, 0.1), sink=1.3), role="rock", chamfer=0.8, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.4, 3.6, 2.4), at=S("mid", "side6", (0.3, -0.3), sink=1.2), role="rockd", chamfer=0.7, taper=0.65)
    m.box("bumpC", size=(4.0, 3.2, 2.2), at=S("bot", "side2", (0, 0.3), sink=1.0), role="rockd", chamfer=0.7, taper=0.65)
    # mâchoire : crocs sur le bord avant du dessus, penchés vers l'extérieur
    fangs(m, "fang", [("top", "top", (-3.0, -2.9), 1.15, 2.6, (16, -8, 0)), ("top", "top", (-0.4, -3.6), 1.4, 3.4, (18, 0, 0)),
                      ("top", "top", (2.3, -3.1), 1.15, 2.6, (16, 8, 0)),
                      ("lobeT", "top", (0.9, -0.2), 0.95, 2.2, (0, 16, 0)), ("lobeT", "top", (-0.2, -1.2), 0.8, 1.7, (14, 0, 0))])
    molars(m, "molar", [("top", "top", (-1.7, -3.4), 0.9), ("top", "top", (1.0, -3.5), 0.9), ("top", "top", (3.6, -2.2), 0.8)])
    drool(m, "slime", [("mid", "side0", 0.8, 1.5, 1.8), ("mid", "side1", -0.6, 1.5, 1.3), ("mid", "side7", 0.2, 1.5, 2.0),
                       ("lobeM", "side5", 0.2, 1.1, 1.2)])
    m.build()
    bite(m, "top", "top", (1.4, 2.6), 0.9)
    bite(m, "top", "top", (-2.8, 1.2), 0.7)
    bite(m, "mid", "side3", (0.0, 1.1), 0.7)
    bite(m, "mid", "side5", (0.3, 1.0), 0.6)
    bite(m, "lobeT", "top", (1.2, 1.0), 0.6)
    m.blob("top", "top", (-0.6, -2.4), 0.9, "slime", seed=3)
    return m


def rock_v2():
    m = ropilot.model("Rock_R5_V2", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#463D37", noise=0.035, mottle=("#3A322C", 0.25, 4), shade=0.2, top=0.15),
        rockd=dict(color="#332B26", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#5A4E45", noise=0.03, shade=0.12, top=0.12),
        tooth=dict(color="#BDB08E", noise=0.025, shade=0.15, top=0.2),
        bite="#1E1915", bitel="#6C6056", slime="#3E8A22",
        vein="#E4ECF6",
        silver=dict(color="#E6EEF8", noise=0.02, shade=0.1, top=0.2),
        silverd=dict(color="#A8B8D0", noise=0.02, shade=0.1, top=0.15))
    S = m.surface
    m.prism("bot", radius=5.8, height=3.2, at=(0, 0, 1.6), role="rockd", sides=8, taper=1.4, turn=0)
    m.prism("mid", radius=8.2, height=3.8, at=(0, 0, 5.1), role="rock", sides=8, taper=1.0, turn=0, shear=(0.4, 0.3))
    m.prism("top", radius=8.2, height=2.8, at=(0.4, 0.3, 8.4), role="rockl", sides=8, taper=0.68, turn=0, shear=(0.5, -0.5))
    m.box("bumpA", size=(5.4, 4.4, 3.0), at=S("mid", "side2", (0, 0.2), sink=1.4), role="rock", chamfer=0.9, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.8, 3.8, 2.4), at=S("top", "side5", (0.3, -0.2), sink=1.1), role="rockl", chamfer=0.8, taper=0.65)
    m.box("bumpC", size=(4.2, 3.4, 2.4), at=S("bot", "side4", (0, 0.3), sink=1.0), role="rockd", chamfer=0.7, taper=0.65)
    fangs(m, "fang", [("top", "top", (-3.6, -2.2), 1.1, 2.6, (16, -8, 0)), ("top", "top", (-1.2, -3.6), 1.3, 3.2, (18, 0, 0)),
                      ("top", "top", (1.4, -3.6), 1.05, 2.4, (16, 8, 0))])
    molars(m, "molar", [("top", "top", (-2.4, -3.0), 0.85), ("top", "top", (0.1, -3.8), 0.85)])
    cluster(m, "sA", "top", "top", (1.2, 0.8), 2.1, "silver", "silverd", 5, 1)
    cluster(m, "sB", "mid", "side0", (0.5, 0.0), 1.5, "silver", "silverd", 4, 2)
    cluster(m, "sC", "mid", "side4", (-0.4, 0.3), 1.4, "silverd", "silver", 4, 3)
    cluster(m, "sD", "bumpA", "top", (0, 0), 1.1, "silver", "silverd", 3, 4)
    cluster(m, "sE", "top", "side6", (0, 0), 1.1, "silver", "silverd", 3, 5)
    cluster(m, "sG", "mid", "side2", (0.6, -0.2), 1.0, "silverd", "silver", 3, 11)
    m.build()
    m.line("mid", "side1", [(-2, -1.5), (-0.6, -0.2), (0.4, 0.1), (1.8, 1.4)], "vein", width=3)
    m.line("mid", "side3", [(-1.8, 1.2), (-0.4, 0.2), (1.6, -0.8)], "vein", width=3)
    m.line("mid", "side6", [(-1.6, -1.2), (0, 0), (0.8, 1.4)], "vein", width=2)
    m.line("top", "side2", [(-1.2, -0.6), (0.2, 0.2), (1.2, 0.4)], "vein", width=2)
    m.line("mid", "side7", [(-1.6, 0.8), (0, 0.2), (1.6, -1)], "vein", width=2)
    bite(m, "top", "top", (-2.6, 2.4), 0.8)
    bite(m, "mid", "side5", (0.0, 1.2), 0.7)
    m.line("mid", "side7", [(0.9, 1.8), (0.9, 0.4)], "slime", width=3)
    m.circle("mid", "side7", (0.9, 0.2), 0.3, "slime")
    return m


def rock_v3():
    m = ropilot.model("Rock_R5_V3", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#3A322D", noise=0.035, mottle=("#2F2824", 0.25, 4), shade=0.2, top=0.15),
        rockd=dict(color="#2A2420", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#4C423B", noise=0.03, shade=0.12, top=0.12),
        tooth=dict(color="#B8AA88", noise=0.025, shade=0.15, top=0.2),
        bite="#1A1512", bitel="#5E534A", slime="#3E8A22",
        gold=dict(color="#FFC83A", noise=0.025, shade=0.12, top=0.25),
        goldd=dict(color="#E09A1E", noise=0.025, shade=0.12, top=0.2),
        glow=dict(color="#F0A020", glow=True))
    S = m.surface
    m.prism("bot", radius=6.4, height=3.6, at=(0, 0, 1.8), role="rockd", sides=8, taper=1.4, turn=15)
    m.prism("mid", radius=9.0, height=4.4, at=(0, 0, 5.8), role="rock", sides=8, taper=1.0, turn=15, shear=(-0.4, -0.4))
    m.prism("top", radius=9.0, height=3.2, at=(-0.4, -0.4, 9.6), role="rockl", sides=8, taper=0.66, turn=15, shear=(0.6, 0.8))
    m.box("bumpA", size=(6, 4.8, 3.2), at=S("mid", "side3", (0, 0.2), sink=1.5), role="rock", chamfer=1.0, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(5.2, 4.2, 2.6), at=S("top", "side7", (0.3, -0.2), sink=1.2), role="rockl", chamfer=0.9, taper=0.65)
    m.box("bumpC", size=(4.6, 3.6, 2.6), at=S("bot", "side6", (0, 0.3), sink=1.1), role="rockd", chamfer=0.8, taper=0.65)
    fangs(m, "fang", [("top", "top", (-3.4, -2.8), 1.15, 2.8, (16, -8, 0)), ("top", "top", (-0.8, -3.9), 1.4, 3.4, (18, 0, 0)),
                      ("top", "top", (1.8, -3.6), 1.1, 2.6, (16, 8, 0))])
    molars(m, "molar", [("top", "top", (-2.1, -3.5), 0.9), ("top", "top", (0.6, -3.9), 0.9)])
    cluster(m, "gA", "top", "top", (0.6, 1.0), 1.8, "gold", "goldd", 5, 7)
    cluster(m, "gB", "mid", "side0", (0.4, 0.1), 1.4, "gold", "goldd", 4, 8)
    cluster(m, "gC", "mid", "side5", (-0.3, 0.2), 1.3, "goldd", "gold", 4, 9)
    cluster(m, "gD", "mid", "side2", (0.2, -0.2), 1.1, "gold", "goldd", 3, 10)
    for name, host, face, uv, s, rot in [("n1", "top", "top", (3.2, -1.6), 1.4, 20), ("n2", "mid", "side1", (-0.6, -0.4), 1.3, -10),
                                         ("n3", "mid", "side6", (0.5, 0.6), 1.2, 35), ("n4", "bumpA", "top", (0, 0), 1.1, 10),
                                         ("n5", "top", "side4", (0, 0), 1.1, -25), ("n6", "bot", "side1", (0, 0.2), 1.0, 5)]:
        m.box(name, size=(1.6 * s, 1.4 * s, 1.1 * s), at=S(host, face, uv, sink=0.35 * s), role="gold", chamfer=0.35 * s, taper=0.75, rot=(0, 0, rot), solo=True)
    cracks = [("mid", "side4", (-1.4, 1.0), (1.5, -0.9)), ("mid", "side7", (-1.2, -0.8), (1.3, 0.9)),
              ("mid", "side1", (0.6, 1.2), (1.8, 0.2)), ("top", "side2", (-1.0, -0.3), (1.0, 0.4))]
    for i, (host, face, a, b) in enumerate(cracks):
        du, dv = b[0] - a[0], b[1] - a[1]
        m.box(f"crack{i}", size=(math.hypot(du, dv), 0.36, 0.12), at=S(host, face, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), sink=0.06),
              role="glow", rot=(0, 0, math.degrees(math.atan2(dv, du))), solo=True)
    m.build()
    bite(m, "top", "top", (-3.0, 2.2), 0.8)
    bite(m, "mid", "side3", (1.4, 1.4), 0.6)
    m.line("mid", "side6", [(-1.2, 1.9), (-1.2, 0.6)], "slime", width=3)
    m.circle("mid", "side6", (-1.2, 0.4), 0.3, "slime")
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
    for c in ("Rock_R5_V1", "Rock_R5_V2", "Rock_R5_V3"):
        join_rock(c)
