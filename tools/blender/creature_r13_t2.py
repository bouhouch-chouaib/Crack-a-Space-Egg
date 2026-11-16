# Jade Monkey (R13_T2, Uncommon) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R13_Refs/Ref_R13_T2_*.png)
# Petit singe espiegle en jade vert : grosse tete aux coins chanfreines, visage clair en coeur peint (deux ronds
# autour des yeux + bas du visage), museau clair en relief avec narines et sourire, grands yeux separes a deux
# reflets, joues roses ; grandes oreilles rondes a l'interieur clair ; corps en poire au ventre clair ; longs bras
# aux mains claires, bracelets d'or graves avec une petite gemme turquoise ; jambes courtes, pieds clairs, anneaux
# d'or aux chevilles ; longue queue enroulee sur le cote avec une bande d'or ; diademe d'or a gemme turquoise
# lumineuse ; veines de jade plus claires sur la tete et le corps.
# compare() final : face 0.80, dos 0.79, gauche 0.79, dessus 0.77 (37 pieces, 1 052 triangles, 2,32 x 1,68 x 3,34).
# La reference est un singe arrondi (lisse) : la tete chanfreinee et les blocs plafonnent la face vers 0.8.
# check_model : 0 piece flottante ou cachee, 0 arete ouverte ; 13 « gaps » de voisins (reflets, bracelets, anneaux).
# --- suite : make_t2(), exec(rigjoin.py), rig_join("R13_T2", GROUPS_T2), save R13_T2_rig.blend, import ->
# Work_R13_T2, CreatureRig.Install(workspace.Work_R13_T2, "R13_T2", nil, true), puis joints corriges dans le repere
# du Core (x = -x Blender, y = z Blender, z = y Blender + 0.08) : ArmL/ArmR (+-0.45, 1.6, 0.08) (epaules),
# Head (0, 1.85, 0.14) (cou), LegL/LegR (+-0.28, 0.74, 0.13) (hanches), Tail (-0.12, 0.8, 0.42) (base) ;
# oreilles laissees. Gemmes lumineuses : Head__Glow (diademe), ArmL__Glow / ArmR__Glow (bracelets).
# Portrait : rbxassetid://95943150463525 (Renders/Creatures/R13_T2.png).
# Ce fichier est autonome (le Blender de Ropilot est partage : ne pas compter sur des variables globales).
import ropilot, bpy, os, math, mathutils
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R13_Refs")
REF2 = {v: os.path.join(R, f"Ref_R13_T2_{v}.png") for v in ("front", "left", "back", "top")}
PAL2 = dict(
    jade=dict(color="#3FB37F", noise=0.03, shade=0.14, mottle=("#4cc28c", 0.3, 4), top=0.12),
    jade_dark=dict(color="#1F6E4E", noise=0.03, shade=0.1),
    jade_light=dict(color="#8FE0B4", noise=0.025, shade=0.1, top=0.06, mottle=("#a2e8c2", 0.2, 3)),
    gold=dict(color="#F2C14E", noise=0.02, shade=0.12, top=0.15),
    gold_dark=dict(color="#B8862B", noise=0.02, shade=0.08),
    eye="#2A2420", white="#ffffff", blush="#f39a8c", mouth="#1F6E4E",
    glow=dict(color="#3EC9D6", glow=True),
    vein=dict(color="#5ec793", noise=0.02),
)
HZ2 = 2.55          # centre de la tete


def ext2(a, b, e=0.05):
    # allonge un segment de e aux deux bouts (les maillons de la queue se recouvrent)
    a, b = mathutils.Vector(a), mathutils.Vector(b)
    d = (b - a).normalized() * e
    return tuple(a - d), tuple(b + d)


