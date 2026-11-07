# 25 types de pierres précieuses (minerais des géodes), facettées comme de vraies tailles.
# Usage (Blender de Ropilot) : exec(open(r"<repo>/tools/blender/gems.py", encoding="utf-8").read()); build_all()
# Chaque type est fait de 1 à 3 objets dans la collection « GemTypes », nommés « Gnn_Type_Part » :
#   Gem      la pierre (couleur et matière posées dans Studio selon le minerai : tools/gems-install.lua)
#   Core     copie réduite de la pierre, au centre : cœur lumineux (Neon) des minerais Epic et plus
#   Base     roche (grappes, géode)      Setting   monture dorée (joyau serti)
# Debout, la table face à l'avant (-Y dans Blender = vers la caméra), environ 2 studs de haut.
import bpy, bmesh, math, random
from mathutils import Vector, Matrix

TAU = math.pi * 2
COLORS = {"Gem": (0.92, 0.95, 1.0), "Core": (1, 1, 1), "Base": (0.36, 0.33, 0.30), "Setting": (0.85, 0.65, 0.13)}


# CONTOURS ------------------------------------------------------------------------------------
# Un contour est une fonction r(angle) dans le plan de la pierre (x à droite, z en haut).

def _poly_fn(pts):
    # contour donné par un polygone (étoilé depuis le centre) : rayon le plus loin le long de chaque angle
    segs = list(zip(pts, pts[1:] + pts[:1]))

    def r(a):
        d = (math.cos(a), math.sin(a))
        best = 0.0
        for (x1, y1), (x2, y2) in segs:
            ex, ey = x2 - x1, y2 - y1
            den = d[0] * ey - d[1] * ex
            if abs(den) < 1e-9:
                continue
            t = (x1 * ey - y1 * ex) / den
            u = (x1 * d[1] - y1 * d[0]) / den
            if t > 0 and -1e-6 <= u <= 1 + 1e-6:
                best = max(best, t)
        return best

    return r


def round_fn(a):
    return 1.0


def oval_fn(a, w=0.74):
    return w / math.sqrt((math.cos(a)) ** 2 + (w * math.sin(a)) ** 2)


def cushion_fn(a, n=4.0):
    return (abs(math.cos(a)) ** n + abs(math.sin(a)) ** n) ** (-1 / n)


def square_fn(a):
    return 1 / max(abs(math.cos(a)), abs(math.sin(a)))


def marquise_fn():
    pts = []
    for i in range(41):
        t = -1 + 2 * i / 40
        pts.append((0.46 * (1 - t * t), t))
    pts += [(-x, y) for x, y in reversed(pts[1:-1])]
    return _poly_fn(pts)


def pear_fn():
    pts = []
    c, R = (0.0, -0.32), 0.66
    for i in range(25):  # arc du bas, de la gauche à la droite
        a = math.radians(160 + 220 * i / 24)
        pts.append((c[0] + R * math.cos(a), c[1] + R * math.sin(a)))
    p0 = pts[-1]
    for i in range(1, 21):  # côté droit jusqu'à la pointe
        t = i / 20
        q = (0.62, 0.42)
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * q[0] + t * t * 0
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * q[1] + t * t * 1.0
        pts.append((x, y))
    p1 = pts[0]
    for i in range(19, 0, -1):  # côté gauche, symétrique
        t = i / 20
        q = (-0.62, 0.42)
        x = (1 - t) ** 2 * p1[0] + 2 * (1 - t) * t * q[0]
        y = (1 - t) ** 2 * p1[1] + 2 * (1 - t) * t * q[1] + t * t * 1.0
        pts.append((x, y))
    return _poly_fn(pts)


def heart_fn():
    pts = []
    for i in range(80):
        t = TAU * i / 80
        x = 16 * math.sin(t) ** 3 / 17
        y = (13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)) / 17
        pts.append((x, y + 0.1))
    return _poly_fn(pts)


def trillion_fn():
    pts = []
    corners = [(0, 1), (0.866, -0.5), (-0.866, -0.5)]
    for k in range(3):
        a, b = corners[k], corners[(k + 1) % 3]
        for i in range(10):
            t = i / 10
            x, y = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
            bulge = 1 + 0.12 * math.sin(math.pi * t)  # côtés légèrement bombés
            pts.append((x * bulge, y * bulge))
    return _poly_fn(pts)


