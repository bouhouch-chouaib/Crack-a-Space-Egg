# Astéroïdes de l'anneau 1 « Dust Belt » (25 nov.), au kit low-poly de Ropilot (ropilot.model, px = 8, sans
# picots : ils sont posés dans Studio sur la roche seulement, comme tools/apply-studs.lua).
# Trois types, qu'on reconnaît de loin sans rien lire (Config.RockTypes) :
#   V1 Soft Rock   : roche de sable à deux lobes, cratères peints, petits cristaux roses de poussière d'étoiles
#   V2 Silver Rock : roche brune plus sombre, filons d'argent peints, grosses grappes de cristaux d'argent
#   V3 Gold Rock   : roche brun foncé, grappes de cristaux d'or, pépites, fentes lumineuses orange (néon)
# Corps = 3 prismes empilés (bas évasé, ceinture, haut qui se referme) + bosses enfoncées.
# À lancer avec ropilot_blender_run_python. Ensuite, chaque collection est fusionnée en « _Asteroid »
# (la roche), « _Ore » (cristaux et pépites) et « _Glow » (néon), importée dans Studio (ropilot_blender_import)
# puis réglée : Asteroid = PrimaryPart (visée, collision précise, picots), Ore et Glow hors des rayons
# (CanQuery = false), Glow en Neon, pivot au centre, attribut Painted (RockLook ne le repeint pas).
# Les couleurs sont plus foncées que voulu : l'import les éclaircit.
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


def rock_v1():
    m = ropilot.model("Rock_R1_V1", px=8, reset=True, symmetric=False)
    m.palette(
        sand=dict(color="#C99E6C", noise=0.03, mottle=("#B38658", 0.2, 4), shade=0.2, top=0.15),
        sandd=dict(color="#9A7049", noise=0.03, shade=0.18, top=0.12),
        sandl=dict(color="#DDBD8C", noise=0.025, shade=0.12, top=0.12),
        crater=dict(color="#8E6646", noise=0.03), craterd="#5E3F2A",
        dust=dict(color="#F48CC0", noise=0.02))
    S = m.surface
    m.prism("bot", radius=5.2, height=3.0, at=(0, 0, 1.5), role="sandd", sides=8, taper=1.45)
    m.prism("mid", radius=7.5, height=3.4, at=(0, 0, 4.7), role="sand", sides=8, taper=1.0)
    m.prism("top", radius=7.5, height=3.0, at=(0, 0, 7.9), role="sandl", sides=8, taper=0.62, shear=(0.9, -0.5))
    m.prism("lobeB", radius=3.6, height=2.2, at=(5.2, 3.4, 1.9), role="sandd", sides=7, taper=1.4, turn=10)
    m.prism("lobeM", radius=5.0, height=2.4, at=(5.2, 3.4, 4.2), role="sand", sides=7, taper=1.0, turn=10)
    m.prism("lobeT", radius=5.0, height=2.2, at=(5.2, 3.4, 6.5), role="sandl", sides=7, taper=0.6, turn=10, shear=(0.5, 0.4))
    m.box("bumpA", size=(5.4, 4.4, 3.0), at=S("mid", "side1", (0, 0.3), sink=1.4), role="sand", chamfer=0.9, taper=0.65, rot=(0, 0, 20))
    m.box("bumpB", size=(4.6, 3.8, 2.6), at=S("mid", "side4", (0.5, -0.6), sink=1.2), role="sandd", chamfer=0.8, taper=0.65, rot=(0, 0, -15))
    m.box("bumpC", size=(5.0, 3.6, 2.4), at=S("top", "side6", (0, -0.2), sink=1.1), role="sandl", chamfer=0.8, taper=0.65)
    m.box("bumpD", size=(4.0, 3.2, 2.2), at=S("bot", "side3", (0, 0.3), sink=1.0), role="sandd", chamfer=0.7, taper=0.65)
    m.box("bumpE", size=(4.4, 3.8, 2.0), at=S("top", "top", (1.6, -1.2), sink=1.0), role="sandl", chamfer=0.8, taper=0.6, rot=(0, 0, 30))
    dust = [("top", "top", (-2.2, -1.6), 0.4, 1.4), ("top", "top", (-1.6, -2.3), 0.3, 1.0), ("top", "top", (-2.6, -0.9), 0.25, 0.8),
            ("mid", "side0", (1.4, 0.5), 0.32, 1.1), ("bumpA", "top", (0.6, 0.2), 0.32, 1.1), ("mid", "side5", (-1, 0.6), 0.3, 1.0),
            ("lobeT", "top", (0.3, 0.2), 0.4, 1.5), ("lobeT", "top", (-0.5, 0.6), 0.3, 1.0), ("lobeT", "top", (0.6, -0.5), 0.26, 0.8)]
    for i, (host, face, uv, r, h) in enumerate(dust):
        m.crystal(f"dust{i}", radius=r, height=h, at=S(host, face, uv), role="dust", sides=5, tip=0.35, solo=True)
    m.build()

    def crater(part, face, at, r):
        m.circle(part, face, at, r, "crater")
        m.circle(part, face, (at[0] + r * 0.08, at[1] - r * 0.1), r * 0.72, "craterd")
        m.circle(part, face, (at[0] - r * 0.25, at[1] + r * 0.3), r * 0.22, "sandl")
    crater("top", "top", (-1.0, 1.6), 1.5)
    crater("top", "top", (1.4, 1.8), 0.8)
    crater("mid", "side6", (0.6, 0.2), 1.2)
    crater("mid", "side3", (-0.6, 0.3), 0.9)
    crater("mid", "side2", (0.3, -0.4), 1.1)
    crater("bumpB", "top", (0, 0), 0.7)
    crater("lobeM", "side3", (0, 0.2), 0.9)
    return m


