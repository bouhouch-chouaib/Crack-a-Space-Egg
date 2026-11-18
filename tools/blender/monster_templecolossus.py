# Temple Colossus (anneau 13 Jade Temple) : kit ropilot.model, px = 8, sans picots
# Executer d'abord monster_common_r11_14.py. Reference : Renders/Monster_Refs/GenM_TempleColossus_*.png (generate_mesh)
# Colosse gardien en blocs de jade sculptes et or : jambes de pierre moussue a bracelets d'or, pagne de jade a glyphes
# d'or, ceinture a gemme lumineuse, torse en trapeze inverse a rainures et soleil lumineux au poitrail, epaulieres
# massives a pointe d'or et mousse ; bras de pierre, brassards d'or, poings de pierre enormes a jointures et rune
# lumineuse en losange ; tete-casque de jade, masque solaire dore a rayons rouges et or, yeux de feu, crocs d'or ;
# couronne d'or a gemme et grande coiffe de plumes rouges, turquoise et or a bagues.
PAL_TC = dict(
    jade=dict(color="#2f9a6a", noise=0.035, shade=0.16, mottle=("#3cae7a", 0.25, 5), top=0.16),
    jade_dark=dict(color="#1d6b4a", noise=0.03, shade=0.14, top=0.12),
    jade_light=dict(color="#5cc79a", noise=0.03, shade=0.12, top=0.14, rim=-0.15),
    stone=dict(color="#6f7a6a", noise=0.05, shade=0.16, mottle=("#5f6a5b", 0.3, 4), top=0.16),
    stone_dark=dict(color="#4c5649", noise=0.04, shade=0.14, top=0.12),
    gold=dict(color="#ffc83a", noise=0.025, shade=0.16, top=0.18),
    gold_dark=dict(color="#dc9a1c", noise=0.025, shade=0.14, top=0.12),
    red=dict(color="#d8342a", noise=0.03, shade=0.12, top=0.1, streaks=("#b82620", 0.3, "v")),
    teal=dict(color="#1fb5b0", noise=0.03, shade=0.12, top=0.1, streaks=("#14928e", 0.3, "v")),
    moss=dict(color="#7fb23a", noise=0.05, shade=0.1, mottle=("#93c84a", 0.3, 3)),
    mouth="#1a120a", eye="#3a1a05",
    glow=dict(color="#ffc850", glow=True), fire=dict(color="#ff8a1e", glow=True),
)


