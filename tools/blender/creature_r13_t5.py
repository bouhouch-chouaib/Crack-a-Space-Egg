# Temple Lion (R13_T5, Legendary) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R13_Refs/Ref_R13_T5_*.png)
# Lion gardien de temple debout sur quatre pattes massives : corps en pierre sable sculptee (spirales gravees
# sur les epaules et les cuisses), grande criniere d'or en deux couronnes de meches a boucles gravees autour du
# visage (suit la tete), visage de pierre, coussinets du museau, nez rouge brique, yeux de jade separes a reflets
# sous des sourcils droits, diademe d'or au front avec trois gemmes (jade lumineuse au centre, rouge brique de
# part et d'autre), machoire (rig Jaw) a crocs creme et barbiche d'or, oreilles rondes (rig EarL / EarR), collier
# d'or a clochette de jade, touffes d'or aux coudes, aux jarrets et le long de l'echine, bracelets d'or aux
# poignets, griffes creme ; la patte avant gauche posee sur une boule de jade gravee d'or ; queue a houppe (rig Tail).
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R13_Refs")
REF5 = {v: os.path.join(R, f"Ref_R13_T5_{v}.png") for v in ("front", "left", "back", "top")}
PAL5 = dict(
    stone=dict(color="#c8a673", noise=0.035, shade=0.16, mottle=("#bb9967", 0.25, 4), top=0.14, speckle=("#a8946e", 0.05)),
    stone_dark=dict(color="#7d6646", noise=0.03, shade=0.12),
    stone_light=dict(color="#e2c999", noise=0.025, shade=0.1, top=0.1),
    gold=dict(color="#f2c14e", noise=0.03, shade=0.14, top=0.16, rim=-0.2),
    gold_dark=dict(color="#b8862b", noise=0.03, shade=0.12, top=0.1),
    gold_light=dict(color="#ffd97a", noise=0.025, shade=0.1, top=0.12),
    jade=dict(color="#3fb37f", noise=0.03, shade=0.14, top=0.16, rim=-0.22),
    jade_dark=dict(color="#1f6e4e", noise=0.03, shade=0.12),
    brick=dict(color="#b5482f", noise=0.02, shade=0.12, top=0.15, rim=-0.2),
    cream=dict(color="#f4ead0", noise=0.015, shade=0.1),
    mouth="#5a2018", white="#ffffff", iris="#2f9e6c", eye="#10261c", shine="#ffffff",
    glow=dict(color="#1fc46e", glow=True),
)
MR5 = dict(mirror=True)


def tuft5(m, name, c, r, a, size, role, y=None, tip=(0.5, 0.65), spiral=True):
    # meche de criniere : bloc chanfreine qui s'affine, pointe vers l'exterieur a l'angle a (0 = haut, 90 = +X)
    ra = math.radians(a)
    p = (c[0] + r * math.sin(ra), c[1] if y is None else y, c[2] + r * math.cos(ra))
    m.box(name, size=size, at=p, role=role, chamfer=min(size[0], size[1]) * 0.28, taper=tip, rot=(0, a, 0), solo=True)
    if spiral:
        m.line(name, "front", [(-0.22, 0.55), (-0.18, -0.5)], "gold_dark", 1)
        m.line(name, "front", [(0.22, 0.45), (0.18, -0.4)], "gold_dark", 1)
    return p


