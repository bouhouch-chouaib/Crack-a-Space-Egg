# Thunder Owl (R9_T4, Epic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R9_Refs/Ref_R9_T4_*.png)
# Ailes = amas de nuages d'orage (rig WingL / WingR) avec des eclairs lumineux pendus dessous, yeux jaunes
# lumineux sur un disque facial lilas, aigrettes en eclairs (rig EarL / EarR), couronne d'or, collier a gemme.
# compare() final : face 0.85, dos 0.85, gauche 0.75, dessus 0.59
import ropilot, bpy, os
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R9_Refs")
REF4 = {v: os.path.join(R, f"Ref_R9_T4_{v}.png") for v in ("front", "left", "back", "top")}
PAL4 = dict(
    plum=dict(color="#6e5ac8", noise=0.035, shade=0.16, mottle=("#6450bc", 0.22, 4), top=0.12),
    plum_dark=dict(color="#4a3a9e", noise=0.03, shade=0.12),
    lilac=dict(color="#9e86ff", noise=0.03, shade=0.1, top=0.12),
    mist=dict(color="#d9ccff", noise=0.025, shade=0.1),
    navy=dict(color="#2a1e5a", noise=0.03, shade=0.12),
    cloud=dict(color="#7e6ad6", noise=0.03, shade=0.2, top=0.2, mottle=("#8f7ce0", 0.25, 5)),
    cloud_dark=dict(color="#3a2c7a", noise=0.03, shade=0.14),
    cloud_light=dict(color="#b7a6ff", noise=0.025, shade=0.1, top=0.15),
    gold=dict(color="#ffcf3a", noise=0.03, shade=0.12, top=0.12, rim=-0.22),
    gold_dark=dict(color="#d99a1e", noise=0.03),
    bolt=dict(color="#ffe15a", noise=0.015, shade=0.08, top=0.15, rim=-0.25),
    eye="#140f33", white="#ffffff",
    glow=dict(color="#ffd21a", glow=True), glow_cyan=dict(color="#3fd8ff", glow=True),
)


