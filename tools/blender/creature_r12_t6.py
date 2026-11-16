# Fungal Stag (R12_T6, Mythic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R12_Refs/Ref_R12_T6_*.png)
# Grand cerf elance et majestueux : pelage violet-lavande (raie de dos violette, taches creme de faon), poitrail
# et ventre creme, cou puissant a criniere de mousse, tete fine a museau creme et truffe violet nuit, machoire
# (rig Jaw), yeux turquoise separes poses sur les aretes avant du crane (visibles de face et de profil, reflets,
# cils), longues oreilles (rig EarL / EarR) ; immenses bois ramifies en pieds de champignon creme, portant des
# chapeaux etages violets et turquoise et, au bout de chaque andouiller, un chapeau turquoise lumineux ; pattes
# fines a genou et jarret marques (pas de batons droits), balzanes creme, sabots violet nuit ; queue creme (rig Tail).
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R12_Refs")
REF6 = {v: os.path.join(R, f"Ref_R12_T6_{v}.png") for v in ("front", "left", "back", "top")}
PAL6 = dict(
    fur=dict(color="#9d7fe6", noise=0.03, shade=0.16, mottle=("#8f70dc", 0.25, 4), top=0.12),
    fur_dark=dict(color="#7a52c8", noise=0.03, shade=0.12),
    fur_light=dict(color="#b89bff", noise=0.025, shade=0.1, top=0.08),
    cream=dict(color="#f4eedc", noise=0.02, shade=0.12, top=0.06),
    stem=dict(color="#efe6f8", noise=0.025, shade=0.16, top=0.1),
    shelf=dict(color="#7a52c8", noise=0.03, shade=0.14, top=0.18, rim=-0.2),
    teal=dict(color="#6ef0d2", noise=0.025, shade=0.14, top=0.15, rim=-0.2),
    moss=dict(color="#6fb04a", noise=0.04, shade=0.14, mottle=("#86c45a", 0.35, 3), top=0.15),
    moss_dark=dict(color="#3e7a32", noise=0.035, shade=0.12),
    hoof=dict(color="#2c2148", noise=0.02, shade=0.1, top=0.2),
    nose=dict(color="#2c2148", noise=0.02, shade=0.1, top=0.25),
    white="#ffffff", iris="#2fbfa0", eye="#1a1230", shine="#ffffff", mouth="#2c1a30",
    glow=dict(color="#3fe8c4", glow=True),
)
MR = dict(mirror=True)
HK, HC, HO = 1.3, (0, -4.9, 8.9), (0, 0.6, 0.75)
NECK0, NECK1 = (0, -2.6, 5.7), (0, -3.65, 9.15)
# bois gauche : merrain (points), puis andouillers (depart sur le merrain, bout)
ANT = [(-0.55, -4.25, 9.75), (-1.5, -4.0, 10.6), (-2.6, -3.75, 11.4), (-3.3, -3.6, 12.4), (-3.55, -3.75, 13.3)]
TINES = [(1, (-1.65, -4.85, 11.75)), (2, (-2.35, -4.5, 12.75)), (2, (-3.75, -3.3, 11.2)), (3, (-2.85, -2.85, 13.5))]


def add(a, b, k=1.0):
    return tuple(a[i] + b[i] * k for i in range(3))