def build_t2(m):
    MR = dict(mirror=True)
    m.box("Head", size=(1.52, 1.4, 1.55), at=(0, 0.06, HZ2), role="jade", chamfer=0.4, taper=(0.76, 1.0))
    m.box("Muzzle", size=(0.66, 0.42, 0.36), at=(0, -0.71, HZ2 - 0.3), role="jade_light", chamfer=0.12, taper=(0.86, 1))
    m.box("Eye_L", size=(0.3, 0.06, 0.4), at=(-0.26, -0.655, HZ2 + 0.12), role="eye", chamfer=0.04, **MR)
    m.box("Shine_L", size=(0.12, 0.04, 0.12), at=(-0.31, -0.69, HZ2 + 0.23), role="white", **MR)
    m.box("Shine2_L", size=(0.06, 0.04, 0.06), at=(-0.19, -0.69, HZ2 + 0.02), role="white", **MR)
    m.prism("Ear_L", radius=0.31, height=0.16, at=(-0.84, 0.02, HZ2 + 0.03), role="jade", sides=8, turn=22.5, rot=(90, 0, 0), **MR)
    m.prism("EarIn_L", radius=0.19, height=0.05, at=(-0.86, -0.08, HZ2 + 0.03), role="jade_light", sides=8, turn=22.5, rot=(90, 0, 0), **MR)
    m.box("Body", size=(0.96, 0.78, 1.22), at=(0, 0.05, 1.22), role="jade", chamfer=0.26, taper=(0.86, 0.85), faces={"bottom": "jade_dark"})
    sh, hd = (-0.45, 0.0, 1.62), (-0.66, -0.06, 0.8)
    m.beam("Arm_L", start=sh, end=hd, role="jade", width=0.27, depth=0.29, chamfer=0.08, **MR)
    m.box("Hand_L", size=(0.31, 0.33, 0.3), at=(-0.68, -0.08, 0.66), role="jade_light", chamfer=0.09, **MR)
    m.prism("Bracelet_L", radius=0.2, height=0.12, at=(-0.65, -0.06, 0.92), role="gold", sides=8, turn=22.5, rot=(0, 15, 0), **MR)
    m.box("Leg_L", size=(0.34, 0.4, 0.66), at=(-0.27, 0.05, 0.44), role="jade", chamfer=0.1, rot=(0, -4, 0), **MR)
    m.box("Foot_L", size=(0.46, 0.6, 0.16), at=(-0.32, -0.05, 0.08), role="jade_light", chamfer=0.05, **MR)
    # longue queue enroulee sur le cote (comme la reference)
    pts = [(0.15, 0.36, 0.78), (0.5, 0.36, 0.45), (0.85, 0.33, 0.3), (1.03, 0.3, 0.6), (1.07, 0.3, 1.1), (0.96, 0.3, 1.4), (0.78, 0.3, 1.44), (0.7, 0.3, 1.26)]
    w = [0.22, 0.2, 0.19, 0.18, 0.16, 0.15, 0.13]
    for i in range(len(pts) - 1):
        a, b = ext2(pts[i], pts[i + 1], 0.06 if i else 0.0)
        m.beam(f"Tail{i}", start=a, end=b, role="jade", width=w[i], depth=w[i], solo=True)
    return m


def details_t2(m):
    MR = dict(mirror=True)
    # diademe d'or et gemme turquoise sur le front
    m.box("Diadem", size=(0.86, 0.36, 0.1), at=m.surface("Head", "bevel_front_top", (0, 0)), role="gold", chamfer=0.03)
    m.box("DiademGem", size=(0.18, 0.18, 0.1), at=m.surface("Diadem", "top", (0, 0)), role="glow", rot=(0, 0, 45))
    # anneaux d'or aux chevilles, bande d'or sur la queue, gemmes des bracelets
    m.box("Anklet_L", size=(0.42, 0.48, 0.1), at=(-0.27, 0.05, 0.26), role="gold", chamfer=0.03, rot=(0, -4, 0), **MR)
    a, b = mathutils.Vector((0.5, 0.36, 0.45)), mathutils.Vector((0.85, 0.33, 0.3))
    m.beam("TailBand", start=tuple(a.lerp(b, 0.3)), end=tuple(a.lerp(b, 0.6)), role="gold", width=0.27, depth=0.27, solo=True)
    m.box("BraceletGem_L", size=(0.1, 0.06, 0.1), at=(-0.66, -0.27, 0.92), role="glow", rot=(0, 45, 0), **MR)
    return m


