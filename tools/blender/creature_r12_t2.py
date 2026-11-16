# Mushroom Hedgehog (R12_T2, Uncommon) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R12_Refs/Ref_R12_T2_*.png)
# Herisson rond : corps en trois tranches octogonales (avant, milieu, croupe qui s'affinent) au manteau brun
# ecorce raye de piquants clairs peints ; visage creme en coin, museau pointu, nez violet nuit, grands yeux
# separes a deux reflets, joues roses, petites oreilles rondes ; quatre pattes courtes aux orteils creme,
# petite queue. Les piquants sont remplaces par 16 champignons (pied creme, chapeau en deux etages qui s'arrondit,
# lamelles creme dessous) qui poussent vers le haut : amanites rouges a pois blancs, chanterelles orange,
# lavande, et 7 petits chapeaux turquoise lumineux ; coussinets de mousse au pied de six d'entre eux.
# Les champignons sont poses par lancer de rayon sur le manteau construit (surf_hits), d'ou deux build().
import ropilot, bpy, os, math, mathutils
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R12_Refs")
REF2 = {v: os.path.join(R, f"Ref_R12_T2_{v}.png") for v in ("front", "left", "back", "top")}
PAL2 = dict(
    coat=dict(color="#6a4a30", noise=0.035, shade=0.16, streaks=("#57391f", 0.35, "v"), top=0.12),
    coat_dark=dict(color="#4e3420", noise=0.03, shade=0.12),
    quill=dict(color="#94704a", noise=0.02),
    cream=dict(color="#f4eedc", noise=0.025, shade=0.1, top=0.06),
    cream_dark=dict(color="#e2d4b4", noise=0.03, shade=0.1),
    stem=dict(color="#f4eedc", noise=0.02, shade=0.12),
    red=dict(color="#d8382e", noise=0.025, shade=0.12, top=0.1),
    orange=dict(color="#f09a3c", noise=0.025, shade=0.12, top=0.1, speckle=("#ffd9a0", 0.08)),
    lav=dict(color="#b89bff", noise=0.025, shade=0.12, top=0.1, speckle=("#e6dcff", 0.08)),
    moss=dict(color="#6fb04a", noise=0.05, shade=0.1, mottle=("#3e7a32", 0.35, 3), top=0.1),
    eye="#2c2148", white="#ffffff", blush="#ff9eb0", nose="#2c2148",
    glow=dict(color="#3fe0c0", glow=True),
)
BZ = 1.45          # hauteur de l'axe du corps
BR = 1.42          # rayon du corps octogonal


def part_obj(col, part):
    for o in bpy.data.collections[col].all_objects:
        if (o.get("ropilot_part") or o.name.split(".")[0]) == part:
            return o


def surf_hits(col, parts, center, dirs):
    # point et normale de la surface des pieces `parts`, vue depuis `center` dans chaque direction
    objs = [part_obj(col, p) for p in parts]
    out = []
    for d in dirs:
        d = mathutils.Vector(d).normalized()
        start = mathutils.Vector(center) + d * 6
        best = None
        for o in objs:
            inv = o.matrix_world.inverted()
            ok, loc, nrm, idx = o.ray_cast(inv @ start, (inv.to_3x3() @ (-d)).normalized())
            if ok:
                w = o.matrix_world @ loc
                dist = (w - start).length
                if best is None or dist < best[0]:
                    best = (dist, tuple(w), tuple((o.matrix_world.to_3x3() @ nrm).normalized()))
        out.append(best[1:] if best else None)
    return out


def nrot(n):
    # rot=(x, y, 0) du kit qui couche l'axe z d'une piece sur la direction n
    nx, ny, nz = n
    return (math.degrees(math.asin(max(-1, min(1, -ny)))), math.degrees(math.atan2(nx, nz)), 0)


