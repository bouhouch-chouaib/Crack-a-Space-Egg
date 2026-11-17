# Lantern Wyvern (R14_T7, Cosmic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R14_Refs/Ref_R14_T7_*.png)
# Wyverne fantome colossale debout sur deux pattes, ailes immenses levees et deployees : corps bleu nuit a
# ventre de plaques de brume, cretes de brume turquoise en lambeaux le long du cou, du dos et de la queue,
# coeur spectral lumineux au poitrail ; tete bien detachee, museau ardoise, grands yeux turquoise lumineux
# separes a reflets sous des arcades fieres, machoire (rig Jaw) ; cornes creme recourbees a bagues violettes,
# une lanterne de fer a flamme orange pendue au bout de chaque corne (suit la tete) ; ailes (rig WingL / WingR) :
# bras et doigts bleu nuit a griffes creme, membranes de brume turquoise pale qui s'eclaircissent vers le corps
# et finissent en lambeaux pointus ; pattes digitigrades puissantes (rig LegL / LegR) a griffes creme ;
# longue queue (rig Tail) qui s'affine, passe du bleu nuit au turquoise et finit en volute de brume lumineuse.
import ropilot, bpy, os, math

def close_gaps_r14(col_name, rounds=25, extra=0.025):
    # ferme les petits ecarts signales par check_model (deplace la piece de la valeur proposee, plus un leger
    # recouvrement) ; les ecarts sont de quelques centiemes de stud, invisibles a l'oeil
    import io, re, contextlib
    pat = re.compile(r"gap [\d.]+ studs between \S+ and \S+: move (\S+) by \(([-\d.]+), ([-\d.]+), ([-\d.]+)\)")
    fl = re.compile(r"FLOATING (.+?) \(.*move by \(([-\d.]+), ([-\d.]+), ([-\d.]+)\)")
    for _ in range(rounds):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            res = ropilot.check_model(collection=col_name, max_lines=100000)
        if res["problems"] == 0:
            break
        moved = set()
        for line in buf.getvalue().splitlines():
            g = pat.search(line)
            names, v = None, None
            if g:
                names, v = [g.group(1)], [float(g.group(i)) for i in (2, 3, 4)]
            else:
                f = fl.search(line)
                if f:
                    names, v = [n.strip() for n in f.group(1).split(",")], [float(f.group(i)) for i in (2, 3, 4)]
            if not names:
                continue
            L = math.sqrt(sum(c * c for c in v)) or 1.0
            for n in names:
                o = bpy.data.objects.get(n)
                if o is None or n in moved:
                    continue
                moved.add(n)
                for i in range(3):
                    o.location[i] += v[i] * (1 + extra / L)
    return ropilot.check_model(collection=col_name, max_lines=12)


def ground_r14(col_name):
    # pose le point le plus bas sur z = 0
    bpy.context.view_layer.update()
    objs = [o for o in bpy.data.collections[col_name].all_objects if o.type == "MESH"]
    z0 = min(min((o.matrix_world @ v.co).z for v in o.data.vertices) for o in objs)
    for o in objs:
        o.location.z -= z0
    bpy.context.view_layer.update()
    return z0


def save_only_r14(col_name, fname):
    # n'ecrit que la collection de la creature (pas les modeles des autres taches ni les references)
    col = bpy.data.collections[col_name]
    bpy.data.libraries.write(os.path.join(ropilot.FILES_DIR, fname), {col}, fake_user=True, compress=True)


def glow_share_r14(col_name):
    # part de surface lumineuse (materiaux « glow ») dans la creature
    tot = glo = 0.0
    for o in bpy.data.collections[col_name].all_objects:
        if o.type != "MESH":
            continue
        a = sum(p.area for p in o.data.polygons) * (o.matrix_world.to_scale()[0] ** 2)
        tot += a
        mat = o.material_slots[0].material.name if o.material_slots and o.material_slots[0].material else ""
        if "glow" in mat.lower():
            glo += a
    return round(glo / tot, 4) if tot else 0


