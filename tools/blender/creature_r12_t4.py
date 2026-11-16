# Glowcap Moth (R12_T4, Epic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R12_Refs/Ref_R12_T4_*.png)
# Papillon de nuit duveteux debout : corps en oeuf octogonal creme, bavette de fourrure, petits pieds bruns,
# abdomen raye lavande qui part vers l'arriere (rig Tail) ; collerette blanche (deux anneaux + 16 touffes) ; tete
# ronde, grands yeux separes a deux reflets, joues roses, petit sourire ; antennes plumeuses violettes a barbes
# lavande et bout turquoise lumineux. Grandes ailes violettes (rig WingL / WingR) faites de lobes octogonaux qui se
# recouvrent (aile avant + pointe + lobe interieur, aile arriere + pointe), bord lavande, bande sombre, nervures
# violet nuit, points lavande ; chapeaux de champignon turquoise lumineux en relief sur les deux faces.
# compare() final : face 0.77, dos 0.77, gauche 0.64, dessus 0.55 (98 pieces, 2 258 triangles, 7,64 x 3,83 x 5,42).
# Ecart voulu : la reference a un corps et un abdomen plus profonds (de profil) et des ailes legerement en biais
# vues du dessus ; ici ailes dans un seul plan (battement propre autour de la racine) et corps plus compact.
# check_model : 0 piece flottante ou cachee, 0 chevauchement profond, 0 arete ouverte ; 44 « gaps » de voisins.
# --- suite : make_t4(), exec(rigjoin.py), rig_join("R12_T4", GROUPS_T4), save R12_T4_rig.blend, import ->
# Work_R12_T4, CreatureRig.Install(workspace.Work_R12_T4, "R12_T4", nil, true), puis joints corriges dans le repere
# du Core (z = y Blender - 0.6) : WingL/WingR (+-0.5, 2.85, 0.02) (racine), Head (0, 2.6, -0.55) (cou),
# Tail (0, 0.85, 0.4) (base de l'abdomen). Antennes et chapeaux lumineux : Head__Glow, WingL__Glow, WingR__Glow.
# Portrait : rbxassetid://121739539800181 (Renders/Creatures/R12_T4.png).
import ropilot, bpy, os, math, mathutils
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R12_Refs")
REF4 = {v: os.path.join(R, f"Ref_R12_T4_{v}.png") for v in ("front", "left", "back", "top")}
PAL4 = dict(
    fur=dict(color="#fdf0d4", noise=0.035, shade=0.1, streaks=("#f2e2c0", 0.35, "v"), top=0.08),
    fur_dark=dict(color="#e8cf9e", noise=0.04, shade=0.1, streaks=("#dcc08a", 0.35, "v")),
    fur_white=dict(color="#fff8ec", noise=0.03, shade=0.08, streaks=("#f2e8d6", 0.3, "v"), top=0.06),
    wing=dict(color="#7a52c8", noise=0.03, shade=0.06, mottle=("#8660d2", 0.25, 4)),
    wing_dark=dict(color="#2c2148", noise=0.03, shade=0.06),
    wing_mid=dict(color="#5a3aa0", noise=0.03, shade=0.06),
    wing_light=dict(color="#b89bff", noise=0.03, shade=0.06),
    stripe=dict(color="#b89bff", noise=0.03, shade=0.12, streaks=("#a88aee", 0.3, "v")),
    leg=dict(color="#6a4a30", noise=0.03, shade=0.1),
    eye="#2c2148", white="#ffffff", blush="#ff9eb0",
    glow=dict(color="#3fe0c0", glow=True),
)
HZ4 = 3.1             # centre de la tete
WY = 0.62             # plan des ailes (y)
ROOT = (0.5, WY, 2.85)    # racine de l'aile droite (la gauche est creee en miroir)
# lobes des ailes : (nom, centre, rayon) ; les lobes secondaires, plus fins, restent caches dans le lobe principal
# la ou ils se recouvrent (pas de faces confondues)
WINGS = [("Fore", (2.25, WY, 3.85), 1.25), ("ForeTip", (3.0, WY, 4.6), 0.82), ("ForeIn", (1.35, WY, 4.25), 0.8),
         ("Hind", (1.9, WY, 1.75), 0.9), ("HindTip", (2.45, WY, 1.2), 0.6)]
GLYPHS = ((2.35, 3.95, 1.25), (3.05, 4.72, 0.72), (1.95, 1.72, 0.92))   # chapeaux lumineux (x, z, taille)


