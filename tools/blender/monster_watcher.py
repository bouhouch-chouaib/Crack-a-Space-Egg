# Rift Watcher (anneau 6, The Rift) : kit ropilot.model, px = 8, sans picots
# Reference de forme : l'ancien ReplicatedStorage.Assets.Monsters.Watcher (boule a piques, un grand oeil cyan)
# rendu en vues orthogonales (Renders/Monster_Refs/Watcher_*.png).
# Gardien de la faille : grand oeil qui flotte dans une coque blindee bleu nuit (bloc tres chanfreine), iris cyan
# lumineux a pupille fendue, paupieres blindees en V (regard dur), deux gemmes lumineuses au-dessus ; couronne de
# grands cristaux de la faille qui rayonnent autour de l'oeil ; anneau de runes derriere la coque ; piques sombres ;
# six tentacules qui pendent et s'enroulent sous lui, anneaux pales et bouts lumineux.
exec(open(r"C:\Users\bouho\OneDrive - Conseil régional Grand Est - Numérique Educatif\Documents\Crack the Asteroid\tools\blender\monster_helpers.py", encoding="utf-8").read())

WT_COL = "Monster_Watcher"
WT_PAL = dict(
    shell=dict(color="#2b3a5e", noise=0.035, shade=0.16, mottle=("#24314f", 0.3, 4), top=0.12),
    shell_dark=dict(color="#1b2440", noise=0.03, shade=0.12, top=0.08),
    shell_light=dict(color="#45588a", noise=0.03, shade=0.14, top=0.14),
    cryst=dict(color="#9feaff", noise=0.025, shade=0.14, top=0.18, streaks=("#d6f8ff", 0.2, "v")),
    cryst_dark=dict(color="#3fb4d8", noise=0.025, shade=0.14, top=0.15),
    sclera=dict(color="#d6f1fb", noise=0.02, shade=0.08, rim=-0.15),
    pupil="#071220", shine="#ffffff", rune="#5ae6ff", rune_dark="#2a7fa0",
    tent=dict(color="#34466e", noise=0.035, shade=0.14, mottle=("#2c3c60", 0.3, 4)),
    tent_ring=dict(color="#7f97c8", noise=0.025, shade=0.12),
    spike=dict(color="#141a2c", noise=0.03, shade=0.12, top=0.1),
    glow=dict(color="#5ae6ff", glow=True),
    glow_deep=dict(color="#1fb8ec", glow=True),
)
WT_O = (0, 0, 11.0)       # centre de l'oeil
WT_R = 5.2                # demi-cote de la coque


def wt_rad(r, a_deg, y):
    a = math.radians(a_deg)
    return (WT_O[0] + r * math.sin(a), y, WT_O[2] + r * math.cos(a))