def load_col_r14(col_name, fname):
    # recharge la collection sauvegardee (Blender partage, souvent redemarre) ; remplace celle de la scene
    old = bpy.data.collections.get(col_name)
    if old:
        for o in list(old.all_objects):
            bpy.data.objects.remove(o, do_unlink=True)
        bpy.data.collections.remove(old)
    path = os.path.join(ropilot.FILES_DIR, fname)
    with bpy.data.libraries.load(path, link=False) as (src, dst):
        dst.collections = [c for c in src.collections if c == col_name]
    for c in dst.collections:
        if c is not None:
            bpy.context.scene.collection.children.link(c)
    return bpy.data.collections.get(col_name)

R14R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R14_Refs")
REF14_7 = {v: os.path.join(R14R, f"Ref_R14_T7_{v}.png") for v in ("front", "left", "back", "top")}
PAL14_7 = dict(
    scale=dict(color="#2e3f58", noise=0.035, shade=0.16, mottle=("#283850", 0.25, 4), top=0.14),
    scale_dark=dict(color="#1e2a3a", noise=0.03, shade=0.12, top=0.1),
    slate=dict(color="#4a5868", noise=0.03, shade=0.14, top=0.12),
    slate_light=dict(color="#6a7a8c", noise=0.025, shade=0.12, top=0.12),
    belly=dict(color="#ddeff0", noise=0.025, shade=0.12, top=0.08, rim=-0.18),
    belly_dark=dict(color="#a9c3c9", noise=0.02),
    memb=dict(color="#8fe3d8", noise=0.035, shade=0.06, mottle=("#a6ece2", 0.3, 5), streaks=("#b9f2ea", 0.2, "v")),
    memb_light=dict(color="#cfeeee", noise=0.03, shade=0.06, mottle=("#ddf5f4", 0.3, 5), streaks=("#e8fafa", 0.2, "v")),
    flame=dict(color="#6ef0dc", noise=0.03, shade=0.12, top=0.15, streaks=("#9ff8ea", 0.25, "v")),
    flame_dark=dict(color="#2fa79a", noise=0.03, shade=0.12, top=0.12),
    horn=dict(color="#f6e9c8", noise=0.02, shade=0.14, top=0.12),
    horn_dark=dict(color="#d6c49a", noise=0.02, shade=0.12),
    violet=dict(color="#7a5ab8", noise=0.025, shade=0.12, top=0.15),
    iron=dict(color="#2a2a32", noise=0.025, shade=0.12, top=0.15),
    mouth="#1a1424", eye="#0e1622", shine="#ffffff",
    glow=dict(color="#22e0c4", glow=True), glow_orange=dict(color="#e85f1a", glow=True),
)
MR14 = dict(mirror=True)


def add14(a, b, k=1.0):
    return tuple(a[i] + b[i] * k for i in range(3))


def sub14(a, b):
    return tuple(a[i] - b[i] for i in range(3))


def norm14(v):
    L = math.sqrt(sum(c * c for c in v)) or 1.0
    return tuple(c / L for c in v)


def mid14(a, b, t=0.5):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def curve14(m, name, pts, widths, depths, roles, ext=0.12, chamf=0.15, **kw):
    # chaine de segments qui se chevauchent (courbe continue), largeur qui varie
    sfx = "_L" if kw.get("mirror") else ""
    for i in range(len(pts) - 1):
        d = norm14(sub14(pts[i + 1], pts[i]))
        last = i == len(pts) - 2
        m.beam(f"{name}{i}{sfx}", start=add14(pts[i], d, -ext if i else 0), end=add14(pts[i + 1], d, 0 if last else ext),
               role=roles[i % len(roles)], width=widths[i], depth=depths[i], taper=max(0.05, widths[i + 1] / widths[i]),
               chamfer=chamf * widths[i + 1], **kw)


