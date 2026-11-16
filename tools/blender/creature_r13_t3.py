# Golden Scarab (R13_T3, Rare) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R13_Refs/Ref_R13_T3_*.png) ;
# une 2e generation (« chubby ») sortait un scarabee debout : la 1re (plate, longues pattes) a ete gardee.
# Scarabee rond et brillant en or : carapace bombee en quatre etages de prismes a 12 cotes allonges, coupee ensuite
# en deux elytres (bisect, fente de 0,07 qui se voit, face de coupe or sombre) ; corselet plus petit devant ; tete
# d'or a grands yeux separes a deux reflets, sourire, joues, deux petites cornes recourbees vers l'avant, antennes
# a massue d'or ; six pattes jade sombre (cuisse, jambe, griffe d'or) ; dessous jade sombre.
# Motifs graves : bord or sombre, frise d'incrustations de jade, chevrons, rosace au sommet ; gemmes turquoise
# lumineuses serties d'or sombre (une par elytre, une sur le corselet).
# compare() final (avant la coupe) : face 0.71, dos 0.71, gauche 0.70, dessus 0.66 (47 pieces + 4 demi-etages,
# 1 184 triangles, 3,63 x 4,05 x 1,76). Ecart voulu : la reference est plate, aux pattes longues et fines (elles
# plafonnent la face) ; la carapace est ici plus bombee et ronde, comme demande (« scarabee rond et brillant »).
# check_model : 0 piece flottante ou cachee, 0 arete ouverte ; chevauchements voulus (pattes et ventre sous la
# carapace).
# --- suite : make_t3(), exec(rigjoin.py), rig_join("R13_T3", GROUPS_T3), save R13_T3_rig.blend, import ->
# Work_R13_T3, CreatureRig.Install(workspace.Work_R13_T3, "R13_T3", nil, true), puis joints corriges dans le repere
# du Core (x = -x Blender, y = z Blender, z = y Blender + 0.09) : LegFL/FR (+-0.58, 0.72, -0.61), LegL/R
# (+-0.6, 0.72, 0.39), LegBL/BR (+-0.58, 0.72, 1.34) (hanches sous la carapace), Head (0, 0.85, -1.15) (cou),
# WingL/WingR (+-0.04, 1.68, 0.54) (charniere au sommet de la fente : les elytres s'ouvrent pendant la figure).
# Gemmes : WingL__Glow / WingR__Glow (Follow), gemme du corselet = Body2 (Neon).
# Portrait : rbxassetid://116359762015268 (Renders/Creatures/R13_T3.png).
# Ce fichier est autonome (le Blender de Ropilot est partage : ne pas compter sur des variables globales).
import ropilot, bpy, bmesh, os, math, mathutils
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R13_Refs")
REF3 = {v: os.path.join(R, f"Ref_R13_T3_{v}.png") for v in ("front", "left", "back", "top")}
PAL3 = dict(
    gold=dict(color="#F2C14E", noise=0.025, shade=0.16, top=0.18, mottle=("#f7cd62", 0.25, 4)),
    gold_dark=dict(color="#B8862B", noise=0.025, shade=0.1),
    gold_light=dict(color="#ffe08a", noise=0.02, shade=0.06),
    jade=dict(color="#3FB37F", noise=0.03, shade=0.1),
    jade_dark=dict(color="#1F6E4E", noise=0.03, shade=0.12, top=0.08),
    turq="#3EC9D6",
    eye="#2A2420", white="#ffffff", blush="#f39a8c", mouth="#2A2420",
    glow=dict(color="#3EC9D6", glow=True),
)
SY3 = 1.07     # allongement de la carapace en y
DC = 0.45      # centre de la carapace (y)
DOME = [("Dome0", 1.3, 0.32, 0.62, 1.0), ("Dome1", 1.3, 0.42, 0.99, 0.84), ("Dome2", 1.092, 0.34, 1.37, 0.62), ("Dome3", 0.677, 0.14, 1.61, 0.55)]
PRON = [("Pron0", 0.92, 0.3, 0.66, 1.0), ("Pron1", 0.92, 0.36, 0.99, 0.8), ("Pron2", 0.736, 0.2, 1.27, 0.6)]
LEGS3 = {"F": [(-0.55, -0.7, 0.7), (-1.1, -0.92, 0.8), (-1.38, -1.18, 0.1), (-1.62, -1.42, 0.03)],
         "M": [(-0.58, 0.3, 0.7), (-1.2, 0.32, 0.82), (-1.5, 0.34, 0.1), (-1.8, 0.37, 0.03)],
         "B": [(-0.55, 1.25, 0.7), (-1.1, 1.45, 0.8), (-1.38, 1.65, 0.1), (-1.62, 1.88, 0.03)]}
