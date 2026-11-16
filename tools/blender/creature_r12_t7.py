# Mushroom Mammoth (R12_T7, Cosmic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R12_Refs/Ref_R12_T7_*.png)
# Mammouth colossal a laine violette (meches lavande peintes, franges qui pendent sous les flancs, le poitrail et
# aux genoux), bosse d'epaule haute et dos qui descend vers la croupe ; tete en dome, grands yeux separes a reflets
# et sourcils bienveillants, oreilles (rig EarL / EarR), longue trompe qui s'affine et s'enroule vers l'avant,
# grandes defenses creme recourbees a bague violette ; quatre pattes en colonnes qui s'evasent, ongles creme ;
# sur le dos une foret de champignons geants sur coussins de mousse : grande amanite rouge a points creme, chapeau
# turquoise geant a lamelles lumineuses, chapeaux violets et lavande, chanterelles orange, petits chapeaux
# lumineux ; mousse qui coule sur les flancs ; queue a houppe (rig Tail).
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R12_Refs")
REF7 = {v: os.path.join(R, f"Ref_R12_T7_{v}.png") for v in ("front", "left", "back", "top")}
PAL7 = dict(
    fur=dict(color="#7a52c8", noise=0.035, shade=0.16, mottle=("#6c46b8", 0.3, 4), top=0.12, streaks=("#9d7fe6", 0.25, "v")),
    fur_dark=dict(color="#55389e", noise=0.03, shade=0.14, streaks=("#6a4ab8", 0.25, "v")),
    fur_light=dict(color="#a88af0", noise=0.03, shade=0.12, top=0.1, streaks=("#b89bff", 0.2, "v")),
    skin=dict(color="#8e6ad8", noise=0.025, shade=0.14, top=0.08),
    tusk=dict(color="#f4eedc", noise=0.02, shade=0.14, top=0.12),
    nail=dict(color="#f4eedc", noise=0.015, shade=0.1),
    sole=dict(color="#2c2148", noise=0.02, shade=0.1),
    moss=dict(color="#6fb04a", noise=0.04, shade=0.14, mottle=("#86c45a", 0.35, 3), top=0.15, speckle=("#3e7a32", 0.06)),
    moss_dark=dict(color="#3e7a32", noise=0.035, shade=0.12, mottle=("#4e8c3c", 0.3, 3)),
    amanita=dict(color="#d8382e", noise=0.03, shade=0.14, top=0.12),
    stem=dict(color="#f4eedc", noise=0.025, shade=0.16),
    teal=dict(color="#6ef0d2", noise=0.025, shade=0.14, top=0.15, rim=-0.2),
    violet=dict(color="#7a52c8", noise=0.03, shade=0.14, top=0.18, rim=-0.2),
    lav=dict(color="#b89bff", noise=0.03, shade=0.14, top=0.15, rim=-0.2),
    chant=dict(color="#f09a3c", noise=0.03, shade=0.14, top=0.12),
    band=dict(color="#2e3e7a", noise=0.02, shade=0.1, top=0.2),
    white="#ffffff", iris="#2fbfa0", eye="#1a1230", shine="#ffffff", mouth="#3a1f4a",
    glow=dict(color="#3fe8c4", glow=True),
)
MR = dict(mirror=True)
# trompe : points du front vers le bout enroule vers l'avant ; largeurs
TR = [(0, -8.75, 11.0), (0, -9.55, 9.0), (0, -10.0, 7.0), (0, -10.15, 5.2), (0, -10.4, 3.7), (0, -11.1, 2.75), (0, -11.85, 3.0), (0, -12.15, 3.75)]
TW = [2.2, 1.95, 1.7, 1.5, 1.3, 1.12, 0.95, 0.8]
# defense gauche : de la gencive vers la pointe relevee et rentree
# defense gauche : courbe de Bezier (gencive -> descend vers l'avant -> remonte en se rentrant), 8 segments
_P0, _P1, _P2 = (-1.5, -8.4, 9.9), (-2.7, -12.4, 5.9), (-1.6, -12.9, 10.4)
TK = [tuple((1 - t) ** 2 * _P0[j] + 2 * (1 - t) * t * _P1[j] + t * t * _P2[j] for j in range(3)) for t in [k / 8 for k in range(9)]]
TKW = [1.08 - 0.09 * k for k in range(9)]


def add(a, b, k=1.0):
    return tuple(a[i] + b[i] * k for i in range(3))


