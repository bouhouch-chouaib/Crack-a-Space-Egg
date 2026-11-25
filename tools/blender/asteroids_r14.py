# Astéroïdes de l'anneau 14 « Phantom Mist » (25 nov.), au kit low-poly de Ropilot (ropilot.model, px = 8,
# sans picots : ils sont posés dans Studio sur la roche seulement). Même méthode que asteroids_r1.py.
# Silhouette propre à l'anneau : roche gris-bleu à 7-9 pans entourée d'un col de brume (plaques pâles
# effilées qui sortent de la ceinture), petites citrouilles souriantes posées sur le dessus et sur la brume,
# bougies et lanternes ; mignon, jamais effrayant.
#   V1 Soft Rock   : roche gris-bleu à deux lobes, pic de roche tordu sur le lobe, col de brume, trois
#                    citrouilles souriantes (une grosse au sommet), bougies à flamme turquoise, deux lanternes
#                    à flamme turquoise (néon), volutes de brume peintes
#   V2 Silver Rock : roche gris-bleu sombre, grosses grappes de cristaux d'argent, filons d'argent, col de
#                    brume, une citrouille, bougies et une lanterne turquoise (néon)
#   V3 Gold Rock   : roche gris-bleu très sombre, grappes de cristaux d'or, pépites, fentes lumineuses orange
#                    (néon), bougies à flamme orange, une citrouille, petit pic tordu, col de brume
# Attention au kit : la peinture est appliquée au build() suivant et s'accumule ; peindre puis construire.
# Les plaques de brume sont posées sur des faces de côté : leur face qui regarde vers le haut est « back ».
# À lancer avec ropilot_blender_run_python, puis join_rock() par collection (_Asteroid, _Ore, _Glow),
# ropilot_blender_import et réglage dans Studio (voir asteroids_r1.py). Couleurs plus foncées que voulu.
import math
import random

BODY = ("bot", "mid", "top", "lobe", "bump")

SMILE = [".#...#.",
         "###.###",
         ".......",
         "#.....#",
         ".#####."]


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


def mist(m, specs):
    """Plaques de brume effilées qui sortent d'une face de côté (épaisseur sur v, longueur vers l'extérieur)."""
    for name, host, face, uv, w, out, rot in specs:
        m.box(name, size=(w, 0.45, out), at=m.surface(host, face, uv, sink=out * 0.45), role="mist", chamfer=0.15,
              taper=(0.7, 1.0), rot=(0, 0, rot), solo=True)
        if w >= 4.4:  # seconde nappe, plus petite, posée sur la première
            s = min(w, out) * 0.6
            m.box(name + "u", size=(s, s * 0.8, 0.32), at=m.surface(name, "back", (0, 0), sink=0.04), role="mistl", chamfer=0.1,
                  taper=0.8, solo=True)


def pumpkin(m, pre, host, face, uv, s, turn=0):
    """Citrouille souriante : bande à 6 pans (visage peint sur side0), dôme, tige verte."""
    S = m.surface
    m.prism(pre + "a", radius=0.95 * s, height=0.7 * s, at=S(host, face, uv, sink=0.12 * s), role="pump", sides=6, taper=1.0,
            rot=(0, 0, turn), solo=True)
    m.prism(pre + "b", radius=0.95 * s, height=0.42 * s, at=S(host, face, uv, sink=-0.56 * s), role="pumpl", sides=6, taper=0.55,
            rot=(0, 0, turn), solo=True)
    m.prism(pre + "c", radius=0.13 * s + 0.04, height=0.45 * s, at=S(host, face, uv, sink=-0.9 * s), role="stem", sides=5, taper=0.7,
            rot=(12, 0, turn), solo=True)
    m.stamp(pre + "a", "side0", (0, 0), SMILE, {"#": "face"}, cell=max(0.125, 0.12 * s))
    for i in (1, 2, 4, 5):
        m.line(pre + "a", f"side{i}", [(0, -0.3 * s), (0, 0.3 * s)], "pumpd", width=1)


