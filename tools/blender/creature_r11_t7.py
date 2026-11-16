# Cotton Candy Unicorn (R11_T7, Cosmic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R11_Refs/Ref_R11_T7_*.png)
# Licorne ailee colossale : corps blanc-creme (poitrail, tonneau, croupe), cou cambre, tete de cheval a museau
# rose pale, grands yeux separes visibles de face et de profil (iris raisin, pupille, reflets, cils), oreilles
# (rig EarL / EarR) ; corne en sucre d'orge torsadee rouge et blanche a bague doree et pointe lumineuse ; criniere,
# toupet et queue (rig Tail) en grosses masses de barbe a papa rose et bleue, la queue s'affine vers le bas ;
# collier de dragees bleues ; grandes ailes (rig WingL / WingR) : bras dore, plumes en gaufrette quadrillee
# terminees par du sucre file rose ou bleu ; pattes (rig LegFL/FR/BL/BR) a touffes de barbe a papa et sabots
# dores ; petites etoiles de sucre lumineuses sur les ailes, la criniere et la queue.
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R11_Refs")
REF7 = {v: os.path.join(R, f"Ref_R11_T7_{v}.png") for v in ("front", "left", "back", "top")}
PAL7 = dict(
    coat=dict(color="#fff6ec", noise=0.025, shade=0.08, mottle=("#fbe9ef", 0.25, 4), top=0.08),
    coat_shade=dict(color="#f3dde6", noise=0.025, shade=0.1),
    snout=dict(color="#ffe3ef", noise=0.02, shade=0.12, top=0.08),
    cc_pink=dict(color="#ff8cc8", noise=0.04, shade=0.14, mottle=("#ffb0d8", 0.4, 3), top=0.15),
    cc_pink_l=dict(color="#ffc4e1", noise=0.04, shade=0.12, mottle=("#ffd8ec", 0.35, 3), top=0.12),
    cc_blue=dict(color="#7fd0ff", noise=0.04, shade=0.14, mottle=("#a8e0ff", 0.4, 3), top=0.15),
    cc_blue_l=dict(color="#bfe8ff", noise=0.04, shade=0.12, mottle=("#d6f1ff", 0.35, 3), top=0.12),
    gold=dict(color="#ffc83a", noise=0.03, shade=0.16, top=0.15, rim=-0.22),
    gold_dark=dict(color="#d99a1c", noise=0.03, shade=0.12),
    wafer=dict(color="#ffd98a", noise=0.03, shade=0.12, top=0.1, rim=-0.25),
    cane=dict(color="#fff6ec", noise=0.02, shade=0.1, top=0.1),
    cane_red=dict(color="#e8344e", noise=0.02, shade=0.12, top=0.12),
    dragee=dict(color="#7fd0ff", noise=0.02, shade=0.12, top=0.2, rim=-0.25),
    white="#ffffff", iris="#7a4fc0", eye="#24161c", shine="#ffffff", mouth="#c0507e",
    glow=dict(color="#ffd23a", glow=True), glow_pink=dict(color="#ff4fae", glow=True),
)
WR, WE, WT = (-1.6, -1.0, 7.9), (-4.4, -0.9, 11.2), (-7.9, -0.2, 14.0)      # aile gauche : racine, poignet, bout
FEATH = [(0.04, 2.4), (0.16, 2.8), (0.28, 3.2), (0.4, 3.5), (0.52, 3.8), (0.64, 4.0), (0.76, 3.9), (0.88, 3.6), (1.0, 3.1)]
FDIR = (-0.22, 0.5, -0.84)          # direction des plumes (vers l'arriere, le bas, l'exterieur)
TAIL7 = [(0, 4.6, 7.4), (0, 5.9, 7.0), (0, 6.8, 5.9), (0, 7.3, 4.5), (0, 7.4, 3.1), (0, 7.2, 1.8), (0, 6.9, 0.95)]
TS7 = [2.1, 2.3, 2.2, 1.95, 1.65, 1.3, 0.95]
NECK0, NECK1 = (0, -3.0, 7.0), (0, -5.2, 10.8)
HO = (0, -0.7, 0.4)                  # tete avancee et relevee (par rapport au premier jet)
HK, HC = 1.2, (0, -5.0, 11.3)        # tete agrandie de HK autour du centre du crane
CP = ("cc_pink", "cc_blue", "cc_pink_l", "cc_blue_l")


