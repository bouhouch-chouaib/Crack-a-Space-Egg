# Astéroïdes de l'anneau 11 « Candy Comet » (25 nov.), au kit low-poly de Ropilot (ropilot.model, px = 8,
# sans picots : ils sont posés dans Studio sur la roche seulement). Même méthode que asteroids_r1.py.
# Silhouette propre à l'anneau : gâteau rond à 9-11 pans, glaçage sur le dessus qui coule sur la ceinture.
#   V1 Soft Rock   : base chocolat, ceinture de biscuit aux pépites de chocolat, dessus en glaçage rose qui
#                    coule (peint), second lobe au glaçage menthe, vermicelles, sucette, sucre d'orge, guimauves
#   V2 Silver Rock : chocolat noir et dessus chocolat au lait, flaque et coulures de glaçage rose, grosses grappes
#                    de cristaux d'argent, filons d'argent peints, sucre d'orge, guimauve, vermicelles
#   V3 Gold Rock   : chocolat très noir, grappes de cristaux d'or, pépites, fentes de caramel lumineuses (néon),
#                    coulures de glaçage rose, vermicelles, sucre d'orge
# Attention au kit : la peinture est appliquée au build() suivant et s'accumule ; peindre puis construire.
# À lancer avec ropilot_blender_run_python, puis join_rock() par collection (_Asteroid, _Ore, _Glow),
# ropilot_blender_import et réglage dans Studio (voir asteroids_r1.py). Couleurs plus foncées que voulu.
import math
import random

BODY = ("bot", "mid", "top", "lobe", "bump")
SPR = ["spry", "sprb", "sprg", "sprp", "sprw"]
CANDY_PAL = dict(spry="#E0B020", sprb="#2E7CD8", sprg="#48B048", sprp="#8A48C8", sprw="#ECE4E0")


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


def sprinkles(m, pre, host, face, center, rad, n, seed):
    """Vermicelles : petits bâtonnets de couleur posés au hasard dans un disque."""
    rnd = random.Random(seed)
    for i in range(n):
        a = rnd.uniform(0, 2 * math.pi)
        d = rad * math.sqrt(rnd.random())
        m.box(f"{pre}{i}", size=(0.6, 0.2, 0.18), at=m.surface(host, face, (center[0] + math.cos(a) * d, center[1] + math.sin(a) * d), sink=0.04),
              role=SPR[i % len(SPR)], rot=(0, 0, rnd.uniform(0, 180)), solo=True)


def paint_drips(m, host, faces, vtop, role, seed, width=8, fw=4.0):
    """Glaçage qui coule (peint) : bande en haut de chaque face, coulures arrondies vers le bas."""
    rnd = random.Random(seed)
    for face, us in faces:
        m.rect(host, face, (0, vtop - 0.25), (fw, 0.6), role)
        for u in us:
            L = rnd.uniform(0.9, 2.0)
            m.line(host, face, [(u, vtop), (u, vtop - L)], role, width=width)
            m.circle(host, face, (u, vtop - L), width / 16 + 0.1, role)


def lollipop(m, pre, host, face, uv, stick, r, role, yaw=0):
    S = m.surface
    m.prism(pre + "s", radius=0.16, height=stick + 0.3, at=S(host, face, uv, sink=0.3), role="sprw", sides=6, solo=True)
    m.prism(pre + "d", radius=r, height=0.45, at=S(host, face, uv, sink=-(stick + r - 0.25)), role=role, sides=12, rot=(90, 0, yaw), solo=True)


def cane(m, pre, host, face, uv, n, seg, r):
    """Sucre d'orge : tronçons rouges et blancs empilés."""
    for i in range(n):
        m.prism(f"{pre}{i}", radius=r, height=seg + 0.02, at=m.surface(host, face, uv, sink=0.3 - i * seg),
                role="cred" if i % 2 == 0 else "sprw", sides=8, solo=True)


