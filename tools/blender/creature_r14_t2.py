# Boo Pup (R14_T2, Uncommon) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R14_Refs/Ref_R14_T2_*.png)
# Petit chiot fantome blanc-brume qui flotte : grosse tete ronde chanfreinee, museau blanc, truffe noir doux, langue
# rose qui depasse, grands yeux separes a deux reflets et bas d'iris turquoise sombre, joues roses ; oreilles
# ardoise qui montent puis retombent sur les cotes ; tache ardoise derriere la tete ; corps en cloche octogonale,
# pattes avant tendues aux coussinets roses ; pas de pattes arriere : le bas du corps s'affine (bande de brume
# turquoise) et finit en queue de fantome qui part en arriere, ondule et remonte en volute ; bout de queue en feu
# follet turquoise lumineux ; collier violet a medaille turquoise lumineuse (decalee pour ne pas etre cachee par la
# langue).
# compare() final : face 0.79, dos 0.79, gauche 0.78, dessus 0.69 (28 pieces, 1 014 triangles, 2,39 x 2,65 x 3,27).
# Ecart voulu : la reference est un chiot assis en goutte (bas tres large) ; ici le bas s'affine en queue de fantome
# (demande « pas de pattes arriere, queue ondulee ») : la face plafonne vers 0.8. Essais rejetes : jupe a ourlet en
# disques (lisait comme des roues), en triangles (des pointes), en blocs (des creneaux).
# check_model : 0 piece flottante ou cachee, 0 arete ouverte (gaps signales = voisins proches : queue, pattes).
# --- suite : make_t2(), exec(rigjoin.py), rig_join("R14_T2", GROUPS_T2), save R14_T2_rig.blend, import ->
# Work_R14_T2, CreatureRig.Install(workspace.Work_R14_T2, "R14_T2", nil, true), puis joints corriges dans le repere
# du Core (x = -x Blender, y = z Blender, z = y Blender - 0.05) : ArmL/ArmR (+-0.5, 1.75, -0.48) (epaules),
# Head (0, 1.8, -0.3) (cou), EarL/EarR (+-0.45, 2.95, -0.23) (haut de l'oreille), Tail (0, 0.6, 0) (base sous le
# ventre). Lueurs : Tail__Glow (Follow Tail), medaille = Body2 (Neon).
# Portrait : rbxassetid://132047384144913 (Renders/Creatures/R14_T2.png).
# Ce fichier est autonome (le Blender de Ropilot est partage : ne pas compter sur des variables globales).
import ropilot, bpy, os, math, mathutils
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R14_Refs")
REF_B2 = {v: os.path.join(R, f"Ref_R14_T2_{v}.png") for v in ("front", "left", "back", "top")}
PAL_B2 = dict(
    mist=dict(color="#EEF8F8", noise=0.02, shade=0.08, top=0.04, mottle=("#f6fcfc", 0.2, 4)),
    mist_dark=dict(color="#BDE9E6", noise=0.025, shade=0.08, streaks=("#b0e2df", 0.3, "v")),
    snow=dict(color="#FFFFFF", noise=0.015, shade=0.05),
    slate=dict(color="#4A5868", noise=0.03, shade=0.12, top=0.08),
    pink="#F4A6B8", tongue=dict(color="#FF7F9C", noise=0.02, shade=0.1), nose="#22202A",
    eye="#22202A", white="#ffffff", blush="#F7A3B3", mouth="#22202A",
    violet=dict(color="#7A5AB8", noise=0.02, shade=0.1, top=0.1),
    glow=dict(color="#2FD9C0", glow=True),
)
HZ_B2, HY_B2 = 2.4, -0.28        # centre de la tete
TAILPTS_B2 = [(0, -0.05, 0.81), (0, 0.22, 0.43), (0, 0.66, 0.29), (0, 1.06, 0.49), (0, 1.2, 0.89), (0, 1.06, 1.27)]
TAILW_B2 = [1.12, 0.86, 0.64, 0.48, 0.34]


def ext_b2(a, b, e=0.05):
    a, b = mathutils.Vector(a), mathutils.Vector(b)
    d = (b - a).normalized() * e
    return tuple(a - d), tuple(b + d)


