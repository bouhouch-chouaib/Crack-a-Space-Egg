# Astéroïdes de l'anneau 10 « Clockwork Belt » (25 nov.), au kit low-poly de Ropilot (ropilot.model, px = 8,
# sans picots : ils sont posés dans Studio sur la roche seulement). Même méthode que asteroids_r1.py.
# Silhouette propre à l'anneau : corps à 6 pans (7 pour V3), comme un carter de machine, dessus plat.
#   V1 Soft Rock   : acier bleuté à deux lobes, ceinture de cuivre rivetée, gros rouage de laiton debout sur la
#                    face avant, rouage couché sur le dessus, cheminée, tuyaux à brides, hublots turquoise (néon)
#   V2 Silver Rock : acier sombre, grosses grappes de cristaux d'argent, filons d'argent peints, un rouage,
#                    un tuyau de cuivre et des rivets de laiton
#   V3 Gold Rock   : bronze sombre et ceinture d'acier rivetée d'or, grappes de cristaux d'or, pépites,
#                    rouage doré, fentes lumineuses orange (néon)
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


def gear(m, pre, host, face, uv, r, h, role, hub, teeth=8, sink=0.1, spin=0):
    """Rouage posé à plat sur une face : disque, moyeu hexagonal, dents tout autour."""
    S = m.surface
    m.prism(pre, radius=r, height=h, at=S(host, face, uv, sink=sink), role=role, sides=teeth * 2, turn=spin, solo=True)
    m.prism(pre + "h", radius=r * 0.38, height=h + 0.25, at=S(host, face, uv, sink=sink), role=hub, sides=6, turn=spin, solo=True)
    for i in range(teeth):
        a = 2 * math.pi * i / teeth + math.radians(spin)
        m.box(f"{pre}t{i}", size=(0.55 * r, 0.42 * r, h),
              at=S(host, face, (uv[0] + math.cos(a) * r * 1.02, uv[1] + math.sin(a) * r * 1.02), sink=sink),
              role=role, rot=(0, 0, math.degrees(a)), solo=True)


def rivets(m, pre, host, face, pts, role, r=0.28):
    for i, uv in enumerate(pts):
        m.prism(f"{pre}{i}", radius=r, height=0.3, at=m.surface(host, face, uv, sink=0.05), role=role, sides=6, taper=0.55, solo=True)


def pipe(m, pre, host, face, a, b, role, flange, w=0.75):
    """Tuyau chanfreiné d'un point à l'autre d'une face, avec une bride à chaque bout."""
    S = m.surface
    du, dv = b[0] - a[0], b[1] - a[1]
    L = math.hypot(du, dv)
    ang = math.degrees(math.atan2(dv, du))
    m.box(pre, size=(L, w, w), at=S(host, face, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), sink=w * 0.35), role=role,
          chamfer=w * 0.25, rot=(0, 0, ang), solo=True)
    for j, p in enumerate((a, b)):
        m.box(f"{pre}f{j}", size=(0.35, w * 1.45, w * 1.45), at=S(host, face, p, sink=w * 0.5), role=flange, rot=(0, 0, ang), solo=True)


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


