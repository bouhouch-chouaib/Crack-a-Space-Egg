# Tide Seahorse (R8_T5, Legendary) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R8_Refs/Ref_R8_T5_*.png)
import ropilot, bpy, os
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R8_Refs")
REF = {v: os.path.join(R, f"Ref_R8_T5_{v}.png") for v in ("front", "left", "back", "top")}
PAL5 = {'teal': {'color': '#28aaa8', 'noise': 0.035, 'shade': 0.16, 'mottle': ('#1f9896', 0.2, 4), 'top': 0.1}, 'teal_dark': {'color': '#1a7f82', 'noise': 0.03, 'shade': 0.12}, 'teal_light': {'color': '#6fd8cc', 'noise': 0.03}, 'coral': {'color': '#ff7a6e', 'noise': 0.03, 'shade': 0.12, 'top': 0.08}, 'coral_dark': {'color': '#d9544c', 'noise': 0.03}, 'coral_light': {'color': '#ffb39c', 'noise': 0.03}, 'gold': {'color': '#f2c14e', 'noise': 0.03, 'shade': 0.14, 'top': 0.12, 'rim': -0.2}, 'gold_dark': {'color': '#b8862a', 'noise': 0.03}, 'sand': {'color': '#f4e2bc', 'noise': 0.03, 'shade': 0.12}, 'navy': '#1c2a66', 'white': '#ffffff', 'pearl': {'color': '#fbf7ef', 'noise': 0.015, 'shade': 0.1}, 'glow': {'color': '#2fd8f0', 'glow': True}}

def loft(m, prefix, sl, role, chamfer=0.12, faces=None):
    names = []
    for i in range(len(sl) - 1):
        z0, c0, d0, w0 = sl[i]
        z1, c1, d1, w1 = sl[i + 1]
        n = f"{prefix}{i}"
        m.box(n, size=(w0, d0, z1 - z0), at=(0, (c0 + c1) / 2, (z0 + z1) / 2), role=role,
              taper=(w1 / w0, d1 / d0), shear=(0, c1 - c0), chamfer=chamfer, faces=faces)
        names.append(n)
    return names