def candles(m, pre, host, face, uv, hs, flame="glow"):
    S = m.surface
    offs = [(0, 0), (0.5, 0.25), (-0.35, 0.45), (0.2, -0.5)]
    for i, h in enumerate(hs):
        du, dv = offs[i]
        c = f"{pre}{i}"
        m.prism(c, radius=0.22, height=h, at=S(host, face, (uv[0] + du, uv[1] + dv), sink=0.08), role="wax", sides=6, solo=True)
        m.crystal(c + "f", radius=0.14, height=0.42, at=S(c, "top", (0, 0), sink=0.02), role=flame, sides=4, tip=0.5, base_tip=0.3, solo=True)


def lantern(m, pre, host, face, uv, post=1.4):
    """Lanterne sur un petit poteau : socle et chapeau en fer, cœur lumineux turquoise (néon), quatre montants."""
    S = m.surface
    m.prism(pre + "p", radius=0.2, height=post, at=S(host, face, uv, sink=0.1), role="iron", sides=4, solo=True)
    m.box(pre + "b", size=(0.9, 0.9, 0.2), at=S(pre + "p", "top", (0, 0), sink=0.03), role="iron", solo=True)
    m.box(pre + "g", size=(0.62, 0.62, 0.8), at=S(pre + "b", "top", (0, 0), sink=0.02), role="glow", solo=True)
    for i, (du, dv) in enumerate([(0.34, 0.34), (-0.34, 0.34), (0.34, -0.34), (-0.34, -0.34)]):
        m.box(f"{pre}r{i}", size=(0.12, 0.12, 0.84), at=S(pre + "b", "top", (du, dv), sink=0.02), role="iron", solo=True)
    m.prism(pre + "t", radius=0.68, height=0.42, at=S(pre + "g", "top", (0, 0), sink=0.04), role="iron", sides=4, taper=0.25, turn=45, solo=True)


def wisps(m, specs, role="mistp"):
    for i, (host, face, uv, r) in enumerate(specs):
        m.blob(host, face, uv, r, role, rough=0.5, seed=70 + i)
        m.blob(host, face, (uv[0] + r * 0.9, uv[1] + r * 0.25), r * 0.6, role, rough=0.5, seed=90 + i)


