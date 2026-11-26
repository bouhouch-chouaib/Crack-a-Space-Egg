# Décors du couloir en low-poly (27 nov.), au kit de Ropilot (ropilot.model, px = 8, picots dans la texture),
# comme les astéroïdes et les monstres : prismes, boîtes chanfreinées, cristaux, peinture au pixel. Ils
# remplacent les décors en pièces simples (boules, cylindres) de server/CorridorDecor.
# À lancer avec ropilot_blender_run_python :  CK = {"bpy": bpy, "ropilot": ropilot}; exec(open(chemin).read(), CK)
# puis CK["build"](["Spire", ...]) : chaque modèle est construit dans sa collection « Dec_<Nom> » et ses pièces
# sont fusionnées en « <Nom>__Body » (tout ce qui est fixe), « <Nom>__Glow » (néon) et, pour ce qui bouge,
# « <Nom>__<Groupe> » (préfixe du nom de pièce : wingL, wingR, spin, tail, seg...).
# CK["batch"]("CK_Lot1", [...]) range les modèles côte à côte dans une collection pour un seul import.
# Repère : +Z en haut, l'avant du modèle est -Y (il regarde +Z dans Roblox, vers le centre du couloir).
# Hauteur visée : environ 12 studs (le jeu les agrandit d'anneau en anneau).
# Les couleurs sont un peu plus foncées que voulu : l'import les éclaircit.
import math
import random

MODELS = {}
MOVING = ("wingL", "wingR", "spin", "tail", "seg", "jaw", "finL", "finR")


def model(fn):
    MODELS[fn.__name__] = fn
    return fn


def M(name, studs=True):
    return ropilot.model("Dec_" + name, px=8, reset=True, symmetric=False, studs=studs)


def rock_roles(base, dark, light, **more):
    roles = dict(
        rock=dict(color=base, noise=0.035, mottle=(dark, 0.2, 4), shade=0.18, top=0.15),
        rockd=dict(color=dark, noise=0.03, shade=0.18, top=0.12),
        rockl=dict(color=light, noise=0.03, shade=0.12, top=0.14))
    roles.update(more)
    return roles


def plain(color, **kw):
    d = dict(color=color, noise=0.03, shade=0.15, top=0.14)
    d.update(kw)
    return d


def glow(color):
    return dict(color=color, glow=True)


# 1. DUST BELT ----------------------------------------------------------------------------------------