def star_fn(points=6, inner=0.52):
    pts = []
    for i in range(points * 2):
        a = math.pi / 2 + math.pi * i / points
        r = 1 if i % 2 == 0 else inner
        pts.append((r * math.cos(a), r * math.sin(a)))
    return _poly_fn(pts)


# MAILLAGES -----------------------------------------------------------------------------------

def _obj(name, bm, col, kind, smooth=False):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = smooth
    o = bpy.data.objects.new(name, me)
    col.objects.link(o)
    mat = bpy.data.materials.get("Gem_" + kind) or bpy.data.materials.new("Gem_" + kind)
    mat.use_nodes = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*COLORS[kind], 1)
    o.data.materials.append(mat)
    return o


def _rings(bm, fn, n, specs, sx, sz, culet=None, table=True, close_back=False):
    # specs : (échelle, profondeur w (avant = -), demi-pas de rotation 0/1)
    rings = []
    for scale, w, half in specs:
        ring = []
        for i in range(n):
            a = TAU * (i + 0.5 * half) / n
            r = fn(a) * scale
            ring.append(bm.verts.new((math.cos(a) * r * sx, w, math.sin(a) * r * sz)))
        rings.append((ring, half))
    for (A, ha), (B, hb) in zip(rings, rings[1:]):
        for i in range(n):
            j = (i + 1) % n
            if ha == hb:
                bm.faces.new((A[i], A[j], B[j], B[i]))
            elif hb > ha:  # B[i] entre A[i] et A[i+1]
                bm.faces.new((A[i], A[j], B[i]))
                bm.faces.new((B[i], A[j], B[j]))
            else:  # A[i] entre B[i] et B[i+1]
                bm.faces.new((B[i], B[j], A[i]))
                bm.faces.new((A[i], B[j], A[j]))
    if table:
        bm.faces.new(list(reversed(rings[0][0])))
    last = rings[-1][0]
    if culet is not None:
        tip = bm.verts.new(culet)
        for i in range(n):
            bm.faces.new((last[i], last[(i + 1) % n], tip))
    elif close_back:
        bm.faces.new(last)
    return rings


def brilliant(col, name, fn, n=16, sx=1.0, sz=1.0, crown=0.32, girdle=0.06, pav=0.85, table=0.56, core=True):
    def build(k):
        bm = bmesh.new()
        g = girdle / 2
        specs = [(table, -crown, 0), (0.83, -crown * 0.48, 1), (1.0, -g, 0), (1.0, g, 0), (0.55, g + pav * 0.52, 1)]
        _rings(bm, fn, n, [(s * k, w * k, h) for s, w, h in specs], sx, sz, culet=(0, (g + pav) * k, 0))
        return bm

    _obj(name + "_Gem", build(1.0), col, "Gem")
    if core:
        _obj(name + "_Core", build(0.5), col, "Core")


def step_cut(col, name, pts, sx=1.0, sz=1.0, crown=0.26, girdle=0.06, pav=0.7, core=True):
    fn_pts = pts

    def build(k):
        bm = bmesh.new()
        g = girdle / 2
        specs = [(0.7, -crown), (0.86, -crown * 0.5), (1.0, -g), (1.0, g), (0.78, g + pav * 0.35), (0.5, g + pav * 0.7), (0.2, g + pav)]
        rings = []
        for s, w in specs:
            rings.append([bm.verts.new((x * s * sx * k, w * k, y * s * sz * k)) for x, y in fn_pts])
        n = len(fn_pts)
        for A, B in zip(rings, rings[1:]):
            for i in range(n):
                j = (i + 1) % n
                bm.faces.new((A[i], A[j], B[j], B[i]))
        bm.faces.new(list(reversed(rings[0])))
        bm.faces.new(rings[-1])
        return bm

    _obj(name + "_Gem", build(1.0), col, "Gem")
    if core:
        _obj(name + "_Core", build(0.5), col, "Core")


