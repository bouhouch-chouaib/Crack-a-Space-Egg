# Images des mondes de l'Index (Config.WorldArt), 25 nov. : une scène Blender par anneau, rendue en 384 x 1024.
# Même composition que l'anneau 1 (tools/ui-icons/world_r1.png) :
#   en haut, la créature Mythique (T6) en vol devant l'astéroïde d'or (V3) ;
#   au milieu, l'astéroïde d'argent (V2) avec la créature Légendaire (T5) dessus ;
#   en bas, la roche de la zone (V1) avec la créature Uncommon (T2) et l'œuf Mythique ;
#   au loin, de petites copies des trois astéroïdes ; fond en dégradé aux couleurs de l'anneau, nébuleuse et étoiles.
# Le haut et le bas de l'image passent sous le titre et le pourcentage de l'Index : les sujets restent au centre.
# Préparation (outils Ropilot) : ropilot_blender_import_model des modèles du jeu
#   Asteroids.Ring<n>.V1..V3, Creatures.R<n>_T2, R<n>_T5, R<n>_T6, Eggs.R<n>_T6
# (les collections arrivent sous ces noms, « R<n>_T6 2 » pour l'œuf), puis make_world(n, palette) ici.
# Chaque anneau a sa propre scène (World_R<n>) : on ne rend jamais la scène principale, partagée.
import math
import os
import random
from mathutils import Matrix, Vector

OUT = os.path.join(os.path.expanduser("~"), "OneDrive - Conseil régional Grand Est - Numérique Educatif", "Documents",
                   "Ropilot", "Renders", "IndexWorlds")

# Taille visée (plus grande dimension, studs) et place de chaque élément : (x, y, z), rotation z, rôle
LAYOUT = {
    "V3": dict(size=25, at=(7, 48, 22), rz=30),
    "T6": dict(size=17, at=(-3, 30, 38), rz=-35),
    "V2": dict(size=20, at=(-6.5, 12, 6), rz=-20),
    "T5": dict(size=11.5, at=(-10, 11, None), rz=30, on="V2"),
    "V1": dict(size=19, at=(4, -12, -6), rz=15),
    "T2": dict(size=7.5, at=(1.5, -14, None), rz=-15, on="V1"),
    "EGG": dict(size=8, at=(8, -10.5, None), rz=-10, on="V1"),
}
FAR = [(-22, 140, 66, "V1", 0.5), (18, 160, 8, "V1", 0.6), (-20, 120, -4, "V2", 0.45), (22, 130, 55, "V1", 0.4),
       (-14, 170, 30, "V3", 0.5), (14, 110, 70, "V1", 0.35), (-24, 150, 80, "V1", 0.4)]


def bbox_objs(objs):
    pts = [o.matrix_world @ Vector(c) for o in objs if o.type == "MESH" for c in o.bound_box]
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return mn, mx


