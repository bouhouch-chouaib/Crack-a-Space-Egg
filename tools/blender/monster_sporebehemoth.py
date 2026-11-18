# Spore Behemoth (anneau 12 Mushroom Moon) : kit ropilot.model, px = 8, sans picots
# Executer d'abord monster_common_r11_14.py. Reference : Renders/Monster_Refs/GenM_SporeBehemoth_*.png (generate_mesh)
# Behemoth massif facon gorille : chair de champignon violet sombre tachee, plis du ventre clairs, mousse verte sur le dos,
# les epaules et les avant-bras ; jambes courtes, pieds a griffes ; enormes bras et poings a jointures et griffes ;
# tete basse en avant, sourcils en V, grands yeux menthe lumineux, gueule ouverte a crocs, machoire prognathe et deux
# defenses baguees de mousse ; enorme chapeau d'amanite rouge a pois blancs, pied et lamelles creme ;
# champignons turquoise sur le dos et les epaules, lamelles lumineuses (certains chapeaux lumineux).
PAL_SB = dict(
    flesh=dict(color="#4b2c6e", noise=0.035, shade=0.18, mottle=("#41265f", 0.25, 4), top=0.12),
    flesh_dark=dict(color="#331d4c", noise=0.03, shade=0.14, top=0.1),
    flesh_light=dict(color="#7454a0", noise=0.03, shade=0.12, top=0.1, rim=-0.15),
    moss=dict(color="#5f9e3c", noise=0.05, shade=0.12, mottle=("#78b84a", 0.3, 3), top=0.15),
    moss_dark=dict(color="#3f7428", noise=0.04, shade=0.12),
    cap=dict(color="#d6262c", noise=0.03, shade=0.16, top=0.12, mottle=("#c41f26", 0.2, 5)),
    spot=dict(color="#fbf3e2", noise=0.02, shade=0.08, top=0.1),
    stem=dict(color="#eadcbf", noise=0.03, shade=0.14, streaks=("#d8c7a4", 0.25, "v")),
    gill=dict(color="#c9b089", noise=0.03, streaks=("#a88e66", 0.35, "u")),
    tusk=dict(color="#f3e9cf", noise=0.02, shade=0.14, top=0.12),
    teal=dict(color="#2fb8a6", noise=0.03, shade=0.14, top=0.14),
    teal_dark=dict(color="#1d7f78", noise=0.03, shade=0.12),
    claw=dict(color="#24162e", noise=0.02, shade=0.1, top=0.15),
    mouth="#170c1f", eye="#0b1a17", shine="#ffffff",
    glow=dict(color="#6ef0d2", glow=True),
)


def shroom(m, name, base, r, h, tilt=(0, 0, 0), glow_cap=False, solo=True):
    # champignon : pied clair, chapeau turquoise (ou tout lumineux), lamelles lumineuses dessous
    rx, ry = math.radians(tilt[0]), math.radians(tilt[1])
    up = vnorm((math.sin(ry), -math.sin(rx), math.cos(rx) * math.cos(ry)))
    top = vadd(base, up, h)
    m.beam(f"{name}St", start=vadd(base, up, -0.3), end=top, role="stem", width=r * 0.55, depth=r * 0.55, chamfer=0.05, solo=solo)
    m.prism(f"{name}Gl", radius=r * 0.92, height=0.18, at=vadd(top, up, 0.05), role="glow", sides=8, turn=22.5, rot=tilt, solo=solo)
    m.prism(f"{name}Cp", radius=r, height=r * 0.75, at=vadd(top, up, 0.14 + r * 0.375), role="glow" if glow_cap else "teal", sides=8,
            turn=22.5, taper=0.35, rot=tilt, solo=solo)


