# Astéroïdes de l'anneau 8 « Star Reef » (25 nov.), au kit low-poly de Ropilot (ropilot.model, px = 8, sans
# picots : ils sont posés dans Studio sur la roche seulement, comme tools/apply-studs.lua).
# Même méthode que tools/blender/asteroids_r1.py. Zone : récif de corail dans l'espace, roche turquoise
# trouée, coraux branchus rose corail, éventails orange, coraux-tubes, anémones, coquillages.
#   V1 Soft Rock   : roche turquoise à 9 pans avec une arche de récif sur le côté, trous peints ; sur le dessus
#                    deux coraux branchus roses, une anémone violette ; tubes orange et coquillages sur les flancs
#   V2 Silver Rock : roche bleu-sarcelle plus sombre, grosses grappes de cristaux d'argent, filons d'argent,
#                    un corail branchu rose, une anémone et un coquillage
#   V3 Gold Rock   : roche sarcelle très sombre en double plateau, grappes de cristaux d'or, pépites,
#                    fentes lumineuses or, un éventail de corail orange et un coquillage
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
    m.box(name, size=(math.hypot(du, dv), w, 0.12), at=m.surface(host, face, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), sink=0.06),
          role=role, rot=(0, 0, math.degrees(math.atan2(dv, du))), solo=True)


def coral(m, pre, base, h, roles, seed=1, w=0.5):
    # corail branchu : un tronc et des branches qui montent en s'écartant, bouts plus clairs
    rnd = random.Random(seed)
    x, y, z = base
    top = (x + rnd.uniform(-0.3, 0.3), y + rnd.uniform(-0.3, 0.3), z + h)
    m.beam(pre + "t", (x, y, z - 0.3), top, roles[0], width=w, taper=0.75)
    k = 0
    for i in range(3):
        a = rnd.uniform(0, 2 * math.pi) if i == 0 else a + 2.1 + rnd.uniform(-0.3, 0.3)
        f = 0.35 + 0.2 * i
        s = (x + (top[0] - x) * f, y + (top[1] - y) * f, z + h * f)
        L = h * (0.55 - 0.08 * i)
        e = (s[0] + L * 0.6 * math.cos(a), s[1] + L * 0.6 * math.sin(a), s[2] + L * 0.8)
        m.beam(f"{pre}b{k}", s, e, roles[0], width=w * 0.8, taper=0.7)
        m.crystal(f"{pre}k{k}", radius=w * 0.42, height=w * 0.9, at=e, role=roles[1], sides=5, tip=0.5, taper=1.0, solo=True)
        k += 1
    m.crystal(pre + "kt", radius=w * 0.45, height=w, at=top, role=roles[1], sides=5, tip=0.5, taper=1.0, solo=True)


def anemone(m, pre, base, r, roles, n=8, seed=1):
    # anémone : un pied et une couronne de tentacules qui s'ouvrent
    rnd = random.Random(seed)
    x, y, z = base
    m.prism(pre + "p", radius=r, height=r * 0.9, at=(x, y, z + r * 0.35), role=roles[0], sides=7, taper=1.15, solo=True)
    zt = z + r * 0.8
    for i in range(n):
        a = 2 * math.pi * i / n + rnd.uniform(-0.15, 0.15)
        s = (x + r * 0.6 * math.cos(a), y + r * 0.6 * math.sin(a), zt)
        e = (x + r * 1.6 * math.cos(a), y + r * 1.6 * math.sin(a), zt + r * rnd.uniform(1.0, 1.5))
        m.beam(f"{pre}{i}", s, e, roles[1 + i % (len(roles) - 1)], width=r * 0.32, taper=0.45)


