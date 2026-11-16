# Sun Condor (R13_T7, Cosmic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R13_Refs/Ref_R13_T7b_*.png ;
# la premiere generation Ref_R13_T7 avait les ailes repliees et n'a pas servi)
# Condor colossal en or, en pose heraldique : corps en oeuf d'or a poitrail de plumes plus claires, broche d'or a
# jade lumineuse sur le poitrail, collerette de plumes creme autour du cou ; tete chauve rouge brique a crete,
# bec crochu ivoire a pointe sombre, machoire (rig Jaw), grands yeux de jade separes a reflets sous des sourcils
# fiers ; couronne de soleil d'or a rayons longs et courts derriere la tete, pointes lumineuses (suit la tete) ;
# immenses ailes deployees en V (rig WingL / WingR) : bras d'or, couvertures dorees claires, remiges d'or a bouts
# de jade et longues remiges primaires ecartees en doigts ; queue en eventail a bouts de jade (rig Tail) ;
# pattes (rig LegL / LegR) a culottes de plumes, doigts ecailles et grandes serres creme.
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R13_Refs")
REF7 = {v: os.path.join(R, f"Ref_R13_T7b_{v}.png") for v in ("front", "left", "back", "top")}
PAL7 = dict(
    gold=dict(color="#f2c14e", noise=0.03, shade=0.15, mottle=("#e8b440", 0.25, 4), top=0.15),
    gold_dark=dict(color="#b8862b", noise=0.03, shade=0.13, top=0.12),
    gold_light=dict(color="#ffd97a", noise=0.025, shade=0.1, top=0.12),
    feather=dict(color="#e9b23e", noise=0.03, shade=0.12, top=0.12, streaks=("#d49a2c", 0.25, "v")),
    jade=dict(color="#3fb37f", noise=0.03, shade=0.12, top=0.14),
    jade_dark=dict(color="#1f6e4e", noise=0.03, shade=0.12),
    cream=dict(color="#f4ead0", noise=0.025, shade=0.12, top=0.1, mottle=("#fbf3e2", 0.3, 3)),
    cream_dark=dict(color="#e2d3ae", noise=0.025, shade=0.12),
    skin=dict(color="#d0654a", noise=0.03, shade=0.14, top=0.1),
    brick=dict(color="#b5482f", noise=0.025, shade=0.12, top=0.12),
    beak=dict(color="#f4ead0", noise=0.02, shade=0.12, top=0.12),
    beak_tip=dict(color="#3a2f24", noise=0.02, shade=0.1),
    leg=dict(color="#6e6352", noise=0.03, shade=0.12, top=0.12),
    talon=dict(color="#f4ead0", noise=0.015, shade=0.1),
    mouth="#4a1a20", white="#ffffff", iris="#3fb37f", eye="#10261c", shine="#ffffff",
    glow=dict(color="#ffc21a", glow=True), glow_jade=dict(color="#1fc46e", glow=True),
)
MR7 = dict(mirror=True)
WR7, WE7, WT7 = (-2.9, 0.7, 11.6), (-8.2, 0.9, 14.5), (-13.6, 1.2, 16.8)   # aile gauche : racine, poignet, bout
RC7 = (0, -0.7, 12.7)                                                     # centre de la collerette
HK7, HC7, HO7 = 1.3, (0, -2.45, 14.4), (0, -0.45, 1.25)                   # tete agrandie de HK7 autour de HC7, puis decalee de HO7


def HP7(x, y, z):
    return tuple(HC7[i] + ((x, y, z)[i] - HC7[i]) * HK7 + HO7[i] for i in range(3))


def HS7(*v):
    return tuple(c * HK7 for c in v)


SC7 = HP7(0, -0.9, 15.1)                                                  # centre de la couronne de soleil


def add7(a, b, k=1.0):
    return tuple(a[i] + b[i] * k for i in range(3))


def sub7(a, b):
    return tuple(a[i] - b[i] for i in range(3))


def norm7(v):
    L = math.sqrt(sum(c * c for c in v)) or 1.0
    return tuple(c / L for c in v)


