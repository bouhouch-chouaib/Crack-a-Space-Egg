# Star Leviathan (R8_T7, Cosmic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R8_Refs/Ref_R8_T7_*.png)
# Corps en S fait de segments le long d'une ligne (SPINE), tete 1,15x plus grande que sur la reference.
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R8_Refs")
REF = {v: os.path.join(R, f"Ref_R8_T7_{v}.png") for v in ("front", "left", "back", "top")}
PAL7 = {'teal': {'color': '#28aaa8', 'noise': 0.035, 'shade': 0.16, 'mottle': ('#1f9896', 0.2, 4), 'top': 0.1}, 'teal_dark': {'color': '#1a7f82', 'noise': 0.03, 'shade': 0.12}, 'teal_light': '#6fd8cc', 'navy': {'color': '#22347e', 'noise': 0.035, 'shade': 0.14, 'top': 0.08}, 'navy_dark': {'color': '#151f55', 'noise': 0.03, 'shade': 0.1}, 'gold': {'color': '#f2c14e', 'noise': 0.03, 'shade': 0.14, 'top': 0.12, 'rim': -0.2}, 'gold_dark': '#b8862a', 'coral': {'color': '#ff7a6e', 'noise': 0.03, 'shade': 0.12, 'top': 0.08}, 'coral_light': {'color': '#ffb39c', 'noise': 0.03}, 'pearl': {'color': '#fbf7ef', 'noise': 0.015, 'shade': 0.1}, 'crystal': {'color': '#6fd9ee', 'noise': 0.02, 'shade': 0.1, 'top': 0.15, 'rim': -0.25}, 'membrane': {'color': '#22347e', 'noise': 0.04, 'mottle': ('#2c2a8a', 0.35, 6), 'shade': 0.08}, 'star': '#fff4c8', 'white': '#ffffff', 'mouth': '#0d1430', 'tooth': {'color': '#f6f3ea', 'noise': 0.01}, 'glow': {'color': '#22e4ff', 'glow': True}, 'glow_gold': {'color': '#ffcc33', 'glow': True}}

import math

SB = 1.1   # body scale (the head is drawn 1.15x bigger than the reference's)
_SP = [(0.55, 8.75), (1.35, 7.85), (1.45, 6.9), (0.8, 6.0), (-0.4, 5.35), (-1.7, 4.8), (-2.9, 4.2), (-3.5, 3.3),
       (-3.45, 2.3), (-2.85, 1.35), (-1.8, 0.9), (-0.5, 0.92), (0.8, 1.02), (1.85, 1.2), (2.7, 1.4)]
SPINE = [(y * SB, z * SB) for y, z in _SP]
THICK = [t * SB for t in (1.55, 1.65, 1.75, 1.85, 1.9, 1.9, 1.9, 1.9, 1.85, 1.8, 1.72, 1.65, 1.45, 1.25, 1.05)]
WIDE = [t * SB * 0.86 for t in (2.1, 2.2, 2.3, 2.45, 2.5, 2.55, 2.55, 2.5, 2.4, 2.3, 2.1, 1.95, 1.75, 1.5, 1.3)]

def spine_frame(i):
    (y0, z0), (y1, z1) = SPINE[i], SPINE[i + 1]
    L = math.hypot(y1 - y0, z1 - z0)
    dy, dz = (y1 - y0) / L, (z1 - z0) / L
    return (y0, z0), (y1, z1), (dy, dz), (dz, -dy), L   # n = belly side

