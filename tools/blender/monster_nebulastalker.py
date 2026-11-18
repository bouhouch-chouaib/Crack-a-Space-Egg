# Nebula Stalker (anneau 4, Nebula) : kit ropilot.model, px = 8, sans picots
# Reference de forme : workspace.GenM_NebulaStalker (generate_mesh) rendu en vues orthogonales (Renders/Monster_Refs/GenM_NebulaStalker_*.png)
# Raie manta cosmique geante : grandes ailes-nageoires violettes balayees vers l'arriere, bouts releves, dessus
# piquete d'etoiles (mouchetures blanches peintes et etoiles lumineuses), dessous rose ; bord d'attaque violet sombre,
# bord de fuite rose ; tete large a gueule ouverte bordee de crocs lavande, deux yeux violets lumineux sous des
# arcades, deux cornes cephaliques recourbees vers l'avant ; crete de cristaux lumineux sur le dos ; longue queue
# fouet qui ondule et finit en dard lumineux.
exec(open(r"C:\Users\bouho\OneDrive - Conseil régional Grand Est - Numérique Educatif\Documents\Crack the Asteroid\tools\blender\monster_helpers.py", encoding="utf-8").read())

NS_COL = "Monster_NebulaStalker"
NS_PAL = dict(
    wing=dict(color="#5b2fa0", noise=0.035, shade=0.12, mottle=("#7a3cb8", 0.35, 6), speckle=("#ffffff", 0.012), top=0.06),
    wing_dark=dict(color="#3a1d6e", noise=0.03, shade=0.12, mottle=("#4a2486", 0.3, 5), speckle=("#e8d8ff", 0.008)),
    wing_pink=dict(color="#d0509e", noise=0.03, shade=0.1, mottle=("#e06ab4", 0.3, 5), speckle=("#ffffff", 0.01)),
    belly=dict(color="#f0a6d4", noise=0.025, shade=0.12),
    belly_dark=dict(color="#c47aae", noise=0.025, shade=0.1),
    hide=dict(color="#4c2690", noise=0.035, shade=0.16, mottle=("#5e30a8", 0.3, 5), speckle=("#ffffff", 0.008), top=0.08),
    hide_dark=dict(color="#2c1656", noise=0.03, shade=0.12),
    horn=dict(color="#3a1d6e", noise=0.03, shade=0.14, top=0.12),
    horn_tip=dict(color="#ff7ac8", noise=0.02, shade=0.1),
    fang=dict(color="#f3e8ff", noise=0.02, shade=0.12, top=0.1),
    mouth=dict(color="#1e0c2e", noise=0.03, shade=0.08),
    eye_dark="#140a24", shine="#ffffff",
    glow=dict(color="#b45cff", glow=True),
    glow_pink=dict(color="#ff5cc8", glow=True),
)
NS_Z = 6.0      # hauteur du plan des ailes a la racine


def ns_wing_seg(m, name, a, b, c1, c2, t1, t2, role, over=0.15, **kw):
    # segment d'aile droite (+X) de a a b : boite allongee sur x, corde c1 -> c2, epaisseur t1 -> t2
    d = mk_sub(b, a)
    L = mk_len(d)
    rz = math.degrees(math.atan2(d[1], d[0]))
    ry = -math.degrees(math.atan2(d[2], math.hypot(d[0], d[1])))
    m.box(name, size=(L + over, c1, t1), at=mk_mid(a, b), role=role, axis="x", taper=(c2 / c1, t2 / t1), rot=(0, ry, rz), **kw)