def tubes(m, pre, host, face, uv, s, role, seed=1):
    # coraux-tubes : trois tuyaux debout de hauteurs différentes
    rnd = random.Random(seed)
    for i, (du, dv, hh) in enumerate([(0, 0, 1.0), (0.75, 0.35, 0.7), (-0.6, 0.5, 0.55)]):
        m.prism(f"{pre}{i}", radius=0.38 * s, height=hh * 1.8 * s, at=m.surface(host, face, (uv[0] + du * s, uv[1] + dv * s), sink=0.2),
                role=role, sides=6, taper=1.15, rot=(rnd.uniform(-12, 12), rnd.uniform(-12, 12), 0), solo=True)


def scallop(m, name, host, face, uv, s, role, rot=0):
    # coquille Saint-Jacques : un éventail plat bombé
    m.box(name, size=(1.5 * s, 1.3 * s, 0.45 * s), at=m.surface(host, face, uv, sink=0.1), role=role, taper=(0.35, 0.8), chamfer=0.1 * s,
          axis="y", rot=(0, 0, rot), solo=True)


def fan(m, name, host, face, uv, s, role, rot=0):
    # corail éventail : une plaque fine qui s'évase vers le haut
    m.box(name, size=(1.0 * s, 0.2 * s, 2.0 * s), at=m.surface(host, face, uv, sink=0.15), role=role, taper=(2.6, 1.0), pivot="bottom",
          rot=(0, 0, rot), solo=True)


def rock_v1():
    m = ropilot.model("Rock_R8_V1", px=8, reset=True, symmetric=False)
    m.palette(
        reef=dict(color="#1F8A86", noise=0.03, mottle=("#197672", 0.2, 4), shade=0.2, top=0.15),
        reefd=dict(color="#156663", noise=0.03, shade=0.18, top=0.12),
        reefl=dict(color="#2AA39C", noise=0.025, shade=0.12, top=0.14),
        hole="#0E4E4C", holel="#37B0A8",
        pink=dict(color="#E04C78", noise=0.025, shade=0.1, top=0.15),
        pinkl=dict(color="#FF8AA8", noise=0.02, shade=0.08),
        orange=dict(color="#F07A2A", noise=0.025, shade=0.1, top=0.15),
        orangel="#FFB070",
        purple=dict(color="#8A4CC8", noise=0.02, shade=0.1),
        purplel=dict(color="#C07AF0", noise=0.02, shade=0.08),
        shellc=dict(color="#F2D7B8", noise=0.02, shade=0.1, top=0.1), shellr="#D08A6A")
    S = m.surface
    sh = (-0.5, 0.4)
    m.prism("bot", radius=5.4, height=2.8, at=(0, 0, 1.4), role="reefd", sides=9, taper=1.42, turn=5)
    m.prism("mid", radius=7.6, height=3.2, at=(0, 0, 4.4), role="reef", sides=9, taper=1.0, turn=5)
    m.prism("top", radius=7.6, height=2.6, at=(0, 0, 7.3), role="reefl", sides=9, taper=0.68, turn=5, shear=sh)
    # arche de récif : un pilier à côté et un pont de roche
    m.prism("lobeP", radius=2.0, height=6.6, at=(10.0, -5.8, 3.3), role="reef", sides=6, taper=0.8, turn=10)
    m.beam("lobeA", (5.2, -3.0, 6.6), (10.2, -5.9, 6.4), "reefl", width=2.6, depth=1.9, chamfer=0.3)
    m.box("bumpA", size=(5.0, 4.2, 2.6), at=S("mid", "side3", (0, 0.2), sink=1.5), role="reef", chamfer=0.9, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.4, 3.6, 2.4), at=S("mid", "side6", (0.4, -0.4), sink=1.3), role="reefd", chamfer=0.8, taper=0.65, rot=(0, 0, -15))
    m.box("bumpC", size=(4.0, 3.2, 2.0), at=S("top", "top", (2.4, 1.8), sink=1.1), role="reefl", chamfer=0.7, taper=0.6, rot=(0, 0, 25))
    ztop = 8.6
    coral(m, "coA", (sh[0] - 2.4, sh[1] + 1.4, ztop), 3.6, ("pink", "pinkl"), seed=2, w=0.75)
    coral(m, "coD", (sh[0] - 0.6, sh[1] + 2.8, ztop), 2.6, ("pink", "pinkl"), seed=11, w=0.6)
    coral(m, "coB", (sh[0] + 1.6, sh[1] - 2.4, ztop), 2.6, ("orange", "pinkl"), seed=5, w=0.6)
    anemone(m, "anA", (sh[0] - 2.6, sh[1] - 1.8, ztop - 0.1), 1.0, ("purple", "purplel", "pinkl"), seed=3)
    coral(m, "coC", (10.2, -5.9, 7.2), 2.0, ("pink", "pinkl"), seed=8, w=0.5)
    tubes(m, "tuA", "mid", "side1", (0.2, 0.0), 1.4, "orange", seed=1)
    tubes(m, "tuB", "mid", "side5", (-0.3, -0.2), 1.3, "orange", seed=2)
    fan(m, "faA", "top", "top", (3.0, -2.0), 1.2, "orange", rot=-30)
    scallop(m, "scA", "bumpA", "top", (0.2, 0.0), 1.6, "shellc", rot=20)
    scallop(m, "scB", "mid", "side8", (-0.2, 0.2), 1.4, "shellc", rot=-10)
    m.build()
    # trous du récif
    for part, face, at, r in [("mid", "side0", (0.6, 0.4), 0.5), ("mid", "side0", (-0.8, -0.3), 0.35), ("mid", "side2", (0.2, 0.3), 0.45),
                              ("mid", "side4", (-0.4, -0.2), 0.4), ("top", "top", (0.6, 2.6), 0.45), ("top", "top", (-3.6, 0.2), 0.35),
                              ("lobeP", "side2", (0, 0.6), 0.35), ("lobeP", "side4", (0, -0.8), 0.3), ("mid", "side6", (-1.2, 0.8), 0.3)]:
        m.circle(part, face, at, r, "hole")
        m.circle(part, face, (at[0] - r * 0.3, at[1] + r * 0.35), r * 0.3, "holel")
    for sc in ("scA", "scB"):
        for dx in (-0.5, 0.0, 0.5):
            m.line(sc, "top", [(dx * 0.3, -0.7), (dx, 0.6)], "shellr", width=1)
    for t in ("tuA0", "tuA1", "tuA2", "tuB0", "tuB1", "tuB2"):
        m.circle(t, "top", (0, 0), 0.3, "hole")
    m.line("faA", "front", [(-1.2, 0.9), (0, -0.9), (1.2, 0.9)], "orangel", width=1)
    m.line("faA", "front", [(0, -0.9), (0, 0.9)], "orangel", width=1)
    return m