def build_t7(m):
    MR = dict(mirror=True)
    # ---- segmented body: teal segments, dark rings at the joints, gold belly plates, navy back plates
    n_seg = len(SPINE) - 1
    for i in range(n_seg):
        (y0, z0), (y1, z1), (dy, dz), (ny, nz), L = spine_frame(i)
        e = 0.18
        w = (WIDE[i] + WIDE[i + 1]) / 2
        d = (THICK[i] + THICK[i + 1]) / 2
        m.beam(f"Seg{i}", start=(0, y0 - dy * e, z0 - dz * e), end=(0, y1 + dy * e, z1 + dz * e), role="teal",
               width=w, depth=d, taper=WIDE[i + 1] / WIDE[i], chamfer=0.22)
        o = d / 2 - 0.02
        m.beam(f"Belly{i}", start=(0, y0 + ny * o - dy * 0.05, z0 + nz * o - dz * 0.05), end=(0, y1 + ny * o + dy * 0.05, z1 + nz * o + dz * 0.05),
               role="gold", width=w * 0.62, depth=0.16, chamfer=0.04)
        m.beam(f"Back{i}", start=(0, y0 - ny * o - dy * 0.05, z0 - nz * o - dz * 0.05), end=(0, y1 - ny * o + dy * 0.05, z1 - nz * o + dz * 0.05),
               role="navy", width=w * 0.7, depth=0.18, chamfer=0.05)
        if i % 2 == 1 and i < 12:
            m.beam(f"Lume{i}", start=(0, y0 - ny * (o + 0.07) + dy * 0.35, z0 - nz * (o + 0.07) + dz * 0.35),
                   end=(0, y1 - ny * (o + 0.07) - dy * 0.35, z1 - nz * (o + 0.07) - dz * 0.35), role="glow", width=w * 0.22, depth=0.08)
        if 0 < i < n_seg:
            # ring between segments (covers the bend)
            (py, pz) = SPINE[i]
            (_, _, (ady, adz), _, _) = spine_frame(i - 1)
            ty, tz = ady + dy, adz + dz
            tl = math.hypot(ty, tz)
            ty, tz = ty / tl, tz / tl
            m.beam(f"Ring{i}", start=(0, py - ty * 0.2, pz - tz * 0.2), end=(0, py + ty * 0.2, pz + tz * 0.2),
                   role="navy_dark", width=WIDE[i] * 1.03, depth=THICK[i] * 1.03, chamfer=0.2)
        if i >= 2 and i % 1 == 0 and i <= 12:
            # back crystal spikes, pointing away from the belly
            cy, cz = (y0 + y1) / 2 - ny * (o + 0.05), (z0 + z1) / 2 - nz * (o + 0.05)
            ang = math.degrees(math.atan2(-ny, -nz))   # tilt from +z toward +y
            m.crystal(f"Spike{i}", radius=0.2 if i < 9 else 0.16, height=0.75 if i < 9 else 0.55, at=(0, cy, cz), role="crystal", sides=4,
                      rot=(-ang, 0, 0))
    BP = lambda x, y, z: (x * SB, y * SB, z * SB)
    BS = lambda *v: tuple(c * SB for c in v)
    # ---- tail fin (navy with crystal tips)
    m.beam("TailFinUp", start=BP(0, 2.5, 1.5), end=BP(0, 4.15, 2.95), role="navy", width=SB*0.3, depth=SB*1.25, taper=0.4, chamfer=0.05)
    m.beam("TailFinDn", start=BP(0, 2.5, 1.35), end=BP(0, 4.15, 0.35), role="navy", width=SB*0.3, depth=SB*1.05, taper=0.4, chamfer=0.05)
    m.crystal("TailTipUp", radius=SB*0.22, height=SB*0.8, at=BP(0, 3.95, 2.78), role="crystal", sides=4, rot=(-45, 0, 0))
    m.crystal("TailTipDn", radius=SB*0.2, height=SB*0.7, at=BP(0, 4.0, 0.5), role="crystal", sides=4, rot=(-120, 0, 0))
    K, PY, PZ = 1.15, 0.1 * SB, 9.05 * SB
    HP = lambda *p: HP(*p[0]) if len(p) == 1 else (p[0] * K, PY + (p[1] - 0.1) * K, PZ + (p[2] - 9.05) * K)
    HS = lambda *v: tuple(c * K for c in v)
    # ---- head: skull, snout, jaw (rig Jaw), fangs, glowing eyes under gold brows
    m.box("Skull", size=HS(2.3, 2.2, 1.25), at=HP(0, 0.0, 9.55), role="teal", chamfer=0.3, axis="y", taper=(0.85, 0.85))
    m.box("Snout", size=HS(1.85, 1.3, 0.8), at=HP(0, -1.6, 9.32), role="teal", chamfer=0.2, axis="y", taper=(0.78, 0.78))
    m.box("SnoutPlate", size=HS(1.3, 1.6, 0.2), at=HP(0, -1.3, 9.77), role="navy", chamfer=0.05, axis="y", taper=(0.7, 1))
    m.box("Jaw", size=HS(1.75, 2.15, 0.5), at=HP(0, -1.05, 8.66), role="gold", chamfer=0.12, axis="y", taper=(0.72, 0.8), faces={"top": "mouth"})
    m.box("Mouth", size=HS(1.6, 1.8, 0.24), at=HP(0, -1.15, 8.96), role="mouth", axis="y", taper=(0.75, 1))
    m.prism("Fang_L", radius=K*0.13, height=K*0.42, at=HP(-0.55, -1.95, 8.82), role="tooth", sides=3, taper=0, rot=(180, 0, 0), **MR)
    m.prism("FangLow_L", radius=K*0.1, height=K*0.3, at=HP(-0.42, -1.8, 9.0), role="tooth", sides=3, taper=0, **MR)
    m.box("Eye_L", size=HS(0.14, 0.72, 0.44), at=HP(-1.08, -0.62, 9.68), role="glow", rot=(-14, 0, -12), **MR)
    m.box("Pupil_L", size=HS(0.08, 0.12, 0.34), at=HP(-1.15, -0.68, 9.68), role="mouth", rot=(-14, 0, -12), **MR)
    m.beam("Brow_L", start=HP(-1.12, 0.15, 10.05), end=HP(-0.95, -1.05, 9.82), role="gold", width=K*0.26, depth=K*0.26, chamfer=0.04, **MR)
    # cheek frills (rig EarL / EarR): navy blades with crystal tips
    m.beam("Frill_L", start=HP(-1.0, 0.6, 9.4), end=HP(-2.1, 1.5, 9.9), role="navy", width=K*0.7, depth=K*0.14, taper=0.35, **MR)
    m.beam("Frill2_L", start=HP(-1.0, 0.7, 9.05), end=HP(-1.9, 1.6, 8.85), role="navy_dark", width=K*0.55, depth=K*0.12, taper=0.35, **MR)
    m.crystal("FrillTip_L", radius=K*0.12, height=K*0.45, at=HP(-2.0, 1.45, 9.85), role="crystal", sides=4, rot=(0, -60, 0), **MR)
    # ---- crown of gold and coral, star gem, pearls
    m.box("Crown", size=HS(1.75, 1.45, 0.32), at=HP(0, 0.15, 10.32), role="gold", chamfer=0.06)
    m.prism("CrownPt0_L", radius=K*0.16, height=K*0.5, at=HP(-0.55, -0.45, 10.45), role="gold", sides=4, taper=0, **MR)
    m.prism("CrownPt1", radius=K*0.17, height=K*0.6, at=HP(0.0, -0.55, 10.45), role="gold", sides=4, taper=0)
    m.prism("CrownPtB_L", radius=K*0.14, height=K*0.42, at=HP(-0.75, 0.55, 10.45), role="gold", sides=4, taper=0, **MR)
    m.box("StarGem", size=HS(0.34, 0.14, 0.34), at=HP(0, -0.62, 10.32), role="glow_gold", rot=(0, 45, 0))
    m.beam("Antler_L", start=HP(-0.6, 0.35, 10.4), end=HP(-1.55, 0.75, 11.3), role="coral", width=K*0.4, taper=0.65, **MR)
    m.beam("AntTine1_L", start=HP(-1.0, 0.5, 10.75), end=HP(-1.75, 0.25, 10.95), role="coral", width=K*0.3, taper=0.65, **MR)
    m.beam("AntTine2_L", start=HP(-1.3, 0.62, 11.0), end=HP(-1.05, 1.15, 11.35), role="coral_light", width=K*0.26, taper=0.65, **MR)
    for n, p in (("AntPearlA_L", (-1.55, 0.75, 11.3)), ("AntPearlB_L", (-1.75, 0.25, 10.95))):
        m.box(n, size=HS(0.24, 0.24, 0.24), at=HP(p), role="pearl", **MR)
    # ---- mane crest down the back of the neck
    for i, (a, b) in enumerate((((0, 0.9, 9.9), (0, 2.0, 10.1)), ((0, 1.35, 9.1), (0, 2.45, 9.1)), ((0, 1.85, 8.2), (0, 2.65, 7.85)))):
        m.beam(f"Mane{i}", start=BP(*a), end=BP(*b), role="navy", width=SB*0.16, depth=SB*(0.75 - 0.1 * i), taper=0.3)
    # ---- star fin-wings (rig FinL / FinR): gold bones, starry membranes, crystal tips
    root = BP(-1.15, 1.38, 7.9)
    m.beam("Bone1_L", start=root, end=BP(-5.6, 1.5, 8.85), role="gold", width=SB*0.24, depth=SB*0.32, taper=0.6, chamfer=0.04, **MR)
    m.beam("Bone2_L", start=root, end=BP(-5.55, 1.5, 7.3), role="gold", width=SB*0.2, depth=SB*0.26, taper=0.6, chamfer=0.03, **MR)
    m.beam("Bone3_L", start=root, end=BP(-3.6, 1.45, 5.15), role="gold", width=SB*0.2, depth=SB*0.24, taper=0.6, chamfer=0.03, **MR)
    m.beam("Memb1_L", start=root, end=BP(-5.45, 1.5, 7.95), role="membrane", width=SB*0.1, depth=SB*0.5, taper=4.8, **MR)
    m.beam("Memb2_L", start=root, end=BP(-4.45, 1.48, 6.15), role="membrane", width=SB*0.1, depth=SB*0.5, taper=4.0, **MR)
    m.beam("Memb3_L", start=root, end=BP(-5.1, 1.5, 7.15), role="membrane", width=SB*0.1, depth=SB*0.5, taper=3.6, **MR)
    m.crystal("WingTip1_L", radius=SB*0.18, height=SB*0.7, at=BP(-5.55, 1.5, 8.8), role="crystal", sides=4, rot=(0, -60, 0), **MR)
    m.crystal("WingTip2_L", radius=SB*0.15, height=SB*0.55, at=BP(-5.5, 1.5, 7.3), role="crystal", sides=4, rot=(0, -100, 0), **MR)
    m.crystal("WingTip3_L", radius=SB*0.15, height=SB*0.5, at=BP(-3.55, 1.45, 5.2), role="crystal", sides=4, rot=(0, -145, 0), **MR)
    m.box("WingRoot_L", size=BS(0.5, 0.9, 0.9), at=BP(-1.2, 1.38, 7.9), role="gold", chamfer=0.1, **MR)
    for i, (x, z) in enumerate(((-2.6, 7.75), (-3.6, 7.4), (-4.5, 8.05), (-4.7, 7.0), (-3.1, 6.55), (-3.9, 5.9), (-2.6, 5.75))):
        m.box(f"Star{i}_L", size=BS(0.3, 0.62, 0.3), at=BP(x, 1.49, z + 0.6), role="glow_gold" if i % 3 != 1 else "star", rot=(0, 45, 0), **MR)
    return m

