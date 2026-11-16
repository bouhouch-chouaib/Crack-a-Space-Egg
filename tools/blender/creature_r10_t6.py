# Mecha Raptor (R10_T6, Mythic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R10_Refs/Ref_R10_T6_*.png)
# Velociraptor bipede en chrome et acier sombre : torse releve, coeur-rouage de laiton a centre turquoise sur
# le poitrail, cou sombre a bagues chromees, tete agrandie (K) a gueule grande ouverte (rig Jaw) bordee de dents,
# crete de laiton, yeux turquoise sur les cotes du crane (iris, pupille fendue, reflet) sous une arcade sombre,
# epaulieres a pointe de laiton, petits bras griffus (rig ArmL / ArmR, coude lumineux), jambes digitigrades
# (rig LegL / LegR) : cuisse chromee a rouage et moyeu lumineux, genou et cheville lumineux, tibia sombre a piston
# chrome, griffes et grande griffe-faucille de laiton relevee ; longue queue raide qui s'affine (rig Tail) a
# bagues sombres ; epines dorsales de laiton du cou au bout de la queue.
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R10_Refs")
REF6 = {v: os.path.join(R, f"Ref_R10_T6_{v}.png") for v in ("front", "left", "back", "top")}
PAL6 = dict(
    chrome=dict(color="#c9d4de", noise=0.025, shade=0.16, mottle=("#bccad6", 0.2, 4), top=0.12, rim=-0.15),
    chrome_light=dict(color="#e6edf3", noise=0.02, shade=0.1, top=0.1),
    steel=dict(color="#7c8c9c", noise=0.03, shade=0.14, top=0.12),
    steel_dark=dict(color="#3e4a58", noise=0.03, shade=0.12, top=0.08),
    brass=dict(color="#e0a84a", noise=0.03, shade=0.14, top=0.14, rim=-0.22),
    brass_light=dict(color="#f5cf7a", noise=0.03, shade=0.1, top=0.12),
    brass_dark=dict(color="#b8822e", noise=0.03, shade=0.1),
    mouth="#1a1424", tooth=dict(color="#f4f8fb", noise=0.01), eye="#16202c", shine="#ffffff",
    glow=dict(color="#5ae6d2", glow=True),
)
TAIL6 = [(0, 1.6, 5.45), (0, 3.0, 5.6), (0, 4.4, 5.7), (0, 5.6, 5.72), (0, 6.6, 5.65)]
TW6 = [1.6, 1.2, 0.85, 0.5, 0.12]
K6, HC6, HDZ6 = 1.15, (0.0, -2.45, 8.0), -0.3    # tete agrandie autour du haut du cou, un peu abaissee


def mid(a, b, t=0.5):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def HP(x, y, z):
    return (HC6[0] + (x - HC6[0]) * K6, HC6[1] + (y - HC6[1]) * K6, HC6[2] + (z - HC6[2]) * K6 + HDZ6)


def HS(*v):
    return tuple(c * K6 for c in v)


