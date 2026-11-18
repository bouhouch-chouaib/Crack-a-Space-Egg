# Devourer (anneau 5, Devourer Belt) : kit ropilot.model, px = 8, sans picots
# Reference de forme : l'ancien ReplicatedStorage.Assets.Monsters.Devourer (ver de pierre enroule, gueule a crocs verts)
# rendu en vues orthogonales (Renders/Monster_Refs/Devourer_*.png).
# Devoreur d'asteroides : tete blindee qui s'ouvre en quatre (crane superieur leve, machoire inferieure baissee,
# deux mandibles laterales en crochets), chaque piece bordee de crocs os et de crocs verts lumineux ; gorge en
# anneaux de gencives et de dents qui descend vers un tourbillon vert lumineux ; deux morceaux d'asteroide coinces
# dans la gueule ; six yeux verts lumineux sur le crane, couronne de cornes ; corps d'anneaux de roche anthracite
# moussue separes de lave verte, plaques dorsales et piques, enroule en point d'interrogation au-dessus et derriere.
exec(open(r"C:\Users\bouho\OneDrive - Conseil régional Grand Est - Numérique Educatif\Documents\Crack the Asteroid\tools\blender\monster_helpers.py", encoding="utf-8").read())

DV_COL = "Monster_Devourer"
DV_PAL = dict(
    rock=dict(color="#3b3f43", noise=0.04, shade=0.18, mottle=("#2f3336", 0.3, 4), top=0.1),
    rock_light=dict(color="#585e62", noise=0.035, shade=0.15, top=0.14),
    rock_dark=dict(color="#24272a", noise=0.03, shade=0.1),
    moss=dict(color="#5c8a2e", noise=0.04, shade=0.14, mottle=("#4a7426", 0.35, 3), top=0.12),
    plate=dict(color="#4a5048", noise=0.035, shade=0.16, mottle=("#556b3c", 0.25, 5), top=0.14),
    mouth=dict(color="#16240f", noise=0.03, shade=0.08),
    gum=dict(color="#2f4a1f", noise=0.03, shade=0.12),
    fang=dict(color="#e6edcf", noise=0.02, shade=0.14, top=0.1),
    horn=dict(color="#c9cdb4", noise=0.02, shade=0.14, top=0.12),
    aster=dict(color="#8a7560", noise=0.045, shade=0.18, mottle=("#6e5c4a", 0.35, 3), top=0.12),
    vein="#7dff3c", vein_dark="#3f8a1a", eye_dark="#0b1208",
    glow=dict(color="#86f040", glow=True),
    glow_hot=dict(color="#c8ff5a", glow=True),
)
DV_C = 35.0                        # ouverture du crane et de la machoire (degres)
DV_HU = (0, -1.4, 10.6)            # charniere du crane
DV_HD = (0, -1.4, 5.4)             # charniere de la machoire
DV_SKIP = {("Gum", 0), ("Gum", 4)}  # gencives cachees dans le crane et la machoire


def dv_dir(up, deg=DV_C):
    a = math.radians(deg)
    return (0, -math.cos(a), math.sin(a) * (1 if up else -1))


def dv_ring_boxes(m, name, y, cz, r, n, size, role, a0=0.0):
    for k in range(n):
        a = a0 + 360.0 * k / n
        ar = math.radians(a)
        if (name, k) in DV_SKIP:
            continue
        m.box(f"{name}{k}", size=size, at=(r * math.sin(ar), y, cz + r * math.cos(ar)), role=role, chamfer=0.1, rot=(0, a, 0), solo=True)


def dv_top(u, v, h=0.0):
    # point du dessus du crane (repere du crane : u vers +X, v vers l'arriere, h au-dessus de la face)
    t = math.radians(DV_C)
    c = mk_add(DV_HU, dv_dir(True), 3.6)
    ly, lz = (0, math.cos(t), -math.sin(t)), (0, math.sin(t), math.cos(t))
    return mk_add(mk_add(mk_add(c, (u, 0, 0)), ly, v), lz, 1.4 + h)


