# Plasma Tiger (R9_T6, Mythic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R9_Refs/Ref_R9_T6_*.png)
# Tigre trapu violet orage : poitrail haut, epaules et cuisses puissantes, grosses pattes blanches aux griffes
# electriques (cyan lumineux), rayures de plasma (eclats jaunes lumineux bordes de bleu nuit peints),
# tete large : museau et collerette blancs, crocs, sourcils lourds, yeux jaunes a pupille fendue avec reflet,
# bracelets d'or aux pattes avant, longue queue rayee a pointe de plasma.
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R9_Refs")
REF6 = {v: os.path.join(R, f"Ref_R9_T6_{v}.png") for v in ("front", "left", "back", "top")}
PAL6 = dict(
    fur=dict(color="#6e5ac8", noise=0.035, shade=0.16, mottle=("#6450bc", 0.2, 4), top=0.12),
    fur_dark=dict(color="#4a3a9e", noise=0.03, shade=0.12),
    navy=dict(color="#2a1e5a", noise=0.03, shade=0.1),
    white=dict(color="#efeaff", noise=0.02, shade=0.1),
    cream=dict(color="#d9ccff", noise=0.025, shade=0.1),
    nose="#ff8fb8", eye="#140f33", shine="#ffffff",
    tooth=dict(color="#fbf8ff", noise=0.01),
    gold=dict(color="#ffcf3a", noise=0.03, shade=0.12, top=0.12, rim=-0.22),
    gold_dark=dict(color="#d99a1e", noise=0.03),
    glow=dict(color="#ffd21a", glow=True), glow_cyan=dict(color="#3fd8ff", glow=True),
)
TAIL6 = [(0, 3.3, 4.3), (0, 4.2, 3.6), (0, 4.75, 2.95), (0, 5.3, 3.05), (0, 5.6, 3.7)]


