# Lantern Squid (R14_T4, Epic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R14_Refs/Ref_R14_T4_*.png)
# Calmar fantome amical turquoise pale : manteau en gros bloc chanfreine qui s'affine, grande pointe a 8 pans,
# nageoires de calmar en losange de chaque cote de la pointe, rebord turquoise moyen et dessous turquoise sombre ;
# gros yeux separes (bas d'iris turquoise sombre, deux reflets), sourire, joues, ventre clair ; taches spectrales
# sur les cotes et le dos ; feu follet turquoise lumineux au sommet (socle ardoise) et gemme lumineuse sur le front ;
# huit tentacules : six au sol qui s'enroulent au bout, deux bras qui tiennent chacun une lanterne de fer (anse,
# chapeau, montants, socle) a flamme turquoise (Neon).
# compare() final : face 0.69, dos 0.69, gauche 0.76, dessus 0.55 (79 pieces, 2 160 triangles, 4,44 x 4,21 x 5,38).
# Ecarts voulus : la reference n'a pas de nageoires (ajoutees pour lire « calmar » et non « pieuvre »), son manteau
# est un cylindre lisse qui descend plus bas, et ses tentacules (8 au sol + bras) font une couronne plus dense ;
# un manteau octogonal fidele laissait un visage minuscule (lisait « crayon » / « fusee ») : le bloc chanfreine
# donne une grande face plate pour les yeux. Dessus 0.55 : la couronne de tentacules de la reference est plus fournie.
# check_model : 0 piece flottante ou cachee, 0 arete ouverte (gaps = maillons voisins des tentacules).
# Piege du kit : peindre hors de la face plate (sur un chanfrein, ou sur les faces triangulaires d'un cone) fait
# boucler Blender (delai depasse puis redemarrage) : ne peindre que dans la face.
# --- suite : make_t4(), exec(rigjoin.py), rig_join("R14_T4", GROUPS_T4), save R14_T4_rig.blend, import ->
# Work_R14_T4, CreatureRig.Install(workspace.Work_R14_T4, "R14_T4", nil, true), puis joints corriges dans le repere
# du Core (y = z Blender - 0.05) : ArmL/ArmR (+-0.82, 1.9, 0) (epaules des bras porte-lanterne), FinL/FinR
# (+-0.6, 3.9, 0) (racine des nageoires), Tentacles (0, 0.8, 0) (sous le manteau). Lueurs : ArmL__Glow / ArmR__Glow
# (flammes, Follow), feu follet + gemme du front = Body2 (Neon).
# Portrait : rbxassetid://92902962109031 (Renders/Creatures/R14_T4.png).
# Ce fichier est autonome (le Blender de Ropilot est partage : ne pas compter sur des variables globales).
import ropilot, bpy, os, math, mathutils
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R14_Refs")
REF_B4 = {v: os.path.join(R, f"Ref_R14_T4_{v}.png") for v in ("front", "left", "back", "top")}
PAL_B4 = dict(
    ghost=dict(color="#A8F0E4", noise=0.025, shade=0.1, top=0.1, mottle=("#b8f5ea", 0.25, 4)),
    ghost_mid=dict(color="#7FD9CC", noise=0.03, shade=0.1),
    ghost_dark=dict(color="#2FA79A", noise=0.03, shade=0.1),
    ghost_light=dict(color="#E8FFFB", noise=0.02, shade=0.06),
    sucker=dict(color="#F6E9C8", noise=0.02),
    iron=dict(color="#2C2A36", noise=0.03, shade=0.1, top=0.12),
    iron_light=dict(color="#4A5868", noise=0.03, shade=0.1, top=0.1),
    violet=dict(color="#7A5AB8", noise=0.02, shade=0.1),
    eye="#1E2A3A", white="#ffffff", blush="#F7A3B3", mouth="#1E2A3A", iris="#2FA79A",
    glow=dict(color="#2FD9C0", glow=True),
)
LEG_R4 = [(0.6, 0.85), (1.1, 0.42), (1.5, 0.22), (1.82, 0.22), (1.98, 0.46), (1.84, 0.64)]   # (rayon, z) le long d'un tentacule
LEG_W4 = [0.52, 0.44, 0.36, 0.28, 0.22, 0.16]
LEG_ANG4 = [30, 90, 150, 210, 270, 330]
ARM_R4 = [(0.8, 1.95), (1.3, 2.1), (1.72, 2.02), (1.96, 1.8), (1.92, 1.58)]
ARM_W4 = [0.4, 0.33, 0.27, 0.21, 0.17]


