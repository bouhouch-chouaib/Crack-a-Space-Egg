# Couloir, suite : pièces de structure (piliers, arche, îles) et petites créatures volantes.
# À exécuter après corridor_kit.py, _2 et _3, dans le même espace de noms.
# Structure : sans texture, une couleur unie par groupe (« __Trim », « __Dark », « __Glow ») : le jeu la
# reteint aux couleurs de chaque biome (server/CorridorDecor) et pose les picots.
# Créatures : texture au pixel, sans picots (comme les créatures du jeu) ; ce qui bouge reste une pièce à
# part (« __WingL », « __Spin », « __Tail », « __Jaw », « __FinL »...), animée par Critters.client.
import math
import random


def MS(name):
    return ropilot.model("Dec_" + name, px=8, reset=True, symmetric=False, studs=False)


def join_roles(name, m):
    # structure : une pièce par rôle, matière unie (pas de texture : le jeu choisit la couleur)
    col = bpy.data.collections["Dec_" + name]
    groups = {}
    for o in list(col.all_objects):
        if o.type != "MESH":
            continue
        part = m.parts.get(o.get("ropilot_part", o.name)) or m.parts.get(o.name)
        role = (part or {}).get("role", "trim")
        key = "Glow" if "glow" in role else ("Dark" if "dark" in role else "Trim")
        groups.setdefault(key, []).append(o)
    out = []
    greys = {"Trim": (0.72, 0.72, 0.72, 1), "Dark": (0.3, 0.3, 0.3, 1), "Glow": (1, 0.85, 0.3, 1)}
    for key, objs in groups.items():
        if len(objs) > 1:
            with bpy.context.temp_override(active_object=objs[0], selected_editable_objects=objs, object=objs[0]):
                bpy.ops.object.join()
        o = objs[0]
        o.name = name + "__" + key
        mat = bpy.data.materials.new("Plain_" + name + "_" + key)
        mat.use_nodes = True
        bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        bsdf.inputs["Base Color"].default_value = greys[key]
        o.data.materials.clear()
        o.data.materials.append(mat)
        if "roblox_material" in o and key != "Glow":
            del o["roblox_material"]
        out.append("%s(%d)" % (o.name, len(o.data.polygons)))
    return out


def wipe(name):
    col = bpy.data.collections.get("Dec_" + name)
    if col:
        for o in list(col.all_objects):
            bpy.data.objects.remove(o, do_unlink=True)


STRUCT = {}


def struct(fn):
    STRUCT[fn.__name__] = fn
    return fn


def build_struct(names):
    report = []
    for n in names:
        wipe(n)
        m = STRUCT[n]()
        info = m.build()
        report.append("%s : %s | %s" % (n, info["size"], join_roles(n, m)))
    return "\n".join(report)


GREY = dict(trim=dict(color="#B8B8B8", noise=0, shade=0), dark=dict(color="#4C4C4C", noise=0, shade=0), glow=dict(color="#FFD84A", glow=True))


@struct
def PostCap():
    # chapiteau de pilier (4 de large) : corniche à gradins, quatre griffes, pointe lumineuse. Sert en haut, et
    # retourné en bas.
    m = MS("PostCap")
    m.palette(**GREY)
    m.box("neck", size=(4.4, 4.4, 0.9), at=(0, 0, 0.45), role="dark", chamfer=0.2)
    m.box("flare", size=(4.0, 4.0, 1.6), at=(0, 0, 1.7), role="trim", chamfer=0.3, taper=1.4)
    m.box("slab", size=(6.2, 6.2, 0.9), at=(0, 0, 2.95), role="dark", chamfer=0.25)
    m.box("crown", size=(4.6, 4.6, 1.0), at=(0, 0, 3.9), role="trim", chamfer=0.3, taper=0.75)
    for i in range(4):
        a = math.radians(45 + 90 * i)
        m.prism("claw%d" % i, radius=0.55, height=1.6, at=(math.cos(a) * 2.6, math.sin(a) * 2.6, 4.2), role="dark", sides=4, taper=0.2, turn=45)
    m.crystal("tip", radius=0.9, height=2.6, at=(0, 0, 4.3), role="glow", sides=6, tip=0.45, base_tip=0.2, solo=True)
    return m


@struct
def PostShaft():
    # fût de pilier (10 de haut, étiré par le jeu) : huit pans, deux bagues
    m = MS("PostShaft")
    m.palette(**GREY)
    m.prism("shaft", radius=2.0, height=10.0, at=(0, 0, 5.0), role="trim", sides=8, turn=22.5)
    m.prism("ringA", radius=2.3, height=0.5, at=(0, 0, 1.2), role="dark", sides=8, turn=22.5)
    m.prism("ringB", radius=2.3, height=0.5, at=(0, 0, 8.8), role="dark", sides=8, turn=22.5)
    return m