def rig(scene, col, key):
    """Empty parent de la collection, posé au centre bas de sa boîte."""
    e = bpy.data.objects.new(f"E_{scene.name}_{key}", None)
    scene.collection.objects.link(e)
    mn, mx = bbox_objs(col.all_objects)
    e.location = ((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z)
    inv = Matrix.Translation(e.location).inverted()
    for o in col.all_objects:
        if o.parent is None:
            o.parent = e
            o.matrix_parent_inverse = inv
    return e, max(mx.x - mn.x, mx.y - mn.y, mx.z - mn.z)


def rock_top(col):
    """Hauteur du dessus de la roche (sans le décor), au milieu de sa boîte."""
    rock = [o for o in col.all_objects if o.type == "MESH" and "Asteroid" in o.name] or list(col.all_objects)
    mn, mx = bbox_objs(rock)
    return mx.z


def background(scene, low, mid, high, nebula):
    bpy.ops.mesh.primitive_plane_add(size=1)
    bg = bpy.context.active_object
    for c in list(bg.users_collection):
        c.objects.unlink(bg)
    scene.collection.objects.link(bg)
    bg.name = f"BG_{scene.name}"
    bg.location = (0, 300, 26)
    bg.rotation_euler = (math.radians(90), 0, 0)
    bg.scale = (300, 600, 1)
    mat = bpy.data.materials.new(f"BG_{scene.name}")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    cr = ramp.color_ramp
    cr.elements[0].position, cr.elements[0].color = 0.25, (*low, 1)
    cr.elements[1].position, cr.elements[1].color = 0.75, (*high, 1)
    cr.elements.new(0.5).color = (*mid, 1)
    nt.links.new(tc.outputs["Generated"], sep.inputs[0])
    nt.links.new(sep.outputs["Y"], ramp.inputs[0])
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 3.0
    noise.inputs["Detail"].default_value = 6
    nr = nt.nodes.new("ShaderNodeValToRGB")
    nr.color_ramp.elements[0].position, nr.color_ramp.elements[0].color = 0.45, (0, 0, 0, 1)
    nr.color_ramp.elements[1].position, nr.color_ramp.elements[1].color = 0.8, (*nebula, 1)
    nt.links.new(tc.outputs["Generated"], noise.inputs["Vector"])
    nt.links.new(noise.outputs["Fac"], nr.inputs[0])
    add = nt.nodes.new("ShaderNodeMix")
    add.data_type, add.blend_type = "RGBA", "ADD"
    add.inputs["Factor"].default_value = 0.55
    nt.links.new(ramp.outputs["Color"], add.inputs[6])
    nt.links.new(nr.outputs["Color"], add.inputs[7])
    vor = nt.nodes.new("ShaderNodeTexVoronoi")
    vor.inputs["Scale"].default_value = 160
    sr = nt.nodes.new("ShaderNodeValToRGB")
    sr.color_ramp.elements[0].position, sr.color_ramp.elements[0].color = 0.0, (1, 1, 1, 1)
    sr.color_ramp.elements[1].position, sr.color_ramp.elements[1].color = 0.06, (0, 0, 0, 1)
    nt.links.new(tc.outputs["Generated"], vor.inputs["Vector"])
    nt.links.new(vor.outputs["Distance"], sr.inputs[0])
    add2 = nt.nodes.new("ShaderNodeMix")
    add2.data_type, add2.blend_type = "RGBA", "ADD"
    add2.inputs["Factor"].default_value = 1.0
    nt.links.new(add.outputs[2], add2.inputs[6])
    nt.links.new(sr.outputs["Color"], add2.inputs[7])
    nt.links.new(add2.outputs[2], em.inputs["Color"])
    nt.links.new(em.outputs[0], out.inputs[0])
    bg.data.materials.clear()
    bg.data.materials.append(mat)


def make_world(n, low, mid, high, nebula, cols=None, render=True):
    """cols : noms des collections importées {V1, V2, V3, T2, T5, T6, EGG} (par défaut ceux de l'import)."""
    cols = cols or {"V1": "V1", "V2": "V2", "V3": "V3", "T2": f"R{n}_T2", "T5": f"R{n}_T5", "T6": f"R{n}_T6", "EGG": f"R{n}_T6 2"}
    name = f"World_R{n}"
    old = bpy.data.scenes.get(name)
    if old:
        # relance : les modèles quittent leurs anciens parents en gardant leur place, puis on efface le reste
        for cname in cols.values():
            for o in bpy.data.collections[cname].all_objects:
                if o.parent and name in o.parent.name:
                    mw = o.matrix_world.copy()
                    o.parent = None
                    o.matrix_world = mw
        for o in [o for o in bpy.data.objects if o.name.endswith(name) or f"_{name}_" in o.name]:
            bpy.data.objects.remove(o)
        bpy.data.scenes.remove(old)
    sc = bpy.data.scenes.new(name)
    rigs = {}
    for key, cname in cols.items():
        col = bpy.data.collections[cname]
        # la collection passe de la scène principale à la scène du monde
        for parent in [bpy.context.scene.collection] + list(bpy.data.collections):
            if col.name in [c.name for c in parent.children]:
                parent.children.unlink(col)
        sc.collection.children.link(col)
        rigs[key] = rig(sc, col, key)
    tops = {}
    for key in ("V3", "V2", "V1"):
        e, dim = rigs[key]
        L = LAYOUT[key]
        s = L["size"] / dim
        e.location, e.scale, e.rotation_euler = L["at"], (s, s, s), (0, 0, math.radians(L["rz"]))
    sc.view_layers[0].update()
    for key in ("V2", "V1"):
        tops[key] = rock_top(bpy.data.collections[cols[key]])
    for key in ("T6", "T5", "T2", "EGG"):
        e, dim = rigs[key]
        L = LAYOUT[key]
        s = L["size"] / dim
        x, y, z = L["at"]
        if z is None:
            z = tops[L["on"]] - 0.3
        e.location, e.scale, e.rotation_euler = (x, y, z), (s, s, s), (0, 0, math.radians(L["rz"]))
    sc.view_layers[0].update()
    # petits astéroïdes au loin
    rnd = random.Random(n)
    for i, (x, y, z, key, s) in enumerate(FAR):
        col = bpy.data.collections[cols[key]]
        e = rigs[key][0]
        col.instance_offset = e.location.copy()
        inst = bpy.data.objects.new(f"Far_{name}_{i}", None)
        inst.instance_type, inst.instance_collection = "COLLECTION", col
        inst.location = (x, y, z)
        inst.scale = (s * LAYOUT[key]["size"] / 24 / e.scale.x,) * 3
        inst.rotation_euler = (math.radians(rnd.uniform(-15, 15)), 0, math.radians(rnd.uniform(0, 360)))
        sc.collection.objects.link(inst)
    # caméra, lumières, monde
    cd = bpy.data.cameras.new(f"Cam_{name}")
    cam = bpy.data.objects.new(f"Cam_{name}", cd)
    sc.collection.objects.link(cam)
    sc.camera = cam
    cd.lens, cd.sensor_fit, cd.sensor_height, cd.clip_end = 50, "VERTICAL", 36, 2000
    cam.location = (0, -100, 26)
    cam.rotation_euler = (Vector((0, 10, 23)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    for lname, rot, en, col in [("Sun", (50, 10, -35), 4.5, (1, 0.93, 0.85)), ("Rim", (-40, 0, 160), 2.0, (0.75, 0.55, 1.0)),
                                ("Fill", (100, 0, 10), 1.6, (1.0, 0.8, 0.65))]:
        ld = bpy.data.lights.new(f"{lname}_{name}", "SUN")
        lo = bpy.data.objects.new(f"{lname}_{name}", ld)
        sc.collection.objects.link(lo)
        ld.energy, ld.color = en, col
        lo.rotation_euler = [math.radians(a) for a in rot]
    w = bpy.data.worlds.new(f"W_{name}")
    sc.world = w
    w.use_nodes = True
    bgn = next(nd for nd in w.node_tree.nodes if nd.type == "BACKGROUND")
    bgn.inputs[0].default_value, bgn.inputs[1].default_value = (0.35, 0.3, 0.4, 1), 0.6
    background(sc, low, mid, high, nebula)
    try:
        sc.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError:
        sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage = 384, 1024, 100
    sc.render.film_transparent = False
    sc.view_settings.view_transform = "Standard"
    try:
        sc.view_settings.look = "Medium High Contrast"
    except TypeError:
        pass
    sc.render.image_settings.file_format = "PNG"
    os.makedirs(OUT, exist_ok=True)
    sc.render.filepath = os.path.join(OUT, f"World_R{n}.png")
    if render:
        bpy.ops.render.render(write_still=True, scene=sc.name)
    return sc.render.filepath


# Fond de chaque anneau : bas, milieu, haut du dégradé, couleur de la nébuleuse (valeurs linéaires)
PALETTES = {
    1: ((0.30, 0.12, 0.06), (0.20, 0.05, 0.22), (0.03, 0.02, 0.10), (0.85, 0.35, 0.55)),
    2: ((0.10, 0.30, 0.45), (0.10, 0.12, 0.40), (0.02, 0.03, 0.12), (0.45, 0.75, 0.95)),
    3: ((0.45, 0.12, 0.03), (0.25, 0.04, 0.05), (0.05, 0.01, 0.02), (0.90, 0.35, 0.10)),
    4: ((0.35, 0.12, 0.40), (0.18, 0.06, 0.35), (0.04, 0.02, 0.12), (0.60, 0.30, 0.90)),
    5: ((0.12, 0.18, 0.06), (0.10, 0.06, 0.10), (0.02, 0.02, 0.03), (0.40, 0.80, 0.20)),
    6: ((0.05, 0.25, 0.40), (0.05, 0.08, 0.25), (0.01, 0.02, 0.08), (0.20, 0.80, 0.95)),
    7: ((0.45, 0.28, 0.10), (0.25, 0.12, 0.15), (0.05, 0.03, 0.08), (0.90, 0.60, 0.30)),
    8: ((0.05, 0.40, 0.40), (0.05, 0.15, 0.30), (0.01, 0.03, 0.08), (0.95, 0.45, 0.55)),
    9: ((0.25, 0.15, 0.40), (0.12, 0.08, 0.28), (0.03, 0.02, 0.08), (0.95, 0.85, 0.30)),
    10: ((0.45, 0.28, 0.08), (0.15, 0.10, 0.08), (0.03, 0.03, 0.05), (0.30, 0.90, 0.85)),
    11: ((0.60, 0.25, 0.45), (0.35, 0.15, 0.45), (0.08, 0.04, 0.15), (1.00, 0.70, 0.85)),
    12: ((0.10, 0.35, 0.35), (0.20, 0.10, 0.35), (0.04, 0.02, 0.10), (0.40, 0.95, 0.80)),
    13: ((0.10, 0.40, 0.25), (0.05, 0.15, 0.18), (0.01, 0.04, 0.05), (0.95, 0.80, 0.30)),
    14: ((0.15, 0.40, 0.40), (0.10, 0.12, 0.25), (0.02, 0.03, 0.07), (0.60, 0.95, 0.90)),
}


def world_from_import(n):
    """Juste après ropilot_blender_import_model des 7 modèles de l'anneau n (voir l'en-tête) : renomme les
    astéroïdes importés (V1..V3 -> W<n>_V1..), compose la scène et la rend."""
    for k in ("V1", "V2", "V3"):
        col = bpy.data.collections[k]
        col.name = f"W{n}_{k}"
        # il arrive que l'import n'ait pas la texture d'une roche (roche blanche) : on reprend le matériau
        # du modèle construit au kit (collection Rock_R<n>_V<k>), dont la mise à plat est la même
        kit = bpy.data.collections.get(f"Rock_R{n}_{k}")
        if kit:
            kmat = next((s.material for o in kit.all_objects for s in o.material_slots
                         if s.material and "glow" not in s.material.name.lower()), None)
            for o in col.all_objects:
                m = o.material_slots[0].material if o.material_slots else None
                textured = m and m.use_nodes and any(nd.type == "TEX_IMAGE" and nd.image for nd in m.node_tree.nodes)
                if kmat and "Glow" not in o.name and not textured:
                    o.material_slots[0].material = kmat
    cols = {"V1": f"W{n}_V1", "V2": f"W{n}_V2", "V3": f"W{n}_V3", "T2": f"R{n}_T2", "T5": f"R{n}_T5", "T6": f"R{n}_T6", "EGG": f"R{n}_T6 2"}
    return make_world(n, *PALETTES[n], cols=cols)
