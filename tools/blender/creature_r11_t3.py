# Marshmallow Bunny (R11_T3, Rare) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R11_Refs/Ref_R11_T3_*.png)
# Lapin assis tout en guimauve : blocs cylindriques (prismes octogonaux) pour le corps, la tete (couchee : face
# ronde), les cuisses et la queue pompon ; longues oreilles a l'interieur rose ; nez en boule de gomme cerise ;
# bande de sucre rose a vermicelles, spirales de guimauve roses (cuisses, arriere de la tete), noeud de ruban
# menthe avec un coeur de bonbon lumineux, bout des pieds grille (toast), bout de queue rose.
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R11_Refs")
REF3 = {v: os.path.join(R, f"Ref_R11_T3_{v}.png") for v in ("front", "left", "back", "top")}
PAL3 = dict(
    mallow=dict(color="#fff6ec", noise=0.03, shade=0.12, mottle=("#ffeedd", 0.25, 4), top=0.05, speckle=("#ffffff", 0.05)),
    mallow_dark=dict(color="#f0dcc8", noise=0.03, shade=0.1),
    toast=dict(color="#e2a25a", noise=0.05, shade=0.12, mottle=("#c98440", 0.3, 3)),
    pink=dict(color="#ff8cc8", noise=0.03, shade=0.1, top=0.1),
    pink_dark=dict(color="#e0609e", noise=0.03),
    mint=dict(color="#3fbfa8", noise=0.03, shade=0.12, top=0.12),
    mint_light=dict(color="#8cebdc", noise=0.03),
    cherry=dict(color="#e8344e", noise=0.02, shade=0.08, top=0.15),
    eye="#2a1420", white="#ffffff", blush="#ffadd2",
    glow=dict(color="#ff5aa8", glow=True),
)
SPIRAL = ["PPPPP", "P...P", "P.P.P", "P.PPP", "P...."]


def build_t3(m):
    MR = dict(mirror=True)
    # corps : gros cylindre de guimauve, bande de sucre rose, assise plus foncee
    m.prism("Body", radius=0.94, height=1.34, at=(0, 0.12, 1.0), role="mallow", sides=8, turn=22.5)
    m.prism("BodyBand", radius=0.96, height=0.22, at=(0, 0.12, 0.66), role="pink", sides=8, turn=22.5)
    m.prism("Seat", radius=0.86, height=0.34, at=(0, 0.14, 0.17), role="mallow_dark", sides=8, turn=22.5)
    # tete : cylindre couche (face ronde vers l'avant), museau, nez en boule de gomme
    m.prism("Head", radius=0.9, height=1.08, at=(0, -0.12, 2.16), role="mallow", sides=8, turn=22.5, rot=(90, 0, 0))
    m.box("Muzzle", size=(0.6, 0.2, 0.4), at=(0, -0.74, 1.99), role="mallow", chamfer=0.12)
    m.prism("Nose", radius=0.14, height=0.16, at=(0, -0.86, 2.1), role="cherry", sides=8, turn=22.5, rot=(90, 0, 0))
    m.box("NoseShine", size=(0.06, 0.04, 0.06), at=(-0.05, -0.945, 2.15), role="white")
    m.box("Eye_L", size=(0.3, 0.08, 0.4), at=(-0.38, -0.7, 2.38), role="eye", chamfer=0.04, **MR)
    m.box("Shine_L", size=(0.14, 0.05, 0.14), at=(-0.43, -0.745, 2.48), role="white", **MR)
    m.box("Shine2_L", size=(0.06, 0.05, 0.06), at=(-0.32, -0.745, 2.28), role="white", **MR)
    # longues oreilles ecartees, interieur rose
    m.box("Ear_L", size=(0.66, 0.26, 1.2), at=(-0.4, -0.06, 2.8), role="mallow", chamfer=0.12, taper=(0.78, 1), pivot="bottom", rot=(0, -22, 0), **MR)
    m.box("EarIn_L", size=(0.4, 0.06, 0.9), at=(-0.43, -0.2, 2.88), role="pink", taper=(0.7, 1), pivot="bottom", rot=(0, -22, 0), **MR)
    # pattes avant tenues contre le ventre
    m.box("Arm_L", size=(0.36, 0.42, 0.46), at=(-0.36, -0.78, 1.2), role="mallow", chamfer=0.12, rot=(-25, 0, 0), faces={"front": "mallow_dark"}, **MR)
    # pattes arriere : cuisse ronde sur le cote, grand pied vers l'avant au bout grille
    m.prism("Thigh_L", radius=0.48, height=0.3, at=(-0.8, 0.22, 0.56), role="mallow", sides=8, turn=22.5, rot=(0, 90, 0), **MR)
    m.box("Foot_L", size=(0.46, 1.04, 0.34), at=(-0.62, -0.46, 0.17), role="mallow", chamfer=0.12, faces={"front": "toast"}, **MR)
    # queue pompon, bout rose
    m.prism("Tail", radius=0.38, height=0.36, at=(0, 1.0, 0.62), role="mallow", sides=8, turn=22.5, rot=(90, 0, 0))
    m.prism("TailTip", radius=0.24, height=0.12, at=(0, 1.2, 0.62), role="pink", sides=8, turn=22.5, rot=(90, 0, 0))
    # noeud de ruban menthe au cou, coeur de bonbon lumineux
    m.prism("Ribbon", radius=0.86, height=0.16, at=(0, 0.08, 1.66), role="mint", sides=8, turn=22.5)
    m.box("Bow_L", size=(0.42, 0.14, 0.38), at=(-0.26, -0.77, 1.62), role="mint", chamfer=0.04, taper=(1, 0.45), axis="x", **MR)
    m.box("Knot", size=(0.18, 0.16, 0.2), at=(0, -0.8, 1.62), role="glow", chamfer=0.03)
    return m


