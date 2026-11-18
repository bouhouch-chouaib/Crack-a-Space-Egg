# Sour Worm (anneau 11 Candy Comet) : kit ropilot.model, px = 8, sans picots
# Executer d'abord monster_common_r11_14.py. Reference : Renders/Monster_Refs/GenM_SourWorm2_*.png (generate_mesh regenere :
# la premiere reference etait une boule, pas un ver)
# Ver gelifie acidule geant : grand anneau enroule au sol puis second anneau, cou dresse en S comme un cobra, rayures
# rose vif / vert / jaune pailletees de sucre, ventre jaune pale ; capuchon de cobra a pointes ; tete-tube a gueule ronde
# enorme tournee vers l'avant (levre rose, gencive, deux couronnes de dents en bonbon blanches et roses, gorge lumineuse) ;
# yeux roses lumineux sur le dessus avec sourcils en colere, antennes de reglisse a boule jaune ; cristaux de sucre sur
# le dos et l'anneau (quelques-uns lumineux).
PAL_SW = dict(
    pink=dict(color="#ff4fa3", noise=0.03, shade=0.16, top=0.14, speckle=("#ffe6f3", 0.04)),
    pink_dark=dict(color="#d42f7f", noise=0.03, shade=0.14, top=0.1),
    green=dict(color="#6fdc2e", noise=0.03, shade=0.16, top=0.14, speckle=("#eaffd8", 0.04)),
    green_dark=dict(color="#45a81c", noise=0.03, shade=0.14),
    yellow=dict(color="#ffd82e", noise=0.03, shade=0.16, top=0.14, speckle=("#fff8d8", 0.04)),
    belly=dict(color="#fff0a8", noise=0.025, shade=0.12, rim=-0.15),
    sugar=dict(color="#fbfbff", noise=0.03, shade=0.1, top=0.1),
    tooth=dict(color="#fffaf2", noise=0.015, shade=0.12, top=0.1),
    toothp=dict(color="#ff8cc6", noise=0.015, shade=0.12, top=0.1),
    gum=dict(color="#c21f5e", noise=0.03, shade=0.1),
    mouth="#3a0a22", tongue=dict(color="#ff5f8a", noise=0.03, shade=0.12), eye="#1a0614", shine="#ffffff",
    brow=dict(color="#9a1d5c", noise=0.02, shade=0.1),
    glow=dict(color="#ff6ebe", glow=True),
)
STR = ["pink", "green", "yellow"]