def build_tc(m):
    m.box("Foot_L", size=(2.8, 3.8, 1.3), at=(-2.4, -0.4, 0.65), role="stone_dark", chamfer=0.35, taper=(0.9, 0.85))
    m.box("FootGold_L", size=(2.9, 0.5, 0.55), at=(-2.4, -2.3, 0.55), role="gold", chamfer=0.1)
    m.box("Leg_L", size=(2.5, 2.6, 3.6), at=(-2.4, 0.1, 2.9), role="stone", chamfer=0.45, taper=(1.12, 1.1))
    m.box("Anklet_L", size=(2.75, 2.85, 0.55), at=(-2.4, 0.1, 1.55), role="gold", chamfer=0.12)
    m.box("Skirt", size=(6.4, 4.4, 2.8), at=(0, 0.2, 5.7), role="jade", chamfer=0.5, taper=(0.86, 0.92))
    m.box("Flap", size=(2.6, 0.5, 3.6), at=(0, -2.15, 4.8), role="jade_light", chamfer=0.1, taper=(1.25, 1), faces={"bottom": "gold"})
    m.box("FlapGold", size=(3.4, 0.55, 0.45), at=(0, -2.2, 3.15), role="gold", chamfer=0.1)
    m.box("Belt", size=(6.0, 4.3, 0.9), at=(0, 0.2, 7.4), role="gold", chamfer=0.25)
    m.box("BeltGem", size=(1.1, 0.3, 0.6), at=(0, -2.0, 7.4), role="glow", rot=(0, 45, 0))
    m.box("Waist", size=(5.4, 3.8, 1.6), at=(0, 0.2, 8.5), role="jade_dark", chamfer=0.4)
    m.box("Torso", size=(6.4, 4.4, 4.6), at=(0, 0.3, 11.0), role="jade", chamfer=0.6, taper=(1.35, 1.1))
    m.box("ChestL_L", size=(3.4, 0.7, 2.2), at=(-1.85, -2.05, 11.9), role="jade_light", chamfer=0.25, taper=(1.05, 1))
    m.box("Rune", size=(1.6, 0.25, 1.6), at=(0, -2.43, 10.0), role="glow", rot=(0, 45, 0))
    m.box("RuneRim", size=(2.4, 0.25, 2.4), at=(0, -2.3, 10.0), role="gold", rot=(0, 45, 0))
    for k in range(4):
        a = k * 90
        dx, dz = math.cos(math.radians(a)) * 1.85, math.sin(math.radians(a)) * 1.85
        m.box(f"RuneRay{k}", size=(0.4, 0.22, 0.4), at=(dx, -2.4, 10.0 + dz), role="glow", rot=(0, 45, 0), solo=True)
    m.box("Back", size=(6.6, 1.6, 3.4), at=(0, 2.5, 11.4), role="jade_dark", chamfer=0.5, taper=(1.2, 1))
    m.box("Pauldron_L", size=(3.6, 4.2, 2.4), at=(-5.0, 0.3, 13.0), role="jade", chamfer=0.6, taper=(0.75, 0.85), faces={"bottom": "jade_dark"})
    m.box("PauldronGold_L", size=(3.8, 4.4, 0.55), at=(-5.0, 0.3, 11.95), role="gold", chamfer=0.15)
    m.prism("PauldronSpike_L", radius=0.6, height=1.6, at=(-5.4, 0.3, 14.7), role="gold", sides=4, taper=0, turn=45, rot=(0, -20, 0))
    m.box("MossPad_L", size=(2.4, 2.6, 0.45), at=(-5.2, 0.6, 14.25), role="moss", chamfer=0.15, rot=(0, -12, 0))
    # bras et poings enormes
    m.beam("Arm_L", start=(-5.6, 0.3, 12.0), end=(-6.2, 0.0, 8.6), role="stone", width=2.2, depth=2.4, chamfer=0.5, taper=0.9)
    m.box("Elbow_L", size=(2.4, 2.6, 1.4), at=(-6.25, 0.0, 8.5), role="jade_dark", chamfer=0.4)
    m.beam("Fore_L", start=(-6.25, 0.0, 8.7), end=(-6.6, -0.4, 5.8), role="jade", width=2.8, depth=3.0, chamfer=0.6, taper=1.15)
    m.box("Bracer_L", size=(3.6, 3.8, 1.2), at=(-6.6, -0.3, 6.5), role="gold", chamfer=0.25)
    m.box("Fist_L", size=(4.4, 4.5, 3.9), at=(-6.8, -0.7, 3.6), role="stone", chamfer=0.8, taper=(0.95, 0.92))
    for k, dx in enumerate((-1.4, 0.0, 1.4)):
        m.box(f"Knuckle{k}_L", size=(1.25, 1.1, 1.25), at=(-6.8 + dx, -2.95, 2.8), role="stone_dark", chamfer=0.28)
    m.box("FistRune_L", size=(1.25, 0.2, 1.25), at=(-6.8, -3.0, 4.6), role="glow", rot=(0, 45, 0))
    m.box("FistRuneRim_L", size=(1.8, 0.16, 1.8), at=(-6.8, -2.94, 4.6), role="gold_dark", rot=(0, 45, 0))
    m.box("Thumb_L", size=(1.3, 1.6, 1.8), at=(-4.6, -1.6, 3.9), role="stone_dark", chamfer=0.3)
    # tete et masque solaire
    m.box("Neck", size=(2.6, 2.6, 1.2), at=(0, 0.4, 13.4), role="jade_dark", chamfer=0.3)
    m.box("Helm", size=(4.2, 4.0, 3.4), at=(0, 0.5, 15.2), role="jade", chamfer=0.7, taper=(0.9, 0.9))
    m.box("HelmBack", size=(3.6, 0.8, 2.8), at=(0, 2.7, 15.2), role="jade_dark", chamfer=0.3, faces={"back": "jade_light"})
    MZ = 15.0
    m.prism("SunRays", radius=3.5, height=0.45, at=(0, -1.7, MZ), role="gold_dark", sides=12, turn=15, rot=(90, 0, 0))
    m.prism("Mask", radius=2.45, height=0.7, at=(0, -2.1, MZ), role="gold", sides=8, turn=22.5, rot=(90, 0, 0))
    for k in range(12):
        a = math.radians(15 + 30 * k)
        if math.sin(a) < -0.6:
            continue
        b = (2.9 * math.cos(a), -1.85, MZ + 2.9 * math.sin(a))
        t = (4.3 * math.cos(a), -1.85, MZ + 4.3 * math.sin(a))
        m.beam(f"Ray{k}", start=b, end=t, role="gold" if k % 2 else "red", width=0.75, depth=0.35, taper=0.08, solo=True)
    m.beam("Brow_L", start=(-2.05, -2.55, MZ + 1.2), end=(-0.25, -2.62, MZ + 0.55), role="gold_dark", width=0.5, depth=0.45, chamfer=0.08)
    m.box("EyeHole_L", size=(1.5, 0.2, 0.95), at=(-1.0, -2.5, MZ + 0.15), role="mouth", rot=(0, -14, 0))
    m.box("Eye_L", size=(1.25, 0.26, 0.7), at=(-1.0, -2.56, MZ + 0.15), role="fire", rot=(0, -14, 0))
    m.box("EyeCore_L", size=(0.5, 0.27, 0.36), at=(-0.95, -2.62, MZ + 0.15), role="glow", rot=(0, -14, 0))
    m.box("MaskNose", size=(0.7, 0.5, 0.9), at=(0, -2.6, MZ - 0.6), role="gold_dark", chamfer=0.1, taper=(1.3, 1))
    m.box("MaskMouth", size=(2.0, 0.2, 0.5), at=(0, -2.5, MZ - 1.45), role="mouth")
    for k, x in enumerate((-0.7, 0.0, 0.7)):
        m.box(f"MaskTooth{k}", size=(0.35, 0.22, 0.32), at=(x, -2.56, MZ - 1.32), role="gold", solo=True)
    # couronne et coiffe de plumes
    m.box("Crown", size=(4.4, 2.0, 0.9), at=(0, 0.9, 17.2), role="gold", chamfer=0.25, taper=(0.9, 0.9))
    m.box("CrownGem", size=(0.9, 0.3, 0.9), at=(0, -0.15, 17.3), role="glow", rot=(0, 45, 0))
    roles = ["red", "teal", "gold", "red", "teal"]
    for k in range(9):
        ang = math.radians(-68 + 17 * k)
        L = 7.0 - abs(k - 4) * 0.55
        d = (math.sin(ang), 0.12, math.cos(ang))
        b = (math.sin(ang) * 0.9, 1.25 + 0.05 * abs(k - 4), 17.4)
        mpt = vadd(b, d, L * 0.55)
        t = vadd(b, d, L)
        role = roles[k % 5]
        m.beam(f"Feather{k}", start=b, end=mpt, role=role, width=0.8, depth=0.35, taper=2.1, chamfer=0.05, solo=True)
        m.beam(f"FeatherTip{k}", start=vadd(mpt, d, -0.15), end=t, role=role, width=1.7, depth=0.35, taper=0.08, solo=True)
        m.beam(f"FeatherBand{k}", start=vadd(mpt, d, -0.6), end=vadd(mpt, d, 0.1), role="gold" if role != "gold" else "teal",
               width=1.65, depth=0.42, taper=1.0, solo=True)
    return m