def mid(a, b, t=0.5):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def add(a, b, k=1.0):
    return tuple(a[i] + b[i] * k for i in range(3))


def HP(x, y, z):
    return tuple(HC[i] + ((x, y, z)[i] - HC[i]) * HK + HO[i] for i in range(3))


def HS(*v):
    return tuple(c * HK for c in v)


def norm(v):
    L = math.sqrt(sum(c * c for c in v))
    return tuple(c / L for c in v)


def wing_point(s):
    # point du bord d'attaque, s de 0 (racine) a 1 (bout)
    if s <= 0.45:
        return mid(WR, WE, s / 0.45)
    return mid(WE, WT, (s - 0.45) / 0.55)


def star(m, name, at, size, role="glow", plane="xz", **kw):
    # etoile de sucre a quatre branches : deux barreaux croises
    sfx = "_L" if kw.get("mirror") else ""
    if plane == "xz":
        m.box(name + "A" + sfx, size=(size, 0.2, 0.14), at=at, role=role, rot=(0, 45, 0), **kw)
        m.box(name + "B" + sfx, size=(size, 0.2, 0.14), at=at, role=role, rot=(0, -45, 0), **kw)
    else:
        m.box(name + "A" + sfx, size=(0.2, size, 0.14), at=at, role=role, rot=(45, 0, 0), **kw)
        m.box(name + "B" + sfx, size=(0.2, size, 0.14), at=at, role=role, rot=(-45, 0, 0), **kw)


def cloud(m, name, at, s, k):
    # masse de barbe a papa : gros bloc tres chanfreine et deux bosses plus petites d'une autre couleur
    sg = 1 if k % 2 else -1
    m.box(name, size=(s * 0.95, s, s * 0.88), at=at, role=CP[k % 4], chamfer=s * 0.32, solo=True)
    m.box(name + "a", size=(s * 0.62, s * 0.62, s * 0.58), at=add(at, (0.36 * s * sg, 0.12 * s, 0.33 * s)), role=CP[(k + 1) % 4],
          chamfer=s * 0.2, solo=True)
    m.box(name + "b", size=(s * 0.55, s * 0.55, s * 0.5), at=add(at, (-0.33 * s * sg, -0.22 * s, 0.25 * s)), role=CP[(k + 2) % 4],
          chamfer=s * 0.18, solo=True)