def mid7(a, b, t=0.5):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def feather7(m, name, base, tip, w, role, tip_role, roll=0.0, depth=0.26, tipk=0.7, **kw):
    # plume : tige large qui s'affine, bout d'une autre couleur
    sfx = "_L" if kw.get("mirror") else ""
    p = mid7(base, tip, tipk)
    m.beam(name + sfx, start=base, end=p, role=role, width=w, depth=depth, taper=0.9, roll=roll, **kw)
    m.beam(name + "T" + sfx, start=add7(p, norm7(sub7(tip, base)), -0.25), end=tip, role=tip_role, width=w * 0.9, depth=depth + 0.02,
           taper=0.4, roll=roll, **kw)


def wing_pt7(s):
    return mid7(WR7, WE7, s / 0.45) if s <= 0.45 else mid7(WE7, WT7, (s - 0.45) / 0.55)


def build_t7(m, wroll=0.0):
    # ---- corps : oeuf d'or penche vers l'avant, poitrail clair, bas du corps, epaules
    TC, TS, TCH, TA = (0, 0.6, 9.0), (6.4, 5.6, 7.0), 2.4, math.radians(10)
    m.box("Torso", size=TS, at=TC, role="gold", chamfer=TCH, rot=(10, 0, 0))

    def torso_pt(x, dz, out=0.0):
        # point de la face avant du torse (chanfreins compris), en coordonnees locales x / dz, pousse de `out` vers l'avant
        ce = 1.2   # chanfrein reel du torse (le kit plafonne la valeur demandee ; mesure par lancer de rayon)
        yl = -TS[1] / 2 + max(0.0, abs(dz) - (TS[2] / 2 - ce), abs(x) - (TS[0] / 2 - ce)) - out
        return (TC[0] + x, TC[1] + yl * math.cos(TA) - dz * math.sin(TA), TC[2] + dz * math.cos(TA) + yl * math.sin(TA))
    # poitrail en ecailles de plumes claires : rangees de meches qui pointent vers le bas
    for r, (dz, xs) in enumerate(((1.7, (-1.0, 0.0, 1.0)), (0.75, (-1.5, -0.5, 0.5, 1.5)), (-0.2, (-1.0, 0.0, 1.0)), (-1.15, (-1.5, -0.5, 0.5, 1.5)),
                                   (-2.1, (-1.0, 0.0, 1.0)))):
        for k, x in enumerate(xs):
            a = torso_pt(x, dz + 0.55, -0.05)
            b = torso_pt(x * 1.05, dz - 0.75, 0.35)
            m.beam(f"BreastF{r}_{k}", start=a, end=b, role="gold_light" if (r + k) % 2 else "feather", width=1.25, depth=0.55, taper=0.5,
                   chamfer=0.12, solo=True)
    m.box("Lower", size=(4.8, 4.0, 3.1), at=(0, 1.1, 5.9), role="gold", chamfer=1.4)
    m.box("Shoulders", size=(6.8, 3.6, 2.8), at=(0, 1.0, 11.7), role="gold_dark", chamfer=1.2)
    # broche d'or a jade lumineuse sur le poitrail
    m.prism("Brooch", radius=0.9, height=0.45, at=(0, -3.05, 10.3), role="gold", sides=8, rot=(80, 0, 0))
    m.box("BroochGem", size=(0.62, 0.25, 0.62), at=(0, -3.42, 10.38), role="glow_jade", rot=(0, 45, 0))
    # ---- cou et collerette de plumes creme
    m.beam("Neck", start=(0, -0.3, 12.0), end=HP7(0, -1.9, 13.7), role="skin", width=2.3, depth=2.3, chamfer=0.5, taper=0.85)
    for k in range(14):
        f = math.radians(k * 360 / 14)
        a = add7(RC7, (1.1 * math.cos(f), 1.0 * math.sin(f), 0.4))
        b = add7(RC7, (3.3 * math.cos(f), 3.0 * math.sin(f), -0.9))
        m.beam(f"Ruff{k}", start=a, end=b, role="cream" if k % 2 else "cream_dark", width=1.8, depth=1.2, taper=0.45, chamfer=0.25, solo=True)
    for k in range(10):
        f = math.radians(18 + k * 36)
        a = add7(RC7, (0.9 * math.cos(f), 0.8 * math.sin(f), 1.0))
        b = add7(RC7, (2.2 * math.cos(f), 2.05 * math.sin(f), 0.25))
        m.beam(f"RuffT{k}", start=a, end=b, role="cream", width=1.5, depth=1.0, taper=0.45, chamfer=0.2, solo=True)
    # ---- tete chauve (rig Head) : crane rouge brique, crete, bec crochu ivoire a pointe sombre
    m.box("Skull", size=HS7(3.2, 3.0, 2.6), at=HP7(0, -2.45, 14.4), role="skin", chamfer=0.62 * HK7)
    m.box("Comb", size=HS7(0.6, 2.0, 0.85), at=HP7(0, -2.9, 15.85), role="brick", chamfer=0.22 * HK7, taper=(0.7, 0.8))
    m.box("Beak", size=HS7(1.5, 2.2, 1.2), at=HP7(0, -4.65, 14.25), role="beak", chamfer=0.25 * HK7, axis="y", taper=(0.7, 0.75))
    m.beam("BeakHook", start=HP7(0, -5.55, 14.55), end=HP7(0, -6.0, 13.55), role="beak_tip", width=0.72 * HK7, depth=0.75 * HK7, taper=0.45,
           chamfer=0.1 * HK7)
    m.box("MouthIn", size=HS7(1.2, 1.7, 0.25), at=HP7(0, -4.45, 13.68), role="mouth")
    m.box("Eye_L", size=HS7(1.0, 0.4, 1.05), at=HP7(-1.05, -3.88, 14.95), role="white", chamfer=0.1, **MR7)
    m.box("Iris_L", size=HS7(0.66, 0.1, 0.74), at=HP7(-1.0, -4.1, 14.9), role="iris", **MR7)
    m.box("Pupil_L", size=HS7(0.36, 0.08, 0.5), at=HP7(-0.98, -4.17, 14.88), role="eye", **MR7)
    m.box("Shine_L", size=HS7(0.24, 0.06, 0.24), at=HP7(-1.14, -4.22, 15.12), role="shine", **MR7)
    m.box("Shine2_L", size=HS7(0.12, 0.06, 0.12), at=HP7(-0.82, -4.22, 14.66), role="shine", **MR7)
    m.beam("Brow_L", start=HP7(-1.7, -3.98, 15.62), end=HP7(-0.45, -4.0, 15.55), role="gold_dark", width=0.36 * HK7, depth=0.36 * HK7,
           chamfer=0.08, **MR7)
    # ---- couronne de soleil (suit la tete) : disque d'or sombre, anneau de jade, rayons longs et courts, pointes lumineuses
    m.prism("CrownDisc", radius=3.0, height=0.7, at=SC7, role="gold_dark", sides=12, rot=(90, 0, 0))
    m.prism("CrownRing", radius=2.55, height=0.3, at=add7(SC7, (0, -0.45, 0)), role="jade", sides=12, rot=(90, 0, 0))
    for k in range(13):
        a = -132 + k * 22
        ra = math.radians(a)
        L = 6.4 if k % 2 == 0 else 5.0
        base = add7(SC7, (2.6 * math.sin(ra), 0.05, 2.6 * math.cos(ra)))
        tip = add7(SC7, (L * math.sin(ra), 0.05, L * math.cos(ra)))
        m.beam(f"Ray{k}", start=base, end=tip, role="gold" if k % 2 == 0 else "gold_light", width=1.5 if k % 2 == 0 else 1.15, depth=0.45,
               taper=0.18, roll=90 if a != 0 else 0, solo=True)
        if k % 2 == 0:
            m.box(f"RayTip{k}", size=(0.5, 0.3, 0.5), at=add7(SC7, ((L - 0.95) * math.sin(ra), -0.2, (L - 0.95) * math.cos(ra))),
                  role="glow", rot=(0, 45 + a, 0), solo=True)
    # ---- machoire (rig Jaw) : bec inferieur
    m.box("Jaw", size=HS7(1.25, 1.8, 0.5), at=HP7(0, -4.4, 13.4), role="beak", chamfer=0.12 * HK7, taper=(0.7, 0.8), axis="y", faces={"top": "mouth"})
    # ---- ailes (rig WingL / WingR) : bras d'or, couvertures claires, remiges a bouts de jade, doigts primaires
    m.box("WRoot_L", size=(2.0, 2.2, 2.2), at=WR7, role="gold_dark", chamfer=0.5, **MR7)
    m.beam("WArm_L", start=WR7, end=WE7, role="gold", width=1.2, depth=1.3, chamfer=0.25, **MR7)
    m.beam("WArm2_L", start=WE7, end=WT7, role="gold", width=1.0, depth=1.1, chamfer=0.2, taper=0.7, **MR7)
    m.box("WWrist_L", size=(1.3, 1.3, 1.3), at=WE7, role="gold_dark", chamfer=0.3, **MR7)
    FD = norm7((-0.12, 0.22, -1.0))
    # remiges secondaires (le long du bras interieur) : pendent vers le bas
    for k in range(9):
        s = 0.04 + k * 0.075
        a = add7(wing_pt7(s), (0, 0.15, 0))
        L = 4.2 + 0.25 * k
        feather7(m, f"WSec{k}", a, add7(a, FD, L), 1.45, "feather" if k % 2 else "gold_dark", "jade" if k % 2 else "jade_dark", roll=wroll,
                 mirror=True)
    # doigts primaires (bout de l'aile) : ecartes en eventail, du bas vers l'exterieur
    for k in range(6):
        s = 0.7 + k * 0.06
        a = add7(wing_pt7(s), (0, 0.2, 0))
        t = k / 5
        d = norm7((-0.25 - 0.85 * t, 0.2, -1.0 + 0.85 * t))
        L = 5.2 + 0.6 * t
        feather7(m, f"WPri{k}", a, add7(a, d, L), 1.15, "gold_dark", "jade", roll=wroll, mirror=True)
    # couvertures : rangee de plumes claires plus courtes sur le haut de l'aile
    for k in range(11):
        s = 0.03 + k * 0.088
        a = add7(wing_pt7(s), (0, 0.1, 0.1))
        m.beam(f"WCov{k}_L", start=a, end=add7(a, FD, 1.9), role="gold_light" if k % 2 else "gold", width=1.5, depth=0.42, taper=0.7, roll=wroll,
               **MR7)
    # ---- queue en eventail (rig Tail)
    m.box("TailBase", size=(3.0, 1.8, 1.6), at=(0, 3.0, 5.8), role="gold_dark", chamfer=0.5)
    for k in range(7):
        a = math.radians(-48 + k * 16)
        base = (0.6 * math.sin(a), 3.3, 5.6)
        tip = (4.6 * math.sin(a), 6.6, 3.0 + 0.6 * math.cos(a))
        feather7(m, f"TailF{k}", base, tip, 1.35, "feather" if k % 2 else "gold", "jade", roll=0, solo=True)
    # ---- pattes (rig LegL / LegR) : culotte de plumes, tarse ecaille, doigts et grandes serres
    m.box("Thigh_L", size=(2.4, 2.8, 3.0), at=(-1.9, 0.7, 5.3), role="gold_dark", chamfer=0.85, **MR7)
    m.box("Fringe_L", size=(2.5, 2.8, 0.9), at=(-1.9, 0.65, 3.85), role="feather", chamfer=0.3, taper=(1.15, 1.1), **MR7)
    m.beam("Shank_L", start=(-1.9, 0.5, 4.1), end=(-1.9, 0.0, 1.0), role="leg", width=1.15, depth=1.2, chamfer=0.2, **MR7)
    m.box("Ankle_L", size=(1.35, 1.35, 1.0), at=(-1.9, 0.0, 0.85), role="leg", chamfer=0.25, **MR7)
    for k, dx in enumerate((-0.6, 0.0, 0.6)):
        m.beam(f"Toe{k}_L", start=(-1.9, -0.1, 0.55), end=(-1.9 + dx * 1.7, -2.2, 0.4), role="leg", width=0.6, depth=0.55, **MR7)
        m.prism(f"Talon{k}_L", radius=0.25, height=0.7, at=(-1.9 + dx * 1.75, -2.45, 0.32), role="talon", sides=4, taper=0, rot=(125, 0, 0), **MR7)
    m.beam("ToeB_L", start=(-1.9, 0.1, 0.55), end=(-1.9, 1.5, 0.4), role="leg", width=0.55, depth=0.52, **MR7)
    m.prism("TalonB_L", radius=0.22, height=0.6, at=(-1.9, 1.75, 0.32), role="talon", sides=4, taper=0, rot=(-125, 0, 0), **MR7)
    # ---- peinture : plumes en ecailles sur le poitrail, narines
    m.rect("Beak", "top", (-0.3, 0.3), (0.16, 0.24), "beak_tip")
    m.rect("Beak", "top", (0.3, 0.3), (0.16, 0.24), "beak_tip")
    return m


