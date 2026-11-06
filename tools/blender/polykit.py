# Outils Blender « low-poly facetté » pour les créatures (style des familiers des jeux d'œufs Roblox :
# grosses formes biseautées, facettes nettes, couleurs unies ; picots ajoutés dans Studio).
# Charger voxkit.py d'abord (couleurs, matières, cônes, étoiles…), puis ce fichier.
#
# Une créature = Poly : des pièces par couleur. B(m, clé) = pièce à picots (corps) ;
# D(m, clé) = détail sans picots (yeux, dents, griffes, nez…). Clé « G:… » = lumineux (Neon).
# Groupes animés comme pour les œufs : with layer(m, "Tail"): …  (Tail, WingL, WingR, Orbit).
# Repère : z vers le haut, sol à z = 0, avant de la créature vers -y.

import bpy, bmesh, math, random
from mathutils import Vector, Matrix, Euler


class Poly:
    def __init__(self, seed=0):
        self.parts = {}
        self.layer = None
        self.rnd = random.Random(seed)

    def bm(self, key, stud):
        k = (self.layer or '', key, stud and not key.startswith('G:'))
        if k not in self.parts:
            self.parts[k] = bmesh.new()
        return self.parts[k]


def B(m, key):
    return m.bm(key, True)


def D(m, key):
    return m.bm(key, False)


_TMP = None


def _merge(dst, src):
    """Ajoute la géométrie de src (bmesh temporaire) à dst, puis libère src."""
    global _TMP
    if _TMP is None or _TMP.name not in bpy.data.meshes:
        _TMP = bpy.data.meshes.new("_polytmp")
    src.to_mesh(_TMP)
    src.free()
    dst.from_mesh(_TMP)


def _bevel_all(bm, off):
    if off <= 0:
        return
    kw = dict(geom=list(bm.edges), offset=off, offset_type='OFFSET', segments=1, profile=0.5, clamp_overlap=True)
    try:
        bmesh.ops.bevel(bm, affect='EDGES', **kw)
    except TypeError:
        bmesh.ops.bevel(bm, vertex_only=False, **kw)


def box(bm, center, size, rot=(0, 0, 0), bevel=0.18):
    """Bloc biseauté. size = (largeur x, profondeur y, hauteur z) ; rot = angles (x, y, z) en radians."""
    t = bmesh.new()
    bmesh.ops.create_cube(t, size=1.0)
    bmesh.ops.scale(t, vec=Vector(size), verts=t.verts)
    _bevel_all(t, bevel * min(size))
    bmesh.ops.transform(t, matrix=Matrix.Translation(Vector(center)) @ Euler(rot).to_matrix().to_4x4(), verts=t.verts)
    _merge(bm, t)


def _frame(axis, up):
    a = axis.normalized()
    side = a.cross(Vector(up))
    if side.length < 1e-4:
        side = a.cross(Vector((1, 0, 0)))
    side.normalize()
    fwd = side.cross(a).normalized()
    return a, side, fwd


def frustum(bm, p0, p1, s0, s1, up=(0, 0, 1), bevel=0.15):
    """Tronc de pyramide entre deux points : s0 = (largeur, épaisseur) au départ, s1 à l'arrivée.
    up = la direction qui donne le « dessus » de la section (pour un cou ou un museau : (0, 0, 1))."""
    p0, p1 = Vector(p0), Vector(p1)
    a, side, fwd = _frame(p1 - p0, up)
    t = bmesh.new()

    def ring(p, s):
        w, d = s
        return [t.verts.new(p + side * x * w / 2 + fwd * y * d / 2) for x, y in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    r0, r1 = ring(p0, s0), ring(p1, s1)
    t.faces.new(r0[::-1])
    t.faces.new(r1)
    for i in range(4):
        j = (i + 1) % 4
        t.faces.new((r0[i], r0[j], r1[j], r1[i]))
    bmesh.ops.recalc_face_normals(t, faces=t.faces)
    _bevel_all(t, bevel * min(min(s0), min(s1)))
    _merge(bm, t)


def chain(bm, pts, sizes, up=(0, 0, 1), bevel=0.15):
    """Suite de troncs (pattes, cou, queue). sizes[i] = (largeur, épaisseur) au point i."""
    for i in range(len(pts) - 1):
        a, b = Vector(pts[i]), Vector(pts[i + 1])
        ext = (b - a).normalized() * min(sizes[i + 1]) * 0.3 if i < len(pts) - 2 else Vector()
        frustum(bm, a, b + ext, sizes[i], sizes[i + 1], up=up, bevel=bevel)


def blob(bm, center, radii, rnd=None, jitter=0.1, sub=1):
    """Volume taillé à facettes (muscle, crinière, rocher, touffe)."""
    vs = bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=1.0)['verts']
    for v in vs:
        if rnd:
            v.co *= 1 + rnd.uniform(-jitter, jitter)
        v.co = Vector((v.co.x * radii[0], v.co.y * radii[1], v.co.z * radii[2]))
    bmesh.ops.translate(bm, vec=Vector(center), verts=vs)