def build_t6(m):
    MR = dict(mirror=True)
    # ---- corps : torse releve, hanches, poitrail ; ventre en plaques sombres ; coeur-rouage lumineux
    m.box("Torso", size=(2.8, 3.6, 2.6), at=(0, -0.1, 5.45), role="chrome", chamfer=0.55, rot=(-18, 0, 0), faces={"bottom": "steel_dark"})
    m.box("Hips", size=(3.0, 1.9, 2.3), at=(0, 1.15, 5.3), role="chrome", chamfer=0.5, faces={"bottom": "steel_dark"})
    m.box("Chest", size=(2.5, 1.6, 2.4), at=(0, -1.7, 6.15), role="chrome", chamfer=0.5, rot=(-25, 0, 0), faces={"bottom": "steel_dark"})
    m.box("Belly", size=(1.9, 3.0, 0.3), at=(0, -0.3, 4.2), role="steel_dark", chamfer=0.08, rot=(-18, 0, 0))
    m.box("Spine", size=(0.5, 3.6, 0.2), at=(0, 0.2, 6.75), role="steel_dark", chamfer=0.05, rot=(-14, 0, 0))
    m.prism("CoreGear", radius=0.6, height=0.16, at=(0, -2.68, 6.06), role="brass", sides=8, rot=(65, 0, 0), turn=22.5)
    m.prism("CoreGlow", radius=0.3, height=0.1, at=(0, -2.75, 6.09), role="glow", sides=6, rot=(65, 0, 0))
    # ---- cou : acier sombre, bagues chromees
    m.beam("Neck", start=(0, -1.85, 6.4), end=(0, -2.45, 8.1), role="steel_dark", width=1.25, depth=1.3, chamfer=0.25, taper=0.9)
    for i, t in enumerate((0.35, 0.68)):
        m.beam(f"NeckRing{i}", start=mid((0, -1.85, 6.4), (0, -2.45, 8.1), t), end=mid((0, -1.85, 6.4), (0, -2.45, 8.1), t + 0.12),
               role="chrome_light", width=1.36 - 0.08 * i, depth=1.4 - 0.08 * i, chamfer=0.2)
    # ---- tete (agrandie K6) : crane chrome, museau, gueule ouverte dentee, machoire (rig Jaw) ouverte sur sa charniere
    m.box("Skull", size=HS(1.9, 1.9, 1.75), at=HP(0, -2.95, 8.68), role="chrome", chamfer=0.25)
    m.box("Snout", size=HS(1.55, 1.9, 0.85), at=HP(0, -4.55, 8.4), role="chrome", chamfer=0.22, axis="y", taper=(0.78, 0.8))
    m.box("SnoutPlate", size=HS(0.9, 1.1, 0.12), at=HP(0, -4.95, 8.84), role="steel_dark", chamfer=0.04, axis="y", taper=(0.7, 1))
    m.box("Mouth", size=HS(1.0, 2.1, 0.75), at=HP(0, -4.05, 7.8), role="mouth", axis="y", taper=(0.78, 1), rot=(9, 0, 0))
    hinge = HP(0, -2.85, 7.84)   # charniere au fond de la gueule : « at » = position du pivot
    m.box("Jaw", size=HS(1.4, 2.5, 0.45), at=hinge, role="steel_dark", chamfer=0.12, axis="y", taper=(0.78, 0.9), rot=(18, 0, 0),
          pivot=HS(0, 1.25, 0.22), faces={"top": "mouth"})
    m.box("ChinPlate", size=HS(1.1, 1.8, 0.14), at=hinge, role="chrome", chamfer=0.03, axis="y", taper=(0.75, 1), rot=(18, 0, 0), pivot=HS(0, 1.1, 0.5))
    for k, y in enumerate((-5.15, -4.65, -4.15, -3.7)):
        m.prism(f"Tooth{k}_L", radius=0.11 * K6, height=0.32 * K6, at=HP(-(0.46 + 0.03 * k), y, 8.01 if k == 0 else 7.98), role="tooth", sides=3,
                taper=0, rot=(180, 0, 0), **MR)
    for k, (y, z) in enumerate(((-4.75, 7.33), (-4.23, 7.5), (-3.71, 7.67))):
        m.prism(f"LowTooth{k}_L", radius=0.1 * K6, height=0.28 * K6, at=HP(-(0.44 + 0.03 * k), y, z), role="tooth", sides=3, taper=0,
                rot=(18, 0, 0), **MR)
    for k, (y, h) in enumerate(((-3.55, 0.24), (-2.95, 0.32), (-2.35, 0.28))):
        m.box(f"Crest{k}", size=HS(0.16, 0.55, h), at=HP(0, y, 9.55 + h / 2 - 0.05), role="brass", taper=(1, 0.4), shear=(0, 0.2))
    # yeux turquoise sur l'avant du crane, au-dessus du museau, un peu tournes vers l'exterieur : orbite, iris,
    # pupille fendue, reflet ; arcade sombre presque droite (regard feroce sans etre mechant)
    m.box("Eye_L", size=HS(0.62, 0.12, 0.52), at=HP(-0.52, -3.9, 9.18), role="eye", chamfer=0.04, rot=(0, 0, -18), **MR)
    m.box("Iris_L", size=HS(0.42, 0.1, 0.38), at=HP(-0.51, -3.95, 9.15), role="glow", rot=(0, 0, -18), **MR)
    m.box("Pupil_L", size=HS(0.12, 0.08, 0.3), at=HP(-0.47, -3.99, 9.14), role="eye", rot=(0, 0, -18), **MR)
    m.box("Shine_L", size=HS(0.11, 0.06, 0.11), at=HP(-0.62, -3.995, 9.28), role="shine", rot=(0, 0, -18), **MR)
    m.beam("Brow_L", start=HP(-0.92, -3.86, 9.52), end=HP(-0.2, -3.95, 9.44), role="steel_dark", width=0.22 * K6, depth=0.2 * K6, chamfer=0.04, **MR)
    # ---- epaulieres a pointe de laiton ; petits bras griffus (rig ArmL / ArmR), coude lumineux
    m.box("Shoulder_L", size=(0.9, 1.3, 1.1), at=(-1.3, -1.7, 6.1), role="steel", chamfer=0.25, **MR)
    m.prism("ShoulderSpike_L", radius=0.2, height=0.75, at=(-1.95, -1.7, 6.3), role="brass", sides=4, taper=0, rot=(0, -80, 0), **MR)
    m.beam("UpperArm_L", start=(-1.35, -1.95, 5.8), end=(-1.6, -2.45, 4.65), role="steel_dark", width=0.5, depth=0.5, chamfer=0.08, **MR)
    m.prism("ElbowHub_L", radius=0.24, height=0.56, at=(-1.6, -2.45, 4.67), role="glow", sides=6, rot=(0, 90, 0), **MR)
    m.beam("Forearm_L", start=(-1.6, -2.45, 4.7), end=(-1.48, -3.25, 4.5), role="chrome", width=0.42, depth=0.42, chamfer=0.06, **MR)
    m.box("Hand_L", size=(0.5, 0.42, 0.42), at=(-1.48, -3.38, 4.48), role="steel_dark", chamfer=0.06, **MR)
    for k, dx in enumerate((-0.15, 0.15)):
        m.prism(f"HandClaw{k}_L", radius=0.08, height=0.4, at=(-1.48 + dx, -3.62, 4.3), role="brass", sides=3, taper=0, rot=(150, 0, 0), **MR)
    # ---- jambes (rig LegL / LegR)
    m.box("Thigh_L", size=(1.35, 2.1, 2.5), at=(-1.66, 0.45, 4.2), role="chrome", chamfer=0.4, rot=(18, 0, 0), **MR)
    m.prism("HipGear_L", radius=0.62, height=0.18, at=(-2.38, 0.4, 4.5), role="brass", sides=8, rot=(0, 90, 0), turn=22.5, **MR)
    m.prism("HipHub_L", radius=0.24, height=0.12, at=(-2.49, 0.4, 4.5), role="glow", sides=6, rot=(0, 90, 0), **MR)
    m.prism("Knee_L", radius=0.42, height=0.95, at=(-1.66, -0.35, 3.3), role="glow", sides=6, rot=(0, 90, 0), **MR)
    m.beam("Shin_L", start=(-1.66, -0.35, 3.3), end=(-1.66, 1.05, 1.3), role="steel_dark", width=0.8, depth=0.8, chamfer=0.12, **MR)
    m.beam("Piston_L", start=(-2.11, -0.05, 2.95), end=(-2.11, 0.85, 1.65), role="chrome_light", width=0.16, depth=0.16, **MR)
    m.prism("Ankle_L", radius=0.34, height=0.78, at=(-1.66, 1.05, 1.32), role="glow", sides=6, rot=(0, 90, 0), **MR)
    m.beam("Meta_L", start=(-1.66, 1.05, 1.35), end=(-1.66, 0.55, 0.3), role="chrome", width=0.58, depth=0.58, chamfer=0.08, **MR)
    m.box("Foot_L", size=(1.1, 1.8, 0.45), at=(-1.66, -0.15, 0.22), role="steel_dark", chamfer=0.1, **MR)
    for k, dx in enumerate((-0.25, 0.25)):
        m.prism(f"Toe{k}_L", radius=0.13, height=0.42, at=(-1.66 + dx, -1.15, 0.18), role="brass", sides=4, taper=0, rot=(90, 0, 0), **MR)
    m.beam("Sickle_L", start=(-1.32, -0.55, 0.35), end=(-1.32, -0.95, 1.0), role="brass", width=0.18, depth=0.3, **MR)
    m.beam("SickleTip_L", start=(-1.32, -0.92, 0.95), end=(-1.32, -1.35, 0.72), role="brass_light", width=0.16, depth=0.24, taper=0.2, **MR)
    # ---- longue queue raide qui s'affine (rig Tail), bagues sombres
    for i in range(4):
        a, b = TAIL6[i], TAIL6[i + 1]
        e = 0.08 if i < 3 else 0
        a2 = tuple(a[k] - (b[k] - a[k]) * 0.05 for k in range(3))
        b2 = tuple(b[k] + (b[k] - a[k]) * e for k in range(3))
        m.beam(f"Tail{i}", start=a2, end=b2, role="chrome", width=TW6[i], depth=TW6[i] * 0.9, taper=TW6[i + 1] / TW6[i], chamfer=0.25 if i < 2 else 0.12)
    for i in (1, 2, 3):
        a, b = TAIL6[i], TAIL6[i + 1]
        m.beam(f"TailBand{i}", start=a, end=mid(a, b, 0.1), role="steel_dark", width=TW6[i] * 1.08, depth=TW6[i] * 0.98, chamfer=0.1)
    # ---- epines dorsales de laiton : cou et dos (corps), bout de queue (Spike5-7 dans le rig Tail)
    SP = [((0, -1.76, 7.95), 0.7, 60), ((0, -1.56, 7.45), 0.7, 60), ((0, -0.9, 7.15), 0.75, 55), ((0, 0.4, 6.85), 0.7, 62),
          ((0, 1.7, 6.55), 0.62, 70), ((0, 3.0, 6.35), 0.52, 75), ((0, 4.4, 6.17), 0.42, 80), ((0, 5.6, 5.98), 0.32, 82)]
    for i, (p, h, tilt) in enumerate(SP):
        m.prism(f"Spike{i}", radius=0.22 if h > 0.5 else 0.17, height=h, at=p, role="brass" if i % 2 == 0 else "brass_light", sides=4, taper=0,
                rot=(-tilt, 0, 0))
    # ---- peinture
    for n in ("Torso", "Hips"):
        for (u, v) in ((-0.9, 0.7), (0.9, 0.7), (-0.9, -0.7), (0.9, -0.7)):
            m.rect(n, "left", (u, v), (0.12, 0.12), "steel")
        m.line(n, "left", [(0.0, 0.9), (0.0, -0.9)], "steel", 1)
    for v in (0.9, 0.0, -0.9):
        m.line("Belly", "bottom", [(-0.8, v), (0.8, v)], "chrome", 1)
    m.stamp("Snout", "top", (0, -0.65), ["K....K", "K....K"], {"K": "steel_dark"})   # narines sur le dessus du museau
    m.line("Thigh_L", "left", [(-0.8, 0.0), (0.8, 0.0)], "steel", 1)
    m.rect("Skull", "top", (0, -0.6), (0.12, 0.12), "steel_dark")
    return m