def rock_v2():
    m = ropilot.model("Rock_R1_V2", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#7F6450", noise=0.03, mottle=("#6A513F", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#5C4535", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#977A60", noise=0.025, shade=0.12, top=0.12),
        vein="#E4ECF6",
        silver=dict(color="#E6EEF8", noise=0.02, shade=0.1, top=0.2),
        silverd=dict(color="#A8B8D0", noise=0.02, shade=0.1, top=0.15))
    S = m.surface
    m.prism("bot", radius=5.6, height=3.2, at=(0, 0, 1.6), role="rockd", sides=9, taper=1.42, turn=8)
    m.prism("mid", radius=8.0, height=3.8, at=(0, 0, 5.1), role="rock", sides=9, taper=1.0, turn=8)
    m.prism("top", radius=8.0, height=3.2, at=(0, 0, 8.6), role="rockl", sides=9, taper=0.6, turn=8, shear=(-0.8, 0.6))
    m.box("bumpA", size=(5.4, 4.4, 3.0), at=S("mid", "side2", (0, 0.2), sink=1.4), role="rock", chamfer=0.9, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.8, 4, 2.4), at=S("top", "side6", (0.3, -0.2), sink=1.1), role="rockl", chamfer=0.8, taper=0.65)
    m.box("bumpC", size=(4.2, 3.4, 2.4), at=S("bot", "side5", (0, 0.3), sink=1.0), role="rockd", chamfer=0.7, taper=0.65)
    cluster(m, "sA", "top", "top", (1.0, -0.5), 2.1, "silver", "silverd", 5, 1)
    cluster(m, "sB", "mid", "side0", (0.5, 0.0), 1.5, "silver", "silverd", 4, 2)
    cluster(m, "sC", "mid", "side4", (-0.4, 0.3), 1.4, "silverd", "silver", 4, 3)
    cluster(m, "sD", "bumpA", "top", (0, 0), 1.1, "silver", "silverd", 3, 4)
    cluster(m, "sE", "top", "side7", (0, 0), 1.1, "silver", "silverd", 3, 5)
    cluster(m, "sG", "mid", "side2", (0.6, -0.2), 1.0, "silverd", "silver", 3, 11)
    m.build()
    m.line("mid", "side1", [(-2, -1.5), (-0.6, -0.2), (0.4, 0.1), (1.8, 1.4)], "vein", width=3)
    m.line("mid", "side3", [(-1.8, 1.2), (-0.4, 0.2), (1.6, -0.8)], "vein", width=3)
    m.line("mid", "side6", [(-1.6, -1.2), (0, 0), (0.8, 1.4)], "vein", width=2)
    m.line("top", "side2", [(-1.2, -0.8), (0.2, 0.2), (1.2, 0.5)], "vein", width=2)
    m.line("mid", "side7", [(-1.6, 0.8), (0, 0.2), (1.6, -1)], "vein", width=2)
    return m