def panel7(m, name, apex, a, b, role, th=0.22, **kw):
    # membrane triangulaire dans le plan de l'aile (x-z) : pointe sur `apex`, base de a a b
    e = mid14(a, b)
    v = sub14(apex, e)
    h = math.hypot(v[0], v[2])
    w = math.hypot(b[0] - a[0], b[2] - a[2])
    ry = math.degrees(math.atan2(v[0], v[2]))
    c = mid14(e, apex)
    m.box(name, size=(w, th, h), at=c, role=role, taper=(0.04, 1), rot=(0, ry, 0), **kw)


def tatter7(m, name, base, d, L, w, role, th=0.18, **kw):
    # lambeau de membrane : bande plate qui s'affine en pointe, dans le plan de l'aile (x-z)
    d = norm14(d)
    tip = add14(base, d, L)
    ry = math.degrees(math.atan2(d[0], d[2]))
    m.box(name, size=(w, th, L), at=mid14(base, tip), role=role, taper=(0.05, 1), rot=(0, ry, 0), **kw)


HK7, HC7 = 1.0, (0, -2.4, 19.3)


def build_t7(m):
    # ---- pattes (rig LegL / LegR) : cuisse puissante, jambe digitigrade, pied a trois doigts et griffes creme
    m.beam("Thigh_L", start=(-2.6, 0.8, 8.6), end=(-3.0, -1.2, 4.6), role="scale", width=2.9, depth=3.4, chamfer=0.8, taper=0.65, **MR14)
    m.box("Knee_L", size=(1.7, 1.5, 1.4), at=(-3.05, -1.75, 4.8), role="slate", chamfer=0.35, **MR14)
    m.beam("Shin_L", start=(-3.05, -1.3, 5.0), end=(-3.15, 0.9, 1.7), role="scale", width=1.7, depth=1.9, chamfer=0.35, taper=0.85, **MR14)
    m.beam("Foot_L", start=(-3.15, 1.0, 1.9), end=(-3.2, -0.8, 0.55), role="scale_dark", width=1.9, depth=1.3, chamfer=0.3, **MR14)
    for k, dx in enumerate((-0.85, 0.0, 0.85)):
        m.beam(f"Toe{k}_L", start=(-3.2, -0.6, 0.6), end=(-3.2 + dx * 1.2, -2.5, 0.42), role="scale_dark", width=0.75, depth=0.7, chamfer=0.1, **MR14)
        m.prism(f"Claw{k}_L", radius=0.32, height=0.85, at=(-3.2 + dx * 1.25, -2.85, 0.36), role="horn", sides=4, taper=0, rot=(110, 0, 0), **MR14)
    m.beam("ToeB_L", start=(-3.15, 0.8, 1.1), end=(-3.15, 2.2, 0.4), role="scale_dark", width=0.65, depth=0.6, **MR14)
    # ---- corps dresse : hanches, ventre, poitrail (prismes a 8 pans), plaques de brume sur le ventre
    m.prism("Hips", radius=3.4, height=3.6, at=(0, 0.7, 7.7), role="scale", sides=8, turn=22.5, taper=0.95)
    m.prism("Trunk", radius=3.25, height=7.4, at=(0, 0.35, 11.6), role="scale", sides=8, turn=22.5, taper=0.78)
    m.box("Pecs", size=(5.2, 2.6, 3.0), at=(0, -0.9, 13.4), role="scale", chamfer=1.0, taper=(0.8, 0.9))
    # ventre : grandes plaques de brume qui se chevauchent
    for k, (z, w, yf, tilt) in enumerate(((7.1, 3.1, -2.3, -4), (8.9, 3.25, -2.3, -6), (10.7, 3.2, -2.3, -8), (12.5, 3.15, -2.25, -10),
                                         (14.1, 2.6, -2.0, -14))):
        m.box(f"Plate{k}", size=(w, 0.6, 1.95), at=(0, yf, z), role="belly", chamfer=0.25, taper=(0.86, 1), rot=(tilt, 0, 0), solo=True)
    m.box("Heart", size=(1.1, 0.3, 1.1), at=(0, -2.92, 12.5), role="glow", rot=(0, 45, 0))
    m.box("HeartRim", size=(1.6, 0.25, 1.6), at=(0, -2.8, 12.5), role="flame_dark", rot=(0, 45, 0))
    # ---- cou en S, plaques de brume a l'avant
    NK = [(0, 0.0, 14.6), (0, -0.7, 16.2), (0, -1.4, 17.6), (0, -1.9, 18.6)]
    curve14(m, "Neck", NK, [2.9, 2.5, 2.2, 2.0], [3.0, 2.6, 2.3, 2.1], ["scale"], ext=0.25, chamf=0.25)
    for k in range(2):
        a, b = NK[k + 1], NK[k + 2]
        m.beam(f"NeckPlate{k}", start=add14(a, (0, -1.05, -0.2)), end=add14(b, (0, -0.95, -0.1)), role="belly", width=1.5, depth=0.4, chamfer=0.08)
    # ---- tete (rig Head) : crane, museau, plaque ardoise, narines, yeux turquoise lumineux a reflets, arcades
    m.box("Skull", size=(3.3, 3.3, 2.7), at=(0, -2.3, 19.5), role="scale", chamfer=0.7, faces={"bottom": "belly"})
    m.box("Snout", size=(2.5, 3.2, 1.65), at=(0, -4.75, 19.05), role="scale", chamfer=0.4, axis="y", taper=(0.78, 0.82), faces={"bottom": "belly"})
    m.box("SnoutPlate", size=(1.5, 2.6, 0.25), at=(0, -4.6, 19.9), role="slate", chamfer=0.06, axis="y", taper=(0.6, 1))
    m.box("MouthIn", size=(2.0, 2.8, 0.3), at=(0, -4.6, 18.25), role="mouth")
    m.box("Nostril_L", size=(0.3, 0.2, 0.22), at=(-0.45, -6.38, 19.45), role="scale_dark", **MR14)
    m.box("Iris_L", size=(1.0, 0.26, 1.05), at=(-1.0, -3.98, 20.12), role="glow", rot=(0, -12, 0), **MR14)
    m.box("Pupil_L", size=(0.32, 0.08, 0.66), at=(-0.95, -4.14, 20.1), role="eye", rot=(0, -12, 0), **MR14)
    m.box("Shine_L", size=(0.26, 0.06, 0.26), at=(-1.2, -4.17, 20.38), role="shine", **MR14)
    m.box("Shine2_L", size=(0.12, 0.06, 0.12), at=(-0.75, -4.17, 19.85), role="shine", **MR14)
    m.beam("Brow_L", start=(-1.8, -3.85, 20.85), end=(-0.55, -4.0, 20.95), role="slate", width=0.42, depth=0.5, chamfer=0.08, **MR14)
    # cornes creme recourbees (bague violette), lanterne de fer pendue au bout
    HN = [(-1.1, -1.7, 20.5), (-1.9, -1.5, 21.6), (-2.8, -1.4, 22.45), (-3.8, -1.9, 22.75), (-4.3, -2.7, 22.25)]
    curve14(m, "Horn_L", HN, [0.95, 0.8, 0.62, 0.45, 0.22], [0.95, 0.8, 0.62, 0.45, 0.22], ["horn", "horn", "horn_dark", "horn"], ext=0.1,
            chamf=0.1, **MR14)
    m.prism("HornRing_L", radius=0.62, height=0.38, at=mid14(HN[0], HN[1], 0.35), role="violet", sides=6, rot=(0, -40, 0), **MR14)
    lt = (-4.3, -2.75, 22.1)
    lx, ly = lt[0], lt[1]
    m.beam("LChain_L", start=lt, end=(lx, ly, 21.2), role="iron", width=0.16, depth=0.16, **MR14)
    m.box("LCap_L", size=(1.15, 1.15, 0.42), at=(lx, ly, 21.05), role="iron", chamfer=0.1, taper=(0.5, 0.5), **MR14)
    m.box("LGlass_L", size=(0.82, 0.82, 1.05), at=(lx, ly, 20.3), role="glow_orange", **MR14)
    for k, (dx, dy) in enumerate(((-0.45, -0.45), (0.45, -0.45), (-0.45, 0.45), (0.45, 0.45))):
        m.box(f"LBar{k}_L", size=(0.16, 0.16, 1.1), at=(lx + dx, ly + dy, 20.3), role="iron", **MR14)
    m.box("LBase_L", size=(1.05, 1.05, 0.26), at=(lx, ly, 19.7), role="iron", chamfer=0.06, **MR14)
    # crete de brume derriere la tete (suit la tete)
    for k, (y, z) in enumerate(((-1.0, 21.0), (-0.3, 20.4))):
        m.beam(f"HeadFrill{k}", start=(0, y, z - 0.4), end=(0, y + 1.6, z + 0.9 - 0.3 * k), role="flame" if k else "flame_dark", width=0.45,
               depth=1.3, taper=0.1, solo=True)
    # ---- machoire (rig Jaw)
    m.box("Jaw", size=(2.1, 3.0, 0.7), at=(0, -4.35, 17.85), role="scale", chamfer=0.18, axis="y", taper=(0.78, 0.85),
          faces={"top": "mouth", "bottom": "belly"})
    # ---- cretes de brume turquoise en lambeaux le long du cou et du dos
    for k, (y, z, L) in enumerate(((0.8, 17.2, 1.8), (1.5, 15.6, 2.0), (2.5, 13.9, 2.1), (3.0, 12.0, 2.0), (3.35, 10.1, 1.8), (3.6, 8.3, 1.6))):
        m.beam(f"Frill{k}", start=(0, y - 0.6, z + 0.2), end=(0, y + L * 0.85, z + L * 0.55), role="flame" if k % 2 == 0 else "flame_dark", width=0.45,
               depth=1.4, taper=0.08, solo=True)
    # ---- ailes (rig WingL / WingR) : epaule, bras, avant-bras, poignet a griffe, trois doigts, membranes en lambeaux
    WR, WEL, WW = (-3.0, 1.0, 14.8), (-5.7, 1.6, 19.0), (-8.6, 1.8, 22.9)
    F = [(-15.4, 2.3, 21.4), (-14.2, 2.3, 16.4), (-10.8, 2.1, 13.4)]
    LOW = (-3.6, 1.5, 12.6)
    m.box("WShoulder_L", size=(2.2, 2.4, 2.4), at=WR, role="scale_dark", chamfer=0.6, **MR14)
    m.beam("WArm_L", start=WR, end=WEL, role="scale", width=1.35, depth=1.45, chamfer=0.3, taper=0.85, **MR14)
    m.beam("WFore_L", start=WEL, end=WW, role="scale", width=1.15, depth=1.25, chamfer=0.25, taper=0.85, **MR14)
    m.box("WWrist_L", size=(1.3, 1.3, 1.3), at=WW, role="slate", chamfer=0.3, **MR14)
    m.prism("WThumb_L", radius=0.34, height=1.2, at=add14(WW, (0.05, 0, 0.55)), role="horn", sides=4, taper=0, rot=(0, -15, 0), **MR14)
    for i, t in enumerate(F):
        m.beam(f"WFinger{i}_L", start=WW, end=t, role="scale_dark", width=0.55 - 0.05 * i, depth=0.62 - 0.05 * i, taper=0.5, chamfer=0.08, **MR14)
        m.prism(f"WTip{i}_L", radius=0.2, height=0.7, at=t, role="horn", sides=4, taper=0,
                rot=(0, math.degrees(math.atan2(t[0] - WW[0], t[2] - WW[2])), 0), **MR14)
    # membranes : turquoise pale vers le bout, brume plus claire vers le corps
    yM = 2.05
    P = [(F[0][0], yM, F[0][2]), (F[1][0], yM, F[1][2]), (F[2][0], yM, F[2][2]), (LOW[0], yM, LOW[2])]
    W2 = (WW[0], yM, WW[2])
    panel7(m, "Memb0_L", W2, P[0], P[1], "memb", **MR14)
    panel7(m, "Memb1_L", W2, P[1], P[2], "memb", **MR14)
    panel7(m, "Memb2_L", W2, P[2], P[3], "memb_light", **MR14)
    panel7(m, "Memb3_L", (WEL[0], yM, WEL[2]), P[3], (WR[0] - 0.6, yM, WR[2] + 0.2), "memb_light", **MR14)
    # lambeaux qui pendent du bord de fuite
    for j, (a, b, role) in enumerate(((P[0], P[1], "memb"), (P[1], P[2], "memb"), (P[2], P[3], "memb_light"))):
        for k, (t, L, w) in enumerate(((0.22, 1.5 + 0.6 * (j % 2), 1.4), (0.52, 2.9 - 0.5 * j, 1.7), (0.8, 1.2 + 0.4 * j, 1.2))):
            base = mid14(a, b, t)
            out = norm14(sub14(base, W2))
            tatter7(m, f"Tat{j}{k}_L", add14(base, out, -0.35), out, L + 0.35, w, role if k != 1 else ("flame" if j < 2 else "memb"), **MR14)
    # ---- queue (rig Tail) : s'affine, passe du bleu nuit au turquoise, finit en volute de brume lumineuse
    TP = [(0, 2.4, 7.0), (0, 4.4, 4.6), (0.6, 6.6, 2.6), (2.2, 8.5, 1.5), (4.5, 9.3, 1.25), (6.6, 8.9, 1.3)]
    curve14(m, "Tail", TP, [3.0, 2.5, 2.1, 1.75, 1.45, 1.2], [2.9, 2.4, 2.0, 1.65, 1.35, 1.1],
            ["scale", "scale", "scale", "slate", "flame_dark"], ext=0.3, chamf=0.25, solo=True)
    for k in range(4):
        a, b = TP[k], TP[k + 1]
        c = mid14(a, b)
        d = norm14(sub14(b, a))
        hw = (3.0, 2.5, 2.1, 1.75)[k] * 0.45
        m.beam(f"TailFrill{k}", start=add14(c, (0, 0, hw - 0.3)), end=add14(add14(c, d, 1.2), (0, 0, hw + 1.1)),
               role="flame" if k % 2 == 0 else "flame_dark", width=0.4, depth=1.2 - 0.1 * k, taper=0.08, solo=True)
    cx, cy, cz = 8.9, 8.6, 3.5
    spiral = []
    for i in range(9):
        t = i / 8
        ang = math.radians(-95 + 380 * t)
        r = 2.4 * (1 - 0.7 * t)
        spiral.append((cx + r * math.cos(ang), cy, cz + r * math.sin(ang)))
    curve14(m, "Volute", [TP[-1]] + spiral, [1.2, 1.15, 1.1, 1.0, 0.92, 0.84, 0.75, 0.66, 0.56, 0.45],
            [1.1, 1.05, 1.0, 0.92, 0.84, 0.76, 0.68, 0.6, 0.5, 0.4], ["flame", "flame", "memb_light", "flame"], ext=0.12, chamf=0.1, solo=True)
    m.box("VoluteCore", size=(0.9, 0.9, 0.9), at=spiral[-1], role="glow", rot=(0, 45, 0), solo=True)
    # ---- peinture : ecailles sur les flancs et les cuisses, lignes des plaques
    for n in ("Torso", "Hips"):
        for f in ("side1", "side7"):
            pass
    return m