def build_t6(m):
    MR = dict(mirror=True)
    # ---- corps : poitrail haut, dos continu, hanches puissantes, ventre blanc
    m.box("Chest", size=(3.3, 2.5, 3.8), at=(0, -1.85, 3.95), role="fur", chamfer=0.6, faces={"bottom": "white"})
    m.box("ChestFluff", size=(2.2, 0.6, 2.0), at=(0, -3.05, 3.2), role="white", chamfer=0.35, taper=(0.8, 1))
    m.box("Torso", size=(3.1, 3.4, 3.3), at=(0, 0.5, 3.85), role="fur", chamfer=0.6, faces={"bottom": "white"})
    m.box("Hips", size=(3.2, 2.0, 3.3), at=(0, 2.45, 3.8), role="fur", chamfer=0.6, faces={"bottom": "white"})
    m.box("Belly", size=(2.0, 3.8, 0.4), at=(0, 0.4, 2.2), role="white", chamfer=0.12)
    # ---- tete : crane large, joues et museau blancs, nez rose, machoire (rig Jaw), crocs, touffes de joues
    m.box("Head", size=(3.0, 2.2, 2.1), at=(0, -3.45, 5.9), role="fur", chamfer=0.5)
    m.box("Cheek_L", size=(0.95, 1.0, 0.85), at=(-0.85, -4.25, 5.25), role="white", chamfer=0.22, **MR)
    m.box("Muzzle", size=(1.3, 0.8, 0.8), at=(0, -4.8, 5.3), role="white", chamfer=0.2, taper=(0.9, 0.9), axis="y")
    m.box("Nose", size=(0.36, 0.3, 0.28), at=(0, -5.17, 5.66), role="nose", chamfer=0.05, taper=(1.7, 1))
    m.box("Jaw", size=(1.1, 0.85, 0.4), at=(0, -4.6, 4.72), role="white", chamfer=0.1)
    m.prism("Fang_L", radius=0.11, height=0.36, at=(-0.33, -5.05, 4.92), role="tooth", sides=4, taper=0, rot=(180, 0, 0), **MR)
    m.beam("Ruff_L", start=(-1.25, -3.75, 5.45), end=(-2.05, -3.5, 5.05), role="white", width=0.75, depth=0.3, taper=0.3, **MR)
    m.beam("Ruff2_L", start=(-1.2, -3.6, 5.05), end=(-1.85, -3.3, 4.6), role="white", width=0.6, depth=0.28, taper=0.3, **MR)
    m.box("Ear_L", size=(0.85, 0.45, 0.8), at=(-1.15, -3.05, 7.15), role="fur", chamfer=0.12, taper=(0.55, 0.8), rot=(0, -12, 0),
          faces={"front": "cream", "back": "white"}, **MR)
    # yeux : blanc, iris jaune lumineux, pupille fendue, reflet ; bien separes ; sourcils presque droits
    m.box("Eye_L", size=(0.6, 0.1, 0.44), at=(-0.72, -4.58, 6.18), role="white", **MR)
    m.box("Iris_L", size=(0.38, 0.08, 0.38), at=(-0.66, -4.63, 6.16), role="glow", **MR)
    m.box("Pupil_L", size=(0.1, 0.06, 0.3), at=(-0.64, -4.68, 6.16), role="eye", **MR)
    m.box("Shine_L", size=(0.1, 0.05, 0.1), at=(-0.74, -4.69, 6.28), role="shine", **MR)
    m.beam("Brow_L", start=(-1.15, -4.6, 6.6), end=(-0.32, -4.6, 6.52), role="navy", width=0.2, depth=0.12, **MR)
    # front : trois eclats de plasma
    m.box("Forehead_L", size=(0.14, 0.8, 0.06), at=(-0.5, -4.0, 6.94), role="glow", **MR)
    m.box("Forehead", size=(0.14, 1.1, 0.06), at=(0.0, -3.85, 6.94), role="glow")
    # ---- pattes : epaules et cuisses, grosses pattes blanches, bracelets d'or, griffes electriques
    m.box("Shoulder_L", size=(1.25, 1.7, 1.8), at=(-1.45, -1.95, 3.25), role="fur", chamfer=0.4, **MR)
    m.box("LegF_L", size=(1.15, 1.2, 2.3), at=(-1.5, -2.45, 1.6), role="fur", chamfer=0.26, taper=(1.15, 1.15), **MR)
    m.box("PawF_L", size=(1.45, 1.65, 0.6), at=(-1.5, -2.85, 0.3), role="white", chamfer=0.16, **MR)
    m.box("Bracer_L", size=(1.38, 1.43, 0.32), at=(-1.5, -2.45, 1.1), role="gold", chamfer=0.06, **MR)
    m.box("BracerGem_L", size=(0.26, 0.1, 0.2), at=(-1.5, -3.17, 1.1), role="glow_cyan", **MR)
    m.box("Thigh_L", size=(1.3, 2.0, 2.2), at=(-1.45, 2.4, 2.75), role="fur", chamfer=0.4, **MR)
    m.box("LegB_L", size=(1.0, 1.0, 1.5), at=(-1.45, 2.85, 1.0), role="fur", chamfer=0.22, taper=(1.15, 1.15), **MR)
    m.box("PawB_L", size=(1.35, 1.5, 0.55), at=(-1.45, 2.7, 0.28), role="white", chamfer=0.16, **MR)
    for k, dx in enumerate((-0.4, 0.0, 0.4)):
        m.prism(f"ClawF{k}_L", radius=0.1, height=0.32, at=(-1.5 + dx, -3.63, 0.22), role="glow_cyan", sides=4, taper=0, rot=(90, 0, 0), **MR)
        m.prism(f"ClawB{k}_L", radius=0.09, height=0.28, at=(-1.45 + dx * 0.9, 1.99, 0.2), role="glow_cyan", sides=4, taper=0, rot=(90, 0, 0), **MR)
    # ---- queue rayee, pointe de plasma (rig Tail)
    for i in range(len(TAIL6) - 1):
        m.beam(f"Tail{i}", start=TAIL6[i], end=TAIL6[i + 1], role="fur" if i % 2 == 0 else "navy", width=0.62 - 0.05 * i,
               depth=0.62 - 0.05 * i, chamfer=0.06)
    m.crystal("TailTip", radius=0.26, height=0.7, at=(0, 5.62, 3.62), role="glow", sides=4, rot=(-25, 0, 0))
    # ---- rayures : bandes bleu nuit en relief sur les flancs, coeur de plasma lumineux (cote gauche + miroir)
    for k, (y, zt, ln) in enumerate(((-2.45, 5.55, 1.3), (-1.4, 5.55, 1.35), (-0.25, 5.3, 1.9), (0.75, 5.3, 2.0), (1.75, 5.25, 1.7), (2.85, 5.2, 1.2))):
        x = -1.58 if k < 2 else (-1.53 if k < 5 else -1.58)
        x = -1.63 if k in (0, 1, 5) else -1.53
        m.beam(f"Band{k}_L", start=(x, y, zt), end=(x, y + 0.35, zt - ln), role="navy", width=0.08, depth=0.5, taper=0.25, **MR)
        m.beam(f"Stripe{k}_L", start=(x - 0.04, y + 0.02, zt - 0.12), end=(x - 0.04, y + 0.3, zt - ln * 0.8), role="glow", width=0.06,
               depth=0.18, taper=0.3, **MR)
    # ---- peinture : rayures bleu nuit (dos, pattes, front), museau
    for host, vs in (("Chest", (-0.55, 0.35)), ("Torso", (-0.75, 0.25, 1.1)), ("Hips", (-0.45, 0.45))):
        for v in vs:
            m.line(host, "top", [(-0.95, v + 0.12), (-0.3, v - 0.05), (0.3, v - 0.05), (0.95, v + 0.12)], "navy", 3)
    m.line("Head", "top", [(-0.6, 0.2), (0, -0.05), (0.6, 0.2)], "navy", 2)
    m.line("Head", "top", [(-0.5, 0.65), (0, 0.45), (0.5, 0.65)], "navy", 2)
    for n in ("LegF_L", "LegB_L"):
        m.line(n, "left", [(-0.45, 0.25), (0.45, 0.4)], "navy", 2)
        m.line(n, "left", [(-0.45, -0.2), (0.45, -0.05)], "navy", 2)
    m.line("Head", "front", [(-0.15, 0.95), (-0.05, 0.75)], "navy", 2)
    m.line("Head", "front", [(0.15, 0.95), (0.05, 0.75)], "navy", 2)
    m.stamp("Muzzle", "front", (0, -0.15), ["...K...", "..K.K.."], {"K": "navy"})
    for sd in ("L", "R"):
        m.stamp("Cheek_" + sd, "front", (0, 0.05), ["K.K", ".K."], {"K": "fur"})
    m.line("Bracer_L", "front", [(-0.5, 0.0), (0.5, 0.0)], "gold_dark", 1)
    return m


