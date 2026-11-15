# Storm Ram (R9_T5, Legendary) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R9_Refs/Ref_R9_T5_*.png)
# Laine = amas de nuages d'orage (dessus clair, dessous sombre) traverses d'eclairs lumineux sur les flancs,
# tete sortie devant (visage prune, museau lilas, yeux jaunes lumineux bien separes), cornes enroulees
# en spirale anguleuse d'eclair jaune avec pointes lumineuses, sabots dores, collier d'or a clochette.
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R9_Refs")
REF5 = {v: os.path.join(R, f"Ref_R9_T5_{v}.png") for v in ("front", "left", "back", "top")}
PAL5 = dict(
    wool=dict(color="#7e6ad6", noise=0.03, shade=0.2, top=0.2, mottle=("#8f7ce0", 0.25, 5)),
    wool_dark=dict(color="#3a2c7a", noise=0.03, shade=0.14),
    wool_light=dict(color="#b7a6ff", noise=0.025, shade=0.1, top=0.15),
    face=dict(color="#4a3a9e", noise=0.03, shade=0.12),
    shin=dict(color="#2a1e5a", noise=0.03, shade=0.12),
    muzzle=dict(color="#9e86ff", noise=0.03, shade=0.12),
    lilac=dict(color="#9e86ff", noise=0.03, shade=0.1),
    gold=dict(color="#ffcf3a", noise=0.03, shade=0.12, top=0.12, rim=-0.22),
    gold_dark=dict(color="#d99a1e", noise=0.03),
    bolt=dict(color="#ffe15a", noise=0.015, shade=0.08, top=0.15, rim=-0.25),
    hoof=dict(color="#ffc531", noise=0.03, shade=0.14, top=0.12, rim=-0.2),
    eye="#140f33", white="#ffffff",
    glow=dict(color="#ffd21a", glow=True), glow_cyan=dict(color="#3fd8ff", glow=True),
)
# nuages de laine : nom, taille, position, role
PUFFS5 = [
    ("PuffTop0", (2.5, 1.8, 1.2), (0, -0.85, 4.95), "wool_light"),
    ("PuffTop1", (3.0, 2.0, 1.35), (0, 0.75, 5.15), "wool_light"),
    ("PuffTop2", (2.5, 1.7, 1.15), (0, 2.25, 4.9), "wool_light"),
    ("PuffUp0_L", (1.4, 1.8, 1.3), (-1.45, -0.25, 4.55), "wool"),
    ("PuffUp1_L", (1.4, 1.9, 1.35), (-1.45, 1.55, 4.6), "wool_light"),
    ("PuffMid0_L", (1.15, 1.8, 1.8), (-1.75, -1.0, 3.55), "wool"),
    ("PuffMid1_L", (1.2, 2.0, 2.0), (-1.85, 0.75, 3.45), "wool"),
    ("PuffMid2_L", (1.1, 1.6, 1.75), (-1.7, 2.45, 3.6), "wool"),
    ("PuffLow0_L", (1.0, 1.9, 1.1), (-1.5, -0.2, 2.4), "wool_dark"),
    ("PuffLow1_L", (1.0, 1.9, 1.1), (-1.5, 1.7, 2.45), "wool_dark"),
]


def horn_pts5():
    # spirale de corne (cote -X) : part du dessus de la tete, recule, descend, revient devant ;
    # rayon alterne (zigzag d'eclair)
    pts = []
    n = 8
    for i in range(n + 1):
        t = i / n
        phi = math.radians(125 - 265 * t)
        r = 1.25 - 0.78 * t + (0.1 if i % 2 else -0.04) * (1 - t)
        x = 0.8 + 1.15 * min(1, t * 1.5)
        pts.append((-x, -2.45 + r * math.cos(phi), 5.25 + r * math.sin(phi)))
    return pts