@model
def Spire():
    # aiguille de roche penchée, strates peintes, éclats d'ambre
    m = M("Spire")
    m.palette(**rock_roles("#8A6A4E", "#6A4F3C", "#A88463", band="#57402F",
                           amber=plain("#D9952B", top=0.22), glow=glow("#FFAE2B")))
    S = m.surface
    m.prism("base", radius=4.0, height=2.0, at=(0, 0, 1.0), role="rockd", sides=7, taper=0.82, turn=10)
    m.prism("s1", radius=3.0, height=4.4, at=(0.1, 0, 4.2), role="rock", sides=6, taper=0.8, shear=(0.5, 0.2), turn=25)
    m.prism("s2", radius=2.3, height=4.2, at=(0.6, 0.2, 8.4), role="rockl", sides=6, taper=0.72, shear=(0.5, -0.3), turn=5)
    m.prism("s3", radius=1.6, height=4.0, at=(1.1, -0.1, 12.4), role="rock", sides=5, taper=0.2, shear=(0.3, 0.1))
    m.box("slabA", size=(3.4, 2.6, 2.2), at=S("s1", "side1", (0, -0.6), sink=0.9), role="rockd", chamfer=0.5, taper=0.7, rot=(0, 0, 20))
    m.box("slabB", size=(2.6, 2.0, 1.8), at=S("s2", "side4", (0, 0.2), sink=0.7), role="rock", chamfer=0.4, taper=0.7)
    m.prism("shardA", radius=0.9, height=3.4, at=(-3.2, 1.2, 1.7), role="rockl", sides=5, taper=0.2, shear=(-0.5, 0.2))
    m.prism("shardB", radius=0.7, height=2.4, at=(2.9, -2.2, 1.2), role="rock", sides=5, taper=0.2, shear=(0.4, -0.2))
    m.box("pebA", size=(1.6, 1.3, 1.0), at=(-2.2, -2.6, 0.5), role="rockl", chamfer=0.3, rot=(0, 0, 30))
    m.box("pebB", size=(1.1, 1.0, 0.8), at=(3.4, 1.8, 0.4), role="rockd", chamfer=0.25, rot=(0, 0, -15))
    m.crystal("amb0", radius=0.55, height=2.0, at=S("base", "top", (-1.6, -1.2), sink=0.2), role="amber", sides=6, tip=0.3, solo=True, rot=(-12, 8, 0))
    m.crystal("amb1", radius=0.4, height=1.3, at=S("base", "top", (-2.3, -0.4), sink=0.2), role="amber", sides=6, tip=0.3, solo=True, rot=(8, -20, 0))
    m.crystal("amb2", radius=0.45, height=1.5, at=S("slabA", "top", (0, 0), sink=0.2), role="amber", sides=6, tip=0.3, solo=True)
    m.crystal("tip", radius=0.4, height=1.2, at=(1.75, 0.05, 14.3), role="glow", sides=6, tip=0.4, base_tip=0.4, solo=True)
    m.build()
    for part, sides in (("s1", 6), ("s2", 6)):
        for i in range(sides):
            m.line(part, "side%d" % i, [(-2, 0.6), (2, 0.9)], "band", width=2)
            m.line(part, "side%d" % i, [(-2, -1.0), (2, -0.8)], "band", width=1)
    return m


@model
def Pebbles():
    # petit tas de cailloux qui flottent, tenus par un socle fendu
    m = M("Pebbles")
    m.palette(**rock_roles("#8A6A4E", "#6A4F3C", "#A88463", amber=plain("#D9952B", top=0.22), glow=glow("#FFAE2B")))
    rnd = random.Random(4)
    m.prism("base", radius=3.4, height=1.6, at=(0, 0, 0.8), role="rockd", sides=7, taper=0.8, turn=20)
    m.box("crack", size=(2.6, 0.3, 0.14), at=m.surface("base", "top", (0, 0), sink=0.06), role="glow", rot=(0, 0, 30), solo=True)
    spots = [(0, 0, 3.6, 2.6), (-2.2, 0.6, 5.6, 1.7), (1.9, -0.6, 6.4, 1.9), (0.3, 0.8, 8.6, 1.5), (-1.2, -0.9, 10.4, 1.1), (1.5, 0.5, 11.6, 0.9)]
    for i, (x, y, z, s) in enumerate(spots):
        m.box("peb%d" % i, size=(s * 1.3, s * 1.1, s), at=(x, y, z), role=("rock", "rockl", "rockd")[i % 3], chamfer=s * 0.28,
              taper=0.8, rot=(rnd.uniform(-25, 25), rnd.uniform(-25, 25), rnd.uniform(0, 90)))
    m.crystal("amb", radius=0.5, height=1.6, at=m.surface("peb0", "top", (0.2, 0), sink=0.2), role="amber", sides=6, tip=0.3, solo=True)
    m.crystal("spark", radius=0.35, height=1.0, at=(0.2, 0.2, 13.0), role="glow", sides=6, tip=0.4, base_tip=0.4, solo=True)
    m.build()
    return m


# 2. ICE RING -----------------------------------------------------------------------------------------