def build_sb(m):
    m.prism("Leg_L", radius=1.8, height=3.4, at=(-2.9, 0.9, 2.4), role="flesh_dark", sides=8, turn=22.5, taper=1.15)
    m.box("Foot_L", size=(3.1, 3.6, 1.3), at=(-3.0, 0.2, 0.65), role="flesh_dark", chamfer=0.4, taper=(0.9, 0.85))
    for k, dx in enumerate((-0.95, 0.0, 0.95)):
        m.prism(f"Toe{k}_L", radius=0.36, height=0.9, at=(-3.0 + dx, -1.75, 0.38), role="claw", sides=4, taper=0, rot=(95, 0, 0))
    m.prism("Belly", radius=4.6, height=4.8, at=(0, 0.6, 5.6), role="flesh", sides=8, turn=22.5, taper=1.05)
    for k, (z, w) in enumerate(((4.3, 4.6), (5.7, 5.0), (7.1, 5.0))):
        m.box(f"Fold{k}", size=(w, 0.7, 1.35), at=(0, -3.75 + 0.05 * k, z), role="flesh_light", chamfer=0.3, taper=(0.85, 1), rot=(-6, 0, 0))
    m.box("Chest", size=(9.6, 6.6, 4.6), at=(0, 0.3, 9.7), role="flesh", chamfer=1.5, taper=(0.82, 0.8))
    m.box("Hump", size=(7.4, 5.0, 3.6), at=(0, 1.7, 12.1), role="flesh", chamfer=1.4, taper=(0.6, 0.6))
    m.box("MossBack", size=(6.2, 3.6, 0.8), at=(0, 2.4, 13.8), role="moss", chamfer=0.3, taper=(0.75, 0.7), rot=(18, 0, 0))
    m.box("MossShoulder_L", size=(3.2, 3.4, 0.7), at=(-4.9, 0.4, 12.55), role="moss", chamfer=0.25, rot=(0, -12, 0))
    for k, (x, y, z) in enumerate(((-2.2, 4.05, 12.9), (0.2, 4.2, 12.7), (2.4, 4.0, 12.9))):
        m.prism(f"MossDrip{k}", radius=0.55, height=1.3, at=(x, y, z), role="moss_dark", sides=4, taper=0, turn=45, rot=(180, 0, 0), solo=True)
    m.prism("Shoulder_L", radius=2.4, height=3.6, at=(-5.0, 0.3, 10.6), role="flesh", sides=8, turn=22.5, rot=(0, 90, 0), taper=0.9)
    m.beam("Arm_L", start=(-5.7, 0.2, 10.4), end=(-6.6, -0.5, 6.6), role="flesh", width=2.6, depth=2.8, chamfer=0.8, taper=0.85)
    m.box("Elbow_L", size=(2.5, 2.7, 1.8), at=(-6.6, -0.35, 6.6), role="flesh_dark", chamfer=0.6)
    m.beam("Fore_L", start=(-6.6, -0.5, 6.9), end=(-6.7, -1.2, 2.6), role="flesh", width=2.5, depth=2.7, chamfer=0.8, taper=1.3)
    m.box("ForeMoss_L", size=(3.4, 3.7, 0.7), at=(-6.7, -1.0, 4.0), role="moss_dark", chamfer=0.2, rot=(-8, 0, 0))
    m.box("Fist_L", size=(3.4, 3.8, 2.7), at=(-6.7, -1.4, 1.35), role="flesh_dark", chamfer=0.8, taper=(0.95, 0.9))
    for k, dx in enumerate((-1.05, 0.0, 1.05)):
        m.box(f"Knuckle{k}_L", size=(0.95, 1.0, 0.9), at=(-6.7 + dx, -3.25, 1.75), role="flesh_light", chamfer=0.25)
        m.prism(f"Claw{k}_L", radius=0.36, height=1.05, at=(-6.7 + dx, -3.45, 0.5), role="claw", sides=4, taper=0, rot=(100, 0, 0))
    # tete basse et large
    m.box("Head", size=(5.8, 4.2, 3.0), at=(0, -2.9, 12.6), role="flesh", chamfer=1.0, taper=(0.9, 0.85), faces={"bottom": "mouth"})
    m.beam("Brow_L", start=(-2.6, -4.85, 13.75), end=(-0.35, -5.05, 13.05), role="flesh_dark", width=0.85, depth=1.0, chamfer=0.2)
    m.box("Iris_L", size=(1.45, 0.28, 1.1), at=(-1.4, -4.98, 12.7), role="glow", rot=(0, 0, -10))
    m.box("Pupil_L", size=(0.36, 0.08, 0.72), at=(-1.3, -5.15, 12.62), role="eye")
    m.box("Shine_L", size=(0.26, 0.06, 0.26), at=(-1.65, -5.17, 12.95), role="shine")
    m.box("Nose", size=(1.5, 0.9, 0.8), at=(0, -5.15, 12.15), role="flesh_dark", chamfer=0.25, taper=(0.8, 1))
    m.box("Nostril_L", size=(0.3, 0.1, 0.25), at=(-0.38, -5.61, 12.0), role="mouth")
    m.box("Lip", size=(5.0, 1.2, 0.6), at=(0, -4.55, 11.35), role="flesh_dark", chamfer=0.2)
    m.box("MouthIn", size=(4.8, 1.6, 1.5), at=(0, -4.55, 10.45), role="mouth")
    for k, x in enumerate((-1.75, -0.6, 0.6, 1.75)):
        m.prism(f"TopTooth{k}", radius=0.34, height=0.9, at=(x, -5.45, 10.8), role="tusk", sides=4, taper=0, rot=(180, 0, 0), solo=True)
    m.box("Jaw", size=(6.8, 4.6, 2.0), at=(0, -3.6, 9.0), role="flesh", chamfer=0.6, taper=(1.0, 0.9), faces={"top": "mouth"})
    m.box("Chin", size=(4.6, 1.0, 1.4), at=(0, -5.8, 9.0), role="flesh_dark", chamfer=0.3)
    for k, x in enumerate((-1.2, 0.0, 1.2)):
        m.prism(f"BotTooth{k}", radius=0.3, height=0.7, at=(x, -5.75, 10.2), role="tusk", sides=4, taper=0, solo=True)
    m.prism("Tusk_L", radius=0.6, height=3.4, at=(-2.85, -5.5, 11.0), role="tusk", sides=6, taper=0.05, rot=(-20, -22, 0))
    m.prism("TuskBand_L", radius=0.72, height=0.38, at=(-2.62, -5.68, 9.7), role="moss_dark", sides=6, rot=(-20, -22, 0))
    # chapeau d'amanite
    m.prism("Stem", radius=1.6, height=1.5, at=(0, -2.0, 14.6), role="stem", sides=8, turn=22.5)
    m.prism("Gills", radius=4.7, height=0.5, at=(0, -1.8, 15.4), role="gill", sides=8, turn=22.5)
    m.prism("CapRim", radius=5.2, height=0.9, at=(0, -1.8, 16.05), role="cap", sides=8, turn=22.5, taper=0.92)
    m.prism("Cap", radius=4.8, height=2.0, at=(0, -1.8, 17.5), role="cap", sides=8, turn=22.5, taper=0.6)
    m.prism("CapTop", radius=2.9, height=0.8, at=(0, -1.8, 18.9), role="cap", sides=8, turn=22.5, taper=0.55)
    k = 0
    for s in range(8):
        for (u, v, sz) in (((-0.9 if s % 2 else 0.7), 0.1, 1.05), ((1.0 if s % 2 else -0.8), -0.45, 0.7)):
            m.box(f"Spot{k}", size=(sz, sz, 0.16), at=m.surface("Cap", f"side{s}", (u, v)), role="spot", chamfer=0.06, solo=True)
            k += 1
    for (u, v, sz) in ((0.0, 0.0, 1.3), (1.0, 0.8, 0.7), (-0.9, -0.7, 0.7)):
        m.box(f"Spot{k}", size=(sz, sz, 0.16), at=m.surface("CapTop", "top", (u, v)), role="spot", chamfer=0.06, solo=True)
        k += 1
    # champignons turquoise lumineux
    shroom(m, "SA", (-5.2, 0.9, 12.7), 1.55, 1.5, (8, -25, 0))
    shroom(m, "SB", (-4.0, -0.4, 12.6), 0.75, 0.9, (-10, -10, 0), glow_cap=True)
    shroom(m, "SC", (5.2, 0.9, 12.7), 1.15, 1.6, (6, 22, 0))
    shroom(m, "SD", (4.3, 2.0, 12.5), 0.7, 0.8, (15, 15, 0), glow_cap=True)
    shroom(m, "SE", (-1.6, 3.4, 13.5), 1.75, 1.8, (28, -10, 0))
    shroom(m, "SF", (1.7, 3.5, 13.4), 1.25, 1.3, (32, 12, 0))
    shroom(m, "SG", (0.2, 4.6, 11.4), 0.7, 0.8, (60, 0, 0), glow_cap=True)
    shroom(m, "SH", (-3.0, 3.6, 11.4), 0.9, 1.0, (45, -25, 0), glow_cap=True)
    shroom(m, "SI", (3.2, 3.6, 11.0), 1.0, 1.1, (45, 25, 0))
    return m