def amanita(m, name, at, s, tilt=(0, 0, 0)):
    x, y, z = at
    m.prism(name + "Stem", radius=0.3 * s, height=1.2 * s, at=(x, y, z + 0.45 * s), role="stem", sides=6, taper=0.82, rot=tilt, solo=True)
    m.box(name + "Ring", size=(0.75 * s, 0.75 * s, 0.14 * s), at=(x + tilt[1] * 0.012 * s, y - tilt[0] * 0.012 * s, z + 0.8 * s), role="stem",
          chamfer=0.05 * s, rot=tilt, solo=True)
    m.box(name + "Cap", size=(1.7 * s, 1.7 * s, 0.75 * s), at=(x + tilt[1] * 0.02 * s, y - tilt[0] * 0.02 * s, z + 1.3 * s), role="amanita",
          chamfer=0.3 * s, taper=(0.55, 0.55), rot=tilt, solo=True)
    return name + "Cap"


def cap(m, name, at, s, role, glow_gills=False, tilt=(0, 0, 0)):
    # chapeau large (prisme a 8 pans) sur pied creme ; lamelles lumineuses dessous si glow_gills
    x, y, z = at
    m.prism(name + "Stem", radius=0.24 * s, height=1.1 * s, at=(x, y, z + 0.4 * s), role="stem", sides=6, taper=0.8, rot=tilt, solo=True)
    c = (x + tilt[1] * 0.018 * s, y - tilt[0] * 0.018 * s, z + 1.05 * s)
    m.prism(name + "Cap", radius=0.85 * s, height=0.42 * s, at=c, role=role, sides=8, taper=0.5, rot=tilt, solo=True)
    if glow_gills:
        m.prism(name + "Gills", radius=0.8 * s, height=0.08 * s, at=add(c, (0, 0, -0.22 * s)), role="glow", sides=8, rot=tilt, solo=True)


def glowcap(m, name, at, s, tilt=(0, 0, 0)):
    x, y, z = at
    m.prism(name + "Stem", radius=0.2 * s, height=0.9 * s, at=(x, y, z + 0.3 * s), role="stem", sides=5, taper=0.8, rot=tilt, solo=True)
    m.prism(name + "Cap", radius=0.62 * s, height=0.42 * s, at=(x + tilt[1] * 0.011 * s, y - tilt[0] * 0.011 * s, z + 0.85 * s),
            role="glow", sides=6, taper=0.45, rot=tilt, solo=True)


def moss(m, name, at, w, l, h=0.7, rot=(0, 0, 0)):
    x, y, z = at
    m.box(name, size=(w, l, h), at=at, role="moss", chamfer=0.3, taper=(0.85, 0.85), faces={"bottom": "moss_dark"}, rot=rot, solo=True)
    m.box(name + "a", size=(w * 0.4, l * 0.42, h * 0.8), at=(x - w * 0.24, y + l * 0.18, z + h * 0.5), role="moss", chamfer=0.2,
          taper=(0.75, 0.75), rot=(rot[0], rot[1], 17), solo=True)
    m.box(name + "b", size=(w * 0.3, l * 0.32, h * 0.6), at=(x + w * 0.28, y - l * 0.26, z + h * 0.4), role="moss_dark", chamfer=0.15,
          taper=(0.75, 0.75), rot=(rot[0], rot[1], -22), solo=True)