def ext4(a, b, e=0.05):
    a, b = mathutils.Vector(a), mathutils.Vector(b)
    d = (b - a).normalized() * e
    return tuple(a - d), tuple(b + d)


def polar4(r, z, ang):
    a = math.radians(ang)
    return (r * math.cos(a), r * math.sin(a), z)


def chain4(m, name, pts, widths, role="ghost", over=0.06, chamfer=0.0):
    for i in range(len(pts) - 1):
        a, b = ext4(pts[i], pts[i + 1], over if i else 0.0)
        w = widths[i]
        m.beam(f"{name}{i}", start=a, end=b, role=role, width=w, depth=w, taper=widths[i + 1] / w if i + 1 < len(widths) else 0.8,
               chamfer=chamfer if w > 0.25 else 0.0, solo=True)


def lantern4(m, sfx, x, top):
    # lanterne de fer suspendue : anse, chapeau, montants, socle, flamme turquoise
    y = 0.0
    m.beam(f"Handle{sfx}0", start=(x - 0.14, y, top - 0.12), end=(x - 0.06, y, top + 0.05), role="iron", width=0.05, depth=0.05, solo=True)
    m.beam(f"Handle{sfx}1", start=(x + 0.14, y, top - 0.12), end=(x + 0.06, y, top + 0.05), role="iron", width=0.05, depth=0.05, solo=True)
    m.box(f"HandleTop{sfx}", size=(0.18, 0.05, 0.05), at=(x, y, top + 0.05), role="iron", solo=True)
    m.prism(f"LCap{sfx}", radius=0.3, height=0.18, at=(x, y, top - 0.2), role="iron", sides=4, turn=45, taper=0.45, solo=True)
    m.box(f"LTop{sfx}", size=(0.44, 0.44, 0.06), at=(x, y, top - 0.31), role="iron_light", solo=True)
    m.box(f"Flame{sfx}", size=(0.28, 0.28, 0.4), at=(x, y, top - 0.54), role="glow", solo=True)
    for i, (dx, dy) in enumerate(((-1, -1), (1, -1), (-1, 1), (1, 1))):
        m.box(f"Post{sfx}{i}", size=(0.06, 0.06, 0.44), at=(x + dx * 0.17, y + dy * 0.17, top - 0.54), role="iron", solo=True)
    m.box(f"LBase{sfx}", size=(0.44, 0.44, 0.08), at=(x, y, top - 0.78), role="iron_light", solo=True)
    m.prism(f"LFoot{sfx}", radius=0.2, height=0.08, at=(x, y, top - 0.86), role="iron", sides=4, turn=45, taper=0.6, rot=(180, 0, 0), solo=True)


MW4, MD4, MH4, MZ4 = 2.1, 1.9, 2.4, 2.1      # manteau : largeur, profondeur, hauteur, centre z
MCH4, MTP4 = 0.42, 0.84                       # chanfrein et retrecissement du manteau


def build_b4(m):
    MR = dict(mirror=True)
    # manteau : gros bloc chanfreine qui s'affine, pointe a 8 pans, rebord et dessous turquoise sombre
    m.box("Mantle", size=(MW4, MD4, MH4), at=(0, 0, MZ4), role="ghost", chamfer=MCH4, taper=(MTP4, MTP4))
    m.prism("Cone", radius=1.0, height=2.0, at=(0, 0, MZ4 + MH4 / 2 + 0.66), role="ghost", sides=8, turn=22.5, taper=0.0)
    m.prism("Rim", radius=1.18, height=0.34, at=(0, 0, 0.92), role="ghost_mid", sides=8, turn=22.5, taper=0.88, faces={"bottom": "ghost_dark"})
    m.prism("Under", radius=0.86, height=0.3, at=(0, 0, 0.66), role="ghost_dark", sides=8, turn=22.5)
    # nageoires de calmar en losange de chaque cote de la pointe
    m.box("Fin_L", size=(0.72, 0.1, 0.72), at=(-0.98, 0, 3.95), role="ghost_mid", chamfer=0.03, rot=(0, 45, 0), **MR)
    for k, ang in enumerate(LEG_ANG4):
        chain4(m, f"Leg{k}_", [polar4(r, z, ang) for r, z in LEG_R4], LEG_W4, chamfer=0.07)
    chain4(m, "ArmA_L", [polar4(r, z, 180) for r, z in ARM_R4], ARM_W4, chamfer=0.06)
    chain4(m, "ArmA_R", [polar4(r, z, 0) for r, z in ARM_R4], ARM_W4, chamfer=0.06)
    lantern4(m, "_L", -1.92, 1.52)
    lantern4(m, "_R", 1.92, 1.52)
    return m


