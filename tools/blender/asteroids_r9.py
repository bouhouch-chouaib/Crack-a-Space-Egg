# Astéroïdes de l'anneau 9 « Storm Halo » (25 nov.), au kit low-poly de Ropilot (ropilot.model, px = 8, sans
# picots : ils sont posés dans Studio sur la roche seulement, comme tools/apply-studs.lua).
# Même méthode que tools/blender/asteroids_r1.py. Zone : roche gris-violet, nuages violets solidifiés (gros
# blocs très chanfreinés) en halo autour de la roche, éclairs jaunes en zigzag (néon), petits paratonnerres.
#   V1 Soft Rock   : roche gris-violet à 7 pans au dessus penché, ceinture de nuages violets tout autour (le halo),
#                    éclairs jaunes en zigzag sur les flancs, deux paratonnerres sur le dessus
#   V2 Silver Rock : roche violet-gris plus sombre, grosses grappes de cristaux d'argent, filons d'argent,
#                    quelques nuages, un paratonnerre et un éclair
#   V3 Gold Rock   : roche violet très sombre à 8 pans, grappes de cristaux d'or, pépites, fentes lumineuses or,
#                    nuages, un paratonnerre et un éclair jaune
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
    du, dv = b[0] - a[0], b[1] - a[1]
    m.box(name, size=(math.hypot(du, dv) + w * 0.6, w, 0.12), at=m.surface(host, face, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), sink=0.06),
          role=role, rot=(0, 0, math.degrees(math.atan2(dv, du))), solo=True)


def bolt(m, pre, host, face, c, s, role="glow", flip=False):
    # éclair en zigzag posé sur une face (centre c, taille s)
    pts = [(-0.35, 1.0), (0.25, 0.15), (-0.2, 0.05), (0.4, -1.0)]
    if flip:
        pts = [(-x, y) for x, y in pts]
    pts = [(c[0] + x * s, c[1] + y * s) for x, y in pts]
    for i in range(3):
        slit(m, f"{pre}{i}", host, face, pts[i], pts[i + 1], role, w=0.34 * s)


def puff(m, pre, at, s, roles, seed=1, turn=0):
    # nuage solidifié : une galette à 8 pans et trois bosses rondes par-dessus (low-poly)
    rnd = random.Random(seed)
    x, y, z = at
    c, si = math.cos(math.radians(turn)), math.sin(math.radians(turn))
    m.prism(pre + "a", radius=1.6 * s, height=0.9 * s, at=(x, y, z), role=roles[0], sides=8, taper=0.85, turn=rnd.uniform(0, 45), solo=True)
    for i, (dx, dz, k) in enumerate([(-0.75, 0.55, 0.75), (0.15, 0.8, 0.9), (0.95, 0.5, 0.6)]):
        m.prism(f"{pre}{'bcd'[i]}", radius=1.6 * s * k * 0.75, height=1.1 * s * k, at=(x + dx * s * c, y + dx * s * si, z + dz * s),
                role=roles[1 + i % (len(roles) - 1)], sides=8, taper=0.55, turn=rnd.uniform(0, 45), solo=True)


def rod(m, pre, base, h, roles):
    # paratonnerre : socle, tige, deux barrettes et une pointe cuivrée
    x, y, z = base
    m.prism(pre + "s", radius=0.55, height=0.4, at=(x, y, z + 0.1), role=roles[1], sides=6, taper=0.8, solo=True)
    m.prism(pre + "t", radius=0.2, height=h, at=(x, y, z + 0.3 + h / 2), role=roles[0], sides=6, solo=True)
    m.box(pre + "x", size=(1.1, 0.2, 0.2), at=(x, y, z + 0.3 + h * 0.62), role=roles[0], solo=True)
    m.box(pre + "y", size=(0.7, 0.2, 0.2), at=(x, y, z + 0.3 + h * 0.8), role=roles[0], solo=True)
    m.crystal(pre + "p", radius=0.3, height=0.9, at=(x, y, z + 0.25 + h), role=roles[2], sides=4, tip=0.6, solo=True)