def egg(m, name, r, zb, h_bot, h_mid, h_top, y, role, t_bot=0.78, t_top=0.7):
    # « oeuf » octogonal : base biseautee, milieu droit, haut qui s'affine
    m.prism(name + "Bot", radius=r, height=h_bot, at=(0, y, zb + h_bot / 2), role=role, sides=8, turn=22.5, taper=t_bot, rot=(180, 0, 0))
    m.prism(name, radius=r, height=h_mid, at=(0, y, zb + h_bot + h_mid / 2), role=role, sides=8, turn=22.5)
    m.prism(name + "Top", radius=r, height=h_top, at=(0, y, zb + h_bot + h_mid + h_top / 2), role=role, sides=8, turn=22.5, taper=t_top)


def build_t4(m):
    MR = dict(mirror=True)
    # ---- corps duveteux en oeuf, petits pieds, abdomen raye qui part vers l'arriere (rig Tail)
    egg(m, "Body", 1.25, 0.12, 0.35, 0.95, 0.75, 0.2, "fur", t_top=0.66)
    m.pyramid("Bib", size=(1.1, 0.3, 0.85), at=(0, -1.0, 1.72), role="fur_white", rot=(180, 0, 0))
    m.box("Foot_L", size=(0.42, 0.55, 0.26), at=(-0.45, -0.35, 0.13), role="leg", chamfer=0.1, **MR)
    m.beam("Abdomen", start=(0, 1.0, 0.85), end=(0, 2.05, 0.42), role="stripe", width=1.15, depth=0.8, taper=0.6, chamfer=0.22)
    m.beam("AbdomenTip", start=(0, 2.0, 0.44), end=(0, 2.5, 0.3), role="fur_dark", width=0.68, depth=0.46, taper=0.5, chamfer=0.12)
    # ---- collerette de fourrure : deux anneaux et touffes tout autour
    m.prism("Ruff", radius=1.22, height=0.42, at=(0, 0.1, 2.32), role="fur_white", sides=12, taper=0.88)
    m.prism("Ruff2", radius=1.0, height=0.3, at=(0, 0.1, 2.6), role="fur", sides=12, taper=0.8)
    for k, a in enumerate((105, 130, 155, 180, 205, 230, 255)):
        r = math.radians(a)
        m.box(f"Tuft{k}_L", size=(0.46, 0.44, 0.46), at=(1.2 * math.cos(r), 0.1 + 1.2 * math.sin(r), 2.26), role="fur_white",
              chamfer=0.14, taper=(0.72, 0.72), rot=(0, 0, a), **MR)
    for nm, a in (("TuftF", 270), ("TuftB", 90)):
        r = math.radians(a)
        m.box(nm, size=(0.46, 0.44, 0.46), at=(1.2 * math.cos(r), 0.1 + 1.2 * math.sin(r), 2.26), role="fur_white", chamfer=0.14,
              taper=(0.72, 0.72), rot=(0, 0, a))
    # ---- tete ronde (oeuf octogonal), grands yeux separes a deux reflets, joues, petit sourire
    egg(m, "Head", 0.98, HZ4 - 0.62, 0.25, 0.7, 0.42, 0.0, "fur", t_bot=0.85, t_top=0.62)
    fy = -0.98 * math.cos(math.radians(22.5))
    m.box("Eye_L", size=(0.42, 0.08, 0.52), at=(-0.36, fy - 0.01, HZ4 + 0.02), role="eye", chamfer=0.07, **MR)
    m.box("Shine_L", size=(0.16, 0.05, 0.16), at=(-0.43, fy - 0.055, HZ4 + 0.14), role="white", **MR)
    m.box("Shine2_L", size=(0.08, 0.05, 0.08), at=(-0.27, fy - 0.055, HZ4 - 0.1), role="white", **MR)
    m.box("Blush_L", size=(0.24, 0.04, 0.12), at=(-0.58, fy - 0.005, HZ4 - 0.3), role="blush", **MR)
    m.box("Smile_L", size=(0.08, 0.04, 0.08), at=(-0.09, fy - 0.005, HZ4 - 0.3), role="eye", **MR)
    m.box("SmileMid", size=(0.12, 0.04, 0.07), at=(0, fy - 0.005, HZ4 - 0.36), role="eye")
    # ---- antennes plumeuses : tige violette, barbes lavande de chaque cote, bout lumineux
    a0, a1 = (-0.3, -0.12, HZ4 + 0.62), (-0.95, -0.3, HZ4 + 1.75)
    m.beam("Antenna_L", start=a0, end=a1, role="wing", width=0.13, depth=0.13, **MR)
    for k in range(4):
        t = 0.3 + 0.18 * k
        p = tuple(a0[i] + (a1[i] - a0[i]) * t for i in range(3))
        ln = 0.42 - 0.06 * k
        m.beam(f"BarbO{k}_L", start=p, end=(p[0] - ln * 0.9, p[1], p[2] + ln * 0.15), role="wing_light", width=0.08, depth=0.06, **MR)
        m.beam(f"BarbI{k}_L", start=p, end=(p[0] + ln * 0.55, p[1], p[2] + ln * 0.75), role="wing_light", width=0.08, depth=0.06, **MR)
    m.box("AntTip_L", size=(0.2, 0.2, 0.2), at=a1, role="glow", chamfer=0.05, **MR)
    # ---- ailes (rig WingL / WingR) : lobes octogonaux qui se recouvrent, attaches par des poutres fines
    for nm, c, rad in WINGS:
        th = 0.16 if nm in ("Fore", "Hind") else 0.12
        m.prism(f"{nm}Wing_R", radius=rad, height=th, at=c, role="wing", sides=8, turn=22.5, rot=(90, 0, 0), faces={"sides": "wing_light"}, **MR)
    for nm, c, rad in (WINGS[0], WINGS[3]):
        m.beam(f"{nm}Root_R", start=ROOT, end=c, role="wing_mid", width=0.12, depth=rad * 0.9, **MR)
    # chapeaux de champignon lumineux en relief sur les deux faces des ailes (chapeau en trapeze + pied)
    for k, (cx, cz, s) in enumerate(GLYPHS):
        for side, dy in (("F", -0.085), ("B", 0.085)):
            m.box(f"Glyph{k}{side}_R", size=(0.78 * s, 0.05, 0.36 * s), at=(cx, WY + dy, cz + 0.1 * s), role="glow", taper=(0.5, 1), **MR)
            m.box(f"GlyphStem{k}{side}_R", size=(0.2 * s, 0.05, 0.3 * s), at=(cx, WY + dy, cz - 0.2 * s), role="glow", **MR)
    return m


