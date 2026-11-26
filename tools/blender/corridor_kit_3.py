# Décors du couloir, suite (biomes 9 à 14). À exécuter après corridor_kit.py et corridor_kit_2.py, dans le
# même espace de noms :  exec(open(".../corridor_kit_3.py").read(), CK)
import math
import random


# 9. STORM HALO ---------------------------------------------------------------------------------------

@model
def StormCloud():
    # nuage d'orage sombre qui crache un éclair en zigzag
    m = M("StormCloud")
    m.palette(cloud=plain("#4E4A78", shade=0.2, top=0.16), cloudd=plain("#38345C", shade=0.2), cloudl=plain("#6A65A0", top=0.18),
              glow=glow("#FFD92E"), glowR=glow("#7CA8FF"))
    m.box("c0", size=(7.4, 5.0, 3.8), at=(0, 0, 10.2), role="cloud", chamfer=1.3)
    m.box("c1", size=(5.0, 4.4, 3.2), at=(4.0, 0.2, 9.6), role="cloudd", chamfer=1.1)
    m.box("c2", size=(4.6, 4.0, 3.0), at=(-4.0, -0.2, 9.4), role="cloudd", chamfer=1.0)
    m.box("c3", size=(4.6, 3.8, 3.0), at=(0.8, 0, 12.6), role="cloudl", chamfer=1.0)
    m.box("c4", size=(3.2, 3.0, 2.4), at=(-2.4, 0.3, 12.2), role="cloud", chamfer=0.8)
    m.box("c5", size=(3.6, 3.2, 1.8), at=(1.8, -1.4, 8.2), role="cloudd", chamfer=0.6)
    zig = [(0.6, 8.2), (-0.9, 6.0), (0.5, 5.6), (-1.1, 3.2), (0.3, 2.9), (-0.6, 0.3)]
    w = 1.0
    for i in range(len(zig) - 1):
        (x0, z0), (x1, z1) = zig[i], zig[i + 1]
        m.beam("bolt%d" % i, (x0, -0.6, z0), (x1, -0.6, z1), role="glow", width=w, depth=0.4, taper=0.85)
        w *= 0.88
    for i, (x, y, z, l) in enumerate(((-3.6, -0.8, 7.0, 1.4), (3.4, -1.0, 6.6, 1.2), (4.8, 0.6, 7.4, 1.0), (-4.8, 0.4, 6.8, 1.1), (2.2, 0.8, 5.4, 0.9))):
        m.box("rain%d" % i, size=(0.22, 0.22, l), at=(x, y, z - l / 2), role="glowR", rot=(0, 10, 0), solo=True)
    m.build()
    return m


@model
def Rod():
    # paratonnerre : mât de métal, bobines, boule chargée au sommet
    m = M("Rod")
    m.palette(metal=plain("#5A5884", shade=0.18, rim=-0.15), metald=plain("#3E3C62"), copper=plain("#B0703A", streaks=("#8A5428", 0.3, "u")),
              rock=plain("#4E4A78", mottle=("#3A3660", 0.25, 4)), glow=glow("#FFD92E"))
    m.prism("base", radius=3.4, height=1.4, at=(0, 0, 0.7), role="rock", sides=7, taper=0.84)
    m.box("plinth", size=(3.4, 3.4, 1.4), at=(0, 0, 2.1), role="metald", chamfer=0.3, taper=0.85)
    m.prism("mast", radius=0.7, height=9.0, at=(0, 0, 7.3), role="metal", sides=6, taper=0.6)
    for i, (z, r) in enumerate(((4.2, 1.9), (6.2, 1.6), (8.2, 1.3))):
        m.prism("coil%d" % i, radius=r, height=0.7, at=(0, 0, z), role="copper", sides=10)
        m.prism("coilIn%d" % i, radius=r * 0.7, height=0.9, at=(0, 0, z), role="metald", sides=10)
    for i in range(3):
        a = math.radians(90 + i * 120)
        m.beam("leg%d" % i, (math.cos(a) * 2.6, math.sin(a) * 2.6, 1.2), (math.cos(a) * 0.5, math.sin(a) * 0.5, 4.6), role="metald", width=0.4)
    m.crystal("tip", radius=1.0, height=2.6, at=(0, 0, 11.4), role="glow", sides=6, tip=0.4, base_tip=0.4, solo=True)
    for i, (dx, dz) in enumerate(((1.6, 0.8), (-1.5, 1.2), (1.2, -0.6))):
        m.beam("arc%d" % i, (0, -0.2, 12.7), (dx, -0.4, 12.7 + dz), role="glow", width=0.22, taper=0.5)
    m.build()
    return m


# 10. CLOCKWORK BELT ----------------------------------------------------------------------------------

def gear(m, pre, r, teeth, at, role, roled, thick=1.2, glow_role="glow"):
    # rouage vu de face (axe vers l'avant) : disque, dents, moyeu ; préfixe « spin » = pièce qui tourne
    x, y, z = at
    m.prism(pre + "disc", radius=r, height=thick, at=(x, y, z), role=role, sides=max(8, teeth), rot=(90, 0, 0))
    for i in range(teeth):
        a = i / teeth * math.tau
        m.box("%stooth%d" % (pre, i), size=(r * 0.42, thick, r * 0.36), at=(x + math.cos(a) * r * 1.08, y, z + math.sin(a) * r * 1.08), role=role,
              rot=(0, -math.degrees(a) + 90, 0), taper=0.8)
    m.prism(pre + "hub", radius=r * 0.36, height=thick * 1.5, at=(x, y, z), role=roled, sides=8, rot=(90, 0, 0))
    m.prism(pre + "pin", radius=r * 0.14, height=thick * 1.8, at=(x, y, z), role=glow_role, sides=6, rot=(90, 0, 0), solo=True)
    for i in range(4):
        a = i / 4 * math.tau + 0.4
        m.prism("%shole%d" % (pre, i), radius=r * 0.16, height=thick * 1.1, at=(x + math.cos(a) * r * 0.64, y, z + math.sin(a) * r * 0.64), role=roled, sides=6,
                rot=(90, 0, 0))