m = ropilot.model("R8_T7", px=8, reset=True)
m.reference(REF)
m.palette(**PAL7)
build_t7(m)
print(m.build()); print(m.check()); print(m.compare()["report"])
ropilot.check_model(collection="R8_T7", max_lines=8)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R8_T7.blend"), copy=True)
# --- suite : rig_join("R8_T7", GROUPS_T7), save R8_T7_rig.blend, import -> Work_R8_T7,
# CreatureRig.Install(workspace.Work_R8_T7, "R8_T7", nil, true)
GROUPS_T7 = {'Head': ['Skull', 'Snout', 'SnoutPlate', 'Mouth', 'Fang_*', 'Eye_*', 'Pupil_*', 'Brow_*', 'Crown', 'CrownPt*', 'StarGem', 'Antler_*', 'AntTine*', 'AntPearl*', 'Mane0'], 'Jaw': ['Jaw', 'FangLow_*'], 'EarL': ['Frill_L', 'Frill2_L', 'FrillTip_L'], 'EarR': ['Frill_R', 'Frill2_R', 'FrillTip_R'], 'FinL': ['Bone*_L', 'Memb*_L', 'WingTip*_L', 'WingRoot_L', 'Star*_L'], 'FinR': ['Bone*_R', 'Memb*_R', 'WingTip*_R', 'WingRoot_R', 'Star*_R'], 'Tail': ['Seg11', 'Seg12', 'Seg13', 'Belly11', 'Belly12', 'Belly13', 'Back11', 'Back12', 'Back13', 'Ring12', 'Ring13', 'Spike11', 'Spike12', 'Lume11', 'TailFin*', 'TailTip*']}