def mid(a, b, t=0.5):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def build_t6(m):
    # ---- corps : poitrail profond, tonneau, croupe ; ventre et poitrail creme
    m.box("Barrel", size=(2.8, 6.4, 2.3), at=(0, 0.3, 5.25), role="fur", chamfer=0.75, faces={"bottom": "cream"})
    m.box("Chest", size=(3.05, 2.6, 3.1), at=(0, -2.1, 5.1), role="fur", chamfer=0.9, faces={"bottom": "cream"})
    m.box("Rump", size=(3.0, 2.5, 2.8), at=(0, 2.65, 5.2), role="fur", chamfer=0.9, faces={"bottom": "cream"}, slope=(0, -0.25))
    m.box("Belly", size=(1.9, 3.6, 0.4), at=(0, 0.3, 4.12), role="cream", chamfer=0.15)
    m.box("Blaze", size=(2.0, 0.7, 1.8), at=(0, -3.35, 4.6), role="cream", chamfer=0.35, taper=(0.8, 1))
    m.box("BackStripe", size=(0.7, 6.2, 0.2), at=(0, 0.25, 6.42), role="fur_dark", chamfer=0.05)
    # ---- cou puissant (reste dans Body) et criniere de mousse le long de la crete
    m.beam("Neck", start=NECK0, end=NECK1, role="fur", width=1.55, depth=1.9, taper=0.82, chamfer=0.4)
    m.beam("Throat", start=add(NECK0, (0, -0.6, 0.1)), end=add(NECK1, (0, -0.45, -0.6)), role="fur_light", width=0.95, depth=0.6, taper=0.75, chamfer=0.15)
    for k, t in enumerate((0.15, 0.42, 0.7, 0.95)):
        p = add(mid(NECK0, NECK1, t), (0, 0.85 - 0.12 * t, 0.25))
        m.box(f"Mane{k}", size=(0.9 - 0.12 * t, 1.0, 0.7), at=p, role="moss" if k % 2 == 0 else "moss_dark", chamfer=0.18, rot=(-28, 0, 0))
    # deux petits chapeaux lumineux dans la criniere
    for k, t in enumerate((0.3, 0.8)):
        p = add(mid(NECK0, NECK1, t), (0.42 if k else -0.42, 0.95, 0.55))
        m.prism(f"ManeCapStem{k}", radius=0.12, height=0.4, at=p, role="stem", sides=5, taper=0.8, rot=(-25, 0, 0), solo=True)
        m.prism(f"ManeCap{k}", radius=0.34, height=0.22, at=add(p, (0, 0.1, 0.25)), role="glow", sides=6, taper=0.4, rot=(-25, 0, 0), solo=True)
    # ---- tete (rig Head) : crane, museau creme qui s'affine, truffe, gueule sombre
    m.box("Skull", size=(1.9, 1.9, 1.8), at=(0, -4.45, 9.0), role="fur", chamfer=0.5)
    m.box("Snout", size=(1.25, 1.55, 1.0), at=(0, -5.9, 8.62), role="cream", chamfer=0.25, taper=(0.82, 0.8), axis="y")
    m.box("Nose", size=(0.62, 0.3, 0.4), at=(0, -6.65, 8.85), role="nose", chamfer=0.08)
    m.box("Forehead", size=(1.0, 1.2, 0.5), at=(0, -5.0, 9.65), role="fur_dark", chamfer=0.15, taper=(0.8, 0.9), slope=(0, 0.2))
    m.box("MouthIn", size=(0.85, 1.0, 0.12), at=(0, -5.85, 8.15), role="mouth")
    # machoire (rig Jaw)
    m.box("Jaw", size=(0.95, 1.25, 0.36), at=(0, -5.75, 7.93), role="cream", chamfer=0.1, taper=(0.85, 0.85), axis="y")
    # yeux turquoise sur les aretes avant du crane : blanc, iris, pupille, reflets, cils
    C = (-0.79, -5.24, 9.12)
    N, T = (-0.7071, -0.7071, 0), (0.7071, -0.7071, 0)
    E = dict(rot=(0, 0, -45), **MR)

    def ep(u, dn, dz):
        return add(add(add(C, T, u), N, dn), (0, 0, dz))
    m.box("Eye_L", size=(0.6, 0.1, 0.66), at=ep(0, 0.02, 0), role="white", **E)
    m.box("Iris_L", size=(0.45, 0.08, 0.52), at=ep(0.04, 0.07, -0.03), role="iris", **E)
    m.box("Pupil_L", size=(0.24, 0.06, 0.32), at=ep(0.06, 0.11, -0.05), role="eye", **E)
    m.box("Shine_L", size=(0.14, 0.05, 0.14), at=ep(-0.08, 0.13, 0.1), role="shine", **E)
    m.box("Shine2_L", size=(0.07, 0.05, 0.07), at=ep(0.15, 0.13, -0.17), role="shine", **E)
    m.beam("Lash_L", start=ep(-0.22, 0.05, 0.3), end=ep(-0.42, 0.1, 0.5), role="eye", width=0.08, depth=0.08, **MR)
    # longues oreilles (rig EarL / EarR)
    m.box("Ear_L", size=(1.25, 0.32, 0.55), at=(-1.45, -4.05, 9.55), role="fur", chamfer=0.1, taper=(1, 1), rot=(0, -22, 0), **MR)
    m.box("EarIn_L", size=(0.85, 0.1, 0.32), at=(-1.5, -4.24, 9.57), role="cream", rot=(0, -22, 0), **MR)
    # ---- bois de champignons : merrain creme qui s'affine, chapeaux etages, andouillers a chapeau lumineux
    m.prism("Pedicel_L", radius=0.42, height=0.4, at=add(ANT[0], (0, 0, -0.1)), role="fur_dark", sides=6, **MR)
    for i in range(len(ANT) - 1):
        w = 0.52 - 0.08 * i
        m.beam(f"Antler{i}_L", start=ANT[i], end=ANT[i + 1], role="stem", width=w, depth=w, taper=(w - 0.07) / w, chamfer=0.06, **MR)
        m.box(f"Knot{i}_L", size=(w + 0.1, w + 0.1, w + 0.1), at=ANT[i + 1], role="stem", chamfer=0.08, **MR)
    for k, (i, tip) in enumerate(TINES):
        m.beam(f"Tine{k}_L", start=ANT[i], end=tip, role="stem", width=0.3, depth=0.3, taper=0.7, **MR)
        m.prism(f"TipCap{k}_L", radius=0.42, height=0.3, at=add(tip, (0, 0, 0.05)), role="glow", sides=6, taper=0.4, **MR)
    m.prism("TipCap4_L", radius=0.5, height=0.34, at=add(ANT[4], (0, 0, 0.05)), role="glow", sides=6, taper=0.4, **MR)
    # chapeaux etages : disques plats violets et turquoise sur le cote exterieur du merrain
    SH = [(0, 0.55, "shelf", 0.5), (1, 0.35, "teal", 0.45), (1, 0.8, "shelf", 0.4), (2, 0.4, "teal", 0.42), (2, 0.75, "shelf", 0.36), (3, 0.5, "teal", 0.32)]
    for k, (i, t, role, r) in enumerate(SH):
        p = mid(ANT[i], ANT[i + 1], t)
        m.prism(f"Shelf{k}_L", radius=r, height=0.16, at=add(p, (-0.28, 0.12, 0)), role=role, sides=6, taper=0.7, **MR)
    # ---- pattes avant (rig LegFL / LegFR) : epaule, avant-bras, genou, canon fin, balzane, sabot
    m.box("Shoulder_L", size=(1.0, 1.7, 2.1), at=(-1.08, -2.35, 4.9), role="fur", chamfer=0.4, **MR)
    m.beam("FArm_L", start=(-1.0, -2.4, 4.3), end=(-1.0, -2.25, 2.25), role="fur", width=0.85, depth=1.05, taper=0.75, chamfer=0.15, **MR)
    m.box("FKnee_L", size=(0.72, 0.85, 0.55), at=(-1.0, -2.25, 2.25), role="fur_dark", chamfer=0.12, **MR)
    m.beam("FCannon_L", start=(-1.0, -2.25, 2.1), end=(-1.0, -2.45, 0.6), role="fur", width=0.55, depth=0.62, **MR)
    m.box("FSock_L", size=(0.7, 0.8, 0.35), at=(-1.0, -2.47, 0.72), role="cream", chamfer=0.1, **MR)
    m.box("FHoof_L", size=(0.75, 0.95, 0.55), at=(-1.0, -2.55, 0.27), role="hoof", chamfer=0.1, taper=(0.85, 0.85), **MR)
    # ---- pattes arriere (rig LegBL / LegBR) : cuisse, jambe vers le jarret (en arriere), canon, sabot
    m.box("Thigh_L", size=(1.1, 2.3, 2.6), at=(-1.05, 2.6, 4.75), role="fur", chamfer=0.5, **MR)
    m.beam("BGaskin_L", start=(-1.0, 2.75, 3.75), end=(-1.0, 3.4, 1.95), role="fur", width=0.8, depth=1.05, taper=0.72, chamfer=0.12, **MR)
    m.box("BHock_L", size=(0.6, 0.72, 0.5), at=(-1.0, 3.4, 1.95), role="fur_dark", chamfer=0.1, **MR)
    m.beam("BCannon_L", start=(-1.0, 3.38, 1.85), end=(-1.0, 3.05, 0.6), role="fur", width=0.5, depth=0.58, **MR)
    m.box("BSock_L", size=(0.68, 0.78, 0.35), at=(-1.0, 3.03, 0.72), role="cream", chamfer=0.1, **MR)
    m.box("BHoof_L", size=(0.72, 0.92, 0.55), at=(-1.0, 2.95, 0.27), role="hoof", chamfer=0.1, taper=(0.85, 0.85), **MR)
    # ---- queue creme (rig Tail)
    m.box("Tail", size=(0.75, 0.55, 1.1), at=(0, 3.95, 6.15), role="cream", chamfer=0.2, rot=(-35, 0, 0), faces={"back": "fur_light"})
    # ---- touffes lumineuses : deux petits chapeaux sur la croupe et le garrot
    m.prism("BackCapStem", radius=0.14, height=0.45, at=(0.45, 2.3, 6.55), role="stem", sides=5, taper=0.8, solo=True)
    m.prism("BackCap", radius=0.4, height=0.26, at=(0.45, 2.3, 6.82), role="glow", sides=6, taper=0.4, solo=True)
    m.prism("BackCap2Stem", radius=0.12, height=0.35, at=(-0.5, 3.0, 6.4), role="stem", sides=5, taper=0.8, solo=True)
    m.prism("BackCap2", radius=0.32, height=0.22, at=(-0.5, 3.0, 6.62), role="teal", sides=6, taper=0.4, solo=True)
    # ---- tete agrandie de HK autour du centre du crane (sans les bois, qui suivent le dessus du crane)
    head = ["Skull", "Snout", "Nose", "Forehead", "MouthIn", "Jaw", "Eye_L", "Iris_L", "Pupil_L", "Shine_L", "Shine2_L", "Lash_L",
            "Ear_L", "EarIn_L"]
    m.scale(HK, names=head)
    for n in head:
        m.move(n, by=tuple(HC[i] * (1 - HK) + HO[i] for i in range(3)))
    a0 = ANT[0]
    d = tuple(HC[i] + (a0[i] - HC[i]) * HK + HO[i] - a0[i] for i in range(3))
    for n in m.parts:
        if n.split("_")[0].rstrip("0123456789") in ("Pedicel", "Antler", "Knot", "Tine", "TipCap", "Shelf"):
            m.move(n, by=d)
    # ---- peinture : taches de faon creme sur le dos et les flancs, bouche, naseaux
    for host, spots in (("Barrel", ((-0.8, 0.5), (0.4, 0.75), (0.9, 0.2))), ("Rump", ((-0.6, 0.6), (0.5, 0.3))), ("Chest", ((0.6, 0.7),))):
        for (u, v) in spots:
            m.rect(host, "left", (u, v), (0.3, 0.25), "cream")
            m.rect(host, "right", (-u, v), (0.3, 0.25), "cream")
    for (u, v) in ((-0.8, -0.9), (0.8, -0.6), (-0.8, 0.9), (0.8, 1.1)):
        m.rect("Barrel" if abs(v) < 1.2 else "Rump", "top", (u, v), (0.28, 0.24), "cream")
    m.rect("Nose", "front", (-0.15, 0.0), (0.12, 0.12), "#5a4a8a")
    m.rect("Nose", "front", (0.15, 0.0), (0.12, 0.12), "#5a4a8a")
    m.line("Snout", "front", [(-0.3, -0.25), (0.0, -0.35), (0.3, -0.25)], "mouth", 1)
    return m