@model
def Gear():
    # deux rouages de laiton qui s'engrènent sur un bâti riveté
    m = M("Gear")
    m.palette(brass=plain("#A87A2E", top=0.22, rim=-0.2), brassd=plain("#7E5A20"), copper=plain("#A8643A"), steel=plain("#4E5A6E", rim=-0.15),
              steeld=plain("#384252"), rivet="#D9B24A", glow=glow("#3FE0C8"))
    m.box("base", size=(8.0, 4.4, 1.4), at=(0, 0.6, 0.7), role="steeld", chamfer=0.3)
    m.box("frame", size=(2.0, 1.6, 8.0), at=(0, 1.2, 5.2), role="steel", chamfer=0.25, taper=0.8)
    m.box("frame2", size=(1.6, 1.4, 3.4), at=(4.4, 1.2, 2.9), role="steel", chamfer=0.2, taper=0.8)
    m.box("brace", size=(5.6, 0.8, 0.8), at=(2.2, 1.2, 2.6), role="steeld", rot=(0, -20, 0))
    gear(m, "spinA", 3.6, 10, (0, -0.2, 8.4), "brass", "brassd", glow_role="rivet")
    gear(m, "spin2B", 2.0, 7, (4.5, -0.2, 3.9), "copper", "brassd", thick=1.0, glow_role="rivet")
    m.build()
    for x in (-3.2, -1.6, 1.6, 3.2):
        m.rect("base", "front", (x, 0), (0.4, 0.4), "rivet")
    for z in (-2.6, -1.0, 0.6, 2.2):
        m.rect("frame", "front", (0, z), (0.4, 0.4), "rivet")
    return m


@model
def Pipe():
    # tuyauterie de laiton : coude, brides rivetées, manomètre, volant de vanne
    m = M("Pipe")
    m.palette(brass=plain("#A87A2E", top=0.22, streaks=("#8A6222", 0.25, "v")), brassd=plain("#7E5A20"), steel=plain("#4E5A6E", rim=-0.15),
              steeld=plain("#384252"), dial=plain("#D8D0B8"), red=plain("#B03A2E"), rivet="#D9B24A", glow=glow("#3FE0C8"))
    m.prism("foot", radius=2.6, height=0.9, at=(0, 0, 0.45), role="steeld", sides=8)
    m.prism("p1", radius=1.5, height=8.6, at=(0, 0, 5.2), role="brass", sides=8)
    for i, z in enumerate((2.2, 6.0, 9.2)):
        m.prism("fl%d" % i, radius=2.0, height=0.6, at=(0, 0, z), role="steel", sides=8)
    m.box("elbow", size=(3.2, 3.2, 3.2), at=(0, 0, 11.0), role="brassd", chamfer=0.9)
    m.prism("p2", radius=1.5, height=3.4, at=(0, -2.8, 11.0), role="brass", sides=8, rot=(90, 0, 0))
    m.prism("mouth", radius=2.0, height=0.7, at=(0, -4.6, 11.0), role="steel", sides=8, rot=(90, 0, 0))
    m.prism("mouthIn", radius=1.2, height=0.3, at=(0, -4.95, 11.0), role="steeld", sides=8, rot=(90, 0, 0))
    # petit tuyau latéral et manomètre
    m.beam("side", (1.2, 0, 4.2), (3.6, 0, 4.2), role="brassd", width=0.9)
    m.beam("sideUp", (3.6, 0, 3.9), (3.6, 0, 7.0), role="brassd", width=0.9)
    m.prism("gauge", radius=1.3, height=0.6, at=(3.6, -0.5, 7.8), role="steel", sides=10, rot=(90, 0, 0))
    m.prism("gaugeFace", radius=1.0, height=0.7, at=(3.6, -0.55, 7.8), role="dial", sides=10, rot=(90, 0, 0))
    m.beam("needle", (3.6, -0.95, 7.8), (4.2, -0.95, 8.5), role="red", width=0.16)
    # volant de vanne qui tourne
    m.prism("spindisc", radius=1.5, height=0.3, at=(-2.3, -0.4, 6.0), role="red", sides=8, rot=(90, 0, 90))
    for i in range(4):
        a = i / 4 * math.tau
        m.box("spinspoke%d" % i, size=(0.34, 0.34, 2.8), at=(-2.3, -0.4, 6.0), role="red", rot=(math.degrees(a), 0, 0))
    m.beam("stem", (-1.2, -0.4, 6.0), (-2.2, -0.4, 6.0), role="steeld", width=0.4)
    m.prism("lamp", radius=0.5, height=0.6, at=(0, -1.75, 12.9), role="glow", sides=6, solo=True)
    m.build()
    for i in range(8):
        m.rect("mouth", "side%d" % i, (0, 0), (0.25, 0.25), "rivet")
    return m


# 11. CANDY COMET -------------------------------------------------------------------------------------

