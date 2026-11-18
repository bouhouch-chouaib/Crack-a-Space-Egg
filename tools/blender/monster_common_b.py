# Outils communs des monstres des anneaux 7 a 10 (Queen, AbyssAngler, StormHydra, GearSpider), kit ropilot.model.
# Usage dans le Blender de Ropilot : exec(open(r"<repo>/tools/blender/monster_common_b.py", encoding="utf-8").read())
# Noms suffixes « _mb » : Blender est partage avec d'autres taches qui definissent leurs propres outils.
import ropilot, bpy, bmesh, os, math, io, re, contextlib

MB_REFS = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "Monster_Refs")


def refs_mb(name):
    # vues orthogonales de la reference rendues par ropilot_blender_render (style clean, fond #8fa0b8)
    return {v: os.path.join(MB_REFS, f"{name}_{v}.png") for v in ("front", "left", "back", "top")}


def add_mb(a, b, k=1.0):
    return tuple(a[i] + b[i] * k for i in range(3))


def sub_mb(a, b):
    return tuple(a[i] - b[i] for i in range(3))


def norm_mb(v):
    L = math.sqrt(sum(c * c for c in v)) or 1.0
    return tuple(c / L for c in v)


def mid_mb(a, b, t=0.5):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def mx_mb(p):
    # symetrique en x
    return (-p[0], p[1], p[2])


def curve_mb(m, name, pts, widths, depths, roles, ext=0.12, chamf=0.15, **kw):
    # chaine de segments qui se chevauchent (courbe continue), largeur qui varie
    for i in range(len(pts) - 1):
        d = norm_mb(sub_mb(pts[i + 1], pts[i]))
        last = i == len(pts) - 2
        m.beam(f"{name}{i}" + ("_L" if kw.get("mirror") else ""), start=add_mb(pts[i], d, -ext if i else 0),
               end=add_mb(pts[i + 1], d, 0 if last else ext), role=roles[i % len(roles)], width=widths[i], depth=depths[i],
               taper=max(0.05, widths[i + 1] / widths[i]), chamfer=chamf * widths[i + 1], **kw)


def close_gaps_mb(col_name, rounds=25, extra=0.025):
    # ferme les petits ecarts signales par check_model (deplace la piece de la valeur proposee, plus un leger recouvrement)
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


def ground_mb(col_name):
    # pose le point le plus bas sur z = 0
    bpy.context.view_layer.update()
    objs = [o for o in bpy.data.collections[col_name].all_objects if o.type == "MESH"]
    z0 = min(min((o.matrix_world @ v.co).z for v in o.data.vertices) for o in objs)
    for o in objs:
        o.location.z -= z0
    bpy.context.view_layer.update()
    return z0


def save_only_mb(col_name, fname):
    # n'ecrit que la collection du monstre (pas les modeles des autres taches ni les references)
    col = bpy.data.collections[col_name]
    bpy.data.libraries.write(os.path.join(ropilot.FILES_DIR, fname), {col}, fake_user=True, compress=True)


def load_col_mb(col_name, fname):
    # recharge la collection sauvegardee (Blender partage, souvent redemarre) ; remplace celle de la scene
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


def glow_share_mb(col_name):
    # part de surface lumineuse (materiaux « glow ») dans le monstre
    tot = glo = 0.0
    for o in bpy.data.collections[col_name].all_objects:
        if o.type != "MESH":
            continue
        s = o.matrix_world.to_scale()
        a = sum(p.area for p in o.data.polygons) * abs(s[0] * s[1] * s[2]) ** (2 / 3)
        tot += a
        mat = o.material_slots[0].material.name if o.material_slots and o.material_slots[0].material else ""
        if "glow" in mat.lower():
            glo += a
    return round(glo / tot, 4) if tot else 0


def merge_mb(col_name, zones=None):
    # fusionne le monstre en peu de pieces : une par zone (dict nom -> motifs fnmatch, le reste va dans Body)
    # et par materiau lumineux (« <zone>__Glow », Neon dans Studio). Noms finaux « <col>:<zone> ».
    import fnmatch
    zones = zones or {}
    col = bpy.data.collections[col_name]
    objs = [o for o in col.all_objects if o.type == "MESH"]
    owner = {}
    for z, pats in zones.items():
        for o in objs:
            part = o.get("ropilot_part") or re.sub(r"\.\d+$", "", o.name)
            if o.name not in owner and any(fnmatch.fnmatchcase(part, p) for p in pats):
                owner[o.name] = z
    buckets = {}
    for o in objs:
        z = owner.get(o.name, "Body")
        mat = o.material_slots[0].material.name if o.material_slots and o.material_slots[0].material else ""
        glow = "glow" in mat.lower()
        buckets.setdefault((z, mat if glow else ""), []).append(o)
    out, glow_n = [], {}
    for (z, mat), lst in sorted(buckets.items()):
        if mat:
            glow_n[z] = glow_n.get(z, 0) + 1
            name = z + "__Glow" + ("" if glow_n[z] == 1 else str(glow_n[z]))
        else:
            name = z
        bpy.ops.object.select_all(action="DESELECT")
        for o in lst:
            o.select_set(True)
        bpy.context.view_layer.objects.active = lst[0]
        if len(lst) > 1:
            bpy.ops.object.join()
        o = bpy.context.view_layer.objects.active
        o.name = col_name + ":" + name
        o.data.name = col_name + ":" + name
        bm = bmesh.new()
        bm.from_mesh(o.data)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
        bm.to_mesh(o.data)
        bm.free()
        out.append((name, len(o.data.polygons)))
    return out


def tri_count_mb(col_name):
    n = 0
    for o in bpy.data.collections[col_name].all_objects:
        if o.type == "MESH":
            n += sum(len(p.vertices) - 2 for p in o.data.polygons)
    return n
