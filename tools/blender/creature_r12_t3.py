# Toadstool Frog (R12_T3, Rare) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R12_Refs/Ref_R12_T3_*.png)
# Grenouille vert mousse dodue assise : grosse tete plate, menton et ventre creme, grand sourire et langue,
# joues roses ; grands yeux a deux reflets sur deux bosses en haut de la tete ; chapeau d'amanite rouge en trois
# etages incline vers l'arriere (ne cache pas les yeux), pied creme a collerette, lamelles creme dessous, pois
# blancs en relief poses par lancer de rayon ; taches de mousse sombre peintes ; cuisses repliees, pieds et mains
# palmes a trois doigts ; trois petits champignons turquoise lumineux sur coussins de mousse sur le dos.
# compare() final : face 0.88, dos 0.88, gauche 0.76, dessus 0.86 (61 pieces, 2 036 triangles, hauteur 4,29).
# check_model : 0 piece flottante ou cachee, 0 arete ouverte ; 5 chevauchements voulus (cuisses et menton dans le
# corps, collerette sur le pied du chapeau), voisins proches signales comme « gaps » (pois, coussins de mousse).
# --- suite : make_t3(), exec(rigjoin.py), rig_join("R12_T3", GROUPS_T3), save R12_T3_rig.blend, import ->
# Work_R12_T3, CreatureRig.Install(workspace.Work_R12_T3, "R12_T3", nil, true), puis joints corriges dans le repere
# du Core (z = y Blender - 0.115) : Head (0, 1.6, 0.1) (cou), ArmL/ArmR (+-0.78, 1.05, -0.98) (epaules),
# LegL/LegR (+-1.05, 0.8, 0.5) (hanches). Les champignons lumineux deviennent Body2 (Neon).
# Portrait : rbxassetid://107715632682468 (Renders/Creatures/R12_T3.png).
import ropilot, bpy, os, math, mathutils
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R12_Refs")
REF3 = {v: os.path.join(R, f"Ref_R12_T3_{v}.png") for v in ("front", "left", "back", "top")}
PAL3 = dict(
    skin=dict(color="#6fb04a", noise=0.03, shade=0.16, mottle=("#79bd52", 0.25, 4), top=0.14),
    skin_dark=dict(color="#3e7a32", noise=0.03, shade=0.12),
    skin_light=dict(color="#9ad46a", noise=0.03, shade=0.1, top=0.1),
    belly=dict(color="#f4eedc", noise=0.025, shade=0.1, top=0.06),
    cap=dict(color="#d8382e", noise=0.025, shade=0.14, mottle=("#e04538", 0.2, 4), top=0.14),
    cap_dark=dict(color="#a82820", noise=0.025, shade=0.1),
    gill=dict(color="#efe2c4", noise=0.03, shade=0.1, streaks=("#d9c8a2", 0.4, "v")),
    spot=dict(color="#fffaf0", noise=0.02, shade=0.04, top=0.04),
    stem=dict(color="#f4eedc", noise=0.02, shade=0.12),
    eye="#2c2148", white="#ffffff", blush="#ff9eb0", tongue="#ff7a90", mouth="#2c2148",
    glow=dict(color="#3fe0c0", glow=True),
)
HZ3 = 1.95                 # centre de la tete
CP = (0, 0.3, 2.95)        # base du chapeau
CT = 10.0                  # inclinaison du chapeau vers l'arriere (degres)


def capc(h):
    t = math.radians(CT)
    return (CP[0], CP[1] + h * math.sin(t), CP[2] + h * math.cos(t))


