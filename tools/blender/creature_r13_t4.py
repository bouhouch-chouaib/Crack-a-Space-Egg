# Sphinx Cat (R13_T4, Epic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R13_Refs/Ref_R13_T4_*.png)
# Chat assis bien droit, pelage sable : torse droit, dos, croupe, poitrail creme, cuisses arriere rondes (prismes
# couches), pieds a plat, pattes avant fines aux pieds cremes et bracelets d'or ; tete qui depasse de la coiffe,
# museau creme, nez rose, bouche en « w », points de moustaches, joues ; grands yeux verts de jade octogonaux
# soulignes de khol (cadre + trait vers l'exterieur), pupille fendue, deux reflets ; oreilles hautes a l'interieur
# rose. Coiffe nemes rayee or et turquoise : bandeau or sombre a gemme turquoise lumineuse, dessus, ailes evasees
# derriere les joues, pans qui tombent sur les epaules, dos ; collier de jade en V a bord d'or et pendentif
# turquoise lumineux ; queue en crosse a deux anneaux d'or et bout rayé.
# compare() final : face 0.78, dos 0.78, gauche 0.73, dessus 0.75 (49 pieces, 1 358 triangles, 2,10 x 3,37 x 4,49).
# Ecart voulu : la reference est trapue (grosse croupe, coiffe en bloc qui cache la tete) ; ici la tete depasse de
# la coiffe et le corps est plus fin (« elance ») : un premier essai fidele (0.81 / 0.76) se lisait comme une caisse.
# check_model : 0 piece flottante ou cachee, 0 arete ouverte ; 2 chevauchements voulus (dos de la coiffe et poitrail
# dans le torse) ; 13 « gaps » de voisins (reflets, pupilles, bracelets).
# --- suite : make_t4(), exec(rigjoin.py), rig_join("R13_T4", GROUPS_T4), save R13_T4_rig.blend, import ->
# Work_R13_T4, CreatureRig.Install(workspace.Work_R13_T4, "R13_T4", nil, true), puis joints corriges dans le repere
# du Core (x = -x Blender, y = z Blender, z = y Blender - 0.285) : Head (0, 2.55, -0.53) (cou), EarL/EarR
# (+-0.45, 3.78, -0.75) (base), LegFL/FR (+-0.32, 1.95, -0.73) (epaules), LegBL/BR (+-0.78, 0.95, 0.15) (hanches),
# Tail (0, 0.42, 0.8) (base). Gemme du bandeau : Head__Glow (Follow), pendentif : Body2 (Neon).
# Portrait : rbxassetid://134577077562821 (Renders/Creatures/R13_T4.png).
# Ce fichier est autonome (le Blender de Ropilot est partage : ne pas compter sur des variables globales).
import ropilot, bpy, os, math, mathutils
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R13_Refs")
REF4 = {v: os.path.join(R, f"Ref_R13_T4_{v}.png") for v in ("front", "left", "back", "top")}
PAL4 = dict(
    sand=dict(color="#E2BC80", noise=0.03, shade=0.14, streaks=("#d8b074", 0.3, "v"), top=0.1),
    sand_dark=dict(color="#B98E55", noise=0.03, shade=0.1),
    cream=dict(color="#F4EAD0", noise=0.025, shade=0.08, top=0.05),
    gold=dict(color="#F2C14E", noise=0.02, shade=0.12, top=0.16),
    gold_dark=dict(color="#B8862B", noise=0.02, shade=0.08),
    turq=dict(color="#3EC9D6", noise=0.02, shade=0.1),
    jade=dict(color="#3FB37F", noise=0.03, shade=0.12, mottle=("#4cc28c", 0.25, 3), top=0.1),
    jade_dark=dict(color="#1F6E4E", noise=0.03),
    jade_light="#8FE0B4",
    khol="#2A2420", white="#ffffff", pink="#f0a0a0", blush="#f39a8c", nose="#c9706a",
    glow=dict(color="#3EC9D6", glow=True),
)
HZ4 = 3.25     # centre de la tete
HY4 = -0.62    # y de la tete