def _prism(bm, sides, r, h, at=Vector(), rot=None, top=0.0, bottom=0.0, jitter=0.0, rng=None, taper=1.0):
    rng = rng or random.Random(1)
    rot = rot if rot is not None else Matrix.Identity(3)
    ring0, ring1 = [], []
    for i in range(sides):
        a = TAU * i / sides
        jr = 1 + (rng.uniform(-jitter, jitter) if jitter else 0)
        ring0.append(bm.verts.new(at + rot @ Vector((math.cos(a) * r * jr, math.sin(a) * r * jr, 0))))
        ring1.append(bm.verts.new(at + rot @ Vector((math.cos(a) * r * jr * taper, math.sin(a) * r * jr * taper, h))))
    for i in range(sides):
        j = (i + 1) % sides
        bm.faces.new((ring0[i], ring0[j], ring1[j], ring1[i]))
    if top > 0:
        tip = bm.verts.new(at + rot @ Vector((rng.uniform(-0.04, 0.04) * r, rng.uniform(-0.04, 0.04) * r, h + top)))
        for i in range(sides):
            bm.faces.new((ring1[i], ring1[(i + 1) % sides], tip))
    else:
        bm.faces.new(ring1)
    if bottom > 0:
        tip = bm.verts.new(at + rot @ Vector((0, 0, -bottom)))
        for i in range(sides):
            bm.faces.new((ring0[(i + 1) % sides], ring0[i], tip))
    else:
        bm.faces.new(list(reversed(ring0)))


def _rock(bm, scale, at=Vector(), seed=1, sub=1, jitter=0.18):
    rng = random.Random(seed)
    res = bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=1.0)
    for v in res["verts"]:
        v.co = Vector((v.co.x * scale[0], v.co.y * scale[1], v.co.z * scale[2])) * (1 + rng.uniform(-jitter, jitter)) + at


def _tilt(x_deg, y_deg, z_deg=0):
    return (Matrix.Rotation(math.radians(z_deg), 3, "Z") @ Matrix.Rotation(math.radians(y_deg), 3, "Y")
            @ Matrix.Rotation(math.radians(x_deg), 3, "X"))


def _single(col, name, make, core=True, kind="Gem", smooth=False):
    bm = bmesh.new()
    make(bm, 1.0)
    _obj(name + "_" + kind, bm, col, kind, smooth)
    if core:
        bm = bmesh.new()
        make(bm, 0.5)
        _obj(name + "_Core", bm, col, "Core", smooth)


# LES 25 TYPES ----------------------------------------------------------------------------------