def rock_v1():
    m = ropilot.model("Rock_R10_V1", px=8, reset=True, symmetric=False)
    m.palette(
        steel=dict(color="#4A6076", noise=0.03, mottle=("#3E5266", 0.2, 4), shade=0.2, top=0.15),
        steeld=dict(color="#34455A", noise=0.03, shade=0.18, top=0.12),
        steell=dict(color="#5E7790", noise=0.025, shade=0.12, top=0.12),
        copper=dict(color="#9A4A28", noise=0.03, shade=0.15, top=0.15),
        copperd=dict(color="#6E321C", noise=0.03, shade=0.12),
        brass=dict(color="#9C7428", noise=0.025, shade=0.12, top=0.18),
        brassd=dict(color="#6E5018", noise=0.025, shade=0.1),
        seam="#26323F", glow=dict(color="#18C8B8", glow=True))
    S = m.surface
    m.prism("bot", radius=5.0, height=3.0, at=(0, 0, 1.5), role="steeld", sides=6, taper=1.45)
    m.prism("mid", radius=7.6, height=3.4, at=(0, 0, 4.7), role="copper", sides=6, taper=1.0)
    m.prism("top", radius=7.6, height=2.6, at=(0, 0, 7.7), role="steel", sides=6, taper=0.66, shear=(0.6, -0.4))
    m.prism("lobeB", radius=3.4, height=2.0, at=(-5.6, 3.8, 1.8), role="steeld", sides=6, taper=1.4, turn=30)
    m.prism("lobeM", radius=4.8, height=2.6, at=(-5.6, 3.8, 4.1), role="copper", sides=6, taper=1.0, turn=30)
    m.prism("lobeT", radius=4.8, height=2.0, at=(-5.6, 3.8, 6.4), role="steell", sides=6, taper=0.62, turn=30, shear=(-0.4, 0.3))
    m.box("bumpA", size=(5.0, 4.2, 2.6), at=S("mid", "side4", (0.8, 0.2), sink=1.3), role="steel", chamfer=0.8, taper=0.65, rot=(0, 0, 10))
    m.box("bumpB", size=(4.4, 3.6, 2.2), at=S("bot", "side1", (0, 0.3), sink=1.0), role="steeld", chamfer=0.7, taper=0.65)
    m.box("bumpC", size=(4.6, 3.4, 2.0), at=S("top", "top", (2.2, 1.8), sink=1.0), role="steell", chamfer=0.7, taper=0.6, rot=(0, 0, 25))
    m.box("bumpD", size=(4.2, 3.4, 2.2), at=S("top", "side3", (-0.4, -0.2), sink=1.0), role="steel", chamfer=0.7, taper=0.6, rot=(0, 0, -20))
    m.box("bumpE", size=(3.6, 3.0, 2.0), at=S("lobeT", "top", (-0.8, 0.9), sink=0.9), role="steell", chamfer=0.6, taper=0.6, rot=(0, 0, 35))
    m.box("bumpF", size=(4.0, 3.2, 2.2), at=S("bot", "side4", (0.4, 0.2), sink=1.0), role="steeld", chamfer=0.7, taper=0.65)
    gear(m, "gA", "mid", "side0", (0.6, 0.1), 2.5, 0.7, "brass", "brassd", 9, 0.15, 10)
    gear(m, "gB", "top", "top", (-1.8, -1.2), 1.6, 0.5, "brass", "copperd", 8, 0.1, 0)
    gear(m, "gC", "lobeM", "side3", (0.0, 0.0), 1.3, 0.5, "brassd", "brass", 6, 0.1, 15)
    pipe(m, "pA", "mid", "side4", (-2.6, -1.0), (2.2, -1.0), "copperd", "brass")
    pipe(m, "pB", "mid", "side2", (-1.2, -1.2), (-1.2, 1.2), "copperd", "brass")
    m.prism("stack", radius=0.7, height=2.6, at=S("top", "top", (-3.2, 1.4), sink=0.3), role="copperd", sides=6, taper=0.85, solo=True)
    m.prism("stackc", radius=0.95, height=0.4, at=S("top", "top", (-3.2, 1.4), sink=-2.0), role="brass", sides=6, solo=True)
    rivets(m, "rv1", "mid", "side1", [(-2.8, 1.1), (-1.4, 1.1), (0, 1.1), (1.4, 1.1), (2.8, 1.1)], "brass")
    rivets(m, "rv3", "mid", "side3", [(-2.8, 1.1), (-0.9, 1.1), (0.9, 1.1), (2.8, 1.1)], "brass")
    rivets(m, "rv5", "mid", "side5", [(-3.0, 1.2), (3.0, 1.2), (-3.0, -1.2), (3.0, -1.2)], "brass")
    for i, (host, face, uv) in enumerate([("mid", "side3", (0, -0.4)), ("lobeM", "side4", (0, 0)), ("top", "side1", (0.2, 0))]):
        m.prism(f"ring{i}", radius=0.85, height=0.25, at=S(host, face, uv, sink=0.05), role="brass", sides=8, solo=True)
        m.prism(f"lamp{i}", radius=0.6, height=0.4, at=S(host, face, uv, sink=0.05), role="glow", sides=8, solo=True)
    m.build()
    m.blob("mid", "side1", (1.5, -0.6), 1.0, "copperd", seed=2)
    m.blob("mid", "side3", (-2.2, 0.6), 0.8, "copperd", seed=3)
    m.blob("lobeM", "side2", (0.6, -0.4), 0.9, "copperd", seed=4)
    for face in ("side0", "side2", "side4"):
        m.line("top", face, [(-2.5, 0.2), (2.5, 0.2)], "seam", width=1)
    m.line("top", "top", [(-4, 3.5), (0, 0.2), (4, -3.2)], "seam", width=1)
    m.line("bot", "side3", [(-2, 0.4), (2, 0.4)], "seam", width=1)
    m.line("lobeT", "top", [(-2, -1.5), (1.5, 2)], "seam", width=1)
    return m