def build_t5(m):
    MC = (0, -3.7, 8.1)       # centre de la criniere (et du visage)
    # ---- corps : poitrail massif et arrondi, tonneau, croupe ; ventre plus sombre
    m.box("Chest", size=(4.4, 3.4, 4.4), at=(0, -1.85, 5.0), role="stone", chamfer=1.45, faces={"bottom": "stone_dark"})
    m.box("Barrel", size=(3.9, 3.6, 3.5), at=(0, 0.95, 5.25), role="stone", chamfer=1.25, faces={"bottom": "stone_dark"})
    m.box("Rump", size=(4.1, 3.0, 3.8), at=(0, 3.3, 5.15), role="stone", chamfer=1.35, faces={"bottom": "stone_dark"}, slope=(0, -0.2))
    # dos et ventre continus : une seule ligne de dos, du garrot a la croupe
    m.box("Back", size=(3.4, 6.6, 1.1), at=(0, 1.0, 6.55), role="stone", chamfer=0.5)
    m.box("Belly", size=(3.0, 5.2, 1.0), at=(0, 0.7, 3.85), role="stone_dark", chamfer=0.45)
    # ---- criniere d'or (suit la tete) : masse arrondie, meches de cote et de nuque, deux couronnes autour du visage
    m.box("ManeMass", size=(4.8, 3.2, 5.0), at=(MC[0], -2.35, MC[2]), role="gold_dark", chamfer=1.6)
    for k in range(10):
        a = -135 + k * 30
        tuft5(m, f"ManeS{k}", MC, 2.6, a, (1.8, 2.5, 2.3), "gold" if k % 2 else "gold_dark", y=-1.9, spiral=False)
    # meches de nuque qui pointent vers l'arriere (couvrent le dos de la criniere)
    for k, a in enumerate((-120, -60, 0, 60, 120)):
        ra = math.radians(a)
        m.box(f"ManeNape{k}", size=(1.6, 1.4, 2.1), at=(1.55 * math.sin(ra), -0.35, MC[2] + 1.55 * math.cos(ra)),
              role="gold" if k % 2 else "gold_light", chamfer=0.4, taper=(0.5, 0.6), rot=(-80, 0, 0), solo=True)
    m.box("ManeNapeC", size=(1.5, 1.3, 1.8), at=(0, -0.4, MC[2] - 0.2), role="gold_dark", chamfer=0.4, taper=(0.5, 0.6), rot=(-80, 0, 0))
    for k in range(12):
        a = -165 + k * 30
        tuft5(m, f"ManeB{k}", MC, 3.05, a, (1.75, 1.3, 2.3), "gold_dark", y=-3.05, spiral=False)
    for k in range(11):
        a = -150 + k * 30
        tuft5(m, f"Mane{k}", MC, 2.55, a, (1.6, 1.25, 2.0), "gold_light" if k % 2 else "gold", y=-3.85)
    # ---- visage (rig Head) : tete de pierre, arete du nez, coussinets du museau, nez, menton
    m.box("Head", size=(3.2, 2.4, 3.4), at=(0, -4.95, 8.0), role="stone", chamfer=0.5)
    m.box("Bridge", size=(1.0, 1.2, 0.7), at=(0, -6.1, 8.0), role="stone", chamfer=0.25, taper=(0.8, 1), axis="y")
    m.box("Pad_L", size=(1.25, 1.25, 1.05), at=(-0.58, -6.45, 7.05), role="stone_light", chamfer=0.42, **MR5)
    m.box("Nose", size=(1.15, 0.7, 0.62), at=(0, -6.85, 7.68), role="stone_dark", chamfer=0.16, taper=(0.55, 1))
    m.box("MouthIn", size=(1.7, 1.1, 0.35), at=(0, -6.35, 6.45), role="mouth")
    for k, x in enumerate((-0.62, 0.62)):
        m.prism(f"Fang{k}", radius=0.15, height=0.45, at=(x, -6.88, 6.62), role="cream", sides=4, taper=0, rot=(180, 0, 0), solo=True)
    # yeux de jade separes, grands, sous des sourcils droits (regard fier)
    m.box("Eye_L", size=(1.0, 0.12, 0.95), at=(-0.82, -6.18, 8.5), role="white", **MR5)
    m.box("Iris_L", size=(0.74, 0.1, 0.8), at=(-0.77, -6.24, 8.45), role="iris", **MR5)
    m.box("Pupil_L", size=(0.36, 0.08, 0.5), at=(-0.75, -6.29, 8.42), role="eye", **MR5)
    m.box("Shine_L", size=(0.22, 0.06, 0.22), at=(-0.9, -6.31, 8.67), role="shine", **MR5)
    m.box("Shine2_L", size=(0.11, 0.06, 0.11), at=(-0.6, -6.31, 8.25), role="shine", **MR5)
    m.beam("Brow_L", start=(-1.42, -6.2, 9.13), end=(-0.32, -6.2, 9.07), role="stone_light", width=0.32, depth=0.3, chamfer=0.06, **MR5)
    # diademe d'or au front : jade lumineuse au centre, gemmes rouge brique de part et d'autre
    m.box("Diadem", size=(2.3, 0.24, 0.42), at=(0, -6.2, 9.45), role="gold", chamfer=0.06)
    m.box("Gem", size=(0.62, 0.24, 0.62), at=(0, -6.29, 9.47), role="glow", rot=(0, 45, 0))
    m.box("GemSide_L", size=(0.36, 0.18, 0.36), at=(-0.78, -6.29, 9.45), role="brick", rot=(0, 45, 0), **MR5)
    # oreilles rondes (rig EarL / EarR) devant la criniere
    m.box("Ear_L", size=(0.95, 0.5, 0.95), at=(-1.4, -4.75, 9.95), role="stone", chamfer=0.3, rot=(0, -25, 0), **MR5)
    m.box("EarIn_L", size=(0.5, 0.1, 0.5), at=(-1.41, -5.02, 9.93), role="stone_dark", rot=(0, -25, 0), **MR5)
    # ---- machoire (rig Jaw) et barbiche d'or
    m.box("Jaw", size=(1.75, 1.3, 0.55), at=(0, -6.2, 6.1), role="stone_light", chamfer=0.18, taper=(0.85, 0.9), axis="y",
          faces={"top": "mouth"})
    for k, x in enumerate((-0.5, 0.5)):
        m.prism(f"LowFang{k}", radius=0.12, height=0.34, at=(x, -6.68, 6.35), role="cream", sides=4, taper=0, solo=True)
    m.box("Beard", size=(1.3, 0.9, 0.9), at=(0, -6.05, 5.55), role="gold", chamfer=0.3, taper=(0.6, 0.8))
    # ---- collier d'or et clochette de jade (sur le poitrail, sous la criniere)
    m.box("Collar", size=(3.6, 0.7, 0.6), at=(0, -3.4, 4.55), role="gold", chamfer=0.15, faces={"front": "gold_light"})
    m.prism("BellCap", radius=0.4, height=0.3, at=(0, -3.85, 4.2), role="gold_dark", sides=6)
    m.box("Bell", size=(0.95, 0.85, 0.95), at=(0, -3.9, 3.7), role="jade", chamfer=0.3, taper=(1.15, 1.15))
    # ---- pattes avant (rig LegFL / LegFR) : epaule, bras qui s'affine, poignet d'or, grosse patte a doigts et griffes
    m.box("Shoulder_L", size=(1.7, 2.5, 2.9), at=(-1.8, -1.95, 5.15), role="stone", chamfer=0.8, **MR5)
    m.box("ElbowTuft_L", size=(1.1, 1.0, 1.5), at=(-1.85, -0.85, 3.65), role="gold", chamfer=0.35, taper=(0.55, 0.9), rot=(-30, 0, 0), **MR5)
    # gauche : patte posee sur la boule (bras incline vers l'avant) ; droite : au sol
    PAW = {"L": (-1.85, -4.15, 2.75), "R": (1.85, -2.55, 0.48)}
    m.beam("FUpper_L", start=(-1.85, -2.0, 4.7), end=(-1.85, -2.2, 3.0), role="stone", width=1.85, depth=1.95, taper=0.9, chamfer=0.5, **MR5)
    m.beam("FArm_L", start=(-1.85, -2.2, 3.3), end=(-1.85, -3.75, 2.95), role="stone", width=1.6, depth=1.6, taper=0.9, chamfer=0.4)
    m.beam("FArm_R", start=(1.85, -2.2, 3.3), end=(1.85, -2.45, 1.05), role="stone", width=1.6, depth=1.6, taper=0.9, chamfer=0.4)
    for s, (x, y, z) in PAW.items():
        m.box(f"FPaw_{s}", size=(1.9, 2.2, 0.95), at=(x, y, z), role="stone", chamfer=0.36, faces={"bottom": "stone_dark"})
        m.box(f"FBand_{s}", size=(1.5, 1.5, 0.4), at=(x, y + 0.3, z + 0.65), role="gold", chamfer=0.1)
        for k, dx in enumerate((-0.6, 0.0, 0.6)):
            m.box(f"FToe{k}_{s}", size=(0.6, 0.6, 0.62), at=(x + dx, y - 1.12, z - 0.14), role="stone_light", chamfer=0.18)
            m.prism(f"FClaw{k}_{s}", radius=0.13, height=0.35, at=(x + dx, y - 1.45, z - 0.2), role="cream", sides=4, taper=0, rot=(90, 0, 0))
    # ---- boule de jade gravee d'or sous la patte avant gauche
    BC = (-1.85, -4.4, 1.2)
    m.box("Ball", size=(2.3, 2.3, 2.3), at=BC, role="jade", chamfer=0.72, solo=True)
    m.box("BallBand", size=(2.38, 0.3, 2.38), at=BC, role="gold", chamfer=0.72, solo=True)
    m.box("BallBand2", size=(0.3, 2.38, 2.38), at=BC, role="gold", chamfer=0.72, solo=True)
    m.box("BallGem", size=(0.5, 0.2, 0.5), at=(BC[0], BC[1] - 1.2, BC[2]), role="glow", rot=(0, 45, 0), solo=True)
    # ---- pattes arriere (rig LegBL / LegBR) : cuisse, jambe vers le jarret, canon, patte
    m.box("Thigh_L", size=(1.9, 3.1, 3.5), at=(-1.95, 3.25, 4.55), role="stone", chamfer=1.0, rot=(-8, 0, 0), **MR5)
    m.beam("BShin_L", start=(-1.9, 3.6, 3.8), end=(-1.9, 4.35, 2.0), role="stone", width=1.6, depth=1.75, taper=0.85, chamfer=0.4, **MR5)
    m.box("HockTuft_L", size=(1.0, 1.0, 1.3), at=(-1.9, 4.85, 2.35), role="gold", chamfer=0.3, taper=(0.55, 0.9), rot=(30, 0, 0), **MR5)
    m.beam("BCannon_L", start=(-1.9, 4.4, 2.2), end=(-1.9, 3.85, 0.85), role="stone", width=1.25, depth=1.35, chamfer=0.3, **MR5)
    m.box("BPaw_L", size=(1.8, 2.1, 0.9), at=(-1.9, 3.45, 0.45), role="stone", chamfer=0.34, faces={"bottom": "stone_dark"}, **MR5)
    m.box("BBand_L", size=(1.4, 1.4, 0.38), at=(-1.9, 3.85, 1.1), role="gold", chamfer=0.1, **MR5)
    for k, dx in enumerate((-0.55, 0.0, 0.55)):
        m.box(f"BToe{k}_L", size=(0.56, 0.55, 0.56), at=(-1.9 + dx, 2.4, 0.3), role="stone_light", chamfer=0.16, **MR5)
        m.prism(f"BClaw{k}_L", radius=0.12, height=0.32, at=(-1.9 + dx, 2.1, 0.25), role="cream", sides=4, taper=0, rot=(90, 0, 0), **MR5)
    # ---- touffes d'or le long de l'echine
    for k, (y, z) in enumerate(((0.3, 7.05), (1.7, 7.0), (3.1, 6.95))):
        m.box(f"Spine{k}", size=(1.0, 1.1, 0.8), at=(0, y, z), role="gold" if k % 2 else "gold_light", chamfer=0.3, taper=(0.6, 0.6), rot=(-25, 0, 0))
    # ---- queue (rig Tail) : relevee vers l'arriere, houppe de meches d'or
    m.beam("Tail0", start=(0, 4.5, 6.2), end=(0, 5.7, 7.0), role="stone", width=0.72, depth=0.72, chamfer=0.12, taper=0.9)
    m.beam("Tail1", start=(0, 5.6, 6.95), end=(0, 6.15, 8.3), role="stone", width=0.66, depth=0.66, chamfer=0.1, taper=0.9)
    m.box("TailTuft", size=(1.5, 1.5, 1.5), at=(0, 6.25, 8.85), role="gold", chamfer=0.5)
    for k, (dy, dz, rx) in enumerate(((0.0, 0.8, 0), (0.6, 0.55, -50), (0.8, -0.1, -100))):
        m.box(f"TailT{k}", size=(1.05, 0.95, 1.3), at=(0, 6.25 + dy, 8.85 + dz), role="gold_light" if k == 1 else "gold_dark", chamfer=0.3,
              taper=(0.55, 0.6), rot=(rx, 0, 0))
    # ---- peinture : muscles graves sur epaules et cuisses, rides des coussinets, gravures de la boule
    for host, face in (("Shoulder_L", "left"), ("Thigh_L", "left"), ("Shoulder_R", "right"), ("Thigh_R", "right")):
        for u in (-0.45, 0.05, 0.55):
            m.line(host, face, [(u, 0.65), (u - 0.25, -0.1), (u - 0.1, -0.6)], "stone_dark", 1)
    for side in ("left", "right"):
        for k, u in enumerate((-0.9, 0.0, 0.9)):
            m.line("Barrel", side, [(u - 0.3, 0.35), (u, 0.6), (u + 0.3, 0.35)], "stone_dark", 1)
    for f in ("front", "left", "top"):
        m.line("Ball", f, [(-0.6, 0.6), (-0.3, 0.3), (-0.6, 0.0)], "gold", 1)
        m.line("Ball", f, [(0.6, -0.6), (0.3, -0.3), (0.6, 0.0)], "gold", 1)
    for u in (-0.25, 0.0, 0.25):
        m.rect("Pad_L", "front", (u, 0.05), (0.1, 0.1), "stone_dark")
        m.rect("Pad_R", "front", (u, 0.05), (0.1, 0.1), "stone_dark")
    return m