def build_t5(m):
    MR = dict(mirror=True)
    # ---- laine : nuages d'orage, dessous sombre
    m.box("Body", size=(3.6, 4.4, 2.9), at=(0, 0.7, 3.55), role="wool", chamfer=0.9, faces={"bottom": "wool_dark"})
    m.box("Under", size=(2.8, 3.8, 1.0), at=(0, 0.7, 2.2), role="wool_dark", chamfer=0.35)
    for n, s, a, r in PUFFS5:
        kw = MR if n.endswith("_L") else {}
        m.box(n, size=s, at=a, role=r, chamfer=min(s) * 0.36, faces={"bottom": "wool_dark"} if r != "wool_dark" else None, **kw)
    m.box("Chest", size=(2.5, 1.3, 2.0), at=(0, -1.75, 3.15), role="wool_light", chamfer=0.6, faces={"bottom": "wool"})
    m.box("Rump", size=(2.6, 1.1, 2.3), at=(0, 2.95, 3.7), role="wool", chamfer=0.5, faces={"bottom": "wool_dark"})
    # ---- tete sortie devant : visage prune, museau lilas, meche de nuage, gemme d'orage
    m.box("Neck", size=(1.3, 1.2, 1.3), at=(0, -2.08, 4.45), role="shin", chamfer=0.25)
    m.box("Head", size=(1.75, 1.7, 1.95), at=(0, -2.8, 5.25), role="face", chamfer=0.38)
    m.box("Snout", size=(1.4, 1.1, 1.1), at=(0, -3.6, 4.6), role="muzzle", chamfer=0.28, taper=(0.86, 0.86), axis="y")
    m.box("Forelock", size=(1.9, 1.5, 0.8), at=(0, -2.65, 6.3), role="wool_light", chamfer=0.3)
    m.box("ForelockTuft", size=(0.6, 0.6, 0.45), at=(0, -3.2, 6.2), role="wool_light", chamfer=0.16)
    m.box("Gem", size=(0.3, 0.12, 0.3), at=(0, -3.52, 6.25), role="glow_cyan", rot=(0, 45, 0))
    # yeux jaunes lumineux bien separes, pupille sombre, reflet blanc (pas de bandeau de sourcils)
    m.box("Eye_L", size=(0.44, 0.1, 0.52), at=(-0.5, -3.68, 5.6), role="white", chamfer=0.03, **MR)
    m.box("Iris_L", size=(0.3, 0.08, 0.36), at=(-0.46, -3.73, 5.56), role="glow", **MR)
    m.box("Pupil_L", size=(0.14, 0.06, 0.2), at=(-0.45, -3.78, 5.54), role="eye", **MR)
    m.box("Shine_L", size=(0.1, 0.05, 0.1), at=(-0.55, -3.82, 5.66), role="white", **MR)
    # oreilles (rig EarL / EarR)
    m.box("Ear_L", size=(0.8, 0.28, 0.42), at=(-1.12, -2.95, 5.05), role="face", chamfer=0.06, taper=(1, 0.7), rot=(0, -28, -12),
          faces={"front": "lilac"}, **MR)
    # ---- cornes : spirale anguleuse d'eclair jaune, pointe lumineuse
    pts = horn_pts5()
    for i in range(len(pts) - 1):
        w = 0.66 - 0.05 * i
        m.beam(f"Horn{i}_L", start=pts[i], end=pts[i + 1], role="bolt", width=w, depth=w, taper=0.86, **MR)
    m.crystal("HornTip_L", radius=0.16, height=0.42, at=pts[-1], role="glow", sides=4, rot=(-40, -30, 0), **MR)
    # ---- collier d'or a clochette
    m.box("Collar", size=(1.55, 1.35, 0.3), at=(0, -2.16, 4.15), role="gold", chamfer=0.08)
    m.box("Bell", size=(0.55, 0.5, 0.55), at=(0, -2.93, 3.88), role="gold", chamfer=0.1, taper=(0.75, 0.75))
    m.box("BellGlow", size=(0.2, 0.08, 0.2), at=(0, -3.2, 3.83), role="glow_cyan")
    # ---- pattes : manchon de laine, jambe bleu nuit, sabot dore
    for n, y in (("LegF", -1.4), ("LegB", 2.05)):
        m.box(n + "_L", size=(0.9, 0.9, 1.45), at=(-0.95, y, 1.1), role="shin", chamfer=0.12, **MR)
        m.box(n + "Hoof_L", size=(1.15, 1.2, 0.5), at=(-0.95, y - 0.05, 0.25), role="hoof", chamfer=0.1, **MR)
        m.box(n + "Puff_L", size=(1.35, 1.4, 1.0), at=(-1.0, y, 1.9), role="wool", chamfer=0.4, **MR)
    # ---- queue : petit nuage et eclair
    m.box("Tail", size=(1.0, 0.8, 0.95), at=(0, 3.5, 4.35), role="wool_light", chamfer=0.32)
    m.beam("TailBoltA", start=(-0.1, 3.93, 4.6), end=(0.1, 4.18, 4.05), role="glow", width=0.16, depth=0.1, solo=True)
    m.beam("TailBoltB", start=(0.1, 4.18, 4.05), end=(-0.15, 4.23, 3.6), role="glow", width=0.14, depth=0.1, taper=0.4, solo=True)
    # ---- eclairs qui jaillissent de la laine (flancs)
    for name, x, w, zig in (("Bolt", -2.47, 0.24, [(0.15, 4.35), (0.85, 3.55), (0.35, 3.5), (1.05, 2.65)]),
                            ("BoltB", -2.35, 0.18, [(-1.2, 4.15), (-0.75, 3.55), (-1.1, 3.5), (-0.7, 2.95)])):
        for k in range(3):
            (y0, z0), (y1, z1) = zig[k], zig[k + 1]
            m.beam(f"{name}{k}_L", start=(x, y0, z0), end=(x, y1, z1), role="glow", width=w, depth=0.1,
                   taper=0.7 if k == 2 else 1, **MR)
    # ---- peinture
    m.stamp("Snout", "front", (0, 0.0), ["K.....K", ".......", ".......", "..K.K..", "...K..."], {"K": "shin"})
    for n in ("PuffTop0", "PuffTop1", "PuffTop2"):
        m.line(n, "top", [(-0.6, 0.1), (-0.2, 0.3), (0.2, 0.1), (0.6, 0.3)], "wool", 1)
    for n in ("PuffMid0_L", "PuffMid2_L", "PuffUp0_L"):
        m.line(n, "left", [(-0.4, 0.2), (0.0, 0.4), (0.4, 0.2)], "wool_light", 1)
    m.blob("Chest", "front", (-0.55, 0.45), 0.22, "wool", seed=4)
    m.blob("Chest", "front", (0.6, -0.35), 0.2, "wool", seed=7)
    for n in ("LegFHoof_L", "LegBHoof_L"):
        m.line(n, "front", [(0, -0.2), (0, 0.2)], "gold_dark", 1)
    m.line("Collar", "front", [(-0.6, 0.0), (0.6, 0.0)], "gold_dark", 1)
    return m


