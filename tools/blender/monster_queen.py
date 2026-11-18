# Nest Queen (monstre de l'anneau 7, Model « Queen ») : kit ropilot.model, px = 8, sans picots
# Reference de forme : l'ancien modele ReplicatedStorage.Assets.Monsters.Queen (reine guepe debout, quatre ailes,
# couronne d'antennes), rendu en vues orthogonales (Renders/Monster_Refs/Queen_*.png). Refaite plus imposante :
# reine insecte-dragon dressee sur quatre pattes d'insecte, deux bras-faux leves, thorax cramoisi a plastron
# ambre et coeur lumineux, tete de dragon a museau, couronne de chitine a pointes d'or et gemmes, mandibules
# recourbees, yeux orange lumineux ; quatre ailes d'ambre nervurees ; gros abdomen annele qui porte une grappe
# d'oeufs orange lumineux dans des alveoles, termine par un dard.
# Usage : exec(open(r"<repo>/tools/blender/monster_common_b.py").read()) puis exec de ce fichier.
import ropilot, bpy, math

PAL_MQ = dict(
    chitin=dict(color="#8e2433", noise=0.035, shade=0.16, mottle=("#7a1d2b", 0.2, 4), top=0.14),
    chitin_dark=dict(color="#4c1420", noise=0.03, shade=0.12, top=0.1),
    chitin_light=dict(color="#b8394a", noise=0.03, shade=0.14, top=0.14),
    amber=dict(color="#eba13a", noise=0.03, shade=0.14, top=0.15),
    amber_dark=dict(color="#b86a22", noise=0.03, shade=0.12, top=0.12),
    amber_light=dict(color="#f8cf6e", noise=0.025, shade=0.12, top=0.12),
    memb=dict(color="#f4ad55", noise=0.03, shade=0.06, mottle=("#f8c272", 0.3, 5), streaks=("#fbd38a", 0.2, "v")),
    memb_light=dict(color="#f9cf86", noise=0.03, shade=0.06, mottle=("#fbdca0", 0.3, 5), streaks=("#fde6b4", 0.2, "v")),
    vein=dict(color="#7a2a18", noise=0.02, shade=0.1),
    belly=dict(color="#f2c48a", noise=0.025, shade=0.12, top=0.08, rim=-0.18),
    cell=dict(color="#c97a2a", noise=0.03, shade=0.14, top=0.12, rim=-0.2),
    mouth="#2a0c12", eye="#1a0808", shine="#ffffff",
    glow=dict(color="#e45c14", glow=True),   # Studio : (228, 92, 20), plus clair il vire au jaune en Neon
)
MRQ = dict(mirror=True)


def wing_mq(m, name, root, tip, wmax, roles=("memb", "memb_light"), th=0.22, y_off=0.0, **kw):
    # aile d insecte : deux plaques effilees bout a bout dans le plan x-z, nervure centrale sombre
    d = norm_mb(sub_mb(tip, root))
    L = math.dist(root, tip)
    ry = math.degrees(math.atan2(d[0], d[2]))
    rx = -math.degrees(math.asin(max(-1, min(1, d[1]))))
    a, b = 0.38 * L, 0.62 * L
    m.box(f"{name}A", size=(wmax * 0.35, th, a + 0.1), at=add_mb(root, d, a / 2), role=roles[1], taper=(1 / 0.35, 1), rot=(rx, ry, 0), **kw)
    m.box(f"{name}B", size=(wmax, th, b), at=add_mb(root, d, a + b / 2), role=roles[0], taper=(0.18, 1), rot=(rx, ry, 0), **kw)
    # nervure centrale et bord d'attaque sombre (costa) du cote haut de l'aile, deux nervures transverses
    side = norm_mb((-d[2], 0, d[0]))
    if side[2] < 0:
        side = tuple(-c for c in side)
    off = (0, -th * 0.6, 0)
    m.beam(f"{name}V", start=add_mb(add_mb(root, d, 0.3), off), end=add_mb(add_mb(tip, d, -1.2), off), role="vein", width=0.22, depth=0.14,
           taper=0.5, **kw)
    e0 = add_mb(add_mb(root, d, 0.2), side, wmax * 0.12)
    e1 = add_mb(add_mb(root, d, a), side, wmax * 0.46)
    m.beam(f"{name}C0", start=add_mb(e0, off), end=add_mb(e1, off), role="vein", width=0.34, depth=0.18, **kw)
    m.beam(f"{name}C1", start=add_mb(e1, off), end=add_mb(add_mb(tip, d, -0.25), off), role="vein", width=0.34, depth=0.18, taper=0.4, **kw)
    for k, t in enumerate((0.55, 0.78)):
        w = wmax * 0.5 * (1 - 0.82 * (t - 0.38) / 0.62)
        c = add_mb(add_mb(root, d, L * t), off)
        m.beam(f"{name}X{k}", start=add_mb(c, side, w * 0.88), end=add_mb(c, side, -w * 0.88), role="vein", width=0.18, depth=0.14, **kw)


