# Outils communs aux monstres des anneaux 3 a 6 (kit ropilot.model, px = 8, sans picots).
# Usage dans le Blender de Ropilot : exec(open(r"<repo>/tools/blender/monster_helpers.py", encoding="utf-8").read())
# Tous les noms commencent par mk_ (Blender partage avec d'autres taches).
import ropilot, bpy, os, math, io, re, contextlib

MK_REPO = r"C:\Users\bouho\OneDrive - Conseil régional Grand Est - Numérique Educatif\Documents\Crack the Asteroid"
MK_REFS = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "Monster_Refs")


def mk_refs(stem):
    return {v: os.path.join(MK_REFS, f"{stem}_{v}.png") for v in ("front", "left", "back", "top")}


def mk_add(a, b, k=1.0):
    return tuple(a[i] + b[i] * k for i in range(3))


def mk_sub(a, b):
    return tuple(a[i] - b[i] for i in range(3))


def mk_norm(v):
    L = math.sqrt(sum(c * c for c in v)) or 1.0
    return tuple(c / L for c in v)


def mk_mid(a, b, t=0.5):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def mk_len(v):
    return math.sqrt(sum(c * c for c in v))


def mk_curve(m, name, pts, widths, depths, roles, ext=0.12, chamf=0.15, **kw):
    # chaine de poutres qui se chevauchent (courbe continue), largeur qui varie
    sfx = "_L" if kw.get("mirror") else ""
    for i in range(len(pts) - 1):
        d = mk_norm(mk_sub(pts[i + 1], pts[i]))
        last = i == len(pts) - 2
        m.beam(f"{name}{i}{sfx}", start=mk_add(pts[i], d, -ext if i else 0), end=mk_add(pts[i + 1], d, 0 if last else ext),
               role=roles[i % len(roles)], width=widths[i], depth=depths[i], taper=max(0.05, widths[i + 1] / widths[i]),
               chamfer=chamf * widths[i + 1], **kw)


def mk_seg(m, name, a, b, radius, role, sides=8, taper=1.0, over=0.0, **kw):
    # prisme a `sides` pans d'axe a -> b, dans le plan x = cste (rotation autour de x seulement)
    d = mk_sub(b, a)
    L = mk_len(d)
    rx = math.degrees(math.atan2(-d[1], d[2]))
    m.prism(name, radius=radius, height=L + 2 * over, at=mk_mid(a, b), role=role, sides=sides, turn=180 / sides,
            taper=taper, rot=(rx, 0, 0), **kw)


def mk_close_gaps(col_name, rounds=25, extra=0.025):
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


def mk_ground(col_name):
    bpy.context.view_layer.update()
    objs = [o for o in bpy.data.collections[col_name].all_objects if o.type == "MESH"]
    z0 = min(min((o.matrix_world @ v.co).z for v in o.data.vertices) for o in objs)
    for o in objs:
        o.location.z -= z0
    bpy.context.view_layer.update()
    return z0


def mk_save(col_name, fname):
    col = bpy.data.collections[col_name]
    bpy.data.libraries.write(os.path.join(ropilot.FILES_DIR, fname), {col}, fake_user=True, compress=True)


def mk_load(col_name, fname):
    old = bpy.data.collections.get(col_name)
    if old:
        for o in list(old.all_objects):
            bpy.data.objects.remove(o, do_unlink=True)
        bpy.data.collections.remove(old)
    path = os.path.join(ropilot.FILES_DIR, fname)
    with bpy.data.libraries.load(path, link=False) as (src, dst):
        dst.collections = [c for c in src.collections if c == col_name]
    for c in dst.collections:
        if c is not None:
            bpy.context.scene.collection.children.link(c)
    return bpy.data.collections.get(col_name)


def mk_glow_share(col_name):
    tot = glo = 0.0
    for o in bpy.data.collections[col_name].all_objects:
        if o.type != "MESH":
            continue
        s = o.matrix_world.to_scale()[0]
        a = sum(p.area for p in o.data.polygons) * s * s
        tot += a
        mat = o.material_slots[0].material.name if o.material_slots and o.material_slots[0].material else ""
        if "glow" in mat.lower():
            glo += a
    return round(glo / tot, 4) if tot else 0


def mk_tris(col_name):
    n = 0
    for o in bpy.data.collections[col_name].all_objects:
        if o.type == "MESH":
            n += sum(len(p.vertices) - 2 for p in o.data.polygons)
    return n


def mk_join(col_name, out_col):
    # copie la collection, fusionne : une piece par materiau non lumineux groupe en « Body »,
    # une piece par materiau lumineux (« Glow », « Glow2 »...), dans une nouvelle collection out_col
    import bmesh
    src = bpy.data.collections[col_name]
    old = bpy.data.collections.get(out_col)
    if old:
        for o in list(old.all_objects):
            bpy.data.objects.remove(o, do_unlink=True)
        bpy.data.collections.remove(old)
    dst = bpy.data.collections.new(out_col)
    bpy.context.scene.collection.children.link(dst)
    buckets = {}
    for o in src.all_objects:
        if o.type != "MESH":
            continue
        c = o.copy()
        c.data = o.data.copy()
        dst.objects.link(c)
        mat = o.material_slots[0].material.name if o.material_slots and o.material_slots[0].material else ""
        key = mat if "glow" in mat.lower() else ""
        buckets.setdefault(key, []).append(c)
    names = []
    gi = 0
    for key in sorted(buckets):
        lst = buckets[key]
        bpy.ops.object.select_all(action="DESELECT")
        for o in lst:
            o.select_set(True)
        bpy.context.view_layer.objects.active = lst[0]
        if len(lst) > 1:
            bpy.ops.object.join()
        o = bpy.context.view_layer.objects.active
        if key:
            gi += 1
            nm = "Glow" + ("" if gi == 1 else str(gi))
        else:
            nm = "Shell"
        o.name = out_col + ":" + nm
        o.data.name = o.name
        bm = bmesh.new()
        bm.from_mesh(o.data)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
        bm.to_mesh(o.data)
        bm.free()
        names.append((o.name, sum(len(p.vertices) - 2 for p in o.data.polygons)))
    return names


def mk_strip_caps(col_name, prefixes, min_sides=6):
    # retire les faces d'extremite (octogones caches dans les anneaux voisins) des bagues lumineuses : moins de neon cache
    import bmesh
    n = 0
    for o in bpy.data.collections[col_name].all_objects:
        part = o.get("ropilot_part") or o.name
        if o.type == "MESH" and part.startswith(prefixes):
            bm = bmesh.new()
            bm.from_mesh(o.data)
            caps = [f for f in bm.faces if len(f.verts) >= min_sides]
            bmesh.ops.delete(bm, geom=caps, context="FACES_ONLY")
            n += len(caps)
            bm.to_mesh(o.data)
            bm.free()
    return n
