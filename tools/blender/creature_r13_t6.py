# Feathered Serpent (R13_T6, Mythic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R13_Refs/Ref_R13_T6_*.png)
# Long serpent de jade enroule au sol en grande boucle, cou dresse en S, plaques de ventre creme sur le cou,
# anneaux d'or graves et ecailles d'or en losange le long du dos ; tete a museau long et plaque d'or, grands yeux
# ambre separes sur les aretes avant du crane (visibles de face et de profil, reflets), sourcils d'or, gemme
# turquoise lumineuse au front, machoire (rig Jaw) a langue fourchue rouge brique et crocs creme ; grande
# collerette de plumes rouges, bleues, jade et turquoise sur un anneau d'or (suit la tete) ; deux ailes de plumes
# (rig WingL / WingR) partant du haut du cou ; queue qui passe par-dessus la boucle, se dresse en s'affinant et
# finit en panache de plumes (rig Tail).
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R13_Refs")
REF6 = {v: os.path.join(R, f"Ref_R13_T6_{v}.png") for v in ("front", "left", "back", "top")}
PAL6 = dict(
    jade=dict(color="#3fb37f", noise=0.035, shade=0.16, mottle=("#35a070", 0.3, 3), top=0.14),
    jade_dark=dict(color="#1f6e4e", noise=0.03, shade=0.12, top=0.1),
    jade_light=dict(color="#8fe0b4", noise=0.025, shade=0.1, top=0.1),
    belly=dict(color="#f0d9a0", noise=0.02, shade=0.12, top=0.08, rim=-0.18),
    gold=dict(color="#f2c14e", noise=0.03, shade=0.14, top=0.16, rim=-0.2),
    gold_dark=dict(color="#b8862b", noise=0.03, shade=0.12),
    red=dict(color="#e5484d", noise=0.025, shade=0.12, top=0.12),
    blue=dict(color="#3e7be0", noise=0.025, shade=0.12, top=0.12),
    teal=dict(color="#3ec9d6", noise=0.025, shade=0.12, top=0.12),
    brick=dict(color="#b5482f", noise=0.02, shade=0.12),
    cream=dict(color="#f4ead0", noise=0.015, shade=0.1),
    mouth="#4a1a20", white="#ffffff", iris="#2bb3c0", eye="#0b1a14", shine="#ffffff",
    glow=dict(color="#22c8d8", glow=True),
)
MR6 = dict(mirror=True)


def add6(a, b, k=1.0):
    return tuple(a[i] + b[i] * k for i in range(3))


def sub6(a, b):
    return tuple(a[i] - b[i] for i in range(3))


def norm6(v):
    L = math.sqrt(sum(c * c for c in v)) or 1.0
    return tuple(c / L for c in v)


def mid6(a, b, t=0.5):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


# ---- trace du corps : boucle au sol (ellipse), cou, queue
LC, LRX, LRY, LZ = (0.0, 1.0), 3.4, 3.0, 1.0
LOOP = [(LC[0] + LRX * math.cos(math.radians(270 - 22.5 * k)), LC[1] + LRY * math.sin(math.radians(270 - 22.5 * k)), LZ) for k in range(15)]
INNER = [(1.1, -0.55, 1.0), (0.55, 1.0, 1.02), (0.2, 2.55, 1.5)]
TAILP = [(0.0, 3.85, 2.36), (0.0, 4.85, 3.6), (0.0, 5.3, 4.9), (0.0, 5.35, 5.9)]
NECK = [(0, -2.0, 1.0), (0, -2.45, 2.6), (0, -2.25, 4.3), (0, -1.55, 5.9), (0, -1.25, 7.5), (0, -1.6, 9.0), (0, -2.3, 10.25)]
NW = [2.4, 2.4, 2.3, 2.2, 2.1, 2.0, 1.95]
HC6 = (0, -3.0, 11.1)
HK6 = 1.3                     # tete agrandie de HK6 autour du centre du crane