def build_dv(m):
    cz = 8.0
    # ---- base de la tete (cou blinde) et collerette
    m.prism("HeadBase", radius=4.7, height=4.6, at=(0, 0.6, cz), role="rock", sides=8, turn=22.5, rot=(90, 0, 0), taper=1.08)
    m.prism("Collar", radius=5.3, height=1.3, at=(0, 2.6, cz), role="plate", sides=8, turn=22.5, rot=(90, 0, 0))
    # ---- crane superieur leve (porte les yeux) et machoire inferieure baissee
    du, dd = dv_dir(True), dv_dir(False)
    m.box("Skull", size=(8.6, 7.6, 2.8), at=mk_add(DV_HU, du, 3.6), role="rock", chamfer=0.6, axis="y", taper=(0.78, 0.7),
          rot=(-DV_C, 0, 0), faces={"bottom": "mouth"})
    m.box("Jaw", size=(7.8, 7.0, 2.2), at=mk_add(DV_HD, dd, 3.3), role="rock", chamfer=0.5, axis="y", taper=(0.75, 0.75),
          rot=(DV_C, 0, 0), faces={"top": "mouth"})
    m.box("Chin", size=(4.2, 2.2, 1.6), at=mk_add(mk_add(DV_HD, dd, 5.6), (0, 0.2, -1.1)), role="plate", chamfer=0.35, rot=(DV_C, 0, 0))
    # plaques de mousse sur le crane et la machoire
    m.box("SkullMoss", size=(5.6, 4.0, 0.5), at=m.surface("Skull", "top", (0, 0.9)), role="moss", chamfer=0.15, taper=(0.85, 0.85))
    # ---- crocs du crane (pendent vers la gorge) et de la machoire (montent)
    nu = (0, -math.sin(math.radians(DV_C)), -math.cos(math.radians(DV_C)))     # normale du dessous du crane
    nd = (0, -math.sin(math.radians(DV_C)), math.cos(math.radians(DV_C)))      # normale du dessus de la machoire
    for k, x in enumerate((-3.0, -1.8, -0.6, 0.6, 1.8, 3.0)):
        big = k in (0, 5, 2, 3)
        base = mk_add(mk_add(DV_HU, du, 6.6 - 0.25 * abs(x)), nu, 1.1)
        base = (x * (0.92 if abs(x) > 2 else 1.0), base[1], base[2])
        tip = mk_add(mk_add(base, nu, 2.3 if big else 1.6), (0, 0.5, 0))
        m.beam(f"FangU{k}", start=base, end=tip, role="glow" if k in (0, 5) else "fang", width=0.85 if big else 0.6, depth=0.8, taper=0.06, solo=True)
    for k, x in enumerate((-2.6, -1.3, 0.0, 1.3, 2.6)):
        base = mk_add(mk_add(DV_HD, dd, 6.1 - 0.25 * abs(x)), nd, 0.9)
        base = (x, base[1], base[2])
        tip = mk_add(mk_add(base, nd, 1.9 if k != 2 else 1.4), (0, 0.4, 0))
        m.beam(f"FangD{k}", start=base, end=tip, role="glow" if k in (0, 4) else "fang", width=0.8, depth=0.75, taper=0.06, solo=True)
    # crocs lateraux le long du crane et de la machoire
    for s in (-1, 1):
        for k, t in enumerate((2.6, 4.4)):
            base = mk_add(mk_add(DV_HU, du, t), nu, 1.0)
            base = (s * 3.4, base[1], base[2])
            m.beam(f"FangSU{k}{'L' if s < 0 else 'R'}", start=base, end=mk_add(base, nu, 1.5), role="fang", width=0.6, depth=0.6, taper=0.06, solo=True)
            base = mk_add(mk_add(DV_HD, dd, t), nd, 0.8)
            base = (s * 3.0, base[1], base[2])
            m.beam(f"FangSD{k}{'L' if s < 0 else 'R'}", start=base, end=mk_add(base, nd, 1.3), role="fang", width=0.55, depth=0.55, taper=0.06, solo=True)
    # ---- mandibles laterales en crochets (se referment vers la gueule)
    MP = [(-4.3, -1.6, cz), (-6.9, -4.6, cz + 0.3), (-7.0, -7.6, cz + 0.1), (-5.4, -9.8, cz - 0.1), (-3.6, -10.6, cz - 0.2)]
    mk_curve(m, "Mand_L", MP, [3.0, 2.6, 2.0, 1.3, 0.4], [1.6, 1.4, 1.1, 0.8, 0.4], ["rock", "rock", "plate", "horn"], ext=0.18, chamf=0.15,
             roll=90, mirror=True)
    for k, t in enumerate((0.45, 0.75)):
        i = 1 + k
        b = mk_mid(MP[i], MP[i + 1], 0.5)
        m.beam(f"MandFang{k}_L", start=mk_add(b, (0.5, 0, 0)), end=mk_add(b, (1.9, -0.3, 0)), role="glow" if k == 0 else "fang", width=0.6,
               depth=0.7, taper=0.06, mirror=True)
    # ---- gorge : anneaux de gencives et de dents qui descendent vers le tourbillon vert
    m.prism("Gullet", radius=3.9, height=0.8, at=(0, -1.75, cz), role="mouth", sides=8, turn=22.5, rot=(90, 0, 0))
    dv_ring_boxes(m, "Gum", -2.35, cz, 3.0, 8, (2.6, 0.6, 1.0), "gum", 0)
    for k in range(8):
        a = math.radians(22.5 + 45 * k)
        b = (3.2 * math.sin(a), -2.5, cz + 3.2 * math.cos(a))
        e = (1.7 * math.sin(a), -3.2, cz + 1.7 * math.cos(a))
        m.beam(f"RingFang{k}", start=b, end=e, role="fang", width=0.6, depth=0.55, taper=0.06, solo=True)
    m.prism("Vortex", radius=1.6, height=0.4, at=(0, -2.25, cz), role="glow", sides=8, turn=22.5, rot=(90, 0, 0))
    m.prism("VortexCore", radius=0.75, height=0.4, at=(0, -2.5, cz), role="glow_hot", sides=8, rot=(90, 0, 0))
    # morceaux d'asteroide coinces dans la gueule
    m.box("Aster0", size=(2.0, 1.8, 1.7), at=(1.5, -6.0, cz + 2.3), role="aster", chamfer=0.4, rot=(20, 15, 30), solo=True)
    m.box("Aster1", size=(1.5, 1.4, 1.3), at=(-1.6, -5.1, cz - 1.5), role="aster", chamfer=0.35, rot=(-15, 30, -20), solo=True)
    # ---- six yeux verts lumineux sur le crane, arcades, couronne de cornes
    # yeux sur la face avant du crane (visibles de face, au-dessus des crocs) : deux grands, deux petits plus haut
    for k, (u, v, s) in enumerate(((1.25, 0.15, 1.05), (2.55, 0.35, 0.75))):
        m.box(f"EyeSock{k}_L", size=(s + 0.5, s * 0.7 + 0.4, 0.3), at=m.surface("Skull", "front", (-u, v)), role="eye_dark", mirror=True)
        m.box(f"Eye{k}_L", size=(s, s * 0.7, 0.45), at=m.surface("Skull", "front", (-u, v)), role="glow_hot", rot=(0, 0, -14), mirror=True)
    for k, (u, v, s) in enumerate(((1.0, -0.6, 0.6), (2.4, -0.2, 0.5))):
        m.box(f"EyeTop{k}_L", size=(s, s * 0.75, 0.4), at=m.surface("Skull", "top", (-u, -3.2 + v)), role="glow_hot", mirror=True)
    m.beam("Brow_L", start=dv_top(-3.3, -3.75, 0.05), end=dv_top(-0.4, -3.55, 0.05), role="rock_dark", width=0.6,
           depth=0.8, chamfer=0.1, mirror=True)
    for k, (u, L, sx) in enumerate(((0.0, 4.2, 0.0), (2.4, 3.6, 1.6), (3.9, 2.8, 2.6))):
        base = dv_top(-u, 2.4, -0.2)
        tip = mk_add(base, (-sx, 3.0, L * 0.8))
        m.beam(f"Horn{k}_L", start=base, end=tip, role="horn", width=1.3 - 0.2 * k, depth=1.3 - 0.2 * k, taper=0.08, chamfer=0.06,
               mirror=k > 0, solo=k == 0)
    # ---- corps enroule en point d'interrogation : anneaux de roche moussue, lave verte entre deux anneaux
    SP = [(0, 2.8, cz + 0.3), (0, 4.8, cz + 3.3), (0, 7.4, cz + 5.3), (0, 10.4, cz + 5.4), (0, 12.6, cz + 3.4), (0, 13.0, cz + 0.2),
          (0, 11.6, cz - 2.8), (0, 9.2, cz - 4.6), (0, 6.6, cz - 5.0)]
    RR = [4.0, 3.8, 3.6, 3.35, 3.1, 2.8, 2.45, 2.0, 1.5]
    for i in range(len(SP) - 1):
        a, b = SP[i], SP[i + 1]
        mk_seg(m, f"Seg{i}", mk_mid(a, b, 0.08), mk_mid(a, b, 0.86), RR[i], "rock" if i % 2 == 0 else "plate", taper=0.94)
        if i < len(SP) - 2:
            c = SP[i + 2]
            mk_seg(m, f"Core{i}", mk_mid(a, b, 0.84), mk_mid(b, c, 0.1), RR[i + 1] * 0.88, "glow")
        # plaque dorsale moussue et pique
        d = mk_norm(mk_sub(b, a))
        out = (0, -d[2], d[1])                  # normale a la courbe, vers l'exterieur de l'enroulement
        v = mk_sub(mk_mid(a, b), (0, 8.8, cz + 0.3))      # depuis le centre de l'enroulement
        if out[1] * v[1] + out[2] * v[2] < 0:
            out = (0, -out[1], -out[2])
        c = mk_mid(a, b, 0.47)
        r = RR[i]
        m.beam(f"Scute{i}", start=mk_add(mk_add(c, out, r * 0.82), d, -1.0), end=mk_add(mk_add(c, out, r * 0.82), d, 1.0), role="moss",
               width=r * 1.05, depth=0.7, taper=0.8, chamfer=0.12, solo=True)
        m.beam(f"Spike{i}", start=mk_add(c, out, r * 0.95), end=mk_add(mk_add(c, out, r * 0.95 + 2.4 - 0.15 * i), d, -0.8), role="horn",
               width=0.9, depth=1.0, taper=0.08, solo=True)
        if i % 2 == 0:
            for s in (-1, 1):
                m.beam(f"SideSpike{i}{'L' if s < 0 else 'R'}", start=(s * r * 0.8, c[1], c[2]), end=(s * (r + 1.7), c[1] + d[1] * -0.6, c[2] + d[2] * -0.6),
                       role="horn", width=0.7, depth=0.7, taper=0.08, solo=True)
    tail_a, tail_b = SP[-1], mk_add(SP[-1], mk_norm(mk_sub(SP[-1], SP[-2])), 2.2)
    mk_seg(m, "TailTip", tail_a, tail_b, 1.2, "horn", taper=0.05, over=0.1)
    return m