def build_t4(m):
    MR = dict(mirror=True)
    # ---- masses : corps rond, ventre lilas, grosse tete
    m.box("Body", size=(2.9, 3.0, 2.6), at=(0, 0.35, 1.55), role="plum", chamfer=0.7, taper=(1.05, 1.0))
    m.box("Belly", size=(2.0, 0.3, 1.85), at=(0, -1.1, 1.4), role="lilac", chamfer=0.3, taper=(0.75, 1))
    m.box("Head", size=(2.9, 2.6, 1.8), at=(0, 0.15, 3.6), role="plum", chamfer=0.6)
    # ---- ailes en nuages d'orage, un peu en avant, dessous sombre, eclairs pendus
    m.box("WingRoot_L", size=(1.0, 1.5, 1.4), at=(-1.6, 0.2, 2.5), role="cloud_dark", chamfer=0.3, **MR)
    m.box("Cloud0_L", size=(1.4, 1.4, 1.0), at=(-2.2, -0.05, 2.1), role="cloud_dark", chamfer=0.3, **MR)
    m.box("Cloud1_L", size=(1.4, 1.6, 1.3), at=(-2.45, -0.1, 2.95), role="cloud", chamfer=0.4, faces={"bottom": "cloud_dark"}, **MR)
    m.box("Cloud2_L", size=(1.3, 1.4, 1.2), at=(-3.25, -0.4, 3.4), role="cloud", chamfer=0.38, faces={"bottom": "cloud_dark"}, **MR)
    m.box("Cloud3_L", size=(1.0, 1.1, 1.0), at=(-3.5, -0.6, 4.2), role="cloud_light", chamfer=0.3, **MR)
    m.box("Cloud4_L", size=(1.0, 1.1, 0.85), at=(-2.55, -0.3, 3.8), role="cloud_light", chamfer=0.28, **MR)
    m.box("Puff_L", size=(0.7, 0.8, 0.6), at=(-3.95, -0.55, 3.5), role="cloud_light", chamfer=0.2, **MR)
    m.box("Puff2_L", size=(0.7, 0.8, 0.55), at=(-1.9, -0.1, 3.5), role="cloud_light", chamfer=0.2, **MR)
    m.beam("Zap1_L", start=(-3.1, -0.45, 2.9), end=(-3.4, -0.45, 2.2), role="glow", width=0.2, depth=0.16, **MR)
    m.beam("Zap2_L", start=(-3.44, -0.45, 2.23), end=(-3.02, -0.45, 2.16), role="glow", width=0.2, depth=0.16, **MR)
    m.beam("Zap3_L", start=(-3.05, -0.45, 2.2), end=(-3.38, -0.45, 1.45), role="glow", width=0.2, depth=0.16, taper=0.25, **MR)
    # ---- couronne d'or et gemme
    m.box("Crown", size=(1.2, 0.95, 0.4), at=(0, 0.1, 4.62), role="gold", chamfer=0.06)
    m.prism("CrownPt_L", radius=0.2, height=0.5, at=(-0.42, -0.22, 4.82), role="gold", sides=4, taper=0, **MR)
    m.prism("CrownPtC", radius=0.22, height=0.62, at=(0, -0.22, 4.82), role="gold", sides=4, taper=0)
    m.prism("CrownPtB_L", radius=0.18, height=0.4, at=(-0.42, 0.42, 4.82), role="gold", sides=4, taper=0, **MR)
    m.box("CrownGem", size=(0.32, 0.1, 0.26), at=(0, -0.39, 4.62), role="glow_cyan")
    # ---- pattes (rig LegL / LegR) : serres dorees
    m.box("Foot_L", size=(0.55, 0.7, 0.35), at=(-0.6, -0.55, 0.175), role="gold", chamfer=0.06, **MR)
    for k, dx in enumerate((-0.18, 0.0, 0.18)):
        m.prism(f"Toe{k}_L", radius=0.09, height=0.3, at=(-0.6 + dx, -0.92, 0.11), role="gold_dark", sides=4, taper=0, rot=(90, 0, 0), **MR)
    m.box("Shin_L", size=(0.42, 0.42, 0.45), at=(-0.6, -0.45, 0.5), role="plum_dark", chamfer=0.08, **MR)
    # ---- queue en eventail (rig Tail)
    m.beam("TailC", start=(0, 1.5, 0.9), end=(0, 2.5, 0.25), role="plum_dark", width=0.8, depth=0.25, taper=1.2)
    m.beam("Tail_L", start=(-0.3, 1.5, 0.9), end=(-0.7, 2.3, 0.3), role="navy", width=0.6, depth=0.22, taper=1.1, **MR)
    m.box("TailTip", size=(0.95, 0.3, 0.18), at=(0, 2.48, 0.27), role="lilac", chamfer=0.04, rot=(-33, 0, 0))
    # ---- visage : disque facial lilas, yeux jaunes lumineux, sourcils, bec d'or
    m.box("Disc_L", size=(1.3, 0.14, 1.25), at=(-0.66, -1.17, 3.55), role="lilac", chamfer=0.1, **MR)
    m.box("Eye_L", size=(0.74, 0.1, 0.74), at=(-0.66, -1.27, 3.58), role="glow", **MR)
    m.box("Pupil_L", size=(0.36, 0.08, 0.42), at=(-0.6, -1.33, 3.55), role="eye", **MR)
    m.box("Shine_L", size=(0.15, 0.06, 0.15), at=(-0.76, -1.34, 3.76), role="white", **MR)
    m.box("EyeRim_L", size=(0.86, 0.06, 0.12), at=(-0.66, -1.25, 3.18), role="plum_dark", **MR)
    m.box("Brow_L", size=(1.1, 0.18, 0.22), at=(-0.68, -1.22, 4.07), role="plum_dark", chamfer=0.04, rot=(0, 9, 0), **MR)
    m.box("BeakTop", size=(0.42, 0.34, 0.3), at=(0, -1.32, 3.4), role="gold", chamfer=0.05)
    m.prism("Beak", radius=0.22, height=0.45, at=(0, -1.36, 3.1), role="gold", sides=4, taper=0, rot=(180, 0, 0), turn=45)
    # ---- aigrettes en eclairs (rig EarL / EarR)
    m.beam("Tuft1_L", start=(-0.95, -0.15, 4.2), end=(-1.5, -0.2, 4.75), role="bolt", width=0.36, depth=0.26, **MR)
    m.beam("Tuft2_L", start=(-1.58, -0.2, 4.76), end=(-1.18, -0.2, 4.84), role="bolt", width=0.3, depth=0.24, **MR)
    m.beam("Tuft3_L", start=(-1.2, -0.2, 4.78), end=(-1.78, -0.2, 5.3), role="bolt", width=0.3, depth=0.24, taper=0.3, **MR)
    # ---- collier d'or et gemme d'orage
    m.box("Collar", size=(2.3, 0.5, 0.26), at=(0, -0.98, 2.76), role="gold", chamfer=0.06)
    m.box("CollarGem", size=(0.34, 0.12, 0.34), at=(0, -1.25, 2.66), role="glow_cyan", rot=(0, 45, 0))
    # ---- peinture
    for face, sg in (("left", 1), ("right", -1)):
        for (u, v) in ((0.3, 0.4), (-0.2, 0.1), (0.5, -0.25), (-0.6, -0.4), (0.0, -0.6)):
            m.stamp("Body", face, (sg * u, v), ["L.L", ".L."], {"L": "plum_dark"})
    m.stamp("Head", "top", (0.0, -0.6), ["L.L.L", ".L.L."], {"L": "lilac"})
    m.line("Crown", "front", [(-0.4, 0.0), (0.4, 0.0)], "gold_dark", 1)
    for n in ("Cloud1_L", "Cloud2_L", "Cloud1_R", "Cloud2_R"):
        m.blob(n, "top", (0.1, 0.1), 0.25, "cloud_light", seed=2)
    for z in (0.55, 0.05, -0.45):
        m.line("Belly", "front", [(-0.45, z + 0.15), (0, z - 0.1), (0.45, z + 0.15)], "plum", 2)
    for (u, v) in ((-0.65, 0.3), (0.0, 0.3), (0.65, 0.3), (-0.65, -0.2), (0.0, -0.2), (0.65, -0.2)):
        m.line("Body", "back", [(u - 0.22, v + 0.08), (u, v - 0.06), (u + 0.22, v + 0.08)], "lilac", 2)
    m.line("Head", "back", [(-0.5, 0.1), (0, -0.15), (0.5, 0.1)], "lilac", 2)
    return m