@struct
def PostLamp():
    # lanterne accrochée au pilier, côté couloir (avant = -Y) : potence, cage, flamme
    m = MS("PostLamp")
    m.palette(**GREY)
    m.box("plate", size=(2.6, 0.6, 3.4), at=(0, 0, 0), role="dark", chamfer=0.15)
    m.beam("arm", (0, 0, 1.0), (0, -2.6, 1.6), role="dark", width=0.5)
    m.beam("hang", (0, -2.6, 1.6), (0, -2.6, 0.6), role="dark", width=0.25)
    m.pyramid("roof", size=(2.4, 2.4, 1.0), at=(0, -2.6, 0.6), role="dark")
    m.box("flame", size=(1.5, 1.5, 1.8), at=(0, -2.6, -0.75), role="glow", solo=True)
    for i, (dx, dy) in enumerate(((-0.8, -0.8), (0.8, -0.8), (-0.8, 0.8), (0.8, 0.8))):
        m.beam("bar%d" % i, (dx, -2.6 + dy, -1.7), (dx, -2.6 + dy, 0.2), role="dark", width=0.22)
    m.box("floor", size=(2.0, 2.0, 0.35), at=(0, -2.6, -1.85), role="dark")
    return m


@struct
def ArchBlock():
    # claveau de l'arche du portail (12 de long sur l'axe Y, 4 de large, 3.4 de haut) : bloc biseauté, moulures
    m = MS("ArchBlock")
    m.palette(**GREY)
    m.box("core", size=(4.0, 12.0, 3.4), at=(0, 0, 0), role="trim", chamfer=0.45)
    m.box("bandA", size=(4.5, 1.2, 3.9), at=(0, -5.2, 0), role="dark", chamfer=0.25)
    m.box("bandB", size=(4.5, 1.2, 3.9), at=(0, 5.2, 0), role="dark", chamfer=0.25)
    m.box("inset", size=(4.3, 6.4, 1.6), at=(0, 0, 0), role="dark", chamfer=0.2)
    m.box("gemL", size=(0.5, 1.4, 1.0), at=(-2.2, 0, 0), role="glow", solo=True)
    m.box("gemR", size=(0.5, 1.4, 1.0), at=(2.2, 0, 0), role="glow", solo=True)
    return m


@struct
def Island():
    # petite île flottante (12 de large) : plateau, roche qui se resserre en pointe dessous, éclats
    m = MS("Island")
    m.palette(**GREY)
    m.prism("top", radius=6.0, height=1.4, at=(0, 0, -0.7), role="trim", sides=9, taper=1.06, turn=10)
    m.prism("mid", radius=5.2, height=2.6, at=(0.2, 0, -2.7), role="dark", sides=8, taper=0.62, turn=30, rot=(180, 0, 0))
    m.prism("low", radius=3.2, height=3.0, at=(0.5, 0.2, -5.5), role="dark", sides=7, taper=0.3, rot=(180, 0, 0))
    m.box("chunkA", size=(2.6, 2.2, 1.8), at=(-4.4, 2.0, -2.2), role="dark", chamfer=0.5, taper=0.7, rot=(0, 0, 30))
    m.box("chunkB", size=(2.0, 1.8, 1.4), at=(4.2, -2.6, -2.0), role="trim", chamfer=0.4, taper=0.7)
    m.box("bit0", size=(0.9, 0.8, 0.8), at=(-2.6, -3.6, -6.2), role="dark", chamfer=0.2, rot=(20, 30, 10), solo=True)
    m.box("bit1", size=(0.7, 0.6, 0.6), at=(3.0, 2.8, -7.4), role="trim", chamfer=0.15, rot=(10, 0, 40), solo=True)
    return m


# CRÉATURES ---------------------------------------------------------------------------------------------
# Corps d'environ 3 studs, centré vers z = 2, l'avant en -Y. Le visage est peint sur l'avant.

def face(m, part, dx=0.72, y=0.25, eye=0.75, mouth="smile", ink="ink", white="white", face_name="front"):
    for sx in (-1, 1):
        m.rect(part, face_name, (sx * dx, y), (eye, eye * 1.1), white)
        m.rect(part, face_name, (sx * dx + 0.05 * sx, y - 0.05), (eye * 0.55, eye * 0.7), ink)
        m.rect(part, face_name, (sx * dx - 0.08, y + eye * 0.25), (0.13, 0.13), white)
    if mouth == "smile":
        m.line(part, face_name, [(-0.3, y - 0.75), (-0.12, y - 0.9), (0.12, y - 0.9), (0.3, y - 0.75)], ink, width=1)
    elif mouth == "o":
        m.rect(part, face_name, (0, y - 0.8), (0.3, 0.3), ink)


INK = dict(ink="#1A1824", white="#F2F2EE")


def wing_pair(m, x, z, w, d, role, thick=0.16, y=0.2, taper=(0.45, 1), rot=0):
    # deux ailes plates, larges au corps et pointues au bout
    m.box("wingL", size=(w, d, thick), at=(-x - w / 2, y, z), role=role, taper=taper, axis="x", rot=(0, 0, 180 + rot))
    m.box("wingR", size=(w, d, thick), at=(x + w / 2, y, z), role=role, taper=taper, axis="x", rot=(0, 0, -rot))