def paint_sb(m):
    for s in range(8):
        m.blob("Belly", f"side{s}", (0.8 if s % 2 else -0.9, 0.9), 0.55, "flesh_light", seed=s)
        m.blob("Belly", f"side{s}", (-0.4, -1.2), 0.4, "flesh_light", seed=s + 9)
    for f, (u, v), sd in (("back", (1.5, 0.5), 1), ("back", (-2.0, -1.0), 2), ("left", (0.8, 0.4), 3), ("right", (-0.8, 0.4), 4)):
        m.blob("Chest", f, (u, v), 0.9, "moss", seed=sd)
        m.blob("Chest", f, (u - 1.6, v - 0.9), 0.5, "flesh_light", seed=3)
    m.blob("Hump", "back", (0.6, 0.2), 0.9, "moss_dark", seed=4)
    for s in range(8):
        m.blob("Leg_L", f"side{s}", (0, 0.6), 0.45, "flesh_light", seed=s)


SB = ropilot.model("SporeBehemoth", px=8, reset=True)
SB.reference(refs_mk("SporeBehemoth"))
SB.palette(**PAL_SB)
build_sb(AutoMirror(SB))
paint_sb(SB)
print(SB.build())
ground_mk("SporeBehemoth")
print(SB.compare(image=False)["report"])
print(close_gaps_mk("SporeBehemoth"))
print("glow", glow_share_mk("SporeBehemoth"))
save_mine("SporeBehemoth")
# compare() : face 0.68, dos 0.68, gauche 0.70, dessus 0.87 (la reference est une boule assise ; ici un gorille dresse
# au chapeau d'amanite enorme, choisi pour la silhouette). Lueur 3,6 % de la surface.
