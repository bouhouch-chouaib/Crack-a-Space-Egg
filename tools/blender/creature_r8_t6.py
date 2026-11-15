# Abyss Shark (R8_T6, Mythic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R8_Refs/Ref_R8_T6_*.png)
import ropilot, bpy, os
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R8_Refs")
REF = {v: os.path.join(R, f"Ref_R8_T6_{v}.png") for v in ("front", "left", "back", "top")}
PAL6 = {'navy': {'color': '#22347e', 'noise': 0.035, 'shade': 0.16, 'mottle': ('#1c2c6c', 0.2, 4), 'top': 0.1}, 'navy_dark': {'color': '#16205a', 'noise': 0.03, 'shade': 0.12}, 'navy_light': '#4560b8', 'belly': {'color': '#c9d6ee', 'noise': 0.03, 'shade': 0.12}, 'mouth': '#0d1430', 'tooth': {'color': '#f6f3ea', 'noise': 0.01}, 'crystal': {'color': '#6fd9ee', 'noise': 0.02, 'shade': 0.1, 'top': 0.15, 'rim': -0.25}, 'crystal_dark': '#3aa7c8', 'glow': {'color': '#22e4ff', 'glow': True}, 'glow_dim': {'color': '#1fb8d8', 'glow': True}}

def loft_y(m, prefix, sl, role, chamfer=0.2, faces=None, lip=0.2):
    # slices (y, centre z, height, width) from front (-y) to back (+y); taper and shear on the front end.
    # each slice runs "lip" studs into the next one, 4% bigger there: overlapping plates instead of grooves
    names = []
    for i in range(len(sl) - 1):
        y0, z0, h0, w0 = sl[i]
        y1, z1, h1, w1 = sl[i + 1]
        last = i == len(sl) - 2
        k = 1.0 if last else 1.04
        y1b = y1 if last else y1 + lip
        h1b, w1b = h1 * k, w1 * k
        n = f"{prefix}{i}"
        m.box(n, size=(w1b, y1b - y0, h1b), at=(0, (y0 + y1b) / 2, (z0 + z1) / 2), role=role, axis="y",
              taper=(w0 / w1b, h0 / h1b), shear=(0, z0 - z1), chamfer=chamfer, faces=faces)
        names.append(n)
    return names

def interp(sl, y, k):
    for i in range(len(sl) - 1):
        if sl[i][0] <= y <= sl[i + 1][0]:
            t = (y - sl[i][0]) / (sl[i + 1][0] - sl[i][0])
            return sl[i][k] + t * (sl[i + 1][k] - sl[i][k])
    return sl[-1][k]

