# Brass Sky Whale (R10_T7, Cosmic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) redressee de 12 deg puis rendue en vues orthogonales
# (Renders/R10_Refs/Ref_R10_T7_*.png)
# Baleine colossale en coque de laiton rivetee faite de segments a grands chanfreins (section presque octogonale)
# le long d'une ligne (SP7), du museau arrondi a la queue relevee : bandes de cuivre aux jointures, ventre en
# plaques d'acier a sillons, grande machoire d'acier (rig Jaw) sous une bouche sombre a grille chromee (fanons),
# event de laiton qui fume sur la tete, yeux turquoise lumineux a reflets bas sur les cotes de la tete sous une
# arcade de cuivre, hublots turquoise cercles de laiton le long des flancs, deux cheminees de cuivre qui fument
# sur le dos, aileron de laiton, nageoires (rig FinL / FinR) faites d'un grand rouage dente a moyeu lumineux et de
# trois plaques articulees a charnieres lumineuses, queue (rig Tail) relevee qui s'affine jusqu'a une grande
# nageoire a deux lobes effiles.
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R10_Refs")
REF7 = {v: os.path.join(R, f"Ref_R10_T7_{v}.png") for v in ("front", "left", "back", "top")}
PAL7 = dict(
    brass=dict(color="#e0a84a", noise=0.03, shade=0.16, mottle=("#d69c40", 0.2, 4), top=0.14),
    brass_light=dict(color="#f5cf7a", noise=0.03, shade=0.1, top=0.12, rim=-0.2),
    brass_dark=dict(color="#b8822e", noise=0.03, shade=0.12),
    copper=dict(color="#c8703a", noise=0.035, shade=0.14, top=0.12),
    copper_dark=dict(color="#8e4a26", noise=0.03, shade=0.12),
    steel=dict(color="#7c8c9c", noise=0.03, shade=0.12, top=0.1),
    steel_dark=dict(color="#3e4a58", noise=0.03, shade=0.1),
    chrome=dict(color="#c9d4de", noise=0.02, shade=0.1, top=0.12, rim=-0.2),
    steam=dict(color="#eaf8f6", noise=0.02, shade=0.1, top=0.08),
    mouth="#1a1424", eye="#16202c", shine="#ffffff",
    glow=dict(color="#5ae6d2", glow=True),
)
# ligne du dos (y, z), hauteur au debut de chaque segment ; largeur au debut (la fin suit la hauteur : le kit
# retrecit largeur et hauteur du meme facteur)
SP7 = [(-10.8, 4.85), (-8.6, 5.55), (-6.0, 5.6), (-2.6, 5.5), (0.8, 5.8), (3.8, 6.3), (6.2, 7.2), (8.0, 8.35), (8.9, 9.0)]
H7 = [2.1, 5.0, 6.1, 6.1, 5.2, 3.7, 2.4, 1.4, 1.0]
W7 = [2.4, 5.6, 6.7, 6.7, 5.8, 4.1, 2.6, 1.5, 1.05]
FTIP = (-7.0, 0.1, 0.02)                    # bout de la nageoire gauche (la racine est calculee sur le flanc)
FL_ROOT, FL_TIP = (0.0, 8.75, 9.05), (-5.1, 10.0, 10.75)   # nageoire de queue : depart et bout du lobe gauche


def mid(a, b, t=0.5):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def frame7(i):
    (y0, z0), (y1, z1) = SP7[i], SP7[i + 1]
    L = math.hypot(y1 - y0, z1 - z0)
    dy, dz = (y1 - y0) / L, (z1 - z0) / L
    return (y0, z0), (y1, z1), (dy, dz), (dz, -dy), L      # n = cote du ventre


def ch7(i):
    return min(1.8, 0.29 * min(W7[i], H7[i]))


def body_at(y):
    # demi-largeur, centre z, demi-hauteur et chanfrein du corps a la position y
    for i in range(len(SP7) - 1):
        y0, y1 = SP7[i][0], SP7[i + 1][0]
        if y0 <= y <= y1:
            t = (y - y0) / (y1 - y0)
            k = 1 + (H7[i + 1] / H7[i] - 1) * t
            return W7[i] * k / 2, SP7[i][1] + (SP7[i + 1][1] - SP7[i][1]) * t, H7[i] * k / 2, ch7(i) * k
    return W7[-1] / 2, SP7[-1][1], H7[-1] / 2, ch7(len(SP7) - 2)


