# Phantom King (anneau 14 Phantom Mist, boss final) : kit ropilot.model, px = 8, sans picots
# Executer d'abord monster_common_r11_14.py. Reference : Renders/Monster_Refs/GenM_PhantomKing_*.png (generate_mesh)
# Roi fantome geant qui flotte : queue de brume qui s'affine vers l'arriere (bleu nuit -> turquoise pale) ; robe bleu nuit
# evasee a ourlet en lambeaux bleu nuit et turquoise, panneau de brume et gemmes lumineuses ; epaules tombantes et col de
# brume en lambeaux ; haut col a pointes derriere la tete ; cape royale en deux pans, doublure violette, bord en lambeaux ;
# tete fantome pale dans une capuche, grands yeux turquoise lumineux a paupiere sombre inclinee, large sourire en
# croissant a crocs ; couronne d'or a pointes et gemmes, quatre bras de fer qui portent des lanternes de fer a flamme
# orange ; bras en manches bleu nuit a revers de brume en lambeaux, mains geantes de brume aux doigts recourbes et
# longues griffes sombres, levees de chaque cote du visage ; coeur spectral lumineux sur la poitrine.
PAL_PK = dict(
    navy=dict(color="#1d2a4c", noise=0.035, shade=0.16, mottle=("#24345c", 0.25, 5), top=0.14),
    navy_dark=dict(color="#121b35", noise=0.03, shade=0.12, top=0.1),
    navy_light=dict(color="#2f4475", noise=0.03, shade=0.14, top=0.14),
    mist=dict(color="#6fd8cc", noise=0.035, shade=0.1, mottle=("#86e4d9", 0.3, 5), streaks=("#a6efe6", 0.2, "v")),
    mist_dark=dict(color="#3a9e9c", noise=0.03, shade=0.1, streaks=("#4fb3ae", 0.25, "v")),
    mist_light=dict(color="#c4f4ee", noise=0.03, shade=0.08, mottle=("#d8faf5", 0.3, 5), streaks=("#e6fcf9", 0.2, "v")),
    face=dict(color="#b6ece4", noise=0.025, shade=0.14, top=0.1),
    face_dark=dict(color="#7fc4c0", noise=0.02, shade=0.1),
    socket="#141c34", mouth="#0c1022", eye="#06222a", shine="#ffffff",
    tooth=dict(color="#f4fbff", noise=0.015, shade=0.1),
    crown=dict(color="#d9ad40", noise=0.025, shade=0.16, top=0.18),
    crown_dark=dict(color="#9c7522", noise=0.025, shade=0.12),
    iron=dict(color="#2b2a33", noise=0.025, shade=0.12, top=0.15),
    claw=dict(color="#262040", noise=0.02, shade=0.1, top=0.15),
    violet=dict(color="#6a4fb0", noise=0.025, shade=0.12, top=0.15),
    glow=dict(color="#78f0dc", glow=True), glow_orange=dict(color="#e85f1a", glow=True),
)


def lantern_pk(m, name, top, s=1.0):
    # lanterne de fer a flamme orange pendue par une chaine
    x, y, z = top
    m.beam(f"{name}Chain", start=(x, y, z + 0.1), end=(x, y, z - 1.3 * s), role="iron", width=0.16, depth=0.16, solo=True)
    zc = z - 1.3 * s
    m.box(f"{name}Ring", size=(0.5 * s, 0.14, 0.5 * s), at=(x, y, zc + 0.1), role="iron", solo=True)
    m.box(f"{name}Cap", size=(1.2 * s, 1.2 * s, 0.45 * s), at=(x, y, zc - 0.2 * s), role="iron", chamfer=0.1, taper=(0.45, 0.45), solo=True)
    m.box(f"{name}Glass", size=(0.82 * s, 0.82 * s, 1.1 * s), at=(x, y, zc - 1.0 * s), role="glow_orange", solo=True)
    for k, (dx, dy) in enumerate(((-1, -1), (1, -1), (-1, 1), (1, 1))):
        m.box(f"{name}Bar{k}", size=(0.16, 0.16, 1.15 * s), at=(x + dx * 0.45 * s, y + dy * 0.45 * s, zc - 1.0 * s), role="iron", solo=True)
    m.box(f"{name}Base", size=(1.1 * s, 1.1 * s, 0.28 * s), at=(x, y, zc - 1.68 * s), role="iron", chamfer=0.06, solo=True)
    m.prism(f"{name}Drop", radius=0.25 * s, height=0.5 * s, at=(x, y, zc - 2.05 * s), role="iron", sides=4, taper=0, rot=(180, 0, 0), solo=True)


