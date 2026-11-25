# Astéroïdes de l'anneau 7 « The Nest » (25 nov.), au kit low-poly de Ropilot (ropilot.model, px = 8, sans
# picots : ils sont posés dans Studio sur la roche seulement, comme tools/apply-studs.lua).
# Même méthode que tools/blender/asteroids_r1.py. Zone : roche sable-ocre, brindilles tressées en nid,
# coquilles d'œufs cassées, plumes. Silhouette en coupe large et plate (8 pans), couronne de brindilles.
#   V1 Soft Rock   : coupe de roche ocre à 8 pans + un caillou-lobe, couronne de brindilles tressées sur le dessus
#                    avec deux coquilles d'œufs cassées et des plumes rousses et crème plantées dans le nid
#   V2 Silver Rock : roche ocre-brun plus sombre, grosses grappes de cristaux d'argent, filons d'argent,
#                    un arc de brindilles, une plume et une coquille cassée
#   V3 Gold Rock   : roche brun foncé à deux étages, grappes de cristaux d'or, pépites, fentes lumineuses or,
#                    un petit nid de brindilles avec une coquille dorée
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


def nest(m, pre, c, z, r, n, roles, arc=1.0, start=0.0, seed=1, w=0.45):
    # brindilles tressées : deux rangs de bâtons qui se croisent autour d'un cercle (arc = part du tour)
    rnd = random.Random(seed)
    k = 0
    for layer in range(2):
        rr = r + 0.35 * layer
        zz = z + 0.32 * layer
        for i in range(n):
            a0 = start + 2 * math.pi * arc * (i + 0.5 * layer) / n
            a1 = a0 + 2 * math.pi * arc * 1.35 / n
            if layer and i == n - 1 and arc < 1:
                continue
            p0 = (c[0] + rr * math.cos(a0), c[1] + rr * math.sin(a0), zz + rnd.uniform(-0.12, 0.12) + (0.18 if i % 2 else -0.05))
            p1 = (c[0] + rr * math.cos(a1), c[1] + rr * math.sin(a1), zz + rnd.uniform(-0.12, 0.12) + (-0.05 if i % 2 else 0.18))
            m.beam(f"{pre}{k}", p0, p1, roles[k % len(roles)], width=w, depth=w * 0.9, taper=0.8, roll=rnd.uniform(0, 40))
            k += 1


def shell(m, pre, at, r, role, spot, tilt=(0, 0, 0)):
    # coquille d'œuf cassée : une coupe à bord dentelé
    x, y, z = at
    m.prism(pre + "c", radius=r, height=r * 1.3, at=(x, y, z + r * 0.65), role=role, sides=8, taper=1.2, rot=tilt, solo=True)
    for i, (a, h) in enumerate([(0, 0.7), (110, 0.5), (200, 0.8), (290, 0.45)]):
        ra = math.radians(a)
        m.pyramid(f"{pre}t{i}", size=(r * 0.7, r * 0.35, r * h), at=(x + r * 1.15 * math.cos(ra), y + r * 1.15 * math.sin(ra), z + r * 1.3 + r * h * 0.5 - 0.05),
                  role=role, rot=(0, 0, a + 90), solo=True)


def feather(m, name, at, length, role, lean=(20, 0, 0)):
    # plume : une lame fine qui s'affine, plantée et penchée
    m.box(name, size=(length * 0.55, 0.14, length), at=at, role=role, taper=(0.35, 1.0), pivot="bottom", rot=lean, solo=True)