def rock_v2():
    m = ropilot.model("Rock_R10_V2", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#3C4C5E", noise=0.03, mottle=("#324050", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#2A3644", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#4C5E72", noise=0.025, shade=0.12, top=0.12),
        copperd=dict(color="#7A3A20", noise=0.03, shade=0.12),
        brass=dict(color="#8E6824", noise=0.025, shade=0.12, top=0.18),
        vein="#E4ECF6", seam="#1E2834",
        silver=dict(color="#E6EEF8", noise=0.02, shade=0.1, top=0.2),
        silverd=dict(color="#A8B8D0", noise=0.02, shade=0.1, top=0.15))
    S = m.surface
    m.prism("bot", radius=5.8, height=3.2, at=(0, 0, 1.6), role="rockd", sides=6, taper=1.42, turn=15)
    m.prism("mid", radius=8.4, height=3.8, at=(0, 0, 5.1), role="rock", sides=6, taper=1.0, turn=15)
    m.prism("top", radius=8.4, height=3.0, at=(0, 0, 8.5), role="rockl", sides=6, taper=0.62, turn=15, shear=(-0.7, 0.5))
    m.box("bumpA", size=(5.6, 4.4, 3.0), at=S("mid", "side2", (0, 0.2), sink=1.4), role="rock", chamfer=0.9, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(5.0, 4.0, 2.4), at=S("top", "side4", (0.3, -0.2), sink=1.1), role="rockl", chamfer=0.8, taper=0.65)
    m.box("bumpC", size=(4.4, 3.4, 2.4), at=S("bot", "side5", (0, 0.3), sink=1.0), role="rockd", chamfer=0.7, taper=0.65)
    m.box("bumpD", size=(4.6, 3.6, 2.2), at=S("mid", "side5", (-0.6, -0.2), sink=1.1), role="rockd", chamfer=0.7, taper=0.65, rot=(0, 0, -20))
    cluster(m, "sA", "top", "top", (1.2, -0.6), 2.2, "silver", "silverd", 5, 1)
    cluster(m, "sB", "mid", "side0", (0.6, 0.0), 1.6, "silver", "silverd", 4, 2)
    cluster(m, "sC", "mid", "side3", (-0.4, 0.3), 1.5, "silverd", "silver", 4, 3)
    cluster(m, "sD", "bumpA", "top", (0, 0), 1.1, "silver", "silverd", 3, 4)
    cluster(m, "sE", "top", "side1", (0, 0), 1.2, "silver", "silverd", 3, 5)
    cluster(m, "sG", "bumpD", "top", (0, 0), 1.0, "silverd", "silver", 3, 11)
    gear(m, "gA", "mid", "side1", (0.3, -0.1), 1.6, 0.5, "brass", "copperd", 8, 0.1, 0)
    gear(m, "gB", "top", "top", (-3.4, 2.0), 1.2, 0.45, "brass", "copperd", 6, 0.1, 10)
    pipe(m, "pA", "mid", "side4", (-2.8, -1.1), (2.4, -1.1), "copperd", "brass", w=0.7)
    rivets(m, "rv0", "mid", "side0", [(-3.4, 1.4), (3.4, 1.4), (-3.4, -1.4), (3.4, -1.4)], "brass")
    rivets(m, "rv3", "mid", "side3", [(-3.4, 1.4), (3.4, 1.4), (3.4, -1.4)], "brass")
    m.build()
    m.line("mid", "side1", [(-3.2, -1.5), (-2.4, -0.4), (-2.0, 1.2)], "vein", width=3)
    m.line("mid", "side2", [(-2.2, 1.4), (-0.6, 0.2), (1.8, -0.8)], "vein", width=3)
    m.line("mid", "side4", [(-1.6, 1.4), (0, 0.4), (1.8, 1.2)], "vein", width=2)
    m.line("mid", "side5", [(-3.4, 1.2), (-2.6, -0.4)], "vein", width=2)
    m.line("top", "side2", [(-1.4, -0.8), (0.2, 0.2), (1.4, 0.5)], "vein", width=2)
    m.line("top", "side5", [(-1.6, 0.6), (0.2, -0.2), (1.6, 0.4)], "vein", width=3)
    m.line("top", "top", [(-5, -0.5), (-1.5, -3.5)], "seam", width=1)
    return m