def rock_v1():
    m = ropilot.model("Rock_R11_V1", px=8, reset=True, symmetric=False)
    m.palette(
        choc=dict(color="#4A2818", noise=0.03, mottle=("#3C2012", 0.2, 4), shade=0.2, top=0.12),
        chocd=dict(color="#341A10", noise=0.03, shade=0.18, top=0.1),
        cookie=dict(color="#A0683A", noise=0.035, mottle=("#8C582E", 0.25, 3), shade=0.18, top=0.12),
        icing=dict(color="#D24C88", noise=0.02, shade=0.12, top=0.15),
        mint=dict(color="#3FAE96", noise=0.02, shade=0.12, top=0.15),
        mallow=dict(color="#E8A8C4", noise=0.02, shade=0.12, top=0.15),
        mallowm=dict(color="#B4E0D0", noise=0.02, shade=0.12, top=0.15),
        chip="#2A140C", cred=dict(color="#C8283A", noise=0.02), **CANDY_PAL)
    S = m.surface
    m.prism("bot", radius=5.2, height=3.0, at=(0, 0, 1.5), role="chocd", sides=10, taper=1.45)
    m.prism("mid", radius=7.4, height=3.4, at=(0, 0, 4.7), role="cookie", sides=10, taper=1.0)
    m.prism("top", radius=7.4, height=2.8, at=(0, 0, 7.8), role="icing", sides=10, taper=0.64, shear=(0.5, -0.4))
    m.prism("lobeB", radius=3.6, height=2.0, at=(5.0, 4.0, 1.8), role="chocd", sides=9, taper=1.4, turn=10)
    m.prism("lobeM", radius=4.8, height=2.4, at=(5.0, 4.0, 4.0), role="cookie", sides=9, taper=1.0, turn=10)
    m.prism("lobeT", radius=4.8, height=2.2, at=(5.0, 4.0, 6.3), role="mint", sides=9, taper=0.6, turn=10, shear=(0.4, 0.4))
    m.box("bumpA", size=(5.0, 4.0, 2.6), at=S("mid", "side7", (0, 0.2), sink=1.3), role="cookie", chamfer=0.9, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.4, 3.6, 2.2), at=S("bot", "side3", (0, 0.3), sink=1.0), role="chocd", chamfer=0.7, taper=0.65)
    m.box("bumpC", size=(4.4, 3.6, 1.8), at=S("top", "top", (-1.8, 1.8), sink=0.9), role="icing", chamfer=0.8, taper=0.6, rot=(0, 0, 25))
    m.box("bumpD", size=(4.0, 3.2, 2.0), at=S("bot", "side8", (0.4, 0.2), sink=1.0), role="choc", chamfer=0.7, taper=0.65)
    sprinkles(m, "sp", "top", "top", (0.6, -0.6), 3.2, 22, 5)
    sprinkles(m, "sq", "lobeT", "top", (0, 0), 2.0, 9, 6)
    lollipop(m, "lp", "top", "top", (1.8, 1.4), 1.8, 1.4, "cred", yaw=-30)
    cane(m, "cn", "lobeT", "top", (0.8, -0.6), 5, 0.55, 0.32)
    m.box("ml1", size=(1.8, 1.8, 1.6), at=S("top", "top", (-3.0, -1.4), sink=0.2), role="mallow", chamfer=0.35, rot=(0, 0, 20), solo=True)
    m.box("ml2", size=(1.5, 1.5, 1.3), at=S("mid", "side3", (0.6, -0.2), sink=0.3), role="mallowm", chamfer=0.3, rot=(0, 0, 10), solo=True)
    m.box("ml3", size=(1.4, 1.4, 1.2), at=S("lobeT", "top", (-1.4, 0.8), sink=0.2), role="mallow", chamfer=0.3, rot=(0, 0, -15), solo=True)
    rnd = random.Random(7)
    for i in range(10):
        for _ in range(3):
            m.circle("mid", f"side{i}", (rnd.uniform(-1.7, 1.7), rnd.uniform(-1.5, -0.3)), 0.4, "chip")
    for i in range(0, 9):
        m.circle("lobeM", f"side{i}", (rnd.uniform(-1.2, 1.2), rnd.uniform(-1.0, -0.3)), 0.36, "chip")
    paint_drips(m, "mid", [("side%d" % i, us) for i, us in [(0, (-1.4, 0.9)), (1, (0.2,)), (2, (-0.8, 1.2)), (3, (-1.2, 0.6)), (4, (0.3,)),
                                                          (5, (-1.0, 0.8)), (6, (0.0,)), (7, (-1.3, 1.1)), (8, (-0.6, 1.0)), (9, (0.4,))]],
                1.7, "icing", 3, fw=4.8)
    paint_drips(m, "lobeM", [("side%d" % i, (0.0,) if i % 2 else (-0.6, 0.7)) for i in range(9)], 1.2, "mint", 4, width=7, fw=3.4)
    for r_, c in [(1.4, "cred"), (1.05, "sprw"), (0.7, "cred"), (0.35, "sprw")]:
        m.circle("lpd", "top", (0, 0), r_, c)
    m.build()
    return m