@model
def Lollipop():
    # grande sucette en spirale (elle tourne), nœud de ruban, petits bonbons au pied
    m = M("Lollipop")
    m.palette(stick=plain("#D8D0C4", shade=0.12), candy=plain("#C8447A"), candyl=plain("#E886A8"), cream=plain("#E8DCD0"), swirl="#E8DCD0",
              bow=plain("#3F9AC8"), bowd=plain("#2E7AA6"), base=plain("#B8527A", mottle=("#9A3E64", 0.2, 4)), mint=plain("#5CC8A0"),
              lemon=plain("#D9B83A"), glow=glow("#7FE0FF"))
    m.prism("base", radius=3.4, height=1.2, at=(0, 0, 0.6), role="base", sides=8, taper=0.84)
    m.prism("stick", radius=0.5, height=8.2, at=(0, 0, 5.0), role="stick", sides=6)
    # disque de sucette, face au couloir
    m.prism("spindisc", radius=3.9, height=1.3, at=(0, 0, 11.4), role="candy", sides=12, rot=(90, 0, 0))
    m.prism("spinrim", radius=4.2, height=0.7, at=(0, 0, 11.4), role="candyl", sides=12, rot=(90, 0, 0))
    m.prism("spinmid", radius=2.6, height=1.6, at=(0, 0, 11.4), role="cream", sides=10, rot=(90, 0, 0))
    m.prism("spincore", radius=1.3, height=1.9, at=(0, 0, 11.4), role="candy", sides=8, rot=(90, 0, 0))
    for i in range(6):
        a = i / 6 * math.tau
        m.box("spinarm%d" % i, size=(0.5, 1.45, 1.5), at=(math.cos(a) * 3.2, 0, 11.4 + math.sin(a) * 3.2), role="cream", rot=(0, -math.degrees(a) + 60, 0))
    m.box("bowL", size=(1.6, 0.6, 1.2), at=(-1.0, -0.5, 6.9), role="bow", taper=(0.3, 1), axis="x", rot=(0, 0, 180))
    m.box("bowR", size=(1.6, 0.6, 1.2), at=(1.0, -0.5, 6.9), role="bow", taper=(0.3, 1), axis="x")
    m.box("knot", size=(0.7, 0.7, 0.7), at=(0, -0.55, 6.9), role="bowd", chamfer=0.15)
    for i, (x, y, role) in enumerate(((-2.2, -1.6, "mint"), (2.0, -1.9, "lemon"), (2.6, 1.0, "candyl"))):
        m.box("drop%d" % i, size=(1.3, 1.1, 0.9), at=(x, y, 1.6), role=role, chamfer=0.3, rot=(0, 0, 30 * i))
    m.crystal("shine", radius=0.3, height=0.9, at=(3.6, -1.0, 14.4), role="glow", sides=4, tip=0.5, base_tip=0.5, solo=True)
    m.build()
    return m


@model
def CandyCane():
    # sucre d'orge rayé et sa crosse, glaçage qui coule sur le socle
    m = M("CandyCane")
    m.palette(red=plain("#B8323E"), white=plain("#E0D8D0", shade=0.1), icing=plain("#E8A8C4", shade=0.1, top=0.15), base=plain("#8A5A44", mottle=("#6E4534", 0.2, 4)),
              sprA=plain("#3F9AC8"), sprB=plain("#D9B83A"), sprC=plain("#5CC8A0"), glow=glow("#7FE0FF"))
    m.prism("base", radius=3.6, height=1.4, at=(0, 0, 0.7), role="base", sides=8, taper=0.84)
    m.prism("icing", radius=3.2, height=0.5, at=(0, 0, 1.55), role="icing", sides=8)
    for i, a in enumerate((0.4, 1.9, 3.3, 4.6, 5.6)):
        m.box("drip%d" % i, size=(0.8, 0.5, 0.9 + (i % 2) * 0.5), at=(math.cos(a) * 3.1, math.sin(a) * 3.1, 1.0 - (i % 2) * 0.2), role="icing", chamfer=0.15)
    # tige et crosse en tronçons rayés
    pts = [(-1.0, 0, 1.6 + i * 1.5) for i in range(7)]
    for k in range(1, 6):
        a = k * 0.62
        pts.append((-1.0 + (1 - math.cos(a)) * 2.0, 0, 10.6 + math.sin(a) * 2.0))
    for i in range(len(pts) - 1):
        m.beam("cane%d" % i, pts[i], pts[i + 1], role="red" if i % 2 == 0 else "white", width=1.5)
    for i, (x, y, role) in enumerate(((1.6, -1.6, "sprA"), (-2.2, -1.2, "sprB"), (0.6, 2.0, "sprC"), (2.4, 0.6, "sprB"), (-1.6, 1.8, "sprA"))):
        m.box("spr%d" % i, size=(0.9, 0.3, 0.3), at=(x, y, 1.95), role=role, rot=(0, 0, 40 * i))
    m.crystal("shine", radius=0.3, height=0.9, at=(2.6, -0.8, 13.6), role="glow", sides=4, tip=0.5, base_tip=0.5, solo=True)
    m.build()
    return m