@model
def CrPuff():
    # boule de poussière : corps rond en bloc, touffes, petites ailes, antenne à lueur
    m = MS("CrPuff")
    m.palette(body=plain("#B8946A", shade=0.14, top=0.14, mottle=("#9E7C56", 0.2, 3)), tuft=plain("#D8BC92"), belly=plain("#E4D0AC"),
              wing=plain("#E8DCC0"), glow=glow("#FFC44A"), **INK)
    m.box("body", size=(3.0, 2.8, 2.8), at=(0, 0, 2.0), role="body", chamfer=0.8)
    m.box("belly", size=(1.9, 0.4, 1.3), at=(0, -1.3, 1.35), role="belly", chamfer=0.2)
    for i, (x, y, z, r) in enumerate(((-1.2, 0.4, 3.5, 0.5), (0.2, 0.6, 3.7, 0.6), (1.2, 0.2, 3.5, 0.45), (-1.7, 0.8, 2.4, 0.4), (1.7, 0.8, 2.2, 0.4), (0, 1.5, 2.6, 0.5))):
        m.prism("tuft%d" % i, radius=r, height=r * 1.6, at=(x, y, z), role="tuft", sides=4, taper=0.15, shear=(x * 0.12, y * 0.12))
    wing_pair(m, 1.4, 2.4, 1.4, 1.1, "wing")
    m.beam("ant", (0, -0.2, 3.3), (0.2, -0.8, 4.4), role="tuft", width=0.14)
    m.crystal("antTip", radius=0.24, height=0.6, at=(0.2, -0.8, 4.3), role="glow", sides=5, tip=0.4, base_tip=0.4, solo=True)
    m.build()
    face(m, "body", y=0.45)
    return m


@model
def CrSprite():
    # lutin de glace : couronne de cristaux, écharpe, ailes de givre
    m = MS("CrSprite")
    m.palette(body=plain("#6FB4E0", shade=0.12, top=0.2), belly=plain("#C8E8F6"), ice=dict(color="#A8DCF4", noise=0.02, shade=0.08, top=0.25),
              iced=dict(color="#5C9CCC", noise=0.02), scarf=plain("#D8546C"), wing=dict(color="#BFE8F8", noise=0.02, shade=0.05),
              glow=glow("#6FE0FF"), **INK)
    m.box("body", size=(2.8, 2.6, 2.8), at=(0, 0, 2.0), role="body", chamfer=0.7)
    m.box("belly", size=(1.8, 0.4, 1.2), at=(0, -1.2, 1.3), role="belly", chamfer=0.2)
    for i, (x, h, r, rot) in enumerate(((0, 1.9, 0.5, 0), (-0.85, 1.3, 0.38, -18), (0.85, 1.3, 0.38, 18), (-0.4, 1.0, 0.3, -8), (0.45, 1.0, 0.3, 8))):
        m.crystal("crown%d" % i, radius=r, height=h, at=(x, 0.2 if i < 3 else -0.5, 3.3), role="ice" if i % 2 == 0 else "iced", sides=6, tip=0.35, solo=True, rot=(0, rot, 0))
    m.box("scarf", size=(3.0, 2.8, 0.5), at=(0, 0, 1.0), role="scarf", chamfer=0.12)
    m.box("scarfEnd", size=(0.6, 0.3, 1.3), at=(0.9, -1.5, 0.3), role="scarf", rot=(10, 0, -10))
    wing_pair(m, 1.3, 2.3, 2.0, 1.3, "wing", rot=12)
    m.crystal("gem", radius=0.26, height=0.5, at=(0, -1.35, 3.0), role="glow", sides=4, tip=0.5, base_tip=0.5, solo=True, rot=(90, 0, 0))
    m.build()
    face(m, "body", y=0.5)
    return m


@model
def CrBat():
    # chauve-souris de braise : grandes oreilles, ailes à membrane, ventre qui rougeoie
    m = MS("CrBat")
    m.palette(body=plain("#6A2C30", shade=0.18, top=0.12), bodyd=plain("#4A1E24"), wing=plain("#B8552A", streaks=("#8E3E1E", 0.3, "u")),
              ear=plain("#B8552A"), fang="#F2F2EE", glow=glow("#FF8A1E"), **INK)
    m.box("body", size=(2.8, 2.5, 2.7), at=(0, 0, 2.0), role="body", chamfer=0.7)
    m.box("belly", size=(1.4, 0.3, 1.0), at=(0, -1.2, 1.3), role="glow", solo=True)
    m.pyramid("earL", size=(1.0, 0.5, 1.7), at=(-0.9, 0.2, 3.2), role="body", apex=(-0.25, 0))
    m.pyramid("earR", size=(1.0, 0.5, 1.7), at=(0.9, 0.2, 3.2), role="body", apex=(0.25, 0))
    m.pyramid("earInL", size=(0.5, 0.3, 1.0), at=(-0.9, -0.1, 3.25), role="ear", apex=(-0.12, 0))
    m.pyramid("earInR", size=(0.5, 0.3, 1.0), at=(0.9, -0.1, 3.25), role="ear", apex=(0.12, 0))
    # ailes : membrane en deux panneaux avec des pointes
    for side, name in ((-1, "wingL"), (1, "wingR")):
        m.box(name, size=(2.6, 1.9, 0.16), at=(side * 2.6, 0.2, 2.5), role="wing", taper=(0.5, 1), axis="x", rot=(0, 0, 180 if side < 0 else 0))
        m.box(name + "Tip", size=(1.5, 1.2, 0.14), at=(side * 4.5, 0.4, 2.5), role="wing", taper=(0.2, 1), axis="x", rot=(0, 0, 180 if side < 0 else 0))
        m.beam(name + "Bone", (side * 1.3, -0.6, 2.6), (side * 5.0, -0.1, 2.6), role="bodyd", width=0.2, taper=0.4)
    m.box("feetL", size=(0.5, 0.6, 0.5), at=(-0.6, -0.4, 0.5), role="bodyd")
    m.box("feetR", size=(0.5, 0.6, 0.5), at=(0.6, -0.4, 0.5), role="bodyd")
    m.build()
    face(m, "body", y=0.5, mouth=None)
    m.rect("body", "front", (-0.3, -0.35), (0.2, 0.3), "fang")
    m.rect("body", "front", (0.3, -0.35), (0.2, 0.3), "fang")
    return m