@model
def Crystal():
    # grappe de cristaux de glace sur un socle de neige
    m = M("Crystal")
    m.palette(ice=dict(color="#7FBFE6", noise=0.02, shade=0.1, top=0.25), iced=dict(color="#4F93C8", noise=0.02, shade=0.1, top=0.2),
              icel=dict(color="#BFE4F6", noise=0.02, shade=0.08, top=0.2), snow=plain("#D4E4EE", top=0.1, shade=0.1),
              snowd=plain("#A9C4D6"), glow=glow("#6FD8FF"))
    m.prism("base", radius=4.2, height=1.6, at=(0, 0, 0.8), role="snow", sides=8, taper=0.8, turn=12)
    m.box("drift", size=(3.6, 2.6, 1.2), at=(2.2, -1.6, 0.6), role="snow", chamfer=0.45, taper=0.7)
    m.box("drift2", size=(2.8, 2.2, 1.0), at=(-2.6, 1.6, 0.5), role="snowd", chamfer=0.4, taper=0.7)
    specs = [(0, 0.2, 1.5, 11.5, "ice", (0, 0, 0)), (-1.9, -0.6, 1.1, 7.6, "icel", (10, -16, 20)), (1.9, 0.5, 1.2, 8.6, "iced", (-8, 18, 40)),
             (0.6, -1.9, 0.9, 5.4, "icel", (22, 8, 10)), (-0.9, 1.8, 0.9, 6.2, "ice", (-20, -8, 30)), (2.8, -1.4, 0.6, 3.2, "iced", (14, 24, 0)),
             (-2.9, 0.9, 0.6, 3.6, "ice", (-10, -26, 15))]
    for i, (x, y, r, h, role, rot) in enumerate(specs):
        m.crystal("c%d" % i, radius=r, height=h, at=(x, y, 1.0), role=role, sides=6, tip=0.28, solo=True, rot=rot)
    m.crystal("core", radius=0.5, height=1.6, at=(0, 0.2, 12.3), role="glow", sides=6, tip=0.4, base_tip=0.4, solo=True)
    m.build()
    return m


@model
def Snow():
    # bonhomme de neige cubique : écharpe, chapeau, bras en branches
    m = M("Snow")
    m.palette(snow=plain("#D8E6F0", top=0.12, shade=0.12), snowd=plain("#AFC8DA"), coal="#2A2A36", carrot=plain("#D9772A"),
              scarf=plain("#3F86C9", streaks=("#2F6AA6", 0.3, "u")), hat=plain("#39485E"), band=plain("#3F86C9"),
              wood=plain("#6B4B34", streaks=("#523828", 0.3, "v")), glow=glow("#6FD8FF"))
    m.prism("base", radius=3.8, height=1.0, at=(0, 0, 0.5), role="snowd", sides=8, taper=0.85)
    m.box("b1", size=(5.4, 5.0, 4.4), at=(0, 0, 3.0), role="snow", chamfer=1.1, taper=0.9)
    m.box("b2", size=(4.0, 3.8, 3.4), at=(0, 0, 6.6), role="snow", chamfer=0.9, taper=0.9)
    m.box("head", size=(3.2, 3.0, 2.8), at=(0, 0, 9.5), role="snow", chamfer=0.7)
    m.box("scarf", size=(3.5, 3.3, 0.7), at=(0, 0, 8.2), role="scarf", chamfer=0.15)
    m.box("scarfEnd", size=(0.9, 0.4, 2.2), at=(1.0, -1.75, 7.2), role="scarf", rot=(8, 0, -8))
    m.box("brim", size=(3.6, 3.4, 0.4), at=(0, 0, 11.0), role="hat", chamfer=0.1)
    m.box("hatTop", size=(2.3, 2.2, 2.0), at=(0, 0, 12.2), role="hat", chamfer=0.2, taper=0.92)
    m.box("hatBand", size=(2.5, 2.4, 0.5), at=(0, 0, 11.5), role="band")
    m.pyramid("nose", size=(0.6, 0.6, 1.6), at=m.surface("head", "front", (0, -0.2), sink=0.1), role="carrot")
    m.beam("armL", (-2.0, 0, 7.2), (-4.4, -0.4, 8.6), role="wood", width=0.4, taper=0.6)
    m.beam("armL2", (-3.6, -0.3, 8.1), (-4.2, -0.2, 9.4), role="wood", width=0.28, taper=0.6)
    m.beam("armR", (2.0, 0, 7.2), (4.4, -0.4, 8.2), role="wood", width=0.4, taper=0.6)
    m.beam("armR2", (3.6, -0.3, 7.9), (4.6, -0.1, 9.0), role="wood", width=0.28, taper=0.6)
    m.build()
    m.rect("head", "front", (-0.75, 0.5), (0.5, 0.5), "coal")
    m.rect("head", "front", (0.75, 0.5), (0.5, 0.5), "coal")
    for i, x in enumerate((-0.9, -0.45, 0, 0.45, 0.9)):
        m.rect("head", "front", (x, -0.85 - (0.12 if abs(x) < 0.6 else 0)), (0.25, 0.25), "coal")
    for z in (0.9, 0.0, -0.9):
        m.rect("b2", "front", (0, z), (0.5, 0.5), "coal")
    return m