C13 = ropilot.model("R13_T7", px=8, reset=True)
C13.reference(REF7)
C13.palette(**PAL7)
build_t7(C13, wroll=90.0)
print(C13.build()); print(C13.check()); print(C13.compare()["report"])


def close_gaps_r13(col_name, rounds=25, extra=0.025):
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


def ground_r13(col_name):
    # pose le point le plus bas sur z = 0
    bpy.context.view_layer.update()
    objs = [o for o in bpy.data.collections[col_name].all_objects if o.type == "MESH"]
    z0 = min(min((o.matrix_world @ v.co).z for v in o.data.vertices) for o in objs)
    for o in objs:
        o.location.z -= z0
    bpy.context.view_layer.update()
    return z0


print("sol", ground_r13("R13_T7"))
close_gaps_r13("R13_T7")


def save_only_r13(col_name, fname):
    # n'ecrit que la collection de la creature (pas les modeles des autres taches ni les references)
    col = bpy.data.collections[col_name]
    bpy.data.libraries.write(os.path.join(ropilot.FILES_DIR, fname), {col}, fake_user=True, compress=True)


save_only_r13("R13_T7", "R13_T7.blend")


def wing7(s):
    return [f"WRoot_{s}", f"WArm_{s}", f"WArm2_{s}", f"WWrist_{s}", f"WSec*_{s}", f"WPri*_{s}", f"WCov*_{s}"]


