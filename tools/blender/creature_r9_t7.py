# Tempest Dragon (R9_T7, Cosmic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R9_Refs/Ref_R9_T7_*.png)
# Dragon d'orage debout : ventre a plaques jaunes, bras griffus (rig ArmL / ArmR, leves pendant le rugissement),
# grandes ailes (rig WingL / WingR) dont la membrane violette est zebree d'eclairs jaunes a coeur lumineux,
# tete a machoire ouverte (rig Jaw) avec gorge de plasma, cornes en eclairs qui montent dans une couronne
# de nuages d'orage (suit la tete), crete de cristaux le long du dos, longue queue terminee par une lame-eclair.
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R9_Refs")
REF7 = {v: os.path.join(R, f"Ref_R9_T7_{v}.png") for v in ("front", "left", "back", "top")}
PAL7 = dict(
    scale=dict(color="#6e5ac8", noise=0.035, shade=0.16, mottle=("#6450bc", 0.22, 4), top=0.12),
    scale_dark=dict(color="#4a3a9e", noise=0.03, shade=0.12),
    scale_light=dict(color="#9e86ff", noise=0.03, shade=0.1, top=0.1),
    navy=dict(color="#2a1e5a", noise=0.03, shade=0.1),
    belly=dict(color="#f5d76e", noise=0.025, shade=0.12, top=0.1, rim=-0.15),
    belly_dark=dict(color="#d9b440", noise=0.02),
    membrane=dict(color="#5844b4", noise=0.04, mottle=("#6a56c4", 0.3, 6), shade=0.08),
    cloud=dict(color="#7e6ad6", noise=0.03, shade=0.2, top=0.2, mottle=("#8f7ce0", 0.25, 5)),
    cloud_dark=dict(color="#3a2c7a", noise=0.03, shade=0.14),
    cloud_light=dict(color="#b7a6ff", noise=0.025, shade=0.1, top=0.15),
    bolt=dict(color="#ffe15a", noise=0.015, shade=0.08, top=0.15, rim=-0.25),
    gold=dict(color="#ffcf3a", noise=0.03, shade=0.12, top=0.12, rim=-0.22),
    mouth="#140f33", eye="#140f33", white="#ffffff", tooth=dict(color="#fbf8ff", noise=0.01),
    glow=dict(color="#ffd21a", glow=True), glow_cyan=dict(color="#3fd8ff", glow=True),
)
K = 1.25                      # tete agrandie autour de son centre
HC = (0.0, -2.6, 10.6)
WROOT = (-1.6, 1.3, 8.3)      # racine de l'aile gauche
WRIST = (-4.6, 1.7, 12.3)
WTIPS = [(-8.0, 1.9, 12.0), (-7.9, 1.9, 9.4), (-6.3, 1.8, 7.4), (-3.4, 1.5, 6.6)]
TAIL7 = [(0, 1.5, 3.6), (0.2, 2.9, 2.3), (0.9, 3.8, 1.1), (2.0, 4.1, 0.7), (3.2, 3.7, 0.75), (4.1, 2.8, 1.2)]


HDY = 1.0                     # tete reculee au-dessus du corps (cou plus droit)


def HP(x, y, z):
    return (HC[0] + (x - HC[0]) * K, HC[1] + (y - HC[1]) * K + HDY, HC[2] + (z - HC[2]) * K)


def HS(*v):
    return tuple(c * K for c in v)


def mid(a, b, t=0.5):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def dist(a, b):
    return math.dist(a, b)


def zigzag(m, name, a, b, n, amp, role, width, depth, normal_axis=1, **kw):
    # eclair : ligne brisee de a vers b, decalee alternativement de +-amp perpendiculairement (dans le plan de l'aile)
    pts = []
    dx, dz = b[0] - a[0], b[2] - a[2]
    L = math.hypot(dx, dz)
    px, pz = -dz / L, dx / L
    for i in range(n + 1):
        t = i / n
        p = mid(a, b, t)
        off = 0 if i in (0, n) else (amp if i % 2 else -amp)
        pts.append((p[0] + px * off, p[1], p[2] + pz * off))
    for i in range(n):
        m.beam(f"{name}{i}" + ("_L" if kw.get("mirror") else ""), start=pts[i], end=pts[i + 1], role=role, width=width, depth=depth,
               taper=0.6 if i == n - 1 else 1, **kw)
    return pts