# 3. MAGMA FIELD --------------------------------------------------------------------------------------

@model
def Volcano():
    # petit volcan à gradins, cratère de lave, coulées lumineuses
    m = M("Volcano")
    m.palette(**rock_roles("#4A3B34", "#352A25", "#5C4A40", ash=plain("#57504C"), ember="#9A4418", soot="#231B18",
                           glow=glow("#FF6A14")))
    S = m.surface
    m.prism("base", radius=6.2, height=2.6, at=(0, 0, 1.3), role="rockd", sides=8, taper=0.78, turn=10)
    m.prism("mid", radius=4.8, height=3.4, at=(0, 0, 4.3), role="rock", sides=8, taper=0.72, turn=30)
    m.prism("top", radius=3.4, height=3.2, at=(0.2, 0, 7.6), role="rockl", sides=7, taper=0.62, shear=(0.3, 0.1), turn=5)
    m.prism("rim", radius=2.3, height=1.2, at=(0.45, 0.1, 9.8), role="ash", sides=7, taper=1.12, turn=5)
    m.prism("lava", radius=1.7, height=0.3, at=(0.45, 0.1, 10.35), role="glow", sides=7, turn=5, solo=True)
    m.box("bumpA", size=(3.4, 2.8, 2.2), at=S("base", "side1", (0, 0.2), sink=1.0), role="rock", chamfer=0.6, taper=0.7)
    m.box("bumpB", size=(2.8, 2.4, 1.8), at=S("mid", "side5", (0, 0), sink=0.8), role="rockd", chamfer=0.5, taper=0.7)
    # coulées de lave sur la face avant
    m.box("flow0", size=(0.7, 3.0, 0.14), at=S("top", "side5", (0, -0.2), sink=0.06), role="glow", solo=True)
    m.box("flow1", size=(0.6, 3.0, 0.14), at=S("mid", "side6", (0.2, 0), sink=0.06), role="glow", solo=True)
    m.box("flow2", size=(0.5, 2.2, 0.14), at=S("base", "side6", (-0.3, 0.1), sink=0.06), role="glow", solo=True)
    m.box("flow3", size=(0.5, 2.6, 0.14), at=S("mid", "side2", (0, 0.2), sink=0.06), role="glow", solo=True)
    for i, (x, y, r, h) in enumerate(((-4.6, -3.0, 0.8, 2.2), (4.9, 2.4, 0.7, 1.8), (-3.6, 4.0, 0.6, 1.5))):
        m.prism("col%d" % i, radius=r, height=h, at=(x, y, h / 2), role="rockd", sides=6)
    m.build()
    m.blob("mid", "side0", (0, 0.4), 0.9, "soot", seed=2)
    m.blob("base", "side3", (0.4, 0), 1.1, "soot", seed=5)
    m.line("top", "side5", [(-0.5, 1.2), (0.5, -1.4)], "ember", width=4)
    return m