def rock_v3():
    m = ropilot.model("Rock_R10_V3", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#4A3A30", noise=0.03, mottle=("#3C2E26", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#32261F", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#5C4A3C", noise=0.025, shade=0.12, top=0.12),
        steelb=dict(color="#34424F", noise=0.03, mottle=("#2C3844", 0.2, 4), shade=0.2, top=0.15),
        copperd=dict(color="#6E321C", noise=0.03, shade=0.12),
        gold=dict(color="#FFC83A", noise=0.025, shade=0.12, top=0.25),
        goldd=dict(color="#E09A1E", noise=0.025, shade=0.12, top=0.2),
        glow=dict(color="#F0A020", glow=True))
    S = m.surface
    m.prism("bot", radius=6.4, height=3.6, at=(0, 0, 1.8), role="rockd", sides=7, taper=1.4, turn=5)
    m.prism("mid", radius=9.0, height=4.4, at=(0, 0, 5.8), role="steelb", sides=7, taper=1.0, turn=5)
    m.prism("top", radius=9.0, height=3.4, at=(0, 0, 9.7), role="rockl", sides=7, taper=0.6, turn=5, shear=(0.6, 0.8))
    m.box("bumpA", size=(6, 4.8, 3.2), at=S("mid", "side3", (0, 0.2), sink=1.5), role="rock", chamfer=1.0, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(5.2, 4.2, 2.6), at=S("top", "side6", (0.3, -0.2), sink=1.2), role="rockl", chamfer=0.9, taper=0.65)
    m.box("bumpC", size=(4.6, 3.6, 2.6), at=S("bot", "side5", (0, 0.3), sink=1.1), role="rockd", chamfer=0.8, taper=0.65)
    rivets(m, "rvm4", "mid", "side4", [(-3.0, 1.6), (-1.8, 1.6), (1.8, 1.6), (3.0, 1.6), (-3.0, -1.6), (3.0, -1.6)], "goldd")
    rivets(m, "rvm1", "mid", "side1", [(-3.0, 1.6), (-1.5, 1.6), (0, 1.6), (1.5, 1.6), (3.0, 1.6)], "goldd")
    rivets(m, "rvm6", "mid", "side6", [(-3.0, 1.6), (-1.5, 1.6), (1.5, 1.6), (3.0, 1.6)], "goldd")
    gear(m, "gA", "mid", "side4", (0.6, -0.2), 1.5, 0.5, "goldd", "copperd", 8, 0.1, 5)
    cluster(m, "gcA", "top", "top", (-0.8, 0.6), 1.9, "gold", "goldd", 5, 7)
    cluster(m, "gcB", "mid", "side0", (0.4, 0.1), 1.4, "gold", "goldd", 4, 8)
    cluster(m, "gcC", "mid", "side5", (-0.3, 0.2), 1.3, "goldd", "gold", 4, 9)
    cluster(m, "gcD", "bumpA", "top", (0, 0), 1.1, "gold", "goldd", 3, 10)
    cluster(m, "gcE", "top", "side2", (0, 0), 1.0, "gold", "goldd", 3, 12)
    cluster(m, "gcF", "mid", "side1", (0.6, -0.3), 1.2, "gold", "goldd", 4, 13)
    cluster(m, "gcG", "top", "side5", (0, 0), 1.0, "goldd", "gold", 3, 14)
    nuggets(m, [("n1", "top", "top", (2.8, -1.8), 1.5, 20), ("n2", "mid", "side2", (-0.6, -0.4), 1.3, -10),
                ("n3", "mid", "side6", (0.5, 0.6), 1.2, 35), ("n4", "bumpC", "top", (0, 0), 1.0, 10),
                ("n5", "top", "side4", (0, 0), 1.2, -25), ("n6", "bot", "side1", (0, 0.2), 1.0, 5),
                ("n7", "top", "top", (-3.4, -2.4), 1.2, 40), ("n8", "top", "side3", (0.3, 0), 1.1, 0)])
    cracks(m, [("mid", "side1", (-2.6, -1.6), (-0.6, -1.0)), ("mid", "side3", (-1.4, 1.2), (1.4, -1.2)),
               ("mid", "side6", (-1.8, -1.0), (0.4, -1.4)), ("mid", "side2", (0.6, 1.4), (2.2, 0.2)),
               ("top", "side0", (-1.2, -0.4), (1.2, 0.3))])
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
    for c in ("Rock_R10_V1", "Rock_R10_V2", "Rock_R10_V3"):
        join_rock(c)
