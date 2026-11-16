# Wind-Up Penguin (R10_T3, Rare) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R10_Refs/Ref_R10_T3_*.png)
# Pingouin rond en fer-blanc : dos acier sombre, ventre et masque creme, bande de cuivre rivetee au cou,
# noeud papillon rouge horloge, bec et pattes de cuivre, ailes-nageoires (rig ArmL / ArmR, comme Frostling),
# grande cle a remonter doree plantee dans le dos (lobes de face), gemme turquoise au collier de la cle.
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R10_Refs")
REF3 = {v: os.path.join(R, f"Ref_R10_T3_{v}.png") for v in ("front", "left", "back", "top")}
PAL3 = dict(
    tin=dict(color="#3e4a58", noise=0.03, shade=0.16, mottle=("#465466", 0.18, 4), top=0.12),
    tin_light=dict(color="#56667a", noise=0.03, shade=0.12, top=0.1),
    tin_dark=dict(color="#2c3542", noise=0.025, shade=0.1),
    cream=dict(color="#f2ead6", noise=0.025, shade=0.12, top=0.08),
    cream_dark=dict(color="#d9ccb0", noise=0.025),
    steel=dict(color="#7c8c9c", noise=0.025, shade=0.12, top=0.12, rim=-0.2),
    copper=dict(color="#c8703a", noise=0.03, shade=0.12, top=0.12, rim=-0.2),
    copper_dark=dict(color="#8e4a26", noise=0.03, shade=0.12),
    brass=dict(color="#e0a84a", noise=0.03, shade=0.14, top=0.14, rim=-0.22),
    brass_light=dict(color="#f5cf7a", noise=0.03, shade=0.1, top=0.12, rim=-0.2),
    brass_dark=dict(color="#b8822e", noise=0.03, shade=0.1),
    red=dict(color="#c83a3a", noise=0.03, shade=0.12, top=0.1),
    red_dark=dict(color="#962a2e", noise=0.03),
    eye="#1a1e2e", white="#ffffff", blush="#f5a3a3",
    glow=dict(color="#5ae6d2", glow=True),
)


EGG = [(0.22, 1.7, 1.6), (0.7, 2.36, 2.2), (1.4, 2.5, 2.34), (2.0, 2.3, 2.2), (2.6, 2.0, 1.94), (3.0, 1.56, 1.5), (3.16, 1.1, 1.04)]


def loft_z(m, prefix, sl, role, front=None, chamfer=0.08):
    # tranches (z, largeur, profondeur) de bas en haut : chaque bloc part de sa tranche et se resserre vers la suivante
    names = []
    for i in range(len(sl) - 1):
        z0, w0, d0 = sl[i]
        z1, w1, d1 = sl[i + 1]
        n = f"{prefix}{i}"
        faces = {"bottom": "tin_dark"} if i == 0 else {}
        if front and front[i]:
            faces.update({"front": front[i], "bevel_front_top": front[i], "bevel_front_bottom": front[i]})
        m.box(n, size=(w0, d0, z1 - z0), at=(0, 0, (z0 + z1) / 2),
              role=role, taper=(w1 / w0, d1 / d0), chamfer=chamfer, faces=faces)
        names.append(n)
    return names


