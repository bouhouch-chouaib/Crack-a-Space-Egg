# Zap Pup (R9_T2, Uncommon) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R9_Refs/Ref_R9_T2_*.png)
# compare() final : face 0.85, dos 0.85, gauche 0.81, dessus 0.83
import ropilot, bpy, os
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R9_Refs")
REF2 = {v: os.path.join(R, f"Ref_R9_T2_{v}.png") for v in ("front", "left", "back", "top")}
PAL2 = dict(
    fur=dict(color="#ffc83a", noise=0.035, shade=0.16, mottle=("#ffbb2a", 0.2, 4), top=0.14),
    fur_dark=dict(color="#f0a92a", noise=0.03, shade=0.12),
    fur_light=dict(color="#ffe48a", noise=0.03, shade=0.1),
    cream=dict(color="#fff6d8", noise=0.025, shade=0.1),
    violet=dict(color="#7b63dc", noise=0.035, shade=0.14, top=0.1),
    violet_light=dict(color="#9e86ff", noise=0.03, shade=0.1),
    navy=dict(color="#2a1e5a", noise=0.02),
    bolt=dict(color="#fff176", noise=0.015, shade=0.08, top=0.15, rim=-0.3),
    eye="#22184d", white="#ffffff", blush="#ff9ab8", tongue="#ff6f8e", nose="#2a1e5a",
    glow=dict(color="#ffd21a", glow=True), glow_cyan=dict(color="#3fd8ff", glow=True),
)


