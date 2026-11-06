# Outils Blender communs aux œufs et aux créatures « en briques » (style Lego, picots ajoutés dans Studio).
# Charger dans la session Blender de Ropilot :
#   exec(open(r"<repo>/tools/blender/voxkit.py", encoding="utf-8").read())
#
# - Un modèle est une grille de briques (cells : (x, y, z) -> clé de couleur ; « G:clé » = lumineux)
#   plus des ornements modélisés lisses ou facettés (Ornaments), sans picots.
# - build() fusionne les briques par couleur et par ton d'ombrage (lt/md/dk/xd), et range à part les
#   groupes animés (with layer(m, "Tail"): ...) : objets nommés <nom>_A<Groupe>_...
# - Les couleurs sont converties sRGB -> linéaire : l'import Ropilot les relit comme linéaires,
#   donc Studio reçoit exactement les couleurs hexadécimales de la palette.
# Repère : z vers le haut, l'avant du modèle vers -y, le sol à z = 0 (bas des briques à z = -0.5).

import bpy, bmesh, math, random, colorsys, contextlib
from mathutils import Vector, Matrix


# COULEURS ------------------------------------------------------------------------------------

def hexrgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def tone(rgb, dl, ds=0.0):
    h, l, s = colorsys.rgb_to_hls(*rgb)
    return colorsys.hls_to_rgb(h, max(0, min(1, l + dl)), max(0, min(1, s + ds)))