def rock_v2():
    m = ropilot.model("Rock_R11_V2", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#4A2A1C", noise=0.03, mottle=("#3C2216", 0.2, 4), shade=0.2, top=0.12),
        rockd=dict(color="#341C12", noise=0.03, shade=0.18, top=0.1),
        rockl=dict(color="#6A3E26", noise=0.03, mottle=("#5A3420", 0.2, 4), shade=0.12, top=0.12),
        icing=dict(color="#C84A84", noise=0.02, shade=0.12, top=0.15),
        mallow=dict(color="#E8A8C4", noise=0.02, shade=0.12, top=0.15),
        cred=dict(color="#C8283A", noise=0.02), vein="#E4ECF6", chip="#24120A",
        silver=dict(color="#E6EEF8", noise=0.02, shade=0.1, top=0.2),
        silverd=dict(color="#A8B8D0", noise=0.02, shade=0.1, top=0.15), **CANDY_PAL)
    S = m.surface
    m.prism("bot", radius=5.8, height=3.2, at=(0, 0, 1.6), role="rockd", sides=9, taper=1.42, turn=8)
    m.prism("mid", radius=8.2, height=3.8, at=(0, 0, 5.1), role="rock", sides=9, taper=1.0, turn=8)
    m.prism("top", radius=8.2, height=3.0, at=(0, 0, 8.5), role="rockl", sides=9, taper=0.6, turn=8, shear=(-0.8, 0.6))
    m.box("bumpA", size=(5.4, 4.4, 3.0), at=S("mid", "side2", (0, 0.2), sink=1.4), role="rock", chamfer=0.9, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.8, 4, 2.4), at=S("top", "side6", (0.3, -0.2), sink=1.1), role="rockl", chamfer=0.8, taper=0.65)
    m.box("bumpC", size=(4.2, 3.4, 2.4), at=S("bot", "side5", (0, 0.3), sink=1.0), role="rockd", chamfer=0.7, taper=0.65)
    cluster(m, "sA", "top", "top", (1.0, -0.5), 2.1, "silver", "silverd", 5, 1)
    cluster(m, "sB", "mid", "side0", (0.5, -0.3), 1.5, "silver", "silverd", 4, 2)
    cluster(m, "sC", "mid", "side4", (-0.4, -0.2), 1.4, "silverd", "silver", 4, 3)
    cluster(m, "sD", "bumpA", "top", (0, 0), 1.1, "silver", "silverd", 3, 4)
    cluster(m, "sE", "top", "side7", (0, 0), 1.1, "silver", "silverd", 3, 5)
    cluster(m, "sG", "mid", "side2", (0.6, -0.4), 1.0, "silverd", "silver", 3, 11)
    cluster(m, "sH", "top", "side3", (0, 0), 1.2, "silver", "silverd", 3, 13)
    cluster(m, "sI", "mid", "side6", (0.6, -0.2), 1.1, "silverd", "silver", 3, 14)
    sprinkles(m, "sp", "top", "top", (-1.6, 1.2), 2.4, 12, 8)
    cane(m, "cn", "top", "top", (-3.0, -1.8), 5, 0.55, 0.32)
    m.box("ml1", size=(1.6, 1.6, 1.4), at=S("top", "top", (-2.4, 2.6), sink=0.2), role="mallow", chamfer=0.3, rot=(0, 0, 20), solo=True)
    m.blob("top", "top", (-1.8, 1.4), 2.6, "icing", rough=0.3, seed=3)
    m.blob("top", "top", (2.2, -1.6), 1.2, "icing", rough=0.3, seed=4)
    paint_drips(m, "mid", [("side%d" % i, (-0.9, 0.9) if i % 2 else (0.2,)) for i in range(9)], 1.9, "icing", 9, fw=5.4)
    rnd = random.Random(12)
    for i in range(9):
        m.circle("mid", f"side{i}", (rnd.uniform(-1.8, 1.8), rnd.uniform(-1.6, -0.6)), 0.36, "chip")
    m.line("mid", "side1", [(-2, -1.5), (-0.6, -0.4), (0.4, -0.1), (1.8, 0.6)], "vein", width=3)
    m.line("mid", "side3", [(-1.8, 0.4), (-0.4, -0.4), (1.6, -1.2)], "vein", width=3)
    m.line("mid", "side6", [(-1.6, -1.4), (0, -0.4), (0.8, 0.6)], "vein", width=2)
    m.line("mid", "side7", [(-1.6, 0.4), (0, -0.4), (1.6, -1.2)], "vein", width=2)
    m.line("mid", "side8", [(-1.8, -1.2), (0.2, -0.6), (1.4, 0.4)], "vein", width=3)
    m.line("bot", "side2", [(-1.2, 0.6), (0.4, -0.2), (1.4, 0.2)], "vein", width=2)
    for f in ("side1", "side4", "side8"):
        m.line("top", f, [(-1.4, -0.6), (0.2, 0.2), (1.4, 0.0)], "vein", width=2)
    m.build()
    return m