def build_ns(m):
    z = NS_Z
    # ---- corps : losange aplati qui s'affine vers l'arriere, dessous rose
    m.box("Body", size=(6.6, 9.0, 3.8), at=(0, 0.6, z + 0.3), role="hide", chamfer=0.7, axis="y", taper=(1.15, 1.1),
          faces={"bottom": "belly"})
    m.box("Rump", size=(4.2, 4.2, 2.6), at=(0, 6.0, z), role="hide", chamfer=0.5, axis="y", taper=(1.6, 1.3),
          faces={"bottom": "belly"})
    # ---- tete large : front plat avec gueule ouverte
    m.box("Head", size=(7.6, 3.4, 3.8), at=(0, -4.6, z + 0.2), role="hide", chamfer=0.6, axis="y", taper=(0.92, 0.9),
          faces={"bottom": "belly"})
    m.box("Mouth", size=(5.2, 0.4, 1.8), at=(0, -6.25, z - 0.45), role="mouth", chamfer=0.1)
    m.box("Lip", size=(5.8, 1.0, 0.5), at=(0, -6.1, z - 1.45), role="belly_dark", chamfer=0.12)
    for k in range(6):
        x = -2.2 + 0.88 * k
        L = 1.25 if k in (0, 5) else 0.85
        m.prism(f"FangU{k}", radius=0.3, height=L, at=(x, -6.4, z + 0.45 - L / 2), role="fang", sides=4, taper=0, turn=45, rot=(0, 180, 0), solo=True)
    for k in range(5):
        x = -1.76 + 0.88 * k
        m.prism(f"FangD{k}", radius=0.26, height=0.75, at=(x, -6.4, z - 1.3 + 0.37), role="fang", sides=4, taper=0, turn=45, solo=True)
    # yeux violets lumineux sur les coins de la tete, arcades sombres
    m.box("EyeSock_L", size=(1.9, 0.5, 1.35), at=(-2.6, -6.15, z + 1.25), role="eye_dark", chamfer=0.1, rot=(0, 0, -10), mirror=True)
    m.box("Eye_L", size=(1.5, 0.3, 0.95), at=(-2.6, -6.38, z + 1.25), role="glow", rot=(0, 0, -10), mirror=True)
    m.box("Shine_L", size=(0.3, 0.12, 0.3), at=(-2.95, -6.55, z + 1.48), role="shine", mirror=True)
    m.beam("Brow_L", start=(-3.7, -5.9, z + 2.2), end=(-1.3, -6.1, z + 1.7), role="hide_dark", width=0.55, depth=0.7, chamfer=0.1, mirror=True)
    # cornes cephaliques recourbees vers l'avant (bouts roses)
    HP = [(-3.3, -5.0, z + 0.4), (-4.1, -6.7, z + 0.4), (-4.2, -8.1, z + 1.2), (-3.6, -8.9, z + 2.4)]
    mk_curve(m, "Horn_L", HP, [1.3, 1.1, 0.85, 0.5], [1.5, 1.2, 0.9, 0.5], ["horn", "horn", "horn_tip"], ext=0.12, chamf=0.12, mirror=True)
    # ---- ailes : quatre segments par cote, balayes vers l'arriere, bouts releves
    WP = [(2.6, -1.4, z + 0.3), (6.0, -0.6, z + 1.3), (9.0, 1.0, z + 1.5), (11.4, 3.2, z + 0.3), (12.6, 5.4, z - 1.9)]
    CH = [8.6, 7.2, 5.4, 3.2, 0.7]
    TH = [2.0, 1.4, 0.95, 0.6, 0.3]
    for i in range(4):
        ns_wing_seg(m, f"Wing{i}_R", WP[i], WP[i + 1], CH[i], CH[i + 1], TH[i], TH[i + 1], "wing", mirror=True,
                    faces={"bottom": "wing_pink"})
    # bord d'attaque violet sombre et bord de fuite rose (plus fins, devant et derriere l'aile)
    for i in range(4):
        a, b = WP[i], WP[i + 1]
        fa = mk_add(a, (0.15, -CH[i] * 0.5 + 0.25, 0.08))
        fb = mk_add(b, (0.15, -CH[i + 1] * 0.5 + 0.25, 0.08))
        m.beam(f"Lead{i}_R", start=fa, end=fb, role="wing_dark", width=0.9 - 0.15 * i, depth=TH[i] * 0.9, taper=0.8, mirror=True)
        ra = mk_add(a, (0, CH[i] * 0.5 - 0.35, -0.05))
        rb = mk_add(b, (0, CH[i + 1] * 0.5 - 0.35, -0.05))
        m.beam(f"Trail{i}_R", start=ra, end=rb, role="wing_pink", width=0.75 - 0.12 * i, depth=TH[i] * 0.6, taper=0.8, mirror=True)
    # etoiles lumineuses piquees sur le dessus des ailes
    for k, (seg, u, v, sz) in enumerate(((0, 0.6, -1.0, 0.6), (1, 0.4, 0.8, 0.5), (1, -1.0, -1.6, 0.4), (2, 0.5, 0.2, 0.45), (2, -0.8, -1.4, 0.35),
                                        (3, 0.0, 0.0, 0.32))):
        m.box(f"Star{k}_R", size=(sz, sz, 0.3), at=m.surface(f"Wing{seg}_R", "top", (u, v)), role="glow_pink" if k % 2 else "glow",
              rot=(0, 0, 45), mirror=True)
    # ---- crete de cristaux sur le dos
    for k, (y, h, r) in enumerate(((-2.6, 2.2, 0.6), (-0.8, 3.2, 0.8), (1.2, 2.7, 0.7), (3.2, 2.0, 0.55), (5.2, 1.3, 0.45))):
        m.crystal(f"Crys{k}", radius=r, height=h, at=(0, y, z + 1.9 if y < 4 else z + 1.1), role="glow" if k in (1, 3) else "horn", sides=4, tip=0.4, solo=True)
    for k, (x, y, h) in enumerate(((1.4, -1.6, 1.0), (1.5, 0.6, 1.2), (1.3, 2.6, 0.9))):
        m.crystal(f"CrysS{k}_R", radius=0.35, height=h, at=(x, y, z + 1.85), role="glow_pink" if k == 1 else "horn", sides=4, tip=0.4,
                  rot=(0, 18, 0), mirror=True)
    # ---- queue fouet qui ondule, dard lumineux
    TP = [(0, 7.6, z - 0.1), (0, 9.6, z - 0.8), (0.4, 11.5, z - 1.9), (1.1, 13.2, z - 2.3), (1.1, 14.8, z - 1.9), (0.4, 16.0, z - 1.0)]
    mk_curve(m, "Tail", TP, [1.6, 1.25, 0.95, 0.72, 0.52, 0.38], [1.3, 1.05, 0.85, 0.65, 0.5, 0.36], ["hide", "hide_dark"], ext=0.15,
             chamf=0.12, solo=True)
    m.prism("Sting", radius=0.5, height=1.6, at=mk_add(TP[-1], (-0.35, 0.65, 0.4)), role="glow_pink", sides=4, taper=0,
            rot=(-62, -25, 0), solo=True)
    for k in range(3):
        a, b = TP[k + 1], TP[k + 2]
        c = mk_mid(a, b, 0.4)
        m.beam(f"TailSpike{k}", start=mk_add(c, (0, 0, 0.25)), end=mk_add(c, (0, 0.6, 1.2 - 0.2 * k)), role="horn", width=0.35, depth=0.45,
               taper=0.1, solo=True)
    return m