@model
def Gumdrop():
    # gros bonbon gélifié couvert de sucre, cupcake et bonbon emballé à côté
    m = M("Gumdrop")
    m.palette(gum=plain("#4FA85A", speckle=("#E8F0E0", 0.06), shade=0.12, top=0.2), gumd=plain("#3A8446", speckle=("#E8F0E0", 0.06)),
              gumv=plain("#8A5CC4", speckle=("#F0E8F8", 0.06)), gumvd=plain("#6A44A0"), cake=plain("#A8703E"), icing=plain("#E8A8C4", top=0.15),
              cherry=plain("#B8323E"), wrap=plain("#3F9AC8"), wrapl=plain("#7FC4E4"), base=plain("#B8527A", mottle=("#9A3E64", 0.2, 4)),
              glow=glow("#7FE0FF"))
    m.prism("base", radius=5.2, height=1.0, at=(0, 0, 0.5), role="base", sides=9, taper=0.88)
    m.prism("g0", radius=3.6, height=2.4, at=(0, 0.6, 2.2), role="gumd", sides=9, taper=0.92)
    m.prism("g1", radius=3.3, height=2.2, at=(0, 0.6, 4.5), role="gum", sides=9, taper=0.78)
    m.prism("g2", radius=2.55, height=1.6, at=(0, 0.6, 6.4), role="gum", sides=9, taper=0.5)
    m.prism("v0", radius=1.9, height=1.5, at=(-3.6, -1.8, 1.75), role="gumvd", sides=8, taper=0.9)
    m.prism("v1", radius=1.7, height=1.5, at=(-3.6, -1.8, 3.25), role="gumv", sides=8, taper=0.5)
    # cupcake
    m.prism("cup", radius=1.3, height=1.6, at=(3.4, -1.8, 1.8), role="cake", sides=10, taper=1.3)
    m.prism("top0", radius=1.9, height=0.9, at=(3.4, -1.8, 3.05), role="icing", sides=8, taper=0.8)
    m.prism("top1", radius=1.4, height=0.8, at=(3.4, -1.8, 3.9), role="icing", sides=8, taper=0.6, turn=20)
    m.prism("top2", radius=0.8, height=0.7, at=(3.4, -1.8, 4.6), role="icing", sides=8, taper=0.3, turn=40)
    m.box("cherry", size=(0.8, 0.8, 0.8), at=(3.4, -1.8, 5.2), role="cherry", chamfer=0.25)
    # bonbon emballé
    m.box("wrapMid", size=(1.8, 1.2, 1.2), at=(0.6, -3.6, 1.6), role="wrap", chamfer=0.35, rot=(0, 0, 15))
    m.box("wrapL", size=(1.0, 1.2, 1.2), at=(-0.75, -3.95, 1.6), role="wrapl", taper=(1, 0.2), axis="x", rot=(0, 0, 195))
    m.box("wrapR", size=(1.0, 1.2, 1.2), at=(1.95, -3.25, 1.6), role="wrapl", taper=(1, 0.2), axis="x", rot=(0, 0, 15))
    m.crystal("shine", radius=0.3, height=0.9, at=(1.6, -0.6, 8.6), role="glow", sides=4, tip=0.5, base_tip=0.5, solo=True)
    m.build()
    return m


# 12. MUSHROOM MOON -----------------------------------------------------------------------------------

def shroom(m, pre, x, y, h, r, stem, cap, capd, capl, glow_role="glow", spots=True, sides=9):
    m.prism(pre + "stem", radius=r * 0.3, height=h, at=(x, y, 1.0 + h / 2), role=stem, sides=7, taper=0.75)
    z = 1.0 + h
    m.prism(pre + "gill", radius=r * 0.78, height=0.3, at=(x, y, z - 0.1), role=glow_role, sides=sides, solo=True)
    m.prism(pre + "cap0", radius=r, height=r * 0.34, at=(x, y, z + r * 0.17), role=capd, sides=sides, taper=0.94)
    m.prism(pre + "cap1", radius=r * 0.94, height=r * 0.36, at=(x, y, z + r * 0.52), role=cap, sides=sides, taper=0.74)
    m.prism(pre + "cap2", radius=r * 0.7, height=r * 0.3, at=(x, y, z + r * 0.85), role=capl, sides=sides, taper=0.45)
    if spots:
        for i in range(5):
            a = i / 5 * math.tau + 0.5
            m.prism("%sspot%d" % (pre, i), radius=r * 0.15, height=0.2, at=(x + math.cos(a) * r * 0.62, y + math.sin(a) * r * 0.62, z + r * 0.78), role="spot",
                    sides=6, rot=(math.degrees(math.sin(a)) * 0.45, -math.degrees(math.cos(a)) * 0.45, 0), solo=True)
        m.prism(pre + "spotT", radius=r * 0.16, height=0.2, at=(x, y, z + r * 1.02), role="spot", sides=6, solo=True)


@model
def Mushroom():
    # grand champignon rouge à pois, lamelles lumineuses, deux petits et de la mousse
    m = M("Mushroom")
    m.palette(stem=plain("#D0C4AC", streaks=("#B0A48C", 0.25, "v")), cap=plain("#B8323E", top=0.2), capd=plain("#8E2430"), capl=plain("#D05560"),
              blue=plain("#2E9AB8", top=0.2), blued=plain("#207890"), bluel=plain("#5CC4DA"), spot=plain("#E8E0D4"),
              moss=plain("#4A7A52", mottle=("#386040", 0.3, 4), top=0.2), mossd=plain("#386040"), glow=glow("#5CF0C8"))
    m.prism("base", radius=5.0, height=1.4, at=(0, 0, 0.7), role="moss", sides=9, taper=0.84, turn=8)
    m.box("mossA", size=(3.4, 2.6, 1.4), at=(-3.2, -1.4, 1.2), role="mossd", chamfer=0.5, taper=0.7)
    shroom(m, "A", 0.4, 0.4, 7.4, 5.2, "stem", "cap", "capd", "capl")
    shroom(m, "B", -3.4, -1.6, 2.4, 2.0, "stem", "blue", "blued", "bluel", spots=False, sides=8)
    shroom(m, "C", 3.6, -2.0, 1.6, 1.5, "stem", "blue", "blued", "bluel", spots=False, sides=7)
    m.beam("ring", (-1.0, 0.4, 6.0), (1.8, 0.4, 6.0), role="stem", width=0.5, depth=2.6)
    for i, (x, y, z) in enumerate(((-2.4, -2.6, 6.6), (2.8, -1.0, 8.0), (-4.2, 0.6, 9.4))):
        m.crystal("spore%d" % i, radius=0.28, height=0.8, at=(x, y, z), role="glow", sides=5, tip=0.5, base_tip=0.5, solo=True)
    m.build()
    return m