def build_mq(m):
    # ---- pattes d'insecte (deux paires) : hanche, cuisse qui monte, genou ambre, tibia qui descend, griffe
    for k, (hip, knee, foot) in enumerate((((-2.6, 1.9, 5.4), (-5.2, 3.0, 8.2), (-6.0, 4.2, 0.0)),
                                          ((-2.8, -0.2, 5.6), (-5.4, -1.0, 8.0), (-5.9, -2.4, 0.0)))):
        m.box(f"Coxa{k}_L", size=(1.7, 1.7, 1.7), at=hip, role="chitin_dark", chamfer=0.4, **MRQ)
        m.beam(f"Femur{k}_L", start=hip, end=knee, role="chitin", width=1.6, depth=1.75, chamfer=0.4, taper=0.75, **MRQ)
        m.box(f"KneeCap{k}_L", size=(1.45, 1.45, 1.45), at=knee, role="amber", chamfer=0.35, **MRQ)
        mid = add_mb(mid_mb(knee, foot, 0.55), (-0.5, 0, 0))
        m.beam(f"Tibia{k}_L", start=knee, end=mid, role="chitin", width=1.3, depth=1.35, chamfer=0.28, taper=0.85, **MRQ)
        m.box(f"Band{k}_L", size=(1.25, 1.25, 0.55), at=mid, role="amber_dark", chamfer=0.18, **MRQ)
        m.beam(f"Tarsus{k}_L", start=mid, end=foot, role="chitin_dark", width=1.05, depth=1.1, chamfer=0.18, taper=0.45, **MRQ)
        m.prism(f"LegSpike{k}_L", radius=0.28, height=1.0, at=add_mb(mid_mb(knee, mid, 0.5), (-0.45, 0, 0.1)), role="amber_light", sides=4,
                taper=0, rot=(0, -60, 0), **MRQ)
        m.prism(f"Claw{k}_L", radius=0.32, height=0.8, at=add_mb(foot, (0, -0.35, 0.1)), role="amber_light", sides=4, taper=0,
                rot=(100, 0, 0), **MRQ)
    # ---- taille et thorax dresse (prismes a 8 pans), plastron ambre, coeur lumineux
    m.prism("Waist", radius=2.3, height=2.4, at=(0, 0.5, 5.1), role="chitin_dark", sides=8, turn=22.5, taper=1.2)
    m.prism("Thorax", radius=3.3, height=4.6, at=(0, 0.2, 8.3), role="chitin", sides=8, turn=22.5, taper=1.1)
    m.box("Chest", size=(6.6, 3.0, 3.4), at=(0, -1.4, 9.0), role="chitin_light", chamfer=0.9, taper=(1.12, 0.9))
    m.box("Plastron", size=(3.2, 0.5, 3.0), at=(0, -2.95, 8.4), role="amber", chamfer=0.3, taper=(0.3, 1), rot=(-6, 0, 0))
    m.box("PlastronRim", size=(3.8, 0.35, 3.5), at=(0, -2.75, 8.5), role="amber_dark", chamfer=0.3, taper=(0.3, 1), rot=(-6, 0, 0))
    m.box("Core", size=(1.0, 0.35, 1.0), at=(0, -3.25, 8.6), role="glow", rot=(0, 45, 0))
    for k, (z, w) in enumerate(((5.6, 3.6), (6.6, 4.4))):
        m.box(f"BellyPlate{k}", size=(w, 0.5, 0.75), at=(0, -2.2 - 0.25 * k, z), role="chitin_dark", chamfer=0.15, taper=(0.85, 1), rot=(-8, 0, 0))
    # epaulieres de chitine et pointes
    m.box("Pauldron_L", size=(2.6, 3.0, 1.7), at=(-3.5, -0.4, 10.6), role="chitin_light", chamfer=0.6, taper=(0.7, 0.8), rot=(0, -18, 0), **MRQ)
    m.prism("PauldronSpike_L", radius=0.45, height=1.8, at=(-4.4, -0.3, 11.7), role="amber_light", sides=4, taper=0, rot=(0, -35, 0), **MRQ)
    m.prism("PauldronSpikeB_L", radius=0.35, height=1.3, at=(-3.4, 0.4, 11.6), role="amber", sides=4, taper=0, rot=(-15, -15, 0), **MRQ)
    # plaques dorsales
    for k, (z, y) in enumerate(((10.2, 2.9), (8.6, 3.2))):
        m.box(f"BackPlate{k}", size=(3.6 - 0.4 * k, 0.8, 1.6), at=(0, y, z), role="chitin_light", chamfer=0.3, taper=(0.75, 1), rot=(12, 0, 0))
    # ---- bras-faux (mante) : epaule, bras qui descend, faux d'ambre levee vers l'avant, dents
    SH, EL, TP = (-3.7, -0.9, 9.4), (-5.9, -1.9, 7.4), (-5.8, -4.6, 13.4)
    m.beam("Arm_L", start=SH, end=EL, role="chitin", width=1.3, depth=1.4, chamfer=0.3, taper=0.85, **MRQ)
    m.box("Elbow_L", size=(1.4, 1.4, 1.4), at=EL, role="amber", chamfer=0.35, **MRQ)
    FM = mid_mb(EL, TP, 0.45)
    m.beam("Fore_L", start=EL, end=FM, role="chitin_light", width=1.25, depth=1.35, chamfer=0.25, taper=0.9, **MRQ)
    m.beam("Scythe_L", start=FM, end=TP, role="amber_light", width=1.1, depth=0.55, chamfer=0.12, taper=0.08, **MRQ)
    m.beam("ScytheBack_L", start=add_mb(FM, (0, 0.3, 0)), end=mid_mb(FM, TP, 0.6), role="amber_dark", width=0.6, depth=0.62, taper=0.3, **MRQ)
    dsc = norm_mb(sub_mb(TP, FM))
    for k, t in enumerate((0.22, 0.45, 0.68)):
        p = mid_mb(FM, TP, t)
        m.prism(f"Tooth{k}_L", radius=0.22, height=0.8 - 0.15 * k, at=add_mb(p, (0.25, -0.2, -0.35)), role="amber_light", sides=4, taper=0,
                rot=(150, 25, 0), **MRQ)
    # ---- cou et tete de dragon : crane, museau, plaque, narines, yeux, arcades, mandibules, machoire
    m.beam("Neck", start=(0, 0.0, 10.4), end=(0, -1.2, 12.4), role="chitin_dark", width=2.4, depth=2.4, chamfer=0.55)
    m.box("Skull", size=(3.6, 3.3, 2.6), at=(0, -1.6, 12.9), role="chitin", chamfer=0.75, taper=(0.82, 0.8), faces={"bottom": "belly"})
    m.prism("Cheek_L", radius=0.42, height=1.7, at=(-2.05, -1.2, 12.3), role="amber", sides=4, taper=0, rot=(-35, -70, 0), **MRQ)
    m.prism("CheekB_L", radius=0.32, height=1.2, at=(-1.95, -0.4, 12.9), role="amber_dark", sides=4, taper=0, rot=(-55, -60, 0), **MRQ)
    m.box("Snout", size=(2.5, 2.9, 1.5), at=(0, -3.9, 12.4), role="chitin", chamfer=0.4, axis="y", taper=(0.72, 0.8), faces={"bottom": "belly"})
    m.box("SnoutPlate", size=(1.4, 2.4, 0.22), at=(0, -3.8, 13.18), role="amber", chamfer=0.05, axis="y", taper=(0.55, 1))
    m.box("Nostril_L", size=(0.3, 0.2, 0.2), at=(-0.4, -5.33, 12.8), role="chitin_dark", **MRQ)
    m.box("MouthIn", size=(1.9, 2.4, 0.28), at=(0, -3.8, 11.62), role="mouth")
    m.box("Jaw", size=(2.0, 2.6, 0.6), at=(0, -3.6, 11.25), role="chitin", chamfer=0.15, axis="y", taper=(0.72, 0.85),
          faces={"top": "mouth", "bottom": "belly"})
    for k, x in enumerate((-0.55, 0.55)):
        m.prism(f"Fang{k}", radius=0.17, height=0.5, at=(x, -4.75, 11.45), role="amber_light", sides=4, taper=0, rot=(180, 0, 0), solo=True)
    m.box("Iris_L", size=(1.25, 0.3, 1.0), at=(-1.12, -3.24, 13.25), role="glow", rot=(0, -14, 0), **MRQ)
    m.box("Pupil_L", size=(0.3, 0.08, 0.78), at=(-1.06, -3.42, 13.22), role="eye", rot=(0, -14, 0), **MRQ)
    m.box("Shine_L", size=(0.26, 0.06, 0.26), at=(-1.4, -3.46, 13.5), role="shine", **MRQ)
    m.beam("Brow_L", start=(-1.9, -3.1, 14.0), end=(-0.45, -3.35, 13.82), role="chitin_dark", width=0.35, depth=0.5, chamfer=0.08, **MRQ)
    # mandibules recourbees (ambre) de chaque cote de la bouche
    MD = [(-1.1, -3.2, 11.65), (-1.75, -4.4, 11.3), (-1.55, -5.5, 11.05), (-0.6, -5.95, 10.85)]
    curve_mb(m, "Mandible_L", MD, [0.75, 0.62, 0.48, 0.3], [0.7, 0.58, 0.45, 0.28], ["amber", "amber", "amber_light"], ext=0.1, chamf=0.1, **MRQ)
    m.prism("MandTooth_L", radius=0.16, height=0.5, at=(-1.55, -4.8, 11.2), role="amber_light", sides=4, taper=0, rot=(0, 75, 0), **MRQ)
    # ---- couronne de chitine : bandeau ambre, cinq pointes d'or, gemmes orange, cornes vers l'arriere
    m.prism("CrownBand", radius=1.75, height=0.75, at=(0, -1.55, 14.3), role="amber_dark", sides=8, turn=22.5, taper=1.08)
    for k, (x, h, y) in enumerate(((0, 2.3, -2.2), (-1.0, 1.75, -2.0), (-1.6, 1.25, -1.45))):
        m.prism(f"CrownSpike{k}" + ("" if k == 0 else "_L"), radius=0.5 - 0.06 * k, height=h, at=(x, y, 14.6 + h / 2),
                role="amber_light", sides=4, taper=0, rot=(0, -12 * k, 0), **({} if k == 0 else MRQ))
    m.box("CrownGem", size=(0.55, 0.25, 0.55), at=(0, -3.08, 14.35), role="glow", rot=(0, 45, 0))
    m.box("CrownGem_L", size=(0.4, 0.22, 0.4), at=(-1.1, -2.9, 14.35), role="glow", rot=(0, 45, -25), **MRQ)
    HN = [(-1.2, -0.6, 14.2), (-2.0, 0.4, 15.0), (-2.6, 1.7, 15.4), (-2.9, 2.9, 15.1)]
    curve_mb(m, "Horn_L", HN, [0.75, 0.6, 0.45, 0.2], [0.75, 0.6, 0.45, 0.2], ["chitin_light", "chitin", "chitin_dark"], ext=0.1, chamf=0.1, **MRQ)
    # ---- ailes d'insecte : deux paires d'ambre nervurees, attachees au dos
    wing_mq(m, "WingUp_L", (-1.4, 2.5, 11.2), (-9.6, 5.0, 16.3), 4.8, **MRQ)
    wing_mq(m, "WingLo_L", (-1.4, 2.8, 9.8), (-8.6, 5.6, 8.6), 3.4, **MRQ)
    m.box("WingRoot_L", size=(1.6, 1.4, 2.6), at=(-1.4, 2.6, 10.1), role="chitin_dark", chamfer=0.4, **MRQ)
    # ---- abdomen annele vers l'arriere, alveoles et oeufs lumineux sur le dos, dard
    AB = [(0, 2.3, 6.6), (0, 4.6, 6.0), (0, 6.8, 4.9), (0, 8.5, 3.5), (0, 9.5, 2.3)]
    RW = [4.6, 5.8, 5.4, 4.0, 2.4]
    for i in range(len(AB) - 1):
        d = norm_mb(sub_mb(AB[i + 1], AB[i]))
        m.beam(f"Abdo{i}", start=add_mb(AB[i], d, -0.35 if i else 0), end=add_mb(AB[i + 1], d, 0.35), role="chitin" if i % 2 == 0 else "chitin_light",
               width=RW[i], depth=RW[i], taper=max(0.4, RW[i + 1] / RW[i]), chamfer=RW[i + 1] * 0.28)
        m.beam(f"AbdoBand{i}", start=add_mb(AB[i + 1], d, -0.2), end=add_mb(AB[i + 1], d, 0.25), role="amber_dark",
               width=RW[i + 1] * 1.04, depth=RW[i + 1] * 1.04, chamfer=RW[i + 1] * 0.3)
    m.beam("Stinger", start=add_mb(AB[-1], (0, -0.2, 0.1)), end=(0, 10.9, 0.7), role="amber_light", width=1.2, depth=1.2, taper=0.05, chamfer=0.2)
    # alveoles ambre et oeufs (cristaux arrondis lumineux) sur le dessus de l'abdomen
    def top_ab(y, x=0.0):
        # dessus de l'abdomen a la profondeur y (axe AB, largeurs RW), plus bas sur les cotes (chanfrein)
        for i in range(len(AB) - 1):
            if AB[i][1] <= y <= AB[i + 1][1] or i == len(AB) - 2:
                t = (y - AB[i][1]) / (AB[i + 1][1] - AB[i][1])
                return AB[i][2] + (AB[i + 1][2] - AB[i][2]) * t + (RW[i] + (RW[i + 1] - RW[i]) * t) / 2 - 0.45 * abs(x)
    EGG = [((0, 4.0), 1.0, 2.2), ((-1.45, 5.2), 0.85, 1.85), ((1.45, 5.2), 0.85, 1.85), ((0, 6.4), 0.95, 2.0),
           ((-1.3, 7.5), 0.72, 1.6), ((1.3, 7.5), 0.72, 1.6), ((0, 8.5), 0.68, 1.5)]
    for k, ((x, y), r, h) in enumerate(EGG):
        z = top_ab(y, x)
        m.prism(f"EggCell{k}", radius=r * 1.32, height=1.0, at=(x, y, z + 0.05), role="cell", sides=6, taper=1.15, solo=True)
        m.crystal(f"Egg{k}", radius=r, height=h, at=(x, y, z + 0.3), role="glow", sides=6, tip=0.32, base_tip=0.2, taper=1.0, solo=True)
    # pointes de chitine sur les flancs de l'abdomen
    for k, (y, z) in enumerate(((4.4, 5.9), (6.6, 4.9), (8.3, 3.6))):
        m.prism(f"AbdoSpike{k}_L", radius=0.4, height=1.4 - 0.15 * k, at=(-2.75 + 0.4 * k, y, z), role="amber_light", sides=4, taper=0,
                rot=(0, -80, 0), **MRQ)
    return m