@model
def CrJelly():
    # méduse d'étoiles : cloche à facettes, étoile lumineuse dedans, tentacules qui ondulent
    m = MS("CrJelly")
    m.palette(bell=plain("#C860B8", shade=0.12, top=0.2), belll=plain("#E496D6"), skirt=plain("#9A4CC0"), tent=plain("#E496D6"),
              tentd=plain("#9A4CC0"), glow=glow("#FFD84A"), **INK)
    m.prism("rim", radius=1.9, height=0.6, at=(0, 0, 1.6), role="skirt", sides=8, taper=0.94)
    m.prism("bell", radius=1.8, height=1.5, at=(0, 0, 2.65), role="bell", sides=8, taper=0.82)
    m.prism("top", radius=1.48, height=0.9, at=(0, 0, 3.85), role="belll", sides=8, taper=0.5)
    m.box("faceplate", size=(1.9, 0.3, 1.3), at=(0, -1.72, 2.6), role="belll", chamfer=0.1)
    m.crystal("star", radius=0.3, height=0.9, at=(0, 0, 4.2), role="glow", sides=4, tip=0.5, base_tip=0.5, solo=True)
    rnd = random.Random(3)
    for i in range(6):
        a = i / 6 * math.tau
        x, y = math.cos(a) * 1.2, math.sin(a) * 1.2
        l = rnd.uniform(1.6, 2.4)
        m.beam("tail%d_%d_a" % (i % 2, i), (x, y, 1.4), (x * 1.1, y * 1.1, 1.4 - l * 0.5), role="tent" if i % 2 else "tentd", width=0.28, taper=0.8)
        m.beam("tail%d_%d_b" % (i % 2, i), (x * 1.1, y * 1.1, 1.4 - l * 0.5), (x * 0.9, y * 0.9, 1.4 - l), role="tent" if i % 2 else "tentd", width=0.22, taper=0.5)
    m.build()
    face(m, "faceplate", dx=0.5, y=0.1, eye=0.5, mouth="smile")
    return m


@model
def CrChomper():
    # croqueur : presque tout en bouche, mâchoire qui claque, œil sur tige
    m = MS("CrChomper")
    m.palette(body=plain("#4A9A4E", shade=0.16, top=0.16, mottle=("#3A7E40", 0.2, 3)), bodyd=plain("#3A7E40"), mouth=plain("#5A1E38"),
              tooth=plain("#E8E4D4"), wing=plain("#A8D86C"), glow=glow("#9CF04A"), **INK)
    m.box("body", size=(3.2, 2.9, 1.8), at=(0, 0, 2.9), role="body", chamfer=0.6)
    m.box("gullet", size=(2.6, 1.6, 0.4), at=(0, -0.5, 1.95), role="mouth")
    m.box("jaw", size=(3.2, 2.9, 1.1), at=(0, 0, 1.2), role="bodyd", chamfer=0.4)
    m.box("jawIn", size=(2.6, 1.6, 0.3), at=(0, -0.5, 1.7), role="mouth")
    for i, x in enumerate((-1.1, -0.4, 0.4, 1.1)):
        m.pyramid("tooth%d" % i, size=(0.5, 0.4, 0.6), at=(x, -1.2, 2.0), role="tooth", rot=(180, 0, 0), pivot="bottom")
        m.pyramid("jawTooth%d" % i, size=(0.5, 0.4, 0.55), at=(x * 0.86 + 0.2, -1.2, 1.75), role="tooth")
    for sx in (-1, 1):
        m.beam("stalk%d" % sx, (sx * 0.8, -0.4, 3.7), (sx * 1.0, -0.7, 4.5), role="bodyd", width=0.24)
        m.box("eye%d" % sx, size=(0.8, 0.8, 0.8), at=(sx * 1.0, -0.8, 4.7), role="white", chamfer=0.2)
        m.box("pupil%d" % sx, size=(0.4, 0.2, 0.45), at=(sx * 1.0, -1.2, 4.7), role="ink")
    wing_pair(m, 1.5, 3.1, 1.3, 1.0, "wing")
    m.crystal("spike", radius=0.25, height=0.7, at=(0, 0.8, 3.75), role="glow", sides=5, tip=0.5, solo=True)
    m.build()
    return m