def build_t7(m):
    MR = dict(mirror=True)
    # ---- jambes (rig LegL / LegR) : cuisse, tibia, pied a griffes
    m.box("Thigh_L", size=(1.8, 2.5, 2.7), at=(-1.45, 0.7, 2.95), role="scale", chamfer=0.5, rot=(-15, 0, 0), **MR)
    m.beam("Shin_L", start=(-1.5, 1.3, 2.2), end=(-1.5, 0.7, 0.5), role="scale_dark", width=1.15, depth=1.15, chamfer=0.2, **MR)
    m.box("Foot_L", size=(1.55, 2.2, 0.6), at=(-1.5, 0.05, 0.3), role="scale_dark", chamfer=0.15, **MR)
    for k, dx in enumerate((-0.45, 0.0, 0.45)):
        m.prism(f"Toe{k}_L", radius=0.15, height=0.5, at=(-1.5 + dx, -1.08, 0.2), role="bolt", sides=4, taper=0, rot=(90, 0, 0), **MR)
    m.box("KneeCap_L", size=(1.0, 0.5, 0.9), at=(-1.5, -0.55, 3.0), role="belly", chamfer=0.15, **MR)
    # ---- torse penche en avant, ventre a plaques jaunes, poitrail large
    m.box("Torso", size=(3.6, 3.2, 4.3), at=(0, 0.45, 4.95), role="scale", chamfer=0.7, rot=(10, 0, 0))
    m.box("Belly", size=(2.5, 0.5, 4.0), at=(0, -1.12, 4.85), role="belly", chamfer=0.2, rot=(10, 0, 0))
    m.box("Chest", size=(4.2, 3.0, 2.8), at=(0, -0.3, 7.45), role="scale", chamfer=0.7)
    m.box("ChestPlate", size=(2.7, 0.45, 2.3), at=(0, -1.72, 7.25), role="belly", chamfer=0.18)
    # ---- cou
    m.beam("Neck", start=(0, -0.4, 8.0), end=(0, -0.9, 10.15), role="scale", width=2.0, depth=1.9, chamfer=0.4, taper=0.85)
    m.beam("NeckPlate", start=(0, -1.3, 8.2), end=(0, -1.75, 9.75), role="belly", width=1.3, depth=0.3, chamfer=0.08)
    # ---- tete (agrandie K) : crane, museau, machoire ouverte (rig Jaw), crocs, gorge de plasma
    m.box("Skull", size=HS(2.5, 2.4, 1.85), at=HP(0, -2.4, 10.85), role="scale", chamfer=0.45)
    m.box("Snout", size=HS(1.55, 2.0, 0.85), at=HP(0, -4.3, 10.5), role="scale", chamfer=0.22, taper=(0.82, 0.85), axis="y")
    m.box("SnoutPlate", size=HS(1.0, 1.8, 0.15), at=HP(0, -4.15, 10.97), role="navy", chamfer=0.04, taper=(0.75, 1), axis="y")
    m.box("Mouth", size=HS(1.35, 2.0, 0.47), at=HP(0, -3.9, 9.86), role="mouth", taper=(0.85, 1), axis="y")
    m.box("Throat", size=HS(0.8, 0.12, 0.3), at=HP(0, -2.95, 9.85), role="glow_cyan")
    m.box("Jaw", size=HS(1.5, 2.1, 0.45), at=HP(0, -3.85, 9.45), role="scale_dark", chamfer=0.12, taper=(0.8, 0.85), axis="y", rot=(10, 0, 0),
          faces={"top": "mouth", "bottom": "belly"})
    for k, y in enumerate((-5.0, -4.45, -3.9)):
        m.prism(f"Fang{k}_L", radius=0.12 * K, height=0.4 * K, at=HP(-0.52 + 0.05 * k, y, 9.95), role="tooth", sides=4, taper=0,
                rot=(180, 0, 0), **MR)
    m.prism("LowFang_L", radius=0.1 * K, height=0.3 * K, at=HP(-0.45, -4.55, 9.62), role="tooth", sides=4, taper=0, **MR)
    m.box("Nostril_L", size=HS(0.2, 0.12, 0.14), at=HP(-0.32, -5.27, 10.75), role="glow_cyan", **MR)
    # yeux lumineux jaunes a pupille fendue et reflet, au-dessus du museau, arcade presque droite
    m.box("Eye_L", size=HS(0.62, 0.1, 0.46), at=HP(-0.78, -3.62, 11.28), role="glow", **MR)
    m.box("Pupil_L", size=HS(0.13, 0.08, 0.38), at=HP(-0.72, -3.67, 11.26), role="eye", **MR)
    m.box("Shine_L", size=HS(0.13, 0.06, 0.13), at=HP(-0.9, -3.7, 11.4), role="white", **MR)
    m.beam("Brow_L", start=HP(-1.3, -3.4, 11.72), end=HP(-0.35, -3.66, 11.66), role="scale_dark", width=0.3 * K, depth=0.26 * K, chamfer=0.05, **MR)
    # cornes en eclairs, qui montent dans la couronne de nuages
    hp = [HP(-0.7, -2.1, 11.6), HP(-1.0, -1.7, 12.55), HP(-0.75, -1.4, 12.75), HP(-1.05, -0.95, 13.8)]
    for i in range(3):
        m.beam(f"Horn{i}_L", start=hp[i], end=hp[i + 1], role="bolt", width=(0.5 - 0.1 * i) * K, depth=(0.5 - 0.1 * i) * K,
               taper=0.75, **MR)
    # collerettes de joue (rig EarL / EarR)
    m.beam("Frill_L", start=HP(-1.1, -2.2, 10.7), end=HP(-2.0, -1.4, 11.15), role="scale_dark", width=0.65 * K, depth=0.2 * K, taper=0.3, **MR)
    m.beam("Frill2_L", start=HP(-1.1, -2.0, 10.3), end=HP(-1.85, -1.3, 10.1), role="navy", width=0.5 * K, depth=0.18 * K, taper=0.3, **MR)
    # ---- couronne de nuages d'orage en anneau au-dessus de la tete (suit la tete), eclairs entre les nuages
    cc = HP(0, -2.1, 12.35)
    r = 1.6 * K
    cpts = []
    for i in range(8):
        a = math.radians(90 + i * 45)
        p = (cc[0] + r * math.cos(a), cc[1] + r * math.sin(a) * 0.8, cc[2] + (0.2 if i % 2 else 0.0))
        cpts.append(p)
        role = "cloud_light" if i % 2 == 0 else "cloud"
        nm = "Crown%d" % i
        m.box(nm, size=HS(1.15, 1.15, 0.95), at=p, role=role, chamfer=0.38, faces={"bottom": "cloud_dark"}, solo=True)
    for k, i in enumerate((1, 3, 5, 7)):
        p = cpts[i]
        zigzag(m, "CrownBolt%d_" % k, (p[0] * 1.02, p[1], p[2] - 0.2), (p[0] * 1.16, p[1] - 0.1, p[2] - 1.7), 3, 0.18, "glow", 0.17, 0.17, solo=True)
    # ---- crete de cristaux (dos du cou, dos, queue)
    for i, (y, z, h, tilt) in enumerate(((0.1, 9.35, 0.9, -40), (0.9, 8.57, 1.1, -45), (1.62, 6.85, 1.0, -60), (1.9, 5.3, 0.9, -70))):
        m.crystal(f"Spine{i}", radius=0.3, height=h, at=(0, y - (0.13 if i == 1 else 0), z), role="bolt" if i % 2 == 0 else "scale_light", sides=4, rot=(tilt, 0, 0))
    # ---- bras (rig ArmL / ArmR) : epaule, bras, avant-bras, main, griffes electriques
    m.box("Shoulder_L", size=(1.4, 1.6, 1.4), at=(-2.15, -0.3, 7.75), role="scale_dark", chamfer=0.35, **MR)
    m.box("ShoulderBand_L", size=(1.48, 1.0, 0.3), at=(-2.15, -0.3, 7.15), role="gold", chamfer=0.06, **MR)
    m.beam("UpperArm_L", start=(-2.15, -0.5, 7.4), end=(-2.6, -1.4, 5.95), role="scale", width=1.0, depth=1.0, chamfer=0.2, **MR)
    m.beam("Forearm_L", start=(-2.6, -1.4, 6.05), end=(-2.2, -2.55, 5.35), role="scale_dark", width=0.85, depth=0.85, chamfer=0.15, **MR)
    m.box("Hand_L", size=(0.95, 0.8, 0.9), at=(-2.15, -2.7, 5.2), role="scale", chamfer=0.15, **MR)
    for k, dx in enumerate((-0.3, 0.0, 0.3)):
        m.prism(f"Claw{k}_L", radius=0.11, height=0.42, at=(-2.15 + dx, -3.05, 4.95), role="glow_cyan", sides=4, taper=0, rot=(150, 0, 0), **MR)
    # ---- ailes (rig WingL / WingR) : os, membranes violettes en eventail, eclairs dans la membrane
    m.box("WingRoot_L", size=(0.9, 1.0, 1.0), at=WROOT, role="gold", chamfer=0.15, **MR)
    m.beam("WingArm_L", start=WROOT, end=WRIST, role="navy", width=0.6, depth=0.65, chamfer=0.1, **MR)
    m.box("WingWrist_L", size=(0.6, 0.6, 0.6), at=WRIST, role="gold", chamfer=0.1, **MR)
    m.crystal("WingClaw_L", radius=0.18, height=0.7, at=WRIST, role="bolt", sides=4, rot=(0, -40, 0), **MR)
    for i, t in enumerate(WTIPS[:3]):
        m.beam(f"Finger{i}_L", start=WRIST, end=t, role="navy", width=0.32, depth=0.38, taper=0.55, **MR)
        m.crystal(f"FingerTip{i}_L", radius=0.15, height=0.55, at=t, role="bolt", sides=4,
                  rot=(0, math.degrees(math.atan2(t[0] - WRIST[0], t[2] - WRIST[2])), 0), **MR)
    # membranes : du poignet vers le milieu de deux bouts de doigts, et de la racine vers le bas de l'aile
    for i in range(2):
        a, b = WTIPS[i], WTIPS[i + 1]
        e = mid(a, b)
        m.beam(f"Memb{i}_L", start=WRIST, end=e, role="membrane", width=0.12, depth=0.35, taper=dist(a, b) / 0.35 * 0.95, **MR)
    a, b = WTIPS[2], WTIPS[3]
    m.beam("Memb2_L", start=mid(WRIST, WROOT, 0.35), end=mid(a, b), role="membrane", width=0.12, depth=1.6, taper=dist(a, b) / 1.6 * 0.9, **MR)
    m.beam("Memb3_L", start=WROOT, end=mid(WRIST, WTIPS[2], 0.55), role="membrane", width=0.12, depth=0.5, taper=5.0, **MR)
    # eclairs jaunes dans la membrane, coeur lumineux (cote gauche ; miroir)
    for i, (a, b) in enumerate(((mid(WRIST, WTIPS[0], 0.15), mid(WTIPS[0], WTIPS[1], 0.55)),
                                (mid(WRIST, WTIPS[1], 0.15), mid(WTIPS[1], WTIPS[2], 0.5)),
                                (mid(WROOT, WRIST, 0.45), mid(WTIPS[2], WTIPS[3], 0.45)))):
        a = (a[0], a[1] - 0.12, a[2]); b = (b[0], b[1] - 0.12, b[2])
        pts = zigzag(m, f"WBolt{i}_", a, b, 4, 0.34, "bolt", 0.46, 0.1, **MR)
        for j in range(4 if i == 2 else 3):
            p0, p1 = pts[j], pts[j + 1]
            m.beam(f"WCore{i}_{j}_L", start=(p0[0], p0[1] - 0.1, p0[2]), end=(p1[0], p1[1] - 0.1, p1[2]), role="glow", width=0.16, depth=0.06,
                   taper=0.6 if j == 3 else 1, **MR)
    # ---- queue (rig Tail) : segments, crete, lame en eclair au bout
    for i in range(len(TAIL7) - 1):
        w = 1.75 - 0.25 * i
        m.beam(f"Tail{i}", start=TAIL7[i], end=TAIL7[i + 1], role="scale", width=w, depth=w * 0.9, chamfer=0.2, taper=0.85, solo=True)
        if i < 4:
            p = mid(TAIL7[i], TAIL7[i + 1])
            m.crystal(f"TailSpike{i}", radius=0.22 - 0.03 * i, height=0.7 - 0.08 * i, at=(p[0], p[1], p[2] + w * 0.42), role="bolt",
                      sides=4, rot=(-30, 0, 0), solo=True)
    tip = TAIL7[-1]
    m.beam("TailBladeA", start=(tip[0] - 0.2, tip[1], tip[2] - 0.1), end=(tip[0] + 0.5, tip[1] + 0.2, tip[2] + 1.0), role="bolt", width=0.6, depth=0.25, solo=True)
    m.beam("TailBladeB", start=(tip[0] + 0.5, tip[1] + 0.2, tip[2] + 0.95), end=(tip[0] + 0.15, tip[1] + 0.25, tip[2] + 1.05), role="bolt", width=0.5, depth=0.22, solo=True)
    m.beam("TailBladeC", start=(tip[0] + 0.2, tip[1] + 0.25, tip[2] + 1.0), end=(tip[0] + 0.9, tip[1] + 0.4, tip[2] + 2.0), role="bolt", width=0.45, depth=0.2, taper=0.2, solo=True)
    m.beam("TailCore", start=(tip[0] + 0.0, tip[1] - 0.1, tip[2] + 0.1), end=(tip[0] + 0.45, tip[1] - 0.0, tip[2] + 0.9), role="glow", width=0.14, depth=0.32, solo=True)
    # ---- peinture
    for k, v in enumerate((1.4, 0.6, -0.2, -1.0)):
        m.line("Belly", "front", [(-1.1, v), (1.1, v)], "belly_dark", 1)
    for v in (0.5, -0.3):
        m.line("ChestPlate", "front", [(-1.2, v), (1.2, v)], "belly_dark", 1)
    for n in ("Torso", "Chest"):
        for (u, v) in ((0.6, 0.6), (-0.4, 0.1), (0.3, -0.6)):
            m.stamp(n, "left", (u, v), ["L.L", ".L."], {"L": "scale_dark"}, mirror=True)
    m.stamp("Thigh_L", "left", (0.2, 0.3), ["L.L", ".L."], {"L": "scale_light"})
    return m