def side_x(y, z):
    # x du flanc gauche a la hauteur z (tient compte du chanfrein)
    hw, zc, hh, c = body_at(y)
    over = abs(z - zc) - (hh - c)
    return -(hw - max(0.0, over))


def build_t7(m):
    MR = dict(mirror=True)
    n_seg = len(SP7) - 1
    # ---- coque : segments de laiton, ventre d'acier, bandes de cuivre aux jointures
    for i in range(n_seg):
        (y0, z0), (y1, z1), (dy, dz), (ny, nz), L = frame7(i)
        e = 0.15
        m.beam(f"Seg{i}", start=(0, y0 - dy * (e if i else 0), z0 - dz * (e if i else 0)), end=(0, y1 + dy * e, z1 + dz * e), role="brass",
               width=W7[i], depth=H7[i], taper=H7[i + 1] / H7[i], chamfer=ch7(i))
        if 2 <= i <= 4:
            o, o1 = H7[i] / 2 - 0.2, H7[i + 1] / 2 - 0.2
            m.beam(f"Belly{i}", start=(0, y0 + ny * o, z0 + nz * o), end=(0, y1 + ny * o1, z1 + nz * o1), role="steel",
                   width=W7[i] * 0.62, depth=0.6, taper=H7[i + 1] / H7[i], chamfer=0.15)
        if 1 <= i < n_seg:
            (py, pz) = SP7[i]
            _, _, (ady, adz), _, _ = frame7(i - 1)
            ty, tz = ady + dy, adz + dz
            tl = math.hypot(ty, tz)
            ty, tz = ty / tl, tz / tl
            # bague octogonale (un prisme : un pave mince ne peut pas avoir de grands chanfreins)
            wprev = W7[i - 1] * H7[i] / H7[i - 1]
            ap = (max(W7[i], wprev, H7[i]) / 2 + 0.06)
            m.prism(f"Ring{i}", radius=ap / math.cos(math.radians(22.5)), height=0.34, at=(0, py, pz), role="copper", sides=8,
                    rot=(math.degrees(math.atan2(-ty, tz)), 0, 0))
    # ---- tete : grande machoire d'acier (rig Jaw), bouche sombre et grille chromee (fanons) au bout du museau
    m.box("Jaw", size=(4.3, 5.1, 1.45), at=(0, -7.75, 2.95), role="steel", chamfer=0.6, axis="y", taper=(0.66, 0.55), faces={"top": "mouth"})
    m.box("Mouth", size=(2.6, 4.0, 0.5), at=(0, -8.35, 3.68), role="mouth", axis="y", taper=(0.8, 1))
    for k in range(5):
        x = -1.0 + k * 0.5
        m.box(f"Baleen{k}", size=(0.16, 0.14, 0.5), at=(x, -10.38 + abs(x) * 0.15, 3.68), role="chrome", solo=True)
    # event sur la tete, qui fume
    m.prism("BlowRing", radius=0.55, height=0.32, at=(0, -7.2, 8.42), role="brass_dark", sides=8)
    m.prism("BlowHole", radius=0.34, height=0.06, at=(0, -7.2, 8.6), role="steel_dark", sides=8)
    m.box("BlowSteam0", size=(0.85, 0.85, 0.6), at=(0, -7.1, 8.9), role="steam", chamfer=0.25)
    m.box("BlowSteam1", size=(0.6, 0.6, 0.45), at=(0, -6.75, 9.35), role="steam", chamfer=0.18)
    # yeux turquoise lumineux bas sur les cotes de la tete ; arcade de cuivre presque droite (regard fier)
    ex = side_x(-7.4, 5.0)
    m.box("Eye_L", size=(0.18, 1.32, 1.18), at=(ex, -7.4, 4.98), role="eye", chamfer=0.06, **MR)
    m.box("Iris_L", size=(0.12, 1.12, 1.0), at=(ex - 0.07, -7.43, 4.96), role="glow", **MR)
    m.box("Pupil_L", size=(0.1, 0.34, 0.52), at=(ex - 0.12, -7.48, 4.92), role="eye", **MR)
    m.box("Shine_L", size=(0.08, 0.34, 0.34), at=(ex - 0.15, -7.77, 5.3), role="shine", **MR)
    m.box("Shine2_L", size=(0.08, 0.18, 0.18), at=(ex - 0.15, -7.26, 4.7), role="shine", **MR)
    m.beam("Brow_L", start=(side_x(-6.4, 5.85) + 0.02, -6.4, 5.85), end=(side_x(-8.4, 5.8) + 0.02, -8.4, 5.8), role="copper_dark", width=0.34,
           depth=0.32, chamfer=0.05, **MR)
    # ---- hublots turquoise cercles de laiton le long des flancs
    for k, y in enumerate((-4.3, -1.6, 1.1, 3.7)):
        hw, zc, hh, c = body_at(y)
        z = zc + 0.25
        x = side_x(y, z)
        r = 0.62 if k < 3 else 0.5
        m.prism(f"Port{k}_L", radius=r, height=0.2, at=(x - 0.05, y, z), role="brass_light", sides=8, rot=(0, 90, 0), turn=22.5, **MR)
        m.prism(f"PortGlass{k}_L", radius=r * 0.66, height=0.12, at=(x - 0.13, y, z), role="glow", sides=8, rot=(0, 90, 0), turn=22.5, **MR)
    # ---- deux cheminees de cuivre qui fument sur le dos
    x, y = -1.15, -1.3
    m.prism("ChimBase_L", radius=0.8, height=0.5, at=(x, y, 8.55), role="brass", sides=8, **MR)
    m.prism("Chimney_L", radius=0.56, height=1.2, at=(x, y, 9.3), role="copper", sides=8, **MR)
    m.prism("ChimBand_L", radius=0.62, height=0.18, at=(x, y, 9.3), role="copper_dark", sides=8, **MR)
    m.prism("ChimRim_L", radius=0.7, height=0.3, at=(x, y, 9.95), role="brass_dark", sides=8, **MR)
    m.box("Steam0_L", size=(1.15, 1.15, 0.75), at=(x, y + 0.2, 10.42), role="steam", chamfer=0.33, **MR)
    m.box("Steam1_L", size=(0.85, 0.85, 0.6), at=(x * 0.9, y + 0.8, 10.9), role="steam", chamfer=0.26, **MR)
    # ---- aileron de laiton
    m.box("Dorsal", size=(0.4, 1.8, 1.1), at=(0, 4.1, 8.45), role="brass_dark", chamfer=0.06, taper=(1, 0.35), shear=(0, 0.6))
    # ---- nageoires (rig FinL / FinR) : grand rouage dente a moyeu lumineux, trois plaques articulees, charnieres lumineuses
    fy, fz = -3.7, 3.7
    fx = side_x(fy, fz)
    froot = (fx - 0.15, fy, fz)
    m.prism("FinGear_L", radius=1.15, height=0.36, at=froot, role="brass_light", sides=12, rot=(0, 90, 0), turn=15, **MR)
    for k in (0, 1, 2, 9, 10, 11):     # dents visibles (les autres entrent dans le flanc)
        a = math.radians(k * 30)
        m.box(f"FinTooth{k}_L", size=(0.3, 0.32, 0.36), at=(froot[0], fy + math.cos(a) * 1.22, fz + math.sin(a) * 1.22), role="brass_dark",
              rot=(k * 30, 0, 0), **MR)
    m.prism("FinHub_L", radius=0.5, height=0.5, at=(froot[0] - 0.2, fy, fz), role="copper", sides=8, rot=(0, 90, 0), **MR)
    m.prism("FinHubGlow_L", radius=0.26, height=0.1, at=(froot[0] - 0.48, fy, fz), role="glow", sides=6, rot=(0, 90, 0), **MR)
    J = [froot, mid(froot, FTIP, 0.36), mid(froot, FTIP, 0.69), FTIP]
    FW = [2.8, 2.3, 1.7, 0.5]
    roles = ("brass", "copper", "brass")
    for k in range(3):
        a, b = J[k], J[k + 1]
        a2 = mid(a, b, -0.08) if k else mid(a, b, 0.1)
        b2 = mid(a, b, 1.06) if k < 2 else b
        m.beam(f"FinPlate{k}_L", start=a2, end=b2, role=roles[k], width=FW[k], depth=0.36 - 0.03 * k, taper=FW[k + 1] / FW[k], chamfer=0.08, **MR)
        if k:
            m.beam(f"FinHinge{k}_L", start=mid(a, b, -0.05), end=mid(a, b, 0.05), role="glow", width=FW[k] * 0.5, depth=0.44, **MR)
    # ---- queue (rig Tail) : grande nageoire a deux lobes effiles, moyeu de cuivre
    m.box("FlukeHub", size=(1.3, 1.3, 1.0), at=FL_ROOT, role="copper", chamfer=0.25)
    m.beam("Fluke_L", start=FL_ROOT, end=FL_TIP, role="brass", width=2.9, depth=0.45, taper=0.3, chamfer=0.1, **MR)
    m.beam("FlukeEdge_L", start=mid(FL_ROOT, FL_TIP, 0.15), end=FL_TIP, role="brass_light", width=0.5, depth=0.5, taper=0.4, **MR)
    # ---- peinture : rivets, joints de plaques, sillons du ventre et de la machoire
    for i in range(n_seg - 1):
        _, _, _, _, L = frame7(i)
        hh = H7[i] / 2
        nr = max(2, int(L / 0.75))
        for face in ("left", "right"):
            for k in range(nr):
                u = -L / 2 + (k + 0.5) * L / nr
                m.rect(f"Seg{i}", face, (u, hh * 0.5), (0.14, 0.14), "brass_light")
                m.rect(f"Seg{i}", face, (u, -hh * 0.42), (0.14, 0.14), "brass_dark")
        m.line(f"Seg{i}", "top", [(-W7[i] * 0.2, -L / 2), (-W7[i] * 0.2, L / 2)], "brass_dark", 1)
        m.line(f"Seg{i}", "top", [(W7[i] * 0.2, -L / 2), (W7[i] * 0.2, L / 2)], "brass_dark", 1)
    for i in range(2, 5):
        _, _, _, _, L = frame7(i)
        for u in (-0.75, -0.25, 0.25, 0.75):
            m.line(f"Belly{i}", "bottom", [(u * W7[i] * 0.3, -L / 2), (u * W7[i] * 0.3, L / 2)], "steel_dark", 1)
    for k in (-1.1, -0.37, 0.37, 1.1):
        m.line("Jaw", "bottom", [(k, -2.2), (k, 2.2)], "steel_dark", 1)
    # commissure de la bouche qui remonte vers l'oeil (ligne sombre sur les flancs de la tete)
    for face in ("left", "right"):
        m.line("Seg1", face, [(1.3, -1.05), (0.4, -1.05), (-0.3, -0.75)], "mouth", 2)
    for k in range(3):
        m.line(f"FinPlate{k}_L", "top", [(0, -0.6), (0, 0.6)], "brass_dark", 1)
    return m