@model
def CrCube():
    # cube de pixels : visage à l'écran, coins lumineux, petits cubes en orbite
    m = MS("CrCube")
    m.palette(body=plain("#2E8AB0", shade=0.12, tiles=(4, 0.12)), bodyd=plain("#1E6686"), screen=plain("#12283A"), pix="#5CF0F4", mag="#E860D8",
              glow=glow("#39E4F0"), glowM=glow("#E04FD0"), **INK)
    m.box("body", size=(2.8, 2.8, 2.8), at=(0, 0, 2.0), role="body", chamfer=0.25)
    m.box("screen", size=(2.2, 0.3, 1.8), at=(0, -1.35, 2.1), role="screen")
    for i, (sx, sz) in enumerate(((-1, -1), (1, -1), (-1, 1), (1, 1))):
        m.box("corner%d" % i, size=(0.5, 0.5, 0.5), at=(sx * 1.4, -1.4, 2.0 + sz * 1.4), role="glow", solo=True)
    for i in range(3):
        a = i / 3 * math.tau
        m.box("spinbit%d" % i, size=(0.6, 0.6, 0.6), at=(math.cos(a) * 2.7, math.sin(a) * 2.7, 2.0 + (i - 1) * 0.5),
              role="bodyd", rot=(20 * i, 30, 15))
    m.build()
    m.stamp("screen", "front", (0, 0.1), ["##...##", "##...##", ".......", ".#...#.", "..###.."], {"#": "pix"}, cell=0.25)
    m.rect("body", "top", (0, 0), (1.2, 1.2), "mag")
    return m


@model
def CrChick():
    # poussin dans sa demi-coquille, hélice sur la tête
    m = MS("CrChick")
    m.palette(shell=plain("#D8CCB0", shade=0.14), shelld=plain("#B8AA8C"), body=plain("#D9B02E", shade=0.12, top=0.18), beak=plain("#D9772A"),
              wing=plain("#E8C84A"), prop=plain("#C84A4A"), propd=plain("#3A3A48"), spot="#A88A5E", glow=glow("#FFD84A"), **INK)
    m.prism("shell", radius=1.7, height=1.5, at=(0, 0, 0.95), role="shell", sides=8, taper=1.18)
    m.prism("shellBot", radius=1.1, height=0.5, at=(0, 0, 0.0), role="shelld", sides=8, taper=1.55)
    for i in range(8):
        a = i / 8 * math.tau + 0.39
        m.prism("zig%d" % i, radius=0.55, height=0.7, at=(math.cos(a) * 1.75, math.sin(a) * 1.75, 2.0), role="shell", sides=3, taper=0.1, turn=math.degrees(a) + 90)
    m.box("body", size=(2.5, 2.3, 2.4), at=(0, 0, 2.7), role="body", chamfer=0.65)
    m.pyramid("beak", size=(0.7, 0.7, 0.5), at=(0, -1.35, 2.5), role="beak", rot=(90, 0, 0))
    m.box("wingL", size=(0.9, 0.8, 0.2), at=(-1.6, 0, 2.4), role="wing", taper=(0.4, 1), axis="x", rot=(0, 0, 180))
    m.box("wingR", size=(0.9, 0.8, 0.2), at=(1.6, 0, 2.4), role="wing", taper=(0.4, 1), axis="x")
    m.box("cap", size=(0.6, 0.6, 0.5), at=(0, 0, 4.1), role="propd")
    m.box("spinA", size=(3.0, 0.5, 0.12), at=(0, 0, 4.45), role="prop")
    m.box("spinB", size=(0.5, 3.0, 0.12), at=(0, 0, 4.45), role="prop")
    m.build()
    face(m, "body", dx=0.62, y=0.45, eye=0.6, mouth=None)
    m.circle("shell", "side5", (0, 0), 0.25, "spot")
    m.circle("shell", "side6", (0.1, 0.2), 0.2, "spot")
    return m


@model
def CrFish():
    # poisson du récif : rayures blanches, grande queue, nageoires, bulle
    m = MS("CrFish")
    m.palette(body=plain("#D9772A", shade=0.12, top=0.16), bodyd=plain("#B85A1E"), stripe="#F2EEE4", fin=plain("#2EB8A8"), find=plain("#1E8E84"),
              glow=glow("#5CF0DC"), **INK)
    m.box("body", size=(2.4, 3.0, 2.6), at=(0, -0.2, 2.0), role="body", chamfer=0.7)
    m.box("rear", size=(1.9, 1.6, 2.0), at=(0, 1.9, 2.0), role="bodyd", chamfer=0.5, taper=(0.5, 0.6), axis="y", rot=(0, 0, 180))
    m.box("tailA", size=(0.2, 1.6, 2.8), at=(0, 3.4, 2.0), role="fin", taper=(1, 1.9), axis="y")
    m.box("dorsal", size=(0.2, 1.8, 1.1), at=(0, -0.1, 3.7), role="fin", slope=(0, 0.7))
    m.box("finL", size=(1.2, 0.9, 0.16), at=(-1.7, -0.3, 1.5), role="find", taper=(0.4, 1), axis="x", rot=(0, 20, 180))
    m.box("finR", size=(1.2, 0.9, 0.16), at=(1.7, -0.3, 1.5), role="find", taper=(0.4, 1), axis="x", rot=(0, -20, 0))
    m.box("lip", size=(1.0, 0.4, 0.5), at=(0, -1.75, 1.6), role="bodyd", chamfer=0.12)
    m.crystal("bubble", radius=0.3, height=0.7, at=(0.4, -2.3, 3.4), role="glow", sides=6, tip=0.5, base_tip=0.5, solo=True)
    m.build()
    for side in ("left", "right"):
        m.rect("body", side, (-0.2 if side == "left" else 0.2, 0), (0.5, 2.6), "stripe")
        m.rect("body", side, (0.9 if side == "left" else -0.9, 0.35), (0.8, 0.85), "white")
        m.rect("body", side, (1.0 if side == "left" else -1.0, 0.3), (0.42, 0.55), "ink")
    m.rect("body", "top", (0, 0.5), (2.4, 0.5), "stripe")
    return m


