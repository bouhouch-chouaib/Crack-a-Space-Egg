# Spirit Wolf (R14_T6, Mythic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R14_Refs/Ref_R14_T6_*.png)
# Grand loup esprit massif : corps arrondi en prismes a 8 pans, fourrure brume pale, cape de dos bleu nuit a meches
# le long de l'echine ; grosse collerette de fourrure pale sur le poitrail ; tete a masque bleu nuit, museau pale,
# truffe sombre, joues en touffes pales, grands yeux orange lanterne lumineux separes a reflets sous des sourcils
# fiers, oreilles dressees a interieur turquoise (rig EarL / EarR), machoire (rig Jaw) ; volutes de brume turquoise
# en spirale sur les epaules (coeur lumineux) ; collier de cuir orange sombre a lanterne de fer lumineuse ;
# pattes puissantes pales, chaussettes ardoise, griffes creme ; grande queue touffue relevee, bleu nuit puis
# ardoise, bout en volute de brume turquoise lumineuse (rig Tail).
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
REF14_6 = {v: os.path.join(R14R, f"Ref_R14_T6_{v}.png") for v in ("front", "left", "back", "top")}
PAL14_6 = dict(
    fur=dict(color="#ddeff0", noise=0.03, shade=0.16, mottle=("#cfe4e7", 0.25, 4), top=0.1, streaks=("#eef8f8", 0.2, "v")),
    fur_dark=dict(color="#b4cad1", noise=0.03, shade=0.14, streaks=("#c6dade", 0.2, "v")),
    coat=dict(color="#2e3f58", noise=0.035, shade=0.16, mottle=("#283850", 0.25, 4), top=0.14, streaks=("#3a4d68", 0.2, "v")),
    coat_dark=dict(color="#1e2a3a", noise=0.03, shade=0.12, top=0.1),
    slate=dict(color="#4a5868", noise=0.03, shade=0.14, top=0.12),
    flame=dict(color="#6ef0dc", noise=0.03, shade=0.12, top=0.15, streaks=("#9ff8ea", 0.25, "v")),
    flame_dark=dict(color="#2fa79a", noise=0.03, shade=0.12, top=0.12),
    cream=dict(color="#f6e9c8", noise=0.02, shade=0.12, top=0.12),
    iron=dict(color="#2a2a32", noise=0.025, shade=0.12, top=0.15),
    leather=dict(color="#b8561c", noise=0.03, shade=0.12, top=0.1),
    pumpkin=dict(color="#f2862e", noise=0.03, shade=0.12, top=0.12),
    nose="#141a24", mouth="#2a1a2a", eye="#1a1010", shine="#ffffff", tongue="#d8687a",
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


def swirl14(m, name, c, r0, x, turns=1.25, n=9, a0=90.0, roles=("flame",), w=0.3, d=0.42, core=True, **kw):
    # volute de brume : spirale qui s'enroule vers son centre, posee a plat sur un flanc (plan y-z, en x)
    pts = []
    for i in range(n + 1):
        t = i / n
        a = math.radians(a0 + 360 * turns * t)
        r = r0 * (1 - 0.72 * t)
        pts.append((x, c[1] + r * math.cos(a), c[2] + r * math.sin(a)))
    curve14(m, name, pts, [d * (1 - 0.4 * i / n) for i in range(n + 1)], [w] * (n + 1), list(roles), ext=0.1, chamf=0.05, **kw)
    if core:
        m.box(name + "Core" + ("_L" if kw.get("mirror") else ""), size=(w * 0.8, 0.42, 0.42), at=(x, pts[-1][1], pts[-1][2]), role="glow",
              rot=(45, 0, 0), **kw)
    return pts


HK6, HC6, HO6 = 1.22, (0, -5.8, 11.6), (0, 0.35, -0.2)    # tete agrandie de HK6 autour de HC6, puis decalee de HO6


def HP6(x, y, z):
    return tuple(HC6[i] + ((x, y, z)[i] - HC6[i]) * HK6 + HO6[i] for i in range(3))


def HS6(*v):
    return tuple(c * HK6 for c in v)


def wisp14(m, name, base, s, roles, w=0.55, d=0.8, up=1.0, **kw):
    # meche de brume : monte, file vers l'arriere en ondulant, pointe relevee
    p1 = add14(base, (0, 0.55 * s, 1.0 * s * up))
    p2 = add14(p1, (0, 1.3 * s, 0.1 * s))
    p3 = add14(p2, (0, 0.8 * s, 0.7 * s))
    curve14(m, name, [base, p1, p2, p3], [w, w * 0.9, w * 0.7, 0.06], [d, d * 0.9, d * 0.65, 0.08], roles, ext=0.18, chamf=0.12, **kw)


def build_t6(m):
    # ---- corps massif arrondi : poitrail, tonneau, croupe (prismes a 8 pans) ; cape bleu nuit sur le dos
    m.prism("Chest", radius=2.95, height=3.6, at=(0, -2.5, 7.7), role="fur", sides=8, turn=22.5, taper=0.8, rot=(90, 0, 0))
    m.prism("Barrel", radius=2.7, height=3.4, at=(0, 0.6, 7.45), role="fur", sides=8, turn=22.5, rot=(90, 0, 0))
    m.prism("Rump", radius=2.75, height=2.8, at=(0, 3.4, 7.55), role="fur", sides=8, turn=22.5, taper=0.76, rot=(-90, 0, 0))
    m.box("Saddle", size=(5.3, 8.4, 2.3), at=(0, 0.6, 9.65), role="coat", chamfer=0.9, faces={"bottom": "coat_dark"})
    m.box("SaddleEdge_L", size=(0.5, 7.6, 1.3), at=(-2.55, 0.6, 8.55), role="coat", chamfer=0.2, taper=(1.0, 0.85), **MR14)
    for k, y in enumerate((-2.6, -1.2, 0.2, 1.6, 3.0, 4.2)):
        m.beam(f"Spine{k}", start=(0, y - 0.75, 10.45), end=(0, y + 1.0, 11.05 - 0.05 * k), role="coat" if k % 2 else "coat_dark", width=1.8 - 0.08 * k,
               depth=0.9, taper=0.45, chamfer=0.15, solo=True)
    # ---- collerette de fourrure pale sur le poitrail et le cou
    m.beam("Neck", start=(0, -3.2, 8.6), end=(0, -5.0, 11.2), role="fur", width=3.4, depth=3.0, chamfer=0.9, taper=0.85)
    for k, x in enumerate((-2.0, -1.0, 0.0, 1.0, 2.0)):
        m.beam(f"Ruff{k}", start=(x * 0.95, -5.0 + 0.15 * abs(x), 10.2), end=(x * 1.12, -5.2 + 0.25 * abs(x), 6.9 + 0.25 * abs(x)),
               role="fur" if k % 2 == 0 else "fur_dark", width=1.45, depth=1.1, taper=0.35, chamfer=0.12, solo=True)
    for s in (-1, 1):
        for k, (y, z) in enumerate(((-3.6, 10.4), (-2.6, 9.6))):
            m.beam(f"RuffS{k}{'L' if s < 0 else 'R'}", start=(2.2 * s, y, z), end=(3.0 * s, y + 0.4, z - 2.1), role="fur" if k else "fur_dark",
                   width=1.3, depth=1.5, taper=0.35, chamfer=0.12, solo=True)
    # ---- tete (rig Head), agrandie de HK6 autour de HC6 : crane bleu nuit, front pale, museau pale, truffe, joues en
    # touffes, grands yeux orange lumineux a reflets ; oreilles (rig EarL / EarR) ; machoire (rig Jaw)
    m.box("Skull", size=HS6(3.9, 3.3, 3.2), at=HP6(0, -5.6, 12.5), role="coat", chamfer=0.85 * HK6, faces={"front": "fur", "bottom": "fur"})
    m.box("Mask", size=HS6(1.1, 0.3, 1.5), at=HP6(0, -7.24, 13.3), role="coat", chamfer=0.1, taper=(0.4, 1))
    m.box("Snout", size=HS6(2.3, 3.0, 1.75), at=HP6(0, -8.1, 11.55), role="fur", chamfer=0.45 * HK6, axis="y", taper=(0.78, 0.8),
          faces={"top": "fur_dark"})
    m.box("SnoutTop", size=HS6(1.3, 2.6, 0.35), at=HP6(0, -7.9, 12.45), role="coat", chamfer=0.1, axis="y", taper=(0.6, 1))
    m.box("Nose", size=HS6(1.0, 0.6, 0.72), at=HP6(0, -9.55, 12.05), role="nose", chamfer=0.15, taper=(0.8, 0.8))
    m.box("MouthIn", size=HS6(1.7, 2.4, 0.3), at=HP6(0, -7.9, 10.65), role="mouth")
    m.box("Eye_L", size=HS6(1.0, 0.2, 0.8), at=HP6(-1.0, -7.2, 12.8), role="glow_orange", chamfer=0.06, rot=(0, -14, 0), **MR14)
    m.box("Pupil_L", size=HS6(0.3, 0.08, 0.6), at=HP6(-0.94, -7.32, 12.78), role="eye", rot=(0, -14, 0), **MR14)
    m.box("Shine_L", size=HS6(0.24, 0.06, 0.24), at=HP6(-1.22, -7.36, 13.0), role="shine", rot=(0, -14, 0), **MR14)
    m.box("Shine2_L", size=HS6(0.12, 0.06, 0.12), at=HP6(-0.74, -7.36, 12.58), role="shine", rot=(0, -14, 0), **MR14)
    m.beam("Brow_L", start=HP6(-1.65, -7.2, 13.4), end=HP6(-0.7, -7.26, 13.5), role="coat_dark", width=0.26 * HK6, depth=0.28, chamfer=0.05, **MR14)
    for k, (z, L) in enumerate(((11.95, 1.6), (11.3, 1.35))):
        m.beam(f"Cheek{k}_L", start=HP6(-1.5, -6.2, z), end=HP6(-1.5 - L, -5.4, z - 0.9), role="fur" if k else "fur_dark", width=1.2 * HK6,
               depth=1.0, taper=0.3, chamfer=0.1, **MR14)
    m.box("Ear_L", size=HS6(1.3, 0.85, 2.3), at=HP6(-1.4, -5.0, 14.8), role="coat", chamfer=0.15, taper=(0.25, 0.4), rot=(0, -10, 0), **MR14)
    m.box("EarIn_L", size=HS6(0.75, 0.14, 1.55), at=HP6(-1.38, -5.45, 14.65), role="flame_dark", taper=(0.25, 1), rot=(0, -10, 0), **MR14)
    m.box("Jaw", size=HS6(2.0, 2.7, 0.7), at=HP6(0, -7.75, 10.3), role="fur", chamfer=0.18, axis="y", taper=(0.8, 0.85), faces={"top": "mouth"})
    m.box("Tongue", size=HS6(0.9, 1.6, 0.2), at=HP6(0, -8.0, 10.86), role="tongue", chamfer=0.05)
    # ---- collier de cuir et lanterne de fer au poitrail
    m.prism("Collar", radius=2.15, height=0.65, at=(0, -4.55, 10.45), role="leather", sides=8, turn=22.5, rot=(37, 0, 0))
    m.box("Buckle", size=(0.9, 0.45, 1.0), at=(0, -6.25, 8.95), role="iron", chamfer=0.08, rot=(37, 0, 0))
    m.beam("Chain", start=(0, -6.4, 8.9), end=(0, -6.55, 8.6), role="iron", width=0.2, depth=0.2)
    m.box("LanternCap", size=(1.3, 1.3, 0.45), at=(0, -6.6, 8.45), role="iron", chamfer=0.12, taper=(0.55, 0.55))
    m.box("LanternGlass", size=(0.92, 0.92, 1.15), at=(0, -6.6, 7.65), role="glow_orange")
    for k, (dx, dy) in enumerate(((-0.5, -0.5), (0.5, -0.5), (-0.5, 0.5), (0.5, 0.5))):
        m.box(f"LanternBar{k}", size=(0.2, 0.2, 1.2), at=(dx, -6.6 + dy, 7.65), role="iron", solo=True)
    m.box("LanternBase", size=(1.2, 1.2, 0.3), at=(0, -6.6, 6.98), role="iron", chamfer=0.06)
    # ---- volutes de brume turquoise sur les epaules (spirale epaisse a coeur lumineux, meches qui montent et filent
    # vers l'arriere) et sur les hanches
    swirl14(m, "SwirlS_L", (0, -2.5, 8.3), 1.55, -3.0, turns=1.1, n=7, w=0.4, d=0.7, roles=("flame", "flame_dark"), **MR14)
    for k, (y, z, sc) in enumerate(((-3.0, 9.7, 1.2), (-1.6, 10.0, 1.0))):
        wisp14(m, f"WispS{k}_L", (-2.65 - 0.1 * k, y, z), sc, ["flame_dark", "flame", "glow"] if k == 0 else ["flame", "flame", "flame"],
               w=0.7, d=1.0, **MR14)
    swirl14(m, "SwirlH_L", (0, 3.7, 6.9), 1.0, -3.12, turns=1.0, n=6, a0=60, w=0.36, d=0.6, roles=("flame_dark", "flame"), core=False, **MR14)
    # ---- pattes (rig LegFL/FR/BL/BR) : epaule / cuisse puissante, avant-bras, chaussette ardoise, patte, griffes creme
    m.beam("FArm_L", start=(-2.1, -2.9, 7.4), end=(-2.15, -3.0, 2.6), role="fur", width=2.0, depth=2.35, chamfer=0.55, taper=0.78, **MR14)
    m.beam("FLow_L", start=(-2.15, -3.0, 3.0), end=(-2.15, -3.15, 1.05), role="fur", width=1.65, depth=1.8, chamfer=0.35, taper=0.95, **MR14)
    m.beam("Elbow_L", start=(-2.2, -2.2, 5.6), end=(-2.25, -1.4, 4.3), role="fur_dark", width=1.0, depth=0.9, taper=0.2, chamfer=0.08, **MR14)
    m.beam("Thigh_L", start=(-2.1, 3.5, 8.6), end=(-2.15, 4.5, 3.4), role="fur", width=2.2, depth=3.2, chamfer=0.65, taper=0.55, **MR14)
    m.beam("BLow_L", start=(-2.15, 4.5, 3.8), end=(-2.15, 3.95, 1.05), role="fur", width=1.6, depth=1.8, chamfer=0.35, taper=0.95, **MR14)
    for nm, yy in (("F", -3.25), ("B", 3.85)):
        m.box(f"{nm}Sock_L", size=(1.85, 2.0, 0.85), at=(-2.15, yy + 0.05, 1.25), role="slate", chamfer=0.22, **MR14)
        m.box(f"{nm}Paw_L", size=(2.15, 2.6, 1.0), at=(-2.15, yy - 0.25, 0.5), role="slate", chamfer=0.3, taper=(0.92, 0.85), **MR14)
        for k, dx in enumerate((-0.6, 0.0, 0.6)):
            m.box(f"{nm}Claw{k}_L", size=(0.36, 0.4, 0.32), at=(-2.15 + dx, yy - 1.58, 0.22), role="cream", taper=(0.6, 0.4), **MR14)
    # ---- grande queue touffue relevee (rig Tail) : bleu nuit, ardoise, bout en volute de brume turquoise lumineuse
    TP = [(0, 4.6, 9.3), (0, 6.2, 10.2), (0, 7.6, 11.3), (0, 8.6, 12.5), (0, 8.9, 13.5)]
    curve14(m, "Tail", TP, [2.0, 2.7, 2.6, 1.9, 0.5], [2.1, 2.7, 2.6, 2.0, 0.6], ["coat", "coat", "slate", "flame_dark"], ext=0.3, chamf=0.25,
            solo=True)
    for k, (i, t, s) in enumerate(((1, 0.5, 1), (1, 0.5, -1), (2, 0.4, 1), (2, 0.4, -1))):
        a = mid14(TP[i], TP[i + 1], t)
        m.beam(f"TailTuft{k}", start=add14(a, (0.5 * s, -0.2, 0)), end=add14(a, (1.35 * s, 0.9, -0.3)), role="coat_dark" if i == 1 else "slate",
               width=1.3, depth=1.6, taper=0.4, chamfer=0.15, solo=True)
    tip = TP[-1]
    curve14(m, "TailCurl", [add14(tip, (0, -0.2, -0.3)), add14(tip, (0, 0.9, 0.6)), add14(tip, (0, 1.8, 0.0)), add14(tip, (0, 1.3, -0.9))],
            [1.3, 1.05, 0.75, 0.12], [1.3, 1.05, 0.75, 0.12], ["flame", "flame", "flame"], ext=0.15, chamf=0.1, solo=True)
    m.box("TailGlow", size=(0.85, 0.85, 0.85), at=add14(tip, (0, 0.95, 0.15)), role="glow", rot=(45, 0, 0), solo=True)
    return m


W6 = ropilot.model("R14_T6", px=8, reset=True)
W6.reference(REF14_6)
W6.palette(**PAL14_6)
build_t6(W6)
print(W6.build()); print(W6.check()); print(W6.compare(image=False)["report"])


ground_r14("R14_T6")
close_gaps_r14("R14_T6")
bpy.context.view_layer.update()
print(ropilot.check_model(collection="R14_T6", max_lines=3))
print("glow", glow_share_r14("R14_T6"))
save_only_r14("R14_T6", "R14_T6.blend")

# --- rig : exec(rigjoin.py), rig_join("R14_T6", GROUPS_T6), save_only_r14("R14_T6", "R14_T6_rig.blend"), import -> Work_R14_T6c,
# CreatureRig.Install(workspace.Work_R14_T6c, "R14_T6", nil, true)
def legf6(s): return [f"FArm_{s}", f"FLow_{s}", f"Elbow_{s}", f"FSock_{s}", f"FPaw_{s}", f"FClaw*_{s}"]
def legb6(s): return [f"Thigh_{s}", f"BLow_{s}", f"BSock_{s}", f"BPaw_{s}", f"BClaw*_{s}", f"SwirlH_L*_{s}"]
GROUPS_T6 = {'Head': ['Skull', 'Mask', 'Snout', 'SnoutTop', 'Nose', 'MouthIn', 'Eye_*', 'Pupil_*', 'Shine_*', 'Shine2_*', 'Brow_*', 'Cheek*'],
             'Jaw': ['Jaw', 'Tongue'],
             'EarL': ['Ear_L', 'EarIn_L'], 'EarR': ['Ear_R', 'EarIn_R'],
             'LegFL': legf6('L'), 'LegFR': legf6('R'), 'LegBL': legb6('L'), 'LegBR': legb6('R'),
             'Tail': ['Tail?', 'TailTuft*', 'TailCurl*', 'TailGlow']}
# joints corriges dans le repere du Core : Head (0, 11.0, -4.0) a la base du crane (Install : 10.76 / -5.38, sous le museau),
# Jaw (0, 10.2, -6.2) a la charniere (Install 10.54 / -6.94), EarL/R (+-1.7, 13.95, -4.47) a la base (Install +-0.82 / 15.26),
# LegFL/FR (+-2.1, 7.4, -2.9) a l'epaule (Install 6.83 / -3.61), LegBL/BR (+-2.1, 8.4, 3.6) a la hanche, Tail (0, 9.3, 4.6) a la racine
# Volutes des hanches dans les pattes arriere (elles suivent la cuisse) ; volutes et meches des epaules dans Body.
# compare() final : face 0.86, dos 0.86, gauche 0.66, dessus 0.64 : la reference a une sorte de cape sombre qui pend derriere la
# croupe et une tete basse ; ici tete agrandie et relevee, queue touffue plus longue.
# 140 pieces kit, 14 pieces Studio (+ Core), hauteur 16.71, neon 1.5 % de la surface
# Portrait : rbxassetid://85303059683915
# Orange lumineux : importe en #ff8a1e (le Neon de Studio le rendait jaune), recolore dans Studio en (232, 95, 26) ; palette mise a jour (#e85f1a).