HY3 = -1.6     # y de la tete


def ext3(a, b, e=0.05):
    a, b = mathutils.Vector(a), mathutils.Vector(b)
    d = (b - a).normalized() * e
    return tuple(a - d), tuple(b + d)


def build_t3(m):
    MR = dict(mirror=True)
    m.box("Belly", size=(1.3, 2.5, 0.42), at=(0, 0.15, 0.64), role="jade_dark", chamfer=0.15)
    # carapace ronde et bombee (coupee ensuite en deux elytres), corselet plus petit devant
    for n, r, h, z, tp in DOME:
        m.prism(n, radius=r, height=h, at=(0, DC / SY3, z), role="gold", sides=12, turn=15, taper=tp, faces={"bottom": "gold_dark"})
    m.scale((1, SY3, 1), names=[d[0] for d in DOME])
    for n, r, h, z, tp in PRON:
        m.prism(n, radius=r, height=h, at=(0, -0.68 / 0.82, z), role="gold", sides=12, turn=15, taper=tp, faces={"bottom": "gold_dark"})
    m.scale((1.18, 0.82, 1), names=[p[0] for p in PRON])
    # tete d'or, grands yeux, deux petites cornes recourbees vers l'avant
    m.box("Head", size=(1.1, 0.72, 0.8), at=(0, HY3, 0.86), role="gold", chamfer=0.18, taper=(0.86, 0.86))
    fy = HY3 - 0.36
    m.box("Eye_L", size=(0.3, 0.06, 0.34), at=(-0.25, fy - 0.01, 0.95), role="eye", chamfer=0.05, **MR)
    m.box("Shine_L", size=(0.12, 0.04, 0.12), at=(-0.3, fy - 0.045, 1.04), role="white", **MR)
    m.box("Shine2_L", size=(0.06, 0.04, 0.06), at=(-0.18, fy - 0.045, 0.87), role="white", **MR)
    m.prism("Horn_L", radius=0.1, height=0.28, at=(-0.17, HY3 - 0.12, 1.33), role="gold_dark", sides=6, taper=0.65, rot=(18, -12, 0), **MR)
    m.prism("HornTip_L", radius=0.065, height=0.26, at=(-0.2, HY3 - 0.25, 1.55), role="gold_dark", sides=6, taper=0.0, rot=(45, -12, 0), **MR)
    # six pattes jade sombre : cuisse, jambe, griffe d'or
    for k, (hip, knee, ankle, toe) in LEGS3.items():
        m.beam(f"Leg{k}A_L", start=hip, end=ext3(hip, knee, 0.06)[1], role="jade_dark", width=0.3, depth=0.3, chamfer=0.07, **MR)
        m.beam(f"Leg{k}B_L", start=ext3(knee, ankle, 0.1)[0], end=ankle, role="jade_dark", width=0.27, depth=0.27, taper=0.8, **MR)
        m.beam(f"Claw{k}_L", start=ext3(ankle, toe, 0.08)[0], end=toe, role="gold", width=0.26, depth=0.14, taper=0.5, **MR)
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


def details_t3(m, col="R13_T3"):
    # a lancer apres un premier build() : les gemmes se posent sur la carapace construite
    MR = dict(mirror=True)
    hits = surf_hits(col, [d[0] for d in DOME], (0, DC, 0.6), [(-0.62, 0.1, 1.0)])
    P, N = mathutils.Vector(hits[0][0]), mathutils.Vector(hits[0][1])
    m.prism("Bezel_L", radius=0.36, height=0.1, at=tuple(P + N * 0.02), role="gold_dark", sides=4, rot=nrot(N), **MR)
    m.prism("Gem_L", radius=0.25, height=0.14, at=tuple(P + N * 0.08), role="glow", sides=4, taper=0.6, rot=nrot(N), **MR)
    hits = surf_hits(col, [p[0] for p in PRON], (0, -0.68, 0.6), [(0, -0.35, 1.0)])
    P, N = mathutils.Vector(hits[0][0]), mathutils.Vector(hits[0][1])
    m.prism("PBezel", radius=0.26, height=0.1, at=tuple(P + N * 0.02), role="gold_dark", sides=4, rot=nrot(N))
    m.prism("PGem", radius=0.18, height=0.12, at=tuple(P + N * 0.07), role="glow", sides=4, taper=0.6, rot=nrot(N))
    # antennes a massue d'or
    m.beam("Antenna_L", start=(-0.4, HY3 - 0.28, 1.0), end=(-0.7, HY3 - 0.4, 1.14), role="jade_dark", width=0.1, depth=0.1, **MR)
    m.box("AntClub_L", size=(0.2, 0.14, 0.22), at=(-0.74, HY3 - 0.42, 1.16), role="gold", chamfer=0.04, rot=(0, 0, -30), **MR)
    return m