def s2l(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


MATS = {}


def material(name, rgb, glow=False):
    if name in MATS:
        return MATS[name]
    lin = tuple(s2l(x) for x in rgb)
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    b.inputs['Base Color'].default_value = (*lin, 1)
    b.inputs['Roughness'].default_value = 0.32
    if glow:
        for k in ('Emission Color', 'Emission'):
            if k in b.inputs:
                b.inputs[k].default_value = (*lin, 1)
                break
        if 'Emission Strength' in b.inputs:
            b.inputs['Emission Strength'].default_value = 0.45
    MATS[name] = m
    return m


DIRS6 = [((1, 0, 0), 'x'), ((-1, 0, 0), 'x'), ((0, 1, 0), 'y'), ((0, -1, 0), 'y'), ((0, 0, 1), 'z'), ((0, 0, -1), 'z')]
LIGHT = Vector((-0.5, -0.6, 0.62)).normalized()
TONES = {'lt': (0.06, 0.02), 'md': (0.0, 0.0), 'dk': (-0.10, 0.05), 'xd': (-0.20, 0.08)}


# ORNEMENTS MODÉLISÉS -------------------------------------------------------------------------

def _orient(direction):
    d = Vector(direction).normalized()
    return Vector((0, 0, 1)).rotation_difference(d).to_matrix().to_4x4()


def orn_sweep(bm, pts, radii, sides=10, flat=1.0, twist_up=Vector((0, 0, 1)), profile=None):
    """Tube lisse le long d'une courbe (cornes, queues, plumes si flat < 1)."""
    pts = [Vector(p) for p in pts]
    dense, dr = [], []
    for i in range(len(pts) - 1):
        p0 = pts[i - 1] if i > 0 else pts[i]
        p1, p2 = pts[i], pts[i + 1]
        p3 = pts[i + 2] if i + 2 < len(pts) else pts[i + 1]
        for s in range(6):
            t = s / 6
            t2, t3 = t * t, t * t * t
            dense.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
            dr.append(radii[i] + (radii[i + 1] - radii[i]) * t)
    dense.append(pts[-1])
    dr.append(radii[-1])
    up0 = Vector(twist_up)
    rings = []
    for k, p in enumerate(dense):
        tan = (dense[min(k + 1, len(dense) - 1)] - dense[max(k - 1, 0)]).normalized()
        side = tan.cross(up0)
        if side.length < 1e-4:
            side = tan.cross(Vector((1, 0, 0)))
        side.normalize()
        up = side.cross(tan).normalized()
        r = max(dr[k], 0.02)
        ring = []
        for i in range(sides):
            th = i / sides * math.tau
            m = profile(th) if profile else 1.0
            ring.append(bm.verts.new(p + (side * math.cos(th) + up * math.sin(th) * flat) * r * m))
        rings.append(ring)
    for k in range(len(rings) - 1):
        a, b = rings[k], rings[k + 1]
        for i in range(sides):
            j = (i + 1) % sides
            bm.faces.new((a[i], a[j], b[j], b[i]))
    bm.faces.new(rings[0][::-1])
    bm.faces.new(rings[-1])


def ribs(n, depth=0.13):
    return lambda th: 1 + depth * math.cos(th * n)


def orn_torus(bm, center, R, r, tilt=0.0, seg=48, sides=10, arc=(0, 1), axis=None):
    rot = _orient(axis) if axis is not None else Matrix.Rotation(tilt, 4, 'X')
    n = max(3, int(seg * (arc[1] - arc[0])) + 1)
    closed = arc == (0, 1)
    rings = []
    for i in range(n):
        f = i / (n if closed else n - 1)
        a = (arc[0] + (arc[1] - arc[0]) * f) * math.tau
        rings.append([bm.verts.new(Vector(center) + rot @ Vector(((R + r * math.cos(b)) * math.cos(a), (R + r * math.cos(b)) * math.sin(a), r * math.sin(b))))
                      for b in (j / sides * math.tau for j in range(sides))])
    for i in range(n if closed else n - 1):
        A, B_ = rings[i], rings[(i + 1) % n]
        for j in range(sides):
            bm.faces.new((A[j], B_[j], B_[(j + 1) % sides], A[(j + 1) % sides]))
    if not closed:
        bm.faces.new(rings[0])
        bm.faces.new(rings[-1][::-1])
    return rot


def orn_crystal(bm, base, direction, length, radius, sides=6, tip=0.35, double=False):
    rot = _orient(direction)
    B0 = Vector(base)
    tw = random.random() * math.tau
    rings = []
    for z, r in ((0, radius * 0.8), (length * (1 - tip), radius)):
        rings.append([bm.verts.new(B0 + rot @ Vector((math.cos(i / sides * math.tau + tw) * r, math.sin(i / sides * math.tau + tw) * r, z))) for i in range(sides)])
    apex = bm.verts.new(B0 + rot @ Vector((radius * 0.08, 0, length)))
    bottom = bm.verts.new(B0 + rot @ Vector((0, 0, -length * (0.35 if double else 0.12))))
    a, b = rings
    for i in range(sides):
        j = (i + 1) % sides
        bm.faces.new((a[i], a[j], b[j], b[i]))
        bm.faces.new((b[i], b[j], apex))
        bm.faces.new((a[j], a[i], bottom))


def orn_gem(bm, center, radius, direction=(0, 0, 1), sides=8):
    """Gemme taillée : couronne plate + pavillon pointu."""
    rot = _orient(direction)
    c = Vector(center)
    table_ = [bm.verts.new(c + rot @ Vector((math.cos(i / sides * math.tau) * radius * 0.55, math.sin(i / sides * math.tau) * radius * 0.55, radius * 0.45))) for i in range(sides)]
    girdle = [bm.verts.new(c + rot @ Vector((math.cos((i + 0.5) / sides * math.tau) * radius, math.sin((i + 0.5) / sides * math.tau) * radius, 0))) for i in range(sides)]
    tip = bm.verts.new(c + rot @ Vector((0, 0, -radius * 0.9)))
    bm.faces.new(table_)
    for i in range(sides):
        j = (i + 1) % sides
        bm.faces.new((table_[i], girdle[i], table_[j]))
        bm.faces.new((girdle[i], girdle[j], table_[j]))
        bm.faces.new((girdle[j], girdle[i], tip))


def orn_ball(bm, center, radius, scale=(1, 1, 1), sub=2):
    vs = bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=radius)['verts']
    bmesh.ops.transform(bm, matrix=Matrix.Translation(Vector(center)) @ Matrix.Diagonal((*scale, 1)), verts=vs)


def orn_cone(bm, base, direction, length, radius, sides=10):
    rot = _orient(direction)
    vs = bmesh.ops.create_cone(bm, cap_ends=True, segments=sides, radius1=radius, radius2=0, depth=length)['verts']
    bmesh.ops.transform(bm, matrix=Matrix.Translation(Vector(base)) @ rot @ Matrix.Translation((0, 0, length / 2)), verts=vs)


def orn_feather(bm, root, tip, width, up=(0, 1, 0)):
    a, b = Vector(root), Vector(tip)
    mid = a.lerp(b, 0.45) + Vector((0, 0, (b - a).length * 0.06))
    orn_sweep(bm, [a, mid, b], [width * 0.45, width, 0.04], sides=8, flat=0.28, twist_up=Vector(up))