def rock_v2():
    m = ropilot.model("Rock_R8_V2", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#175C66", noise=0.03, mottle=("#124C55", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#0F434B", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#1E6E78", noise=0.025, shade=0.12, top=0.14),
        hole="#0A3036",
        pink=dict(color="#E04C78", noise=0.025, shade=0.1, top=0.15),
        pinkl=dict(color="#FF8AA8", noise=0.02, shade=0.08),
        purple=dict(color="#8A4CC8", noise=0.02, shade=0.1),
        purplel=dict(color="#C07AF0", noise=0.02, shade=0.08),
        shellc=dict(color="#F2D7B8", noise=0.02, shade=0.1, top=0.1), shellr="#D08A6A",
        vein="#E4ECF6",
        silver=dict(color="#E6EEF8", noise=0.02, shade=0.1, top=0.2),
        silverd=dict(color="#A8B8D0", noise=0.02, shade=0.1, top=0.15))
    S = m.surface
    sh = (0.8, -0.5)
    m.prism("bot", radius=5.8, height=3.2, at=(0, 0, 1.6), role="rockd", sides=8, taper=1.42, turn=12)
    m.prism("mid", radius=8.2, height=3.8, at=(0, 0, 5.1), role="rock", sides=8, taper=1.0, turn=12)
    m.prism("top", radius=8.2, height=3.0, at=(0, 0, 8.5), role="rockl", sides=8, taper=0.64, turn=12, shear=sh)
    m.box("bumpA", size=(5.4, 4.4, 3.0), at=S("mid", "side2", (0, 0.2), sink=1.5), role="rock", chamfer=0.9, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.8, 4.0, 2.4), at=S("top", "side5", (0.3, -0.2), sink=1.2), role="rockl", chamfer=0.8, taper=0.65)
    m.box("bumpC", size=(4.2, 3.4, 2.4), at=S("bot", "side4", (0, 0.3), sink=1.0), role="rockd", chamfer=0.7, taper=0.65)
    cluster(m, "sA", "top", "top", (0.8, -0.4), 2.1, "silver", "silverd", 5, 1)
    cluster(m, "sB", "mid", "side0", (0.5, 0.0), 1.5, "silver", "silverd", 4, 2)
    cluster(m, "sC", "mid", "side4", (-0.4, 0.3), 1.4, "silverd", "silver", 4, 3)
    cluster(m, "sD", "bumpA", "top", (0, 0), 1.1, "silver", "silverd", 3, 4)
    cluster(m, "sE", "top", "side6", (0, 0), 1.1, "silver", "silverd", 3, 5)
    cluster(m, "sG", "mid", "side2", (0.6, -0.2), 1.0, "silverd", "silver", 3, 11)
    ztop = 10.0
    coral(m, "coA", (sh[0] - 3.0, sh[1] + 2.0, ztop), 2.4, ("pink", "pinkl"), seed=4)
    anemone(m, "anA", (sh[0] + 2.6, sh[1] + 2.4, ztop - 0.1), 0.65, ("purple", "purplel", "pinkl"), seed=6)
    scallop(m, "scA", "mid", "side7", (0.0, 0.0), 1.0, "shellc", rot=10)
    m.build()
    m.line("mid", "side1", [(-2, -1.5), (-0.6, -0.2), (0.4, 0.1), (1.8, 1.4)], "vein", width=3)
    m.line("mid", "side3", [(-1.8, 1.2), (-0.4, 0.2), (1.6, -0.8)], "vein", width=3)
    m.line("mid", "side6", [(-1.6, -1.2), (0, 0), (0.8, 1.4)], "vein", width=2)
    m.line("top", "side2", [(-1.2, -0.8), (0.2, 0.2), (1.2, 0.5)], "vein", width=2)
    for part, face, at, r in [("mid", "side5", (0.4, 0.3), 0.45), ("top", "side1", (-0.6, 0.0), 0.35), ("top", "top", (-3.4, -1.6), 0.4)]:
        m.circle(part, face, at, r, "hole")
    for dx in (-0.35, 0.0, 0.35):
        m.line("scA", "top", [(dx * 0.3, -0.5), (dx, 0.45)], "shellr", width=1)
    return m