def hand_pk(m, s, sx, WR, k=1.0):
    # main griffue : paume, quatre doigts a trois phalanges recourbes vers l'avant, griffes longues
    m.box(f"Palm{s}", size=(3.0 * k, 1.4 * k, 2.6 * k), at=(WR[0], WR[1] - 0.2, WR[2] + 1.1 * k), role="mist_light", chamfer=0.4, taper=(1.15, 1),
          rot=(-28, 0, sx * 10), solo=True)
    for f in range(4):
        off = (-1.1 + 0.73 * f) * k
        spread = (f - 1.5) * 0.35
        b = (WR[0] + off, WR[1] - 0.75 * k, WR[2] + 2.25 * k)
        lift = 0.45 if f in (1, 2) else 0.0
        p1 = (b[0] + spread * 0.8, b[1] - 0.9 * k, b[2] + (1.3 + lift) * k)
        p2 = (p1[0] + spread * 0.6, p1[1] - 1.3 * k, p1[2] + 0.35 * k)
        p3 = (p2[0] + spread * 0.3, p2[1] - 1.1 * k, p2[2] - 0.55 * k)
        w = (0.68 - 0.05 * abs(f - 1.5)) * k
        m.beam(f"Fin{s}{f}a", start=vadd(b, vnorm(vsub(p1, b)), -0.3), end=p1, role="mist_light", width=w, depth=w, chamfer=0.1, taper=0.9, solo=True)
        m.beam(f"Fin{s}{f}b", start=vadd(p1, vnorm(vsub(p2, p1)), -0.2), end=p2, role="mist_light", width=w * 0.9, depth=w * 0.9, chamfer=0.08,
               taper=0.88, solo=True)
        m.beam(f"Fin{s}{f}c", start=vadd(p2, vnorm(vsub(p3, p2)), -0.18), end=p3, role="mist", width=w * 0.78, depth=w * 0.78, chamfer=0.06,
               taper=0.85, solo=True)
        d = vnorm(vsub(p3, p2))
        m.beam(f"Claw{s}{f}", start=vadd(p3, d, -0.2), end=vadd(vadd(p3, d, 1.3 * k), (0, 0, -0.35 * k)), role="claw", width=w * 0.7,
               depth=w * 0.7, taper=0.05, solo=True)
    tb = (WR[0] - sx * 1.5 * k, WR[1] - 0.6 * k, WR[2] + 1.0 * k)
    tt = (WR[0] - sx * 2.3 * k, WR[1] - 1.9 * k, WR[2] + 1.6 * k)
    m.beam(f"Thumb{s}", start=(WR[0] - sx * 0.9 * k, WR[1] - 0.3, WR[2] + 0.9 * k), end=tt, role="mist_light", width=0.66 * k, depth=0.66 * k,
           chamfer=0.1, solo=True)
    m.beam(f"ThumbClaw{s}", start=vadd(tt, vnorm(vsub(tt, tb)), -0.2), end=vadd(tt, (-sx * 0.35, -1.1 * k, 0.1)), role="claw", width=0.46 * k,
           depth=0.46 * k, taper=0.05, solo=True)