def paint_dv(m):
    # veines vertes sur les anneaux et la base de la tete
    for i in range(8):
        for j, f in enumerate(("side1", "side6", "side3", "side4")):
            sg = 1 if (i + j) % 2 else -1
            m.line(f"Seg{i}", f, [(-0.8 * sg, 0.8), (-0.2 * sg, 0.3), (0.15 * sg, -0.2), (0.7 * sg, -0.7)], "vein", width=1)
            m.line(f"Seg{i}", f, [(0.15 * sg, -0.2), (-0.3 * sg, -0.8)], "vein_dark", width=1)
    for j, f in enumerate(("side1", "side6", "side2", "side5")):
        sg = 1 if j % 2 else -1
        m.line("HeadBase", f, [(-1.0 * sg, 1.0), (-0.3 * sg, 0.4), (0.0, -0.3), (0.8 * sg, -0.9)], "vein", width=1)


DVM = ropilot.model(DV_COL, px=8, reset=True)
DVM.reference(mk_refs("Devourer"))
DVM.palette(**DV_PAL)
build_dv(DVM)
paint_dv(DVM)
print(DVM.build())
print(DVM.compare(image=False)["report"])
print("caps", mk_strip_caps(DV_COL, ("Core",)))
mk_close_gaps(DV_COL)
print(ropilot.check_model(collection=DV_COL, max_lines=6))
print("glow", mk_glow_share(DV_COL), "tris", mk_tris(DV_COL))
mk_save(DV_COL, "Monster_Devourer.blend")

# --- installation (18 nov.) : mk_join(<collection>, "M_<Model>") -> Shell + Glow + Glow2, import SANS rotation
# (Blender -Y arrive en +Z), puis dans Studio : pieces tournees de 180 deg autour du centre, Body invisible 1x1x1 au
# centre (PrimaryPart, regard -Z), Forward = "-Z". Couleur Neon principale reglee sur la couleur du monstre (Config).