def build_t7(m):
    # ---- corps : poitrail massif, bosse d'epaule haute, tonneau, croupe plus basse ; ventre plus sombre
    m.box("Chest", size=(8.2, 6.0, 7.0), at=(0, -2.7, 9.0), role="fur", chamfer=1.8, faces={"bottom": "fur_dark"})
    m.box("Hump", size=(6.8, 4.8, 2.8), at=(0, -2.4, 12.6), role="fur", chamfer=1.1, taper=(0.75, 0.8))
    m.box("Barrel", size=(8.0, 4.6, 6.4), at=(0, 1.6, 8.9), role="fur", chamfer=1.7, faces={"bottom": "fur_dark"}, slope=(0, -0.8))
    m.box("Rump", size=(7.6, 4.2, 5.6), at=(0, 4.6, 8.2), role="fur", chamfer=1.7, faces={"bottom": "fur_dark"}, slope=(0, -0.7))
    # franges de laine : sous les flancs entre les pattes, barbe sous le poitrail
    for k, y in enumerate((-1.2, 0.1, 1.4, 2.6)):
        m.box(f"Fringe{k}_L", size=(0.8, 0.9, 3.0), at=(-3.75, y, 5.9), role="fur_dark" if k % 2 else "fur_light", chamfer=0.2,
              taper=(1, 1.7), **MR)
    for k, x in enumerate((-1.9, -0.65)):
        m.box(f"Beard{k}_L", size=(1.1, 0.9, 3.2), at=(x, -5.5, 5.9), role="fur_light" if k % 2 else "fur_dark", chamfer=0.2, taper=(1.3, 1.4), **MR)
    # ---- tete (rig Head) : crane en dome, front, joues, levre ; yeux de face, sourcils bienveillants
    m.box("Skull", size=(5.0, 4.4, 5.6), at=(0, -6.6, 11.7), role="fur", chamfer=0.95)
    m.box("Crown", size=(4.2, 3.6, 1.2), at=(0, -6.5, 14.0), role="fur", chamfer=0.5, taper=(0.85, 0.85))
    m.box("Dome", size=(3.8, 3.2, 2.0), at=(0, -6.3, 14.6), role="fur", chamfer=0.7, taper=(0.75, 0.75))
    m.box("Lip", size=(1.8, 1.0, 0.6), at=(0, -8.9, 9.2), role="skin", chamfer=0.2)
    m.box("Eye_L", size=(1.15, 0.12, 1.25), at=(-1.25, -8.84, 12.2), role="white", **MR)
    m.box("Iris_L", size=(0.85, 0.1, 0.95), at=(-1.17, -8.88, 12.13), role="iris", **MR)
    m.box("Pupil_L", size=(0.5, 0.08, 0.6), at=(-1.13, -8.92, 12.1), role="eye", **MR)
    m.box("Shine_L", size=(0.26, 0.06, 0.26), at=(-1.3, -8.95, 12.35), role="shine", **MR)
    m.box("Shine2_L", size=(0.12, 0.06, 0.12), at=(-0.97, -8.95, 11.9), role="shine", **MR)
    m.beam("Brow_L", start=(-1.9, -8.82, 13.1), end=(-0.7, -8.82, 13.3), role="fur_dark", width=0.32, depth=0.2, **MR)
    # oreilles (rig EarL / EarR)
    m.box("Ear_L", size=(0.75, 1.7, 2.7), at=(-2.92, -6.2, 12.0), role="fur", chamfer=0.45, taper=(1, 1.4), rot=(0, 0, -18), **MR)
    m.box("EarTuft_L", size=(0.8, 1.2, 1.1), at=(-2.95, -6.1, 10.45), role="fur_dark", chamfer=0.3, taper=(1, 1.3), rot=(0, 0, -18), **MR)
    # trompe qui s'affine et s'enroule ; bagues de plis plus claires ; bout plus clair
    for i in range(len(TR) - 1):
        w0, w1 = TW[i], TW[i + 1]
        d = tuple(TR[i + 1][j] - TR[i][j] for j in range(3))
        L = math.sqrt(sum(c * c for c in d))
        m.beam(f"Trunk{i}", start=TR[i], end=add(TR[i + 1], d, 0.2 / L if i < len(TR) - 2 else 0), role="fur" if i < 3 else "skin", width=w0, depth=w0, taper=w1 / w0, chamfer=0.18 * w0)
    for i in (1, 2, 3, 4):
        d = tuple(TR[i + 1][j] - TR[i][j] for j in range(3))
        m.beam(f"TrunkRing{i}", start=TR[i], end=add(TR[i], d, 0.12),
               role="fur_dark", width=TW[i] + 0.08, depth=TW[i] + 0.08, chamfer=0.1)
    m.box("TrunkTip", size=(0.95, 0.5, 0.95), at=add(TR[-1], (0, -0.05, 0.25)), role="skin", chamfer=0.2)
    # defenses creme recourbees, bague violette a la base
    for i in range(len(TK) - 1):
        # segments qui se chevauchent (prolonges de 0.08 de chaque cote) : une courbe continue, sans articulations
        d = tuple(TK[i + 1][j] - TK[i][j] for j in range(3))
        L = math.sqrt(sum(c * c for c in d))
        a = add(TK[i], d, -0.08 / L if i else 0)
        b = add(TK[i + 1], d, 0.08 / L if i < len(TK) - 2 else 0)
        m.beam(f"Tusk{i}_L", start=a, end=b, role="tusk", width=TKW[i], depth=TKW[i], taper=TKW[i + 1] / TKW[i], chamfer=0.1, **MR)
    m.prism("TuskBand_L", radius=0.68, height=0.45, at=add(TK[0], (-0.12, -0.27, -0.42)), role="band", sides=6, rot=(-55, 0, 0), **MR)
    # touffe de mousse et chapeaux lumineux sur le dome (suivent la tete)
    m.box("HeadMoss", size=(2.4, 2.0, 0.5), at=(0.35, -6.0, 15.7), role="moss", chamfer=0.2, taper=(0.85, 0.85), solo=True)
    glowcap(m, "HeadCap", (0.7, -5.9, 15.85), 1.0, tilt=(0, 12, 0))
    glowcap(m, "HeadCap2", (-0.5, -6.4, 15.8), 0.7, tilt=(8, -14, 0))
    # ---- pattes (rig LegFL/FR/BL/BR) : colonnes qui s'evasent, frange de laine au genou, pied a semelle et ongles
    for nm, y, up, uh in (("F", -4.1, (3.0, 3.1, 3.6), 7.1), ("B", 4.5, (3.1, 3.5, 4.4), 7.3)):
        m.box(f"{nm}Upper_L", size=up, at=(-2.8, y, uh), role="fur", chamfer=0.8, **MR)
        m.beam(f"{nm}Lower_L", start=(-2.8, y, 5.6), end=(-2.8, y - 0.15, 1.0), role="fur", width=2.65, depth=2.8, taper=1.1, chamfer=0.5, **MR)
        m.box(f"{nm}Shag_L", size=(3.05, 3.2, 1.5), at=(-2.8, y, 4.3), role="fur_dark", chamfer=0.4, taper=(1.0, 1.0), **MR)
        m.box(f"{nm}Foot_L", size=(3.25, 3.4, 1.1), at=(-2.8, y - 0.2, 0.55), role="skin", chamfer=0.35, faces={"bottom": "sole"}, **MR)
        for k, dx in enumerate((-0.95, 0.0, 0.95)):
            m.box(f"{nm}Nail{k}_L", size=(0.68, 0.3, 0.52), at=(-2.8 + dx, y - 1.93, 0.37), role="nail", chamfer=0.1, **MR)
    # ---- queue a houppe (rig Tail)
    m.beam("Tail0", start=(0, 6.6, 9.2), end=(0, 7.4, 7.4), role="fur", width=0.8, depth=0.8, taper=0.75, chamfer=0.12)
    m.box("TailTuft", size=(0.95, 0.95, 1.3), at=(0, 7.55, 6.9), role="fur_dark", chamfer=0.3, taper=(0.6, 0.6), rot=(-20, 0, 0))
    # ---- foret de champignons sur le dos, sur des coussins de mousse
    moss(m, "MossHump", (0.0, -2.6, 13.95), 5.0, 4.0, h=0.8)
    moss(m, "MossBack", (0.4, 1.6, 12.0), 5.6, 4.2, h=0.8, rot=(-10, 0, 0))
    moss(m, "MossRump", (-0.5, 4.6, 10.85), 4.8, 3.6, h=0.75, rot=(-12, 0, 0))
    for k, (y, ln, z) in enumerate(((-3.2, 2.0, 12.0), (-0.6, 2.6, 11.6), (1.9, 2.2, 11.2), (4.2, 1.8, 10.2))):
        m.box(f"MossDrip{k}_L", size=(0.55, 1.2, ln), at=(-3.92 + 0.04 * k, y, z - ln / 2 + 0.3), role="moss", chamfer=0.16, taper=(1, 1.9),
              faces={"bottom": "moss_dark"}, **MR)
    # chapeau turquoise geant a lamelles lumineuses (le plus haut), grande amanite rouge, chapeaux violets et lavande
    cap(m, "GiantCap", (-0.9, -2.7, 14.5), 3.6, "teal", glow_gills=True, tilt=(4, -6, 0))
    amanita(m, "AmGiant", (1.5, 1.5, 12.3), 2.9, tilt=(-6, 10, 0))
    cap(m, "VioCap", (-1.9, 1.0, 12.4), 2.0, "violet", glow_gills=True, tilt=(-4, -14, 0))
    cap(m, "LavCap", (1.9, -1.6, 14.3), 1.6, "lav", tilt=(6, 16, 0))
    cap(m, "VioCap2", (0.3, 4.8, 11.1), 1.6, "violet", tilt=(-12, 6, 0))
    amanita(m, "AmSmall", (-1.9, 4.2, 11.2), 1.1, tilt=(-12, -12, 0))
    cap(m, "TealCap", (2.6, 3.0, 11.6), 1.3, "teal", tilt=(-10, 18, 0))
    cap(m, "LavCap2", (-2.6, -3.4, 14.0), 1.2, "lav", tilt=(4, -20, 0))
    for k, (x, y, z, s, t) in enumerate(((2.7, -3.6, 13.6, 0.9, (6, 22, 0)), (-2.5, -1.0, 13.3, 0.8, (0, -20, 0)), (3.2, 4.8, 10.6, 0.85, (-10, 22, 0)),
                                         (-0.9, 3.1, 11.75, 0.75, (-10, -6, 0)), (1.0, 6.0, 10.3, 0.7, (-16, 6, 0)), (-2.9, 5.6, 10.2, 0.65, (-14, -18, 0)))):
        glowcap(m, f"Glow{k}", (x, y, z - (0.12 if k == 0 else 0)), s, tilt=t)
    for k, (x, y, z) in enumerate(((3.0, 0.6, 12.05), (-3.0, 2.8, 11.35))):
        m.prism(f"ChantStem{k}", radius=0.25, height=0.7, at=(x, y, z), role="chant", sides=5, taper=1.4, solo=True)
        m.prism(f"ChantCap{k}", radius=0.62, height=0.35, at=(x, y, z + 0.48), role="chant", sides=6, taper=0.6, solo=True)
    # ---- peinture : points creme des amanites, meches de laine, plis de trompe, ongles
    for capn, s in (("AmGiantCap", 2.9), ("AmSmallCap", 1.1)):
        for (u, v) in ((-0.25, 0.15), (0.2, -0.2), (0.05, 0.3), (-0.3, -0.25)):
            m.rect(capn, "top", (u * s, v * s), (0.2 * s, 0.2 * s), "stem")
        for f in ("front", "left", "right", "back"):
            m.rect(capn, f, (-0.35 * s, 0.0), (0.2 * s, 0.18 * s), "stem")
            m.rect(capn, f, (0.3 * s, 0.05 * s), (0.16 * s, 0.16 * s), "stem")
    for host in ("Chest", "Barrel", "Rump"):
        for f in ("left", "right"):
            for k, u in enumerate((-1.4, -0.3, 0.8, 1.7)):
                m.line(host, f, [(u, 1.4 - 0.3 * (k % 2)), (u + 0.25, -1.2)], "fur_light", 2)
    m.line("Skull", "front", [(-1.5, -1.6), (-0.9, -1.9)], "fur_dark", 2)
    m.line("Skull", "front", [(1.5, -1.6), (0.9, -1.9)], "fur_dark", 2)
    return m


