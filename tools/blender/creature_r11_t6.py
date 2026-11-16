# Licorice Panther (R11_T6, Mythic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R11_Refs/Ref_R11_T6_*.png)
# Panthere elancee noir-reglisse a reflets violets (torsades de reglisse peintes en diagonale sur les flancs),
# poitrail puissant, epaules et cuisses musclees, pattes fines aux griffes en sucre d'orge (crochet blanc, pointe
# rouge), collier en sucre d'orge raye rouge et blanc a pendentif menthe lumineux, tete de chat large aux joues
# marquees, yeux menthe lumineux separes (pupille fendue, reflet), truffe raisin, moustaches en sucre file,
# oreilles pointues a interieur raisin (rig EarL / EarR), longue queue fine qui s'affine et finit en spirale de
# reglisse (rouleau noir et violet).
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R11_Refs")
REF6 = {v: os.path.join(R, f"Ref_R11_T6_{v}.png") for v in ("front", "left", "back", "top")}
PAL6 = dict(
    lic=dict(color="#24161c", noise=0.035, shade=0.14, mottle=("#3d2352", 0.35, 3), top=0.22, rim=-0.3),
    lic_light=dict(color="#4a2c66", noise=0.03, shade=0.1, top=0.12, rim=-0.2),
    lic_violet=dict(color="#7a4fc0", noise=0.03, shade=0.12, top=0.12),
    grape=dict(color="#9b6be0", noise=0.025, shade=0.1),
    cane=dict(color="#fff6ec", noise=0.02, shade=0.1, top=0.1),
    cane_red=dict(color="#e8344e", noise=0.02, shade=0.12, top=0.12),
    eye="#120a10", shine="#ffffff",
    glow=dict(color="#2fe0bf", glow=True),
)
TAIL6 = [(0, 2.75, 5.45), (0, 3.75, 5.3), (0, 4.65, 4.65), (0, 5.25, 3.6), (0, 5.45, 2.45)]
TW6 = [0.72, 0.62, 0.54, 0.47, 0.42]
SPC = (0.0, 4.55, 2.4)        # centre de la spirale du bout de la queue (plan YZ)


def mid(a, b, t=0.5):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def claws(m, pre, x, y, z):
    # griffes en sucre d'orge : crochet blanc, pointe rouge
    for k, dx in enumerate((-0.3, 0.0, 0.3)):
        a = (x + dx, y, z + 0.18)
        b = (x + dx, y - 0.3, z + 0.02)
        c = (x + dx, y - 0.48, z - 0.14)
        n = f"{pre}Claw{k}"
        m.beam(f"{n}a_L", start=a, end=b, role="cane", width=0.17, depth=0.17, mirror=True)
        m.beam(f"{n}b_L", start=b, end=c, role="cane_red", width=0.15, depth=0.15, taper=0.35, mirror=True)