@model
def CrSpark():
    # étincelle : petit éclair vivant, antennes en zigzag, ailes de lumière
    m = MS("CrSpark")
    m.palette(body=plain("#D9B02E", shade=0.1, top=0.2), bodyd=plain("#B8901E"), belly=plain("#F0E0A0"), wing=dict(color="#FFE46A", glow=True),
              glow=glow("#FFE02E"), **INK)
    m.box("body", size=(2.4, 2.2, 2.6), at=(0, 0, 2.0), role="body", chamfer=0.7, taper=0.85)
    m.box("belly", size=(1.5, 0.3, 1.0), at=(0, -1.0, 1.4), role="belly", chamfer=0.15)
    m.pyramid("stinger", size=(1.0, 0.9, 1.0), at=(0, 0.2, 0.7), role="bodyd", rot=(180, 0, 0), pivot="bottom")
    for sx in (-1, 1):
        pts = [(sx * 0.6, 0, 3.2), (sx * 1.2, -0.1, 3.9), (sx * 0.7, -0.2, 4.4), (sx * 1.4, -0.3, 5.1)]
        for i in range(3):
            m.beam("ant%d_%d" % (sx, i), pts[i], pts[i + 1], role="glow", width=0.24, taper=0.8)
    m.box("wingL", size=(1.5, 1.0, 0.14), at=(-1.9, 0.2, 2.3), role="glow", taper=(0.3, 1), axis="x", rot=(0, 0, 195), solo=True)
    m.box("wingR", size=(1.5, 1.0, 0.14), at=(1.9, 0.2, 2.3), role="glow", taper=(0.3, 1), axis="x", rot=(0, 0, -15), solo=True)
    m.build()
    face(m, "body", dx=0.55, y=0.45, eye=0.6)
    return m


@model
def CrDrone():
    # drone à remontoir : coque de laiton rivetée, œil de verre, hélice, clé dans le dos, petites pinces
    m = MS("CrDrone")
    m.palette(brass=plain("#A87A2E", top=0.2, rim=-0.2), brassd=plain("#7E5A20"), steel=plain("#4E5A6E"), lens=plain("#1E3A44"), rivet="#E0C060",
              prop=plain("#C8C0A8"), glow=glow("#3FE0C8"), **INK)
    m.box("body", size=(2.8, 2.6, 2.4), at=(0, 0, 2.0), role="brass", chamfer=0.6)
    m.box("belt", size=(3.0, 2.8, 0.5), at=(0, 0, 2.0), role="brassd", chamfer=0.1)
    m.prism("eyeRing", radius=0.95, height=0.4, at=(0, -1.35, 2.3), role="steel", sides=10, rot=(90, 0, 0))
    m.prism("eyeLens", radius=0.7, height=0.5, at=(0, -1.4, 2.3), role="lens", sides=10, rot=(90, 0, 0))
    m.prism("eyeGlow", radius=0.35, height=0.6, at=(0.1, -1.42, 2.4), role="glow", sides=6, rot=(90, 0, 0), solo=True)
    m.prism("mast", radius=0.22, height=0.9, at=(0, 0, 3.6), role="steel", sides=6)
    m.box("spinA", size=(3.4, 0.5, 0.12), at=(0, 0, 4.1), role="prop")
    m.box("spinB", size=(0.5, 3.4, 0.12), at=(0, 0, 4.1), role="prop")
    # clé de remontoir (elle tourne autour de l'axe avant-arrière)
    m.beam("keyStem", (0, 1.3, 2.2), (0, 2.0, 2.2), role="steel", width=0.26)
    m.box("spin2A", size=(0.3, 0.3, 1.9), at=(0, 2.1, 2.2), role="brassd", chamfer=0.08)
    m.box("spin2B", size=(1.0, 0.3, 0.7), at=(0, 2.1, 3.0), role="brassd", chamfer=0.08)
    m.box("spin2C", size=(1.0, 0.3, 0.7), at=(0, 2.1, 1.4), role="brassd", chamfer=0.08)
    for sx in (-1, 1):
        m.beam("arm%d" % sx, (sx * 1.2, -0.6, 1.2), (sx * 1.4, -1.2, 0.3), role="steel", width=0.22)
        m.box("claw%d" % sx, size=(0.5, 0.5, 0.35), at=(sx * 1.4, -1.3, 0.2), role="brassd")
    m.build()
    for x in (-1.1, 1.1):
        for z in (0.75, -0.75):
            m.rect("body", "front", (x, z), (0.22, 0.22), "rivet")
    return m