L13 = ropilot.model("R13_T5", px=8, reset=True)
L13.reference(REF5)
L13.palette(**PAL5)
build_t5(L13)
print(L13.build()); print(L13.check()); print(L13.compare()["report"])


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


close_gaps_r13("R13_T5")


def save_only_r13(col_name, fname):
    # n'ecrit que la collection de la creature (pas les modeles des autres taches ni les references)
    col = bpy.data.collections[col_name]
    bpy.data.libraries.write(os.path.join(ropilot.FILES_DIR, fname), {col}, fake_user=True, compress=True)


save_only_r13("R13_T5", "R13_T5.blend")

GROUPS_T5 = {'Head': ['Head', 'Bridge', 'Pad_*', 'Nose', 'MouthIn', 'Fang*', 'Eye_*', 'Iris_*', 'Pupil_*', 'Shine_*', 'Shine2_*', 'Brow_*',
                      'Diadem', 'Gem', 'GemSide_*', 'ManeMass', 'ManeS*', 'ManeB*', 'ManeNape*', 'Mane?', 'Mane1?'],
             'Jaw': ['Jaw', 'LowFang*', 'Beard'],
             'EarL': ['Ear_L', 'EarIn_L'], 'EarR': ['Ear_R', 'EarIn_R'],
             'LegFL': ['Shoulder_L', 'ElbowTuft_L', 'FUpper_L', 'FArm_L', 'FPaw_L', 'FBand_L', 'FToe*_L', 'FClaw*_L'],
             'LegFR': ['Shoulder_R', 'ElbowTuft_R', 'FUpper_R', 'FArm_R', 'FPaw_R', 'FBand_R', 'FToe*_R', 'FClaw*_R'],
             'LegBL': ['Thigh_L', 'BShin_L', 'HockTuft_L', 'BCannon_L', 'BPaw_L', 'BBand_L', 'BToe*_L', 'BClaw*_L'],
             'LegBR': ['Thigh_R', 'BShin_R', 'HockTuft_R', 'BCannon_R', 'BPaw_R', 'BBand_R', 'BToe*_R', 'BClaw*_R'],
             'Tail': ['Tail0', 'Tail1', 'TailTuft', 'TailT*']}