def build_t7(m, roll=45.0):
    MR = dict(mirror=True)
    # ---- pattes avant (rig LegFL / LegFR) : bras, canon, touffe de barbe a papa, sabot dore
    m.beam("FUpper_L", start=(-1.35, -3.1, 5.3), end=(-1.35, -3.3, 2.3), role="coat", width=1.45, depth=1.55, chamfer=0.3, taper=0.85, **MR)
    m.beam("FLower_L", start=(-1.35, -3.3, 2.45), end=(-1.35, -3.35, 1.0), role="coat", width=1.15, depth=1.25, chamfer=0.2, **MR)
    m.box("FFluff_L", size=(1.9, 2.0, 0.95), at=(-1.35, -3.37, 1.25), role="cc_blue", chamfer=0.4, **MR)
    m.box("FHoof_L", size=(1.55, 1.7, 0.85), at=(-1.35, -3.42, 0.43), role="gold", chamfer=0.15, **MR)
    # ---- pattes arriere (rig LegBL / LegBR) : cuisse, jarret, canon, touffe, sabot
    m.box("Thigh_L", size=(1.8, 2.7, 2.8), at=(-1.4, 3.3, 5.15), role="coat", chamfer=0.65, rot=(-10, 0, 0), **MR)
    m.beam("BUpper_L", start=(-1.4, 3.75, 4.1), end=(-1.4, 4.25, 2.3), role="coat", width=1.3, depth=1.4, chamfer=0.25, **MR)
    m.beam("BLower_L", start=(-1.4, 4.25, 2.45), end=(-1.4, 3.95, 1.0), role="coat", width=1.15, depth=1.25, chamfer=0.2, **MR)
    m.box("BFluff_L", size=(1.9, 2.0, 0.95), at=(-1.4, 3.93, 1.25), role="cc_pink", chamfer=0.4, **MR)
    m.box("BHoof_L", size=(1.55, 1.7, 0.85), at=(-1.4, 3.88, 0.43), role="gold", chamfer=0.15, **MR)
    # ---- corps : poitrail, tonneau, croupe ; ventre rose pale
    m.box("Chest", size=(3.9, 3.3, 3.8), at=(0, -2.5, 6.05), role="coat", chamfer=1.1, faces={"bottom": "coat_shade"})
    m.box("Barrel", size=(3.8, 3.8, 3.5), at=(0, 0.5, 5.95), role="coat", chamfer=1.1, faces={"bottom": "coat_shade"})
    m.box("Rump", size=(4.0, 3.0, 3.7), at=(0, 3.2, 6.1), role="coat", chamfer=1.1, faces={"bottom": "coat_shade"})
    # ---- cou cambre, collier de dragees bleues
    m.beam("Neck", start=NECK0, end=NECK1, role="coat", width=2.1, depth=2.4, taper=0.85, chamfer=0.6)
    nc = mid(NECK0, NECK1, 0.18)
    for k, a in enumerate((-70, -35, 0)):
        r = math.radians(a)
        p = add(nc, (1.12 * math.sin(r), -1.18 * math.cos(r), -0.5 * math.cos(r)))
        m.box(f"Dragee{k}" + ("_L" if a else ""), size=(0.62, 0.62, 0.62), at=p, role="dragee", chamfer=0.2, rot=(0, 0, a), mirror=bool(a))
    # ---- tete (rig Head) : crane, museau rose pale, joues, naseaux, sourire
    m.box("Skull", size=HS(2.5, 2.5, 2.6), at=HP(0, -5.0, 11.3), role="coat", chamfer=0.65 * HK)
    m.box("Muzzle", size=HS(1.75, 2.2, 1.45), at=HP(0, -6.65, 10.6), role="snout", chamfer=0.45 * HK, axis="y", taper=(0.88, 0.88))
    m.box("Cheek_L", size=HS(0.4, 1.4, 1.2), at=HP(-1.15, -5.0, 10.6), role="coat", chamfer=0.15, **MR)
    # grands yeux separes poses sur l'arete avant du crane : visibles de face comme de profil ;
    # blanc, iris raisin, pupille, deux reflets, cils
    C = HP(-0.925, -5.925, 11.45)
    N, T = (-0.7071, -0.7071, 0), (0.7071, -0.7071, 0)
    E = dict(rot=(0, 0, -45), **MR)

    def ep(u, dn, dz):
        return add(add(add(C, T, u * HK), N, dn * HK), (0, 0, dz * HK))
    m.box("Eye_L", size=HS(0.95, 0.12, 1.05), at=ep(0, 0.02, 0), role="white", **E)
    m.box("Iris_L", size=HS(0.7, 0.08, 0.84), at=ep(0.05, 0.08, -0.04), role="iris", **E)
    m.box("Pupil_L", size=HS(0.38, 0.06, 0.5), at=ep(0.08, 0.12, -0.07), role="eye", **E)
    m.box("Shine_L", size=HS(0.22, 0.05, 0.22), at=ep(-0.12, 0.14, 0.18), role="shine", **E)
    m.box("Shine2_L", size=HS(0.11, 0.05, 0.11), at=ep(0.25, 0.14, -0.28), role="shine", **E)
    m.beam("Lash0_L", start=ep(-0.33, 0.06, 0.42), end=ep(-0.62, 0.12, 0.72), role="eye", width=0.1, depth=0.1, **MR)
    m.beam("Lash1_L", start=ep(-0.12, 0.06, 0.5), end=ep(-0.28, 0.12, 0.85), role="eye", width=0.1, depth=0.1, **MR)
    # oreilles (rig EarL / EarR), interieur rose
    m.pyramid("Ear_L", size=HS(0.8, 0.6, 1.3), at=HP(-0.8, -4.4, 13.15), role="coat", **MR)
    m.pyramid("EarIn_L", size=HS(0.48, 0.12, 0.8), at=HP(-0.8, -4.72, 13.05), role="cc_pink", **MR)
    # corne en sucre d'orge torsadee : bague doree, segments rouges et blancs tournes, pointe lumineuse
    hb, ht = HP(0, -5.55, 12.6), HP(0, -6.1, 14.6)
    m.prism("HornRing", radius=0.62, height=0.34, at=add(hb, (0, 0, 0.02)), role="gold", sides=8)
    n = 6
    for k in range(n):
        a, b = mid(hb, ht, k / n), mid(hb, ht, (k + 1) / n + (0.02 if k < n - 1 else 0))
        w = 0.85 * (1 - 0.8 * k / n)
        m.beam(f"Horn{k}", start=a, end=b, role="cane_red" if k % 2 else "cane", width=w, depth=w, taper=(1 - 0.8 * (k + 1) / n) / (1 - 0.8 * k / n),
               roll=k * 30)
    m.prism("HornTip", radius=0.14, height=0.35, at=add(ht, (0, -0.03, 0.05)), role="glow", sides=4, taper=0, rot=(16, 0, 0))
    # toupet de barbe a papa derriere la corne
    cloud(m, "Forelock", HP(0, -4.55, 12.85), 1.35 * HK, 0)
    # ---- criniere : grosses masses de barbe a papa le long de la crete du cou
    d = norm((0, NECK1[1] - NECK0[1], NECK1[2] - NECK0[2]))
    nb = (0, d[2], -d[1])           # vers l'arriere et le haut
    MANE = [(1.0, 1.9), (0.84, 2.1), (0.67, 2.2), (0.5, 2.1), (0.33, 1.95), (0.16, 1.75), (0.0, 1.5)]
    for k, (t, s) in enumerate(MANE):
        p = add(mid(NECK0, NECK1, t), nb, 1.0)
        cloud(m, f"Mane{k}", (0, p[1], p[2]), s, k + 1)
    # ---- queue (rig Tail) : barbe a papa qui s'affine en descendant
    for k, (p, s) in enumerate(zip(TAIL7, TS7)):
        cloud(m, f"TailPuff{k}", p, s, k)
    # ---- ailes (rig WingL / WingR) : bras dore, rangee de gaufrettes, plumes en sucre file a bouts roses et bleus
    m.box("WingRoot_L", size=(1.1, 1.2, 1.2), at=WR, role="gold", chamfer=0.22, **MR)
    m.beam("WingArm_L", start=WR, end=WE, role="gold", width=0.8, depth=0.9, chamfer=0.15, **MR)
    m.beam("WingArm2_L", start=WE, end=WT, role="gold", width=0.7, depth=0.8, chamfer=0.12, taper=0.7, **MR)
    m.box("WingWrist_L", size=(0.95, 0.95, 0.95), at=WE, role="gold_dark", chamfer=0.18, **MR)
    fd = norm(FDIR)
    for k, (s, L) in enumerate(FEATH):
        a = add(wing_point(s), (0, 0.15, 0))
        b = add(a, fd, L)
        c = add(b, fd, 0.85)
        m.beam(f"Feather{k}_L", start=a, end=b, role="coat", width=1.45, depth=0.24, chamfer=0.05, roll=roll, **MR)
        m.beam(f"FTip{k}_L", start=b, end=c, role="cc_pink" if k % 2 else "cc_blue", width=1.45, depth=0.28, taper=0.7, roll=roll, **MR)
        if k % 2 == 0 and k < 8:
            m.beam(f"Wafer{k}_L", start=add(a, fd, -0.1), end=add(a, fd, 1.25), role="wafer", width=1.6, depth=0.4, chamfer=0.06, roll=roll, **MR)
    # ---- etoiles de sucre lumineuses
    star(m, "WStar", add(WE, (0, -0.5, 0.1)), 0.8, role="glow_pink", mirror=True)
    star(m, "WStarTip", add(WT, (0.1, -0.36, 0.0)), 0.6, role="glow_pink", mirror=True)
    p = TAIL7[2]
    star(m, "TStar", (-1.08, p[1], p[2]), 0.65, plane="yz", mirror=True)
    p = add(mid(NECK0, NECK1, 0.5), nb, 1.0)
    star(m, "MStar", (-1.03, p[1], p[2] - 0.3), 0.6, plane="yz", mirror=True)
    # ---- peinture : naseaux, sourire, joues
    m.rect("Muzzle", "front", (-0.4, 0.15), (0.22, 0.16), "mouth")
    m.rect("Muzzle", "front", (0.4, 0.15), (0.22, 0.16), "mouth")
    m.line("Muzzle", "front", [(-0.45, -0.35), (-0.2, -0.5), (0.2, -0.5), (0.45, -0.35)], "mouth", 1)
    m.rect("Cheek_L", "left", (0.0, -0.1), (0.5, 0.3), "cc_pink_l")
    m.rect("Cheek_R", "right", (0.0, -0.1), (0.5, 0.3), "cc_pink_l")
    return m


