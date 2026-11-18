# Cinder Maw (anneau 3, Magma Field) : kit ropilot.model, px = 8, sans picots
# Reference de forme : workspace.GenM_CinderMaw (generate_mesh) rendu en vues orthogonales (Renders/Monster_Refs/GenM_CinderMaw_*.png)
# Ver de lave qui jaillit en arc : enorme gueule ronde tournee vers l'avant, bordee de plaques d'obsidienne et
# de crocs orange brillants, gorge de lave ; arcade d'obsidienne a deux yeux fendus orange au-dessus de la gueule ;
# collerette de plaques autour de la tete ; corps d'anneaux d'obsidienne noire separes par de la lave orange
# (ame lumineuse), fendus de veines orange peintes ; epines de feu sur le dos ; queue qui s'affine en pointe de lave.
exec(open(r"C:\Users\bouho\OneDrive - Conseil régional Grand Est - Numérique Educatif\Documents\Crack the Asteroid\tools\blender\monster_helpers.py", encoding="utf-8").read())

CM_COL = "Monster_CinderMaw"
CM_PAL = dict(
    obsid=dict(color="#2c2733", noise=0.04, shade=0.18, mottle=("#221e29", 0.3, 4), top=0.08),
    obsid_light=dict(color="#47404f", noise=0.035, shade=0.15, top=0.16),
    obsid_dark=dict(color="#1b1820", noise=0.03, shade=0.1),
    crack="#ff7a24", crack_dark="#c2420e",
    fire=dict(color="#ff6a12", noise=0.03, shade=0.18, top=0.12),
    fire_tip=dict(color="#ffc040", noise=0.02, shade=0.1, top=0.2),
    mouth=dict(color="#3a0f0c", noise=0.03, shade=0.1),
    gum=dict(color="#7a1e12", noise=0.03, shade=0.12),
    glow=dict(color="#ff7828", glow=True),
    glow_hot=dict(color="#ffb02e", glow=True),
)
CM_HC = (0, -5.0, 9.4)     # centre de la tete
CM_HR = 5.1                # rayon de la tete
CM_K = CM_HR / 4.4         # agrandissement de la gueule
CM_DZ = CM_HR - 4.4        # decalage vertical de l'arcade
CM_MY = -7.4               # face avant de la tete (fond de la gueule)


def cm_ring(r, a_deg, y, c=CM_HC):
    a = math.radians(a_deg)
    r *= CM_K
    return (c[0] + r * math.sin(a), y, c[2] + r * math.cos(a))