m7 = ropilot.model("R12_T7", px=8, reset=True)
m7.reference(REF7)
m7.palette(**PAL7)
build_t7(m7)
print(m7.build()); print(m7.check()); print(m7.compare()["report"])
ropilot.check_model(collection="R12_T7", max_lines=8)


def save_only(col_name, fname):
    # n'ecrit que la collection de la creature (pas les modeles des autres taches ni les references)
    col = bpy.data.collections[col_name]
    bpy.data.libraries.write(os.path.join(ropilot.FILES_DIR, fname), {col}, fake_user=True, compress=True)


save_only("R12_T7", "R12_T7.blend")

GROUPS_T7 = {'Head': ['Skull', 'Crown', 'Dome', 'Lip', 'Eye_*', 'Iris_*', 'Pupil_*', 'Shine_*', 'Shine2_*', 'Brow_*', 'Trunk*',
                      'Tusk*', 'HeadMoss', 'HeadCap*'],
             'EarL': ['Ear_L', 'EarTuft_L'], 'EarR': ['Ear_R', 'EarTuft_R'],
             'LegFL': ['FUpper_L', 'FLower_L', 'FShag_L', 'FFoot_L', 'FNail*_L'], 'LegFR': ['FUpper_R', 'FLower_R', 'FShag_R', 'FFoot_R', 'FNail*_R'],
             'LegBL': ['BUpper_L', 'BLower_L', 'BShag_L', 'BFoot_L', 'BNail*_L'], 'LegBR': ['BUpper_R', 'BLower_R', 'BShag_R', 'BFoot_R', 'BNail*_R'],
             'Tail': ['Tail0', 'TailTuft']}
# --- suite : exec(rigjoin.py), rig_join("R12_T7", GROUPS_T7), save_only("R12_T7", "R12_T7_rig.blend"), import -> Work_R12_T7,
# CreatureRig.Install(workspace.Work_R12_T7, "R12_T7", nil, true), puis joints corriges dans le repere du Core
# joints corriges dans le repere du Core : Head (0, 11.0, -2.5) au cou (Install le mettait sous la trompe),
# EarL/R (+-2.5, 12.0, -3.9) a la base, Tail (0, 9.2, 8.85) a la racine ; pattes laissees (epaule 8.19, hanche 8.74)
# Pas de Jaw (figure charge, pas de rugissement) ; trompe et defenses suivent la tete.
# compare() final : face 0.76, dos 0.76, gauche 0.70, dessus 0.77 : la reference est plus large (oreilles et flancs evases)
# et plus courte ; ici defenses plus longues en courbe de Bezier et foret de champignons plus haute.
# Portrait : rbxassetid://101907040751364