def build_t6(m):
    MR = dict(mirror=True)
    # ---- corps elance : poitrail, torse, hanches ; ventre un peu plus clair
    m.box("Chest", size=(2.5, 2.6, 2.9), at=(0, -2.2, 5.35), role="lic", chamfer=0.6, faces={"bottom": "lic_light"})
    m.box("Torso", size=(2.15, 3.4, 2.3), at=(0, 0.3, 5.15), role="lic", chamfer=0.5, rot=(-7, 0, 0), faces={"bottom": "lic_light"})
    m.box("Hips", size=(2.35, 1.9, 2.45), at=(0, 2.0, 5.0), role="lic", chamfer=0.55, faces={"bottom": "lic_light"})
    # ---- cou et collier en sucre d'orge (bandes rouges et blanches), pendentif menthe lumineux
    N0, N1 = (0, -2.75, 6.0), (0, -3.45, 7.2)
    m.beam("Neck", start=N0, end=N1, role="lic", width=1.45, depth=1.45, chamfer=0.3)
    for i, (t0, t1, role) in enumerate(((0.18, 0.3, "cane_red"), (0.3, 0.42, "cane"), (0.42, 0.54, "cane_red"))):
        m.beam(f"Collar{i}", start=mid(N0, N1, t0), end=mid(N0, N1, t1), role=role, width=1.62, depth=1.62, chamfer=0.25)
    m.box("Gem", size=(0.42, 0.3, 0.5), at=(0, -3.83, 5.95), role="glow", rot=(0, 45, 0))
    m.box("GemCap", size=(0.3, 0.3, 0.16), at=(0, -3.7, 6.27), role="cane", chamfer=0.04)
    # ---- tete de chat (rig Head) : crane, joues, museau, truffe, menton
    m.box("Head", size=(2.35, 2.0, 1.75), at=(0, -4.05, 7.55), role="lic", chamfer=0.42)
    m.box("Cheeks", size=(2.6, 1.3, 0.95), at=(0, -4.45, 7.0), role="lic", chamfer=0.32)
    m.box("Muzzle", size=(1.3, 0.85, 0.8), at=(0, -5.35, 7.0), role="lic_light", chamfer=0.22)
    m.box("Nose", size=(0.52, 0.22, 0.3), at=(0, -5.78, 7.32), role="grape", chamfer=0.06, taper=(0.6, 1))
    m.box("Chin", size=(0.9, 0.6, 0.35), at=(0, -5.2, 6.52), role="lic_light", chamfer=0.1)
    # yeux menthe lumineux en amande, separes, pupille fendue, reflet ; sourcils droits (regard fier)
    m.box("Eye_L", size=(0.56, 0.1, 0.38), at=(-0.5, -5.07, 7.7), role="glow", **MR)
    m.box("Pupil_L", size=(0.13, 0.08, 0.34), at=(-0.46, -5.12, 7.69), role="eye", **MR)
    m.box("Shine_L", size=(0.12, 0.06, 0.12), at=(-0.58, -5.15, 7.8), role="shine", **MR)
    m.beam("Brow_L", start=(-0.8, -4.98, 8.0), end=(-0.24, -4.98, 8.0), role="lic_violet", width=0.16, depth=0.16, **MR)
    # moustaches en sucre file
    for k, dz in enumerate((0.1, -0.12)):
        m.beam(f"Whisker{k}_L", start=(-0.55, -5.55, 7.0 + dz), end=(-1.5, -5.3, 7.1 + dz * 2.2), role="cane", width=0.07, depth=0.07, **MR)
    # oreilles pointues (rig EarL / EarR), interieur raisin
    m.pyramid("Ear_L", size=(0.85, 0.55, 1.05), at=(-0.68, -3.85, 8.55), role="lic", **MR)
    m.pyramid("EarIn_L", size=(0.5, 0.12, 0.65), at=(-0.68, -4.12, 8.48), role="grape", **MR)
    # ---- pattes avant (rig LegFL / LegFR) : epaule musclee, patte fine, pied, griffes en sucre d'orge
    m.box("Shoulder_L", size=(0.95, 1.45, 1.9), at=(-0.9, -2.55, 4.6), role="lic", chamfer=0.32, **MR)
    m.beam("Foreleg_L", start=(-0.9, -2.65, 4.0), end=(-0.9, -2.95, 0.5), role="lic", width=0.82, depth=0.86, chamfer=0.14, taper=0.78, **MR)
    m.box("FPaw_L", size=(0.98, 1.2, 0.55), at=(-0.9, -3.12, 0.28), role="lic_light", chamfer=0.16, **MR)
    claws(m, "F", -0.9, -3.72, 0.22)
    # ---- pattes arriere (rig LegBL / LegBR) : cuisse musclee, jarret, patte, pied, griffes
    m.box("Thigh_L", size=(1.0, 1.9, 2.3), at=(-0.95, 1.6, 4.1), role="lic", chamfer=0.38, rot=(-12, 0, 0), **MR)
    m.beam("Hock_L", start=(-0.95, 2.0, 3.3), end=(-0.95, 2.4, 1.35), role="lic", width=0.74, depth=0.8, chamfer=0.14, **MR)
    m.beam("Shank_L", start=(-0.95, 2.4, 1.45), end=(-0.95, 2.0, 0.45), role="lic", width=0.66, depth=0.7, chamfer=0.12, **MR)
    m.box("BPaw_L", size=(0.95, 1.15, 0.55), at=(-0.95, 1.75, 0.28), role="lic_light", chamfer=0.16, **MR)
    claws(m, "B", -0.95, 1.17, 0.22)
    # ---- longue queue fine qui s'affine (rig Tail), finie en spirale de reglisse noire et violette
    for i in range(len(TAIL6) - 1):
        m.beam(f"Tail{i}", start=TAIL6[i], end=TAIL6[i + 1], role="lic", width=TW6[i], depth=TW6[i], taper=TW6[i + 1] / TW6[i], chamfer=0.08,
               solo=True)
    # spirale : part du bout de la queue (angle 0, cote arriere), descend, passe sous le centre et s'enroule vers l'interieur
    r0, turns, n = math.dist((SPC[1], SPC[2]), (TAIL6[-1][1], TAIL6[-1][2])), 1.55, 15
    prev = TAIL6[-1]
    for i in range(1, n + 1):
        t = i / n
        th = -t * turns * 2 * math.pi
        r = r0 * (1 - 0.72 * t)
        p = (0, SPC[1] + r * math.cos(th), SPC[2] + r * math.sin(th))
        w = TW6[-1] * (1 - 0.45 * t)
        m.beam(f"Curl{i}", start=prev, end=p, role="lic_violet" if i % 2 else "lic", width=w + 0.06, depth=w, solo=True)
        prev = p
    m.box("CurlCore", size=(0.5, 0.36, 0.36), at=(0, SPC[1] + 0.05, SPC[2] - 0.05), role="lic_violet", solo=True)
    # ---- peinture : torsades de reglisse (diagonales violettes), poitrail, bouche
    for n, L in (("Chest", 2.6), ("Torso", 3.3), ("Hips", 1.9)):
        for k in range(int(L / 0.65)):
            u = -L / 2 + 0.35 + k * 0.65
            m.line(n, "left", [(u - 0.3, 0.55), (u + 0.3, -0.45)], "lic_violet", 1)
            m.line(n, "right", [(-u + 0.3, 0.55), (-u - 0.3, -0.45)], "lic_violet", 1)
        m.line(n, "top", [(0, -L / 2 + 0.25), (0, L / 2 - 0.25)], "lic_violet", 1)
    m.line("Muzzle", "front", [(-0.35, -0.12), (-0.12, -0.25), (0.0, -0.1), (0.12, -0.25), (0.35, -0.12)], "eye", 1)
    m.line("Muzzle", "front", [(0, 0.2), (0, -0.1)], "eye", 1)
    for n in ("Thigh_L", "Shoulder_L"):
        m.line(n, "left", [(-0.3, 0.5), (0.3, -0.3)], "lic_violet", 1)
    return m