def build_t2(m):
    MR = dict(mirror=True)
    m.prism("Body", radius=BR, height=1.0, at=(0, 0.3, BZ), role="coat", sides=8, turn=22.5, rot=(90, 0, 0))
    m.prism("BodyFront", radius=BR, height=0.5, at=(0, -0.45, BZ), role="coat", sides=8, turn=22.5, rot=(90, 0, 0), taper=0.74)
    m.prism("BodyBack", radius=BR, height=0.7, at=(0, 1.15, BZ), role="coat", sides=8, turn=22.5, rot=(-90, 0, 0), taper=0.6)
    m.box("Belly", size=(1.1, 1.8, 0.3), at=(0, 0.3, 0.3), role="cream_dark", chamfer=0.1)
    m.box("Chest", size=(0.8, 0.5, 0.6), at=(0, -0.75, 0.6), role="cream_dark", chamfer=0.2, taper=(0.9, 0.8))
    # visage creme en coin, museau pointu
    m.box("Head", size=(1.44, 1.0, 1.2), at=(0, -1.0, 1.2), role="cream", chamfer=0.32, axis="y", taper=(0.6, 0.6))
    m.box("Snout", size=(0.54, 0.6, 0.42), at=(0, -1.74, 1.02), role="cream", chamfer=0.11, axis="y", taper=(0.4, 0.46))
    m.box("Nose", size=(0.22, 0.13, 0.19), at=(0, -2.04, 1.04), role="nose", chamfer=0.05)
    m.prism("Ear_L", radius=0.15, height=0.12, at=(-0.58, -1.02, 1.66), role="coat_dark", sides=8, turn=22.5, rot=(90, 0, -25), **MR)
    m.prism("EarIn_L", radius=0.08, height=0.04, at=(-0.585, -1.09, 1.66), role="blush", sides=8, turn=22.5, rot=(90, 0, -25), **MR)
    # yeux separes, deux reflets chacun
    m.box("Eye_L", size=(0.24, 0.08, 0.34), at=(-0.27, -1.5, 1.28), role="eye", chamfer=0.04, **MR)
    m.box("Shine_L", size=(0.11, 0.05, 0.11), at=(-0.31, -1.545, 1.37), role="white", **MR)
    m.box("Shine2_L", size=(0.05, 0.05, 0.05), at=(-0.22, -1.545, 1.2), role="white", **MR)
    for n, y in (("LegF", -0.45), ("LegB", 0.95)):
        m.box(n + "_L", size=(0.44, 0.5, 0.5), at=(-0.62, y, 0.25), role="coat_dark", chamfer=0.14, faces={"bottom": "cream_dark"}, **MR)
    m.box("Tail", size=(0.3, 0.3, 0.26), at=(0, 1.62, 0.78), role="coat_dark", chamfer=0.08, rot=(-30, 0, 0))
    return m


# direction depuis le centre du dos, rayon du chapeau, hauteur du pied, couleur, miroir
SHROOMS_T2 = [
    ((0, 0.15, 1), 0.36, 0.42, "red", False),
    ((0, 0.95, 0.75), 0.3, 0.38, "orange", False),
    ((0, 1, 0.25), 0.2, 0.3, "glow", False),
    ((0, -0.45, 1), 0.26, 0.34, "lav", False),
    ((-0.55, -0.3, 0.8), 0.3, 0.4, "red", True),
    ((-0.85, 0.25, 0.5), 0.3, 0.38, "lav", True),
    ((-0.5, 0.8, 0.5), 0.27, 0.36, "red", True),
    ((-1, -0.3, 0.2), 0.24, 0.32, "orange", True),
    ((-0.4, 0.35, 0.95), 0.2, 0.32, "glow", True),
    ((-0.75, 0.85, 0.15), 0.2, 0.28, "glow", True),
    ((-1, 0.5, 0.0), 0.22, 0.3, "red", True),
    ((-0.25, 0.75, 0.9), 0.18, 0.3, "lav", True),
    ((-0.75, -0.05, 0.85), 0.18, 0.3, "orange", True),
    ((-1, -0.1, -0.15), 0.16, 0.26, "lav", True),
    ((-0.3, -0.1, 1), 0.22, 0.34, "orange", True),
    ((-0.62, 0.55, 0.75), 0.2, 0.3, "red", True),
]
MOSSY_T2 = {0, 4, 5, 6, 9, 12}


def mushrooms_t2(m, col="R12_T2", center=(0, 0.3, BZ - 0.1), up=2.2):
    # a lancer apres un premier build() : les champignons se posent sur le manteau construit, pousses vers le haut
    hits = surf_hits(col, ["Body", "BodyFront", "BodyBack"], center, [s[0] for s in SHROOMS_T2])
    caps = []
    for i, (spec, hit) in enumerate(zip(SHROOMS_T2, hits)):
        d, r, hs, colr, mir = spec
        if hit is None:
            print("miss", i)
            continue
        p, n = hit
        N0 = mathutils.Vector(n)
        N = (N0 + mathutils.Vector((0, 0, up))).normalized()
        rot = nrot(N)
        P = mathutils.Vector(p)
        tag = f"{i}_L" if mir else f"{i}"
        h1 = h2 = r * 0.34
        m.prism(f"Stem{tag}", radius=r * 0.36, height=hs, at=tuple(P + N * (hs / 2 - 0.12)), role="stem", sides=6, rot=rot, mirror=mir)
        m.prism(f"Cap{tag}", radius=r * 1.1, height=h1, at=tuple(P + N * (hs - 0.12 + h1 / 2 - 0.02)), role=colr, sides=8, taper=0.78,
                turn=22.5, rot=rot, mirror=mir, faces={"bottom": "cream_dark"} if colr != "glow" else None)
        m.prism(f"Dome{tag}", radius=r * 0.86, height=h2, at=tuple(P + N * (hs - 0.12 + h1 - 0.03 + h2 / 2)), role=colr, sides=8,
                taper=0.45, turn=22.5, rot=rot, mirror=mir)
        caps.append((f"Cap{tag}", f"Dome{tag}", colr, r))
        if i in MOSSY_T2:
            m.prism(f"Moss{tag}", radius=r * 0.8, height=0.14, at=tuple(P), role="moss", sides=6, taper=0.6, rot=nrot(N0), mirror=mir)
    return caps


