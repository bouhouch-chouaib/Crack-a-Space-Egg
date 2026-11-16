# Moss Bear (R12_T5, Legendary) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R12_Refs/Ref_R12_T5_*.png)
# Grand ours massif a quatre pattes : fourrure brun ecorce (ventre et interieur des pattes plus clairs), grosse
# bosse d'epaule, croupe large, tete large et basse devant les epaules, museau creme a truffe violet nuit,
# machoire (rig Jaw) qui s'ouvre sur une gueule sombre, petites oreilles rondes (rig EarL / EarR), yeux orange
# chanterelle separes a reflets ; plaques de mousse verte sur le dos qui coulent sur les flancs (dessus clair,
# bord sombre), amanites rouges a points creme et chapeaux turquoise lumineux qui poussent sur la bosse, les
# epaules et la croupe ; grosses pattes a coussinets violet nuit et griffes creme ; petite queue (rig Tail).
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R12_Refs")
REF5 = {v: os.path.join(R, f"Ref_R12_T5_{v}.png") for v in ("front", "left", "back", "top")}
PAL5 = dict(
    fur=dict(color="#8c6142", noise=0.035, shade=0.16, mottle=("#7a5338", 0.3, 4), top=0.12, streaks=("#6a4a30", 0.18, "v")),
    fur_dark=dict(color="#6a4a30", noise=0.03, shade=0.12),
    fur_light=dict(color="#b88c60", noise=0.03, shade=0.12, top=0.08),
    snout=dict(color="#f4eedc", noise=0.02, shade=0.1, top=0.08),
    snout_dark=dict(color="#e0d2b4", noise=0.02, shade=0.12),
    nose=dict(color="#2c2148", noise=0.02, shade=0.1, top=0.25),
    moss=dict(color="#6fb04a", noise=0.04, shade=0.14, mottle=("#86c45a", 0.35, 3), top=0.15, speckle=("#3e7a32", 0.06)),
    moss_dark=dict(color="#3e7a32", noise=0.035, shade=0.12, mottle=("#4e8c3c", 0.3, 3)),
    amanita=dict(color="#d8382e", noise=0.03, shade=0.14, top=0.12),
    stem=dict(color="#f4eedc", noise=0.025, shade=0.14),
    chant=dict(color="#f09a3c", noise=0.03, shade=0.14, top=0.12),
    claw=dict(color="#f4eedc", noise=0.015, shade=0.1),
    white="#ffffff", iris="#f09a3c", eye="#1e1430", shine="#ffffff", mouth="#2c1a24", tongue="#e06a7a",
    glow=dict(color="#3fe8c4", glow=True),
)
MR = dict(mirror=True)
HK, HC, HO = 1.15, (0, -4.6, 5.1), (0, -0.15, 0.1)


def amanita(m, name, at, s, tilt=(0, 0, 0), **kw):
    # amanite : pied creme, chapeau rouge chanfreine et tasse, anneau, points creme (pieces)
    x, y, z = at
    m.prism(name + "Stem", radius=0.32 * s, height=1.1 * s, at=(x, y, z + 0.4 * s), role="stem", sides=6, taper=0.85, rot=tilt, **kw)
    m.box(name + "Cap", size=(1.7 * s, 1.7 * s, 0.75 * s), at=(x + tilt[1] * 0.012 * s, y - tilt[0] * 0.012 * s, z + 1.15 * s),
          role="amanita", chamfer=0.3 * s, taper=(0.55, 0.55), rot=tilt, **kw)
    return name + "Cap"


def glowcap(m, name, at, s, tilt=(0, 0, 0), **kw):
    # chapeau lumineux turquoise sur pied creme
    x, y, z = at
    m.prism(name + "Stem", radius=0.2 * s, height=0.9 * s, at=(x, y, z + 0.3 * s), role="stem", sides=5, taper=0.8, rot=tilt, **kw)
    m.prism(name + "Cap", radius=0.62 * s, height=0.42 * s, at=(x + tilt[1] * 0.011 * s, y - tilt[0] * 0.011 * s, z + 0.85 * s),
            role="glow", sides=6, taper=0.45, rot=tilt, **kw)