def build_t3(m):
    MR = dict(mirror=True)
    # corps dodu assis, dos arrondi qui descend, ventre creme
    m.box("Body", size=(2.3, 2.4, 1.6), at=(0, 0.45, 0.88), role="skin", chamfer=0.6, taper=(0.8, 0.72), faces={"bottom": "skin_dark"})
    m.box("Belly", size=(1.5, 0.3, 1.15), at=(0, -0.62, 0.85), role="belly", chamfer=0.25, taper=(0.85, 1))
    # tete large et plate, menton creme, yeux sur deux bosses en haut de la tete
    m.box("Head", size=(2.4, 1.85, 1.05), at=(0, -0.35, HZ3), role="skin", chamfer=0.48, taper=(0.9, 0.84))
    m.box("Chin", size=(2.0, 1.45, 0.4), at=(0, -0.5, HZ3 - 0.42), role="belly", chamfer=0.18)
    m.prism("EyeBump_L", radius=0.48, height=0.6, at=(-0.66, -0.72, 2.55), role="skin", sides=8, turn=22.5, taper=0.82, **MR)
    m.box("Eye_L", size=(0.46, 0.08, 0.5), at=(-0.66, -1.17, 2.56), role="eye", chamfer=0.07, **MR)
    m.box("Shine_L", size=(0.18, 0.05, 0.18), at=(-0.74, -1.215, 2.68), role="white", **MR)
    m.box("Shine2_L", size=(0.08, 0.05, 0.08), at=(-0.57, -1.215, 2.44), role="white", **MR)
    # chapeau d'amanite : pied creme a collerette, chapeau en trois etages incline vers l'arriere
    m.prism("CapStem", radius=0.62, height=0.75, at=(0, 0.25, 2.62), role="stem", sides=8, turn=22.5, taper=0.9)
    m.prism("CapRing", radius=0.74, height=0.14, at=(0, 0.25, 2.78), role="gill", sides=8, turn=22.5)
    m.prism("CapBrim", radius=1.62, height=0.45, at=capc(0.22), role="cap", sides=10, taper=0.9, rot=(-CT, 0, 0), faces={"bottom": "gill"})
    m.prism("CapDome", radius=1.46, height=0.5, at=capc(0.66), role="cap", sides=10, taper=0.72, rot=(-CT, 0, 0))
    m.prism("CapTop", radius=1.05, height=0.34, at=capc(1.07), role="cap", sides=10, taper=0.5, rot=(-CT, 0, 0))
    # pattes arriere repliees, grands pieds palmes, bras avant
    m.box("Thigh_L", size=(0.8, 1.5, 0.9), at=(-1.05, 0.55, 0.5), role="skin", chamfer=0.3, **MR)
    m.box("Foot_L", size=(0.8, 0.95, 0.2), at=(-1.15, -0.45, 0.1), role="skin_light", chamfer=0.06, **MR)
    m.box("Arm_L", size=(0.38, 0.42, 1.05), at=(-0.78, -0.87, 0.62), role="skin", chamfer=0.12, rot=(0, -6, 0), **MR)
    m.box("Hand_L", size=(0.6, 0.55, 0.16), at=(-0.82, -1.12, 0.08), role="skin_light", chamfer=0.05, **MR)
    for k, dx in enumerate((-0.25, 0.0, 0.25)):
        m.box(f"Toe{k}_L", size=(0.18, 0.3, 0.12), at=(-1.15 + dx * 1.1, -1.0, 0.06), role="skin_light", chamfer=0.04, **MR)
        m.box(f"Finger{k}_L", size=(0.16, 0.24, 0.1), at=(-0.82 + dx, -1.46, 0.05), role="skin_light", chamfer=0.03, **MR)
    return m


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
    nx, ny, nz = n
    return (math.degrees(math.asin(max(-1, min(1, -ny)))), math.degrees(math.atan2(nx, nz)), 0)


# pois blancs du chapeau (direction depuis le coeur du chapeau, rayon, miroir)
SPOTS_T3 = [((0, 0, 1), 0.26, False), ((0, -1, 0.35), 0.24, False), ((0, 1, 0.5), 0.24, False),
            ((-0.6, -0.55, 0.75), 0.22, True), ((-1, 0.1, 0.35), 0.26, True), ((-0.55, 0.65, 0.65), 0.2, True),
            ((-0.4, 0.05, 0.95), 0.16, True), ((-0.8, -0.8, 0.1), 0.16, True), ((-0.75, 0.75, 0.05), 0.15, True)]
# petits champignons lumineux et coussins de mousse sur le dos (direction depuis le centre du corps)
BACK_T3 = [((-0.45, 0.7, 0.6), 0.2, 0.26, "glow", True), ((0, 1, 0.45), 0.16, 0.22, "glow", False)]