m4 = ropilot.model("R9_T4", px=8, reset=True)
m4.reference(REF4)
m4.palette(**PAL4)
build_t4(m4)
print(m4.build()); print(m4.check()); print(m4.compare()["report"])
ropilot.check_model(collection="R9_T4", max_lines=8)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R9_T4.blend"), copy=True)
# --- suite : exec(rigjoin.py), rig_join("R9_T4", GROUPS_T4), save R9_T4_rig.blend, import -> Work_R9_T4,
# CreatureRig.Install(workspace.Work_R9_T4, "R9_T4", nil, true), puis joints corriges dans le repere du Core :
# EarL/EarR (+-0.98, 4.25, -0.65), WingL/WingR (+-1.3, 2.6, -0.55), Tail (0, 0.95, 0.95)
GROUPS_T4 = {'Head': ['Head', 'Disc_*', 'Eye_*', 'Pupil_*', 'Shine_*', 'EyeRim_*', 'Brow_*', 'BeakTop', 'Beak', 'Crown', 'CrownPt*', 'CrownGem'],
             'EarL': ['Tuft*_L'], 'EarR': ['Tuft*_R'],
             'WingL': ['WingRoot_L', 'Cloud*_L', 'Puff*_L', 'Zap*_L'], 'WingR': ['WingRoot_R', 'Cloud*_R', 'Puff*_R', 'Zap*_R'],
             'LegL': ['Foot_L', 'Toe*_L', 'Shin_L'], 'LegR': ['Foot_R', 'Toe*_R', 'Shin_R'],
             'Tail': ['TailC', 'Tail_L', 'Tail_R', 'TailTip']}