@model
def Spores():
    # souche moussue couverte de petits champignons lumineux, spores qui montent
    m = M("Spores")
    m.palette(wood=plain("#5E4A5E", streaks=("#48384A", 0.3, "v")), woodd=plain("#48384A"), woodl=plain("#7A6278", tiles=(3, 0.15)),
              stem=plain("#D0C4AC"), blue=plain("#2E9AB8", top=0.2), blued=plain("#207890"), bluel=plain("#5CC4DA"),
              vio=plain("#8A5CC4", top=0.2), viod=plain("#6A44A0"), viol=plain("#A884DC"), moss=plain("#4A7A52", mottle=("#386040", 0.3, 4)),
              spot=plain("#E8E0D4"), glow=glow("#5CF0C8"))
    m.prism("stump", radius=3.4, height=4.2, at=(0, 0, 2.1), role="wood", sides=8, taper=0.84, turn=10)
    m.prism("rings", radius=2.7, height=0.2, at=(0, 0, 4.25), role="woodl", sides=8, turn=10)
    for i in range(5):
        a = i / 5 * math.tau + 0.3
        m.beam("root%d" % i, (math.cos(a) * 2.6, math.sin(a) * 2.6, 1.6), (math.cos(a) * 5.0, math.sin(a) * 5.0, 0.2), role="woodd", width=1.0, taper=0.5)
    m.box("mossA", size=(3.0, 2.2, 0.8), at=(-1.2, 0.8, 4.5), role="moss", chamfer=0.3)
    shroom(m, "A", 1.0, -0.6, 4.2, 2.2, "stem", "blue", "blued", "bluel", spots=False, sides=8)
    shroom(m, "B", -1.6, 0.4, 5.6, 1.7, "stem", "vio", "viod", "viol", spots=False, sides=7)
    shroom(m, "C", 0.2, 1.8, 3.6, 1.4, "stem", "blue", "blued", "bluel", spots=False, sides=7)
    # tablettes de champignons sur le flanc
    for i, (a, z, r) in enumerate(((4.4, 1.6, 1.4), (4.9, 2.8, 1.1), (5.4, 1.9, 0.9))):
        m.prism("shelf%d" % i, radius=r, height=0.4, at=(math.cos(a) * 3.3, math.sin(a) * 3.3, z), role="vio" if i % 2 else "blue", sides=6)
        m.prism("shelfG%d" % i, radius=r * 0.8, height=0.15, at=(math.cos(a) * 3.3, math.sin(a) * 3.3, z - 0.25), role="glow", sides=6, solo=True)
    for i, (x, y, z, s) in enumerate(((2.6, -1.6, 9.4, 0.4), (-2.8, -0.8, 11.2, 0.3), (0.6, 0.6, 12.8, 0.35), (3.4, 1.0, 11.8, 0.25), (-1.0, -2.0, 13.6, 0.25))):
        m.crystal("spore%d" % i, radius=s, height=s * 2.6, at=(x, y, z), role="glow", sides=5, tip=0.5, base_tip=0.5, solo=True)
    m.build()
    return m


# 13. JADE TEMPLE -------------------------------------------------------------------------------------

@model
def Pillar():
    # colonne de jade sculptée, bagues d'or, sommet brisé envahi de mousse
    m = M("Pillar")
    m.palette(jade=plain("#2E8A66", mottle=("#236E50", 0.2, 5), top=0.18, tiles=(6, 0.1)), jaded=plain("#236E50"), jadel=plain("#4CA884"),
              gold=plain("#B8892E", top=0.22, rim=-0.2), goldd=plain("#8F6820"), carve="#1C5A42", moss=plain("#5A8A3E", mottle=("#44702E", 0.3, 3)),
              glow=glow("#FFD45C"))
    m.box("step0", size=(6.4, 6.4, 1.0), at=(0, 0, 0.5), role="jaded", chamfer=0.2)
    m.box("step1", size=(5.2, 5.2, 0.9), at=(0, 0, 1.45), role="jade", chamfer=0.2)
    m.box("plinth", size=(4.2, 4.2, 0.8), at=(0, 0, 2.3), role="gold", chamfer=0.2)
    m.prism("shaft", radius=1.8, height=8.0, at=(0, 0, 6.7), role="jade", sides=8, taper=0.88)
    m.prism("band0", radius=2.0, height=0.6, at=(0, 0, 4.4), role="gold", sides=8)
    m.prism("band1", radius=1.8, height=0.6, at=(0, 0, 8.8), role="gold", sides=8)
    m.box("cap", size=(4.4, 4.4, 1.0), at=(0, 0, 11.2), role="gold", chamfer=0.25, taper=1.15)
    m.box("capTop", size=(5.0, 5.0, 0.7), at=(0, 0, 12.05), role="goldd", chamfer=0.15)
    m.box("broken", size=(3.4, 3.2, 1.6), at=(0.3, 0.2, 13.1), role="jadel", chamfer=0.4, slope=(1.0, -0.6))
    m.box("mossTop", size=(2.6, 2.2, 0.5), at=(-0.5, -0.6, 12.65), role="moss", chamfer=0.15)
    m.box("rubble", size=(1.8, 1.5, 1.2), at=(3.6, -2.2, 0.6), role="jadel", chamfer=0.3, rot=(10, 15, 30))
    m.box("rubble2", size=(1.2, 1.0, 0.8), at=(-3.7, 2.0, 0.4), role="jade", chamfer=0.2, rot=(0, 0, 50))
    m.box("gem", size=(0.9, 0.3, 0.9), at=(0, -2.2, 11.2), role="glow", rot=(0, 45, 0), solo=True)
    m.build()
    for i in range(8):
        m.line("shaft", "side%d" % i, [(0, -3.0), (0, 3.0)], "carve", width=1)
        m.stamp("shaft", "side%d" % i, (0, 0.2), ["#.#", ".#.", "#.#"], {"#": "carve"}, cell=0.25)
    return m