def build_t3(m, key=True):
    MR = dict(mirror=True)
    # ---- corps en oeuf (tranches) : ventre creme devant, masque creme sur la tete, calotte acier sombre
    loft_z(m, "Egg", EGG, "tin")
    # plaques creme posees sur le devant des tranches (le fer-blanc sombre les encadre) : ventre et masque
    for i, k, ww, hh, role in ((0, "Belly0", 0.7, 1.0, "cream"), (1, "Belly1", 0.72, 1.0, "cream"), (2, "Belly2", 0.7, 1.0, "cream"),
                               (3, "Mask", 0.74, 1.0, "cream"), (4, "MaskTop", 0.7, 0.75, "cream")):
        z0, w0, d0 = EGG[i]
        z1, w1, d1 = EGG[i + 1]
        h = (z1 - z0) * hh
        z1h = z0 + h
        d1h = d0 + (d1 - d0) * hh
        w1h = w0 + (w1 - w0) * hh
        a = math.degrees(math.atan2((d0 - d1h) / 2, h))
        m.box(k, size=(w0 * ww, 0.26, h + 0.08), at=(0, -(d0 + d1h) / 4, (z0 + z1h) / 2), role=role, taper=(w1h / w0, 1),
              chamfer=0.04, rot=(-a, 0, 0))
    # bande de cuivre rivetee au cou
    m.box("Band", size=(2.38, 2.28, 0.18), at=(0, 0, 2.0), role="copper", chamfer=0.4)
    # noeud papillon rouge horloge sous le bec
    m.box("BowKnot", size=(0.24, 0.24, 0.34), at=(0, -1.33, 1.99), role="brass", chamfer=0.05)
    m.box("Bow_L", size=(0.36, 0.42, 0.32), at=(-0.25, -1.21, 1.99), role="red", chamfer=0.06, **MR)
    # ---- visage : calotte sombre en V entre les yeux, gros yeux separes avec reflets, bec de cuivre
    m.box("Eye_L", size=(0.34, 0.42, 0.28), at=m.surface("MaskTop", "front", (-0.45, -0.16), sink=0.2), role="eye", chamfer=0.05, **MR)
    m.box("Shine_L", size=(0.14, 0.14, 0.05), at=m.surface("Eye_L", "top", (-0.06, 0.09)), role="white", **MR)
    m.box("Shine2_L", size=(0.07, 0.07, 0.05), at=m.surface("Eye_L", "top", (0.08, -0.1)), role="white", **MR)
    m.box("BeakTop", size=(0.68, 0.8, 0.36), at=(0, -1.2, 2.47), role="copper", chamfer=0.06, axis="y", taper=(0.42, 0.7))
    m.box("BeakLow", size=(0.4, 0.5, 0.34), at=(0, -1.18, 2.15), role="copper_dark", chamfer=0.04, axis="y", taper=(0.45, 0.7))
    # ---- rivets de cuivre sur la bande, rouages de laiton sur les flancs, boulon sur la tete
    for k, u in enumerate((-0.6, 0.0, 0.6)):
        m.box(f"BandRivet{k}_L", size=(0.13, 0.13, 0.2), at=m.surface("Band", "left", (u, 0.0), sink=0.14), role="brass_light", **MR)
    m.box("BackRivet_L", size=(0.13, 0.13, 0.2), at=m.surface("Band", "back", (0.45, 0.0), sink=0.14), role="brass_light", **MR)
    m.prism("SideGear_L", radius=0.4, height=0.2, at=m.surface("Egg1", "left", (-0.5, -0.02), sink=0.12), role="brass", sides=8, turn=22.5, **MR)
    m.prism("SideGearT_L", radius=0.45, height=0.16, at=m.surface("Egg1", "left", (-0.5, -0.02), sink=0.12), role="brass_dark", sides=8, **MR)
    m.prism("SideHub_L", radius=0.12, height=0.26, at=m.surface("Egg1", "left", (-0.5, -0.02), sink=0.12), role="copper", sides=6, **MR)
    m.prism("TopBolt", radius=0.16, height=0.16, at=(0, 0.05, 3.2), role="copper", sides=6)
    m.prism("TopBoltCap", radius=0.09, height=0.08, at=(0, 0.05, 3.3), role="brass_light", sides=6)
    # ---- ailes-nageoires (rig ArmL / ArmR)
    m.beam("Flipper_L", start=(-1.0, -0.12, 1.98), end=(-1.5, -0.2, 0.68), role="tin_light", width=0.24, depth=0.7, taper=0.55, chamfer=0.08, **MR)
    m.box("FlipCap_L", size=(0.34, 0.52, 0.34), at=(-1.06, -0.12, 1.86), role="copper", chamfer=0.08, **MR)
    # ---- pattes de cuivre (rig LegL / LegR)
    m.box("Leg_L", size=(0.42, 0.42, 0.3), at=(-0.5, -0.25, 0.26), role="tin_dark", chamfer=0.08, **MR)
    m.box("Foot_L", size=(0.6, 0.72, 0.24), at=(-0.52, -0.6, 0.12), role="copper", chamfer=0.06, axis="y", taper=(1.2, 1), **MR)
    for k, dx in enumerate((-0.2, 0.0, 0.2)):
        m.prism(f"Toe{k}_L", radius=0.08, height=0.24, at=(-0.52 + dx, -1.0, 0.07), role="copper_dark", sides=4, taper=0, rot=(90, 0, 0), **MR)
    # ---- petite queue (rig Tail)
    m.box("Tail", size=(0.7, 0.5, 0.24), at=(0, 1.1, 0.42), role="tin_dark", chamfer=0.07, axis="y", taper=(0.5, 0.6), rot=(-25, 0, 0))
    if key:
        # ---- grande cle doree plantee dans le haut du dos, qui depasse au-dessus de la tete, lobes de face
        m.prism("KeyCollar", radius=0.28, height=0.3, at=(0, 0.86, 2.62), role="copper", sides=8, rot=(-62, 0, 0))
        m.box("KeyGem", size=(0.16, 0.16, 0.16), at=(0, 0.98, 2.69), role="glow", rot=(-62, 45, 0))
        m.beam("KeyShaft", start=(0, 0.8, 2.5), end=(0, 1.12, 3.52), role="brass", width=0.18, depth=0.18)
        m.box("KeyHub", size=(0.38, 0.28, 0.3), at=(0, 1.14, 3.56), role="brass_dark", chamfer=0.06, rot=(-16, 0, 0))
        m.prism("KeyWing_L", radius=0.38, height=0.16, at=(-0.41, 1.17, 3.68), role="brass", sides=6, rot=(74, 0, 0), turn=30, **MR)
        m.prism("KeyHole_L", radius=0.14, height=0.2, at=(-0.45, 1.17, 3.69), role="brass_dark", sides=6, rot=(74, 0, 0), turn=30, **MR)
    # ---- peinture : plaques de fer-blanc rivetees, joues, ventre
    for face, sg in (("left", 1), ("right", -1)):
        for n in ("Egg1", "Egg2"):
            m.line(n, face, [(sg * 0.25, 0.4), (sg * 0.25, -0.4)], "tin_dark", 1)
            for v in (0.2, -0.1):
                m.rect(n, face, (sg * 0.38, v), (0.1, 0.1), "copper")
    for n in ("Egg1", "Egg2"):
        m.line(n, "back", [(0.0, 0.4), (0.0, -0.4)], "tin_dark", 1)
        for v in (0.2, -0.15):
            m.rect(n, "back", (0.14, v), (0.1, 0.1), "copper")
            m.rect(n, "back", (-0.14, v), (0.1, 0.1), "copper")
    m.rect("Mask", "front", (-0.55, 0.12), (0.2, 0.12), "blush")
    m.rect("Mask", "front", (0.55, 0.12), (0.2, 0.12), "blush")
    m.line("Belly1", "front", [(-0.5, 0.1), (0.5, 0.1)], "cream_dark", 1)
    m.line("Belly2", "front", [(-0.5, -0.05), (0.5, -0.05)], "cream_dark", 1)
    for u in (-0.9, -0.5, 0.5, 0.9):
        m.rect("Band", "front", (u, 0.0), (0.1, 0.1), "brass_light")
    m.stamp("Egg5", "top", (0, 0), ["C.C", "...", "C.C"], {"C": "copper"}, cell=0.12)
    m.line("Flipper_L", "left", [(0.0, 0.4), (0.0, -0.4)], "tin", 1)
    m.rect("FlipCap_L", "left", (0.0, 0.0), (0.12, 0.12), "brass_light")
    return m