def HP6(x, y, z):
    return tuple(HC6[i] + ((x, y, z)[i] - HC6[i]) * HK6 for i in range(3))


def HS6(*v):
    return tuple(c * HK6 for c in v)


CC6 = HP6(0, -1.75, 11.1)     # centre de la collerette
WR6, WE6, WT6 = (-0.8, -1.0, 8.4), (-3.1, -0.8, 9.7), (-6.3, -0.4, 10.5)


def seg6(m, name, a, b, w0, w1, role, ext=0.14, **kw):
    d = norm6(sub6(b, a))
    m.beam(name, start=add6(a, d, -ext), end=add6(b, d, ext), role=role, width=w0, depth=w0 * 0.92, taper=w1 / w0,
           chamfer=0.3 * w1, **kw)


def feather6(m, name, base, tip, w, role, tip_role, roll=0.0, **kw):
    # plume : tige large qui s'affine, bout d'une autre couleur
    sfx = "_L" if kw.get("mirror") else ""
    p = mid6(base, tip, 0.68)
    m.beam(name + sfx, start=base, end=p, role=role, width=w, depth=0.22, taper=0.85, roll=roll, **kw)
    m.beam(name + "T" + sfx, start=add6(p, norm6(sub6(tip, base)), -0.2), end=tip, role=tip_role, width=w * 0.85, depth=0.24, taper=0.35,
           roll=roll, **kw)