def build_t5(m):
    MR = dict(mirror=True)
    # ---- body: lofted slices along the S curve (z, centre y, depth, width); the belly faces are sand
    BODY = [(1.25, 1.18, 1.0, 1.0), (2.1, 1.0, 1.15, 1.25), (2.8, 0.42, 1.55, 1.6), (3.5, 0.06, 2.05, 2.0),
            (4.2, 0.04, 2.35, 2.15), (4.9, 0.16, 2.15, 2.05), (5.6, 0.39, 1.8, 1.85), (6.55, 0.62, 1.4, 1.65)]
    loft(m, "Seg", BODY, "teal", 0.14, faces={"front": "sand"})
    # ---- tail curl (spiral forward under the belly)
    m.beam("Curl0", start=(0, 1.18, 1.4), end=(0, 1.0, 0.42), role="teal", width=0.95, depth=0.95, taper=0.95, chamfer=0.14)
    m.beam("Curl1", start=(0, 1.2, 0.48), end=(0, -0.35, 0.48), role="teal", width=0.88, depth=0.82, taper=0.92, chamfer=0.14)
    m.beam("Curl2", start=(0, -0.2, 0.4), end=(0, -0.68, 1.04), role="teal", width=0.8, depth=0.72, taper=0.88, chamfer=0.12)
    m.beam("Curl3", start=(0, -0.66, 0.86), end=(0, -0.12, 1.26), role="teal", width=0.68, depth=0.58, taper=0.85, chamfer=0.1)
    m.beam("Curl4", start=(0, -0.2, 1.27), end=(0, 0.12, 0.93), role="teal_dark", width=0.52, depth=0.44, taper=0.8, chamfer=0.08)
    # ---- head: horse-like wedge, the face slopes down toward the long snout
    m.box("Head", size=(2.0, 2.55, 1.7), at=(0, -0.02, 7.12), role="teal", chamfer=0.32, taper=(0.72, 0.68), shear=(0, -0.24), axis="y")
    m.box("Jowl", size=(1.6, 1.3, 0.6), at=(0, 0.25, 6.4), role="teal", chamfer=0.22, taper=(0.9, 0.85))
    m.beam("Snout", start=(0, -1.0, 6.78), end=(0, -2.18, 6.38), role="teal", width=0.66, depth=0.62, taper=0.82, chamfer=0.08)
    m.box("SnoutTip", size=(0.72, 0.32, 0.64), at=(0, -2.24, 6.36), role="teal_dark", chamfer=0.08)
    m.box("SnoutBand", size=(0.74, 0.18, 0.7), at=(0, -1.68, 6.56), role="gold", chamfer=0.04, rot=(-22, 0, 0))
    # ---- crown: gold band, coral antlers with pearl tips, glowing crystal
    m.box("Crown", size=(1.6, 1.45, 0.32), at=(0, 0.2, 7.98), role="gold", chamfer=0.06)
    m.crystal("CrownGem", radius=0.22, height=0.95, at=(0, 0.2, 8.1), role="glow", sides=4)
    m.beam("Antler_L", start=(-0.45, 0.2, 7.98), end=(-1.95, 0.2, 8.2), role="coral", width=0.4, taper=0.75, **MR)
    m.beam("Tine1_L", start=(-0.95, 0.2, 8.0), end=(-1.0, 0.1, 9.0), role="coral", width=0.34, taper=0.7, **MR)
    m.beam("Tine2_L", start=(-1.6, 0.2, 8.15), end=(-1.85, 0.15, 8.85), role="coral", width=0.32, taper=0.7, **MR)
    m.beam("Tine3_L", start=(-1.28, 0.2, 8.12), end=(-1.4, -0.35, 8.6), role="coral_light", width=0.24, taper=0.7, **MR)
    for n, p in (("PearlA_L", (-1.0, 0.1, 9.0)), ("PearlB_L", (-1.85, 0.15, 8.85)), ("PearlC_L", (-1.97, 0.18, 8.2))):
        m.box(n, size=(0.26, 0.26, 0.26), at=p, role="pearl", **MR)
    # ---- eyes: dark socket, glowing iris, pupil, gold brow slanted down to the front (determined look)
    m.box("Socket_L", size=(0.3, 0.82, 0.76), at=(-0.95, -0.5, 7.2), role="navy", chamfer=0.04, **MR)
    m.box("Iris_L", size=(0.1, 0.58, 0.56), at=(-1.11, -0.52, 7.21), role="glow", **MR)
    m.box("Pupil_L", size=(0.08, 0.24, 0.32), at=(-1.18, -0.63, 7.21), role="navy", **MR)
    m.box("Shine_L", size=(0.06, 0.12, 0.12), at=(-1.19, -0.5, 7.36), role="white", **MR)
    m.beam("Brow_L", start=(-0.88, 0.1, 7.9), end=(-0.95, -0.98, 7.52), role="gold", width=0.22, depth=0.22, chamfer=0.03, **MR)
    # ---- dorsal fin with glowing rays
    m.box("Dorsal", size=(0.12, 0.7, 2.7), at=(0, 1.6, 6.3), role="coral_light", taper=(1, 1.15), shear=(0, 0.25))
    for i, (z0, z1, y1) in enumerate(((4.95, 5.5, 2.1), (5.0, 6.35, 2.22), (5.1, 7.15, 2.2), (5.2, 7.85, 2.05))):
        m.beam(f"Ray{i}", start=(0, 1.3, z0 + 0.1), end=(0, y1, z1), role="glow" if i in (1, 2) else "coral", width=0.24, depth=0.16, taper=0.45)
    m.box("DorsalBase", size=(0.36, 0.4, 0.5), at=(0, 1.32, 5.03), role="gold", chamfer=0.06)
    # ---- pectoral fins (rig FinL / FinR): fans that open outward and back
    m.box("Fin_L", size=(0.12, 0.6, 1.25), at=(-1.16, 0.6, 4.4), role="coral", rot=(0, 0, 40), taper=(1, 1.7), shear=(0, 0.3), **MR)
    m.box("FinKnob_L", size=(0.32, 0.55, 0.55), at=(-1.05, 0.25, 4.3), role="gold", chamfer=0.06, **MR)
    # ---- armour: breastplate, pauldrons, collar, tail rings
    m.box("Breast", size=(1.5, 0.24, 1.5), at=(0, -1.12, 4.55), role="gold", chamfer=0.08, taper=(0.75, 1))
    m.box("BreastGem", size=(0.42, 0.12, 0.5), at=(0, -1.26, 4.62), role="glow")
    m.box("BreastPearl", size=(0.3, 0.14, 0.3), at=(0, -1.15, 3.95), role="pearl")
    m.box("Pauldron_L", size=(0.3, 1.0, 0.6), at=(-1.0, 0.25, 5.1), role="gold", chamfer=0.06, taper=(0.6, 0.8), rot=(0, -18, 0), **MR)
    m.prism("Spike_L", radius=0.15, height=0.45, at=(-1.02, 0.25, 5.4), role="coral", sides=4, taper=0, **MR)
    m.box("Collar", size=(1.86, 1.62, 0.26), at=(0, 0.52, 6.0), role="gold", chamfer=0.05)
    m.box("RingB", size=(1.36, 1.3, 0.22), at=(0, 0.95, 2.1), role="gold", chamfer=0.04)
    m.box("RingC", size=(1.04, 0.22, 0.95), at=(0, 0.75, 0.48), role="gold", chamfer=0.04)
    m.box("RingD", size=(0.86, 0.75, 0.22), at=(0, -0.64, 0.96), role="gold", chamfer=0.04, rot=(-40, 0, 0))
    for i, (y, z) in enumerate(((1.2, 3.6), (1.22, 2.7), (1.55, 2.0), (1.66, 1.3))):
        m.prism(f"Knob{i}", radius=0.17, height=0.42, at=(0, y, z), role="coral", sides=4, taper=0, rot=(-90, 0, 0))
    # ---- paint
    for i in range(7):
        n = f"Seg{i}"
        for face, sg in (("left", 1), ("right", -1)):
            m.line(n, face, [(-0.6, 0.3), (0.6, 0.3)], "teal_dark", 1)
            for (u, v) in ((-0.35, -0.05), (0.2, 0.0), (0.0, -0.25)):
                m.rect(n, face, (sg * u, v), (0.13, 0.13), "teal_light")
        m.line(n, "front", [(-0.45, 0.3), (0.45, 0.3)], "gold", 1)
    for face in ("left", "right"):
        m.line("Head", face, [(-0.9, -0.45), (0.9, -0.45)], "teal_light", 1)
        m.rect("Head", face, (0.0 if face == "left" else 0.0, 0.45), (0.12, 0.12), "teal_light")
    m.rect("SnoutTip", "front", (0, -0.05), (0.32, 0.12), "navy")
    m.line("Fin_L", "left", [(0.0, -0.5), (-0.5, 0.55)], "coral_dark", 1)
    m.line("Fin_L", "left", [(0.0, -0.5), (0.0, 0.55)], "coral_dark", 1)
    m.line("Fin_L", "left", [(0.0, -0.5), (0.5, 0.55)], "coral_dark", 1)
    m.line("Breast", "front", [(-0.55, 0.6), (0.55, 0.6), (0.45, -0.6), (-0.45, -0.6), (-0.55, 0.6)], "gold_dark", 1)
    m.line("Crown", "front", [(-0.7, 0.0), (0.7, 0.0)], "gold_dark", 1)
    return m

m = ropilot.model("R8_T5", px=8, reset=True)
m.reference(REF)
m.palette(**PAL5)
build_t5(m)
print(m.build()); print(m.check()); print(m.compare()["report"])
ropilot.check_model(collection="R8_T5", max_lines=8)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R8_T5.blend"), copy=True)
# --- suite ---
# exec(open(r"<repo>/tools/blender/rigjoin.py", encoding="utf-8").read())
# rig_join("R8_T5", GROUPS_T5)  puis save_as_mainfile(R8_T5_rig.blend), import -> Work_R8_T5,
# CreatureRig.Install(workspace.Work_R8_T5, "R8_T5", nil, true)
GROUPS_T5 = {'Head': ['Head', 'Jowl', 'Snout', 'SnoutTip', 'SnoutBand', 'Crown', 'CrownGem', 'Antler_*', 'Tine*', 'Pearl*', 'Socket_*', 'Iris_*', 'Pupil_*', 'Shine_*', 'Brow_*'], 'FinL': ['Fin_L', 'FinKnob_L'], 'FinR': ['Fin_R', 'FinKnob_R'], 'Tail': ['Seg0', 'Curl*', 'RingC', 'RingD', 'Knob3']}