def build_wt(m):
    ox, oy, oz = WT_O
    # ---- coque : bloc tres chanfreine (octogone sous tous les angles), bandeau sombre a l'arriere
    # tambour a 10 pans d'axe avant-arriere (rond vu de face) et deux chapeaux plus etroits devant et derriere
    m.prism("Orb", radius=WT_R + 0.5, height=2 * WT_R - 2.4, at=WT_O, role="shell", sides=10, turn=18, rot=(90, 0, 0))
    m.prism("OrbCapF", radius=WT_R - 0.6, height=1.4, at=(0, -WT_R + 0.9, oz), role="shell", sides=10, turn=18, rot=(90, 0, 0))
    m.prism("OrbCapB", radius=WT_R - 0.6, height=1.4, at=(0, WT_R - 0.9, oz), role="shell", sides=10, turn=18, rot=(90, 0, 0))
    m.prism("OrbBack", radius=3.9, height=1.8, at=(0, WT_R + 0.3, oz), role="shell_dark", sides=10, turn=18, rot=(90, 0, 0), taper=0.75)
    m.prism("OrbBackCore", radius=1.3, height=0.6, at=(0, WT_R + 1.35, oz), role="glow", sides=10, turn=18, rot=(90, 0, 0))
    # ---- oeil : blanc, iris cyan lumineux, pupille fendue, reflets
    m.prism("Socket", radius=4.5, height=0.8, at=(0, -WT_R + 0.05, oz), role="shell_dark", sides=8, turn=22.5, rot=(90, 0, 0))
    m.prism("Sclera", radius=3.8, height=0.6, at=(0, -WT_R - 0.3, oz), role="sclera", sides=8, turn=22.5, rot=(90, 0, 0))
    m.prism("Iris", radius=2.7, height=0.4, at=(0, -WT_R - 0.55, oz), role="glow", sides=8, turn=22.5, rot=(90, 0, 0))
    m.prism("IrisIn", radius=1.75, height=0.3, at=(0, -WT_R - 0.7, oz), role="glow_deep", sides=8, turn=22.5, rot=(90, 0, 0))
    m.box("Pupil", size=(1.0, 0.3, 3.6), at=(0, -WT_R - 0.85, oz), role="pupil", taper=(0.35, 1))
    m.box("Shine", size=(0.75, 0.15, 0.75), at=(-1.25, -WT_R - 0.95, oz + 1.2), role="shine")
    m.box("Shine2", size=(0.35, 0.15, 0.35), at=(1.1, -WT_R - 0.95, oz - 1.0), role="shine")
    # paupieres blindees en V (regard dur) et paupiere basse
    m.box("Lid_L", size=(4.6, 1.8, 1.6), at=(-2.1, -WT_R - 0.75, oz + 2.95), role="shell_light", chamfer=0.35, rot=(0, 16, 0), mirror=True)
    m.box("LidLow", size=(6.0, 1.6, 1.2), at=(0, -WT_R - 0.6, oz - 3.35), role="shell_light", chamfer=0.3, taper=(0.8, 1))
    m.box("LidLow_L", size=(1.6, 1.5, 1.0), at=(-3.0, -WT_R - 0.55, oz - 2.6), role="shell_light", chamfer=0.25, rot=(0, -35, 0), mirror=True)
    # deux gemmes lumineuses au-dessus des paupieres (la ou le jeu pose ses lueurs d'yeux)
    m.box("GemSock_L", size=(1.5, 0.5, 1.5), at=(-2.5, -WT_R - 0.15, oz + 4.6), role="shell_dark", rot=(0, 45, 0), mirror=True)
    m.box("Gem_L", size=(1.0, 0.5, 1.0), at=(-2.5, -WT_R - 0.35, oz + 4.6), role="glow", rot=(0, 45, 0), mirror=True)
    # ---- couronne de cristaux de la faille qui rayonnent autour de l'oeil
    CR = ((0, 6.8, 1.0, "cryst"), (34, 5.6, 0.85, "cryst"), (66, 5.2, 0.8, "cryst"), (100, 4.4, 0.7, "cryst_dark"),
          (135, 3.4, 0.6, "cryst"))
    for k, (a, h, r, role) in enumerate(CR):
        if a == 0:
            m.crystal(f"Cry{k}", radius=r, height=h, at=wt_rad(WT_R - 0.9, a, 0.6), role=role, sides=6, tip=0.35, solo=True)
            for s, (dy, hh) in ((-1, (-1.6, 4.0)), (1, (1.8, 4.6))):
                m.crystal(f"CryB{s + 1}", radius=0.6, height=hh, at=wt_rad(WT_R - 0.9, 0, 0.6 + dy), role="cryst_dark", sides=6, tip=0.35,
                          rot=(s * -22, 0, 0), solo=True)
        else:
            m.crystal(f"Cry{k}_R", radius=r, height=h, at=wt_rad(WT_R - 0.9, a, 0.6), role=role, sides=6, tip=0.35, rot=(0, a, 0), mirror=True)
            m.crystal(f"CryS{k}_R", radius=r * 0.55, height=h * 0.6, at=wt_rad(WT_R - 0.9, a + 14, 1.8), role="glow" if k == 1 else ("cryst_dark" if role != "cryst_dark" else "cryst"),
                      sides=6, tip=0.35, rot=(-12, a + 14, 0), mirror=True)
    # ---- anneau de runes derriere la coque
    RRg = 7.6
    for k in range(16):
        a = 11.25 + 22.5 * k
        if 150 < a < 210:
            continue          # ouvert en bas, la ou pendent les tentacules
        c = wt_rad(RRg, a, 2.3)
        m.box(f"Halo{k}", size=(2.95, 0.7, 0.85), at=c, role="shell_dark" if k % 2 else "shell_light", chamfer=0.12, rot=(0, a, 0), solo=True)
        if k % 2 == 0:
            m.box(f"Rune{k}", size=(1.3, 0.3, 0.38), at=wt_rad(RRg, a, 2.3 - 0.45), role="glow", rot=(0, a, 0), solo=True)
    for k, a in enumerate((90, 270)):
        m.beam(f"HaloArm{k}", start=wt_rad(WT_R - 1.0, a, 1.8), end=wt_rad(RRg - 0.2, a, 2.3), role="shell_dark", width=0.9, depth=0.9, solo=True)
    # ---- piques sombres sur la coque
    for k, (a, y, L) in enumerate(((20, 2.4, 2.8), (55, 3.2, 2.6), (85, 2.6, 2.4), (122, 2.8, 2.2), (150, 3.1, 1.8))):
        b = wt_rad(WT_R - 0.6, a, y)
        t = mk_add(b, mk_norm((math.sin(math.radians(a)), 0.55, math.cos(math.radians(a)))), L)
        m.beam(f"Spike{k}_R", start=b, end=t, role="spike", width=0.9, depth=0.9, taper=0.06, mirror=True)
    # ---- six tentacules qui pendent et s'enroulent
    TB = ((-1.4, -0.8, 0.0, 1.0), (-3.4, 0.6, -0.6, 0.9), (-2.4, 2.8, -0.5, 0.85))
    for j, (bx, by, curl, sc) in enumerate(TB):
        base = (bx, by, oz - WT_R + 0.9)
        pts = [base]
        for i, (dx, dy, dz) in enumerate(((-0.4 + curl, 0.4, -2.4), (-0.9 + curl, 0.9, -2.3), (-0.8 + curl, 1.3, -1.9), (0.2, 1.4, -1.5),
                                          (1.2, 0.6, -0.4), (1.0, -0.4, 0.6))):
            p = pts[-1]
            pts.append((p[0] + dx * sc, p[1] + dy * sc, p[2] + dz * sc))
        W = [x * sc for x in (2.0, 1.7, 1.4, 1.1, 0.85, 0.6, 0.4)]
        mk_curve(m, f"Tent{j}", pts, W, W, ["tent", "tent", "tent_ring"], ext=0.18, chamf=0.12, mirror=True)
        tip = pts[-1]
        m.box(f"TentTip{j}", size=(0.6, 0.6, 0.6), at=mk_add(tip, mk_norm(mk_sub(tip, pts[-2])), 0.15), role="glow", rot=(0, 45, 0), mirror=True)
    return m