def build_t6(m):
    # ---- boucle au sol, epaisse a l'avant, qui s'affine vers la queue
    pts = LOOP + INNER
    n = len(pts) - 1
    W = [2.35 - 0.6 * i / n for i in range(n + 1)]
    for i in range(n):
        seg6(m, f"Loop{i}", pts[i], pts[i + 1], W[i], W[i + 1], "jade", solo=True)
        if i % 3 == 1:
            seg6(m, f"Band{i}", mid6(pts[i], pts[i + 1], 0.44), mid6(pts[i], pts[i + 1], 0.56), W[i] + 0.08, W[i] + 0.08, "gold", ext=0, solo=True)
        elif 0 < i < n - 1:
            c = mid6(pts[i], pts[i + 1])
            yaw = math.degrees(math.atan2(pts[i + 1][0] - pts[i][0], -(pts[i + 1][1] - pts[i][1])))
            m.box(f"Scale{i}", size=(0.62, 0.62, 0.3), at=(c[0], c[1], c[2] + W[i] * 0.46 - 0.06), role="gold", rot=(0, 0, 45 + yaw), solo=True)
    # ---- queue (rig Tail) : se dresse par-dessus l'arriere de la boucle, panache de plumes
    tp = [INNER[-1]] + TAILP
    TW = [1.75, 1.5, 1.2, 0.9, 0.7]
    for i in range(len(tp) - 1):
        seg6(m, f"Tail{i}", tp[i], tp[i + 1], TW[i], TW[i + 1], "jade", solo=True)
    seg6(m, "TailBand", mid6(tp[2], tp[3], 0.45), mid6(tp[2], tp[3], 0.6), 1.12, 1.12, "gold", ext=0, solo=True)
    top = TAILP[-1]
    m.prism("PlumeCup", radius=0.5, height=0.5, at=add6(top, (0, 0, -0.1)), role="gold", sides=6, taper=1.3)
    for k, (a, L, r1, r2) in enumerate(((-55, 2.0, "blue", "teal"), (-28, 2.6, "red", "gold"), (0, 3.1, "teal", "red"), (28, 2.6, "red", "gold"),
                                        (55, 2.0, "blue", "teal"))):
        ra = math.radians(a)
        base = add6(top, (0.25 * math.sin(ra), 0.05, 0.3))
        tip = add6(top, (L * math.sin(ra), 0.55, 0.3 + L * math.cos(ra)))
        feather6(m, f"Plume{k}", base, tip, 0.72, r1, r2, solo=True)
    # ---- cou dresse en S, plaques de ventre creme a l'avant, anneaux d'or
    for i in range(len(NECK) - 1):
        a, b = NECK[i], NECK[i + 1]
        seg6(m, f"Neck{i}", a, b, NW[i], NW[i + 1], "jade")
        d = norm6(sub6(b, a))
        nf = (0, -d[2], d[1]) if -d[2] < 0 else (0, d[2], -d[1])     # normale vers l'avant (-Y)
        seg6(m, f"Plate{i}", add6(a, nf, NW[i] * 0.4), add6(b, nf, NW[i + 1] * 0.4), NW[i] * 0.62, NW[i + 1] * 0.62, "belly", ext=0.22)
        if i in (1, 3):
            seg6(m, f"NeckBand{i}", mid6(a, b, 0.4), mid6(a, b, 0.56), NW[i] + 0.12, NW[i] + 0.12, "gold", ext=0)
        if i in (0, 2):
            nb = (0, -nf[1], -nf[2])
            c = add6(mid6(a, b), nb, NW[i] * 0.45)
            m.box(f"NeckScale{i}", size=(0.6, 0.3, 0.6), at=c, role="gold", rot=(0, 45, 0))
    # ---- tete (rig Head) : crane, long museau, plaque d'or, gueule, crocs
    m.box("Skull", size=HS6(2.6, 2.7, 2.4), at=HC6, role="jade", chamfer=0.45 * HK6, faces={"bottom": "belly"})
    m.box("Snout", size=HS6(2.0, 2.0, 1.15), at=HP6(0, -5.1, 10.85), role="jade", chamfer=0.3 * HK6, axis="y", taper=(0.8, 0.8), faces={"bottom": "belly"})
    m.box("NosePlate", size=HS6(1.1, 1.5, 0.16), at=HP6(0, -5.05, 11.43), role="gold", chamfer=0.04, taper=(0.7, 1), axis="y")
    m.box("MouthIn", size=HS6(1.6, 2.0, 0.3), at=HP6(0, -4.9, 10.2), role="mouth")
    for k, x in enumerate((-0.55, 0.55)):
        m.prism(f"Fang{k}", radius=0.13 * HK6, height=0.42 * HK6, at=HP6(x, -5.75, 10.32), role="cream", sides=4, taper=0, rot=(180, 0, 0), solo=True)
    # grands yeux ambre en saillie sur l'avant du crane, au-dessus du museau (vus de face, bosses vues de profil)
    m.box("Eye_L", size=(1.05, 0.4, 1.12), at=(-0.9, -4.72, 11.92), role="white", chamfer=0.08, **MR6)
    m.box("Iris_L", size=(0.66, 0.1, 0.76), at=(-0.86, -4.95, 11.88), role="iris", **MR6)
    m.box("Pupil_L", size=(0.36, 0.08, 0.5), at=(-0.84, -5.02, 11.85), role="eye", **MR6)
    m.box("Shine_L", size=(0.24, 0.06, 0.24), at=(-1.0, -5.07, 12.1), role="shine", **MR6)
    m.box("Shine2_L", size=(0.12, 0.06, 0.12), at=(-0.66, -5.07, 11.62), role="shine", **MR6)
    m.beam("Brow_L", start=(-1.5, -4.82, 12.62), end=(-0.32, -4.86, 12.58), role="jade_dark", width=0.34, depth=0.34, chamfer=0.05, **MR6)
    # gemme turquoise lumineuse sur le haut du museau, entre les yeux, sur une plaque d'or
    m.box("GemPlate", size=(0.66, 0.3, 0.66), at=(0, -5.35, 11.7), role="gold", chamfer=0.06, rot=(0, 45, 0))
    m.box("Gem", size=(0.4, 0.22, 0.4), at=(0, -5.5, 11.7), role="glow", rot=(0, 45, 0))
    # ---- collerette de plumes (suit la tete) : anneau d'or, deux couronnes de plumes rouges, bleues, jade, turquoise
    m.prism("CrestRing", radius=2.2, height=0.6, at=CC6, role="gold", sides=10, rot=(90, 0, 0))
    m.prism("CrestDisc", radius=1.95, height=0.45, at=add6(CC6, (0, 0.55, 0)), role="gold_dark", sides=10, rot=(90, 0, 0))
    COLS = (("red", "gold"), ("blue", "teal"), ("jade", "gold"), ("teal", "blue"))
    for k in range(13):
        a = -120 + k * 20
        ra = math.radians(a)
        L = 2.3 + 1.2 * math.cos(ra) ** 2 * (1 if abs(a) < 90 else 0)
        base = add6(CC6, (1.6 * math.sin(ra), -0.05, 1.6 * math.cos(ra)))
        tip = add6(CC6, ((1.6 + L) * math.sin(ra), -0.25, (1.6 + L) * math.cos(ra)))
        r1, r2 = COLS[k % 4]
        feather6(m, f"CF{k}", base, tip, 1.0, r1, r2, roll=0 if a == 0 else 90, solo=True)
    for k in range(1, 11):
        a = -110 + k * 20
        ra = math.radians(a)
        L = 2.8 + 1.3 * math.cos(ra) ** 2 * (1 if abs(a) < 90 else 0)
        base = add6(CC6, (1.5 * math.sin(ra), 0.45, 1.5 * math.cos(ra)))
        tip = add6(CC6, ((1.5 + L) * math.sin(ra), 0.55, (1.5 + L) * math.cos(ra)))
        r1, r2 = COLS[(k + 2) % 4]
        feather6(m, f"CB{k}", base, tip, 1.15, r1, r2, roll=90, solo=True)
    # ---- machoire (rig Jaw) : langue fourchue, petits crocs
    m.box("Jaw", size=HS6(1.75, 2.2, 0.5), at=HP6(0, -4.85, 9.88), role="jade", chamfer=0.14 * HK6, taper=(0.82, 0.85), axis="y",
          faces={"top": "mouth", "bottom": "belly"})
    m.beam("Tongue", start=HP6(0, -5.0, 10.1), end=HP6(0, -6.35, 10.0), role="brick", width=0.3, depth=0.12)
    m.beam("TongueF_L", start=HP6(0, -6.3, 10.0), end=HP6(-0.22, -6.8, 9.95), role="brick", width=0.22, depth=0.12, **MR6)
    for k, x in enumerate((-0.45, 0.45)):
        m.prism(f"LowFang{k}", radius=0.1 * HK6, height=0.3 * HK6, at=HP6(x, -5.6, 10.08), role="cream", sides=4, taper=0, solo=True)
    # ---- ailes de plumes (rig WingL / WingR) depuis le haut du cou
    m.box("WRoot_L", size=(0.9, 1.0, 1.0), at=WR6, role="gold", chamfer=0.2, **MR6)
    m.beam("WArm_L", start=WR6, end=WE6, role="gold", width=0.62, depth=0.7, chamfer=0.12, **MR6)
    m.beam("WArm2_L", start=WE6, end=WT6, role="gold", width=0.55, depth=0.62, chamfer=0.1, taper=0.6, **MR6)
    m.box("WWrist_L", size=(0.8, 0.8, 0.8), at=WE6, role="gold_dark", chamfer=0.15, **MR6)
    m.box("WGem_L", size=(0.42, 0.2, 0.42), at=add6(WE6, (0, -0.44, 0)), role="glow", rot=(0, 45, 0), **MR6)
    FD = norm6((-0.3, 0.3, -0.9))
    WF = [(0.06, 1.5), (0.18, 1.9), (0.3, 2.3), (0.42, 2.6), (0.54, 2.9), (0.66, 3.2), (0.78, 3.45), (0.9, 3.6), (1.0, 3.5)]
    WC = (("jade", "blue"), ("blue", "red"), ("jade", "teal"), ("red", "gold"))
    for k, (s, L) in enumerate(WF):
        a = mid6(WR6, WE6, s / 0.45) if s <= 0.45 else mid6(WE6, WT6, (s - 0.45) / 0.55)
        a = add6(a, (0, 0.1, 0))
        r1, r2 = WC[k % 4]
        feather6(m, f"WF{k}", a, add6(a, FD, L), 1.15, r1, r2, roll=45, mirror=True)
        if k % 2 == 0:
            m.beam(f"WCov{k}_L", start=add6(a, FD, -0.1), end=add6(a, FD, 1.0), role="jade_light", width=1.3, depth=0.32, taper=0.8, roll=45, **MR6)
    # ---- peinture : ecailles sur les plaques, narines, bouche
    m.rect("Snout", "front", (-0.35, 0.2), (0.16, 0.12), "jade_dark")
    m.rect("Snout", "front", (0.35, 0.2), (0.16, 0.12), "jade_dark")
    return m