def paint_t3(m):
    # gravures : bord or sombre, frise de jade, chevrons, rosace au sommet
    for k in range(12):
        m.rect("Dome0", f"side{k}", (0, -0.07), (2, 0.18), "gold_dark")
        m.line("Dome1", f"side{k}", [(-0.4, 0.15), (0.4, 0.15)], "gold_dark", 1)
        m.stamp("Dome1", f"side{k}", (0, -0.02), ["J.J"], {"J": "jade"}, cell=0.12)
        m.stamp("Dome2", f"side{k}", (0, 0), ["D...D", ".D.D.", "..D.."], {"D": "gold_dark"}, cell=0.07)
        m.rect("Pron0", f"side{k}", (0, -0.06), (2, 0.16), "gold_dark")
        m.stamp("Pron1", f"side{k}", (0, 0.02), ["J"], {"J": "jade"}, cell=0.12)
        m.line("Pron1", f"side{k}", [(-0.4, 0.15), (0.4, 0.15)], "gold_dark", 1)
    m.stamp("Dome3", "top", (0, 0), ["..D..", ".D.D.", "D.J.D", ".D.D.", "..D.."], {"D": "gold_dark", "J": "jade"}, cell=0.1)
    # sourire et joues
    m.stamp("Head", "front", (0, -0.2), ["K....K", ".KKKK."], {"K": "mouth"}, cell=0.06)
    m.rect("Head", "front", (-0.38, -0.13), (0.12, 0.06), "blush")
    m.rect("Head", "front", (0.38, -0.13), (0.12, 0.06), "blush")
    return m


def split_dome(col="R13_T3", gap=0.035):
    # coupe chaque etage de la carapace en deux elytres (x < 0 et x > 0), ecartees de 2 x gap : la fente se voit ;
    # la face de coupe prend l'uv d'une face du dessous (or sombre)
    for n in [d[0] for d in DOME]:
        o = part_obj(col, n)
        o2 = o.copy(); o2.data = o.data.copy()
        for c in o.users_collection:
            c.objects.link(o2)
        for ob, keep_neg, side in ((o, True, "L"), (o2, False, "R")):
            inv = ob.matrix_world.inverted()
            co = inv @ mathutils.Vector((0, 0, 0))
            no = (ob.matrix_world.to_3x3().transposed() @ mathutils.Vector((1, 0, 0))).normalized()
            bm = bmesh.new(); bm.from_mesh(ob.data)
            bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
            uvl = bm.loops.layers.uv.active
            bottom = min(bm.faces, key=lambda f: (ob.matrix_world.to_3x3() @ f.normal).z)
            buv = bottom.loops[0][uvl].uv.copy() if uvl else None
            bmesh.ops.bisect_plane(bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces), plane_co=co, plane_no=no,
                                   clear_outer=keep_neg, clear_inner=not keep_neg)
            bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
            cut = [e for e in bm.edges if e.is_boundary]
            nf = bmesh.ops.holes_fill(bm, edges=cut, sides=0)["faces"]
            if uvl:
                for f in nf:
                    for l in f.loops:
                        l[uvl].uv = buv
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
            bm.to_mesh(ob.data); bm.free()
            ob.location.x += -gap if side == "L" else gap
            ob.name = f"{n}_{side}"
            ob["ropilot_part"] = f"{n}_{side}"


GROUPS_T3 = {'Head': ['Head', 'Eye_*', 'Shine*', 'Horn*', 'Antenna_*', 'AntClub_*'],
             'WingL': ['Dome*_L', 'Bezel_L', 'Gem_L'], 'WingR': ['Dome*_R', 'Bezel_R', 'Gem_R'],
             'LegFL': ['LegF*_L', 'ClawF_L'], 'LegFR': ['LegF*_R', 'ClawF_R'],
             'LegL': ['LegM*_L', 'ClawM_L'], 'LegR': ['LegM*_R', 'ClawM_R'],
             'LegBL': ['LegB*_L', 'ClawB_L'], 'LegBR': ['LegB*_R', 'ClawB_R']}


def make_t3(save=True):
    m = ropilot.model("R13_T3", px=8, reset=True)
    m.reference(REF3); m.palette(**PAL3); build_t3(m)
    m.build()
    details_t3(m); paint_t3(m)
    print(m.build()); print(m.check()); print(m.compare(image=False)["report"])
    split_dome()
    if save:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R13_T3.blend"), copy=True)
    return m