def rock_v3():
    m = ropilot.model("Rock_R11_V3", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#3E2216", noise=0.03, mottle=("#321A10", 0.2, 4), shade=0.2, top=0.12),
        rockd=dict(color="#2A160E", noise=0.03, shade=0.18, top=0.1),
        rockl=dict(color="#56301E", noise=0.025, shade=0.12, top=0.12),
        icing=dict(color="#C84A84", noise=0.02, shade=0.12, top=0.15),
        chip="#1C0C06", cred=dict(color="#C8283A", noise=0.02),
        gold=dict(color="#FFC83A", noise=0.025, shade=0.12, top=0.25),
        goldd=dict(color="#E09A1E", noise=0.025, shade=0.12, top=0.2),
        glow=dict(color="#F08C20", glow=True), **CANDY_PAL)
    S = m.surface
    m.prism("bot", radius=6.4, height=3.6, at=(0, 0, 1.8), role="rockd", sides=11, taper=1.4, turn=5)
    m.prism("mid", radius=9.0, height=4.4, at=(0, 0, 5.8), role="rock", sides=11, taper=1.0, turn=5)
    m.prism("top", radius=9.0, height=3.4, at=(0, 0, 9.7), role="rockl", sides=11, taper=0.58, turn=5, shear=(0.6, 0.8))
    m.box("bumpA", size=(6, 4.8, 3.2), at=S("mid", "side3", (0, 0.2), sink=1.5), role="rock", chamfer=1.0, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(5.2, 4.2, 2.6), at=S("top", "side8", (0.3, -0.2), sink=1.2), role="rockl", chamfer=0.9, taper=0.65)
    m.box("bumpC", size=(4.6, 3.6, 2.6), at=S("bot", "side6", (0, 0.3), sink=1.1), role="rockd", chamfer=0.8, taper=0.65)
    cluster(m, "gcA", "top", "top", (-0.8, 0.6), 1.9, "gold", "goldd", 5, 7)
    cluster(m, "gcB", "mid", "side0", (0.4, 0.1), 1.4, "gold", "goldd", 4, 8)
    cluster(m, "gcC", "mid", "side6", (-0.3, 0.2), 1.3, "goldd", "gold", 4, 9)
    cluster(m, "gcD", "bumpA", "top", (0, 0), 1.1, "gold", "goldd", 3, 10)
    cluster(m, "gcE", "top", "side2", (0, 0), 1.0, "gold", "goldd", 3, 12)
    cluster(m, "gcF", "mid", "side9", (0.3, -0.2), 1.2, "gold", "goldd", 4, 13)
    nuggets(m, [("n1", "top", "top", (2.8, -1.8), 1.5, 20), ("n2", "mid", "side2", (-0.4, -0.4), 1.3, -10),
                ("n3", "mid", "side7", (0.4, 0.6), 1.2, 35), ("n4", "bumpC", "top", (0, 0), 1.0, 10),
                ("n5", "top", "side4", (0, 0), 1.2, -25), ("n6", "bot", "side1", (0, 0.2), 1.0, 5),
                ("n7", "top", "top", (-3.4, -2.4), 1.2, 40), ("n8", "top", "side10", (0.3, 0), 1.1, 0)])
    cracks(m, [("mid", "side1", (-1.4, -1.2), (1.2, 1.0)), ("mid", "side4", (-1.3, 1.0), (1.3, -0.9)),
               ("mid", "side8", (-1.2, -0.8), (1.2, 0.9)), ("mid", "side10", (-1.0, 1.0), (1.2, -1.0)),
               ("top", "side6", (-1.0, -0.3), (1.0, 0.3))])
    sprinkles(m, "sp", "top", "top", (2.6, 1.8), 1.6, 8, 15)
    cane(m, "cn", "top", "top", (-3.6, 2.4), 4, 0.55, 0.3)
    paint_drips(m, "mid", [("side%d" % i, (0.0,) if i % 2 else (-0.8, 0.8)) for i in range(11)], 2.2, "icing", 21, fw=5.2)
    rnd = random.Random(22)
    for i in range(11):
        m.circle("mid", f"side{i}", (rnd.uniform(-1.8, 1.8), rnd.uniform(-1.9, -1.0)), 0.36, "chip")
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
    for c in ("Rock_R11_V1", "Rock_R11_V2", "Rock_R11_V3"):
        join_rock(c)