m3 = ropilot.model("R10_T3", px=8, reset=True)
m3.reference(REF3)
m3.palette(**PAL3)
build_t3(m3)
print(m3.build()); print(m3.check()); print(m3.compare()["report"])
ropilot.check_model(collection="R10_T3", max_lines=10)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R10_T3.blend"), copy=True)
GROUPS_T3 = {'Head': ['Egg3', 'Egg4', 'Egg5', 'Mask', 'MaskTop', 'TopBolt', 'TopBoltCap', 'Eye_*', 'Shine*', 'Beak*'],
             'ArmL': ['Flipper_L', 'FlipCap_L'], 'ArmR': ['Flipper_R', 'FlipCap_R'],
             'LegL': ['Leg_L', 'Foot_L', 'Toe*_L'], 'LegR': ['Leg_R', 'Foot_R', 'Toe*_R'],
             'Tail': ['Tail']}

# compare() final : face 0.78, dos 0.79, gauche 0.84, dessus 0.82 (nageoires plus ecartees et cle plus basse que la
# reference, qui la plante tout droit sur la tete).
# --- suite : rig_join("R10_T3", GROUPS_T3), save R10_T3_rig.blend, import -> Work_R10_T3,
# CreatureRig.Install(workspace.Work_R10_T3, "R10_T3", nil, true), puis joints corriges dans le repere du Core :
# ArmL/ArmR (+-1.04, 1.9, -0.12), Head (0, 2.05, 0.05), LegL/LegR (+-0.5, 0.4, -0.25), Tail (0, 0.5, 0.92)