def rock_v1():
    m = ropilot.model("Rock_R9_V1", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#544A66", noise=0.03, mottle=("#483F5A", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#3D354D", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#655A7C", noise=0.025, shade=0.12, top=0.14),
        cloud=dict(color="#6E48A8", noise=0.02, shade=0.15, top=0.2),
        cloudl=dict(color="#8E68C8", noise=0.02, shade=0.12, top=0.2),
        cloudd=dict(color="#553888", noise=0.02, shade=0.15, top=0.15),
        steel=dict(color="#7E8496", noise=0.02, shade=0.1), steeld=dict(color="#4E5262", noise=0.02, shade=0.1),
        copper=dict(color="#D08A3A", noise=0.02, shade=0.1),
        scar="#2E2840",
        glow=dict(color="#F2C400", glow=True))
    S = m.surface
    sh = (1.0, -0.6)
    m.prism("bot", radius=5.0, height=3.0, at=(0, 0, 1.5), role="rockd", sides=7, taper=1.45, turn=0)
    m.prism("mid", radius=7.3, height=3.4, at=(0, 0, 4.7), role="rock", sides=7, taper=1.0, turn=0)
    m.prism("top", radius=7.3, height=3.0, at=(0, 0, 7.9), role="rockl", sides=7, taper=0.64, turn=0, shear=sh)
    m.box("bumpA", size=(4.6, 3.8, 2.4), at=S("top", "top", (-2.2, 1.6), sink=1.0), role="rockl", chamfer=0.7, taper=0.6, rot=(0, 0, 25))
    m.box("bumpB", size=(4.0, 3.2, 2.2), at=S("bot", "side3", (0, 0.3), sink=1.0), role="rockd", chamfer=0.7, taper=0.65)
    # le halo : une ceinture de nuages solidifiés autour de la roche
    for i in range(7):
        a = 2 * math.pi * i / 7 + 0.3
        r = 7.4 + (0.4 if i % 2 else 0)
        s = 1.3 if i % 3 else 1.55
        puff(m, f"cl{i}", (r * math.cos(a), r * math.sin(a), 5.6 + (0.5 if i % 2 else -0.1)), s,
             ("cloud", "cloudl", "cloudd") if i % 2 else ("cloudd", "cloud", "cloudl"), seed=i, turn=math.degrees(a) + 90)
    # éclairs sur les flancs du haut
    bolt(m, "boA", "top", "side1", (0.0, 0.2), 1.5)
    bolt(m, "boB", "top", "side4", (0.2, 0.2), 1.5, flip=True)
    bolt(m, "boC", "top", "top", (1.2, -0.6), 1.6)
    bolt(m, "boD", "top", "side6", (0.0, 0.2), 1.4, flip=True)
    # paratonnerres
    ztop = 9.4
    rod(m, "roA", (sh[0] - 1.6, sh[1] - 2.0, ztop), 2.6, ("steel", "steeld", "copper"))
    rod(m, "roB", (sh[0] + 2.6, sh[1] + 1.6, ztop), 1.8, ("steel", "steeld", "copper"))
    m.build()
    # brûlures d'éclair autour des paratonnerres
    m.blob("top", "top", (-1.6, -2.0), 0.9, "scar", seed=3)
    m.blob("top", "top", (2.6, 1.6), 0.7, "scar", seed=4)
    return m


def rock_v2():
    m = ropilot.model("Rock_R9_V2", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#443A56", noise=0.03, mottle=("#3A3149", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#30293F", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#544A6A", noise=0.025, shade=0.12, top=0.14),
        cloud=dict(color="#6E48A8", noise=0.02, shade=0.15, top=0.2),
        cloudl=dict(color="#8E68C8", noise=0.02, shade=0.12, top=0.2),
        steel=dict(color="#7E8496", noise=0.02, shade=0.1), steeld=dict(color="#4E5262", noise=0.02, shade=0.1),
        copper=dict(color="#D08A3A", noise=0.02, shade=0.1),
        vein="#E4ECF6",
        silver=dict(color="#E6EEF8", noise=0.02, shade=0.1, top=0.2),
        silverd=dict(color="#A8B8D0", noise=0.02, shade=0.1, top=0.15),
        glow=dict(color="#F2C400", glow=True))
    S = m.surface
    sh = (-0.8, 0.6)
    m.prism("bot", radius=5.8, height=3.2, at=(0, 0, 1.6), role="rockd", sides=9, taper=1.42, turn=8)
    m.prism("mid", radius=8.0, height=3.8, at=(0, 0, 5.1), role="rock", sides=9, taper=1.0, turn=8)
    m.prism("top", radius=8.0, height=3.2, at=(0, 0, 8.6), role="rockl", sides=9, taper=0.6, turn=8, shear=sh)
    m.box("bumpA", size=(5.4, 4.4, 3.0), at=S("mid", "side2", (0, 0.2), sink=1.4), role="rock", chamfer=0.9, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.8, 4, 2.4), at=S("top", "side6", (0.3, -0.2), sink=1.1), role="rockl", chamfer=0.8, taper=0.65)
    m.box("bumpC", size=(4.2, 3.4, 2.4), at=S("bot", "side5", (0, 0.3), sink=1.0), role="rockd", chamfer=0.7, taper=0.65)
    cluster(m, "sA", "top", "top", (1.0, -0.5), 2.1, "silver", "silverd", 5, 1)
    cluster(m, "sB", "mid", "side0", (0.5, 0.0), 1.5, "silver", "silverd", 4, 2)
    cluster(m, "sC", "mid", "side4", (-0.4, 0.3), 1.4, "silverd", "silver", 4, 3)
    cluster(m, "sD", "bumpA", "top", (0, 0), 1.1, "silver", "silverd", 3, 4)
    cluster(m, "sE", "top", "side7", (0, 0), 1.1, "silver", "silverd", 3, 5)
    cluster(m, "sG", "mid", "side2", (0.6, -0.2), 1.0, "silverd", "silver", 3, 11)
    for i, a in enumerate((2.3, 3.6, 5.2)):
        puff(m, f"cl{i}", (7.9 * math.cos(a), 7.9 * math.sin(a), 4.6 + 0.4 * i), 1.15, ("cloud", "cloudl"), seed=i + 3, turn=math.degrees(a) + 90)
    bolt(m, "boA", "mid", "side6", (0.2, 0.0), 1.7)
    rod(m, "roA", (sh[0] - 2.6, sh[1] + 1.8, 10.2), 2.4, ("steel", "steeld", "copper"))
    m.build()
    m.line("mid", "side1", [(-2, -1.5), (-0.6, -0.2), (0.4, 0.1), (1.8, 1.4)], "vein", width=3)
    m.line("mid", "side3", [(-1.8, 1.2), (-0.4, 0.2), (1.6, -0.8)], "vein", width=3)
    m.line("mid", "side8", [(-1.6, -1.2), (0, 0), (0.8, 1.4)], "vein", width=2)
    m.line("top", "side2", [(-1.2, -0.8), (0.2, 0.2), (1.2, 0.5)], "vein", width=2)
    return m