def build_t6(m):
    MR = dict(mirror=True)
    # ---- body (navy back, pale belly)
    BODY = [(-3.3, 2.78, 3.6, 3.15), (-1.5, 2.72, 4.15, 3.5), (0.8, 2.8, 3.6, 3.1), (2.8, 2.95, 2.5, 2.1), (4.4, 3.3, 1.0, 0.95)]
    loft_y(m, "Body", BODY, "navy", 0.42, faces={"bottom": "belly"})
    # ---- head (upper skull + snout), jaw, mouth, teeth
    m.box("Head", size=(3.05, 3.0, 2.5), at=(0, -4.7, 3.2), role="navy", axis="y", taper=(0.36, 0.36), shear=(0, -0.35), chamfer=0.32,
          faces={"bottom": "mouth"})
    m.box("Jaw", size=(2.7, 2.3, 0.8), at=(0, -4.45, 1.72), role="belly", axis="y", taper=(0.5, 0.7), chamfer=0.15, faces={"top": "mouth"})
    m.box("Chin", size=(2.9, 0.9, 1.3), at=(0, -3.3, 1.55), role="belly", chamfer=0.25)
    m.box("Mouth", size=(2.1, 1.7, 0.5), at=(0, -4.52, 2.2), role="mouth", axis="y", taper=(0.55, 1))
    for i, (x, y) in enumerate(((-0.3, -5.55), (-0.62, -5.15), (-0.85, -4.65), (-1.0, -4.1))):
        zb = 2.125 + (-3.2 - y) / 3.0 * 0.45
        m.prism(f"ToothU{i}_L", radius=0.13, height=0.38, at=(x, y, zb - 0.14), role="tooth", sides=3, taper=0, turn=180, rot=(180, 0, 0), **MR)
    for i, (x, y) in enumerate(((-0.45, -5.3), (-0.82, -4.9), (-1.05, -4.35))):
        m.prism(f"ToothD{i}_L", radius=0.12, height=0.32, at=(x, y, 2.05), role="tooth", sides=3, taper=0, **MR)
    # ---- eyes: glowing cyan with a heavy brow (menacing, not sad)
    m.box("Eye_L", size=(0.14, 0.75, 0.42), at=(-1.2, -4.4, 3.5), role="glow", rot=(-12, 0, -16), **MR)
    m.box("Pupil_L", size=(0.08, 0.2, 0.3), at=(-1.31, -4.55, 3.5), role="mouth", rot=(-12, 0, -16), **MR)
    m.beam("Brow_L", start=(-1.15, -3.8, 4.0), end=(-0.95, -4.95, 3.68), role="navy_dark", width=0.3, depth=0.3, chamfer=0.04, **MR)
    # ---- crystal dorsal fin, second dorsal, back crystals
    m.box("Dorsal", size=(0.42, 2.5, 2.65), at=(0, -0.25, 5.8), role="crystal", taper=(0.45, 0.15), shear=(0, 1.0))
    m.box("DorsalBase", size=(0.7, 2.7, 0.35), at=(0, -0.45, 4.62), role="navy_dark", chamfer=0.1)
    m.beam("DorsalEdge", start=(0, -1.6, 4.75), end=(0, 0.5, 7.05), role="glow", width=0.12, depth=0.22, taper=0.5)
    m.box("Dorsal2", size=(0.24, 0.8, 0.8), at=(0, 2.7, 4.35), role="crystal", taper=(0.5, 0.2), shear=(0, 0.35))
    for i, (y, z, hh) in enumerate(((1.25, 4.2, 0.6), (1.95, 3.95, 0.5))):
        m.crystal(f"BackCrystal{i}", radius=0.18, height=hh, at=(0, y, z), role="crystal", sides=4)
    # ---- tail: peduncle + crescent fin of crystal
    m.box("Peduncle", size=(0.95, 1.0, 1.0), at=(0, 4.85, 3.3), role="navy", chamfer=0.15)
    m.beam("TailUp", start=(0, 4.9, 3.5), end=(0, 6.3, 5.9), role="navy", width=0.34, depth=1.0, taper=0.45, chamfer=0.05)
    m.beam("TailDn", start=(0, 4.9, 3.1), end=(0, 6.1, 1.2), role="navy", width=0.34, depth=0.95, taper=0.45, chamfer=0.05)
    m.crystal("TailTipUp", radius=0.24, height=0.9, at=(0, 6.05, 5.5), role="crystal", sides=4, rot=(-30, 0, 0))
    m.crystal("TailTipDn", radius=0.22, height=0.8, at=(0, 5.9, 1.6), role="crystal", sides=4, rot=(-150, 0, 0))
    m.box("TailRing", size=(1.1, 0.25, 1.1), at=(0, 4.45, 3.3), role="navy_dark", chamfer=0.05)
    # ---- pectoral fins (rig FinL / FinR): crystal blades sweeping out and down
    m.beam("Fin_L", start=(-1.5, -1.7, 1.7), end=(-5.4, -0.55, 0.08), role="crystal", width=1.4, depth=0.4, taper=0.4, chamfer=0.04, **MR)
    m.beam("FinEdge_L", start=(-1.6, -2.35, 1.75), end=(-5.4, -0.82, 0.12), role="glow", width=0.1, depth=0.2, taper=0.6, **MR)
    m.box("FinRoot_L", size=(0.5, 1.5, 0.72), at=(-1.56, -1.6, 1.65), role="navy_dark", chamfer=0.1, **MR)
    # pelvic and anal fins
    m.beam("Pelvic_L", start=(-0.6, 2.0, 1.55), end=(-1.0, 2.85, 1.1), role="crystal", width=0.6, depth=0.2, taper=0.4, **MR)
    m.box("Anal", size=(0.2, 0.7, 0.6), at=(0, 3.4, 2.05), role="crystal", taper=(1, 0.3), shear=(0, 0.3))
    # ---- glowing flank lines
    for i, (y0, y1, dz) in enumerate(((-2.6, 0.4, 0.25), (1.0, 2.6, 0.15), (-2.2, -0.2, -0.35), (0.1, 2.0, -0.4))):
        x0 = -interp(BODY, y0, 3) / 2 * (1.04 if y0 < 2.8 else 1) - 0.0
        x1 = -interp(BODY, y1, 3) / 2 - 0.0
        m.beam(f"Flank{i}_L", start=(x0, y0, interp(BODY, y0, 1) + dz), end=(x1, y1, interp(BODY, y1, 1) + dz), role="glow", width=0.11, depth=0.1, **MR)
    # gill plates (dark armour) behind the head
    m.box("Gill_L", size=(0.14, 0.9, 2.0), at=(-1.58, -3.05, 2.8), role="navy_dark", chamfer=0.05, taper=(1, 0.8), **MR)
    # ---- paint
    for n in ("Body0", "Body1", "Body2"):
        for face, sg in (("left", 1), ("right", -1)):
            m.rect(n, face, (0, -0.95), (3.0, 0.5), "belly")
    for face in ("left", "right"):
        for (u, v) in ((-0.6, 0.6), (0.3, 0.9), (0.9, 0.4), (-0.2, 0.15)):
            m.rect("Body1", face, (u, v), (0.13, 0.13), "navy_light")
            m.rect("Body2", face, (-u, v - 0.2), (0.13, 0.13), "navy_light")
    for i, u in enumerate((-0.25, 0.0, 0.25)):
        m.line("Gill_L", "left", [(u, 0.7), (u, -0.7)], "mouth", 1)
        m.line("Gill_R", "right", [(u, 0.7), (u, -0.7)], "mouth", 1)
    m.line("Dorsal", "left", [(-0.6, -0.9), (0.4, 0.8)], "crystal_dark", 1)
    m.line("Dorsal", "right", [(0.6, -0.9), (-0.4, 0.8)], "crystal_dark", 1)
    return m

m = ropilot.model("R8_T6", px=8, reset=True)
m.reference(REF)
m.palette(**PAL6)
build_t6(m)
print(m.build()); print(m.check()); print(m.compare()["report"])
ropilot.check_model(collection="R8_T6", max_lines=8)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R8_T6.blend"), copy=True)
# --- suite : rig_join("R8_T6", GROUPS_T6), save R8_T6_rig.blend, import -> Work_R8_T6,
# CreatureRig.Install(workspace.Work_R8_T6, "R8_T6", nil, true)
GROUPS_T6 = {'Head': ['Head', 'Mouth', 'ToothU*', 'Eye_*', 'Pupil_*', 'Brow_*'], 'Jaw': ['Jaw', 'ToothD*'], 'FinL': ['Fin_L', 'FinEdge_L', 'FinRoot_L'], 'FinR': ['Fin_R', 'FinEdge_R', 'FinRoot_R'], 'Tail': ['Body3', 'Peduncle', 'TailUp', 'TailDn', 'TailTip*', 'TailRing', 'Anal']}