def rock_v3():
    import math
    m = ropilot.model("Rock_R1_V3", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#5E4434", noise=0.03, mottle=("#4C3628", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#432F24", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#765741", noise=0.025, shade=0.12, top=0.12),
        gold=dict(color="#FFC83A", noise=0.025, shade=0.12, top=0.25),
        goldd=dict(color="#E09A1E", noise=0.025, shade=0.12, top=0.2),
        glow=dict(color="#F0A020", glow=True))
    S = m.surface
    m.prism("bot", radius=6.4, height=3.6, at=(0, 0, 1.8), role="rockd", sides=10, taper=1.4, turn=5)
    m.prism("mid", radius=9.0, height=4.4, at=(0, 0, 5.8), role="rock", sides=10, taper=1.0, turn=5)
    m.prism("top", radius=9.0, height=3.6, at=(0, 0, 9.8), role="rockl", sides=10, taper=0.58, turn=5, shear=(0.6, 0.8))
    m.box("bumpA", size=(6, 4.8, 3.2), at=S("mid", "side3", (0, 0.2), sink=1.5), role="rock", chamfer=1.0, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(5.2, 4.2, 2.6), at=S("top", "side8", (0.3, -0.2), sink=1.2), role="rockl", chamfer=0.9, taper=0.65)
    m.box("bumpC", size=(4.6, 3.6, 2.6), at=S("bot", "side6", (0, 0.3), sink=1.1), role="rockd", chamfer=0.8, taper=0.65)
    cluster(m, "gA", "top", "top", (-0.8, 0.6), 1.8, "gold", "goldd", 5, 7)
    cluster(m, "gB", "mid", "side0", (0.4, 0.1), 1.4, "gold", "goldd", 4, 8)
    cluster(m, "gC", "mid", "side5", (-0.3, 0.2), 1.3, "goldd", "gold", 4, 9)
    cluster(m, "gD", "mid", "side8", (0.2, -0.2), 1.1, "gold", "goldd", 3, 10)
    for name, host, face, uv, s, rot in [("n1", "top", "top", (2.6, -1.8), 1.5, 20), ("n2", "mid", "side2", (-0.6, -0.4), 1.3, -10),
                                         ("n3", "mid", "side7", (0.5, 0.6), 1.2, 35), ("n4", "bumpA", "top", (0, 0), 1.1, 10),
                                         ("n5", "top", "side4", (0, 0), 1.2, -25), ("n6", "bot", "side1", (0, 0.2), 1.0, 5)]:
        m.box(name, size=(1.6 * s, 1.4 * s, 1.1 * s), at=S(host, face, uv, sink=0.35 * s), role="gold", chamfer=0.35 * s, taper=0.75, rot=(0, 0, rot), solo=True)
    cracks = [("mid", "side1", (-1.5, -1.2), (1.4, 1.3)), ("mid", "side4", (-1.4, 1.0), (1.5, -0.9)),
              ("mid", "side6", (-1.2, -0.8), (1.3, 0.9)), ("mid", "side9", (-1.0, 1.0), (1.2, -1.0))]
    for i, (host, face, a, b) in enumerate(cracks):
        du, dv = b[0] - a[0], b[1] - a[1]
        m.box(f"crack{i}", size=(math.hypot(du, dv), 0.28, 0.12), at=S(host, face, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), sink=0.06),
              role="glow", rot=(0, 0, math.degrees(math.atan2(dv, du))), solo=True)
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
    for c in ("Rock_R1_V1", "Rock_R1_V2", "Rock_R1_V3"):
        join_rock(c)