def build_b2(m):
    MR = dict(mirror=True)
    hy = HY_B2
    m.box("Head", size=(1.82, 1.34, 1.3), at=(0, hy, HZ_B2), role="mist", chamfer=0.5, taper=(0.84, 0.88))
    m.box("Muzzle", size=(0.82, 0.44, 0.5), at=(0, hy - 0.7, HZ_B2 - 0.32), role="snow", chamfer=0.18, axis="y", taper=(0.85, 0.85))
    m.prism("Body", radius=0.86, height=1.05, at=(0, -0.12, 1.36), role="mist", sides=8, turn=22.5, taper=0.72)
    m.prism("Belly", radius=0.6, height=0.42, at=(0, -0.1, 0.64), role="mist", sides=8, turn=22.5, taper=1.43)
    m.beam("Arm_L", start=(-0.5, -0.45, 1.75), end=(-0.46, -0.98, 1.5), role="mist", width=0.36, depth=0.38, chamfer=0.1, **MR)
    m.box("Paw_L", size=(0.42, 0.4, 0.34), at=(-0.46, -1.05, 1.46), role="snow", chamfer=0.12, **MR)
    # oreilles qui montent puis retombent, plus larges en bas
    m.beam("EarTop_L", start=(-0.42, hy + 0.1, 2.96), end=(-0.8, hy + 0.1, 3.2), role="slate", width=0.5, depth=0.24, chamfer=0.07, **MR)
    m.beam("Ear_L", start=(-0.86, hy + 0.1, 3.24), end=(-0.98, hy + 0.04, 2.2), role="slate", width=0.42, depth=0.24, taper=1.3, chamfer=0.1, **MR)
    # queue de fantome : part sous le ventre, ondule vers l'arriere et remonte
    pts, w = TAILPTS_B2, TAILW_B2
    for i in range(len(pts) - 1):
        a, b = ext_b2(pts[i], pts[i + 1], 0.12 if i else 0.0)
        m.beam(f"Tail{i}", start=a, end=b, role="mist", width=w[i], depth=w[i] * 0.85, taper=0.82, chamfer=min(0.14, w[i] * 0.2))
    return m


def details_b2(m):
    MR = dict(mirror=True)
    fy, ez = HY_B2 - 0.62, HZ_B2 + 0.1
    m.box("Eye_L", size=(0.32, 0.12, 0.44), at=(-0.34, fy - 0.01, ez), role="eye", chamfer=0.07, **MR)
    m.box("Shine_L", size=(0.14, 0.04, 0.14), at=(-0.39, fy - 0.08, ez + 0.1), role="white", **MR)
    m.box("Shine2_L", size=(0.07, 0.04, 0.07), at=(-0.26, fy - 0.08, ez - 0.1), role="white", **MR)
    my = HY_B2 - 0.7 - 0.22
    m.box("Nose", size=(0.3, 0.12, 0.17), at=(0, my - 0.02, HZ_B2 - 0.12), role="nose", chamfer=0.05, taper=(0.7, 0.8))
    m.box("Tongue", size=(0.22, 0.09, 0.3), at=(0.07, my, HZ_B2 - 0.62), role="tongue", chamfer=0.05, rot=(-8, 0, 0))
    # collier violet, medaille turquoise lumineuse
    m.box("Collar", size=(1.4, 1.36, 0.16), at=(0, -0.1, 1.72), role="violet", chamfer=0.06)
    m.prism("Tag", radius=0.14, height=0.07, at=(-0.22, -0.75, 1.56), role="glow", sides=6, turn=30, rot=(90, 0, 0), solo=True)
    # bout de queue en feu follet
    a, b = mathutils.Vector(TAILPTS_B2[-2]), mathutils.Vector(TAILPTS_B2[-1])
    d = (b - a).normalized()
    tip = b + d * 0.12
    m.prism("TailTip", radius=0.17, height=0.36, at=tuple(tip), role="glow", sides=6, taper=0.0, rot=(math.degrees(math.atan2(d.y, d.z)), 0, 0))
    return m


def paint_b2(m):
    m.rect("Head", "front", (-0.44, -0.15), (0.12, 0.06), "blush")
    m.rect("Head", "front", (0.44, -0.15), (0.12, 0.06), "blush")
    for e in ("Eye_L", "Eye_R"):
        m.rect(e, "front", (0, -0.14), (0.22, 0.09), "#2FA79A")
    m.stamp("Muzzle", "front", (0, -0.05), ["K..K..K", ".KK.KK."], {"K": "mouth"}, cell=0.05)
    m.blob("Head", "back", (0.2, 0.1), 0.3, "slate", seed=2)
    m.blob("Head", "top", (-0.25, 0.22), 0.18, "slate", seed=5)
    m.stamp("Paw_L", "front", (0, -0.04), ["K.K"], {"K": "pink"})
    m.stamp("Paw_R", "front", (0, -0.04), ["K.K"], {"K": "pink"})
    for k in range(8):
        m.rect("Belly", f"side{k}", (0, -0.12), (2, 0.16), "mist_dark")
    for i in range(4):
        m.line(f"Tail{i}", "top", [(0, -0.3), (0, 0.3)], "#bfeeea", 1)
    return m


GROUPS_T2 = {'Head': ['Head', 'Muzzle', 'Eye_*', 'Shine*', 'Nose', 'Tongue'],
             'EarL': ['EarTop_L', 'Ear_L'], 'EarR': ['EarTop_R', 'Ear_R'],
             'ArmL': ['Arm_L', 'Paw_L'], 'ArmR': ['Arm_R', 'Paw_R'],
             'Tail': ['Tail*']}


def save_col_b2(col, fname):
    # n'enregistre que la collection (Blender partage avec d'autres taches)
    p = os.path.join(ropilot.FILES_DIR, fname)
    bpy.data.libraries.write(p, {bpy.data.collections[col]}, fake_user=True)
    return p


def make_t2(save=True):
    m = ropilot.model("R14_T2", px=8, reset=True)
    m.reference(REF_B2); m.palette(**PAL_B2)
    build_b2(m); details_b2(m); paint_b2(m)
    print(m.build()); print(m.check()); print(m.compare(image=False)["report"])
    if save:
        save_col_b2("R14_T2", "R14_T2.blend")
    return m