def paint_wt(m):
    # fissures cyan peintes sur les pans du tambour (faces planes, sans chanfrein)
    for k, f in enumerate(("side1", "side3", "side4", "side6", "side8", "side9")):
        sg = 1 if k % 2 else -1
        m.line("Orb", f, [(-1.1 * sg, 1.4), (-0.4 * sg, 0.7), (0.2 * sg, 0.2), (-0.2 * sg, -0.6), (0.7 * sg, -1.4)], "rune", width=1)
        m.line("Orb", f, [(0.2 * sg, 0.3), (1.0 * sg, -0.4)], "rune_dark", width=1)


WTM = ropilot.model(WT_COL, px=8, reset=True)
WTM.reference(mk_refs("Watcher"))
WTM.palette(**WT_PAL)
build_wt(WTM)
paint_wt(WTM)
print(WTM.build())
print(WTM.compare(image=False)["report"])
mk_close_gaps(WT_COL)
print(ropilot.check_model(collection=WT_COL, max_lines=6))
print("glow", mk_glow_share(WT_COL), "tris", mk_tris(WT_COL))
mk_save(WT_COL, "Monster_Watcher.blend")

# --- installation (18 nov.) : mk_join(<collection>, "M_<Model>") -> Shell + Glow + Glow2, import SANS rotation
# (Blender -Y arrive en +Z), puis dans Studio : pieces tournees de 180 deg autour du centre, Body invisible 1x1x1 au
# centre (PrimaryPart, regard -Z), Forward = "-Z". Couleur Neon principale reglee sur la couleur du monstre (Config).