m7 = ropilot.model("R10_T7", px=8, reset=True)
m7.reference(REF7)
m7.palette(**PAL7)
build_t7(m7)
print(m7.build()); print(m7.check()); print(m7.compare()["report"])
ropilot.check_model(collection="R10_T7", max_lines=8)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R10_T7.blend"), copy=True)


def fin7(s):
    return ['FinGear_' + s, 'FinTooth*_' + s, 'FinHub_' + s, 'FinHubGlow_' + s, 'FinPlate*_' + s, 'FinHinge*_' + s]


GROUPS_T7 = {'Jaw': ['Jaw'],
             'FinL': fin7('L'), 'FinR': fin7('R'),
             'Tail': ['Seg6', 'Seg7', 'Ring7', 'Fluke*']}
# --- suite : exec(rigjoin.py), rig_join("R10_T7", GROUPS_T7), save R10_T7_rig.blend, import -> Work_R10_T7,
# CreatureRig.Install(workspace.Work_R10_T7, "R10_T7", nil, true), puis joints corriges dans le repere du Core :
# FinL/R (+-2.9, 3.7, -3.43) au moyeu du rouage, Jaw (0, 3.6, -4.93) a la charniere, Tail (0, 7.2, 6.47) a la racine de la queue
# Pas de role Head (la tete fait partie du corps : pas de fente au cou) ; la machoire s'ouvre seule pour rugir.
# compare() final : face 0.67, dos 0.67, gauche 0.66, dessus 0.82 : la reference est une baleine arrondie aux nageoires tres
# tombantes et a la nageoire de queue dressee ; ici coque en segments chanfreines, lobes de queue plus plats