m5 = ropilot.model("R9_T5", px=8, reset=True)
m5.reference(REF5)
m5.palette(**PAL5)
build_t5(m5)
print(m5.build()); print(m5.check()); print(m5.compare()["report"])
ropilot.check_model(collection="R9_T5", max_lines=8)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R9_T5.blend"), copy=True)
# --- suite : exec(rigjoin.py), rig_join("R9_T5", GROUPS_T5), save R9_T5_rig.blend, import -> Work_R9_T5,
# CreatureRig.Install(workspace.Work_R9_T5, "R9_T5", nil, true), puis joints corriges dans le repere du Core :
# Tail (0, 4.3, 3.1), Head (0, 4.7, -2.0) ; pattes et oreilles laissees (hanches en haut des manchons, bord interieur)
# compare() final : face 0.80, dos 0.80, gauche 0.80, dessus 0.79 (tete sortie devant et cornes plus serrees que la reference, pour la lisibilite)
GROUPS_T5 = {'Head': ['Head', 'Snout', 'Forelock', 'ForelockTuft', 'Gem', 'Eye_*', 'Iris_*', 'Pupil_*', 'Shine_*', 'Horn*', 'HornTip_*'],
             'EarL': ['Ear_L'], 'EarR': ['Ear_R'],
             'LegFL': ['LegF_L', 'LegFHoof_L', 'LegFPuff_L'], 'LegFR': ['LegF_R', 'LegFHoof_R', 'LegFPuff_R'],
             'LegBL': ['LegB_L', 'LegBHoof_L', 'LegBPuff_L'], 'LegBR': ['LegB_R', 'LegBHoof_R', 'LegBPuff_R'],
             'Tail': ['Tail', 'TailBolt*']}