def orn_rock(bm, center, radius, rnd, squash=0.72):
    vs = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=radius)['verts']
    for v in vs:
        v.co *= rnd.uniform(0.85, 1.12)
        v.co.z *= squash
    bmesh.ops.rotate(bm, verts=vs, cent=(0, 0, 0), matrix=Matrix.Rotation(rnd.uniform(0, math.tau), 3, 'Z'))
    bmesh.ops.translate(bm, verts=vs, vec=Vector(center))


def orn_star(bm, center, r_out, r_in, thick, normal=(0, -1, 0), spin=0.0):
    rot = _orient(normal)
    c = Vector(center)
    rim = []
    for i in range(10):
        a = i / 10 * math.tau + spin + math.pi / 2
        r = r_out if i % 2 == 0 else r_in
        rim.append(bm.verts.new(c + rot @ Vector((math.cos(a) * r, math.sin(a) * r, 0))))
    f = bm.verts.new(c + rot @ Vector((0, 0, thick)))
    k = bm.verts.new(c + rot @ Vector((0, 0, -thick)))
    for i in range(10):
        j = (i + 1) % 10
        bm.faces.new((rim[i], rim[j], f))
        bm.faces.new((rim[j], rim[i], k))


class Ornaments:
    def __init__(self):
        self.parts = {}  # (groupe, clé, lisse) -> bmesh

    def bm(self, key, group=None, smooth=False):
        k = (group or '', key, smooth)
        if k not in self.parts:
            self.parts[k] = bmesh.new()
        return self.parts[k]

    def build(self, coll, name, palette, offset):
        for (group, key, smooth), bm in self.parts.items():
            bmesh.ops.translate(bm, vec=Vector(offset), verts=bm.verts)
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
            glow = key.startswith('G:')
            base = key[2:] if glow else key
            oname = name + ('_A' + group if group else '') + '_ORN_' + ('G' if glow else '') + base + ('s' if smooth else 'f')
            me = bpy.data.meshes.new(oname)
            bm.to_mesh(me)
            bm.free()
            for p in me.polygons:
                p.use_smooth = smooth
            ob = bpy.data.objects.new(oname, me)
            ob.data.materials.append(material(('Glow_' if glow else 'Orn_') + base, hexrgb(palette[base]), glow))
            coll.objects.link(ob)
        self.parts = {}


# MODÈLE EN BRIQUES ---------------------------------------------------------------------------

class Vox:
    """Grille de briques + ornements. H = hauteur de référence (ombrage), cx = centre en x/y."""

    def __init__(self, H, seed=0, cx=0.0):
        self.cells = {}
        self.H = H
        self.cx = cx
        self.anim = {}
        self.layer = None
        self.orn = Ornaments()
        self.rnd = random.Random(seed)

    def put(self, c, key):
        p = (int(round(c[0])), int(round(c[1])), int(round(c[2])))
        self.cells[p] = key
        if self.layer:
            self.anim[p] = self.layer

    def ell(self, center, radii, key, only_empty=False, cut=None):
        """Ellipsoïde plein. cut(x, y, z) -> True pour exclure une brique."""
        cx, cy, cz = center
        rx, ry, rz = radii
        for x in range(int(math.floor(cx - rx)) - 1, int(math.ceil(cx + rx)) + 2):
            for y in range(int(math.floor(cy - ry)) - 1, int(math.ceil(cy + ry)) + 2):
                for z in range(int(math.floor(cz - rz)) - 1, int(math.ceil(cz + rz)) + 2):
                    if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 + ((z - cz) / rz) ** 2 <= 1:
                        if cut and cut(x, y, z):
                            continue
                        if not only_empty or (x, y, z) not in self.cells:
                            self.put((x, y, z), key)

    def chain(self, pts, radii, key):
        """Suite de boules (queue, cou, pattes courbées)."""
        for i in range(len(pts) - 1):
            a, b = Vector(pts[i]), Vector(pts[i + 1])
            steps = max(2, int((b - a).length * 2))
            for s in range(steps + 1):
                t = s / steps
                r = radii[i] + (radii[i + 1] - radii[i]) * t
                self.ell(a.lerp(b, t), (r, r, r), key)

    def surface(self):
        return [c for c in self.cells if any((c[0] + d[0], c[1] + d[1], c[2] + d[2]) not in self.cells for d, _ in DIRS6)]

    def paint(self, test, key, surface_only=True):
        cells = self.surface() if surface_only else list(self.cells)
        for c in cells:
            if test(*c):
                self.cells[c] = key

    def spots(self, key, n, rad, test=None):
        surf = [c for c in self.surface() if not test or test(*c)]
        for c in self.rnd.sample(sorted(surf), min(n, len(surf))):
            for d in surf:
                if (Vector(d) - Vector(c)).length <= rad:
                    self.cells[d] = key