m6 = ropilot.model("R12_T6", px=8, reset=True)
m6.reference(REF6)
m6.palette(**PAL6)
build_t6(m6)
print(m6.build()); print(m6.check()); print(m6.compare()["report"])
ropilot.check_model(collection="R12_T6", max_lines=8)


def save_only(col_name, fname):
    # n'ecrit que la collection de la creature (pas les modeles des autres taches ni les references)
    col = bpy.data.collections[col_name]
    bpy.data.libraries.write(os.path.join(ropilot.FILES_DIR, fname), {col}, fake_user=True, compress=True)


save_only("R12_T6", "R12_T6.blend")

GROUPS_T6 = {'Head': ['Skull', 'Snout', 'Nose', 'Forehead', 'MouthIn', 'Eye_*', 'Iris_*', 'Pupil_*', 'Shine_*', 'Shine2_*', 'Lash_*',
                      'Pedicel_*', 'Antler*', 'Knot*', 'Tine*', 'TipCap*', 'Shelf*'],
             'Jaw': ['Jaw'],
             'EarL': ['Ear_L', 'EarIn_L'], 'EarR': ['Ear_R', 'EarIn_R'],
             'LegFL': ['Shoulder_L', 'FArm_L', 'FKnee_L', 'FCannon_L', 'FSock_L', 'FHoof_L'],
             'LegFR': ['Shoulder_R', 'FArm_R', 'FKnee_R', 'FCannon_R', 'FSock_R', 'FHoof_R'],
             'LegBL': ['Thigh_L', 'BGaskin_L', 'BHock_L', 'BCannon_L', 'BSock_L', 'BHoof_L'],
             'LegBR': ['Thigh_R', 'BGaskin_R', 'BHock_R', 'BCannon_R', 'BSock_R', 'BHoof_R'],
             'Tail': ['Tail']}
# --- suite : exec(rigjoin.py), rig_join("R12_T6", GROUPS_T6), save_only("R12_T6", "R12_T6_rig.blend"), import -> Work_R12_T6,
# CreatureRig.Install(workspace.Work_R12_T6, "R12_T6", nil, true), puis joints corriges dans le repere du Core
# joints corriges dans le repere du Core : Head (0, 8.9, -2.0) en haut du cou, Jaw (0, 8.62, -3.45) a la charniere,
# EarL/R (+-1.25, 10.5, -2.07) a la base, Tail (0, 6.2, 5.0) a la racine ; pattes laissees (epaule 5.48, hanche 5.57)
# compare() final : face 0.57, dos 0.57, gauche 0.59, dessus 0.69 : les bois ramifies plafonnent le score, et la tete est
# volontairement plus haute (cou plus long, HO z +0.75) et plus grosse (HK = 1.3) que dans la reference, cerf fin a petite tete.
# Portrait : rbxassetid://87095633395322