# --- suite : exec(rigjoin.py), rig_clear avant chaque reconstruction, rig_join("R13_T5", GROUPS_T5),
# save_only_r13("R13_T5", "R13_T5_rig.blend"), import -> Work_R13_T5b, CreatureRig.Install(workspace.Work_R13_T5b, "R13_T5", nil, true)
# joints corriges dans le repere du Core : Head (0, 6.9, -2.2) au cou (Install le mettait a 5.6 de haut), Jaw (0, 6.42, -5.6) a la
# charniere, EarL/R (+-1.05, 9.55, -4.85) a la base, LegFL/FR (+-1.85, 5.7, -2.0) a l'epaule (Install avancait FR a -3.2),
# LegBL/BR (+-1.95, 5.6, 3.15) a la hanche, Tail (0, 6.2, 4.6) a la racine (Install la decalait de 0.75 en x)
# La criniere suit la tete (Head) ; la boule de jade reste dans Body (la patte avant gauche la quitte en marchant).
# compare() final : face 0.78, dos 0.78, gauche 0.62, dessus 0.57 : la reference est un lion gardien ASSIS sur un socle ;
# ici debout sur quatre pattes (style stomp), plus long de profil, socle supprime.
# 141 pieces kit, 12 pieces Studio (Body, Body2 neon, EarL/R, Head, Head__Glow, Jaw, LegFL/FR/BL/BR, Tail), hauteur 12.23
# Portrait : rbxassetid://108681301498276