def build_cm(m):
    # ---- corps : anneaux d'obsidienne sur une ame de lave (arc qui jaillit, tete en avant et en haut)
    SP = [(0, -3.2, 9.2), (0, -0.9, 8.4), (0, 1.1, 6.9), (0, 2.7, 5.0), (0, 4.0, 3.1), (0, 5.6, 1.7), (0, 7.6, 1.1), (0, 9.4, 1.5)]
    RR = [3.6, 3.35, 3.05, 2.75, 2.4, 2.0, 1.55, 1.1]
    for i in range(len(SP) - 1):
        a, b = SP[i], SP[i + 1]
        # lave entre deux anneaux : courte bague lumineuse dans l'intervalle (pas d'ame pleine : peu de neon)
        if i < len(SP) - 2:
            c = SP[i + 2]
            mk_seg(m, f"Core{i}", mk_mid(a, b, 0.84), mk_mid(b, c, 0.12), RR[i + 1] * 0.88, "glow")
        else:
            mk_seg(m, f"Core{i}", mk_mid(a, b, 0.84), mk_add(b, mk_norm(mk_sub(b, a)), 0.3), RR[i + 1] * 0.88, "glow")
        # anneau d'obsidienne plus court que l'intervalle : la lave se voit entre deux anneaux
        a2, b2 = mk_mid(a, b, 0.1), mk_mid(a, b, 0.86)
        mk_seg(m, f"Seg{i}", a2, b2, RR[i], "obsid", taper=0.94)
    # pointe de la queue : cone de lave
    tip_a, tip_b = SP[-1], mk_add(SP[-1], (0, 1.9, 0.9))
    mk_seg(m, "TailTip", tip_a, tip_b, 0.95, "fire", taper=0.05, over=0.1)
    # ---- tete : gros prisme a 8 pans, face avant = gueule
    m.prism("Head", radius=CM_HR * 0.82, height=4.0, at=mk_add(CM_HC, (0, 0.2, 0)), role="obsid", sides=8, turn=22.5, rot=(90, 0, 0),
            taper=1.3)
    m.prism("Neck", radius=CM_HR * 0.86, height=1.2, at=mk_add(CM_HC, (0, 2.4, -0.15)), role="obsid_dark", sides=8, turn=22.5,
            rot=(90, 0, 0), taper=0.92)
    # fond de la gueule (rouge sombre), gencive, gorge de lave
    m.prism("Maw", radius=3.45 * CM_K, height=0.8, at=(0, CM_MY + 0.1, CM_HC[2]), role="mouth", sides=8, turn=22.5, rot=(90, 0, 0))
    m.prism("Throat", radius=1.1 * CM_K, height=0.4, at=(0, CM_MY - 0.3, CM_HC[2]), role="glow_hot", sides=8, turn=22.5, rot=(90, 0, 0))
    for k in range(8):
        a = 45 * k
        m.box(f"Gum{k}", size=(2.0 * CM_K, 0.4, 0.8 * CM_K), at=cm_ring(2.65, a, CM_MY - 0.35), role="gum", chamfer=0.12,
              rot=(0, a, 0), solo=True)
    # levres : 8 plaques d'obsidienne en couronne qui avancent devant la gueule
    for k in range(8):
        a = 22.5 + 45 * k
        c = cm_ring(3.95, a, CM_MY - 0.75)
        m.box(f"Lip{k}", size=(3.0 * CM_K, 1.6, 1.25 * CM_K), at=c, role="obsid_light" if k % 2 == 0 else "obsid", chamfer=0.25,
              taper=(0.82, 1), rot=(0, a, 0), solo=True)
    # crocs orange brillants : deux rangees vers le centre de la gueule
    for k in range(12):
        a = 15 + 30 * k
        base = cm_ring(3.35, a, CM_MY - 1.0)
        tip = cm_ring(1.45 if k % 2 == 0 else 1.95, a, CM_MY - 2.1)
        m.beam(f"Fang{k}", start=base, end=tip, role="glow" if k % 2 == 0 else "fire_tip", width=1.25, depth=1.1, taper=0.06, solo=True)
    for k in range(8):
        a = 22.5 + 45 * k
        base = cm_ring(2.85, a, CM_MY - 0.55)
        tip = cm_ring(1.85, a, CM_MY - 1.0)
        m.beam(f"Tooth{k}", start=base, end=tip, role="fire_tip", width=0.6, depth=0.55, taper=0.08, solo=True)
    # ---- arcade au-dessus de la gueule, deux yeux fendus orange, cornes de feu
    m.box("Brow", size=(7.4, 3.2, 1.9), at=(0, -5.4, 14.55 + CM_DZ), role="obsid_light", chamfer=0.45, taper=(0.7, 0.85), faces={"top": "obsid"})
    for s in (-1, 1):
        m.box(f"Eye{'L' if s < 0 else 'R'}", size=(1.5, 0.3, 0.55), at=(s * 1.6, -7.12, 14.45 + CM_DZ), role="glow_hot", rot=(0, s * 14, 0), solo=True)
        m.box(f"EyeSock{'L' if s < 0 else 'R'}", size=(1.95, 0.3, 0.95), at=(s * 1.6, -7.0, 14.45 + CM_DZ), role="obsid_dark", rot=(0, s * 14, 0), solo=True)
    m.beam("Horn_L", start=(-2.5, -5.4, 14.9 + CM_DZ), end=(-4.6, -3.6, 16.6 + CM_DZ), role="fire", width=1.1, depth=1.1, taper=0.08, chamfer=0.05, mirror=True)
    m.beam("HornTip_L", start=(-4.3, -3.85, 16.3 + CM_DZ), end=(-5.0, -3.3, 17.2 + CM_DZ), role="fire_tip", width=0.5, depth=0.5, taper=0.1, mirror=True)
    # ---- collerette : plaques d'obsidienne en eventail autour de la tete
    for k, a in enumerate((60, 95, 130, 230, 265, 300)):
        base = cm_ring(3.6, a, -3.4)
        tip = cm_ring(6.3, a, -1.8)
        m.beam(f"Frill{k}", start=base, end=tip, role="obsid_light", width=1.9, depth=0.55, taper=0.2, chamfer=0.08, solo=True)
    # ---- epines de feu sur le dos (une par anneau)
    for i in range(len(SP) - 2):
        a, b = SP[i], SP[i + 1]
        c = mk_mid(a, b, 0.48)
        d = mk_norm(mk_sub(b, a))
        up = mk_norm((0, -d[2], d[1])) if d[1] >= 0 else mk_norm((0, d[2], -d[1]))
        if up[2] < 0:
            up = (0, -up[1], -up[2])
        r = RR[i]
        base = mk_add(c, up, r * 0.75)
        L = 2.6 - 0.25 * i
        tip = mk_add(mk_add(base, up, L), d, 0.9)
        m.beam(f"Spine{i}", start=base, end=tip, role="fire", width=1.0 - 0.06 * i, depth=1.3 - 0.08 * i, taper=0.08, solo=True)
        m.beam(f"SpineTip{i}", start=mk_mid(base, tip, 0.6), end=mk_add(tip, mk_norm(mk_sub(tip, base)), 0.15), role="fire_tip",
               width=0.45, depth=0.55, taper=0.1, solo=True)
    return m