def build_pk(m):
    # queue de brume vers l'arriere
    TP = [(0, 0.6, 6.0), (0, 1.4, 4.0), (0.3, 2.6, 2.4), (0.9, 4.2, 1.3), (1.4, 5.8, 0.9), (1.5, 7.0, 1.4)]
    TW = [4.6, 3.6, 2.6, 1.8, 1.1, 0.5]
    roles = ["navy", "navy_light", "mist_dark", "mist", "mist_light"]
    for i in range(len(TP) - 1):
        d = vnorm(vsub(TP[i + 1], TP[i]))
        m.beam(f"Tail{i}", start=vadd(TP[i], d, -0.4 if i else 0), end=vadd(TP[i + 1], d, 0.3), role=roles[i], width=TW[i], depth=TW[i] * 0.9,
               taper=TW[i + 1] / TW[i], chamfer=0.22 * TW[i + 1], solo=True)
    # robe evasee, ourlet en lambeaux
    m.prism("Robe", radius=4.4, height=6.0, at=(0, 0.3, 8.4), role="navy", sides=8, turn=22.5, taper=0.68)
    m.prism("RobeHem", radius=4.75, height=0.9, at=(0, 0.3, 5.75), role="navy_dark", sides=8, turn=22.5, taper=0.97)
    m.box("RobeFront", size=(1.6, 0.5, 5.4), at=(0, -3.35, 8.3), role="mist_dark", chamfer=0.1, taper=(2.2, 1), rot=(-17, 0, 0))
    for k, z in enumerate((7.0, 8.5)):
        m.box(f"RobeGem{k}", size=(0.8, 0.25, 0.8), at=(0, -4.08 + 0.46 * k, z), role="glow", rot=(-17, 45, 0), solo=True)
    for k in range(16):
        a = math.radians(11.25 + 22.5 * k)
        r = 4.55
        b = (r * math.cos(a), 0.3 + r * math.sin(a), 5.7)
        L = (3.4, 2.0, 4.2, 2.6)[k % 4]
        t = (b[0] * 1.18, b[1] * 1.15 + 0.05, 5.7 - L)
        m.beam(f"Tatter{k}", start=b, end=t, role=("navy_dark", "mist_dark", "navy", "mist")[k % 4], width=1.9, depth=0.4, taper=0.06, solo=True)
    # epaules tombantes et col de brume en lambeaux
    m.prism("Mantle", radius=5.0, height=2.4, at=(0, 0.6, 11.4), role="navy_light", sides=8, turn=22.5, taper=0.5)
    for k in range(16):
        a = math.radians(11.25 + 22.5 * k)
        b = (4.6 * math.cos(a), 0.6 + 4.6 * math.sin(a), 10.6)
        t = (5.9 * math.cos(a), 0.6 + 5.9 * math.sin(a), 9.6 - 0.5 * (k % 2))
        m.beam(f"Fur{k}", start=vadd(b, vnorm(vsub(t, b)), -0.4), end=t, role="mist_light" if k % 2 else "mist", width=1.9, depth=0.6, taper=0.08,
               solo=True)
    for k, (x, h) in enumerate(((-3.4, 4.0), (-1.8, 5.2), (0.0, 5.6), (1.8, 5.2), (3.4, 4.0))):
        m.beam(f"Collar{k}", start=(x * 0.85, 2.6, 11.8), end=(x * 1.25, 3.4, 11.8 + h), role="navy_dark" if k % 2 else "navy", width=1.9,
               depth=0.45, taper=0.12, solo=True)
        m.beam(f"CollarRim{k}", start=(x * 0.85, 2.3, 11.9), end=(x * 1.22, 3.1, 11.6 + h * 0.9), role="mist", width=0.35, depth=0.3,
               taper=0.3, solo=True)
    m.box("Heart", size=(1.2, 0.3, 1.2), at=(0, -3.35, 10.2), role="glow", rot=(0, 45, 0))
    m.box("HeartRim", size=(1.9, 0.25, 1.9), at=(0, -3.2, 10.2), role="crown", rot=(0, 45, 0))
    # cape royale en deux pans
    # cape royale d'un seul pan qui s'evase vers le bas et l'arriere, doublure violette, bord en lambeaux
    m.box("Cape", size=(9.4, 0.5, 8.2), at=(0, 4.0, 7.6), role="navy_dark", chamfer=0.15, taper=(0.72, 1), rot=(9, 0, 0), faces={"back": "navy"})
    m.box("CapeLining", size=(8.6, 0.25, 7.6), at=(0, 3.68, 7.7), role="violet", taper=(0.72, 1), rot=(9, 0, 0))
    for k in range(7):
        x = -4.0 + 1.333 * k
        L = (2.6, 3.8, 2.2, 4.4, 2.2, 3.8, 2.6)[k]
        m.beam(f"CapeTat{k}", start=(x, 4.62, 3.95), end=(x * 1.12, 5.0 + 0.15 * L, 3.95 - L), role="navy_dark" if k % 2 else "mist_dark",
               width=1.45, depth=0.45, taper=0.06, solo=True)
    # tete fantome
    HZ = 14.4
    m.prism("Head", radius=2.75, height=4.2, at=(0, -0.3, HZ), role="face", sides=8, turn=22.5, taper=0.86, faces={"back": "face_dark"})
    m.prism("HeadTop", radius=2.3, height=0.8, at=(0, -0.3, HZ + 2.45), role="face", sides=8, turn=22.5, taper=0.7)
    m.box("Hood", size=(6.6, 3.4, 5.6), at=(0, 1.5, HZ + 0.5), role="navy_dark", chamfer=1.2, taper=(0.75, 0.8))
    m.box("HoodSide_L", size=(1.0, 3.0, 4.6), at=(-2.95, -0.9, HZ + 0.1), role="navy", chamfer=0.3, taper=(1, 0.7), rot=(0, 8, 0))
    fy = -0.3 - 2.75 * math.cos(math.radians(22.5)) - 0.05
    m.box("Iris_L", size=(1.75, 0.3, 1.35), at=(-1.3, fy - 0.02, HZ + 0.45), role="glow", chamfer=0.25)
    m.box("Lid_L", size=(2.3, 0.36, 0.75), at=(-1.25, fy - 0.08, HZ + 1.22), role="socket", rot=(0, -20, 0))
    m.box("Pupil_L", size=(0.34, 0.1, 0.85), at=(-1.12, fy - 0.2, HZ + 0.38), role="eye")
    m.box("Shine_L", size=(0.26, 0.06, 0.26), at=(-1.75, fy - 0.2, HZ + 0.62), role="shine")
    SM = [(-2.25, fy + 0.1, HZ - 0.35), (-1.35, fy, HZ - 1.05), (0, fy - 0.03, HZ - 1.3), (1.35, fy, HZ - 1.05), (2.25, fy + 0.1, HZ - 0.35)]
    SD = [0.45, 0.85, 1.0, 0.85, 0.45]
    for i in range(4):
        d = vnorm(vsub(SM[i + 1], SM[i]))
        m.beam(f"Smile{i}", start=vadd(SM[i], d, -0.15), end=vadd(SM[i + 1], d, 0.15), role="mouth", width=0.3, depth=SD[i],
               taper=SD[i + 1] / SD[i], solo=True)
    for k, t in enumerate((0.1, 0.24, 0.38, 0.62, 0.76, 0.9)):
        i = min(3, int(t * 4)); f = t * 4 - i
        p = vmid(SM[i], SM[i + 1], f)
        hh = SD[i] + (SD[i + 1] - SD[i]) * f
        m.prism(f"Fang{k}", radius=0.24, height=0.55, at=(p[0], p[1] - 0.18, p[2] + hh / 2 - 0.22), role="tooth", sides=4, taper=0, turn=45,
                rot=(180, 0, 0), solo=True)
    for k, t in enumerate((0.31, 0.5, 0.69)):
        i = min(3, int(t * 4)); f = t * 4 - i
        p = vmid(SM[i], SM[i + 1], f)
        hh = SD[i] + (SD[i + 1] - SD[i]) * f
        m.prism(f"LowFang{k}", radius=0.2, height=0.45, at=(p[0], p[1] - 0.18, p[2] - hh / 2 + 0.2), role="tooth", sides=4, taper=0, turn=45,
                solo=True)
    # couronne a pointes et lanternes
    CZ = HZ + 2.3
    m.prism("CrownBand", radius=2.6, height=1.0, at=(0, -0.1, CZ + 0.3), role="crown", sides=8, turn=22.5, taper=1.12)
    for k in range(8):
        a = math.radians(22.5 + 45 * k)
        p = (2.55 * math.cos(a), -0.1 + 2.55 * math.sin(a), CZ + 0.8)
        h = 2.6 if k in (5, 6) else 2.0
        m.prism(f"CrownSpike{k}", radius=0.55, height=h, at=(p[0], p[1], p[2] + h / 2 - 0.1), role="crown" if k % 2 else "crown_dark", sides=4,
                taper=0, turn=45 + math.degrees(a), solo=True)
    m.box("CrownGem", size=(0.75, 0.25, 0.75), at=(0, -2.95, CZ + 0.3), role="glow", rot=(0, 45, 0))
    m.box("CrownGem_L", size=(0.5, 0.25, 0.5), at=(-1.25, -2.65, CZ + 0.3), role="violet", rot=(0, 45, -22))
    for s, sx in (("L", -1), ("R", 1)):
        m.beam(f"LArm{s}", start=(sx * 2.2, -0.1, CZ + 0.6), end=(sx * 4.2, -0.6, CZ + 1.4), role="iron", width=0.35, depth=0.35, solo=True)
        m.beam(f"LArmTip{s}", start=(sx * 4.1, -0.6, CZ + 1.4), end=(sx * 4.6, -0.6, CZ + 0.9), role="iron", width=0.3, depth=0.3, solo=True)
        lantern_pk(m, f"Lan{s}", (sx * 4.6, -0.6, CZ + 0.9), 1.0)
        m.beam(f"LArmB{s}", start=(sx * 1.6, 1.5, CZ + 0.6), end=(sx * 3.0, 2.8, CZ + 1.0), role="iron", width=0.3, depth=0.3, solo=True)
        lantern_pk(m, f"LanB{s}", (sx * 3.0, 2.8, CZ + 1.0), 0.8)
    # bras : manches, revers de brume en lambeaux, mains geantes en avant
    for s, sx in (("L", -1), ("R", 1)):
        SH = (sx * 4.3, 0.4, 11.2)
        EL = (sx * 6.7, -0.2, 8.6)
        WR = (sx * 6.9, -2.7, 10.0)
        m.beam(f"Sleeve{s}", start=SH, end=EL, role="navy", width=2.5, depth=2.7, chamfer=0.4, taper=1.25, solo=True)
        m.beam(f"Cuff{s}", start=vmid(SH, EL, 0.72), end=vadd(EL, vnorm(vsub(EL, SH)), 0.6), role="mist_light", width=3.2, depth=3.4,
               chamfer=0.4, taper=1.1, solo=True)
        for j, (dz, L) in enumerate(((-0.6, 2.4), (0.3, 1.6), (-1.4, 1.9))):
            m.beam(f"SleeveTat{s}{j}", start=(EL[0] + sx * 0.3 * j, EL[1] + 0.6 - 0.5 * j, EL[2] - 0.6 + dz * 0.3),
                   end=(EL[0] + sx * (0.4 + 0.3 * j), EL[1] + 1.3 - 0.4 * j, EL[2] - 0.6 - L), role="mist" if j != 1 else "navy_light",
                   width=1.1, depth=0.35, taper=0.08, solo=True)
        m.beam(f"Fore{s}", start=EL, end=WR, role="mist", width=1.8, depth=1.9, chamfer=0.35, taper=1.0, solo=True)
        hand_pk(m, s, sx, WR, 1.2)
    return m


PK = ropilot.model("PhantomKing", px=8, reset=True)
PK.reference(refs_mk("PhantomKing"))
PK.palette(**PAL_PK)
build_pk(AutoMirror(PK))
# dos de la cape : bordure de brume et embleme de couronne doree
PK.rect("Cape", "back", (0, 3.6), (6.6, 0.35), "mist_dark")
PK.rect("Cape", "back", (0, -3.7), (9.0, 0.35), "mist_dark")
PK.stamp("Cape", "back", (0, 0.8), ["#.#.#", "#####", "#####", ".###."], {"#": "crown"}, cell=0.45)
PK.stamp("Cape", "back", (0, -1.4), [".#.", "###", ".#."], {"#": "mist"}, cell=0.45)
print(PK.build())
ground_mk("PhantomKing")
print(PK.compare(image=False)["report"])
print(close_gaps_mk("PhantomKing"))
print("glow", glow_share_mk("PhantomKing"))
save_mine("PhantomKing")