@contextlib.contextmanager
def layer(m, name):
    m.layer = name
    try:
        yield
    finally:
        m.layer = None


def B(m, key, smooth=False):
    return m.orn.bm(key, m.layer, smooth)


def _build_cells(m, cells, name, palette, offset, coll, center):
    groups = {}
    rnd = random.Random(7)
    for c, key in cells.items():
        x, y, z = c
        if key.startswith('G:'):
            g = key
        else:
            n = Vector((x - center.x, y - center.y, (z - center.z) * 0.8))
            d = n.normalized().dot(LIGHT) if n.length > 0 else 0
            if (x, y, z - 1) not in m.cells and z > 0 and (x, y, z + 1) in m.cells:
                d -= 0.25
            t = 'lt' if d > 0.42 else 'md' if d > -0.05 else 'dk' if d > -0.45 else 'xd'
            if rnd.random() < 0.07:
                t = {'lt': 'md', 'md': 'lt', 'dk': 'md', 'xd': 'dk'}[t]
            g = key + '_' + t
        groups.setdefault(g, []).append(c)
    for g, lst in groups.items():
        bm = bmesh.new()
        for (x, y, z) in lst:
            cx, cy, cz = x + offset[0], y + offset[1], z + offset[2]
            for (dx, dy, dz), ax in DIRS6:
                if (x + dx, y + dy, z + dz) in cells:
                    continue
                c0 = Vector((cx + dx * 0.5, cy + dy * 0.5, cz + dz * 0.5))
                u = Vector((0, 0.5, 0)) if ax == 'x' else Vector((0.5, 0, 0))
                v = Vector((0, 0, 0.5)) if ax != 'z' else Vector((0, 0.5, 0))
                pts = [c0 - u - v, c0 + u - v, c0 + u + v, c0 - u + v]
                if (pts[1] - pts[0]).cross(pts[2] - pts[0]).dot(Vector((dx, dy, dz))) < 0:
                    pts.reverse()
                bm.faces.new([bm.verts.new(p) for p in pts])
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
        bmesh.ops.dissolve_limit(bm, angle_limit=0.001, verts=bm.verts, edges=bm.edges, delimit={'NORMAL'})
        oname = name + '_' + g.replace(':', '')
        me = bpy.data.meshes.new(oname)
        bm.to_mesh(me)
        bm.free()
        ob = bpy.data.objects.new(oname, me)
        if g.startswith('G:'):
            mt = material('Glow_' + g[2:], hexrgb(palette[g[2:]]), True)
        else:
            base, t = g.rsplit('_', 1)
            dl, ds = TONES[t]
            mt = material(base + '_' + t, tone(hexrgb(palette[base]), dl, ds))
        ob.data.materials.append(mt)
        coll.objects.link(ob)


def build(m, name, palette, offset=(0, 0, 0)):
    """Crée la collection <name> : briques (par couleur et ton) + groupes animés + ornements."""
    coll = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(coll)
    xs = [c[0] for c in m.cells] or [0]
    ys = [c[1] for c in m.cells] or [0]
    center = Vector(((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, m.H * 0.45))
    groups = sorted(set(m.anim.values()))
    static = {c: k for c, k in m.cells.items() if c not in m.anim}
    _build_cells(m, static, name, palette, offset, coll, center)
    for g in groups:
        part = {c: k for c, k in m.cells.items() if m.anim.get(c) == g}
        _build_cells(m, part, name + '_A' + g, palette, offset, coll, center)
    m.orn.build(coll, name, palette, offset)
    return coll


def clear_scene():
    for o in list(bpy.data.objects):
        if o.type == 'MESH':
            bpy.data.objects.remove(o, do_unlink=True)
    for cl in list(bpy.data.collections):
        bpy.data.collections.remove(cl)
    for mm in list(bpy.data.materials):
        bpy.data.materials.remove(mm)
    MATS.clear()


print("voxkit chargé")