m7 = ropilot.model("R11_T7", px=8, reset=True)
m7.reference(REF7)
m7.palette(**PAL7)
build_t7(m7)
print(m7.build()); print(m7.check()); print(m7.compare()["report"])
ropilot.check_model(collection="R11_T7", max_lines=8)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R11_T7.blend"), copy=True)


def wing7(s):
    return [f"WingRoot_{s}", f"WingArm_{s}", f"WingArm2_{s}", f"WingWrist_{s}", f"Feather*_{s}", f"FTip*_{s}", f"Wafer*_{s}", f"WStar*_{s}"]


GROUPS_T7 = {'Head': ['Skull', 'Muzzle', 'Cheek_*', 'Eye_*', 'Iris_*', 'Pupil_*', 'Shine_*', 'Shine2_*', 'Lash*', 'Horn*', 'Forelock*'],
             'EarL': ['Ear_L', 'EarIn_L'], 'EarR': ['Ear_R', 'EarIn_R'],
             'LegFL': ['FUpper_L', 'FLower_L', 'FFluff_L', 'FHoof_L'], 'LegFR': ['FUpper_R', 'FLower_R', 'FFluff_R', 'FHoof_R'],
             'LegBL': ['Thigh_L', 'BUpper_L', 'BLower_L', 'BFluff_L', 'BHoof_L'], 'LegBR': ['Thigh_R', 'BUpper_R', 'BLower_R', 'BFluff_R', 'BHoof_R'],
             'WingL': wing7('L'), 'WingR': wing7('R'),
             'Tail': ['TailPuff*', 'TStar*']}