def paint_t2(m):
    # visage clair en coeur : deux ronds autour des yeux et le bas du visage
    m.circle("Head", "front", (-0.26, 0.12), 0.34, "jade_light")
    m.circle("Head", "front", (0.26, 0.12), 0.34, "jade_light")
    m.rect("Head", "front", (0, -0.22), (0.86, 0.42), "jade_light")
    m.rect("Head", "front", (-0.46, -0.16), (0.14, 0.07), "blush")
    m.rect("Head", "front", (0.46, -0.16), (0.14, 0.07), "blush")
    # narines et sourire sur le museau
    m.stamp("Muzzle", "front", (0, 0.06), ["K..K"], {"K": "eye"})
    m.line("Muzzle", "front", [(-0.2, -0.02), (-0.1, -0.08), (0, -0.09), (0.1, -0.08), (0.2, -0.02)], "mouth", 1)
    # ventre clair, veines de jade
    m.rect("Body", "front", (0, -0.08), (0.62, 0.78), "jade_light")
    for f, sg in (("left", 1), ("right", -1)):
        m.line("Body", f, [(sg * -0.25, 0.35), (sg * -0.05, 0.1), (sg * 0.1, 0.15), (sg * 0.25, -0.2)], "vein", 1)
        m.line("Head", f, [(sg * -0.4, 0.3), (sg * -0.15, 0.1), (sg * 0.1, 0.25), (sg * 0.35, 0.0)], "vein", 1)
    m.line("Head", "back", [(-0.4, 0.2), (-0.1, 0.0), (0.15, 0.15), (0.4, -0.15)], "vein", 1)
    m.line("Body", "back", [(-0.25, 0.3), (0.0, 0.05), (0.2, 0.15)], "vein", 1)
    # doigts et orteils
    m.stamp("Hand_L", "front", (0, -0.05), ["K.K"], {"K": "jade_dark"})
    m.stamp("Hand_R", "front", (0, -0.05), ["K.K"], {"K": "jade_dark"})
    m.stamp("Foot_L", "front", (0, 0), ["K.K.K"], {"K": "jade"})
    m.stamp("Foot_R", "front", (0, 0), ["K.K.K"], {"K": "jade"})
    # gravure sur les bracelets et le diademe
    for k in range(8):
        m.stamp("Bracelet_L", f"side{k}", (0, 0), ["D"], {"D": "gold_dark"})
        m.stamp("Bracelet_R", f"side{k}", (0, 0), ["D"], {"D": "gold_dark"})
    m.stamp("Diadem", "top", (0, 0), ["D.......D", ".D.....D."], {"D": "gold_dark"})
    return m


GROUPS_T2 = {'Head': ['Head', 'Muzzle', 'Eye_*', 'Shine*', 'Diadem*'],
             'EarL': ['Ear_L', 'EarIn_L'], 'EarR': ['Ear_R', 'EarIn_R'],
             'ArmL': ['Arm_L', 'Hand_L', 'Bracelet_L', 'BraceletGem_L'], 'ArmR': ['Arm_R', 'Hand_R', 'Bracelet_R', 'BraceletGem_R'],
             'LegL': ['Leg_L', 'Foot_L', 'Anklet_L'], 'LegR': ['Leg_R', 'Foot_R', 'Anklet_R'],
             'Tail': ['Tail*']}


def make_t2(save=True):
    m = ropilot.model("R13_T2", px=8, reset=True)
    m.reference(REF2)
    m.palette(**PAL2)
    build_t2(m); details_t2(m); paint_t2(m)
    print(m.build()); print(m.check()); print(m.compare(image=False)["report"])
    if save:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R13_T2.blend"), copy=True)
    return m