def build_types(col):
    T = []

    def add(name, fn):
        T.append((name, fn))

    # bruts
    add("QuartzPoint", lambda n: _single(col, n, lambda bm, k: _prism(bm, 6, 0.42 * k, 1.35 * k, at=Vector((0, 0, -0.95 * k)), top=0.6 * k, jitter=0.06, rng=random.Random(2))))

    def cluster(n):
        bm = bmesh.new()
        _rock(bm, (1.25, 0.9, 0.42), at=Vector((0, 0, -0.75)), seed=3)
        _obj(n + "_Base", bm, col, "Base")
        bm = bmesh.new()
        rng = random.Random(4)
        _prism(bm, 6, 0.3, 1.25, at=Vector((0, 0, -0.65)), top=0.42, rng=rng, jitter=0.05)
        for i in range(7):
            a = TAU * i / 7 + rng.uniform(-0.3, 0.3)
            rr = rng.uniform(0.35, 0.8)
            at = Vector((math.cos(a) * rr, math.sin(a) * rr * 0.6, -0.65))
            rot = Matrix.Rotation(-math.atan2(math.cos(a), math.sin(a)), 3, "Z") @ Matrix.Rotation(math.radians(rng.uniform(25, 45)), 3, "X")
            _prism(bm, 6, rng.uniform(0.14, 0.24), rng.uniform(0.5, 0.95), at=at, rot=rot, top=rng.uniform(0.2, 0.32), rng=rng, jitter=0.05)
        _obj(n + "_Gem", bm, col, "Gem")

    add("Cluster", cluster)

    def rhomb(bm, k):
        res = bmesh.ops.create_cube(bm, size=1.0)
        m = Matrix(((0.95, 0, 0.42), (0, 0.8, 0.25), (0, 0, 1.45)))
        for v in res["verts"]:
            v.co = (m @ v.co) * k

    add("Rhomb", lambda n: _single(col, n, rhomb))

    def cubes(n):
        bm = bmesh.new()
        for size, at, rot in [(1.0, (0, 0, 0), (0, 0, 15)), (0.7, (0.45, -0.2, 0.45), (30, 10, 40)), (0.55, (-0.45, 0.15, 0.4), (-20, 25, -10))]:
            res = bmesh.ops.create_cube(bm, size=size)
            r = _tilt(*rot)
            for v in res["verts"]:
                v.co = r @ v.co + Vector(at)
        _obj(n + "_Gem", bm, col, "Gem")

    add("CubeCluster", cubes)

    def octa(bm, k):
        a, h = 0.75 * k, 1.05 * k
        vs = [bm.verts.new(p) for p in [(a, 0, 0), (0, a, 0), (-a, 0, 0), (0, -a, 0)]]
        top, bot = bm.verts.new((0, 0, h)), bm.verts.new((0, 0, -h))
        for i in range(4):
            bm.faces.new((vs[i], vs[(i + 1) % 4], top))
            bm.faces.new((vs[(i + 1) % 4], vs[i], bot))

    add("Octahedron", lambda n: _single(col, n, octa))
    # tailles brillant (table vers l'avant)
    add("RoundBrilliant", lambda n: brilliant(col, n, round_fn, n=16))
    add("Princess", lambda n: brilliant(col, n, square_fn, n=16, sx=0.8, sz=0.8, crown=0.24, pav=0.75, table=0.62))
    add("EmeraldCut", lambda n: step_cut(col, n, [(0.42, 0.7), (0.3, 0.82), (-0.3, 0.82), (-0.42, 0.7), (-0.42, -0.7), (-0.3, -0.82), (0.3, -0.82), (0.42, -0.7)], sx=1.6, sz=1.15))
    add("Oval", lambda n: brilliant(col, n, oval_fn, n=18))
    add("Pear", lambda n: brilliant(col, n, pear_fn(), n=20))
    add("Marquise", lambda n: brilliant(col, n, marquise_fn(), n=20, sz=1.05))
    add("Heart", lambda n: brilliant(col, n, heart_fn(), n=24))
    add("Cushion", lambda n: brilliant(col, n, cushion_fn, n=20, sx=0.85, sz=0.85))
    add("Trillion", lambda n: brilliant(col, n, trillion_fn(), n=18, crown=0.22, pav=0.7))
    add("Baguette", lambda n: step_cut(col, n, [(0.22, 0.9), (-0.22, 0.9), (-0.22, -0.9), (0.22, -0.9)], sx=1.6, sz=1.15, crown=0.2, pav=0.5))

    # cabochons et perles (lisses)
    def cabochon(bm, k, pear=False):
        res = bmesh.ops.create_uvsphere(bm, u_segments=28, v_segments=18, radius=1.0)
        for v in res["verts"]:
            x, y, z = v.co
            w = 0.74
            if pear:
                w *= (1 - 0.55 * max(0.0, z) ** 1.3)
            y = y * 0.42 if y < 0 else min(y * 0.42, 0.06)
            v.co = Vector((x * w, y, z)) * k

    add("Cabochon", lambda n: _single(col, n, cabochon, core=False, smooth=True))
    add("Pearl", lambda n: _single(col, n, lambda bm, k: bmesh.ops.create_uvsphere(bm, u_segments=32, v_segments=20, radius=0.95 * k), core=False, smooth=True))
    add("TearCabochon", lambda n: _single(col, n, lambda bm, k: cabochon(bm, k, pear=True), core=False, smooth=True))
    add("Nugget", lambda n: _single(col, n, lambda bm, k: _rock(bm, (0.95 * k, 0.75 * k, 0.85 * k), seed=7, sub=2, jitter=0.12)))
    add("DoublePoint", lambda n: _single(col, n, lambda bm, k: _prism(bm, 6, 0.36 * k, 1.2 * k, at=Vector((0, 0, -0.6 * k)), rot=_tilt(0, 18), top=0.42 * k, bottom=0.42 * k, rng=random.Random(9), jitter=0.04)))

    def geode(n):
        # demi-coque de roche ouverte vers l'avant, tapissée de pointes de cristal
        bm = bmesh.new()
        rng = random.Random(11)
        segs, rows = 18, 7
        outer, inner = [], []
        for ri in range(rows + 1):
            phi = (math.pi / 2) * ri / rows  # 0 = bord, pi/2 = fond
            ro, ri_ = [], []
            for si in range(segs):
                a = TAU * si / segs
                jo = 1 + rng.uniform(-0.06, 0.06)
                d = Vector((math.cos(a) * math.cos(phi), math.sin(phi), math.sin(a) * math.cos(phi)))
                ro.append(bm.verts.new(Vector((d.x, d.y * 0.75, d.z)) * 1.0 * jo))
                ri_.append(bm.verts.new(Vector((d.x, d.y * 0.75, d.z)) * 0.8))
            outer.append(ro)
            inner.append(ri_)
        for R in (outer, inner):
            for ri in range(rows):
                for si in range(segs):
                    sj = (si + 1) % segs
                    f = (R[ri][si], R[ri][sj], R[ri + 1][sj], R[ri + 1][si])
                    bm.faces.new(f if R is outer else tuple(reversed(f)))
        for si in range(segs):  # bord
            sj = (si + 1) % segs
            bm.faces.new((outer[0][sj], outer[0][si], inner[0][si], inner[0][sj]))
        _obj(n + "_Base", bm, col, "Base")
        bm = bmesh.new()
        for i in range(34):
            a = rng.uniform(0, TAU)
            phi = rng.uniform(0.15, 1.45)
            d = Vector((math.cos(a) * math.cos(phi), math.sin(phi) * 0.75, math.sin(a) * math.cos(phi)))
            base = d * 0.79
            inward = (-base).normalized()
            rot = inward.to_track_quat("Z", "Y").to_matrix()
            _prism(bm, 4, rng.uniform(0.07, 0.12), 0.05, at=base, rot=rot, top=rng.uniform(0.2, 0.38), rng=rng)
        _obj(n + "_Gem", bm, col, "Gem")

    add("Geode", geode)
    add("Star", lambda n: brilliant(col, n, star_fn(), n=24, crown=0.3, pav=0.55, table=0.5))
    add("Column", lambda n: _single(col, n, lambda bm, k: _prism(bm, 6, 0.4 * k, 1.75 * k, at=Vector((0, 0, -1.0 * k)), top=0.12 * k, taper=0.92, rng=random.Random(13), jitter=0.03)))
    add("Orb", lambda n: _single(col, n, lambda bm, k: bmesh.ops.create_icosphere(bm, subdivisions=2, radius=0.95 * k)))

    def jewel(n):
        brilliant(col, n, oval_fn, n=18, sx=0.85, sz=0.85)
        bm = bmesh.new()
        # chaton : anneau d'or derrière le rondiste, et 4 griffes qui tiennent la pierre
        nseg = 24
        ring_a, ring_b, ring_c, ring_d = [], [], [], []
        for i in range(nseg):
            a = TAU * i / nseg
            r = oval_fn(a)
            for lst, s, w in ((ring_a, 0.98, 0.0), (ring_b, 1.12, 0.0), (ring_c, 1.12, 0.38), (ring_d, 0.9, 0.38)):
                lst.append(bm.verts.new((math.cos(a) * r * 0.85 * s, w, math.sin(a) * r * 0.85 * s)))
        for A, B in ((ring_a, ring_b), (ring_b, ring_c), (ring_c, ring_d), (ring_d, ring_a)):
            for i in range(nseg):
                j = (i + 1) % nseg
                bm.faces.new((A[i], A[j], B[j], B[i]))
        for a in (45, 135, 225, 315):
            ar = math.radians(a)
            r = oval_fn(ar) * 0.85
            p = Vector((math.cos(ar) * r, 0, math.sin(ar) * r))
            rot = Matrix.Rotation(math.radians(90), 3, "X")
            _prism(bm, 4, 0.07, 0.42, at=p * 1.02 + Vector((0, 0.3, 0)), rot=rot, top=0.06)
        # couronne de pointes dorées en haut
        for i, a in enumerate((60, 75, 90, 105, 120)):
            ar = math.radians(a)
            r = oval_fn(ar) * 0.85 * 1.12
            h = 0.5 if a == 90 else 0.32
            _prism(bm, 4, 0.06, 0.05, at=Vector((math.cos(ar) * r, 0.12, math.sin(ar) * r)), rot=Vector((math.cos(ar), 0, math.sin(ar))).to_track_quat("Z", "Y").to_matrix(), top=h)
        _obj(n + "_Setting", bm, col, "Setting")

    add("Jewel", jewel)
    return T


def build_all(cols=5, spacing=4.0):
    old = bpy.data.collections.get("GemTypes")
    if old:
        for o in list(old.all_objects):
            bpy.data.objects.remove(o, do_unlink=True)
        bpy.data.collections.remove(old)
    col = bpy.data.collections.new("GemTypes")
    bpy.context.scene.collection.children.link(col)
    types = build_types(col)
    names = []
    for i, (tname, fn) in enumerate(types):
        name = "G%02d_%s" % (i + 1, tname)
        before = set(o.name for o in col.objects)
        fn(name)
        new = [o for o in col.objects if o.name not in before]
        # chaque type posé sur une grille, le bas à z = 0
        zmin = min((o.matrix_world @ Vector(c)).z for o in new for c in o.bound_box)
        for o in new:
            for v in o.data.vertices:
                v.co.z -= zmin
            o.location = ((i % cols) * spacing, (i // cols) * spacing, 0)
        names.append(name)
    return names