def leg7(s):
    return [f"Thigh_{s}", f"Fringe_{s}", f"Shank_{s}", f"Ankle_{s}", f"Toe*_{s}", f"Talon*_{s}"]


GROUPS_T7 = {'Head': ['Skull', 'Comb', 'Beak', 'BeakHook', 'MouthIn', 'Eye_*', 'Iris_*', 'Pupil_*', 'Shine_*', 'Shine2_*', 'Brow_*',
                      'CrownDisc', 'CrownRing', 'Ray*'],
             'Jaw': ['Jaw'],
             'WingL': wing7('L'), 'WingR': wing7('R'),
             'LegL': leg7('L'), 'LegR': leg7('R'),
             'Tail': ['TailBase', 'TailF*']}
# --- suite : exec(rigjoin.py), rig_clear avant chaque reconstruction, rig_join("R13_T7", GROUPS_T7),
# save_only_r13("R13_T7", "R13_T7_rig.blend"), import -> Work_R13_T7b, CreatureRig.Install(workspace.Work_R13_T7b, "R13_T7", nil, true)
# joints corriges dans le repere du Core : Head (0, 14.0, -1.7) au cou, Jaw (0, 14.55, -4.25) a la charniere du bec,
# WingL/R (+-2.9, 11.5, 0.7) a l'epaule (Install : 12.4 / +1.65), LegL/R (+-1.9, 6.4, 0.7) a la hanche, Tail (0, 5.75, 2.4) a la racine
# compare() final : face 0.50, dos 0.50, gauche 0.50, dessus 0.48 : la reference (Ref_R13_T7b) est un oiseau trapu aux ailes
# dressees et etroites ; ici ailes immenses deployees en V (envergure 38.6) et couronne de soleil, volontairement.
# 216 pieces kit, 10 pieces Studio (Body, Body2 neon, Head, Head__Glow, Jaw, LegL/R, Tail, WingL/R), hauteur 22.84
# Portrait : rbxassetid://90753684144093