m6 = ropilot.model("R10_T6", px=8, reset=True)
m6.reference(REF6)
m6.palette(**PAL6)
build_t6(m6)
print(m6.build()); print(m6.check()); print(m6.compare()["report"])
ropilot.check_model(collection="R10_T6", max_lines=8)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R10_T6.blend"), copy=True)


def side6(s):
    return ['Thigh_' + s, 'HipGear_' + s, 'HipHub_' + s, 'Knee_' + s, 'Shin_' + s, 'Piston_' + s, 'Ankle_' + s, 'Meta_' + s, 'Foot_' + s,
            'Toe*_' + s, 'Sickle_' + s, 'SickleTip_' + s]


GROUPS_T6 = {'Head': ['Skull', 'Snout', 'SnoutPlate', 'Mouth', 'Tooth*_*', 'Crest*', 'Eye_*', 'Iris_*', 'Pupil_*', 'Shine_*', 'Brow_*'],
             'Jaw': ['Jaw', 'ChinPlate', 'LowTooth*_*'],
             'ArmL': ['UpperArm_L', 'ElbowHub_L', 'Forearm_L', 'Hand_L', 'HandClaw*_L'],
             'ArmR': ['UpperArm_R', 'ElbowHub_R', 'Forearm_R', 'Hand_R', 'HandClaw*_R'],
             'LegL': side6('L'), 'LegR': side6('R'),
             'Tail': ['Tail[0-9]', 'TailBand*', 'Spike5', 'Spike6', 'Spike7']}
# --- suite : exec(rigjoin.py), rig_join("R10_T6", GROUPS_T6), save R10_T6_rig.blend, import -> Work_R10_T6,
# CreatureRig.Install(workspace.Work_R10_T6, "R10_T6", nil, true), puis joints corriges dans le repere du Core :
# Head (0, 7.9, -2.75) en haut du cou, Jaw (0, 7.52, -3.23) a la charniere, ArmL/R (+-1.35, 5.8, -2.27) a l'epaule,
# LegL/R (+-1.66, 5.0, 0.25) a la hanche, Tail (0, 5.5, 1.3) a la racine
# compare() final : face 0.78, dos 0.78, gauche 0.66, dessus 0.77 : la reference est un raptor dresse a cou long et bras pendants ;
# ici corps plus horizontal, longue queue raide, tete agrandie a gueule ouverte (lisibilite du raptor gardee au-dessus du score)