HEAD_MQ = ("Skull", "Cheek", "Snout", "SnoutPlate", "Nostril_", "MouthIn", "Jaw", "Fang", "Iris_", "Pupil_", "Shine_", "Brow_", "Mandible_",
           "MandTooth_", "CrownBand", "CrownSpike", "CrownGem", "Horn_")
HB_MQ, HK_MQ = (0, -1.0, 12.0), 1.55       # tete agrandie de HK_MQ autour de la base du crane


def grow_head_mq(col_name):
    from mathutils import Matrix, Vector
    M = Matrix.Translation(Vector(HB_MQ)) @ Matrix.Scale(HK_MQ, 4) @ Matrix.Translation(-Vector(HB_MQ))
    bpy.context.view_layer.update()
    for o in bpy.data.collections[col_name].all_objects:
        part = o.get("ropilot_part") or o.name
        if o.type == "MESH" and part.startswith(HEAD_MQ):
            o.matrix_world = M @ o.matrix_world
            o.data.transform(o.matrix_basis)
            o.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()


Q = ropilot.model("M_Queen", px=8, reset=True)
Q.reference(refs_mb("Queen"))
Q.palette(**PAL_MQ)
build_mq(Q)
print(Q.build())
grow_head_mq("M_Queen")
print(Q.compare(image=False)["report"])