@model
def CrSaucer():
    # soucoupe en bonbon : disque glacé, dôme, petit pilote, lumières sucrées qui tournent
    m = MS("CrSaucer")
    m.palette(disc=plain("#C8447A", shade=0.12, top=0.2), discd=plain("#9A2E5C"), icing=plain("#F0D8E0"), dome=dict(color="#7FC8E8", noise=0.02, shade=0.06),
              pilot=plain("#7CD88A"), sprA="#3F9AC8", sprB="#E0C03A", glow=glow("#7FE0FF"), glowY=glow("#FFD84A"), **INK)
    m.prism("under", radius=1.6, height=0.7, at=(0, 0, 1.1), role="discd", sides=10, taper=1.5)
    m.prism("disc", radius=2.9, height=0.7, at=(0, 0, 1.8), role="disc", sides=12)
    m.prism("icing", radius=2.3, height=0.4, at=(0, 0, 2.3), role="icing", sides=12, taper=0.86)
    m.box("pilot", size=(1.5, 1.4, 1.5), at=(0, 0, 3.1), role="pilot", chamfer=0.4)
    m.prism("dome", radius=1.45, height=1.0, at=(0, 0.1, 4.2), role="dome", sides=8, taper=0.5)
    m.beam("antenna", (0, 0, 4.6), (0, 0, 5.3), role="discd", width=0.12)
    m.crystal("antTip", radius=0.2, height=0.5, at=(0, 0, 5.2), role="glowY", sides=5, tip=0.5, base_tip=0.5, solo=True)
    for i in range(8):
        a = i / 8 * math.tau
        m.box("spinlight%d" % i, size=(0.5, 0.5, 0.35), at=(math.cos(a) * 2.5, math.sin(a) * 2.5, 2.3), role="discd", chamfer=0.1)
    m.prism("beam", radius=0.7, height=0.3, at=(0, 0, 0.65), role="glow", sides=8, solo=True)
    m.build()
    face(m, "pilot", dx=0.36, y=0.15, eye=0.4, mouth="smile")
    for i in range(12):
        m.rect("disc", "side%d" % i, (0, 0), (0.3, 0.3), "sprA" if i % 2 else "sprB")
    return m


@model
def CrFairy():
    # fée champignon : chapeau rouge à pois, ailes de feuille lumineuses, lanterne de spore
    m = MS("CrFairy")
    m.palette(body=plain("#E0D4B8", shade=0.12), cap=plain("#B8323E", top=0.2), capd=plain("#8E2430"), spot=plain("#EEE6D8"),
              wing=dict(color="#5CF0C8", glow=True), leaf=plain("#4A8A52"), glow=glow("#5CF0C8"), **INK)
    m.box("body", size=(2.2, 2.0, 2.2), at=(0, 0, 1.6), role="body", chamfer=0.6, taper=0.9)
    m.prism("cap0", radius=2.1, height=0.6, at=(0, 0, 3.0), role="capd", sides=8, taper=0.95)
    m.prism("cap1", radius=1.95, height=0.7, at=(0, 0, 3.65), role="cap", sides=8, taper=0.7)
    m.prism("cap2", radius=1.36, height=0.5, at=(0, 0, 4.25), role="cap", sides=8, taper=0.4)
    for i in range(4):
        a = i / 4 * math.tau + 0.6
        m.prism("spot%d" % i, radius=0.3, height=0.16, at=(math.cos(a) * 1.3, math.sin(a) * 1.3, 4.02), role="spot", sides=6, solo=True)
    m.prism("spotT", radius=0.3, height=0.16, at=(0, 0, 4.55), role="spot", sides=6, solo=True)
    m.box("wingL", size=(1.8, 1.2, 0.12), at=(-1.9, 0.5, 1.9), role="glow", taper=(0.3, 1), axis="x", rot=(0, 0, 200), solo=True)
    m.box("wingR", size=(1.8, 1.2, 0.12), at=(1.9, 0.5, 1.9), role="glow", taper=(0.3, 1), axis="x", rot=(0, 0, -20), solo=True)
    m.box("collar", size=(2.0, 1.8, 0.3), at=(0, 0, 0.75), role="leaf", taper=1.2)
    m.beam("hand", (0.9, -0.7, 1.2), (1.3, -1.3, 1.0), role="body", width=0.24)
    m.crystal("spore", radius=0.3, height=0.7, at=(1.35, -1.4, 0.4), role="glow", sides=5, tip=0.5, base_tip=0.5, solo=True)
    m.build()
    face(m, "body", dx=0.5, y=0.3, eye=0.55)
    return m