def build_sw(m):
    cx, cy, R = 0.0, 0.6, 5.4
    pts = []
    n = 14
    for i in range(n + 1):
        a = math.radians(70 + 345 * i / n)
        pts.append((cx + R * math.cos(a), cy + R * math.sin(a), 1.4))
    for i in range(n):
        d = vnorm(vsub(pts[i + 1], pts[i]))
        m.beam(f"Coil{i}", start=vadd(pts[i], d, -0.6), end=vadd(pts[i + 1], d, 0.6), role=STR[i % 3], width=2.8, depth=2.8, chamfer=0.45, solo=True)
    tail_a = pts[-1]
    m.beam("TailTip", start=vadd(tail_a, (0.3, -0.6, 0), 0), end=(tail_a[0] + 1.0, tail_a[1] - 3.0, 0.8), role="pink", width=2.4, depth=2.3,
           taper=0.12, chamfer=0.35, solo=True)
    R2 = 3.1
    pts2 = []
    for i in range(10 + 1):
        a = math.radians(250 - 300 * i / 10)
        pts2.append((cx + R2 * math.cos(a), cy + 0.4 + R2 * math.sin(a), 3.6))
    for i in range(10):
        d = vnorm(vsub(pts2[i + 1], pts2[i]))
        m.beam(f"Coil2_{i}", start=vadd(pts2[i], d, -0.55), end=vadd(pts2[i + 1], d, 0.55), role=STR[(i + 1) % 3], width=2.6, depth=2.5,
               chamfer=0.4, solo=True)
    # cou dresse en S
    NK = [pts2[-1], (0, 3.1, 5.0), (0, 3.5, 7.0), (0, 3.0, 8.9), (0, 1.9, 10.5), (0, 1.0, 11.8)]
    NW = [2.6, 3.2, 3.6, 3.9, 4.1, 4.2]
    for i in range(len(NK) - 1):
        d = vnorm(vsub(NK[i + 1], NK[i]))
        m.beam(f"Neck{i}", start=vadd(NK[i], d, -0.5 if i else 0), end=vadd(NK[i + 1], d, 0.5), role=STR[i % 3], width=NW[i],
               depth=NW[i] * 0.95, taper=NW[i + 1] / NW[i], chamfer=0.16 * NW[i], solo=True)
        if 1 <= i <= 3:
            m.beam(f"NeckBelly{i}", start=vadd(NK[i], (0, -NW[i] * 0.47, 0.0)), end=vadd(NK[i + 1], (0, -NW[i + 1] * 0.47, 0.0)), role="belly",
                   width=NW[i] * 0.58, depth=0.45, chamfer=0.1, solo=True)
    # capuchon de cobra
    m.box("Hood_L", size=(3.4, 1.0, 6.4), at=(-3.3, 1.6, 12.6), role="pink_dark", chamfer=0.35, taper=(0.35, 1), rot=(-6, -32, 0),
          faces={"front": "yellow"})
    for k, (z, L) in enumerate(((10.6, 1.7), (12.3, 2.0), (14.0, 1.8))):
        m.prism(f"HoodSpike{k}_L", radius=0.5, height=L, at=(-5.0 + 0.55 * k, 1.75, z), role="green", sides=4, taper=0, turn=45,
                rot=(0, -75 + 14 * k, 0))
    # tete-tube et gueule ronde
    HC = (0, -0.6, 13.6)
    m.prism("Head", radius=3.7, height=5.0, at=HC, role="green", sides=8, turn=22.5, taper=1.08, rot=(90, 0, 0))
    m.prism("HeadBand", radius=3.95, height=1.3, at=(0, 0.6, 13.6), role="pink", sides=8, turn=22.5, rot=(90, 0, 0))
    m.prism("HeadBand2", radius=3.85, height=1.0, at=(0, 1.8, 13.6), role="yellow", sides=8, turn=22.5, rot=(90, 0, 0))
    yF = HC[1] - 2.5
    m.prism("Lip", radius=4.15, height=0.9, at=(0, yF - 0.25, 13.6), role="pink", sides=8, turn=22.5, rot=(90, 0, 0))
    m.prism("Gum", radius=3.2, height=0.5, at=(0, yF - 0.55, 13.6), role="gum", sides=8, turn=22.5, rot=(90, 0, 0))
    m.prism("MouthIn", radius=2.25, height=0.5, at=(0, yF - 0.62, 13.6), role="mouth", sides=8, turn=22.5, rot=(90, 0, 0))
    m.prism("Throat", radius=0.95, height=0.12, at=(0, -3.99, 13.6), role="glow", sides=8, turn=22.5, rot=(90, 0, 0))
    yT = yF - 0.75
    for k in range(10):
        a = math.radians(90 + 36 * k + 18)
        b = (2.85 * math.cos(a), yT, 13.6 + 2.85 * math.sin(a))
        t = (1.35 * math.cos(a), yT - 0.55, 13.6 + 1.35 * math.sin(a))
        m.beam(f"Tooth{k}", start=b, end=t, role="tooth" if k % 2 else "toothp", width=0.9, depth=0.7, taper=0.06, solo=True)
    for k in range(7):
        a = math.radians(90 + 360 / 7 * k)
        b = (2.05 * math.cos(a), yT + 0.1, 13.6 + 2.05 * math.sin(a))
        t = (0.8 * math.cos(a), yT - 0.2, 13.6 + 0.8 * math.sin(a))
        m.beam(f"InTooth{k}", start=b, end=t, role="toothp" if k % 2 else "tooth", width=0.6, depth=0.5, taper=0.06, solo=True)
    # yeux roses lumineux, sourcils en colere, antennes
    m.box("EyeBase_L", size=(2.4, 2.3, 2.0), at=(-1.85, -2.35, 18.5), role="green", chamfer=0.55, faces={"front": "green_dark"})
    m.box("Iris_L", size=(1.7, 0.3, 1.3), at=(-1.85, -3.55, 18.5), role="glow", rot=(0, 0, -6))
    m.box("Pupil_L", size=(0.42, 0.08, 0.9), at=(-1.72, -3.78, 18.45), role="eye")
    m.box("Shine_L", size=(0.34, 0.06, 0.34), at=(-2.25, -3.82, 18.82), role="shine")
    m.beam("Brow_L", start=(-3.3, -3.4, 19.85), end=(-0.45, -3.75, 19.0), role="brow", width=0.7, depth=0.8, chamfer=0.12)
    m.beam("Ant_L", start=(-1.2, 0.2, 17.0), end=(-2.6, 2.0, 19.6), role="pink_dark", width=0.45, depth=0.45, chamfer=0.08)
    m.box("AntBall_L", size=(1.05, 1.05, 1.05), at=(-2.65, 2.1, 19.8), role="yellow", chamfer=0.25)
    # cristaux de sucre
    for k, (p, r, h, tilt) in enumerate((((0, 1.0, 17.1), 0.65, 1.9, (-20, 0, 0)), ((-1.2, 2.3, 17.0), 0.5, 1.4, (-30, -25, 0)),
                                         ((1.25, 2.4, 17.0), 0.55, 1.5, (-25, 25, 0)), ((0, 3.4, 11.4), 0.55, 1.6, (-70, 0, 0)),
                                         ((0, 4.6, 8.7), 0.55, 1.5, (-85, 0, 0)), ((0, 4.9, 6.1), 0.5, 1.3, (-90, 0, 0)))):
        m.crystal(f"Sugar{k}", radius=r, height=h, at=p, role="sugar", sides=4, rot=tilt, solo=True)
    for i in range(0, 14, 2):
        p = pts[i]
        o = vnorm((p[0] - cx, p[1] - cy, 0))
        m.crystal(f"CSugar{i}", radius=0.42, height=1.05, at=(p[0] + o[0] * 0.3, p[1] + o[1] * 0.3, 2.55), role="sugar", sides=4,
                  rot=(math.degrees(-o[1]) * 0.35, math.degrees(o[0]) * 0.35, 0), solo=True)
    for k, p in enumerate(((pts2[1][0], pts2[1][1], 4.7), (-2.6, -1.4, 4.7), (pts2[8][0], pts2[8][1], 4.7))):
        m.crystal(f"GSugar{k}", radius=0.4, height=1.0, at=p, role="glow", sides=4, solo=True)
    return m


SW = ropilot.model("SourWorm", px=8, reset=True)
SW.reference(refs_mk("SourWorm2"))
SW.palette(**PAL_SW)
build_sw(AutoMirror(SW))
print(SW.build())
ground_mk("SourWorm")
print(SW.compare(image=False)["report"])
print(close_gaps_mk("SourWorm"))
print("glow", glow_share_mk("SourWorm"))
save_mine("SourWorm")
# compare() : face 0.70, dos 0.70, gauche 0.68, dessus 0.97 (dresse plus haut que la reference : 20,3 studs).