m6 = ropilot.model("R11_T6", px=8, reset=True)
m6.reference(REF6)
m6.palette(**PAL6)
build_t6(m6)
print(m6.build()); print(m6.check()); print(m6.compare()["report"])
ropilot.check_model(collection="R11_T6", max_lines=8)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R11_T6.blend"), copy=True)
GROUPS_T6 = {'Head': ['Head', 'Cheeks', 'Muzzle', 'Nose', 'Chin', 'Eye_*', 'Pupil_*', 'Shine_*', 'Brow_*', 'Whisker*'],
             'EarL': ['Ear_L', 'EarIn_L'], 'EarR': ['Ear_R', 'EarIn_R'],
             'LegFL': ['Shoulder_L', 'Foreleg_L', 'FPaw_L', 'FClaw*_L'], 'LegFR': ['Shoulder_R', 'Foreleg_R', 'FPaw_R', 'FClaw*_R'],
             'LegBL': ['Thigh_L', 'Hock_L', 'Shank_L', 'BPaw_L', 'BClaw*_L'], 'LegBR': ['Thigh_R', 'Hock_R', 'Shank_R', 'BPaw_R', 'BClaw*_R'],
             'Tail': ['Tail*', 'Curl*']}
# --- suite : exec(rigjoin.py), rig_join("R11_T6", GROUPS_T6), save R11_T6_rig.blend, import -> Work_R11_T6,
# CreatureRig.Install(workspace.Work_R11_T6, "R11_T6", nil, true), puis joints corriges dans le repere du Core :
# Head (0, 7.0, -3.4) en haut du cou, EarL/R (+-0.68, 8.1, -3.73) a la base (au lieu du bord interieur a mi-hauteur),
# LegFL/FR (+-0.9, 4.9, -2.45) a l'epaule, LegBL/BR (+-0.95, 4.85, 1.75) a la hanche, Tail (0, 5.45, 2.85) a la racine
# compare() final : face 0.82, dos 0.82, gauche 0.69, dessus 0.75 : reference tres fine (corps plus large ici pour la
# lisibilite) ; la queue en spirale de reglisse et le museau plus long ajoutent de la surface de profil.
# Le pendentif lumineux du collier devient « Body2 » (piece Neon du corps, comme sur les autres creatures).