def paint_tc(m):
    m.rect("Torso", "back", (0, 0.4), (5.4, 0.18), "jade_dark")
    m.rect("Torso", "back", (0, -1.2), (5.0, 0.18), "jade_dark")
    m.rect("Skirt", "back", (0, 0.3), (5.4, 0.2), "gold_dark")
    for u in (-2.0, -0.7, 0.6, 1.9):
        m.stamp("Skirt", "back", (u, -0.4), ["#.#", "###", ".#."], {"#": "gold"}, cell=0.25)
    for s in ("front", "back", "left", "right"):
        m.blob("Leg_L", s, (0.3, -0.6), 0.5, "moss", seed=3)
        m.line("Leg_L", s, [(-0.6, 1.2), (-0.2, 0.4), (-0.5, -0.2)], "stone_dark", width=1)
    m.blob("Fist_L", "top", (0.6, 0.5), 0.7, "moss", seed=5)
    m.line("Fist_L", "left", [(-1.2, 1.0), (-0.5, 0.3), (-0.8, -0.6)], "stone_dark")
    m.blob("Helm", "top", (0.8, 0.6), 0.6, "moss", seed=2)
    m.rect("Torso", "front", (0, -1.6), (6.0, 0.2), "jade_dark")
    m.rect("Torso", "front", (-2.2, 0.2), (0.2, 3.0), "jade_dark")
    m.rect("Torso", "front", (2.2, 0.2), (0.2, 3.0), "jade_dark")
    for u in (-2.2, 2.2):
        m.stamp("Skirt", "front", (u, 0.3), ["#.#", "###", ".#."], {"#": "gold"}, cell=0.25)
    m.rect("Skirt", "front", (0, 1.0), (6.0, 0.2), "gold_dark")


TC = ropilot.model("TempleColossus", px=8, reset=True)
TC.reference(refs_mk("TempleColossus"))
TC.palette(**PAL_TC)
build_tc(AutoMirror(TC))
paint_tc(TC)
print(TC.build())
ground_mk("TempleColossus")
print(TC.compare(image=False)["report"])
print(close_gaps_mk("TempleColossus"))
print("glow", glow_share_mk("TempleColossus"))
save_mine("TempleColossus")
# compare() : face 0.71, dos 0.71, gauche 0.60, dessus 0.67 (poings et coiffe volontairement plus grands que la reference).