def paint_t4(m):
    # ailes : bande sombre pres du corps, nervures, points lavande ; « top » = face avant (prisme tourne de 90)
    for side in ("R",):   # le kit reporte la peinture sur l'aile gauche
        sg = 1
        for face in ("top", "bottom"):
            fs = sg if face == "top" else -sg   # u vers l'exterieur de l'aile
            m.rect(f"ForeWing_{side}", face, (-fs * 0.85, -0.25), (0.5, 1.2), "wing_mid")
            m.line(f"ForeWing_{side}", face, [(-fs * 1.0, -0.6), (fs * 0.2, -0.75), (fs * 1.0, -0.45)], "wing_dark", 1)
            m.line(f"ForeWing_{side}", face, [(-fs * 1.0, -0.2), (fs * 1.05, 0.55)], "wing_dark", 1)
            for (u, v) in ((0.85, -0.3), (0.55, 0.8), (-0.3, 0.95)):
                m.rect(f"ForeWing_{side}", face, (fs * u, v), (0.14, 0.14), "wing_light")
            m.rect(f"HindWing_{side}", face, (-fs * 0.6, 0.1), (0.4, 0.9), "wing_mid")
            m.line(f"HindWing_{side}", face, [(-fs * 0.75, 0.3), (fs * 0.75, -0.35)], "wing_dark", 1)
            for (u, v) in ((0.55, 0.45), (0.2, -0.65)):
                m.rect(f"HindWing_{side}", face, (fs * u, v), (0.12, 0.12), "wing_light")
            for (u, v) in ((0.3, 0.3), (-0.25, -0.2)):
                m.rect(f"ForeTipWing_{side}", face, (fs * u, v), (0.12, 0.12), "wing_light")
    # abdomen raye
    for v in (-0.35, 0.0, 0.35):
        m.line("Abdomen", "left", [(v, -0.3), (v, 0.3)], "wing_mid", 1)
        m.line("Abdomen", "right", [(v, -0.3), (v, 0.3)], "wing_mid", 1)
        m.line("Abdomen", "top", [(-0.3, v), (0.3, v)], "wing_mid", 1)
    return m


GROUPS_T4 = {'Head': ['Head', 'HeadBot', 'HeadTop', 'Eye_*', 'Shine*', 'Blush_*', 'Smile*', 'Antenna_*', 'Barb*', 'AntTip_*'],
             'WingL': ['*Wing_L', '*Root_L', 'Glyph*_L'], 'WingR': ['*Wing_R', '*Root_R', 'Glyph*_R'],
             'LegL': ['Foot_L'], 'LegR': ['Foot_R'],
             'Tail': ['Abdomen', 'AbdomenTip']}


def make_t4(save=True):
    m4 = ropilot.model("R12_T4", px=8, reset=True)
    m4.reference(REF4)
    m4.palette(**PAL4)
    build_t4(m4)
    paint_t4(m4)
    print(m4.build()); print(m4.check()); print(m4.compare(image=False)["report"])
    if save:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R12_T4.blend"), copy=True)
    return m4