def rock_v1():
    m = ropilot.model("Rock_R7_V1", px=8, reset=True, symmetric=False)
    m.palette(
        ochre=dict(color="#A8743A", noise=0.03, mottle=("#946330", 0.2, 4), shade=0.2, top=0.15),
        ochred=dict(color="#7E5426", noise=0.03, shade=0.18, top=0.12),
        ochrel=dict(color="#BF8C4E", noise=0.025, shade=0.12, top=0.14),
        pebble=dict(color="#8C6A4A", noise=0.03, shade=0.15, top=0.15),
        twig=dict(color="#5A361A", noise=0.04, streaks=("#47290F", 0.3, "v"), shade=0.1),
        twigl=dict(color="#7A4E28", noise=0.04, streaks=("#5F3A1C", 0.3, "v"), shade=0.1),
        shellc=dict(color="#EEE4CC", noise=0.02, shade=0.1, top=0.1),
        spot="#6F9CB8",
        fea=dict(color="#C0562A", noise=0.02, shade=0.08),
        feal=dict(color="#E0C890", noise=0.02, shade=0.08),
        spine="#7A3014")
    S = m.surface
    sh = (0.4, -0.3)
    m.prism("bot", radius=5.2, height=2.8, at=(0, 0, 1.4), role="ochred", sides=8, taper=1.5, turn=0)
    m.prism("mid", radius=7.8, height=3.2, at=(0, 0, 4.4), role="ochre", sides=8, taper=1.0, turn=0)
    m.prism("top", radius=7.8, height=2.4, at=(0, 0, 7.2), role="ochrel", sides=8, taper=0.74, turn=0, shear=sh)
    m.prism("lobeB", radius=2.6, height=2.0, at=(5.6, 4.6, 1.1), role="ochred", sides=7, taper=1.35, turn=15)
    m.prism("lobeM", radius=3.5, height=2.2, at=(5.6, 4.6, 3.2), role="pebble", sides=7, taper=0.9, turn=15)
    m.prism("lobeT", radius=3.15, height=1.4, at=(5.6, 4.6, 5.0), role="pebble", sides=7, taper=0.55, turn=15, shear=(0.3, 0.3))
    m.box("bumpA", size=(5.2, 4.2, 2.6), at=S("mid", "side5", (0, 0.2), sink=1.5), role="ochre", chamfer=0.9, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.4, 3.6, 2.4), at=S("mid", "side2", (0.4, -0.4), sink=1.3), role="ochred", chamfer=0.8, taper=0.65, rot=(0, 0, -15))
    m.box("bumpC", size=(4.0, 3.2, 2.2), at=S("bot", "side6", (0, 0.3), sink=1.0), role="ochred", chamfer=0.7, taper=0.65)
    # couronne de brindilles tressées
    ztop = 8.4
    nest(m, "tw", sh, ztop + 0.25, 4.5, 9, ("twig", "twigl"), seed=3, w=0.58)
    # brindilles plantées dans les flancs, en croix
    for i, (p0, p1) in enumerate([((-7.2, -2.0, 3.6), (-6.4, -3.6, 6.4)), ((-6.4, -3.4, 3.4), (-7.4, -1.6, 6.0)),
                                  ((2.4, -7.6, 3.4), (4.2, -6.8, 6.2)), ((4.0, -7.0, 3.2), (2.2, -7.4, 6.0))]):
        m.beam(f"tws{i}", p0, p1, "twig" if i % 2 else "twigl", width=0.38, depth=0.34, taper=0.8)
    # coquilles d'œufs cassées dans le nid
    shell(m, "egA", (sh[0] - 1.9, sh[1] + 1.3, ztop - 0.1), 1.3, "shellc", "spot", (8, -10, 0))
    shell(m, "egB", (sh[0] + 2.0, sh[1] - 1.6, ztop - 0.1), 1.0, "shellc", "spot", (-12, 6, 0))
    # plumes plantées dans le nid et dans le caillou
    feather(m, "feA", (sh[0] - 3.6, sh[1] + 2.4, ztop), 3.4, "fea", (-18, -22, 40))
    feather(m, "feB", (sh[0] - 4.2, sh[1] + 1.0, ztop), 2.4, "feal", (-10, -30, 70))
    feather(m, "feC", (sh[0] + 3.4, sh[1] + 2.8, ztop), 3.0, "fea", (-25, 20, -30))
    feather(m, "feD", (5.8, 4.9, 5.4), 2.2, "feal", (-12, 18, 20))
    m.build()
    for p in ("egAc", "egBc"):
        m.circle(p, "side1", (0, 0), 0.22, "spot")
        m.circle(p, "side3", (0.1, 0.15), 0.18, "spot")
        m.circle(p, "side5", (-0.1, -0.1), 0.2, "spot")
    for f in ("feA", "feB", "feC", "feD"):
        m.line(f, "front", [(0, -1.2), (0, 1.0)], "spine", width=1)
    m.blob("mid", "side0", (0.6, 0.0), 1.0, "ochred", seed=2)
    m.blob("mid", "side3", (-0.6, 0.3), 0.9, "ochred", seed=4)
    m.blob("top", "top", (-3.6, -3.0), 0.6, "ochred", seed=5)
    return m