@model
def Torii():
    # portique : deux piliers de jade, linteaux d'or aux bouts relevés, lanterne suspendue
    m = M("Torii")
    m.palette(jade=plain("#2E8A66", mottle=("#236E50", 0.2, 5), top=0.18), jaded=plain("#236E50"), gold=plain("#B8892E", top=0.22, rim=-0.2),
              goldd=plain("#8F6820"), red=plain("#A83A32"), carve="#1C5A42", rope=plain("#C9B88A"), glow=glow("#FFD45C"))
    for i, x in enumerate((-5.0, 5.0)):
        m.box("foot%d" % i, size=(3.0, 3.0, 1.2), at=(x, 0, 0.6), role="goldd", chamfer=0.25, taper=0.85)
        m.prism("post%d" % i, radius=1.1, height=10.0, at=(x, 0, 6.2), role="jade", sides=8, taper=0.86, shear=(-0.12 * x, 0))
        m.prism("ring%d" % i, radius=1.3, height=0.5, at=(x * 0.93, 0, 9.4), role="gold", sides=8)
    m.box("tie", size=(11.6, 1.2, 1.1), at=(0, 0, 8.6), role="jaded", chamfer=0.15)
    m.box("lintel", size=(13.6, 1.8, 1.3), at=(0, 0, 11.5), role="red", chamfer=0.2)
    m.box("roof", size=(15.6, 2.6, 0.9), at=(0, 0, 12.6), role="gold", chamfer=0.2)
    m.box("tipL", size=(2.4, 2.6, 0.9), at=(-8.6, 0, 13.05), role="gold", slope=(-0.9, 0), chamfer=0.15)
    m.box("tipR", size=(2.4, 2.6, 0.9), at=(8.6, 0, 13.05), role="gold", slope=(0.9, 0), chamfer=0.15)
    m.box("plaque", size=(2.2, 0.5, 1.8), at=(0, -0.75, 10.0), role="goldd", chamfer=0.15)
    m.box("plaqueGem", size=(0.8, 0.3, 0.8), at=(0, -1.05, 10.0), role="glow", rot=(0, 45, 0), solo=True)
    # lanterne suspendue
    m.beam("rope", (0, 0, 8.0), (0, 0, 6.4), role="rope", width=0.18)
    m.box("lanTop", size=(1.6, 1.6, 0.4), at=(0, 0, 6.3), role="goldd", taper=0.6)
    m.box("lan", size=(1.2, 1.2, 1.5), at=(0, 0, 5.35), role="glow", solo=True)
    m.box("lanBot", size=(1.6, 1.6, 0.3), at=(0, 0, 4.45), role="goldd")
    m.build()
    return m


@model
def Idol():
    # petite idole de jade (grenouille gardienne) sur son autel, collier d'or, gemme au front
    m = M("Idol")
    m.palette(jade=plain("#2E8A66", mottle=("#236E50", 0.2, 5), top=0.18), jaded=plain("#236E50"), jadel=plain("#4CA884"), belly=plain("#7CC4A0"),
              gold=plain("#B8892E", top=0.22, rim=-0.2), goldd=plain("#8F6820"), stone=plain("#5E7A6C", tiles=(5, 0.14)), eye="#141A18", white="#E8F0E0",
              glow=glow("#FFD45C"))
    m.box("altar0", size=(7.0, 6.0, 1.2), at=(0, 0, 0.6), role="stone", chamfer=0.2)
    m.box("altar1", size=(5.8, 5.0, 1.0), at=(0, 0, 1.7), role="goldd", chamfer=0.2)
    m.box("body", size=(4.8, 4.2, 4.0), at=(0, 0.2, 4.2), role="jade", chamfer=1.0, taper=0.86)
    m.box("belly", size=(3.0, 0.6, 2.6), at=(0, -1.85, 3.9), role="belly", chamfer=0.25)
    m.box("head", size=(5.2, 4.0, 3.0), at=(0, -0.1, 7.6), role="jadel", chamfer=0.9, taper=0.9)
    m.box("eyeL", size=(1.5, 1.4, 1.4), at=(-1.6, -0.6, 9.4), role="jade", chamfer=0.4, mirror=True)
    m.box("legL", size=(1.8, 2.6, 1.6), at=(-2.7, -0.9, 2.9), role="jaded", chamfer=0.5, mirror=True)
    m.box("armL", size=(1.1, 1.2, 2.2), at=(-1.9, -2.0, 4.0), role="jaded", chamfer=0.3, mirror=True)
    m.box("collar", size=(4.4, 3.8, 0.6), at=(0, 0.1, 6.1), role="gold", chamfer=0.15)
    m.box("gem", size=(0.8, 0.3, 0.8), at=(0, -2.15, 8.3), role="glow", rot=(0, 45, 0), solo=True)
    m.box("crown", size=(2.0, 1.6, 0.6), at=(0, 0, 9.4), role="gold", chamfer=0.15, taper=0.8)
    for i, x in enumerate((-2.8, 2.8)):
        m.prism("cup%d" % i, radius=0.6, height=0.8, at=(x, -1.9, 2.6), role="gold", sides=6, taper=1.3)
        m.crystal("flame%d" % i, radius=0.35, height=1.0, at=(x, -1.9, 3.0), role="glow", sides=5, tip=0.6, solo=True)
    m.build()
    m.rect("eyeL", "front", (0, 0.05), (0.75, 0.75), "white")
    m.rect("eyeL", "front", (0.05, 0.05), (0.4, 0.5), "eye")
    m.line("head", "front", [(-1.4, -0.7), (-0.6, -0.95), (0.6, -0.95), (1.4, -0.7)], "eye", width=1)
    return m


