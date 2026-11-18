# Aides communes aux monstres des anneaux 11 a 14 (SourWorm, SporeBehemoth, TempleColossus, PhantomKing)
# kit ropilot.model, px = 8, sans picots. A executer dans le Blender de Ropilot avant le script du monstre.
import ropilot, bpy, os, math, io, re, contextlib

MREF = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "Monster_Refs")


def refs_mk(n):
    # vues orthogonales du modele genere (generate_mesh) : Renders/Monster_Refs/GenM_<n>_<vue>.png
    return {v: os.path.join(MREF, f"GenM_{n}_{v}.png") for v in ("front", "left", "back", "top")}


def vadd(a, b, k=1.0): return tuple(a[i] + b[i] * k for i in range(3))
def vsub(a, b): return tuple(a[i] - b[i] for i in range(3))
def vmid(a, b, t=0.5): return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def vnorm(v):
    L = math.sqrt(sum(c * c for c in v)) or 1.0
    return tuple(c / L for c in v)


class AutoMirror:
    # toute piece dont le nom finit par _L recoit mirror=True (jumelle _R)
    def __init__(self, m): self.m = m

    def __getattr__(self, k):
        f = getattr(self.m, k)
        if k in ("box", "prism", "beam", "pyramid", "crystal"):
            def g(name, *a, **kw):
                if name.endswith("_L") and "mirror" not in kw:
                    kw["mirror"] = True
                return f(name, *a, **kw)
            return g
        return f


def close_gaps_mk(col_name, rounds=12, extra=0.025):
    # ferme les petits ecarts signales par check_model (quelques centiemes de stud)
    pat = re.compile(r"gap [\d.]+ studs between \S+ and \S+: move (\S+) by \(([-\d.]+), ([-\d.]+), ([-\d.]+)\)")
    fl = re.compile(r"FLOATING (.+?) \(.*move by \(([-\d.]+), ([-\d.]+), ([-\d.]+)\)")
    for _ in range(rounds):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            res = ropilot.check_model(collection=col_name, max_lines=100000)
        if res["floating"] == 0 and res["gaps"] == 0:
            break
        moved = set()
        for line in buf.getvalue().splitlines():
            g = pat.search(line)
            names = None
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
    return ropilot.check_model(collection=col_name, max_lines=6)


def ground_mk(col_name):
    bpy.context.view_layer.update()
    objs = [o for o in bpy.data.collections[col_name].all_objects if o.type == "MESH"]
    z0 = min(min((o.matrix_world @ v.co).z for v in o.data.vertices) for o in objs)
    for o in objs:
        o.location.z -= z0
    bpy.context.view_layer.update()
    return z0


def glow_share_mk(col_name):
    tot = glo = 0.0
    for o in bpy.data.collections[col_name].all_objects:
        if o.type != "MESH":
            continue
        a = sum(p.area for p in o.data.polygons) * (o.matrix_world.to_scale()[0] ** 2)
        tot += a
        mat = o.material_slots[0].material.name if o.material_slots and o.material_slots[0].material else ""
        if "glow" in mat.lower():
            glo += a
    return round(glo / tot, 4) if tot else 0


def save_mine(col, fname=None):
    # n'ecrit que la collection du monstre (Blender partage avec d'autres taches)
    c = bpy.data.collections[col]
    bpy.data.libraries.write(os.path.join(ropilot.FILES_DIR, fname or (col + ".blend")), {c}, fake_user=True, compress=True)


def load_mine(col_name, fname=None):
    old = bpy.data.collections.get(col_name)
    if old:
        for o in list(old.all_objects):
            bpy.data.objects.remove(o, do_unlink=True)
        bpy.data.collections.remove(old)
    path = os.path.join(ropilot.FILES_DIR, fname or (col_name + ".blend"))
    with bpy.data.libraries.load(path, link=False) as (src, dst):
        dst.collections = [c for c in src.collections if c == col_name]
    for c in dst.collections:
        if c is not None:
            bpy.context.scene.collection.children.link(c)
    return bpy.data.collections.get(col_name)


def fuse_mk(col_name):
    # fusionne par materiau (atlas commun, lueur a part) : quelques MeshParts seulement dans Studio
    col = bpy.data.collections[col_name]
    groups = {}
    for o in list(col.all_objects):
        if o.type != "MESH":
            continue
        mat = o.material_slots[0].material.name if o.material_slots and o.material_slots[0].material else "none"
        groups.setdefault(mat, []).append(o)
    out = []
    for mat, objs in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        if len(objs) > 1:
            bpy.ops.object.join()
        o = bpy.context.view_layer.objects.active
        o.name = col_name + ("_Glow" if "glow" in mat.lower() and "orange" not in mat.lower() else
                             "_GlowOrange" if "orange" in mat.lower() else
                             "_Fire" if "fire" in mat.lower() else "_Body")
        out.append((o.name, len(o.data.polygons)))
    return out