def rock_v3():
    m = ropilot.model("Rock_R9_V3", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#342B46", noise=0.03, mottle=("#2B2339", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#241E32", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#433858", noise=0.025, shade=0.12, top=0.14),
        cloud=dict(color="#6E48A8", noise=0.02, shade=0.15, top=0.2),
        cloudl=dict(color="#8E68C8", noise=0.02, shade=0.12, top=0.2),
        steel=dict(color="#7E8496", noise=0.02, shade=0.1), steeld=dict(color="#4E5262", noise=0.02, shade=0.1),
        gold=dict(color="#FFC83A", noise=0.025, shade=0.12, top=0.25),
        goldd=dict(color="#E09A1E", noise=0.025, shade=0.12, top=0.2),
        glow=dict(color="#F2C400", glow=True))
    S = m.surface
    # socle à 8 pans et un plateau haut décalé (marche)
    m.prism("bot", radius=6.4, height=3.6, at=(0, 0, 1.8), role="rockd", sides=8, taper=1.4, turn=20)
    m.prism("mid", radius=9.0, height=4.4, at=(0, 0, 5.8), role="rock", sides=8, taper=1.0, turn=20)
    m.prism("top", radius=9.0, height=2.6, at=(0, 0, 9.3), role="rockl", sides=8, taper=0.78, turn=20)
    m.prism("lobeT", radius=4.8, height=2.4, at=(-2.2, -1.8, 11.6), role="rockl", sides=6, taper=0.7, turn=0, shear=(-0.3, -0.3))
    m.box("bumpA", size=(6, 4.8, 3.2), at=S("mid", "side3", (0, 0.2), sink=1.5), role="rock", chamfer=1.0, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(5.2, 4.2, 2.6), at=S("top", "side6", (0.3, -0.2), sink=1.2), role="rockl", chamfer=0.9, taper=0.65)
    m.box("bumpC", size=(4.6, 3.6, 2.6), at=S("bot", "side5", (0, 0.3), sink=1.1), role="rockd", chamfer=0.8, taper=0.65)
    cluster(m, "gA", "lobeT", "top", (0.0, 0.2), 1.7, "gold", "goldd", 5, 7)
    cluster(m, "gB", "mid", "side0", (0.4, 0.1), 1.4, "gold", "goldd", 4, 8)
    cluster(m, "gC", "mid", "side5", (-0.3, 0.2), 1.3, "goldd", "gold", 4, 9)
    cluster(m, "gD", "mid", "side7", (0.2, -0.2), 1.1, "gold", "goldd", 3, 10)
    for name, host, face, uv, s, rot in [("n1", "top", "top", (3.4, 2.2), 1.5, 20), ("n2", "mid", "side2", (-0.6, -0.4), 1.3, -10),
                                         ("n3", "mid", "side6", (0.5, 0.6), 1.2, 35), ("n4", "bumpA", "top", (0, 0), 1.1, 10),
                                         ("n5", "top", "side4", (0, 0), 1.2, -25), ("n6", "bot", "side1", (0, 0.2), 1.0, 5)]:
        m.box(name, size=(1.6 * s, 1.4 * s, 1.1 * s), at=S(host, face, uv, sink=0.35 * s), role="gold", chamfer=0.35 * s, taper=0.75, rot=(0, 0, rot), solo=True)
    bolt(m, "boA", "mid", "side1", (0.0, 0.0), 1.8)
    bolt(m, "boB", "mid", "side4", (0.2, 0.0), 1.7, flip=True)
    for i, a in enumerate((0.9, 4.0)):
        puff(m, f"cl{i}", (8.8 * math.cos(a), 8.8 * math.sin(a), 5.0 + 0.6 * i), 1.3, ("cloud", "cloudl"), seed=i + 7, turn=math.degrees(a) + 90)
    rod(m, "roA", (3.6, -2.4, 10.6), 2.2, ("steel", "steeld", "gold"))
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
        f().build()
    for c in ("Rock_R9_V1", "Rock_R9_V2", "Rock_R9_V3"):
        join_rock(c)
