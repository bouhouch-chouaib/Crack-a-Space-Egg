# Pumpkin Kitty (R14_T3, Rare) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R14_Refs/Ref_R14_T3_*.png)
# Petit chat noir doux assis DANS une citrouille sculptee : citrouille en cinq etages a 12 pans qui s'arrondissent
# (sillons orange sombre, reflets clairs), ouverture sombre en haut d'ou sortent le poitrail, la tete et les pattes
# avant posees sur le bord (coussinets roses) ; visage de citrouille sculpte et gentil : yeux triangulaires et grand
# sourire en trois pans, creux brun sombre et lueur de bougie (Neon) ; tete de chat ronde, grands yeux turquoise
# (contour, iris, pupille, deux reflets), museau gris, nez rose, bouche en « w », joues, moustaches ; oreilles
# pointues a l'interieur rose ; couvercle de citrouille pose en chapeau sur la tete avec tige verte et feuille ;
# queue noire qui sort a l'arriere et remonte ; vrille verte et feuille qui retombent du bord.
# compare() final : face 0.85, dos 0.85, gauche 0.81, dessus 0.94 (51 pieces, 1 052 triangles, 3,32 x 3,36 x 3,54).
# check_model : 0 piece flottante ou cachee, 0 arete ouverte ; les etages de la citrouille se recouvrent de 0,03
# (sinon rig_join soude leurs sommets communs et laisse des aretes non manifold).
# --- suite : make_t3(), exec(rigjoin.py), rig_join("R14_T3", GROUPS_T3), save R14_T3_rig.blend, import ->
# Work_R14_T3, CreatureRig.Install(workspace.Work_R14_T3, "R14_T3", nil, true), puis joints corriges dans le repere
# du Core (x = -x Blender, y = z Blender + 0.015, z = y Blender + 0.02) : ArmL/ArmR (+-0.46, 1.88, -0.6) (arriere
# des pattes, sur le bord), Head (0, 2.1, -0.1) (cou), EarL/EarR (+-0.45, 2.98, -0.03) (base), Tail (-0.25, 1.86,
# 0.55) (sortie de la citrouille). Visage sculpte lumineux : Body2 (Neon).
# Portrait : rbxassetid://90219882408102 (Renders/Creatures/R14_T3.png).
# Ce fichier est autonome (le Blender de Ropilot est partage : ne pas compter sur des variables globales).
import ropilot, bpy, os, math, mathutils
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R14_Refs")
REF_B3 = {v: os.path.join(R, f"Ref_R14_T3_{v}.png") for v in ("front", "left", "back", "top")}
PAL_B3 = dict(
    pump=dict(color="#F2862E", noise=0.03, shade=0.16, top=0.1, streaks=("#e67a24", 0.3, "v")),
    pump_dark=dict(color="#B8561C", noise=0.03, shade=0.1),
    pump_light=dict(color="#FFA858", noise=0.02, shade=0.08),
    inside=dict(color="#4a2a14", noise=0.03, shade=0.05),
    fur=dict(color="#2E2B3A", noise=0.03, shade=0.1, top=0.12, streaks=("#36324a", 0.3, "v")),
    fur_light=dict(color="#4A4660", noise=0.03, shade=0.08),
    stem=dict(color="#5E8A3A", noise=0.03, shade=0.12, streaks=("#4f7a30", 0.3, "v"), top=0.1),
    stem_dark=dict(color="#3f6326", noise=0.03),
    iris=dict(color="#3FD9C6", noise=0.01, shade=0.03),
    eye="#15141c", white="#ffffff", pink="#F4A6B8", nose="#F28FA6", blush="#E07A9A", mouth="#8E8AA6",
    glow=dict(color="#FFB13B", glow=True),
)
HZ3, HY3 = 2.55, -0.15          # centre de la tete du chat
# etages de la citrouille : nom, rayon, hauteur, centre z, taper (recouvrement de 0,03 entre etages)
PUMP_B3 = [("PumpLow", 1.32, 0.33, 0.15, 1.55 / 1.32), ("PumpMid0", 1.55, 0.35, 0.46, 1.66 / 1.55), ("PumpMid", 1.66, 0.55, 0.88, 1.0),
           ("PumpMid1", 1.66, 0.33, 1.29, 1.5 / 1.66), ("PumpTop", 1.5, 0.31, 1.58, 1.16 / 1.5)]
D3 = 1.66 * math.cos(math.radians(15))   # apotheme du ventre de la citrouille


def ext3(a, b, e=0.05):
    a, b = mathutils.Vector(a), mathutils.Vector(b)
    d = (b - a).normalized() * e
    return tuple(a - d), tuple(b + d)