# --- suite : exec(rigjoin.py), rig_join("R11_T7", GROUPS_T7), save R11_T7_rig.blend, import -> Work_R11_T7,
# CreatureRig.Install(workspace.Work_R11_T7, "R11_T7", nil, true), puis joints corriges dans le repere du Core :
# Head (0, 10.7, -4.8) en haut du cou, EarL/R (+-0.96, 13.2, -4.62) a la base, LegFL/FR (+-1.35, 5.0, -2.75) a l'epaule,
# LegBL/BR (+-1.4, 6.1, 3.66) a la hanche, WingL/R (+-1.6, 7.9, -0.64) a la racine (au lieu du milieu de l'aile),
# Tail (0, 7.4, 4.6) a la racine (au lieu de l'interieur de la croupe)
# Criniere et collier de dragees dans Body (le cou ne bouge pas) ; le toupet suit la tete.
# compare() final : face 0.72, dos 0.72, gauche 0.59, dessus 0.58 : la reference est une licorne fine aux petites ailes
# dressees, a la longue queue trainant au sol ; ici ailes plus grandes en eventail (plumes tournees de 45 deg pour se lire
# de face comme de profil), tete agrandie (HK = 1.2) avec les yeux visibles de face, queue en barbe a papa plus courte.
# Note : la palette « tiles » sur les plumes en gaufrette a bloque Blender (abandonnee).