def details_t3(m, col="R12_T3"):
    cc = capc(0.45)
    hits = surf_hits(col, ["CapBrim", "CapDome", "CapTop"], cc, [s[0] for s in SPOTS_T3])
    for i, (spec, hit) in enumerate(zip(SPOTS_T3, hits)):
        d, r, mir = spec
        if hit is None:
            print("miss spot", i)
            continue
        p, n = hit
        P, N = mathutils.Vector(p), mathutils.Vector(n)
        m.prism(f"Spot{i}" + ("_L" if mir else ""), radius=r, height=0.08, at=tuple(P + N * 0.02), role="spot", sides=8, turn=22.5,
                taper=0.8, rot=nrot(N), mirror=mir)
    hits = surf_hits(col, ["Body"], (0, 0.45, 0.9), [s[0] for s in BACK_T3])
    for i, (spec, hit) in enumerate(zip(BACK_T3, hits)):
        d, r, hs, colr, mir = spec
        p, n = hit
        P, N0 = mathutils.Vector(p), mathutils.Vector(n)
        N = (N0 + mathutils.Vector((0, 0, 2.2))).normalized()
        rot = nrot(N)
        tag = f"{i}_L" if mir else f"{i}"
        h1 = r * 0.4
        m.prism(f"Moss{tag}", radius=r * 1.5, height=0.12, at=tuple(P), role="skin_dark", sides=6, taper=0.6, rot=nrot(N0), mirror=mir)
        m.prism(f"Stem{tag}", radius=r * 0.36, height=hs, at=tuple(P + N * (hs / 2 - 0.1)), role="stem", sides=6, rot=rot, mirror=mir)
        m.prism(f"Shroom{tag}", radius=r, height=h1, at=tuple(P + N * (hs - 0.1 + h1 / 2 - 0.02)), role=colr, sides=8, taper=0.45,
                turn=22.5, rot=rot, mirror=mir)
    return m


def paint_t3(m):
    # grand sourire, langue, joues, taches de mousse sombre sur le dos, lamelles sous le chapeau
    m.line("Head", "front", [(-0.78, 0.0), (-0.55, -0.13), (-0.28, -0.2), (0, -0.22), (0.28, -0.2), (0.55, -0.13), (0.78, 0.0)], "mouth", 1)
    m.stamp("Head", "front", (0, -0.3), ["TT", "TT"], {"T": "tongue"}, cell=0.1)
    m.rect("Head", "front", (-0.86, 0.14), (0.2, 0.1), "blush")
    m.rect("Head", "front", (0.86, 0.14), (0.2, 0.1), "blush")
    m.stamp("Head", "front", (0, 0.2), ["K.K"], {"K": "skin_dark"}, cell=0.08)
    for (u, v, r_) in ((-0.5, 0.3, 0.2), (0.45, -0.2, 0.24), (0.0, 0.55, 0.16), (-0.2, -0.45, 0.14)):
        m.blob("Body", "top", (u, v), r_, "skin_dark", seed=int(10 * (u + v)) + 7)
    for face, sg in (("left", 1), ("right", -1)):
        m.blob("Body", face, (sg * -0.4, 0.15), 0.2, "skin_dark", seed=3)
        m.blob("Thigh_L" if face == "left" else "Thigh_R", face, (sg * -0.2, 0.1), 0.17, "skin_dark", seed=5)
        m.blob("Head", face, (sg * 0.3, 0.1), 0.15, "skin_dark", seed=9)
    m.blob("Head", "top", (0.4, 0.3), 0.14, "skin_dark", seed=2)
    m.blob("Head", "top", (-0.5, 0.45), 0.12, "skin_dark", seed=4)
    return m


GROUPS_T3 = {'Head': ['Head', 'Chin', 'EyeBump_*', 'Eye_*', 'Shine*', 'Cap*', 'Spot*'],
             'ArmL': ['Arm_L', 'Hand_L', 'Finger*_L'], 'ArmR': ['Arm_R', 'Hand_R', 'Finger*_R'],
             'LegL': ['Thigh_L', 'Foot_L', 'Toe*_L'], 'LegR': ['Thigh_R', 'Foot_R', 'Toe*_R']}


def make_t3(save=True):
    m3 = ropilot.model("R12_T3", px=8, reset=True)
    m3.reference(REF3)
    m3.palette(**PAL3)
    build_t3(m3)
    m3.build()
    details_t3(m3)
    paint_t3(m3)
    print(m3.build()); print(m3.check()); print(m3.compare(image=False)["report"])
    if save:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R12_T3.blend"), copy=True)
    return m3