def on_pump(phi, t, z, out=0.0):
    # point sur la face du ventre de normale phi (degres, 270 = avant), decale de t le long de la face
    n = mathutils.Vector((math.cos(math.radians(phi)), math.sin(math.radians(phi)), 0))
    tg = mathutils.Vector((-n.y, n.x, 0))
    p = n * (D3 + out) + tg * t
    return (p.x, p.y, z)


def build_b3(m):
    MR = dict(mirror=True)
    for n, r, h, z, tp in PUMP_B3:
        kw = {}
        if n == "PumpLow":
            kw["faces"] = {"bottom": "pump_dark"}
        if n == "PumpTop":
            kw["faces"] = {"top": "inside"}
        m.prism(n, radius=r, height=h, at=(0, 0, z), role="pump", sides=12, turn=15, taper=tp, **kw)
    m.box("Chest", size=(1.2, 0.95, 0.75), at=(0, HY3 + 0.05, 1.95), role="fur", chamfer=0.3, taper=(0.9, 0.9))
    m.box("Head", size=(1.62, 1.22, 1.12), at=(0, HY3, HZ3), role="fur", chamfer=0.4, taper=(0.86, 0.9))
    m.prism("Ear_L", radius=0.34, height=0.5, at=(-0.5, HY3 + 0.1, HZ3 + 0.68), role="fur", sides=4, turn=45, taper=0.0, rot=(0, -16, 0), **MR)
    m.box("Paw_L", size=(0.38, 0.62, 0.3), at=(-0.46, HY3 - 0.72, 1.86), role="fur", chamfer=0.11, **MR)
    pts = [(0.25, 0.55, 1.85), (0.55, 1.0, 2.05), (0.75, 1.15, 2.45), (0.72, 1.0, 2.8), (0.55, 0.85, 2.92)]
    w = [0.28, 0.26, 0.24, 0.22]
    for i in range(len(pts) - 1):
        a, b = ext3(pts[i], pts[i + 1], 0.05 if i else 0.0)
        m.beam(f"Tail{i}", start=a, end=b, role="fur", width=w[i], depth=w[i], solo=True)
    # couvercle de citrouille en chapeau, tige verte
    m.prism("Lid", radius=0.46, height=0.2, at=(0.18, HY3 + 0.1, HZ3 + 0.65), role="pump", sides=12, turn=15, taper=0.8, rot=(0, 10, 0), solo=True)
    m.beam("Stem", start=(0.2, HY3 + 0.1, HZ3 + 0.72), end=(0.3, HY3 + 0.14, HZ3 + 0.95), role="stem", width=0.17, depth=0.17, taper=0.8, solo=True)
    return m