def build_t2(m):
    MR = dict(mirror=True)
    # ---- body: round loaf, cream belly and chest fluff
    m.box("Body", size=(1.7, 2.85, 1.45), at=(0, -0.05, 1.1), role="fur", chamfer=0.45, taper=(0.92, 0.95))
    m.box("Belly", size=(1.2, 1.9, 0.3), at=(0, 0.05, 0.42), role="cream", chamfer=0.1)
    m.box("Chest", size=(0.95, 0.4, 0.8), at=(0, -1.38, 1.0), role="cream", chamfer=0.16, taper=(0.75, 1))
    m.prism("ChestTuft", radius=0.22, height=0.32, at=(0, -1.55, 0.62), role="cream", sides=4, taper=0, rot=(180, 0, 0))
    # ---- collar with a glowing bolt tag
    m.box("Collar", size=(1.55, 1.1, 0.24), at=(0, -0.72, 1.55), role="violet", chamfer=0.06)
    m.box("TagRing", size=(0.22, 0.14, 0.2), at=(0, -1.62, 1.42), role="navy")
    m.box("TagA", size=(0.16, 0.1, 0.34), at=(-0.04, -1.68, 1.25), role="glow", rot=(0, -28, 0))
    m.box("TagB", size=(0.16, 0.1, 0.3), at=(0.05, -1.69, 1.03), role="glow", rot=(0, -28, 0))
    # ---- head: big chibi block, fluffy jowls, electric tuft
    m.box("Head", size=(2.0, 1.5, 1.5), at=(0, -0.9, 2.12), role="fur", chamfer=0.42)
    m.box("Jowl", size=(1.7, 0.9, 0.55), at=(0, -1.15, 1.55), role="fur_light", chamfer=0.22)
    m.box("Snout", size=(1.0, 0.5, 0.58), at=(0, -1.75, 1.8), role="cream", chamfer=0.17, taper=(0.9, 0.9), axis="y")
    m.box("Nose", size=(0.4, 0.22, 0.24), at=(0, -2.0, 2.02), role="nose", chamfer=0.06)
    m.box("Tongue", size=(0.26, 0.12, 0.3), at=(0.12, -2.01, 1.52), role="tongue", chamfer=0.04, solo=True)
    m.prism("Tuft1", radius=0.2, height=0.42, at=(0, -1.15, 2.9), role="bolt", sides=4, taper=0, rot=(18, 0, 0))
    m.prism("Tuft2_L", radius=0.16, height=0.32, at=(-0.3, -1.05, 2.86), role="fur_dark", sides=4, taper=0, rot=(12, -22, 0), **MR)
    # big square happy eyes (geometry): dark square, two shines
    m.box("Eye_L", size=(0.44, 0.1, 0.48), at=(-0.45, -1.66, 2.3), role="eye", chamfer=0.03, **MR)
    m.box("Shine_L", size=(0.2, 0.06, 0.2), at=(-0.53, -1.72, 2.41), role="white", **MR)
    m.box("Shine2_L", size=(0.1, 0.06, 0.1), at=(-0.34, -1.72, 2.18), role="white", **MR)
    # ---- floppy violet ears (rig EarL / EarR), lighter inside
    m.box("Ear_L", size=(0.44, 0.8, 1.3), at=(-1.05, -0.85, 2.75), role="violet", chamfer=0.16, taper=(0.75, 0.75), rot=(0, 15, 0),
          pivot="top", faces={"front": "violet_light"}, **MR)
    m.box("EarTip_L", size=(0.5, 0.86, 0.22), at=(-1.33, -0.85, 1.52), role="violet_light", chamfer=0.06, rot=(0, 15, 0), **MR)
    # ---- legs with cream paws
    for n, y in (("LegF", -0.88), ("LegB", 0.72)):
        m.box(n + "_L", size=(0.58, 0.6, 0.75), at=(-0.48, y, 0.5), role="fur", chamfer=0.1, **MR)
        m.box(n + "Paw_L", size=(0.66, 0.72, 0.26), at=(-0.48, y - 0.05, 0.13), role="cream", chamfer=0.08, **MR)
    # ---- flat zig-zag lightning-bolt tail (rig Tail) with a violet band and a glowing tip
    m.box("TailBand", size=(0.5, 0.36, 0.5), at=(0, 1.32, 1.6), role="violet", chamfer=0.08, rot=(-40, 0, 0))
    m.beam("Tail0", start=(0, 1.15, 1.42), end=(0, 1.85, 2.32), role="bolt", width=0.26, depth=0.5)
    m.beam("Tail1", start=(0, 2.02, 2.3), end=(0, 1.32, 2.3), role="bolt", width=0.26, depth=0.3)
    m.beam("Tail2", start=(0, 1.42, 2.22), end=(0, 1.98, 2.98), role="bolt", width=0.26, depth=0.46, taper=0.55)
    m.beam("TailTip", start=(0, 1.93, 2.9), end=(0, 2.08, 3.22), role="glow", width=0.2, depth=0.24, taper=0.2)
    # ---- paint
    m.blob("Body", "top", (0.0, 0.55), 0.38, "violet", rough=0.3, seed=3)
    m.blob("Body", "top", (0.3, -0.1), 0.18, "violet", rough=0.3, seed=5)
    for face, sg in (("left", 1), ("right", -1)):
        m.line("Body", face, [(sg * 0.65, 0.4), (sg * 0.25, 0.05), (sg * 0.45, 0.0), (sg * 0.05, -0.35)], "fur_dark", 2)
        m.rect("Body", face, (sg * -0.6, 0.25), (0.16, 0.16), "fur_light")
        m.rect("Body", face, (sg * -0.35, -0.15), (0.12, 0.12), "fur_light")
    m.rect("Head", "front", (-0.72, -0.48), (0.26, 0.14), "blush")
    m.rect("Head", "front", (0.72, -0.48), (0.26, 0.14), "blush")
    m.stamp("Snout", "front", (0, -0.08), ["K...K", ".KKK."], {"K": "eye"})
    for sd in ("L", "R"):
        for n in ("LegFPaw_", "LegBPaw_"):
            m.stamp(n + sd, "front", (0, 0.0), ["T.T.T"], {"T": "fur_dark"})
    m.line("Collar", "front", [(-0.6, 0.0), (0.6, 0.0)], "violet_light", 1)
    return m


m = ropilot.model("R9_T2", px=8, reset=True)
m.reference(REF2)
m.palette(**PAL2)
build_t2(m)
print(m.build()); print(m.check()); print(m.compare()["report"])
ropilot.check_model(collection="R9_T2", max_lines=8)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R9_T2.blend"), copy=True)
# --- suite : exec(rigjoin.py), rig_join("R9_T2", GROUPS_T2), save R9_T2_rig.blend, import -> Work_R9_T2,
# CreatureRig.Install(workspace.Work_R9_T2, "R9_T2", nil, true), puis joints corriges a la main :
# Tail (0, 1.5, 1.2), EarL/EarR (+-1.0, 2.7, -0.85) dans le repere du Core
GROUPS_T2 = {'Head': ['Head', 'Jowl', 'Snout', 'Nose', 'Tongue', 'Tuft*', 'Eye_*', 'Shine*'],
             'EarL': ['Ear_L', 'EarTip_L'], 'EarR': ['Ear_R', 'EarTip_R'],
             'LegFL': ['LegF_L', 'LegFPaw_L'], 'LegFR': ['LegF_R', 'LegFPaw_R'],
             'LegBL': ['LegB_L', 'LegBPaw_L'], 'LegBR': ['LegB_R', 'LegBPaw_R'],
             'Tail': ['TailBand', 'Tail0', 'Tail1', 'Tail2', 'TailTip']}