def paint_cm(m):
    # veines de lave peintes sur les flancs des anneaux et de la tete
    for i in range(6):
        for j, f in enumerate(("side1", "side6", "side3", "side4")):
            sg = 1 if (i + j) % 2 else -1
            m.line(f"Seg{i}", f, [(-0.7 * sg, 0.7), (-0.15 * sg, 0.35), (0.1 * sg, -0.1), (0.55 * sg, -0.6)], "crack", width=1)
    for j, f in enumerate(("side1", "side6", "side2", "side5", "side3", "side4")):
        sg = 1 if j % 2 else -1
        m.line("Head", f, [(-1.0 * sg, 1.0), (-0.4 * sg, 0.5), (-0.1 * sg, -0.2), (0.6 * sg, -0.5), (0.9 * sg, -1.1)], "crack", width=1)
        m.line("Head", f, [(-0.1 * sg, -0.2), (-0.6 * sg, -0.9)], "crack_dark", width=1)


CMM = ropilot.model(CM_COL, px=8, reset=True)
CMM.reference(mk_refs("GenM_CinderMaw"))
CMM.palette(**CM_PAL)
build_cm(CMM)
paint_cm(CMM)
print(CMM.build())
print(CMM.compare(image=False)["report"])
print("caps", mk_strip_caps(CM_COL, ("Core",)))
mk_close_gaps(CM_COL)
print("glow", mk_glow_share(CM_COL), "tris", mk_tris(CM_COL))
mk_save(CM_COL, "Monster_CinderMaw.blend")

# --- installation (18 nov.) : mk_join("Monster_CinderMaw", "M_CinderMaw") -> Shell + Glow + Glow2, import SANS rotation
# (Blender -Y arrive en +Z), puis dans Studio : pieces tournees de 180 deg autour du centre, Body invisible 1x1x1 au
# centre (PrimaryPart, regard -Z), Forward = "-Z". Neon recolore dans Studio : Glow (232, 95, 26), Glow2 (245, 135, 30)
# (le Neon rend jaune l'orange de la palette).
