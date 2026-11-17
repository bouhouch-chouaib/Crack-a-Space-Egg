# Phantom Stallion (R14_T5, Legendary) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R14_Refs/Ref_R14_T5_*.png)
# Fier cheval fantome debout sur quatre pattes : robe bleu nuit (raie de dos plus sombre), ventre, gorge et museau
# ardoise, liste creme ; corps arrondi en prismes a 8 pans ; grands yeux turquoise separes a reflets sur l'avant
# du crane ; oreilles pointues a interieur turquoise (rig EarL / EarR) ; machoire (rig Jaw) ; criniere de flammes
# spectrales turquoise en lames qui ondulent le long du cou, coeurs lumineux, toupet de flamme (suit la tete) ;
# queue de flammes en S avec langues qui s'echappent et coeur lumineux (rig Tail) ; fanons de flamme turquoise,
# sabots creme a liseré lumineux ; collier de cuir orange sombre et lanterne de fer a verre orange lumineux
# au poitrail.
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
REF14_5 = {v: os.path.join(R14R, f"Ref_R14_T5_{v}.png") for v in ("front", "left", "back", "top")}
PAL14_5 = dict(
    coat=dict(color="#34475f", noise=0.035, shade=0.16, mottle=("#2e4058", 0.25, 4), top=0.14),
    coat_dark=dict(color="#1e2a3a", noise=0.03, shade=0.12, top=0.1),
    slate=dict(color="#4a5868", noise=0.03, shade=0.14, top=0.12),
    slate_light=dict(color="#6a7a8c", noise=0.025, shade=0.12, top=0.12),
    flame=dict(color="#6ef0dc", noise=0.03, shade=0.12, top=0.15, streaks=("#9ff8ea", 0.25, "v")),
    flame_dark=dict(color="#2fa79a", noise=0.03, shade=0.12, top=0.12, streaks=("#3cbcae", 0.25, "v")),
    mist=dict(color="#ddeff0", noise=0.02, shade=0.12, top=0.1),
    cream=dict(color="#f6e9c8", noise=0.02, shade=0.12, top=0.12),
    iron=dict(color="#2a2a32", noise=0.025, shade=0.12, top=0.15),
    leather=dict(color="#b8561c", noise=0.03, shade=0.12, top=0.1),
    pumpkin=dict(color="#f2862e", noise=0.03, shade=0.12, top=0.12),
    mouth="#1a1424", white="#ffffff", iris="#3cd6c2", eye="#101826", shine="#ffffff",
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


def blade14(m, name, base, off1, off2, w, d, roles, **kw):
    # langue de flamme plate (fine en x, large dans le plan y-z) : deux segments, le second se couche (ondulation)
    p1 = add14(base, off1)
    p2 = add14(p1, off2)
    m.beam(name + "a", start=base, end=add14(p1, norm14(off1), 0.2), role=roles[0], width=w, depth=d, taper=0.82, chamfer=0.08, **kw)
    m.beam(name + "b", start=add14(p1, norm14(off2), -0.3), end=p2, role=roles[1], width=w * 0.85, depth=d * 0.8, taper=0.1, **kw)


def fire14(m, name, base, h, L, w, lean, roles, core=None, side=0.0, **kw):
    # flamme de dessin anime : deux blocs plats (fins en x) qui montent depuis `base`, s'affinent en pointe dans le plan y-z
    # et se couchent vers l'arriere (+Y) par cisaillement ; coeur lumineux facultatif
    h1, h2 = h * 0.5, h * 0.62
    s1, s2 = lean * 0.35, lean * 0.9
    c1 = (base[0], base[1], base[2] + h1 / 2)
    m.box(name + "a", size=(w, L, h1), at=c1, role=roles[0], taper=(0.85, 0.72), shear=(side * 0.3, s1), **kw)
    t1 = (base[0] + side * 0.3, base[1] + s1, base[2] + h1)
    c2 = (t1[0], t1[1], t1[2] + h2 / 2 - 0.12)
    m.box(name + "b", size=(w * 0.85, L * 0.72, h2), at=c2, role=roles[1], taper=(0.55, 0.04), shear=(side * 0.5, s2), **kw)
    if core:
        m.box(name + "c", size=(w + 0.06, L * 0.32, h * 0.5), at=(base[0], base[1] + s1 * 0.6, base[2] + h * 0.42), role=core,
              taper=(0.9, 0.3), shear=(0, s1 * 0.8), **kw)


def lock14(m, name, base, s, roles, w=0.66, d=1.15, up=1.0, **kw):
    # meche de flamme couchee : monte, file vers l'arriere en ondulant, pointe relevee (lumineuse)
    p1 = add14(base, (0, 0.75 * s, 0.85 * s * up))
    p2 = add14(p1, (0, 1.35 * s, -0.25 * s))
    p3 = add14(p2, (0, 0.75 * s, 0.55 * s))
    curve14(m, name, [base, p1, p2, p3], [w, w * 0.92, w * 0.72, 0.06], [d, d * 0.9, d * 0.62, 0.08], roles, ext=0.18, chamf=0.12, **kw)


def build_t5(m):
    # ---- corps arrondi : prismes a 8 pans couches le long du corps, poitrail et croupe qui s'arrondissent
    m.prism("Chest", radius=1.9, height=2.6, at=(0, -2.75, 6.65), role="coat", sides=8, turn=22.5, taper=0.72, rot=(90, 0, 0))
    m.prism("Barrel", radius=1.75, height=3.6, at=(0, -0.4, 6.4), role="coat", sides=8, turn=22.5, rot=(90, 0, 0))
    m.prism("Rump", radius=1.95, height=2.6, at=(0, 1.9, 6.7), role="coat", sides=8, turn=22.5, taper=0.7, rot=(-90, 0, 0))
    m.box("Belly", size=(2.0, 4.6, 0.5), at=(0, -0.4, 4.85), role="slate", chamfer=0.2)
    m.box("BackStripe", size=(1.3, 5.2, 0.35), at=(0, -0.1, 8.0), role="coat_dark", chamfer=0.12)
    # ---- cou, gorge, collier
    m.beam("Neck", start=(0, -2.7, 7.2), end=(0, -4.35, 10.5), role="coat", width=2.0, depth=2.6, chamfer=0.7, taper=0.82)
    m.beam("Throat", start=(0, -3.8, 7.0), end=(0, -5.15, 9.7), role="slate", width=1.6, depth=1.4, chamfer=0.45, taper=0.85)
    m.box("Collar", size=(2.25, 3.15, 0.6), at=(0, -3.45, 8.35), role="leather", chamfer=0.1, rot=(26.6, 0, 0))
    m.box("Buckle", size=(0.8, 0.4, 0.62), at=(0, -4.95, 7.75), role="iron", chamfer=0.08, rot=(26.6, 0, 0))
    # ---- tete (rig Head) : crane, long museau ardoise incline, liste creme, yeux sur l'avant du crane
    m.box("Skull", size=(2.3, 2.4, 2.3), at=(0, -4.85, 11.0), role="coat", chamfer=0.65)
    m.box("Muzzle", size=(1.75, 2.6, 1.5), at=(0, -6.25, 9.95), role="slate", chamfer=0.45, axis="y", taper=(0.85, 0.82), rot=(40, 0, 0))
    m.box("Blaze", size=(0.55, 1.9, 0.2), at=(0, -5.85, 10.95), role="cream", chamfer=0.05, axis="y", taper=(0.55, 1), rot=(40, 0, 0))
    m.box("MouthIn", size=(1.45, 1.8, 0.3), at=(0, -5.95, 9.3), role="mouth", rot=(40, 0, 0))
    # yeux sur les aretes avant du crane, tournes vers l'exterieur (vus de face et de profil), bien separes par la liste
    ea = math.radians(-45)              # pose a plat sur le chanfrein avant du crane
    nx, ny = math.sin(ea), -math.cos(ea)          # normale de la face avant de l'oeil tourne
    tx, ty = math.cos(ea), math.sin(ea)           # direction u (vers le nez)
    E0 = (-0.81, -5.71, 11.45)

    def on_eye(du, dv, out):
        return (E0[0] + nx * out + tx * du, E0[1] + ny * out + ty * du, E0[2] + dv)
    m.box("Eye_L", size=(0.72, 0.24, 0.88), at=E0, role="iris", chamfer=0.08, rot=(0, 0, -45), **MR14)
    m.box("Pupil_L", size=(0.36, 0.08, 0.52), at=on_eye(0.06, -0.03, 0.13), role="eye", rot=(0, 0, -45), **MR14)
    m.box("Shine_L", size=(0.22, 0.06, 0.22), at=on_eye(-0.1, 0.18, 0.15), role="shine", rot=(0, 0, -45), **MR14)
    m.box("Shine2_L", size=(0.11, 0.06, 0.11), at=on_eye(0.16, -0.24, 0.15), role="shine", rot=(0, 0, -45), **MR14)
    m.beam("Brow_L", start=(-1.25, -5.85, 12.0), end=(-0.7, -6.08, 12.08), role="coat_dark", width=0.2, depth=0.22, chamfer=0.04, **MR14)
    m.box("BlazeTop", size=(0.5, 0.2, 1.2), at=(0, -6.08, 11.55), role="cream", taper=(0.7, 1))
    # oreilles (rig EarL / EarR) : pointues, interieur turquoise
    m.box("Ear_L", size=(0.7, 0.6, 1.5), at=(-0.85, -4.45, 12.7), role="coat", chamfer=0.12, taper=(0.35, 0.5), rot=(0, -20, 0), **MR14)
    m.box("EarIn_L", size=(0.38, 0.12, 1.0), at=(-0.84, -4.76, 12.62), role="flame_dark", taper=(0.35, 1), rot=(0, -20, 0), **MR14)
    # machoire (rig Jaw)
    m.box("Jaw", size=(1.5, 2.1, 0.5), at=(0, -5.8, 9.0), role="slate", chamfer=0.12, axis="y", taper=(0.85, 0.85), rot=(40, 0, 0),
          faces={"top": "mouth"})
    # ---- criniere : meches de flamme turquoise couchees qui ondulent vers l'arriere le long du cou (sombre a la base,
    # claire au milieu, pointe lumineuse relevee) ; toupet (suit la tete)
    lock14(m, "Forelock", (0, -5.15, 11.95), -0.55, ["flame_dark", "flame", "glow"], w=0.6, d=0.9, up=-1.3)
    RIDGE = [(0, -4.4, 12.15), (0, -3.75, 11.0), (0, -3.15, 9.75), (0, -2.55, 8.75), (0, -1.8, 8.3)]
    curve14(m, "ManeRidge", RIDGE, [0.8, 0.85, 0.85, 0.75, 0.55], [1.1, 1.2, 1.2, 1.0, 0.7], ["flame_dark"], solo=True)
    for k in range(6):
        t = k / 5
        i = min(int(t * 4), 3)
        a = mid14(RIDGE[i], RIDGE[i + 1], t * 4 - i)
        sc = 1.05 - 0.3 * t
        lock14(m, f"Mane{k}", add14(a, (0.12 if k % 2 else -0.12, 0.0, 0.1)), sc,
               ["flame_dark", "flame", "glow"] if k in (2, 4) else ["flame", "flame", "flame"] if k % 2 else ["flame_dark", "flame", "flame"],
               solo=True)
    # ---- pattes (rig LegFL/FR/BL/BR) : avant-bras / cuisse qui s'affinent, canon, fanons de flamme, sabot creme lumineux
    m.beam("FArm_L", start=(-1.25, -2.9, 6.3), end=(-1.35, -3.05, 3.0), role="coat", width=1.55, depth=1.85, chamfer=0.45, taper=0.68, **MR14)
    m.beam("FCannon_L", start=(-1.35, -3.05, 3.25), end=(-1.4, -3.2, 1.0), role="coat", width=1.05, depth=1.15, chamfer=0.25, taper=0.95, **MR14)
    m.beam("Thigh_L", start=(-1.25, 1.6, 7.2), end=(-1.35, 2.25, 3.4), role="coat", width=1.8, depth=2.6, chamfer=0.5, taper=0.5, **MR14)
    m.beam("BCannon_L", start=(-1.35, 2.25, 3.65), end=(-1.4, 1.65, 1.0), role="coat", width=1.05, depth=1.15, chamfer=0.25, taper=0.95, **MR14)
    for nm, yy in (("F", -3.2), ("B", 1.65)):
        m.box(f"{nm}Feather_L", size=(1.4, 1.5, 0.95), at=(-1.4, yy + 0.1, 1.32), role="flame_dark", chamfer=0.25, taper=(0.7, 0.7), **MR14)
        m.box(f"{nm}Hoof_L", size=(1.6, 1.75, 1.0), at=(-1.4, yy - 0.08, 0.5), role="cream", chamfer=0.22, taper=(0.9, 0.9), **MR14)
        m.box(f"{nm}HoofGlow_L", size=(1.46, 1.6, 0.12), at=(-1.4, yy - 0.08, 0.98), role="glow", **MR14)
    # ---- queue de flammes (rig Tail) : grande meche en S qui s'evase, deux meches qui s'en echappent, pointes et coeur lumineux
    TP = [(0, 3.2, 7.9), (0, 4.1, 8.6), (0, 5.0, 7.6), (0, 5.35, 5.3), (0, 4.8, 3.2)]
    curve14(m, "Tail", TP, [0.85, 1.1, 1.15, 0.9, 0.08], [1.2, 1.7, 1.9, 1.5, 0.15], ["flame"], ext=0.3, chamf=0.18, solo=True)
    lock14(m, "TailF0", mid14(TP[1], TP[2], 0.5), 0.8, ["flame_dark", "flame", "glow"], w=0.62, d=1.1, up=0.8, solo=True)
    lock14(m, "TailF1", add14(mid14(TP[2], TP[3], 0.6), (0, 0.45, 0)), 0.7, ["flame_dark", "flame", "glow"], w=0.6, d=1.0, up=-0.2, solo=True)
    m.box("TailTip", size=(0.42, 0.75, 1.0), at=add14(TP[-1], (0, 0.05, 0.3)), role="glow", taper=(0.4, 0.1), rot=(180, 0, 0), solo=True)
    m.beam("TailCore", start=mid14(TP[1], TP[2], 0.6), end=mid14(TP[2], TP[3], 0.8), role="flame_dark", width=1.2, depth=0.9, taper=0.7, solo=True)
    # ---- lanterne au poitrail : chaine, chapeau, cage de fer, verre orange lumineux
    m.beam("Chain", start=(0, -4.95, 7.6), end=(0, -4.95, 6.85), role="iron", width=0.16, depth=0.16)
    m.box("LanternCap", size=(1.15, 1.15, 0.4), at=(0, -4.95, 6.75), role="iron", chamfer=0.1, taper=(0.55, 0.55))
    m.box("LanternGlass", size=(0.82, 0.82, 1.05), at=(0, -4.95, 6.0), role="glow_orange")
    for k, (dx, dy) in enumerate(((-0.45, -0.45), (0.45, -0.45), (-0.45, 0.45), (0.45, 0.45))):
        m.box(f"LanternBar{k}", size=(0.17, 0.17, 1.1), at=(dx, -4.95 + dy, 6.0), role="iron", solo=True)
    m.box("LanternBase", size=(1.05, 1.05, 0.28), at=(0, -4.95, 5.4), role="iron", chamfer=0.06)
    # ---- naseaux (petits blocs, pas de peinture hors des faces plates des chanfreins : le kit boucle)
    m.box("Nostril_L", size=(0.3, 0.2, 0.22), at=(-0.4, -7.5, 9.36), role="coat_dark", rot=(40, 0, 0), **MR14)
    return m


S5 = ropilot.model("R14_T5", px=8, reset=True)
S5.reference(REF14_5)
S5.palette(**PAL14_5)
build_t5(S5)
print(S5.build()); print(S5.check()); print(S5.compare(image=False)["report"])


ground_r14("R14_T5")
close_gaps_r14("R14_T5")
_o = bpy.data.objects.get("Mane31")
if _o:
    # meche coincee entre deux voisines : un rien plus grosse pour les toucher toutes les deux
    _o.location.z -= 0.03
    _o.scale = (1.08, 1.08, 1.08)
bpy.context.view_layer.update()
print(ropilot.check_model(collection="R14_T5", max_lines=3))
print("glow", glow_share_r14("R14_T5"))
save_only_r14("R14_T5", "R14_T5.blend")

# --- rig : exec(rigjoin.py), rig_join("R14_T5", GROUPS_T5), save_only_r14("R14_T5", "R14_T5_rig.blend"), import -> Work_R14_T5c,
# CreatureRig.Install(workspace.Work_R14_T5c, "R14_T5", nil, true)
GROUPS_T5 = {'Head': ['Skull', 'Muzzle', 'Blaze', 'BlazeTop', 'MouthIn', 'Nostril_*', 'Eye_*', 'Pupil_*', 'Shine_*', 'Shine2_*', 'Brow_*', 'Forelock*'],
             'Jaw': ['Jaw'],
             'EarL': ['Ear_L', 'EarIn_L'], 'EarR': ['Ear_R', 'EarIn_R'],
             'LegFL': ['FArm_L', 'FCannon_L', 'FFeather_L', 'FHoof_L', 'FHoofGlow_L'],
             'LegFR': ['FArm_R', 'FCannon_R', 'FFeather_R', 'FHoof_R', 'FHoofGlow_R'],
             'LegBL': ['Thigh_L', 'BCannon_L', 'BFeather_L', 'BHoof_L', 'BHoofGlow_L'],
             'LegBR': ['Thigh_R', 'BCannon_R', 'BFeather_R', 'BHoof_R', 'BHoofGlow_R'],
             'Tail': ['Tail?', 'TailF*', 'TailTip', 'TailCore']}
# joints corriges dans le repere du Core : Head (0, 10.3, -4.1) en haut du cou (Install : 9.51 / -4.75), Jaw (0, 9.7, -5.0) a la charniere,
# EarL/R (+-0.85, 11.95, -4.45) a la base (Install les mettait de travers, x 0.33 / -0.16), LegFL/FR (+-1.25, 6.2, -2.95) a l'epaule
# (Install 5.82), LegBL/BR (+-1.25, 7.0, 1.7) a la hanche, Tail (0, 7.9, 3.1) a la racine (Install 8.39 / 2.81)
# compare() final : face 0.78, dos 0.78, gauche 0.71, dessus 0.81 : la reference est un cheval fin a museau court ; ici tete plus grosse
# (yeux visibles de face), criniere en meches de flamme plus volumineuse, queue plus proche de la croupe.
# 96 pieces kit, 18 pieces Studio (+ Core), hauteur 13.67, neon 4.9 % de la surface
# Portrait : rbxassetid://120495110930838
# Orange lumineux : importe en #ff8a1e (le Neon de Studio le rendait jaune), recolore dans Studio en (232, 95, 26) ; palette mise a jour (#e85f1a).