def details_b4(m):
    MR = dict(mirror=True)
    ez = 2.45
    fy = -(MD4 / 2) * (1 - (1 - MTP4) * (ez - (MZ4 - MH4 / 2)) / MH4) - 0.02   # face avant du manteau a la hauteur des yeux
    m.box("Eye_L", size=(0.46, 0.14, 0.62), at=(-0.36, fy, ez), role="eye", chamfer=0.1, **MR)
    m.box("Iris_L", size=(0.34, 0.06, 0.2), at=(-0.36, fy - 0.07, ez - 0.16), role="iris", chamfer=0.04, **MR)
    m.box("Shine_L", size=(0.18, 0.04, 0.18), at=(-0.42, fy - 0.09, ez + 0.13), role="white", **MR)
    m.box("Shine2_L", size=(0.08, 0.04, 0.08), at=(-0.26, fy - 0.09, ez - 0.03), role="white", **MR)
    # feu follet au sommet, gemme spectrale sur le front
    m.prism("WispBase", radius=0.2, height=0.12, at=(0, 0, MZ4 + MH4 / 2 + 1.66), role="iron_light", sides=4, turn=45, taper=0.7)
    m.prism("Wisp", radius=0.15, height=0.42, at=(0, 0, MZ4 + MH4 / 2 + 1.92), role="glow", sides=4, turn=45, taper=0.0)
    m.box("Brow", size=(0.2, 0.06, 0.2), at=(0, -(MD4 / 2) * (1 - (1 - MTP4) * 0.82) - 0.03, 3.05), role="glow", rot=(0, 45, 0))
    return m


def paint_b4(m):
    # attention : peindre hors de la face plate (sur un chanfrein) bloque Blender (le kit boucle)
    m.rect("Mantle", "front", (0, -0.52), (1.2, 0.4), "ghost_light")
    m.stamp("Mantle", "front", (0, -0.22), ["K......K", ".KK..KK.", "...KK..."], {"K": "mouth"}, cell=0.05)
    m.rect("Mantle", "front", (-0.58, -0.12), (0.16, 0.07), "blush")
    m.rect("Mantle", "front", (0.58, -0.12), (0.16, 0.07), "blush")
    for f in ("left", "right", "back"):
        m.circle("Mantle", f, (0.25, 0.45), 0.13, "ghost_mid")
        m.circle("Mantle", f, (-0.3, 0.05), 0.1, "ghost_mid")
        m.circle("Mantle", f, (0.15, -0.4), 0.08, "ghost_mid")
    return m


def save_col_b4(col, fname):
    p = os.path.join(ropilot.FILES_DIR, fname)
    bpy.data.libraries.write(p, {bpy.data.collections[col]}, fake_user=True)
    return p


def make_t4(save=True, image=False):
    m = ropilot.model("R14_T4", px=8, reset=True)
    m.reference(REF_B4); m.palette(**PAL_B4)
    build_b4(m); details_b4(m); paint_b4(m)
    print(m.build()); print(m.check()); print(m.compare(image=image)["report"])
    if save:
        save_col_b4("R14_T4", "R14_T4.blend")
    return m


def _lantern_groups(s):
    return [f'ArmA_{s}*', f'Handle_{s}*', f'HandleTop_{s}', f'LCap_{s}', f'LTop_{s}', f'Flame_{s}', f'Post_{s}*', f'LBase_{s}', f'LFoot_{s}']


GROUPS_T4 = {'Tentacles': ['Leg*'], 'ArmL': _lantern_groups('L'), 'ArmR': _lantern_groups('R'), 'FinL': ['Fin_L'], 'FinR': ['Fin_R']}