def paint_t3(m):
    m.stamp("Muzzle", "front", (0, -0.12), ["K..K", ".KK."], {"K": "eye"})
    m.rect("Head", "top", (-0.58, -0.12), (0.2, 0.1), "blush")   # « top » du prisme couche = face avant
    m.rect("Head", "top", (0.58, -0.12), (0.2, 0.1), "blush")
    m.stamp("Head", "bottom", (0, 0.05), SPIRAL, {"P": "pink"}, cell=0.14)   # arriere de la tete
    m.stamp("Bow_L", "front", (0, 0), ["M.", ".M"], {"M": "mint_light"})
    m.stamp("Bow_R", "front", (0, 0), [".M", "M."], {"M": "mint_light"})
    # cuisse : la face exterieure est « bottom » apres rot (0, 90, 0)
    m.rect("Thigh_L", "bottom", (0, 0), (0.9, 0.9), "mallow")
    m.stamp("Thigh_L", "bottom", (0, 0), SPIRAL, {"P": "pink"}, cell=0.12)
    for k in range(8):   # vermicelles blancs et citron sur la bande rose
        m.stamp("BodyBand", f"side{k}", (0, 0), ["W.Y"], {"W": "white", "Y": "#ffe66b"})
    return m


GROUPS_T3 = {'Head': ['Head', 'Muzzle', 'Nose', 'NoseShine', 'Eye_*', 'Shine*'],
             'EarL': ['Ear_L', 'EarIn_L'], 'EarR': ['Ear_R', 'EarIn_R'],
             'ArmL': ['Arm_L'], 'ArmR': ['Arm_R'],
             'LegL': ['Thigh_L', 'Foot_L'], 'LegR': ['Thigh_R', 'Foot_R'],
             'Tail': ['Tail', 'TailTip']}

if True:
    m3 = ropilot.model("R11_T3", px=8, reset=True)
    m3.reference(REF3)
    m3.palette(**PAL3)
    build_t3(m3); paint_t3(m3)
    print(m3.build()); print(m3.check()); print(m3.compare(image=False)["report"])
    ropilot.check_model(collection="R11_T3", max_lines=6)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R11_T3.blend"), copy=True)

# compare() final : face 0.85, dos 0.85, gauche 0.74, dessus 0.81 (de profil, les grands pieds de guimauve depassent
# un peu vers l'avant : garde pour que le lapin se tienne assis lisiblement).
# --- suite : exec(rigjoin.py), rig_join("R11_T3", GROUPS_T3), save R11_T3_rig.blend, import -> Work_R11_T3,
# CreatureRig.Install(workspace.Work_R11_T3, "R11_T3", nil, true), puis joints corriges dans le repere du Core :
# ArmL/ArmR (+-0.36, 1.4, -0.8), EarL/EarR (+-0.4, 2.82, -0.17), Head (0, 1.66, -0.2), LegL/LegR (+-0.62, 0.6, 0.1),
# Tail (0, 0.62, 0.72). Le coeur lumineux (Knot) devient Body2 (Neon).