def ext4(a, b, e=0.05):
    a, b = mathutils.Vector(a), mathutils.Vector(b)
    d = (b - a).normalized() * e
    return tuple(a - d), tuple(b + d)


def build_t4(m):
    MR = dict(mirror=True)
    # torse droit (assis), croupe
    m.beam("Torso", start=(0, 0.5, 0.5), end=(0, -0.2, 2.45), role="sand", width=1.15, depth=1.3, taper=0.74, chamfer=0.38)
    m.box("Rump", size=(1.45, 1.55, 0.9), at=(0, 0.5, 0.46), role="sand", chamfer=0.38, taper=(0.86, 0.82))
    m.beam("Back", start=(0, 0.95, 0.75), end=(0, 0.42, 2.25), role="sand", width=1.05, depth=0.7, taper=0.8, chamfer=0.28)
    m.box("Chest", size=(0.74, 0.5, 1.3), at=(0, -0.48, 1.45), role="cream", chamfer=0.22, taper=(0.78, 0.8))
    # cuisses arriere repliees sur les cotes, pieds a plat devant
    m.prism("Thigh_L", radius=0.62, height=0.5, at=(-0.8, 0.42, 0.62), role="sand", sides=8, turn=22.5, rot=(0, 90, 0), **MR)
    m.box("HindFoot_L", size=(0.4, 0.66, 0.2), at=(-0.76, -0.38, 0.1), role="sand", chamfer=0.07, faces={"front": "cream"}, **MR)
    # pattes avant fines et droites, pieds ronds
    m.beam("FrontLeg_L", start=(-0.32, -0.45, 1.95), end=(-0.32, -0.72, 0.18), role="sand", width=0.3, depth=0.32, chamfer=0.08, **MR)
    m.box("Paw_L", size=(0.38, 0.5, 0.22), at=(-0.32, -0.86, 0.11), role="cream", chamfer=0.08, **MR)
    # tete ronde qui depasse de la coiffe, museau creme, oreilles hautes et pointues
    m.box("Head", size=(1.32, 1.0, 1.05), at=(0, HY4, HZ4), role="sand", chamfer=0.2, taper=(0.9, 0.95))
    m.box("Muzzle", size=(0.54, 0.3, 0.32), at=(0, HY4 - 0.58, HZ4 - 0.28), role="cream", chamfer=0.1, taper=(0.9, 1))
    m.prism("Ear_L", radius=0.32, height=0.78, at=(-0.5, HY4 + 0.15, HZ4 + 0.86), role="sand", sides=4, turn=45, taper=0.0, rot=(0, -14, 0), **MR)
    # coiffe rayee (nemes) : bandeau, dessus vers l'arriere, ailes evasees derriere les joues, pans sur les epaules, dos
    m.box("Hood", size=(1.42, 0.95, 0.3), at=(0, HY4 + 0.2, HZ4 + 0.56), role="gold", chamfer=0.12, taper=(0.85, 0.9))
    m.box("Band", size=(1.3, 0.14, 0.16), at=(0, HY4 - 0.3, HZ4 + 0.42), role="gold_dark", chamfer=0.03)
    m.box("HoodSide_L", size=(0.28, 0.85, 1.35), at=(-0.78, HY4 + 0.25, HZ4 - 0.05), role="gold", chamfer=0.06, shear=(0.2, 0), **MR)
    m.box("Lappet_L", size=(0.36, 0.2, 1.1), at=(-0.64, HY4 + 0.0, HZ4 - 1.25), role="gold", chamfer=0.05, taper=(0.8, 1.0), **MR)
    m.box("HoodBack", size=(1.25, 0.5, 1.45), at=(0, HY4 + 0.75, HZ4 - 0.4), role="gold", chamfer=0.1, taper=(0.85, 1.0))
    # queue qui remonte derriere en crosse
    pts = [(0, 1.1, 0.4), (0, 1.58, 0.3), (0, 1.84, 0.72), (0, 1.82, 1.22), (0, 1.62, 1.58), (0, 1.36, 1.66)]
    w = [0.26, 0.24, 0.22, 0.2, 0.18]
    for i in range(len(pts) - 1):
        a, b = ext4(pts[i], pts[i + 1], 0.05 if i else 0.0)
        m.beam(f"Tail{i}", start=a, end=b, role="sand", width=w[i], depth=w[i])
    return m