def rock_v2():
    m = ropilot.model("Rock_R7_V2", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#684828", noise=0.03, mottle=("#583C20", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#4A321C", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#7C5A32", noise=0.025, shade=0.12, top=0.14),
        twig=dict(color="#4A2C14", noise=0.04, streaks=("#3A220E", 0.3, "v"), shade=0.1),
        twigl=dict(color="#6A4222", noise=0.04, streaks=("#4F3018", 0.3, "v"), shade=0.1),
        shellc=dict(color="#EEE4CC", noise=0.02, shade=0.1, top=0.1),
        fea=dict(color="#C0562A", noise=0.02, shade=0.08), spine="#7A3014",
        vein="#E4ECF6",
        silver=dict(color="#E6EEF8", noise=0.02, shade=0.1, top=0.2),
        silverd=dict(color="#A8B8D0", noise=0.02, shade=0.1, top=0.15))
    S = m.surface
    sh = (-0.7, 0.6)
    m.prism("bot", radius=5.8, height=3.2, at=(0, 0, 1.6), role="rockd", sides=9, taper=1.45, turn=6)
    m.prism("mid", radius=8.2, height=3.6, at=(0, 0, 5.0), role="rock", sides=9, taper=1.0, turn=6)
    m.prism("top", radius=8.2, height=2.8, at=(0, 0, 8.2), role="rockl", sides=9, taper=0.7, turn=6, shear=sh)
    m.box("bumpA", size=(5.4, 4.4, 3.0), at=S("mid", "side2", (0, 0.2), sink=1.5), role="rock", chamfer=0.9, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.8, 4.0, 2.4), at=S("top", "side6", (0.3, -0.2), sink=1.2), role="rockl", chamfer=0.8, taper=0.65)
    m.box("bumpC", size=(4.2, 3.4, 2.4), at=S("bot", "side5", (0, 0.3), sink=1.0), role="rockd", chamfer=0.7, taper=0.65)
    cluster(m, "sA", "top", "top", (1.2, -0.8), 2.1, "silver", "silverd", 5, 1)
    cluster(m, "sB", "mid", "side0", (0.5, 0.0), 1.5, "silver", "silverd", 4, 2)
    cluster(m, "sC", "mid", "side4", (-0.4, 0.3), 1.4, "silverd", "silver", 4, 3)
    cluster(m, "sD", "bumpA", "top", (0, 0), 1.1, "silver", "silverd", 3, 4)
    cluster(m, "sE", "top", "side7", (0, 0), 1.1, "silver", "silverd", 3, 5)
    cluster(m, "sG", "mid", "side2", (0.6, -0.2), 1.0, "silverd", "silver", 3, 11)
    # un arc de brindilles sur le bord du dessus, une coquille et une plume
    ztop = 9.6
    nest(m, "tw", sh, ztop + 0.2, 4.4, 5, ("twig", "twigl"), arc=0.45, start=math.radians(100), seed=5, w=0.42)
    shell(m, "egA", (sh[0] - 2.2, sh[1] + 1.8, ztop - 0.1), 0.85, "shellc", "spot", (10, -8, 0))
    feather(m, "feA", (sh[0] - 4.0, sh[1] + 0.6, ztop), 2.8, "fea", (-14, -26, 60))
    m.build()
    m.line("mid", "side1", [(-2, -1.5), (-0.6, -0.2), (0.4, 0.1), (1.8, 1.4)], "vein", width=3)
    m.line("mid", "side3", [(-1.8, 1.2), (-0.4, 0.2), (1.6, -0.8)], "vein", width=3)
    m.line("mid", "side6", [(-1.6, -1.2), (0, 0), (0.8, 1.4)], "vein", width=2)
    m.line("top", "side2", [(-1.2, -0.8), (0.2, 0.2), (1.2, 0.5)], "vein", width=2)
    m.line("mid", "side8", [(-1.6, 0.8), (0, 0.2), (1.6, -1)], "vein", width=2)
    m.line("feA", "front", [(0, -1.1), (0, 0.9)], "spine", width=1)
    return m