S13 = ropilot.model("R13_T6", px=8, reset=True)
S13.reference(REF6)
S13.palette(**PAL6)
build_t6(S13)
print(S13.build()); print(S13.check()); print(S13.compare()["report"])


def close_gaps_r13(col_name, rounds=15, extra=0.025):
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


print("sol", ground_r13("R13_T6"))
close_gaps_r13("R13_T6", rounds=25)


def save_only_r13(col_name, fname):
    # n'ecrit que la collection de la creature (pas les modeles des autres taches ni les references)
    col = bpy.data.collections[col_name]
    bpy.data.libraries.write(os.path.join(ropilot.FILES_DIR, fname), {col}, fake_user=True, compress=True)


save_only_r13("R13_T6", "R13_T6.blend")


def wing6(s):
    return [f"WRoot_{s}", f"WArm_{s}", f"WArm2_{s}", f"WWrist_{s}", f"WGem_{s}", f"WF*_{s}", f"WCov*_{s}"]


GROUPS_T6 = {'Head': ['Skull', 'Snout', 'NosePlate', 'MouthIn', 'Fang*', 'Eye_*', 'Iris_*', 'Pupil_*', 'Shine_*', 'Shine2_*', 'Brow_*',
                      'GemPlate', 'Gem', 'CrestRing', 'CrestDisc', 'CF*', 'CB*'],
             'Jaw': ['Jaw', 'Tongue*', 'LowFang*'],
             'WingL': wing6('L'), 'WingR': wing6('R'),
             'Tail': ['Tail*', 'PlumeCup', 'Plume*']}