HEAD7 = ("Skull", "Snout", "SnoutPlate", "MouthIn", "Nostril_", "Iris_", "Pupil_", "Shine_", "Shine2_", "Brow_", "Horn_", "HornRing_",
         "LChain_", "LCap_", "LGlass_", "LBar", "LBase_", "HeadFrill", "Jaw")
HB7, HK7 = (0, -1.9, 18.3), 1.38          # tete agrandie de HK7 autour de la base du crane (le cou ne bouge pas)


def grow_head7(col_name):
    from mathutils import Matrix, Vector
    M = Matrix.Translation(Vector(HB7)) @ Matrix.Scale(HK7, 4) @ Matrix.Translation(-Vector(HB7))
    bpy.context.view_layer.update()      # sinon matrix_world peut etre perime juste apres build()
    for o in bpy.data.collections[col_name].all_objects:
        part = o.get("ropilot_part") or o.name
        if o.type == "MESH" and part.startswith(HEAD7):
            mw = M @ o.matrix_world
            o.matrix_world = mw
            o.data.transform(o.matrix_basis)
            o.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()


Y7 = ropilot.model("R14_T7", px=8, reset=True)
Y7.reference(REF14_7)
Y7.palette(**PAL14_7)
build_t7(Y7)
print(Y7.build())
grow_head7("R14_T7")
print(Y7.compare(image=False)["report"])