def rock_v3():
    m = ropilot.model("Rock_R7_V3", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#5A3E24", noise=0.03, mottle=("#4A321C", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#402B18", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#70502E", noise=0.025, shade=0.12, top=0.14),
        twig=dict(color="#4A2C14", noise=0.04, streaks=("#3A220E", 0.3, "v"), shade=0.1),
        twigl=dict(color="#6A4222", noise=0.04, streaks=("#4F3018", 0.3, "v"), shade=0.1),
        fea=dict(color="#C0562A", noise=0.02, shade=0.08), spine="#7A3014",
        gold=dict(color="#FFC83A", noise=0.025, shade=0.12, top=0.25),
        goldd=dict(color="#E09A1E", noise=0.025, shade=0.12, top=0.2),
        glow=dict(color="#F0A020", glow=True))
    S = m.surface
    # deux étages : un grand socle à 10 pans et un plateau décalé plus haut
    m.prism("bot", radius=6.4, height=3.6, at=(0, 0, 1.8), role="rockd", sides=10, taper=1.4, turn=9)
    m.prism("mid", radius=9.0, height=4.2, at=(0, 0, 5.7), role="rock", sides=10, taper=1.0, turn=9)
    m.prism("top", radius=9.0, height=2.4, at=(0, 0, 9.0), role="rockl", sides=10, taper=0.8, turn=9)
    m.prism("lobeT", radius=4.6, height=2.6, at=(2.4, 1.6, 11.3), role="rockl", sides=7, taper=0.72, turn=20, shear=(0.3, 0.4))
    m.box("bumpA", size=(6, 4.8, 3.2), at=S("mid", "side3", (0, 0.2), sink=1.5), role="rock", chamfer=1.0, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(5.2, 4.2, 2.6), at=S("top", "side8", (0.3, -0.2), sink=1.2), role="rockl", chamfer=0.9, taper=0.65)
    m.box("bumpC", size=(4.6, 3.6, 2.6), at=S("bot", "side6", (0, 0.3), sink=1.1), role="rockd", chamfer=0.8, taper=0.65)
    cluster(m, "gA", "lobeT", "top", (0.2, 0.0), 1.7, "gold", "goldd", 5, 7)
    cluster(m, "gB", "mid", "side0", (0.4, 0.1), 1.4, "gold", "goldd", 4, 8)
    cluster(m, "gC", "mid", "side5", (-0.3, 0.2), 1.3, "goldd", "gold", 4, 9)
    cluster(m, "gD", "mid", "side8", (0.2, -0.2), 1.1, "gold", "goldd", 3, 10)
    for name, host, face, uv, s, rot in [("n1", "top", "top", (-4.0, -2.4), 1.5, 20), ("n2", "mid", "side2", (-0.6, -0.4), 1.3, -10),
                                         ("n3", "mid", "side7", (0.5, 0.6), 1.2, 35), ("n4", "bumpA", "top", (0, 0), 1.1, 10),
                                         ("n5", "top", "side4", (0, 0), 1.2, -25), ("n6", "bot", "side1", (0, 0.2), 1.0, 5)]:
        m.box(name, size=(1.6 * s, 1.4 * s, 1.1 * s), at=S(host, face, uv, sink=0.35 * s), role="gold", chamfer=0.35 * s, taper=0.75, rot=(0, 0, rot), solo=True)
    for i, (host, face, a, b) in enumerate([("mid", "side1", (-1.5, -1.2), (1.4, 1.3)), ("mid", "side4", (-1.4, 1.0), (1.5, -0.9)),
                                            ("mid", "side6", (-1.2, -0.8), (1.3, 0.9)), ("mid", "side9", (-1.0, 1.0), (1.2, -1.0))]):
        slit(m, f"crack{i}", host, face, a, b)
    # petit nid de brindilles sur l'étage bas, avec une coquille dorée et une plume
    zl = 10.2
    nc = (-4.0, 1.8)
    nest(m, "tw", nc, zl + 0.2, 2.2, 7, ("twig", "twigl"), seed=9, w=0.4)
    shell(m, "egA", (nc[0], nc[1], zl - 0.1), 1.0, "gold", "goldd", (6, -6, 0))
    feather(m, "feA", (nc[0] - 1.6, nc[1] + 1.4, zl), 2.6, "fea", (-16, -24, 45))
    m.build()
    m.line("feA", "front", [(0, -1.0), (0, 0.8)], "spine", width=1)
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
    for c in ("Rock_R7_V1", "Rock_R7_V2", "Rock_R7_V3"):
        join_rock(c)