# --- suite : exec(rigjoin.py), rig_clear avant chaque reconstruction, rig_join("R13_T6", GROUPS_T6),
# save_only_r13("R13_T6", "R13_T6_rig.blend"), import -> Work_R13_T6, CreatureRig.Install(workspace.Work_R13_T6, "R13_T6", nil, true)
# joints corriges dans le repere du Core : Head (0, 10.3, -2.2) en haut du cou, Jaw (0, 9.95, -4.0) a la charniere (Install la
# mettait 0.6 trop en arriere), WingL/R (+-0.8, 8.5, -1.0) a la racine sur le cou (au lieu de 9.0 / +0.6),
# Tail (0.2, 1.6, 2.6) la ou la queue quitte la boucle (Install la mettait en l'air a 5.4)
# Cou et boucle au sol dans Body (pas de membre : slither anime le modele entier) ; collerette dans Head.
# compare() final : face 0.48, dos 0.48, gauche 0.50, dessus 0.37 : la reference a une boucle plus large et plate et une petite
# tete ; ici tete agrandie (HK6 = 1.3) avec yeux visibles de face, collerette en soleil plus grande, boucle plus compacte.
# 195 pieces kit, 9 pieces Studio (Body, Head, Head__Glow, Jaw, Tail, WingL/R, WingL/R__Glow), hauteur 16.71
# Portrait : rbxassetid://76004535046896