def rock_v1():
    m = ropilot.model("Rock_R14_V1", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#5E6A80", noise=0.03, mottle=("#525D72", 0.22, 4), shade=0.2, top=0.15),
        rockd=dict(color="#444E60", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#727E94", noise=0.025, shade=0.12, top=0.12),
        crackd="#343C4C", mistp="#8C98B0",
        mist=dict(color="#94A2C4", noise=0.02, shade=0.08, top=0.18), mistl=dict(color="#A8B4D2", noise=0.02, shade=0.06, top=0.15),
        pump=dict(color="#D86A1C", noise=0.03, shade=0.15, top=0.12), pumpl=dict(color="#E07A24", noise=0.03, shade=0.1, top=0.15),
        pumpd="#A84E16", face="#3A1A0C", stem=dict(color="#4E7A2A", noise=0.03, shade=0.1),
        wax=dict(color="#DCD2BA", noise=0.02, shade=0.12), iron=dict(color="#2E3444", noise=0.03, shade=0.12),
        glow=dict(color="#18C8C0", glow=True))
    S = m.surface
    m.prism("bot", radius=5.2, height=3.0, at=(0, 0, 1.5), role="rockd", sides=7, taper=1.45, turn=5)
    m.prism("mid", radius=7.6, height=3.2, at=(0, 0, 4.6), role="rock", sides=7, turn=5)
    m.prism("top", radius=7.6, height=3.0, at=(0, 0, 7.7), role="rockl", sides=7, taper=0.62, turn=5, shear=(0.6, -0.4))
    m.prism("lobeB", radius=3.2, height=2.0, at=(-5.2, 4.4, 1.9), role="rockd", sides=6, taper=1.4, turn=15)
    m.prism("lobeM", radius=4.2, height=2.2, at=(-5.2, 4.4, 4.0), role="rock", sides=6, turn=15)
    m.prism("lobeT", radius=4.2, height=2.0, at=(-5.2, 4.4, 6.1), role="rockl", sides=6, taper=0.55, turn=15, shear=(-0.3, 0.3))
    m.prism("lobeP", radius=1.7, height=3.6, at=S("lobeT", "top", (0.2, 0.2), sink=0.3), role="rockl", sides=5, taper=0.22, shear=(-0.9, 0.7))
    m.box("bumpA", size=(5.0, 4.0, 2.6), at=S("mid", "side2", (0, 0.2), sink=1.4), role="rock", chamfer=0.9, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.4, 3.6, 2.2), at=S("bot", "side5", (0, 0.3), sink=1.0), role="rockd", chamfer=0.7, taper=0.65)
    m.box("bumpC", size=(4.4, 3.4, 2.2), at=S("top", "side0", (0.4, -0.2), sink=1.1), role="rockl", chamfer=0.8, taper=0.65, rot=(0, 0, -15))
    mist(m, [("mistA", "mid", "side1", (0.4, -0.5), 5.0, 3.4, 0), ("mistB", "mid", "side3", (-0.6, 0.2), 4.6, 3.0, 8),
             ("mistC", "mid", "side6", (0.3, -0.7), 5.0, 3.2, -6), ("mistD", "lobeM", "side3", (0, -0.4), 4.4, 2.8, 0),
             ("mistE", "bot", "side3", (0.2, 0.7), 4.2, 2.6, 0), ("mistF", "mid", "side0", (1.6, 0.6), 3.8, 2.6, 5),
             ("mistG", "mid", "side2", (-1.8, -0.9), 3.6, 2.4, -5), ("mistH", "lobeM", "side1", (0.4, 0.5), 3.6, 2.4, 0),
             ("mistI", "mid", "side4", (0.2, 0.9), 4.0, 2.6, 0)])
    pumpkin(m, "pkA", "top", "top", (1.4, -1.4), 1.6)
    pumpkin(m, "pkB", "top", "top", (2.8, 0.6), 0.9, turn=-30)
    pumpkin(m, "pkC", "mistA", "back", (0, 0.4), 0.9, turn=20)
    candles(m, "cdA", "top", "top", (-1.8, 1.8), (1.1, 0.8, 0.55))
    candles(m, "cdB", "mistC", "back", (0, 0.3), (0.8, 0.55))
    lantern(m, "lnA", "top", "top", (-2.4, -1.4), post=1.4)
    lantern(m, "lnB", "mistD", "back", (0, 0), post=0.5)
    wisps(m, [("top", "side2", (0, 0.2), 0.9), ("top", "side4", (-0.4, 0.0), 0.8), ("mid", "side0", (-1.2, 0.6), 0.9),
              ("mid", "side4", (0.6, -0.4), 1.0), ("mid", "side5", (-1.0, 0.8), 0.8), ("lobeM", "side1", (0, -0.4), 0.8),
              ("top", "side1", (0.6, -0.2), 0.8), ("top", "side5", (0.2, 0.3), 0.9), ("bot", "side0", (0, 0.4), 0.8)])
    m.line("mid", "side0", [(0.6, -1.4), (1.2, -0.2), (2.2, 0.4)], "crackd", width=1)
    m.line("top", "side6", [(-0.8, -1.0), (0.0, 0.0), (0.6, 0.6)], "crackd", width=1)
    m.build()
    return m