@model
def CrDragon():
    # tête de dragon de jade : museau, cornes et crête d'or, moustaches qui flottent
    m = MS("CrDragon")
    m.palette(jade=plain("#2E8A66", shade=0.14, top=0.18, mottle=("#236E50", 0.2, 4)), jaded=plain("#236E50"), belly=plain("#C8A83A"),
              gold=plain("#B8892E", top=0.25), tooth=plain("#E8E4D4"), nostril="#143C2C", glow=glow("#FFD45C"), **INK)
    m.box("body", size=(3.0, 2.8, 2.6), at=(0, 0.4, 2.0), role="jade", chamfer=0.6)
    m.box("snout", size=(2.2, 1.9, 1.5), at=(0, -1.7, 1.6), role="jade", chamfer=0.4, taper=(0.75, 0.8), axis="y", rot=(0, 0, 180))
    m.box("chin", size=(1.9, 1.8, 0.45), at=(0, -1.6, 0.75), role="belly", chamfer=0.12)
    for i, x in enumerate((-0.6, 0.6)):
        m.pyramid("tooth%d" % i, size=(0.3, 0.3, 0.4), at=(x, -2.4, 1.0), role="tooth", rot=(180, 0, 0), pivot="bottom")
    for sx in (-1, 1):
        m.prism("horn%d" % sx, radius=0.34, height=1.9, at=(sx * 0.95, 0.9, 4.0), role="gold", sides=5, taper=0.15, shear=(sx * 0.5, 0.6))
        m.box("brow%d" % sx, size=(1.0, 0.6, 0.35), at=(sx * 0.85, -0.95, 3.2), role="jaded", rot=(0, sx * 12, 0))
        m.box("eye%d" % sx, size=(0.75, 0.25, 0.7), at=(sx * 0.85, -1.05, 2.65), role="white")
        m.box("pupil%d" % sx, size=(0.3, 0.3, 0.5), at=(sx * 0.9, -1.1, 2.65), role="ink")
    for i, y in enumerate((0.0, 0.9, 1.7)):
        m.prism("crest%d" % i, radius=0.4, height=0.9 - i * 0.15, at=(0, y, 3.6), role="gold", sides=4, taper=0.2, shear=(0, 0.3))
    # moustaches (elles ondulent)
    m.beam("finL", (-0.9, -2.3, 1.5), (-2.8, -1.4, 1.9), role="gold", width=0.2, taper=0.4)
    m.beam("finR", (0.9, -2.3, 1.5), (2.8, -1.4, 1.9), role="gold", width=0.2, taper=0.4)
    m.box("gem", size=(0.5, 0.25, 0.5), at=(0, -1.05, 3.05), role="glow", rot=(0, 45, 0), solo=True)
    m.build()
    m.rect("snout", "front", (-0.4, 0.25), (0.22, 0.22), "nostril")
    m.rect("snout", "front", (0.4, 0.25), (0.22, 0.22), "nostril")
    return m


@model
def CrDragonSeg():
    # tronçon du corps du dragon : écailles de jade, ventre et plaque dorsale d'or
    m = MS("CrDragonSeg")
    m.palette(jade=plain("#2E8A66", shade=0.14, top=0.18, mottle=("#236E50", 0.2, 4)), belly=plain("#C8A83A"), gold=plain("#B8892E", top=0.25), scale="#236E50")
    m.box("body", size=(2.4, 2.6, 2.4), at=(0, 0, 2.0), role="jade", chamfer=0.6)
    m.box("belly", size=(1.6, 2.4, 0.4), at=(0, 0, 0.75), role="belly", chamfer=0.1)
    m.prism("crest", radius=0.5, height=1.0, at=(0, 0, 3.6), role="gold", sides=4, taper=0.2, shear=(0, 0.3))
    m.build()
    for side in ("left", "right"):
        m.stamp("body", side, (0, 0), ["#.#.#", ".#.#."], {"#": "scale"}, cell=0.4)
    return m


@model
def CrGhost():
    # petit fantôme : drap à pointes, bras qui flottent, lanterne turquoise
    m = MS("CrGhost")
    m.palette(sheet=plain("#D4E0E8", shade=0.14, top=0.1), sheetd=plain("#A8BCCA"), cheek=plain("#E0A0B4"), iron=plain("#3A3E5C"),
              glow=glow("#4FF0D8"), **INK)
    m.box("body", size=(2.8, 2.6, 2.6), at=(0, 0, 2.4), role="sheet", chamfer=0.8)
    m.box("skirt", size=(2.6, 2.4, 0.9), at=(0, 0, 0.9), role="sheetd", chamfer=0.2, taper=1.12)
    for i in range(6):
        a = i / 6 * math.tau + 0.3
        m.prism("frill%d" % i, radius=0.6, height=0.9, at=(math.cos(a) * 1.0, math.sin(a) * 0.9, 0.5), role="sheet" if i % 2 else "sheetd", sides=4, taper=0.1,
                rot=(180, 0, 0))
    m.box("finL", size=(1.2, 0.8, 0.7), at=(-1.9, -0.3, 2.2), role="sheet", chamfer=0.25, rot=(0, 20, 15))
    m.box("finR", size=(1.2, 0.8, 0.7), at=(1.9, -0.5, 2.0), role="sheet", chamfer=0.25, rot=(0, -5, -25))
    m.box("cheekL", size=(0.45, 0.2, 0.3), at=(-1.0, -1.3, 2.0), role="cheek")
    m.box("cheekR", size=(0.45, 0.2, 0.3), at=(1.0, -1.3, 2.0), role="cheek")
    m.beam("hang", (2.3, -0.9, 1.9), (2.3, -0.9, 1.2), role="iron", width=0.12)
    m.pyramid("lanRoof", size=(0.9, 0.9, 0.4), at=(2.3, -0.9, 1.2), role="iron")
    m.box("lan", size=(0.6, 0.6, 0.7), at=(2.3, -0.9, 0.7), role="glow", solo=True)
    m.box("lanBot", size=(0.8, 0.8, 0.14), at=(2.3, -0.9, 0.3), role="iron")
    m.build()
    face(m, "body", dx=0.6, y=0.3, eye=0.6, mouth="o")
    return m


@model
def CrGhostSeg():
    # volute de la traîne du fantôme
    m = MS("CrGhostSeg")
    m.palette(sheet=plain("#D4E0E8", shade=0.14, top=0.1), sheetd=plain("#A8BCCA"))
    m.box("body", size=(2.0, 2.0, 2.0), at=(0, 0, 2.0), role="sheet", chamfer=0.6)
    m.prism("frill", radius=0.6, height=0.9, at=(0, 0, 0.7), role="sheetd", sides=4, taper=0.1, rot=(180, 0, 0))
    m.build()
    return m