# 14. PHANTOM MIST ------------------------------------------------------------------------------------

@model
def Lantern():
    # réverbère de fer tordu, lanterne à flamme turquoise, pavés et petite citrouille
    m = M("Lantern")
    m.palette(iron=plain("#3A3E5C", shade=0.2, rim=-0.15), irond=plain("#282B44"), stone=plain("#5A6480", tiles=(4, 0.16), mottle=("#485068", 0.2, 4)),
              stoned=plain("#485068"), glass=plain("#2E8A8A"), pump=plain("#B8642A"), pumpd=plain("#8E4A1E"), stem=plain("#4A7A3E"), glow=glow("#4FF0D8"))
    m.prism("base", radius=3.4, height=1.2, at=(0, 0, 0.6), role="stone", sides=8, taper=0.86)
    m.box("plinth", size=(2.0, 2.0, 1.4), at=(0, 0, 1.9), role="stoned", chamfer=0.3, taper=0.8)
    pts = [(0, 0, 2.4), (0.2, 0, 6.0), (-0.1, 0, 9.4), (0.4, 0, 12.0), (1.6, 0, 13.2), (2.8, 0, 12.8)]
    chain(m, "post", pts, "iron", 0.8, taper=0.92, roles=("iron", "irond"))
    m.beam("hang", (2.8, 0, 12.8), (2.8, 0, 11.4), role="irond", width=0.2)
    m.pyramid("lanRoof", size=(2.4, 2.4, 1.0), at=(2.8, 0, 11.4), role="irond")
    m.box("lan", size=(1.5, 1.5, 1.9), at=(2.8, 0, 10.0), role="glow", solo=True)
    for i, (dx, dy) in enumerate(((-0.8, -0.8), (0.8, -0.8), (-0.8, 0.8), (0.8, 0.8))):
        m.beam("bar%d" % i, (2.8 + dx, dy, 9.0), (2.8 + dx, dy, 11.0), role="iron", width=0.2)
    m.box("lanBot", size=(2.0, 2.0, 0.35), at=(2.8, 0, 8.9), role="irond")
    m.prism("drop", radius=0.3, height=0.6, at=(2.8, 0, 8.4), role="iron", sides=4, taper=0.1, turn=180, rot=(180, 0, 0))
    # petite citrouille au pied
    m.box("pk", size=(1.9, 1.7, 1.4), at=(-2.2, -1.4, 1.8), role="pump", chamfer=0.5)
    m.box("pkL", size=(0.8, 1.5, 1.2), at=(-3.1, -1.4, 1.8), role="pumpd", chamfer=0.35)
    m.box("pkR", size=(0.8, 1.5, 1.2), at=(-1.3, -1.4, 1.8), role="pumpd", chamfer=0.35)
    m.box("pkStem", size=(0.35, 0.35, 0.6), at=(-2.2, -1.4, 2.7), role="stem", rot=(0, 15, 0))
    m.build()
    return m