def paint_ns(m):
    # fentes branchiales sous la tete, lignes du dos
    for k in range(4):
        m.rect("Body", "bottom", (-2.0, -2.2 + 0.7 * k), (0.9, 0.18), "belly_dark", mirror=True)
    m.line("Body", "top", [(0, -3.4), (0, 3.6)], "hide_dark", width=2)


NSM = ropilot.model(NS_COL, px=8, reset=True)
NSM.reference(mk_refs("GenM_NebulaStalker"))
NSM.palette(**NS_PAL)
build_ns(NSM)
paint_ns(NSM)
print(NSM.build())
print(NSM.compare(image=False)["report"])
mk_close_gaps(NS_COL)
print(ropilot.check_model(collection=NS_COL, max_lines=4))
print("glow", mk_glow_share(NS_COL), "tris", mk_tris(NS_COL))
mk_save(NS_COL, "Monster_NebulaStalker.blend")

# --- installation (18 nov.) : mk_join(<collection>, "M_<Model>") -> Shell + Glow + Glow2, import SANS rotation
# (Blender -Y arrive en +Z), puis dans Studio : pieces tournees de 180 deg autour du centre, Body invisible 1x1x1 au
# centre (PrimaryPart, regard -Z), Forward = "-Z". Couleur Neon principale reglee sur la couleur du monstre (Config).