m6 = ropilot.model("R9_T6", px=8, reset=True)
m6.reference(REF6)
m6.palette(**PAL6)
build_t6(m6)
print(m6.build()); print(m6.check()); print(m6.compare()["report"])
ropilot.check_model(collection="R9_T6", max_lines=8)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R9_T6.blend"), copy=True)
# --- suite : exec(rigjoin.py), rig_join("R9_T6", GROUPS_T6), save R9_T6_rig.blend, import -> Work_R9_T6,
# CreatureRig.Install(workspace.Work_R9_T6, "R9_T6", nil, true), puis joints corriges dans le repere du Core :
# LegFL/FR (+-1.5, 3.7, -2.1), LegBL/BR (+-1.45, 3.4, 2.4), Head (0, 5.1, -2.6), Jaw (0, 4.9, -4.25), Tail (0, 4.3, 3.3)
# compare() final : face 0.84, dos 0.84, gauche 0.74, dessus 0.73 (dos garde plus bas que la reference, tres bossue)
GROUPS_T6 = {'Head': ['Head', 'Brow_*', 'Muzzle', 'Nose', 'Fang_*', 'Ruff*', 'Cheek_*', 'Eye_*', 'Iris_*', 'Pupil_*', 'Shine_*', 'Forehead*'],
             'Jaw': ['Jaw'],
             'EarL': ['Ear_L'], 'EarR': ['Ear_R'],
             'LegFL': ['Shoulder_L', 'LegF_L', 'PawF_L', 'Bracer_L', 'BracerGem_L', 'ClawF*_L'],
             'LegFR': ['Shoulder_R', 'LegF_R', 'PawF_R', 'Bracer_R', 'BracerGem_R', 'ClawF*_R'],
             'LegBL': ['Thigh_L', 'LegB_L', 'PawB_L', 'ClawB*_L'], 'LegBR': ['Thigh_R', 'LegB_R', 'PawB_R', 'ClawB*_R'],
             'Tail': ['Tail*']}