ground_r14("R14_T7")
close_gaps_r14("R14_T7")
bpy.context.view_layer.update()
print(ropilot.check_model(collection="R14_T7", max_lines=8))
print("glow", glow_share_r14("R14_T7"))
save_only_r14("R14_T7", "R14_T7.blend")

# --- rig : exec(rigjoin.py), rig_join("R14_T7", GROUPS_T7), save_only_r14("R14_T7", "R14_T7_rig.blend"), import -> Work_R14_T7c,
# CreatureRig.Install(workspace.Work_R14_T7c, "R14_T7", nil, true)
def wing7(s): return [f"WShoulder_{s}", f"WArm_{s}", f"WFore_{s}", f"WWrist_{s}", f"WThumb_{s}", f"WFinger*_{s}", f"WTip*_{s}", f"Memb*_{s}", f"Tat*_{s}"]
def leg7(s): return [f"Thigh_{s}", f"Knee_{s}", f"Shin_{s}", f"Foot_{s}", f"Toe*_{s}", f"Claw*_{s}"]
GROUPS_T7 = {'Head': ['Skull', 'Snout', 'SnoutPlate', 'MouthIn', 'Nostril_*', 'Iris_*', 'Pupil_*', 'Shine_*', 'Shine2_*', 'Brow_*',
                      'Horn_*', 'HornRing_*', 'LChain_*', 'LCap_*', 'LGlass_*', 'LBar*', 'LBase_*', 'HeadFrill*'],
             'Jaw': ['Jaw'],
             'WingL': wing7('L'), 'WingR': wing7('R'), 'LegL': leg7('L'), 'LegR': leg7('R'),
             'Tail': ['Tail?', 'TailFrill*', 'Volute*']}
