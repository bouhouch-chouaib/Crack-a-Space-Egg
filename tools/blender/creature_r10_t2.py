# Cog Mouse (R10_T2, Uncommon) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R10_Refs/Ref_R10_T2_*.png,
# 2e generation : la 1re donnait une souris debout sur deux pattes).
# Souris jouet en laiton a quatre pattes : oreilles rondes en rouage (deux octogones decales = dents),
# queue en ressort (anneaux de cuivre le long d'une tige), cle a remonter papillon sur le dos, museau rose.
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R10_Refs")
REF2 = {v: os.path.join(R, f"Ref_R10_T2_{v}.png") for v in ("front", "left", "back", "top")}
PAL2 = dict(
    brass=dict(color="#e0a84a", noise=0.035, shade=0.16, mottle=("#d69c40", 0.2, 4), top=0.14),
    brass_light=dict(color="#f5cf7a", noise=0.03, shade=0.1, top=0.1),
    brass_dark=dict(color="#b8822e", noise=0.03, shade=0.12),
    copper=dict(color="#c8703a", noise=0.03, shade=0.12, top=0.1, rim=-0.2),
    copper_dark=dict(color="#8e4a26", noise=0.03, shade=0.12),
    steel=dict(color="#7c8c9c", noise=0.025, shade=0.12, top=0.12, rim=-0.2),
    steel_dark=dict(color="#3e4a58", noise=0.025, shade=0.1),
    pink=dict(color="#ff8fa8", noise=0.02, shade=0.08, top=0.1),
    pink_dark=dict(color="#e86a8a", noise=0.02),
    eye="#1e1a2e", white="#ffffff", blush="#ffb0a0", red="#c83a3a",
    glow=dict(color="#5ae6d2", glow=True),
)
TAIL = [(1.0, 0.8), (1.28, 0.86), (1.5, 1.06), (1.62, 1.36), (1.6, 1.66), (1.44, 1.88)]