def paint_t2(m, caps):
    # piquants peints (traits clairs) sur tout le manteau
    for part, faces in (("Body", [f"side{k}" for k in range(8)]), ("BodyFront", [f"side{k}" for k in range(8)]),
                        ("BodyBack", [f"side{k}" for k in range(8)] + ["top"])):
        for f in faces:
            for (u, v) in ((-0.3, 0.2), (0.15, -0.1), (0.35, 0.3), (-0.1, -0.35)):
                m.line(part, f, [(u, v), (u + 0.08, v + 0.14)], "quill", 1)
    # pois blancs des amanites
    for cap, dome, colr, r in caps:
        if colr == "red":
            m.circle(dome, "top", (0, 0), 0.06, "white")
            for k in (1, 3, 5, 7):
                m.circle(dome, f"side{k}", (0, 0), 0.04, "white")
            for k in (0, 2, 4, 6):
                m.circle(cap, f"side{k}", (0, 0), 0.04, "white")
    m.rect("Head", "front", (-0.36, -0.12), (0.16, 0.08), "blush")
    m.rect("Head", "front", (0.36, -0.12), (0.16, 0.08), "blush")
    for n in ("LegF_L", "LegB_L"):
        m.stamp(n, "front", (0, -0.12), ["C.C.C"], {"C": "cream_dark"})
    return m


GROUPS_T2 = {'Head': ['Head', 'Snout', 'Nose', 'Eye_*', 'Shine*'],
             'EarL': ['Ear_L', 'EarIn_L'], 'EarR': ['Ear_R', 'EarIn_R'],
             'LegFL': ['LegF_L'], 'LegFR': ['LegF_R'], 'LegBL': ['LegB_L'], 'LegBR': ['LegB_R'],
             'Tail': ['Tail']}


def make_t2(save=True):
    m2 = ropilot.model("R12_T2", px=8, reset=True)
    m2.reference(REF2)
    m2.palette(**PAL2)
    build_t2(m2)
    m2.build()
    caps = mushrooms_t2(m2)
    paint_t2(m2, caps)
    print(m2.build()); print(m2.check()); print(m2.compare(image=False)["report"])
    ropilot.check_model(collection="R12_T2", max_lines=6)
    if save:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R12_T2.blend"), copy=True)
    return m2


# compare() final : face 0.81, dos 0.81, gauche 0.78, dessus 0.74 (118 pieces, 3 120 triangles, 3,32 x 4,00 x 3,40).
# La reference est une boule compacte de chapeaux colles les uns aux autres ; ici les champignons ont un pied
# visible et des trous entre eux (lisibles comme des champignons, pas comme des gemmes) : la silhouette du dessus
# reste plus etroite. check_model : 0 piece flottante, 0 cachee, 0 arete ouverte ; 62 « gaps » = voisins
# proches qui n'ont pas a se toucher (chapeaux entre eux, reflets des yeux, pattes avant et poitrail).
# --- suite : exec(rigjoin.py), rig_join("R12_T2", GROUPS_T2) -> Body, Body__Glow, EarL, EarR, Head, LegBL, LegBR,
# LegFL, LegFR, Tail ; save R12_T2_rig.blend, import -> Work_R12_T2,
# CreatureRig.Install(workspace.Work_R12_T2, "R12_T2", nil, true), puis joint corrige dans le repere du Core
# (z = y Blender + 0.1) : Head (0, 1.15, -0.5) (cou, Install le mettait sous le menton) ; pattes (+-0.62, 0.46, ...)
# a la hanche, oreilles et queue laissees. Les chapeaux lumineux deviennent Body2 (Neon).
# Portrait : rbxassetid://75101977686374 (Renders/Creatures/R12_T2.png).