def details_b3(m):
    MR = dict(mirror=True)
    # visage sculpte : creux sombre + lueur de bougie ; yeux triangulaires, sourire en trois pans
    for nm, phi, t in (("L", 240, 0.08), ("R", 300, -0.08)):
        m.prism(f"CarveEye_{nm}", radius=0.3, height=0.06, at=on_pump(phi, t, 1.2, 0.02), role="inside", sides=3, turn=0, rot=(90, 0, phi - 270), solo=True)
        m.prism(f"GlowEye_{nm}", radius=0.21, height=0.06, at=on_pump(phi, t, 1.18, 0.05), role="glow", sides=3, turn=0, rot=(90, 0, phi - 270), solo=True)
    m.box("CarveMouth", size=(0.8, 0.06, 0.3), at=on_pump(270, 0, 0.66, 0.02), role="inside", solo=True)
    m.box("GlowMouth", size=(0.72, 0.06, 0.2), at=on_pump(270, 0, 0.66, 0.05), role="glow", solo=True)
    for nm, phi, t, tl in (("L", 240, 0.24, -26), ("R", 300, -0.24, 26)):
        m.box(f"CarveSmile_{nm}", size=(0.52, 0.06, 0.28), at=on_pump(phi, t, 0.76, 0.02), role="inside", rot=(0, tl, phi - 270), solo=True)
        m.box(f"GlowSmile_{nm}", size=(0.44, 0.06, 0.18), at=on_pump(phi, t, 0.76, 0.05), role="glow", rot=(0, tl, phi - 270), solo=True)
    # yeux du chat : contour sombre, iris turquoise, pupille, deux reflets
    fy, ez = HY3 - 0.61, HZ3 + 0.06
    m.box("Eye_L", size=(0.4, 0.1, 0.46), at=(-0.35, fy, ez), role="eye", chamfer=0.08, **MR)
    m.box("Iris_L", size=(0.32, 0.06, 0.38), at=(-0.35, fy - 0.04, ez - 0.01), role="iris", chamfer=0.06, **MR)
    m.box("Pupil_L", size=(0.13, 0.04, 0.26), at=(-0.34, fy - 0.07, ez - 0.02), role="eye", **MR)
    m.box("Shine_L", size=(0.12, 0.04, 0.12), at=(-0.41, fy - 0.09, ez + 0.1), role="white", **MR)
    m.box("Shine2_L", size=(0.06, 0.04, 0.06), at=(-0.27, fy - 0.09, ez - 0.12), role="white", **MR)
    # museau gris, nez rose, moustaches, interieur des oreilles
    m.box("Muzzle", size=(0.56, 0.22, 0.3), at=(0, fy - 0.06, HZ3 - 0.28), role="fur_light", chamfer=0.1)
    m.box("Nose", size=(0.16, 0.08, 0.1), at=(0, fy - 0.18, HZ3 - 0.18), role="nose", taper=(0.5, 1), rot=(180, 0, 0))
    for i, (dz, ang) in enumerate(((0.04, 8), (-0.06, -8))):
        m.beam(f"Whisker{i}_L", start=(-0.2, fy - 0.12, HZ3 - 0.25 + dz), end=(-0.95, fy - 0.12, HZ3 - 0.25 + dz + math.sin(math.radians(ang)) * 0.6),
               role="mouth", width=0.04, depth=0.04, **MR)
    m.prism("EarIn_L", radius=0.22, height=0.34, at=(-0.5, HY3 + 0.02, HZ3 + 0.62), role="pink", sides=4, turn=45, taper=0.0, rot=(0, -16, 0), **MR)
    # feuille sur le couvercle ; vrille verte qui retombe du bord, a l'arriere gauche
    m.box("Leaf", size=(0.34, 0.2, 0.05), at=(0.0, HY3 + 0.05, HZ3 + 0.78), role="stem", rot=(0, -25, 30), solo=True)
    vp = [(-1.0, 0.75, 1.72), (-1.26, 0.88, 1.5), (-1.47, 0.83, 1.2), (-1.46, 0.62, 1.0), (-1.32, 0.55, 1.12)]
    for i in range(len(vp) - 1):
        a, b = ext3(vp[i], vp[i + 1], 0.04 if i else 0.0)
        m.beam(f"Vine{i}", start=a, end=b, role="stem", width=0.12, depth=0.12, solo=True)
    m.box("VineLeaf", size=(0.36, 0.05, 0.26), at=(-1.31, 0.96, 1.5), role="stem", rot=(0, 20, 35), solo=True)
    return m


def paint_b3(m):
    for part in [p[0] for p in PUMP_B3]:
        for k in range(12):
            m.line(part, f"side{k}", [(-0.42, -0.6), (-0.42, 0.6)], "pump_dark", 1)
            m.line(part, f"side{k}", [(0.05, -0.45), (0.05, 0.45)], "pump_light", 1)
    m.circle("PumpTop", "top", (0, 0), 0.95, "inside")
    m.rect("Head", "front", (-0.48, -0.2), (0.12, 0.06), "blush")
    m.rect("Head", "front", (0.48, -0.2), (0.12, 0.06), "blush")
    m.stamp("Muzzle", "front", (0, -0.07), ["K..K..K", ".KK.KK."], {"K": "#15141c"}, cell=0.04)
    m.stamp("Paw_L", "front", (0, 0), ["P.P"], {"P": "pink"})
    m.stamp("Paw_R", "front", (0, 0), ["P.P"], {"P": "pink"})
    m.rect("Chest", "front", (0, -0.05), (0.4, 0.3), "fur_light")
    for k in range(12):
        m.line("Lid", f"side{k}", [(-0.18, -0.2), (-0.18, 0.2)], "pump_dark", 1)
    return m


GROUPS_T3 = {'Head': ['Head', 'Muzzle', 'Nose', 'Eye_*', 'Iris_*', 'Pupil_*', 'Shine*', 'Whisker*', 'Lid', 'Stem', 'Leaf'],
             'EarL': ['Ear_L', 'EarIn_L'], 'EarR': ['Ear_R', 'EarIn_R'],
             'ArmL': ['Paw_L'], 'ArmR': ['Paw_R'],
             'Tail': ['Tail*']}


def save_col_b3(col, fname):
    p = os.path.join(ropilot.FILES_DIR, fname)
    bpy.data.libraries.write(p, {bpy.data.collections[col]}, fake_user=True)
    return p


def make_t3(save=True):
    m = ropilot.model("R14_T3", px=8, reset=True)
    m.reference(REF_B3); m.palette(**PAL_B3)
    build_b3(m); details_b3(m); paint_b3(m)
    print(m.build()); print(m.check()); print(m.compare(image=False)["report"])
    if save:
        save_col_b3("R14_T3", "R14_T3.blend")
    return m