def rock_v3():
    m = ropilot.model("Rock_R8_V3", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#11444C", noise=0.03, mottle=("#0D383F", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#0B3036", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#18565E", noise=0.025, shade=0.12, top=0.14),
        hole="#072226",
        orange=dict(color="#F07A2A", noise=0.025, shade=0.1, top=0.15),
        orangel=dict(color="#FFB070", noise=0.02, shade=0.08),
        shellc=dict(color="#F2D7B8", noise=0.02, shade=0.1, top=0.1), shellr="#D08A6A",
        gold=dict(color="#FFC83A", noise=0.025, shade=0.12, top=0.25),
        goldd=dict(color="#E09A1E", noise=0.025, shade=0.12, top=0.2),
        glow=dict(color="#F0A020", glow=True))
    S = m.surface
    # double plateau : deux masses côte à côte de hauteurs différentes
    m.prism("bot", radius=6.2, height=3.6, at=(0, 0, 1.8), role="rockd", sides=10, taper=1.4, turn=0)
    m.prism("mid", radius=8.8, height=4.4, at=(0, 0, 5.8), role="rock", sides=10, taper=1.0, turn=0)
    m.prism("top", radius=8.8, height=3.4, at=(0, 0, 9.7), role="rockl", sides=10, taper=0.62, turn=0, shear=(-0.6, 0.6))
    m.prism("lobeB", radius=3.6, height=3.0, at=(6.4, 4.0, 1.9), role="rockd", sides=7, taper=1.35, turn=15)
    m.prism("lobeM", radius=4.9, height=3.4, at=(6.4, 4.0, 5.1), role="rock", sides=7, taper=1.0, turn=15)
    m.prism("lobeT", radius=4.9, height=2.4, at=(6.4, 4.0, 7.9), role="rockl", sides=7, taper=0.6, turn=15, shear=(0.3, 0.3))
    m.box("bumpA", size=(6, 4.8, 3.2), at=S("mid", "side3", (0, 0.2), sink=1.5), role="rock", chamfer=1.0, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(5.2, 4.2, 2.6), at=S("top", "side7", (0.3, -0.2), sink=1.2), role="rockl", chamfer=0.9, taper=0.65)
    m.box("bumpC", size=(4.6, 3.6, 2.6), at=S("bot", "side6", (0, 0.3), sink=1.1), role="rockd", chamfer=0.8, taper=0.65)
    cluster(m, "gA", "top", "top", (-0.6, 0.4), 1.8, "gold", "goldd", 5, 7)
    cluster(m, "gB", "mid", "side0", (0.4, 0.1), 1.4, "gold", "goldd", 4, 8)
    cluster(m, "gC", "mid", "side5", (-0.3, 0.2), 1.3, "goldd", "gold", 4, 9)
    cluster(m, "gD", "lobeT", "top", (0.2, -0.2), 1.1, "gold", "goldd", 4, 10)
    for name, host, face, uv, s, rot in [("n1", "top", "top", (2.6, -2.2), 1.5, 20), ("n2", "mid", "side2", (-0.6, -0.4), 1.3, -10),
                                         ("n3", "mid", "side8", (0.5, 0.6), 1.2, 35), ("n4", "bumpA", "top", (0, 0), 1.1, 10),
                                         ("n5", "top", "side4", (0, 0), 1.2, -25), ("n6", "lobeM", "side3", (0, 0.2), 1.0, 5)]:
        m.box(name, size=(1.6 * s, 1.4 * s, 1.1 * s), at=S(host, face, uv, sink=0.35 * s), role="gold", chamfer=0.35 * s, taper=0.75, rot=(0, 0, rot), solo=True)
    for i, (host, face, a, b) in enumerate([("mid", "side1", (-1.5, -1.2), (1.4, 1.3)), ("mid", "side4", (-1.4, 1.0), (1.5, -0.9)),
                                            ("mid", "side6", (-1.2, -0.8), (1.3, 0.9)), ("mid", "side9", (-1.0, 1.0), (1.2, -1.0))]):
        slit(m, f"crack{i}", host, face, a, b)
    coral(m, "coA", (-0.6 - 3.6, 0.6 - 2.4, 11.4), 2.6, ("orange", "orangel"), seed=4, w=0.6)
    scallop(m, "scA", "lobeM", "side5", (0.0, 0.0), 1.0, "shellc", rot=0)
    m.build()
    for part, face, at, r in [("mid", "side7", (0.4, 0.3), 0.45), ("lobeM", "side1", (-0.6, 0.0), 0.4), ("top", "side1", (0.2, 0.0), 0.35)]:
        m.circle(part, face, at, r, "hole")
    for dx in (-0.35, 0.0, 0.35):
        m.line("scA", "top", [(dx * 0.3, -0.5), (dx, 0.45)], "shellr", width=1)
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
    for c in ("Rock_R8_V1", "Rock_R8_V2", "Rock_R8_V3"):
        join_rock(c)