def spike(bm, base, direction, length, radius, sides=4):
    orn_cone(bm, base, direction, length, radius, sides=sides)


def slab(bm, pts, normal, thick):
    """Plaque épaisse à partir d'un contour (ailes, nageoires, oreilles, crêtes)."""
    n = Vector(normal).normalized()
    vs = [bm.verts.new(Vector(p) - n * thick / 2) for p in pts]
    f = bm.faces.new(vs)
    r = bmesh.ops.extrude_face_region(bm, geom=[f])
    nv = [g for g in r['geom'] if isinstance(g, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, vec=n * thick, verts=nv)


def flame_shape(bm, base, h, w, back=0.3, sides=5):
    """Flamme taillée à facettes."""
    b = Vector(base)
    orn_sweep(bm, [b, b + Vector((0, back * h * 0.4, h * 0.5)), b + Vector((0, back * h, h))], [w, w * 0.6, 0.03], sides=sides)


# VISAGES ------------------------------------------------------------------------------------

def eyes_cute(m, x, z, fy, w=1.1, h=1.3, pupil=0.55, look=0.0):
    """Yeux des communs : rectangle blanc + grande pupille noire carrée centrée, reflet blanc
    (regard droit et joyeux, jamais tombant)."""
    for s in (-1, 1):
        box(D(m, 'eyew'), (s * x, fy - 0.06, z), (w, 0.2, h), bevel=0.08)
        box(D(m, 'eyeb'), (s * x - s * w * look, fy - 0.16, z + h * 0.02), (w * pupil, 0.2, h * pupil * 1.2), bevel=0.05)
        box(D(m, 'shine'), (s * x - s * w * look + w * pupil * 0.22, fy - 0.2, z + h * pupil * 0.38), (w * pupil * 0.3, 0.2, h * pupil * 0.3), bevel=0.0)


def eyes_fierce(m, x, z, fy, w=1.3, h=0.8, iris='G:eyeglow', brow='browdk', tilt=0.38):
    """Yeux des rares : amande blanche, iris lumineux, sourcil froncé en V (intérieur plus BAS = air fâché).
    Rotation autour de y : un angle négatif relève le côté +x ; pour l'œil droit (s = +1) on relève
    donc le coin extérieur avec -s * angle."""
    for s in (-1, 1):
        r = (0, -s * tilt * 0.6, 0)
        rb = (0, -s * (tilt + 0.15), 0)
        box(D(m, 'eyew'), (s * x, fy - 0.06, z), (w, 0.2, h), rot=r, bevel=0.15)
        box(D(m, iris), (s * x - s * w * 0.06, fy - 0.17, z - h * 0.02), (w * 0.42, 0.2, h * 0.72), rot=r, bevel=0.1)
        box(D(m, 'eyeb'), (s * x - s * w * 0.06, fy - 0.24, z - h * 0.02), (w * 0.14, 0.2, h * 0.52), rot=r, bevel=0.05)
        box(D(m, 'shine'), (s * x + s * w * 0.05, fy - 0.27, z + h * 0.18), (w * 0.1, 0.2, h * 0.16), bevel=0.0)
        box(D(m, brow), (s * (x - w * 0.08), fy - 0.12, z + h * 0.62), (w * 1.3, 0.5, h * 0.38), rot=rb, bevel=0.1)


def teeth_row(m, x0, x1, y, z, n, length, radius, down=True, key='tooth'):
    for i in range(n):
        x = x0 + (x1 - x0) * (i / max(1, n - 1))
        spike(D(m, key), (x, y, z), (0, -0.15, -1 if down else 1), length * (1.25 if i in (0, n - 1) else 1.0), radius, sides=4)


def claws(m, x, y, z, n=3, length=0.9, radius=0.22, key='claw', spread=0.45):
    for i in range(n):
        dx = (i - (n - 1) / 2) * spread
        spike(D(m, key), (x + dx, y, z), (dx * 0.3, -1, -0.45), length, radius, sides=4)


# CONSTRUCTION -------------------------------------------------------------------------------

def build_poly(m, name, pal, offset=(0, 0, 0)):
    coll = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(coll)
    for (group, key, stud), bm in m.parts.items():
        bmesh.ops.translate(bm, vec=Vector(offset), verts=bm.verts)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bmesh.ops.triangulate(bm, faces=bm.faces)
        glow = key.startswith('G:')
        base = key[2:] if glow else key
        oname = name + ('_A' + group if group else '') + ('_P_' if stud else '_ORN_') + ('G' if glow else '') + base
        me = bpy.data.meshes.new(oname)
        bm.to_mesh(me)
        bm.free()
        for p in me.polygons:
            p.use_smooth = False
        ob = bpy.data.objects.new(oname, me)
        ob.data.materials.append(material(('Glow_' if glow else 'Poly_') + base, hexrgb(pal[base]), glow))
        coll.objects.link(ob)
    m.parts = {}
    return coll


print("polykit chargé")