def build_t2(m, key=True):
    MR = dict(mirror=True)
    # ---- corps : boite ronde en laiton, ventre plus clair, bande de cuivre rivetee
    m.box("Body", size=(1.36, 1.9, 1.18), at=(0, 0.08, 0.9), role="brass", chamfer=0.42, taper=(0.92, 0.95), faces={"bottom": "brass_dark"})
    m.box("Rump", size=(1.16, 0.5, 0.8), at=(0, 0.88, 0.8), role="brass", chamfer=0.3)
    m.box("Band", size=(1.44, 0.26, 1.22), at=(0, 0.0, 0.9), role="copper", chamfer=0.4)
    m.box("Chest", size=(0.95, 0.3, 0.7), at=(0, -0.8, 0.86), role="brass_light", chamfer=0.18)
    # ---- tete : bloc rond, museau en pointe rose
    m.box("Head", size=(1.24, 1.0, 1.02), at=(0, -0.8, 1.58), role="brass", chamfer=0.34, axis="y", taper=(0.84, 0.82))
    m.box("Snout", size=(0.74, 0.62, 0.56), at=(0, -1.4, 1.42), role="brass_light", chamfer=0.16, axis="y", taper=(0.5, 0.55))
    m.box("Nose", size=(0.28, 0.2, 0.24), at=(0, -1.72, 1.45), role="pink", chamfer=0.07)
    m.box("BrowBolt", size=(0.16, 0.08, 0.16), at=(0, -1.3, 1.95), role="glow", rot=(0, 45, 0))
    # yeux : gros carres sombres separes, deux reflets chacun
    m.box("Eye_L", size=(0.27, 0.08, 0.38), at=(-0.3, -1.31, 1.72), role="eye", chamfer=0.03, **MR)
    m.box("Shine_L", size=(0.12, 0.05, 0.12), at=(-0.34, -1.355, 1.82), role="white", **MR)
    m.box("Shine2_L", size=(0.06, 0.05, 0.06), at=(-0.24, -1.355, 1.62), role="white", **MR)
    # moustaches en fil d'acier
    for k, dz in enumerate((0.08, -0.06)):
        m.beam(f"Whisker{k}_L", start=(-0.16, -1.54, 1.42 + dz), end=(-0.74, -1.44, 1.46 + dz * 2.2), role="steel", width=0.05, depth=0.05, **MR)
    # ---- oreilles en rouage (rig EarL / EarR) : octogone + octogone tourne = 16 dents
    EX, EY, EZ = -0.64, -0.58, 2.0
    m.prism("Ear_L", radius=0.41, height=0.14, at=(EX, EY, EZ), role="brass", sides=8, rot=(90, 0, 0), turn=22.5, **MR)
    for k in (0, 1, 2, 3, 4, 5, 6):
        a = math.radians(k * 45)
        m.box(f"EarTooth{k}_L", size=(0.16, 0.1, 0.16), at=(EX + math.cos(a) * 0.43, EY, EZ + math.sin(a) * 0.43), role="brass_dark",
              rot=(0, -k * 45, 0), **MR)
    m.prism("EarIn_L", radius=0.28, height=0.06, at=(EX, EY - 0.08, EZ), role="pink", sides=8, rot=(90, 0, 0), turn=22.5, **MR)
    m.prism("EarHub_L", radius=0.11, height=0.1, at=(EX, EY - 0.11, EZ), role="copper", sides=6, rot=(90, 0, 0), **MR)
    m.box("EarPeg_L", size=(0.24, 0.24, 0.3), at=(-0.53, -0.56, 1.76), role="brass_dark", chamfer=0.05, **MR)
    # ---- pattes courtes, pieds de cuivre, rotule boulonnee
    for n, y in (("LegF", -0.5), ("LegB", 0.74)):
        m.box(n + "_L", size=(0.34, 0.38, 0.5), at=(-0.5, y, 0.4), role="brass_dark", chamfer=0.07, **MR)
        m.box(n + "Foot_L", size=(0.42, 0.52, 0.18), at=(-0.5, y - 0.06, 0.09), role="copper_dark", chamfer=0.06, **MR)
        m.prism(n + "Hip_L", radius=0.2, height=0.12, at=(-0.71, y, 0.64), role="steel", sides=8, rot=(0, 90, 0), **MR)
        m.prism(n + "Bolt_L", radius=0.08, height=0.06, at=(-0.78, y, 0.64), role="steel_dark", sides=6, rot=(0, 90, 0), **MR)
    # ---- queue en ressort (rig Tail) : tige fine, anneaux de cuivre, bout rose
    for i in range(len(TAIL) - 1):
        (y0, z0), (y1, z1) = TAIL[i], TAIL[i + 1]
        ey, ez = (y1 - y0) * 0.06, (z1 - z0) * 0.06
        m.beam(f"Tail{i}", start=(0, y0 - ey, z0 - ez), end=(0, y1 + ey, z1 + ez), role="pink_dark", width=0.11, depth=0.11)
        for t in (() if i in (0, len(TAIL) - 2) else (0.5,)):
            py, pz = y0 + (y1 - y0) * t, z0 + (z1 - z0) * t
            dy, dz = (y1 - y0), (z1 - z0)
            L = math.hypot(dy, dz)
            dy, dz = dy / L * 0.04, dz / L * 0.04
            m.beam(f"Coil{i}_{int(t * 4)}", start=(0, py - dy, pz - dz), end=(0, py + dy, pz + dz), role="copper", width=0.22, depth=0.22, chamfer=0.03)
    m.box("TailTip", size=(0.17, 0.22, 0.17), at=(0, 1.38, 1.91), role="pink", chamfer=0.04)
    m.box("TailCap", size=(0.36, 0.34, 0.36), at=(0, 1.08, 0.82), role="copper_dark", chamfer=0.06, rot=(-20, 0, 0))
    if key:
        # ---- cle a remonter papillon sur le dos (laiton clair), collier et gemme turquoise
        KY = 0.8
        m.prism("KeyCollar", radius=0.22, height=0.24, at=(0, KY, 1.43), role="copper", sides=8)
        m.box("KeyGem", size=(0.14, 0.14, 0.08), at=(0, KY, 1.58), role="glow")
        m.box("KeyShaft", size=(0.12, 0.12, 1.07), at=(0, KY, 2.07), role="steel", chamfer=0.02)
        # lobes de cote (plan YZ) : de face, la cle ne fait pas deux oreilles de plus
        m.box("KeyHub", size=(0.18, 0.26, 0.24), at=(0, KY, 2.62), role="brass_dark", chamfer=0.05)
        for nm, dy in (("KeyWingF", -0.3), ("KeyWingB", 0.3)):
            m.prism(nm, radius=0.27, height=0.12, at=(0, KY + dy, 2.8), role="brass_light", sides=6, rot=(0, 90, 0), turn=30)
            m.prism(nm.replace("Wing", "Hole"), radius=0.1, height=0.14, at=(0, KY + dy * 1.07, 2.81), role="brass_dark", sides=6, rot=(0, 90, 0), turn=30)
    # ---- peinture : rivets, joints de plaques, joues
    for face, sg in (("left", 1), ("right", -1)):
        for (u, v) in ((0.62, 0.28), (0.25, 0.32), (-0.15, 0.32), (-0.55, 0.28)):
            m.rect("Body", face, (sg * u, v), (0.12, 0.12), "brass_light")
            m.rect("Body", face, (sg * u + 0.06 * sg, v - 0.06), (0.06, 0.06), "brass_dark")
        m.line("Body", face, [(sg * 0.85, -0.05), (sg * 0.3, -0.05)], "brass_dark", 1)
        m.line("Body", face, [(sg * -0.3, -0.05), (sg * -0.85, -0.05)], "brass_dark", 1)
        m.rect("Head", face, (sg * -0.1, -0.1), (0.2, 0.2), "brass_dark")
    for (u, v) in ((-0.5, 0.0), (0.0, 0.0), (0.5, 0.0)):
        m.rect("Band", "left", (u, 0.3), (0.12, 0.12), "brass_light")
        m.rect("Band", "right", (u, 0.3), (0.12, 0.12), "brass_light")
    m.line("Body", "top", [(0.0, 0.9), (0.0, 0.25)], "brass_dark", 1)
    m.line("Body", "top", [(0.0, -0.35), (0.0, -0.9)], "brass_dark", 1)
    for u in (-0.45, 0.45):
        m.rect("Body", "top", (u, 0.6), (0.12, 0.12), "brass_light")
        m.rect("Body", "top", (u, -0.6), (0.12, 0.12), "brass_light")
    m.rect("Head", "front", (-0.42, -0.3), (0.22, 0.12), "blush")
    m.rect("Head", "front", (0.42, -0.3), (0.22, 0.12), "blush")
    m.stamp("Snout", "front", (0, -0.18), ["K..K", ".KK."], {"K": "eye"})
    m.line("Head", "top", [(-0.35, -0.2), (0.35, -0.2)], "brass_dark", 1)
    m.stamp("Chest", "front", (0, 0.0), ["L.L", "...", "L.L", "...", "L.L"], {"L": "brass_dark"}, cell=0.1)
    m.rect("Chest", "front", (0, 0.0), (0.1, 0.5), "brass")
    for n in ("LegFFoot_L", "LegBFoot_L"):
        m.stamp(n, "front", (0, 0.0), ["T.T.T"], {"T": "brass_light"})
    m.stamp("Rump", "back", (0, 0.15), ["S.S", "...", "S.S"], {"S": "brass_light"})
    return m