def rock_v2():
    m = ropilot.model("Rock_R14_V2", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#4A5468", noise=0.03, mottle=("#3E4758", 0.22, 4), shade=0.2, top=0.15),
        rockd=dict(color="#363E4E", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#5A6478", noise=0.025, shade=0.12, top=0.12),
        mist=dict(color="#8A98BA", noise=0.02, shade=0.08, top=0.18), mistl=dict(color="#9CA8C8", noise=0.02, shade=0.06, top=0.15), mistp="#7886A0",
        pump=dict(color="#D86A1C", noise=0.03, shade=0.15, top=0.12), pumpl=dict(color="#E07A24", noise=0.03, shade=0.1, top=0.15),
        pumpd="#A84E16", face="#3A1A0C", stem=dict(color="#4E7A2A", noise=0.03, shade=0.1),
        wax=dict(color="#DCD2BA", noise=0.02, shade=0.12), iron=dict(color="#262C3A", noise=0.03, shade=0.12),
        vein="#E4ECF6",
        silver=dict(color="#E6EEF8", noise=0.02, shade=0.1, top=0.2),
        silverd=dict(color="#A8B8D0", noise=0.02, shade=0.1, top=0.15),
        glow=dict(color="#18C8C0", glow=True))
    S = m.surface
    m.prism("bot", radius=5.6, height=3.2, at=(0, 0, 1.6), role="rockd", sides=8, taper=1.42, turn=10)
    m.prism("mid", radius=8.0, height=3.6, at=(0, 0, 5.0), role="rock", sides=8, turn=10)
    m.prism("top", radius=8.0, height=3.2, at=(0, 0, 8.4), role="rockl", sides=8, taper=0.6, turn=10, shear=(-0.6, 0.5))
    m.box("bumpA", size=(5.4, 4.4, 3.0), at=S("mid", "side2", (0, 0.2), sink=1.4), role="rock", chamfer=0.9, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(4.8, 4.0, 2.4), at=S("top", "side5", (0.3, -0.2), sink=1.1), role="rockl", chamfer=0.8, taper=0.65)
    m.box("bumpC", size=(4.2, 3.4, 2.4), at=S("bot", "side6", (0, 0.3), sink=1.0), role="rockd", chamfer=0.7, taper=0.65)
    cluster(m, "sA", "top", "top", (0.8, -0.6), 2.2, "silver", "silverd", 5, 1)
    cluster(m, "sB", "mid", "side0", (0.5, 0.0), 1.5, "silver", "silverd", 4, 2)
    cluster(m, "sC", "mid", "side4", (-0.4, 0.2), 1.4, "silverd", "silver", 4, 3)
    cluster(m, "sD", "bumpA", "top", (0, 0), 1.1, "silver", "silverd", 3, 4)
    cluster(m, "sE", "top", "side7", (0, 0), 1.1, "silver", "silverd", 3, 5)
    cluster(m, "sG", "mid", "side6", (0.6, -0.2), 1.1, "silverd", "silver", 3, 11)
    cluster(m, "sH", "top", "side2", (0, 0), 1.1, "silver", "silverd", 3, 12)
    mist(m, [("mistA", "mid", "side1", (0.2, -0.6), 5.2, 3.4, 0), ("mistB", "mid", "side3", (-0.4, 0.3), 4.8, 3.0, 8),
             ("mistC", "mid", "side5", (0.3, -0.6), 5.0, 3.2, -6), ("mistD", "mid", "side7", (-0.6, 0.6), 4.4, 2.8, 0)])
    pumpkin(m, "pkA", "top", "top", (-2.8, 1.4), 1.2, turn=15)
    candles(m, "cdA", "mistB", "back", (0, 0.3), (0.9, 0.6, 0.45))
    lantern(m, "lnA", "top", "top", (-3.0, -1.6), post=1.2)
    for host, face, pts, w in [("mid", "side1", [(-2, -1.4), (-0.6, -0.2), (0.4, 0.1), (1.8, 1.2)], 3),
                               ("mid", "side3", [(-1.8, 1.2), (-0.4, 0.2), (1.6, -0.8)], 3),
                               ("mid", "side5", [(-1.6, -1.2), (0, 0), (0.8, 1.4)], 2),
                               ("mid", "side7", [(-1.6, 0.8), (0, 0.2), (1.6, -1)], 3),
                               ("top", "side3", [(-1.2, -0.8), (0.2, 0.2), (1.2, 0.5)], 2),
                               ("bot", "side2", [(-1.2, 0.6), (0.4, -0.2), (1.4, 0.2)], 2)]:
        m.line(host, face, pts, "vein", width=w)
    wisps(m, [("top", "side0", (-0.6, 0.2), 0.9), ("top", "side4", (0.4, 0.0), 0.8), ("mid", "side2", (1.6, 1.0), 0.7)])
    m.build()
    return m


def rock_v3():
    m = ropilot.model("Rock_R14_V3", px=8, reset=True, symmetric=False)
    m.palette(
        rock=dict(color="#3A4254", noise=0.03, mottle=("#303746", 0.2, 4), shade=0.2, top=0.15),
        rockd=dict(color="#2A303E", noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color="#485064", noise=0.025, shade=0.12, top=0.12),
        mist=dict(color="#7E8CAE", noise=0.02, shade=0.08, top=0.18), mistl=dict(color="#909CBC", noise=0.02, shade=0.06, top=0.15), mistp="#646F86",
        pump=dict(color="#D86A1C", noise=0.03, shade=0.15, top=0.12), pumpl=dict(color="#E07A24", noise=0.03, shade=0.1, top=0.15),
        pumpd="#A84E16", face="#3A1A0C", stem=dict(color="#4E7A2A", noise=0.03, shade=0.1),
        wax=dict(color="#DCD2BA", noise=0.02, shade=0.12),
        gold=dict(color="#FFC83A", noise=0.025, shade=0.12, top=0.25),
        goldd=dict(color="#E09A1E", noise=0.025, shade=0.12, top=0.2),
        glow=dict(color="#F0A020", glow=True))
    S = m.surface
    m.prism("bot", radius=6.4, height=3.6, at=(0, 0, 1.8), role="rockd", sides=9, taper=1.4, turn=5)
    m.prism("mid", radius=9.0, height=4.2, at=(0, 0, 5.7), role="rock", sides=9, turn=5)
    m.prism("top", radius=9.0, height=3.6, at=(0, 0, 9.6), role="rockl", sides=9, taper=0.58, turn=5, shear=(0.6, 0.7))
    m.prism("lobeP", radius=1.6, height=3.4, at=S("top", "top", (-3.2, 2.0), sink=0.4), role="rockl", sides=5, taper=0.22, shear=(-0.8, 0.6))
    m.box("bumpA", size=(6, 4.8, 3.2), at=S("mid", "side3", (0, 0.2), sink=1.5), role="rock", chamfer=1.0, taper=0.65, rot=(0, 0, 15))
    m.box("bumpB", size=(5.2, 4.2, 2.6), at=S("top", "side7", (0.3, -0.2), sink=1.2), role="rockl", chamfer=0.9, taper=0.65)
    m.box("bumpC", size=(4.6, 3.6, 2.6), at=S("bot", "side5", (0, 0.3), sink=1.1), role="rockd", chamfer=0.8, taper=0.65)
    cluster(m, "gcA", "top", "top", (0.8, -0.6), 1.9, "gold", "goldd", 5, 7)
    cluster(m, "gcB", "mid", "side0", (0.4, 0.1), 1.4, "gold", "goldd", 4, 8)
    cluster(m, "gcC", "mid", "side5", (-0.3, 0.2), 1.3, "goldd", "gold", 4, 9)
    cluster(m, "gcD", "bumpA", "top", (0, 0), 1.1, "gold", "goldd", 3, 10)
    cluster(m, "gcE", "top", "side2", (0, 0), 1.0, "gold", "goldd", 3, 12)
    cluster(m, "gcF", "mid", "side7", (0.3, -0.2), 1.2, "gold", "goldd", 4, 13)
    nuggets(m, [("n1", "top", "top", (3.0, 1.6), 1.4, 20), ("n2", "mid", "side2", (-0.6, -0.4), 1.3, -10),
                ("n3", "mid", "side8", (0.5, 0.6), 1.2, 35), ("n4", "bumpC", "top", (0, 0), 1.0, 10),
                ("n5", "top", "side4", (0, 0), 1.2, -25), ("n6", "bot", "side1", (0, 0.2), 1.0, 5),
                ("n7", "top", "top", (-1.0, -3.2), 1.1, 40)])
    cracks(m, [("mid", "side1", (-1.5, -1.2), (1.4, 1.1)), ("mid", "side4", (-1.4, 1.0), (1.5, -0.9)),
               ("mid", "side6", (-1.2, -0.8), (1.3, 0.9)), ("top", "side0", (-1.0, -0.3), (1.0, 0.3))])
    mist(m, [("mistA", "mid", "side1", (0.2, 0.9), 5.4, 3.4, 0), ("mistB", "mid", "side3", (0.4, -1.0), 5.0, 3.2, 8),
             ("mistC", "mid", "side6", (0.3, 1.0), 5.0, 3.0, -6)])
    pumpkin(m, "pkA", "top", "top", (-3.4, -1.0), 1.2, turn=-20)
    candles(m, "cdA", "mistA", "back", (0, 0.3), (0.9, 0.6, 0.45))
    candles(m, "cdB", "top", "top", (2.2, -2.8), (0.8, 0.55))
    wisps(m, [("top", "side3", (0.6, 0.2), 0.8), ("top", "side5", (-0.4, 0.0), 0.8)])
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
    for c in ("Rock_R14_V1", "Rock_R14_V2", "Rock_R14_V3"):
        join_rock(c)