@model
def Pumpkin():
    # grosse citrouille souriante dont le visage brille, feuille et vrille, bougie
    m = M("Pumpkin")
    m.palette(pump=plain("#B8642A", streaks=("#9E5220", 0.25, "v"), top=0.18), pumpd=plain("#8E4A1E"), pumpl=plain("#D08238"),
              stem=plain("#4A7A3E"), leaf=plain("#3E8A4A", top=0.2), stone=plain("#5A6480", tiles=(4, 0.16)), wax=plain("#D8D0BC"), glow=glow("#4FF0D8"),
              inside="#3A2414")
    m.prism("base", radius=5.0, height=1.0, at=(0, 0, 0.5), role="stone", sides=9, taper=0.88)
    m.box("mid", size=(5.4, 5.6, 5.4), at=(0, 0, 3.9), role="pump", chamfer=1.5)
    for i, x in enumerate((-2.9, 2.9)):
        m.box("lobe%d" % i, size=(2.6, 5.0, 4.8), at=(x, 0, 3.8), role="pumpd", chamfer=1.1)
    for i, x in enumerate((-1.5, 1.5)):
        m.box("rib%d" % i, size=(1.6, 5.9, 5.0), at=(x, 0, 3.9), role="pumpl", chamfer=0.6)
    m.box("stem", size=(0.9, 0.9, 1.5), at=(0.1, 0, 7.2), role="stem", taper=0.7, shear=(0.4, 0))
    m.box("leaf", size=(2.2, 1.4, 0.25), at=(1.4, -0.6, 6.9), role="leaf", taper=(0.3, 1), axis="x", rot=(0, -15, -20))
    chain(m, "vine", [(-0.3, 0, 6.8), (-1.6, -0.6, 7.6), (-2.6, -0.4, 7.0), (-3.2, -0.8, 7.8)], "stem", 0.28, taper=0.8)
    # visage creusé qui brille : yeux en triangle, sourire à dents
    m.prism("eyeL", radius=0.85, height=0.5, at=(-1.3, -2.85, 4.9), role="glow", sides=3, rot=(90, 0, 0), solo=True)
    m.prism("eyeR", radius=0.85, height=0.5, at=(1.3, -2.85, 4.9), role="glow", sides=3, rot=(90, 0, 0), solo=True)
    m.prism("nose", radius=0.4, height=0.5, at=(0, -2.9, 3.9), role="glow", sides=3, rot=(90, 0, 0), solo=True)
    m.box("mouth", size=(3.4, 0.5, 0.8), at=(0, -2.85, 2.8), role="glow", solo=True)
    m.box("mouthL", size=(0.8, 0.5, 0.7), at=(-1.9, -2.8, 3.25), role="glow", rot=(0, 30, 0), solo=True)
    m.box("mouthR", size=(0.8, 0.5, 0.7), at=(1.9, -2.8, 3.25), role="glow", rot=(0, -30, 0), solo=True)
    m.box("toothA", size=(0.6, 0.6, 0.45), at=(-0.6, -2.95, 3.05), role="pump")
    m.box("toothB", size=(0.6, 0.6, 0.45), at=(0.8, -2.95, 2.55), role="pump")
    # bougie
    m.prism("candle", radius=0.5, height=1.6, at=(3.6, -2.6, 1.8), role="wax", sides=7)
    m.crystal("flame", radius=0.3, height=0.9, at=(3.6, -2.6, 2.6), role="glow", sides=5, tip=0.6, solo=True)
    m.build()
    return m


@model
def Ghost():
    # petit fantôme mignon qui tient une bougie, drap à pointes, sur une pierre gravée
    m = M("Ghost")
    m.palette(sheet=plain("#CFDCE4", shade=0.16, top=0.1), sheetd=plain("#A8BCCA"), sheetl=plain("#E4EEF2"), eye="#1E2238", cheekp=plain("#D890A8"),
              stone=plain("#5A6480", tiles=(4, 0.16), mottle=("#485068", 0.2, 4)), stoned=plain("#485068"), wax=plain("#D8D0BC"), glow=glow("#4FF0D8"),
              carve="#343A54")
    m.box("slab", size=(6.4, 5.0, 1.2), at=(0, 0, 0.6), role="stone", chamfer=0.25)
    m.box("stoneB", size=(4.2, 1.2, 4.6), at=(0, 2.2, 3.4), role="stoned", chamfer=0.5, taper=(0.86, 1))
    m.prism("skirt", radius=2.9, height=2.6, at=(0, -0.4, 4.0), role="sheetd", sides=8, taper=0.86)
    for i in range(8):
        a = i / 8 * math.tau + 0.2
        m.prism("frill%d" % i, radius=0.75, height=1.3, at=(math.cos(a) * 2.5, -0.4 + math.sin(a) * 2.5, 2.2), role="sheetd" if i % 2 else "sheet", sides=4,
                taper=0.1, rot=(180, 0, 0))
    m.prism("body", radius=2.5, height=2.6, at=(0, -0.4, 6.6), role="sheet", sides=8, taper=0.9)
    m.prism("head", radius=2.25, height=1.6, at=(0, -0.4, 8.7), role="sheetl", sides=8, taper=0.6)
    m.box("armL", size=(1.6, 1.0, 1.0), at=(-2.8, -1.2, 6.4), role="sheet", chamfer=0.3, rot=(0, 25, 20))
    m.box("armR", size=(1.6, 1.0, 1.0), at=(2.6, -1.6, 6.0), role="sheet", chamfer=0.3, rot=(0, -10, -30))
    m.prism("candle", radius=0.35, height=1.5, at=(3.3, -2.3, 6.6), role="wax", sides=6)
    m.crystal("flame", radius=0.3, height=0.9, at=(3.3, -2.3, 7.35), role="glow", sides=5, tip=0.6, solo=True)
    # yeux et bouche : pièces sombres sur l'avant (les faces d'un prisme ne regardent pas toujours droit devant)
    m.box("eyeL", size=(0.7, 0.3, 0.9), at=(-0.9, -2.75, 7.3), role="eye")
    m.box("eyeR", size=(0.7, 0.3, 0.9), at=(0.9, -2.75, 7.3), role="eye")
    m.box("mouth", size=(0.6, 0.3, 0.5), at=(0, -2.8, 6.5), role="eye")
    m.box("cheekL", size=(0.5, 0.25, 0.35), at=(-1.6, -2.55, 6.7), role="cheekp")
    m.box("cheekR", size=(0.5, 0.25, 0.35), at=(1.6, -2.55, 6.7), role="cheekp")
    m.build()
    m.stamp("stoneB", "front", (0, 0.6), ["#.#", "###", "#.#"], {"#": "carve"}, cell=0.35)
    return m