# joints corriges dans le repere du Core : Head (0, 18.4, -1.9) a la base du crane (Install : 19.29 / -1.02), Jaw (0, 18.1, -3.2) a la
# charniere (Install -4.52), WingL/R (+-3.0, 14.8, 1.0) a l'epaule (Install +-2.67 / 17.42), LegL/R (+-2.6, 8.5, 0.8) a la hanche
# (Install 8.25 / -1.35), Tail (0, 6.9, 2.6) a la racine (Install 7.45 / 0.83)
# Lanternes au bout des cornes (dans Head) : elles suivent la tete.
# compare() final : face 0.62, dos 0.62, gauche 0.63, dessus 0.29 : la reference tient les lanternes aux poignets, a des ailes plus
# basses et une queue enroulee pres des pieds ; ici lanternes aux cornes (demande), ailes levees plus grandes (envergure 34.4),
# tete agrandie de 1.38, queue qui part loin derriere vers la droite (vue de dessus tres differente).
# 155 pieces kit, 12 pieces Studio (+ Core), hauteur 24.68, neon 1.9 % de la surface
# Portrait : rbxassetid://128885510147851
# Orange lumineux : importe en #ff8a1e (le Neon de Studio le rendait jaune), recolore dans Studio en (232, 95, 26) ; palette mise a jour (#e85f1a).