def build_t5(m):
    # ---- corps : poitrail et bosse d'epaule, tonneau, croupe plus basse ; ventre clair
    m.box("Chest", size=(5.0, 3.6, 4.1), at=(0, -1.9, 4.15), role="fur", chamfer=0.9, faces={"bottom": "fur_light"})
    m.box("Hump", size=(4.4, 3.2, 1.6), at=(0, -1.5, 6.0), role="fur", chamfer=0.6, taper=(0.8, 0.85))
    m.box("Barrel", size=(4.8, 2.8, 3.9), at=(0, 0.9, 4.15), role="fur", chamfer=1.0, faces={"bottom": "fur_light"}, slope=(0, -0.6))
    m.box("Rump", size=(4.6, 2.9, 3.4), at=(0, 3.0, 3.85), role="fur", chamfer=1.15, faces={"bottom": "fur_light"}, slope=(0, -0.5))
    m.box("Belly", size=(3.4, 4.2, 0.5), at=(0, 0.6, 2.2), role="fur_light", chamfer=0.2)
    m.box("Ruff", size=(4.0, 1.0, 2.6), at=(0, -3.5, 3.98), role="fur_light", chamfer=0.45, taper=(0.85, 1))
    # ---- tete (rig Head) : crane large et bas devant les epaules, joues, museau creme, truffe
    m.box("Skull", size=(3.7, 2.8, 3.0), at=(0, -4.6, 5.1), role="fur", chamfer=0.8)
    m.box("Cheek_L", size=(0.7, 1.3, 1.1), at=(-1.62, -5.0, 4.4), role="fur", chamfer=0.28, **MR)
    m.box("Muzzle", size=(2.0, 1.7, 1.25), at=(0, -6.35, 4.5), role="snout", chamfer=0.35, taper=(0.85, 0.85), axis="y")
    m.box("Nose", size=(0.95, 0.55, 0.55), at=(0, -7.15, 5.0), role="nose", chamfer=0.15, taper=(0.75, 1))
    m.box("MouthIn", size=(1.3, 1.2, 0.15), at=(0, -6.3, 3.92), role="mouth")
    # machoire (rig Jaw) rentree sous le museau : charniere en haut a l'arriere ; langue rose dessus
    m.box("Jaw", size=(1.5, 1.35, 0.5), at=(0, -6.15, 3.66), role="snout_dark", chamfer=0.16, taper=(0.85, 0.9), axis="y")
    # yeux orange chanterelle, separes, poses sur la face avant du crane, au-dessus du museau ; petits sourcils releves
    m.box("Eye_L", size=(0.68, 0.1, 0.72), at=(-0.9, -6.03, 5.5), role="white", **MR)
    m.box("Iris_L", size=(0.5, 0.08, 0.56), at=(-0.86, -6.07, 5.46), role="iris", **MR)
    m.box("Pupil_L", size=(0.3, 0.06, 0.36), at=(-0.84, -6.1, 5.44), role="eye", **MR)
    m.box("Shine_L", size=(0.16, 0.05, 0.16), at=(-0.94, -6.13, 5.6), role="shine", **MR)
    m.box("Shine2_L", size=(0.08, 0.05, 0.08), at=(-0.74, -6.13, 5.34), role="shine", **MR)
    m.beam("Brow_L", start=(-1.3, -5.98, 5.98), end=(-0.55, -5.98, 6.08), role="fur_dark", width=0.22, depth=0.14, **MR)
    # oreilles rondes (rig EarL / EarR), interieur clair
    m.box("Ear_L", size=(1.15, 0.6, 1.05), at=(-1.4, -4.15, 6.8), role="fur", chamfer=0.34, rot=(0, -12, 0), **MR)
    m.box("EarIn_L", size=(0.68, 0.12, 0.62), at=(-1.38, -4.48, 6.75), role="fur_light", chamfer=0.1, rot=(0, -12, 0), **MR)
    # touffe de mousse et petit champignon lumineux sur le crane (suit la tete)
    m.box("HeadMoss", size=(1.6, 1.3, 0.35), at=(0.25, -4.1, 6.62), role="moss", chamfer=0.12, solo=True)
    glowcap(m, "HeadCap", (0.55, -4.0, 6.68), 0.75, tilt=(0, 12, 0), solo=True)
    # ---- pattes avant (rig LegFL / LegFR) : epaule, avant-bras epais qui s'affine au poignet, large patte
    m.box("Shoulder_L", size=(1.6, 2.5, 2.6), at=(-2.1, -2.1, 4.05), role="fur", chamfer=0.72, **MR)
    m.beam("FArm_L", start=(-2.1, -1.95, 3.6), end=(-2.1, -2.45, 0.9), role="fur", width=1.75, depth=1.95, chamfer=0.4, taper=0.82, **MR)
    m.box("FTuft_L", size=(1.4, 0.6, 1.2), at=(-2.1, -1.05, 2.5), role="fur_light", chamfer=0.2, taper=(0.8, 1), **MR)
    m.box("FPaw_L", size=(2.0, 2.5, 0.85), at=(-2.1, -2.75, 0.42), role="fur_dark", chamfer=0.28, **MR)
    m.box("FPad_L", size=(1.2, 0.12, 0.45), at=(-2.1, -4.0, 0.4), role="nose", **MR)
    # ---- pattes arriere (rig LegBL / LegBR) : cuisse ronde, jambe inclinee (talon en arriere), patte
    m.box("Thigh_L", size=(1.6, 2.8, 3.1), at=(-1.95, 2.75, 3.45), role="fur", chamfer=0.9, **MR)
    m.beam("BLeg_L", start=(-2.05, 3.35, 2.5), end=(-2.05, 2.55, 0.85), role="fur", width=1.6, depth=1.8, chamfer=0.35, taper=0.85, **MR)
    m.box("BPaw_L", size=(1.9, 2.3, 0.8), at=(-2.05, 2.3, 0.4), role="fur_dark", chamfer=0.26, **MR)
    for k, dx in enumerate((-0.55, 0.0, 0.55)):
        m.prism(f"FClaw{k}_L", radius=0.15, height=0.45, at=(-2.1 + dx, -4.1, 0.3), role="claw", sides=4, taper=0, rot=(90, 0, 0), **MR)
        m.prism(f"BClaw{k}_L", radius=0.14, height=0.4, at=(-2.05 + dx * 0.9, 1.08, 0.28), role="claw", sides=4, taper=0, rot=(90, 0, 0), **MR)
    # ---- petite queue (rig Tail)
    m.box("Tail", size=(1.0, 0.9, 0.9), at=(0, 4.55, 4.4), role="fur", chamfer=0.3, rot=(-20, 0, 0))
    # ---- mousse : coussins irreguliers sur la bosse, le dos et la croupe (la fourrure reste visible aux bords),
    # mottes qui coulent sur les flancs, touffes
    def moss(name, at, w, l, h=0.55, rot=(0, 0, 0)):
        # coussin de mousse : bloc evase (dessus plus etroit), deux bosses posees dessus
        x, y, z = at
        m.box(name, size=(w, l, h), at=at, role="moss", chamfer=0.25, taper=(0.82, 0.82), faces={"bottom": "moss_dark"}, rot=rot, solo=True)
        m.box(name + "a", size=(w * 0.42, l * 0.45, h * 0.8), at=(x - w * 0.24, y + l * 0.18, z + h * 0.5), role="moss", chamfer=0.16,
              taper=(0.75, 0.75), rot=(rot[0], rot[1], 17), solo=True)
        m.box(name + "b", size=(w * 0.32, l * 0.34, h * 0.6), at=(x + w * 0.28, y - l * 0.26, z + h * 0.4), role="moss_dark", chamfer=0.12,
              taper=(0.75, 0.75), rot=(rot[0], rot[1], -22), solo=True)
    moss("MossHump", (-0.15, -1.6, 6.85), 3.4, 2.7)
    moss("MossBack", (0.35, 0.75, 6.05), 3.5, 2.3, rot=(-8, 0, 0))
    moss("MossRump", (-0.45, 2.95, 5.38), 3.0, 2.2, rot=(-10, 0, 0))
    # mottes qui coulent sur les flancs (larges en haut, etroites en bas)
    for k, (y, ln, z) in enumerate(((-2.0, 1.1, 5.9), (0.45, 1.4, 5.5), (2.6, 0.95, 5.05))):
        m.box(f"MossDrip{k}_L", size=(0.4, 0.8, ln), at=(-2.33, y, z - ln / 2 + 0.2), role="moss", chamfer=0.12, taper=(1, 1.9),
              faces={"bottom": "moss_dark"}, **MR)
    # mousse sur les epaules
    m.box("MossShoulder_L", size=(1.4, 1.9, 0.38), at=(-2.15, -2.05, 5.22), role="moss", chamfer=0.12, **MR)
    # ---- champignons : grande amanite sur la bosse, deux petites, chapeaux lumineux en grappes
    amanita(m, "AmBig", (-0.7, -1.4, 6.95), 1.3, tilt=(4, -10, 0), solo=True)
    amanita(m, "AmMid", (1.25, 1.2, 6.0), 0.95, tilt=(-6, 14, 0), solo=True)
    amanita(m, "AmSmall", (-1.0, 2.7, 5.55), 0.7, tilt=(-8, -16, 0), solo=True)
    amanita(m, "AmShoulder", (2.2, -2.15, 5.22), 0.6, tilt=(0, 24, 0), solo=True)
    glowcap(m, "GlowA", (0.85, -2.2, 6.95), 0.9, tilt=(6, 10, 0), solo=True)
    glowcap(m, "GlowB", (1.25, -0.6, 6.8), 0.7, tilt=(0, 14, 0), solo=True)
    glowcap(m, "GlowC", (-0.6, 0.3, 6.15), 0.75, tilt=(-4, -6, 0), solo=True)
    glowcap(m, "GlowD", (0.4, 3.0, 5.4), 0.85, tilt=(-10, 8, 0), solo=True)
    glowcap(m, "GlowE", (-0.5, 3.6, 5.2), 0.55, tilt=(-14, -6, 0), solo=True)
    glowcap(m, "GlowF", (-2.2, -1.75, 5.25), 0.55, tilt=(0, -26, 0), solo=True)
    # petite chanterelle orange sur la croupe
    m.prism("ChantStem", radius=0.18, height=0.5, at=(1.7, 3.0, 5.2), role="chant", sides=5, taper=1.4, solo=True)
    m.prism("ChantCap", radius=0.45, height=0.25, at=(1.7, 3.0, 5.55), role="chant", sides=6, taper=0.6, solo=True)
    # ---- tete agrandie de HK autour du centre du crane (lisible de loin et de profil), puis avancee et relevee
    head = ["Skull", "Cheek_L", "Muzzle", "Nose", "MouthIn", "Jaw", "Eye_L", "Iris_L", "Pupil_L", "Shine_L", "Shine2_L", "Brow_L",
            "Ear_L", "EarIn_L", "HeadMoss", "HeadCapStem", "HeadCapCap"]  # les jumeaux _R suivent
    m.scale(HK, names=head)
    for n in head:
        m.move(n, by=tuple(HC[i] * (1 - HK) + HO[i] for i in range(3)))
    # ---- peinture : points creme des amanites, truffe, griffes, coussinets, sourire
    for cap, s in (("AmBigCap", 1.25), ("AmMidCap", 0.95), ("AmSmallCap", 0.7), ("AmShoulderCap", 0.6)):
        for (u, v) in ((-0.25, 0.15), (0.2, -0.2), (0.05, 0.3)):
            m.rect(cap, "top", (u * s, v * s), (0.22 * s, 0.22 * s), "stem")
        for f in ("front", "left", "right", "back"):
            m.rect(cap, f, (-0.35 * s, 0.0), (0.22, 0.2), "stem")
            m.rect(cap, f, (0.3 * s, 0.05), (0.18, 0.18), "stem")
    m.line("Muzzle", "front", [(-0.4, -0.15), (-0.15, -0.3), (0.0, -0.22), (0.15, -0.3), (0.4, -0.15)], "mouth", 1)
    m.line("Muzzle", "front", [(0.0, 0.3), (0.0, -0.22)], "mouth", 1)
    m.rect("Jaw", "top", (0.0, 0.0), (0.8, 0.75), "tongue")
    m.rect("Nose", "top", (-0.15, 0.0), (0.2, 0.12), "#5a4a8a")
    for p in ("Chest", "Rump", "Barrel"):
        m.blob(p, "left", (0.3, -0.6), 0.45, "fur_dark", seed=3)
    return m