m7 = ropilot.model("R9_T7", px=8, reset=True)
m7.reference(REF7)
m7.palette(**PAL7)
build_t7(m7)
print(m7.build()); print(m7.check()); print(m7.compare()["report"])
ropilot.check_model(collection="R9_T7", max_lines=8)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R9_T7.blend"), copy=True)
# --- suite : exec(rigjoin.py), rig_join("R9_T7", GROUPS_T7), save R9_T7_rig.blend, import -> Work_R9_T7,
# CreatureRig.Install(workspace.Work_R9_T7, "R9_T7", nil, true), puis joints corriges dans le repere du Core :
# ArmL/R (+-2.0, 7.8, -0.35), LegL/R (+-1.45, 3.9, 0.7), Head (0, 10.1, -0.6), WingL/R (+-1.6, 8.3, 1.3), Tail (0, 3.6, 1.5)
# compare() final : face 0.55, dos 0.55, gauche 0.60, dessus 0.49 (reference = dragon fin aux petites ailes et nuage flottant ;
# ailes plus grandes, couronne attachee a la tete et queue enroulee volontairement)
GROUPS_T7 = {'Head': ['Skull', 'Snout', 'SnoutPlate', 'Mouth', 'Throat', 'Fang*_*', 'Nostril_*', 'Eye_*', 'Pupil_*', 'Shine_*', 'Brow_*',
                      'Horn*', 'Crown*'],
             'Jaw': ['Jaw', 'LowFang_*'],
             'EarL': ['Frill_L', 'Frill2_L'], 'EarR': ['Frill_R', 'Frill2_R'],
             'ArmL': ['Shoulder_L', 'ShoulderBand_L', 'UpperArm_L', 'Forearm_L', 'Hand_L', 'Claw*_L'],
             'ArmR': ['Shoulder_R', 'ShoulderBand_R', 'UpperArm_R', 'Forearm_R', 'Hand_R', 'Claw*_R'],
             'WingL': ['WingRoot_L', 'WingArm_L', 'WingWrist_L', 'WingClaw_L', 'Finger*_L', 'FingerTip*_L', 'Memb*_L', 'WBolt*_L', 'WCore*_L'],
             'WingR': ['WingRoot_R', 'WingArm_R', 'WingWrist_R', 'WingClaw_R', 'Finger*_R', 'FingerTip*_R', 'Memb*_R', 'WBolt*_R', 'WCore*_R'],
             'LegL': ['Thigh_L', 'Shin_L', 'Foot_L', 'Toe*_L', 'KneeCap_L'], 'LegR': ['Thigh_R', 'Shin_R', 'Foot_R', 'Toe*_R', 'KneeCap_R'],
             'Tail': ['Tail*']}