@model
def LavaRock():
    # bloc de basalte fendu : colonnes hexagonales et fissures de lave
    m = M("LavaRock")
    m.palette(**rock_roles("#4A3B34", "#352A25", "#5C4A40", basalt=dict(color="#3A3534", noise=0.025, shade=0.2, top=0.22, rim=-0.15),
                           ember="#9A4418", glow=glow("#FF6A14")))
    S = m.surface
    rnd = random.Random(7)
    m.prism("base", radius=4.6, height=3.0, at=(0, 0, 1.5), role="rockd", sides=7, taper=1.15, turn=15)
    m.prism("mid", radius=5.2, height=3.2, at=(0, 0, 4.6), role="rock", sides=7, taper=0.7, turn=15, shear=(0.3, -0.2))
    for i, (x, y, h, r) in enumerate(((-1.6, 1.2, 9.6, 1.3), (0.1, 1.9, 11.4, 1.25), (1.6, 0.9, 8.0, 1.2), (-0.4, -0.2, 7.0, 1.1), (2.6, -0.6, 5.8, 1.0),
                                      (-2.9, -0.2, 6.2, 1.0))):
        m.prism("col%d" % i, radius=r, height=h, at=(x, y, h / 2 + 0.6), role="basalt", sides=6, turn=rnd.uniform(0, 60))
    cr = [("mid", "side5", (-1.2, -0.8), (1.0, 0.9)), ("mid", "side6", (-0.9, 0.7), (0.9, -0.6)), ("base", "side5", (-0.8, -0.3), (0.9, 0.4)),
          ("base", "side0", (-0.7, 0.5), (0.8, -0.5)), ("mid", "side3", (-0.8, -0.5), (0.9, 0.6))]
    for i, (host, face, a, b) in enumerate(cr):
        du, dv = b[0] - a[0], b[1] - a[1]
        m.box("lava%d" % i, size=(math.hypot(du, dv), 0.3, 0.12), at=S(host, face, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), sink=0.06),
              role="glow", rot=(0, 0, math.degrees(math.atan2(dv, du))), solo=True)
    m.build()
    for host, face, a, b in cr:
        m.line(host, face, [a, b], "ember", width=5)
    return m


# FUSION ET LOTS ----------------------------------------------------------------------------------------

def join(name):
    col = bpy.data.collections["Dec_" + name]
    groups = {}
    for o in list(col.all_objects):
        if o.type != "MESH":
            continue
        key = "Body"
        if "glow" in o.material_slots[0].material.name:
            key = "Glow"
        for pre in MOVING:
            if o.name.startswith(pre):
                # « wingL », « spin2 »... : chaque préfixe (avec son chiffre éventuel) reste une pièce à part
                tail = o.name[len(pre):]
                digits = ""
                for ch in tail:
                    if ch.isdigit():
                        digits += ch
                    else:
                        break
                key = pre[0].upper() + pre[1:] + digits
        groups.setdefault(key, []).append(o)
    out = []
    for key, objs in groups.items():
        if len(objs) > 1:
            with bpy.context.temp_override(active_object=objs[0], selected_editable_objects=objs, object=objs[0]):
                bpy.ops.object.join()
        objs[0].name = name + "__" + key
        out.append(objs[0].name)
    return out


def build(names):
    report = []
    for n in names:
        m = MODELS[n]()
        info = m.build()
        problems = m.check()
        report.append("%s : %s | %s | %s" % (n, info, problems, join(n)))
    return "\n".join(report)


def batch(batch_name, names, gap=6.0):
    # range les modèles côte à côte (le long de X) dans une collection, pour un seul import
    col = bpy.data.collections.get(batch_name)
    if col is None:
        col = bpy.data.collections.new(batch_name)
        bpy.context.scene.collection.children.link(col)
    x = 0.0
    layout = []
    for n in names:
        src = bpy.data.collections["Dec_" + n]
        objs = [o for o in src.all_objects if o.type == "MESH"]
        lo = min(min((o.matrix_world @ v.co).x for v in o.data.vertices) for o in objs)
        hi = max(max((o.matrix_world @ v.co).x for v in o.data.vertices) for o in objs)
        dx = x - lo
        for o in objs:
            o.location.x += dx
            for c in list(o.users_collection):
                c.objects.unlink(o)
            col.objects.link(o)
        layout.append((n, round(dx, 3)))
        x += (hi - lo) + gap
    return layout