m5 = ropilot.model("R12_T5", px=8, reset=True)
m5.reference(REF5)
m5.palette(**PAL5)
build_t5(m5)
print(m5.build()); print(m5.check()); print(m5.compare()["report"])
ropilot.check_model(collection="R12_T5", max_lines=10)


def save_only(col_name, fname):
    # n'ecrit que la collection de la creature (pas les modeles des autres taches ni les references)
    col = bpy.data.collections[col_name]
    bpy.data.libraries.write(os.path.join(ropilot.FILES_DIR, fname), {col}, fake_user=True, compress=True)


save_only("R12_T5", "R12_T5.blend")

GROUPS_T5 = {'Head': ['Skull', 'Cheek_*', 'Brow_*', 'Muzzle', 'Nose', 'MouthIn', 'Eye_*', 'Iris_*', 'Pupil_*',
                      'Shine_*', 'Shine2_*', 'HeadMoss', 'HeadCap*'],
             'Jaw': ['Jaw', 'Tongue'],
             'EarL': ['Ear_L', 'EarIn_L'], 'EarR': ['Ear_R', 'EarIn_R'],
             'LegFL': ['Shoulder_L', 'FArm_L', 'FTuft_L', 'FPaw_L', 'FPad_L', 'FClaw*_L', 'MossShoulder_L', 'GlowF*'],
             'LegFR': ['Shoulder_R', 'FArm_R', 'FTuft_R', 'FPaw_R', 'FPad_R', 'FClaw*_R', 'MossShoulder_R', 'AmShoulder*'],
             'LegBL': ['Thigh_L', 'BLeg_L', 'BPaw_L', 'BClaw*_L'], 'LegBR': ['Thigh_R', 'BLeg_R', 'BPaw_R', 'BClaw*_R'],
             'Tail': ['Tail']}
# --- suite : exec(rigjoin.py), rig_join("R12_T5", GROUPS_T5), save_only("R12_T5", "R12_T5_rig.blend"), import -> Work_R12_T5,
# CreatureRig.Install(workspace.Work_R12_T5, "R12_T5", nil, true), puis joints corriges dans le repere du Core
# joints corriges dans le repere du Core : LegFL/FR (+-2.1, 4.7, -1.06) a l'epaule, LegBL/BR (+-2.05, 4.3, 3.99) a la hanche,
# Head (0, 4.9, -2.3) au cou, Jaw (0, 3.83, -4.4) a la charniere, EarL/R (+-1.5, 6.6, -2.81) a la base, Tail (0, 4.5, 5.55) a la racine
# compare() final : face 0.72, dos 0.72, gauche 0.73, dessus 0.78 : la reference est un ours chibi en forme de caisse (tete
# enorme, 6.5 de large) ; ici ours massif a bosse d'epaule, tete agrandie (HK = 1.15) mais proportionnee, pour rester lisible.
# Portrait : rbxassetid://125011502377456