def details_t4(m):
    MR = dict(mirror=True)
    fy = HY4 - 0.5          # face avant de la tete
    ez = HZ4 + 0.1          # hauteur des yeux
    # grands yeux verts de jade soulignes de khol, pupille fendue, deux reflets
    m.prism("Khol_L", radius=0.17, height=0.05, at=(-0.26, fy - 0.01, ez), role="khol", sides=8, turn=22.5, rot=(90, 0, 0), **MR)
    m.prism("Iris_L", radius=0.135, height=0.04, at=(-0.26, fy - 0.045, ez), role="jade", sides=8, turn=22.5, rot=(90, 0, 0), **MR)
    m.box("Pupil_L", size=(0.08, 0.03, 0.2), at=(-0.25, fy - 0.075, ez - 0.01), role="khol", **MR)
    m.box("Shine_L", size=(0.08, 0.03, 0.08), at=(-0.31, fy - 0.095, ez + 0.07), role="white", **MR)
    m.box("Shine2_L", size=(0.04, 0.03, 0.04), at=(-0.2, fy - 0.095, ez - 0.07), role="white", **MR)
    # nez rose, interieur des oreilles
    m.box("Nose", size=(0.18, 0.08, 0.1), at=(0, HY4 - 0.74, HZ4 - 0.15), role="nose", taper=(0.5, 1), rot=(180, 0, 0))
    m.prism("EarIn_L", radius=0.2, height=0.5, at=(-0.5, HY4 + 0.03, HZ4 + 0.8), role="pink", sides=4, turn=45, taper=0.0, rot=(0, -14, 0), **MR)
    # gemme turquoise sur le bandeau
    m.box("BandGem", size=(0.18, 0.08, 0.18), at=(0, HY4 - 0.38, HZ4 + 0.42), role="glow", rot=(0, 45, 0))
    # collier de jade (usekh) en V sur le poitrail, bord d'or, pendentif turquoise
    m.pyramid("Collar", size=(0.86, 0.16, 0.5), at=(0, -0.7, 2.12), role="jade", rot=(180, 0, 0))
    m.box("CollarRim", size=(0.9, 0.18, 0.1), at=(0, -0.7, 2.38), role="gold", chamfer=0.03)
    m.box("Pendant", size=(0.16, 0.08, 0.16), at=(0, -0.765, 2.02), role="glow", rot=(0, 45, 0))
    # bracelets d'or aux pattes avant
    m.box("Anklet_L", size=(0.38, 0.4, 0.12), at=(-0.32, -0.67, 0.52), role="gold", chamfer=0.03, rot=(-8.7, 0, 0), **MR)
    # anneaux d'or sur la queue
    pts = [(0, 1.1, 0.4), (0, 1.58, 0.3), (0, 1.84, 0.72), (0, 1.82, 1.22), (0, 1.62, 1.58), (0, 1.36, 1.66)]
    for k, i in enumerate((2, 3)):
        a, b = mathutils.Vector(pts[i]), mathutils.Vector(pts[i + 1])
        m.beam(f"TailRing{k}", start=tuple(a.lerp(b, 0.4)), end=tuple(a.lerp(b, 0.6)), role="gold", width=0.27 - 0.02 * k, depth=0.27 - 0.02 * k)
    return m