m2 = ropilot.model("R10_T2", px=8, reset=True)
m2.reference(REF2)
m2.palette(**PAL2)
build_t2(m2)
print(m2.build()); print(m2.check()); print(m2.compare()["report"])
ropilot.check_model(collection="R10_T2", max_lines=10)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R10_T2.blend"), copy=True)
GROUPS_T2 = {'Head': ['Head', 'Snout', 'Nose', 'BrowBolt', 'Eye_*', 'Shine*', 'Whisker*'],
             'EarL': ['Ear_L', 'EarTooth*_L', 'EarIn_L', 'EarHub_L', 'EarPeg_L'],
             'EarR': ['Ear_R', 'EarTooth*_R', 'EarIn_R', 'EarHub_R', 'EarPeg_R'],
             'LegFL': ['LegF_L', 'LegFFoot_L', 'LegFHip_L', 'LegFBolt_L'], 'LegFR': ['LegF_R', 'LegFFoot_R', 'LegFHip_R', 'LegFBolt_R'],
             'LegBL': ['LegB_L', 'LegBFoot_L', 'LegBHip_L', 'LegBBolt_L'], 'LegBR': ['LegB_R', 'LegBFoot_R', 'LegBHip_R', 'LegBBolt_R'],
             'Tail': ['Tail[0-9]', 'Coil*', 'TailTip', 'TailCap']}

# compare() final : face 0.76, dos 0.76, gauche 0.65, dessus 0.74 (0.79 / 0.70 avant de tourner les lobes de la cle
# de cote : de face, ils faisaient deux oreilles de plus ; moustaches et anneau de la cle de la reference plafonnent aussi).
# --- suite : exec(rigjoin.py), rig_join("R10_T2", GROUPS_T2), save R10_T2_rig.blend, import -> Work_R10_T2,
# CreatureRig.Install(workspace.Work_R10_T2, "R10_T2", nil, true), puis joints corriges dans le repere du Core :
# EarL/EarR (+-0.5, 1.78, -0.56), Head (0, 1.3, -0.45), pattes a la hanche y = 0.64, Tail (0, 0.82, 1.0)