def paint_t4(m):
    # rayures turquoise de la coiffe
    for v in (-0.45, -0.15, 0.15, 0.45):
        m.rect("HoodSide_L", "left", (0, v), (1.0, 0.1), "turq")
        m.rect("HoodSide_L", "front", (0, v), (0.4, 0.1), "turq")
    for v in (-0.4, -0.1, 0.2):
        m.rect("Lappet_L", "front", (0, v), (0.5, 0.1), "turq")
        m.rect("Lappet_R", "front", (0, v), (0.5, 0.1), "turq")
    for u in (-0.45, -0.15, 0.15, 0.45):
        m.rect("Hood", "top", (u, 0), (0.1, 1.0), "turq")
        m.rect("HoodBack", "back", (u, 0), (0.1, 1.6), "turq")
    m.rect("Lappet_L", "front", (0, -0.52), (0.5, 0.06), "gold_dark")
    m.rect("Lappet_R", "front", (0, -0.52), (0.5, 0.06), "gold_dark")
    # khol : trait qui prolonge l'oeil vers l'exterieur
    m.line("Head", "front", [(-0.42, 0.1), (-0.5, 0.04)], "khol", 1)
    m.line("Head", "front", [(0.42, 0.1), (0.5, 0.04)], "khol", 1)
    m.rect("Head", "front", (-0.4, -0.14), (0.12, 0.05), "blush")
    m.rect("Head", "front", (0.4, -0.14), (0.12, 0.05), "blush")
    # bouche en « w », points de moustaches
    m.stamp("Muzzle", "front", (0, -0.05), ["K...K", ".K.K.", "..K.."], {"K": "khol"}, cell=0.05)
    m.stamp("Muzzle", "front", (-0.19, 0.03), ["S.S", ".S."], {"S": "sand_dark"}, cell=0.05)
    m.stamp("Muzzle", "front", (0.19, 0.03), ["S.S", ".S."], {"S": "sand_dark"}, cell=0.05)
    # rayures de pelage sable fonce sur les cuisses, le dos et la queue
    m.blob("Thigh_L", "bottom", (0.1, 0.15), 0.12, "sand_dark", seed=3)
    for v in (-0.4, 0.0, 0.4):
        m.line("Back", "back", [(-0.35, v), (0.35, v)], "sand_dark", 1)
    m.rect("Tail4", "left", (0.12, 0), (0.12, 0.3), "sand_dark")
    m.rect("Tail4", "right", (-0.12, 0), (0.12, 0.3), "sand_dark")
    # orteils
    m.stamp("Paw_L", "front", (0, 0), ["K.K"], {"K": "sand_dark"})
    m.stamp("Paw_R", "front", (0, 0), ["K.K"], {"K": "sand_dark"})
    # collier : rangs d'or et de jade clair
    m.line("Collar", "front", [(-0.3, 0.12), (0.3, 0.12)], "gold", 1)
    m.line("Collar", "front", [(-0.18, -0.02), (0.18, -0.02)], "jade_light", 1)
    return m


GROUPS_T4 = {'Head': ['Head', 'Muzzle', 'Nose', 'Khol_*', 'Iris_*', 'Pupil_*', 'Shine*', 'Hood', 'Band*', 'HoodSide_*', 'Lappet_*', 'HoodBack'],
             'EarL': ['Ear_L', 'EarIn_L'], 'EarR': ['Ear_R', 'EarIn_R'],
             'LegFL': ['FrontLeg_L', 'Paw_L', 'Anklet_L'], 'LegFR': ['FrontLeg_R', 'Paw_R', 'Anklet_R'],
             'LegBL': ['Thigh_L', 'HindFoot_L'], 'LegBR': ['Thigh_R', 'HindFoot_R'],
             'Tail': ['Tail*']}


def make_t4(save=True, image=False):
    m = ropilot.model("R13_T4", px=8, reset=True)
    m.reference(REF4); m.palette(**PAL4)
    build_t4(m); details_t4(m); paint_t4(m)
    print(m.build()); print(m.check()); print(m.compare(image=image)["report"])
    if save:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R13_T4.blend"), copy=True)
    return m
