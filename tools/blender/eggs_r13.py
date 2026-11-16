# Œufs de l'anneau 13 « Jade Temple » (ruines d'un temple antique de jade et d'or qui flottent dans l'espace : pierre
# sculptée, jade poli, or gravé, disques solaires, motifs en escalier et en zigzag, plumes rouges et bleues,
# scarabées, petites idoles), même méthode que les anneaux 1 à 12 :
# corps en briques (voxkit.Vox) + ornements lisses (_ORN_), groupes animés (_ACrown_, _AOrbit_, _AHalo_, _AWingL_,
# _AWingR_). Charger voxkit.py avant ce fichier, puis build_all() ou build_one(n).
# clash(coll) vérifie qu'un groupe qui tourne ne traverse ni les ailes qui battent ni les ornements fixes ;
# neon_share(coll) donne la part de surface en néon (à garder sous 5 %).
# Les clés de couleur lumineuses commencent par « g » (ggold13...) : neon_share les reconnaît ainsi.
# Les couleurs sont converties sRGB -> linéaire par voxkit.material (l'import Ropilot les relit comme linéaires).
# Blender est partagé : charger voxkit puis ce fichier dans un espace de noms à part, par exemple
#   NS = {}; exec(open(voxkit).read(), NS); exec(open(eggs_r13).read(), NS); NS['build_all']()

TAU = math.tau

P13 = dict(
    jade13='#3FB37F', jaded13='#1F6E4E', jadel13='#8FE0B4', jadex13='#2E9468',
    gold13='#F2C14E', goldd13='#B8862B', goldl13='#FFE08A',
    stone13='#B8A88A', stoned13='#6E6352', stonel13='#D3C6A6',
    turq13='#3EC9D6', turqd13='#2A97A3',
    brick13='#B5482F', brickd13='#86321F',
    cream13='#F4EAD0',
    fred13='#E5484D', fblue13='#3E7BE0',
    ink13='#2A2620',
    gemt13='#3EC9D6', gemj13='#2FBF7A', gemr13='#E5484D',
    ggold13='#FFD25E', gturq13='#5FE6F0', gjade13='#2FCB80',
)

OFFSETS = {2: 0, 3: 34, 4: 70, 5: 112, 6: 162, 7: 222}
SIZES = {2: (11, 15), 3: (11, 17), 4: (13, 19), 5: (15, 22), 6: (17, 25), 7: (21, 29)}

# BRUIT ET PROFIL (comme les anneaux 8 à 11) --------------------------------------------------

def _h(ix, iy, iz, seed):
    n = ((ix * 73856093) ^ (iy * 19349663) ^ (iz * 83492791) ^ (seed * 2654435761)) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    n ^= n >> 16
    return (n & 0xFFFF) / 65535.0


def vnoise(x, y, z, seed, period=3.0):
    x /= period
    y /= period
    z /= period
    x0, y0, z0 = math.floor(x), math.floor(y), math.floor(z)
    fx, fy, fz = x - x0, y - y0, z - z0
    fx, fy, fz = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy), fz * fz * (3 - 2 * fz)
    v = 0.0
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                w = (fx if dx else 1 - fx) * (fy if dy else 1 - fy) * (fz if dz else 1 - fz)
                v += w * _h(x0 + dx, y0 + dy, z0 + dz, seed)
    return v * 2 - 1


def egg_r(t, R, t0=0.37):
    if t < t0:
        u = (t0 - t) / t0
        return R * math.sqrt(max(0.0, 1 - 0.94 * u * u))
    s = (t - t0) / (1 - t0)
    return R * max(0.0, 1 - s ** 1.35) ** 0.7


def egg_body(m, W, H, key, seed, bump=0.75, t0=0.37):
    """Corps d'œuf en briques : W de large (impair), H de haut (z de -0.5 à H-0.5), surface bosselée."""
    R = W / 2
    lim = (W - 1) // 2
    m.Hc, m.W = H, W
    for z in range(H):
        t = (z + 0.5) / (H + 0.8)
        r = egg_r(t, R, t0)
        for x in range(-lim, lim + 1):
            for y in range(-lim, lim + 1):
                d = math.hypot(x, y)
                n = vnoise(x, y, z, seed) * bump
                if d <= r - 0.45 + n or (x == 0 and y == 0):
                    m.put((x, y, z), key)
    zw = int(round(t0 * (H + 0.8) - 0.5))
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        for k in (lim, lim - 1):
            m.put((dx * k, dy * k, zw), key)
    seen, todo = {(0, 0, 0)}, [(0, 0, 0)]
    while todo:
        c = todo.pop()
        for d, _ in DIRS6:
            p = (c[0] + d[0], c[1] + d[1], c[2] + d[2])
            if p in m.cells and p not in seen:
                seen.add(p)
                todo.append(p)
    for c in list(m.cells):
        if c not in seen:
            del m.cells[c]
    m.body = set(m.cells)


def rs(m, th, z):
    """Distance de l'axe à la surface du corps, à la hauteur z, dans la direction th."""
    zi = max(0, min(m.Hc - 1, int(round(z))))
    c, s = math.cos(th), math.sin(th)
    best = 0.0
    for k in range(170):
        d = k * 0.1
        if (int(round(c * d)), int(round(s * d)), zi) in m.body:
            best = d
    return best + 0.05


def rss(m, th, z):
    return (rs(m, th - 0.2, z) + rs(m, th, z) + rs(m, th + 0.2, z)) / 3


def rmax(m, z):
    """Le plus grand rayon du corps à la hauteur z (tous côtés), pour ce qui tourne autour."""
    return max(rs(m, i / 32 * TAU, z) for i in range(32))


def ztop(m, x, y):
    """Haut de la colonne de briques en (x, y) (face supérieure)."""
    xi, yi = int(round(x)), int(round(y))
    zs = [c[2] for c in m.body if c[0] == xi and c[1] == yi]
    return (max(zs) + 0.5) if zs else -0.5


def pol(r, a, z):
    return Vector((r * math.cos(a), r * math.sin(a), z))


def frame(n):
    """Repère d'une face tournée vers n : u horizontal (vers la droite vu de face), v vers le haut."""
    n = Vector(n).normalized()
    u = Vector((0, 0, 1)).cross(n)
    if u.length < 1e-3:
        u = Vector((1, 0, 0))
    u.normalize()
    v = n.cross(u).normalized()
    return n, u, v


def wave(th, n=6, amp=0.6, phase=0.0):
    """Bord ondulé (festons) pour les bandes peintes."""
    return amp * math.sin(n * th + phase)


def surf_r(m, th, z, k=0.0, dz=0.0):
    """Rayon du corps autour de (th, z), au plus large sur une petite zone (pour poser sans rentrer dedans)."""
    return max(rs(m, th + da, z + d) for da in (-k, 0, k) for d in (-dz, 0, dz))


# PRIMITIVES ----------------------------------------------------------------------------------

def orn_plate(bm, pts2d, origin, u, v, n, thick):
    """Plaque épaisse découpée selon un contour 2D (u, v), face vers n."""
    O, u, v, n = Vector(origin), Vector(u), Vector(v), Vector(n)
    top = [bm.verts.new(O + u * x + v * y + n * (thick / 2)) for x, y in pts2d]
    bot = [bm.verts.new(O + u * x + v * y - n * (thick / 2)) for x, y in pts2d]
    caps = [bm.faces.new(top), bm.faces.new(bot[::-1])]
    k = len(pts2d)
    for i in range(k):
        j = (i + 1) % k
        bm.faces.new((top[i], bot[i], bot[j], top[j]))
    bmesh.ops.triangulate(bm, faces=caps)


def orn_cyl(bm, base, direction, length, r0, r1=None, sides=16):
    """Cylindre (ou tronc de cône si r1) fermé, de base vers base + direction * length."""
    rot = _orient(direction)
    r1 = r0 if r1 is None else r1
    vs = bmesh.ops.create_cone(bm, cap_ends=True, segments=sides, radius1=r0, radius2=r1, depth=length)['verts']
    bmesh.ops.transform(bm, matrix=Matrix.Translation(Vector(base)) @ rot @ Matrix.Translation((0, 0, length / 2)),
                        verts=vs)


def tube(bm, pts, radii, sides=8, profile=None, flat=1.0, ref=None, caps=True):
    """Tube le long d'une polyligne (sans lissage : donner des points serrés), repère transporté le long du tracé."""
    pts = [Vector(p) for p in pts]
    n = len(pts)
    if not hasattr(radii, '__len__'):
        radii = [radii] * n
    T = [(pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized() for i in range(n)]
    ref = Vector(ref) if ref is not None else (Vector((0, 0, 1)) if abs(T[0].z) < 0.9 else Vector((1, 0, 0)))
    s = T[0].cross(ref)
    if s.length < 1e-6:
        s = T[0].orthogonal()
    s.normalize()
    rings = []
    for i in range(n):
        if i:
            s = s - T[i] * s.dot(T[i])
            if s.length < 1e-6:
                s = T[i].orthogonal()
            s.normalize()
        u = s.cross(T[i]).normalized()
        ring = []
        for j in range(sides):
            th = j / sides * TAU
            k = profile(th) if profile else 1.0
            ring.append(bm.verts.new(pts[i] + (s * math.cos(th) + u * math.sin(th) * flat) * radii[i] * k))
        rings.append(ring)
    for i in range(n - 1):
        a, b = rings[i], rings[i + 1]
        for j in range(sides):
            k = (j + 1) % sides
            bm.faces.new((a[j], a[k], b[k], b[j]))
    if caps:
        bm.faces.new(rings[0][::-1])
        bm.faces.new(rings[-1])


def dense(pts, step=0.15):
    """Points serrés le long d'une polyligne."""
    pts = [Vector(p) for p in pts]
    out = [pts[0]]
    for a, b in zip(pts, pts[1:]):
        k = max(1, int((b - a).length / step))
        out += [a.lerp(b, (i + 1) / k) for i in range(k)]
    return out


def helix_along(P, r, pitch, ref, phase=0.0):
    """Hélice enroulée à la distance r autour d'un tracé P (ref : vecteur perpendiculaire au plan du tracé)."""
    ref = Vector(ref).normalized()
    out, s = [], 0.0
    for i, p in enumerate(P):
        if i:
            s += (P[i] - P[i - 1]).length
        t = (P[min(i + 1, len(P) - 1)] - P[max(i - 1, 0)]).normalized()
        e1 = (ref - t * ref.dot(t))
        if e1.length < 1e-6:
            e1 = t.orthogonal()
        e1.normalize()
        e2 = t.cross(e1)
        ph = phase + s / pitch * TAU
        out.append(p + (e1 * math.cos(ph) + e2 * math.sin(ph)) * r)
    return out


def capsule(m, key, a, b, r, sides=8):
    a, b = Vector(a), Vector(b)
    d = b - a
    orn_cyl(B(m, key, True), a, d, d.length, r, sides=sides)
    orn_ball(B(m, key, True), a, r, sub=1)
    orn_ball(B(m, key, True), b, r, sub=1)

# REPRIS DE L'ANNEAU 11 ------------------------------------------------------------------------

def on_faces(m, n, test, mind=0.95, up=True, side=True, seed_shift=0):
    """Choisit n faces de briques visibles du corps (test(x, y, z) sur la brique) : (point, normale, t1, t2)."""
    rnd = random.Random(m.rnd.random() + seed_shift)
    cand = []
    for c in sorted(m.surface()):
        if c not in m.body or not test(*c):
            continue
        for d, ax in DIRS6:
            if d[2] < 0 or (d[2] > 0 and not up) or (d[2] == 0 and not side):
                continue
            if (c[0] + d[0], c[1] + d[1], c[2] + d[2]) not in m.cells:
                cand.append((c, d))
    rnd.shuffle(cand)
    out = []
    for c, d in cand:
        if len(out) >= n:
            break
        nrm = Vector(d)
        t1 = Vector((0, 0, 1)) if d[2] == 0 else Vector((1, 0, 0))
        t2 = nrm.cross(t1)
        p = Vector(c) + nrm * 0.5 + t1 * rnd.uniform(-0.2, 0.2) + t2 * rnd.uniform(-0.2, 0.2)
        if any((p - q[0]).length < mind for q in out):
            continue
        out.append((p, nrm, t1, t2, rnd.uniform(0, TAU)))
    return out


def glow_dots(m, key, n, test=None, mind=3.0):
    surf = sorted(c for c in m.surface() if c in m.body and (not test or test(*c)))
    rnd, chosen, tries = m.rnd, [], 0
    while len(chosen) < n and tries < 800 and surf:
        tries += 1
        c = rnd.choice(surf)
        if all((Vector(c) - Vector(d)).length >= mind for d in chosen):
            chosen.append(c)
    for c in chosen:
        m.cells[c] = key


def nest(m, keys, n, zlo=-0.55, zhi=2.0, tube=(0.32, 0.48), off=(0.15, 0.75)):
    """Nid de racines et de mousse enroulées autour de la base (comme les autres anneaux)."""
    k_w = (m.W / 11) ** 0.6
    tube = (tube[0] * k_w, tube[1] * k_w)
    zhi = zhi * k_w
    rnd = m.rnd
    for i in range(n):
        key = keys[i % len(keys)]
        a0, span = rnd.uniform(0, TAU), rnd.uniform(1.8, 3.4)
        zb, zt = rnd.uniform(zlo, zhi), rnd.uniform(-0.6, 0.6)
        o, ph, tb = rnd.uniform(*off), rnd.uniform(0, TAU), rnd.uniform(*tube)
        k = max(4, int(span / 0.45) + 1)
        pts, rad = [], []
        for j in range(k):
            f = j / (k - 1)
            a = a0 + span * f
            z = max(zlo - 0.15, min(zhi + 0.3, zb + zt * f + 0.25 * math.sin(f * 5 + ph)))
            r = rss(m, a, 2.2) - 0.35 + o + (o * 0.6 + 0.15) * math.sin(f * 6.5 + ph)
            pts.append(pol(r, a, z))
            rad.append(tb * (0.75 + 0.25 * math.sin(f * math.pi)))
        orn_sweep(B(m, key, True), pts, rad, sides=7)


def necklace(m, key, zf, pr, lift=0.18, sub=2, bead=None, br=0.42, a_off=0.0, keep=None):
    """Collier de billes posé sur la coquille, à la hauteur zf(angle). keep(angle) : billes gardées."""
    mean = sum(rs(m, i / 12 * TAU, zf(i / 12 * TAU)) for i in range(12)) / 12
    pitch = (2 * pr * 0.92) if not bead else (2 * pr + 2 * br) * 0.76
    N = max(6, int(round(TAU * (mean + pr * lift) / pitch)))
    A = [a_off + i / N * TAU for i in range(N)]
    Rr = [rs(m, a, zf(a)) for a in A]
    P = []
    env = [max(Rr[(i + k) % N] for k in (-2, -1, 0, 1, 2)) for i in range(N)]
    for i, a in enumerate(A):
        r = (env[i - 1] + env[i] + env[(i + 1) % N]) / 3 + pr * lift
        P.append(pol(r, a, zf(a)))
        if not keep or keep(a):
            orn_ball(B(m, key, True), P[-1], pr, sub=sub)
    if bead:
        for i in range(N):
            if not keep or (keep(A[i]) and keep(A[(i + 1) % N])):
                orn_ball(B(m, bead, True), (P[i] + P[(i + 1) % N]) / 2, br, sub=1)
    return P
def lathe(bm, base, up, prof, sides=14, closed=False, phase=0.0):
    """Surface de révolution autour de l'axe up : prof = [(rayon, hauteur)] ; closed relie le dernier au premier
    (anneau creux, ex. bord de chapeau), sinon les deux bouts sont fermés."""
    rot = _orient(up)
    B0 = Vector(base)
    rings = []
    for r, z in prof:
        if r < 1e-4:
            rings.append([bm.verts.new(B0 + rot @ Vector((0, 0, z)))])
        else:
            rings.append([bm.verts.new(B0 + rot @ Vector((r * math.cos(j / sides * TAU + phase),
                                                            r * math.sin(j / sides * TAU + phase), z)))
                          for j in range(sides)])
    pairs = list(zip(rings, rings[1:])) + ([(rings[-1], rings[0])] if closed else [])
    for a, b in pairs:
        if len(a) == 1 and len(b) == 1:
            continue
        if len(a) == 1:
            for j in range(sides):
                bm.faces.new((a[0], b[j], b[(j + 1) % sides]))
        elif len(b) == 1:
            for j in range(sides):
                bm.faces.new((a[j], a[(j + 1) % sides], b[0]))
        else:
            for j in range(sides):
                k = (j + 1) % sides
                bm.faces.new((a[j], a[k], b[k], b[j]))
    if not closed:
        if len(rings[0]) > 1:
            bm.faces.new(rings[0][::-1])
        if len(rings[-1]) > 1:
            bm.faces.new(rings[-1])
    return rot

def zigzag_paint(m, key, z0, amp, n, width=0.55, arc=None, phase=0.0):
    """Ligne en zigzag peinte sur les briques : z = z0 + amp * triangle(n * angle). arc = (angle, demi-largeur)."""
    for c in m.surface():
        x, y, z = c
        th = math.atan2(y, x)
        if arc:
            d = (th - arc[0] + math.pi) % TAU - math.pi
            if abs(d) > arc[1]:
                continue
        f = (n * th / TAU + phase) % 1.0
        tri = 4 * abs(f - 0.5) - 1
        if abs(z - (z0 + amp * tri)) <= width:
            m.cells[c] = key



# FORMES DE BASE DE L'ANNEAU 13 ------------------------------------------------------------------

FRONT = -math.pi / 2
UP = Vector((0, 0, 1))


def plate(m, key, pts, c, u, v, n, d, smooth=False):
    orn_plate(B(m, key, smooth), pts, c, u, v, n, d)


def box(m, key, c, u, v, n, w, h, d):
    """Pavé centré en c : w selon u, h selon v, d selon n."""
    plate(m, key, [(-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2)], c, u, v, n, d)


def octo(w, h, k):
    """Rectangle aux coins coupés (contour convexe)."""
    return [(-w / 2 + k, -h / 2), (w / 2 - k, -h / 2), (w / 2, -h / 2 + k), (w / 2, h / 2 - k), (w / 2 - k, h / 2),
            (-w / 2 + k, h / 2), (-w / 2, h / 2 - k), (-w / 2, -h / 2 + k)]


def ell(m, key, c, u, v, n, rx, ry, rz, sub=2, smooth=True):
    """Ellipsoïde orienté : demi-axes rx selon u, ry selon v, rz selon n."""
    bm = B(m, key, smooth)
    vs = bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=1.0)['verts']
    u, v, n, c = Vector(u), Vector(v), Vector(n), Vector(c)
    M = Matrix(((u.x * rx, v.x * ry, n.x * rz, c.x), (u.y * rx, v.y * ry, n.y * rz, c.y),
                (u.z * rx, v.z * ry, n.z * rz, c.z), (0, 0, 0, 1)))
    bmesh.ops.transform(bm, matrix=M, verts=vs)


def ribbon(bm, C, Wd, s, n, thick):
    """Bande épaisse le long des points C : demi-largeur Wd[i] selon s, épaisseur selon n. Faite en quadrilatères
    (pas de triangulation automatique d'un contour, qui retournait des faces au lot 12)."""
    rows = []
    for i, (c, w) in enumerate(zip(C, Wd)):
        w = max(w, 0.03)
        si = s[i] if isinstance(s, list) else s
        ni = n[i] if isinstance(n, list) else n
        rows.append([bm.verts.new(c + si * sx * w + ni * nz * thick / 2) for sx, nz in ((-1, 1), (1, 1), (1, -1), (-1, -1))])
    for a, b in zip(rows, rows[1:]):
        for j in range(4):
            k = (j + 1) % 4
            bm.faces.new((a[j], a[k], b[k], b[j]))
    bm.faces.new(rows[0][::-1])
    bm.faces.new(rows[-1])


def leaf_w(t):
    """Profil de plume (0..1) : tuyau fin à la racine, plus large aux deux tiers, bout arrondi."""
    if t < 0.62:
        w = math.sqrt(max(0.0, 1 - ((0.62 - t) / 0.62) ** 2))
    else:
        w = math.sqrt(max(0.0, 1 - ((t - 0.62) / 0.38) ** 2))
    return max(0.16 if t < 0.5 else 0.0, w)


def feather(m, key, root, d, nrm, L, W, tip=None, tipf=0.3, bend=0.0, K=10, thick=0.16, rachis=None):
    """Plume plate : de root vers d, à plat face à nrm, bout d'une autre couleur (tip), courbée de bend vers nrm."""
    d = Vector(d).normalized()
    nrm = Vector(nrm)
    n = nrm - d * nrm.dot(d)
    if n.length < 1e-4:
        n = d.orthogonal()
    n.normalize()
    s = n.cross(d).normalized()
    root = Vector(root)
    T = [i / K for i in range(K + 1)]
    C = [root + d * L * t + n * bend * L * t * t for t in T]
    Wd = [W / 2 * leaf_w(t) for t in T]
    ribbon(B(m, key, False), C, Wd, s, n, thick)
    if tip:
        i0 = int(round((1 - tipf) * K))
        ribbon(B(m, tip, False), C[i0:], [w * 1.05 for w in Wd[i0:]], s, n, thick * 1.35)
    if rachis:
        k1 = int(K * 0.8)
        ribbon(B(m, rachis, False), C[:k1], [max(0.05, W * 0.045)] * k1, s, n, thick * 1.5)
    return C[-1]


def plume_ring(m, c, axis, R0, L, keys, N, W, tilt=0.3, tips=None, a0=0.0, thick=0.16, arc=None):
    """Collerette de plumes autour de axis : elles rayonnent dans le plan perpendiculaire, penchées de tilt le long
    de l'axe. arc = (angle de départ, étendue) pour un éventail au lieu d'un tour complet."""
    ax = Vector(axis).normalized()
    e1 = UP.cross(ax)
    if e1.length < 1e-3:
        e1 = Vector((1, 0, 0))
    e1.normalize()
    e2 = ax.cross(e1).normalized()
    for i in range(N):
        a = a0 + (i / N * TAU if not arc else arc[0] + arc[1] * i / max(1, N - 1))
        r = e1 * math.cos(a) + e2 * math.sin(a)
        d = (r + ax * tilt).normalized()
        feather(m, keys[i % len(keys)], Vector(c) + r * R0 + ax * (0.07 * (i % 2)), d, ax, L, W,
                tip=tips[i % len(tips)] if tips else None, thick=thick)


def feather_wing(m, root, s, L, a_hi=62, a_lo=-20, n=9, W=1.6, sweep=0.16, layers=None, cuff='gold13',
                 gem='gemt13', cuff_r=1.0, bend=0.05):
    """Aile de plumes en éventail (côté s = +1 / -1 en x) : rangée du fond longue (jade), rangées de devant plus
    courtes (bleu, rouge) ; manchette d'or et gemme à la racine."""
    layers = layers or (('jade13', 'jadel13', 1.0, 1.0), ('fblue13', 'turq13', 0.68, 0.85),
                        ('fred13', 'gold13', 0.44, 0.75))
    R0 = Vector(root)
    nrm = Vector((-s * sweep, 1, 0)).normalized()
    for li, (key, tip, lk, wk) in enumerate(layers):
        nn = max(3, n - li * 2)
        for i in range(nn):
            f = i / (nn - 1)
            ang = math.radians(a_hi + (a_lo - a_hi) * f)
            d = Vector((s * math.cos(ang), sweep * math.cos(ang), math.sin(ang))).normalized()
            Li = L * lk * (0.74 + 0.26 * math.sin(math.pi * (0.3 + 0.7 * f)))
            base = R0 - nrm * (0.2 * li + 0.035 * i) + d * 0.5
            feather(m, key, base, d, nrm, Li, W * wk, tip=tip, tipf=0.26, bend=bend, thick=0.2)
    orn_ball(B(m, cuff, True), R0 - nrm * 0.3, cuff_r, sub=2)
    if gem:
        orn_gem(B(m, gem, False), R0 - nrm * (0.3 + cuff_r * 0.92), cuff_r * 0.55, direction=-nrm)
    return nrm


def sun_disc(m, c, nrm, R, nrays=12, thick=0.5, ray='gold13', ray2='brick13', disc='gold13', rim='goldd13',
             inner='jade13', boss='gold13', gem='gemt13', ray_len=0.55, glow=None, dots='goldl13', post=0.0,
             post_key='goldd13'):
    """Disque solaire : grands rayons d'or pointus et petits rayons rouges entre eux (derrière), disque d'or bordé,
    disque de jade, cercle de perles d'or, bouton central et gemme. post : tige qui part de l'arrière."""
    nn, u, v = frame(nrm)
    c = Vector(c)
    hw = R * math.sin(math.pi / nrays) * 1.05
    for k in range(nrays):
        a = k / nrays * TAU + math.pi / 2
        dd = u * math.cos(a) + v * math.sin(a)
        plate(m, ray, [(R * 0.8, -hw), (R * (1 + ray_len), 0), (R * 0.8, hw)], c - nn * thick * 0.2, dd,
              nn.cross(dd), nn, thick * 0.6)
        if ray2:
            a2 = a + math.pi / nrays
            d2 = u * math.cos(a2) + v * math.sin(a2)
            plate(m, ray2, [(R * 0.8, -hw * 0.72), (R * (1 + ray_len * 0.55), 0), (R * 0.8, hw * 0.72)],
                  c - nn * thick * 0.32, d2, nn.cross(d2), nn, thick * 0.5)
    orn_cyl(B(m, disc, False), c - nn * thick / 2, nn, thick, R, sides=max(20, int(R * 10)))
    orn_torus(B(m, rim, True), c + nn * thick * 0.5, R * 0.95, max(0.1, R * 0.07), axis=nn, seg=max(24, int(R * 12)),
              sides=6)
    if inner:
        orn_cyl(B(m, inner, False), c + nn * thick * 0.3, nn, thick * 0.4, R * 0.64, sides=max(18, int(R * 9)))
        if dots:
            nd = max(8, int(R * 5))
            for k in range(nd):
                a = k / nd * TAU
                orn_ball(B(m, dots, True), c + nn * thick * 0.62 + (u * math.cos(a) + v * math.sin(a)) * R * 0.795,
                         max(0.09, R * 0.07), sub=1)
    orn_cyl(B(m, boss, False), c + nn * thick * 0.5, nn, thick * 0.45, R * 0.3, sides=16)
    if gem:
        orn_gem(B(m, gem, False), c + nn * (thick * 0.95 + R * 0.08), R * 0.24, direction=nn)
    if glow:
        orn_torus(B(m, glow, True), c + nn * thick * 0.72, R * 0.47, max(0.06, R * 0.04), axis=nn, seg=32, sides=5)
    if post > 0:
        orn_cyl(B(m, post_key, False), c - nn * (thick / 2 + post), nn, post, R * 0.35, sides=12)
    return nn, u, v


def body_sun(m, th, z, R, thick=0.5, lift=0.25, **kw):
    """Disque solaire posé sur la coquille (face vers l'extérieur), tenu par une tige."""
    n = Vector((math.cos(th), math.sin(th), 0))
    k = R * 0.7 / max(rs(m, th, z), 1.0)
    r0 = max(rs(m, th + da, z + dz) for da in (-k, 0, k) for dz in (-R * 0.7, 0, R * 0.7))
    c = pol(r0 + thick / 2 + lift, th, z)
    sun_disc(m, c, n, R, thick=thick, post=1.8, **kw)
    return c


def medallion(m, th, z, R, gem_key, gold='gold13', dark='goldd13'):
    """Gemme sertie dans un anneau d'or, posée sur la coquille."""
    n = Vector((math.cos(th), math.sin(th), 0))
    r0 = max(rs(m, th + da, z + dz) for da in (-R / 9, 0, R / 9) for dz in (-R * 0.7, 0, R * 0.7))
    c = pol(r0 + 0.12, th, z)
    orn_torus(B(m, gold, True), c, R, R * 0.24, axis=n, seg=32, sides=8)
    orn_cone(B(m, dark, True), c + n * R * 0.1, -n, R * 1.2, R * 0.98, sides=16)
    orn_gem(B(m, gem_key, False), c + n * R * 0.22, R * 0.84, direction=n)
    return c


# PEINTURES -------------------------------------------------------------------------------------

def stepzig_paint(m, key, z0, n, levels, base=0, down=False, phase=0.0, test=None):
    """Bande à gradins : n petites pyramides à marches autour de l'œuf, de z0 - base jusqu'à z0 + marche
    (ou vers le bas si down)."""
    for c in m.surface():
        x, y, z = c
        if test and not test(x, y, z):
            continue
        f = (n * math.atan2(y, x) / TAU + phase) % 1.0
        st = int(round((1 - 2 * abs(f - 0.5)) * levels))
        ok = (z0 - st <= z <= z0 + base) if down else (z0 - base <= z <= z0 + st)
        if ok:
            m.cells[c] = key


def veins(m, key, seed, period=3.4, w=0.085, test=None):
    """Veines claires du jade poli."""
    m.paint(lambda x, y, z: abs(vnoise(x, y, z, seed, period)) < w and (not test or test(x, y, z)), key)


# ANNEAUX, RUINES ---------------------------------------------------------------------------------

def ring_band(m, key, z, h, out=0.1, thick=0.3, seg=60, depth=0.7):
    """Anneau qui épouse la coquille à la hauteur z (h de haut), un peu en relief. Renvoie les rayons."""
    R = []
    for j in range(seg):
        a = j / seg * TAU
        R.append(max(rs(m, a, z + dz) for dz in (-h / 2, 0, h / 2)))
    R = [sum(R[(j + k) % seg] for k in (-2, -1, 0, 1, 2)) / 5 for j in range(seg)]
    bm = B(m, key, False)
    rings = []
    for j in range(seg):
        a = j / seg * TAU
        ro, ri = R[j] + out + thick, R[j] - depth
        rings.append([bm.verts.new(pol(r, a, zz)) for r, zz in ((ri, z - h / 2), (ro, z - h / 2), (ro, z + h / 2),
                                                                  (ri, z + h / 2))])
    for j in range(seg):
        A, Bq = rings[j], rings[(j + 1) % seg]
        for k in range(4):
            l = (k + 1) % 4
            bm.faces.new((A[k], Bq[k], Bq[l], A[l]))
    return lambda a: R[int(round((a % TAU) / TAU * seg)) % seg] + out + thick


def gold_band(m, z, h=0.9, key='gold13', engrave='goldd13', out=0.0, thick=0.26, n_marks=18, gems=None, gem_r=0.45,
              seg=60, a_gem=FRONT):
    """Mince anneau d'or gravé (traits sombres en relief, un sur deux en petite marche), gemmes serties."""
    ro = ring_band(m, key, z, h, out, thick, seg)
    ga = [a_gem + k / len(gems) * TAU for k in range(len(gems))] if gems else []
    for k in range(n_marks):
        a = (k + 0.5) / n_marks * TAU + a_gem
        if any(abs((a - g + math.pi) % TAU - math.pi) < 0.3 for g in ga):
            continue
        nrm = Vector((math.cos(a), math.sin(a), 0))
        tg = Vector((-math.sin(a), math.cos(a), 0))
        r = ro(a) + 0.03
        if k % 2:
            box(m, engrave, pol(r, a, z - h * 0.18), tg, UP, nrm, 0.5, h * 0.22, 0.12)
            box(m, engrave, pol(r, a, z + h * 0.12), tg, UP, nrm, 0.22, h * 0.36, 0.12)
        else:
            box(m, engrave, pol(r, a, z), tg, UP, nrm, 0.15, h * 0.72, 0.12)
    for k, g in enumerate(gems or ()):
        a = ga[k]
        nrm = Vector((math.cos(a), math.sin(a), 0))
        p = pol(ro(a) + 0.1, a, z)
        orn_torus(B(m, engrave, True), p, gem_r * 1.05, gem_r * 0.24, axis=nrm, seg=20, sides=6)
        orn_gem(B(m, g, False), p + nrm * 0.06, gem_r * 0.9, direction=nrm)
    return ro


def ruin_litter(m, n, keys=('stone13', 'stoned13', 'stonel13'), size=(0.8, 1.25), trim=('gold13', 'brick13', 'jade13'),
                zr=0.6, columns=0):
    """Blocs de pierre taillée (un sur deux avec une bande d'or, de brique ou de jade) et tronçons de colonne couchés
    au pied de l'œuf : les ruines du temple."""
    rnd = m.rnd
    a0 = rnd.uniform(0, TAU)
    for i in range(n):
        a = a0 + i / n * TAU + rnd.uniform(-0.25, 0.25)
        sz = rnd.uniform(*size)
        r = max(rs(m, a + d, zr + dz) for d in (-0.3, 0, 0.3) for dz in (0, 0.8)) + sz * 0.75 + 0.15
        rot = a + math.pi / 2 + rnd.uniform(-0.6, 0.6)
        tl = rnd.uniform(-0.22, 0.22)
        u = Vector((math.cos(rot), math.sin(rot), 0))
        n_ = Vector((-math.sin(rot), math.cos(rot), 0))
        v = UP * math.cos(tl) + n_ * math.sin(tl)
        n2 = n_ * math.cos(tl) - UP * math.sin(tl)
        c = pol(r, a, -0.5 + sz * 0.5)
        if i < columns:
            orn_cyl(B(m, 'stonel13', False), c - u * sz * 0.9, u, sz * 1.8, sz * 0.5, sides=12)
            orn_cyl(B(m, 'gold13', False), c - u * 0.13, u, 0.26, sz * 0.56, sides=12)
            orn_cyl(B(m, 'stoned13', False), c - u * sz * 0.95, u, 0.2, sz * 0.58, sides=12)
            continue
        box(m, keys[i % len(keys)], c, u, v, n2, sz * 1.35, sz, sz)
        if trim and i % 2 == 0:
            box(m, trim[(i // 2) % len(trim)], c + v * sz * 0.2, u, v, n2, sz * 1.39, sz * 0.18, sz * 1.04)


# VISAGE D'IDOLE, SCARABÉE, IDOLES, SERPENT ---------------------------------------------------------

def idol_face(m, th, z, S=1.0, gold='gold13', dark='goldd13', inlay='turq13', mouth='brick13', teeth='cream13',
              eyes='ink13', back='stoned13', gem='gemt13'):
    """Petit visage d'idole en or : masque aux coins coupés, coiffe à gradins et gemme, sourcils, yeux sombres incrustés
    de turquoise, nez, bouche rouge et dents, ornements d'oreille ; cadre de pierre sombre derrière."""
    n = Vector((math.cos(th), math.sin(th), 0))
    nn, u, v = frame(n)
    k = 1.8 * S / max(rs(m, th, z), 1.0)
    r0 = max(rs(m, th + da, z + dz) for da in (-k, 0, k) for dz in (-1.8 * S, 0, 1.8 * S))
    c = pol(r0 + 0.2, th, z)
    box(m, back, c - nn * 0.75, u, v, nn, 3.5 * S, 4.0 * S, 1.5)
    plate(m, gold, octo(3.0 * S, 3.4 * S, 0.55 * S), c, u, v, nn, 0.4)
    box(m, dark, c + v * 1.95 * S + nn * 0.08, u, v, nn, 3.7 * S, 0.75 * S, 0.6)
    for i, (w, h) in enumerate(((2.7 * S, 0.5 * S), (1.7 * S, 0.5 * S), (0.75 * S, 0.45 * S))):
        box(m, gold, c + v * (2.55 * S + i * 0.48 * S) - nn * 0.05, u, v, nn, w, h, 0.5)
    orn_gem(B(m, gem, False), c + v * 1.95 * S + nn * 0.5, 0.36 * S, direction=nn)
    box(m, dark, c + v * 0.78 * S + nn * 0.28, u, v, nn, 2.5 * S, 0.3 * S, 0.22)
    for sx in (-1, 1):
        box(m, eyes, c + v * 0.3 * S + u * sx * 0.66 * S + nn * 0.24, u, v, nn, 0.78 * S, 0.44 * S, 0.14)
        box(m, inlay, c + v * 0.3 * S + u * sx * 0.66 * S + nn * 0.3, u, v, nn, 0.3 * S, 0.3 * S, 0.1)
        e = c + u * sx * 1.78 * S + v * 0.1 * S
        orn_cyl(B(m, dark, False), e - nn * 1.0, nn, 1.35, 0.62 * S, sides=16)
        orn_cyl(B(m, 'jade13', False), e + nn * 0.3, nn, 0.14, 0.36 * S, sides=12)
    plate(m, dark, [(-0.34 * S, -0.38 * S), (0.34 * S, -0.38 * S), (0.13 * S, 0.45 * S), (-0.13 * S, 0.45 * S)],
          c - v * 0.2 * S + nn * 0.32, u, v, nn, 0.3)
    box(m, mouth, c - v * 0.98 * S + nn * 0.24, u, v, nn, 1.7 * S, 0.5 * S, 0.14)
    for kk in (-1, 0, 1):
        box(m, teeth, c - v * 0.86 * S + u * kk * 0.44 * S + nn * 0.29, u, v, nn, 0.26 * S, 0.26 * S, 0.1)
    orn_ball(B(m, dark, True), c - v * 1.85 * S + nn * 0.05, 0.3 * S, sub=1)
    return c


def surf_pt(m, p, lift):
    """Ramène le point p sur la coquille (à lift au-dessus), dans sa direction depuis l'axe."""
    th = math.atan2(p.y, p.x)
    return pol(rs(m, th, p.z) + lift, th, p.z)


def scarab(m, th, z, S=1.0, gold='gold13', dark='goldd13', gem='gemt13', glow='G:gturq13'):
    """Scarabée d'or posé sur la coquille : élytres fendues, gemmes turquoise, corselet, tête à râteau, six pattes,
    disque solaire au-dessus de la tête ; ailes de plumes déployées qui font le tour de l'œuf (or, turquoise, or sombre)."""
    n = Vector((math.cos(th), math.sin(th), 0))
    nn, u, v = frame(n)
    r0 = surf_r(m, th, z, 0.2, 1.5)
    c = pol(r0 - 0.3 * S, th, z)
    ell(m, gold, c, u, v, nn, 1.5 * S, 1.9 * S, 1.0 * S)
    tube(B(m, dark, True), [c + v * 1.8 * S * t + nn * (1.0 * S * math.sqrt(max(0.0, 1 - t * t)) + 0.03)
                            for t in [i / 12 * 1.9 - 0.95 for i in range(13)]], 0.1 * S, sides=6)
    for sx in (-1, 1):
        ell(m, 'turq13', c + u * sx * 0.72 * S - v * 0.35 * S + nn * 0.78 * S, u, v, nn, 0.32 * S, 0.62 * S, 0.22 * S,
            sub=1)
    ell(m, gold, c + v * 2.05 * S + nn * 0.05, u, v, nn, 1.2 * S, 0.78 * S, 0.82 * S)
    orn_gem(B(m, gem, False), c + v * 2.1 * S + nn * 0.85 * S, 0.3 * S, direction=nn)
    ell(m, dark, c + v * 2.95 * S, u, v, nn, 0.85 * S, 0.58 * S, 0.62 * S)
    for kk in range(-2, 3):
        orn_cone(B(m, gold, True), c + v * 3.3 * S + u * kk * 0.3 * S + nn * 0.15 * S, (v + u * kk * 0.18).normalized(),
                 0.5 * S, 0.13 * S, sides=6)
    for sx in (-1, 1):
        for dv, a in ((1.8, 0.75), (0.5, 0.0), (-0.9, -0.7)):
            s0 = c + v * dv * S + u * sx * 1.0 * S
            k1 = s0 + (u * sx * math.cos(a) + v * math.sin(a)) * 1.1 * S
            k2 = k1 + (u * sx * 0.3 + v * math.sin(a) * 1.3) * S
            pts = [surf_pt(m, p, 0.12) for p in dense([s0, k1, k2], 0.2)]
            tube(B(m, dark, True), pts, 0.13 * S, sides=6)
    sc = c + v * 4.45 * S + nn * 0.25
    sun_disc(m, sc, n, 0.95 * S, nrays=10, thick=0.36, inner='turq13', boss=gold, gem=None, dots=None,
             glow=glow, ray_len=0.6, post=0.8)
    orn_ball(B(m, 'G:ggold13', True), sc + n * 0.36, 0.2 * S, sub=1)
    # ailes de plumes déployées : éventail qui part des épaules et suit la coquille (longues plumes d'or au fond,
    # plumes turquoise devant, petites plumes d'or sombre près du corps)
    rows = ((gold, 'turq13', 1.0, 0.16, 7), ('turq13', gold, 0.64, 0.34, 6), (dark, 'jade13', 0.36, 0.5, 5))
    for sx in (-1, 1):
        th0, z0 = th + sx * 0.2, z + 1.5 * S
        for key, tipk, lk, lift, K in rows:
            for k in range(K):
                f = k / (K - 1)
                ang = math.radians(-8 + 64 * f)
                L = (5.2 - 2.2 * f) * lk * S + 0.6
                surf_feather(m, key, th0, z0, sx, ang, L, 1.05 * S, tip=tipk, lift=lift + 0.02 * k)
        L0 = 5.2 * S + 0.6
        tw = th0 + sx * (L0 * math.cos(math.radians(-8)) + 0.5) / max(rs(m, th0, z0), 1.0)
        orn_gem(B(m, gem, False), pol(rs(m, tw, z0 + 0.7) + 0.35, tw, z0 + 0.75), 0.36 * S,
                direction=(math.cos(tw), math.sin(tw), 0))
    return c


def surf_feather(m, key, th0, z0, sx, ang, L, W, tip=None, tipf=0.3, lift=0.2, thick=0.18, K=10):
    """Plume couchée sur la coquille : part de (th0, z0) vers le côté sx, penchée de ang vers le bas, et suit la
    courbure de l'œuf (rayon lissé)."""
    r_ref = max(rs(m, th0, z0), 1.0)
    T = [i / K for i in range(K + 1)]
    A = [th0 + sx * L * t * math.cos(ang) / r_ref for t in T]
    Z = [z0 - L * t * math.sin(ang) for t in T]
    raw = [max(rs(m, a + da, zz + dz) for da in (-0.08, 0, 0.08) for dz in (-0.5, 0, 0.5)) for a, zz in zip(A, Z)]
    rr = [sum(raw[max(0, i - 1):i + 2]) / len(raw[max(0, i - 1):i + 2]) for i in range(K + 1)]
    rr = [max(a, b - 0.15) for a, b in zip(rr, raw)]
    C = [pol(r + lift, a, zz) for r, a, zz in zip(rr, A, Z)]
    N = [Vector((math.cos(a), math.sin(a), 0)) for a in A]
    S_ = []
    for i in range(K + 1):
        tg = (C[min(i + 1, K)] - C[max(i - 1, 0)]).normalized()
        S_.append(N[i].cross(tg).normalized())
    Wd = [W / 2 * leaf_w(t) for t in T]
    ribbon(B(m, key, False), C, Wd, S_, N, thick)
    if tip:
        i0 = int(round((1 - tipf) * K))
        ribbon(B(m, tip, False), C[i0:], [w * 1.05 for w in Wd[i0:]], S_[i0:], N[i0:], thick * 1.35)


def mini_scarab(m, c, n, S, gold='gold13', dark='goldd13', gem='gemt13', wing='turq13'):
    nn, u, v = frame(n)
    c = Vector(c)
    ell(m, gold, c, u, v, nn, 0.75 * S, 0.95 * S, 0.5 * S)
    ell(m, gold, c + v * 1.05 * S, u, v, nn, 0.6 * S, 0.4 * S, 0.42 * S)
    ell(m, dark, c + v * 1.5 * S, u, v, nn, 0.42 * S, 0.3 * S, 0.32 * S)
    orn_gem(B(m, gem, False), c + nn * 0.5 * S, 0.22 * S, direction=nn)
    for sx in (-1, 1):
        feather(m, wing, c + u * sx * 0.45 * S + v * 0.35 * S, u * sx + v * 0.45, nn, 1.9 * S, 0.8 * S, tip=gold,
                thick=0.14)
        feather(m, gold, c + u * sx * 0.45 * S + v * 0.1 * S, u * sx - v * 0.1, nn, 1.4 * S, 0.65 * S, tip=wing,
                thick=0.16)


def mini_idol(m, base, out, S, body='gold13', dark='goldd13', plumes=('fred13', 'fblue13', 'jade13')):
    """Petite idole debout (socle de pierre, corps, grosse tête d'or au visage sombre, coiffe de trois plumes)."""
    nn, u, v = frame(out)
    b = Vector(base)
    box(m, 'stoned13', b + v * 0.25 * S, u, v, nn, 1.7 * S, 0.5 * S, 1.5 * S)
    box(m, dark, b + v * 1.15 * S, u, v, nn, 1.2 * S, 1.3 * S, 1.0 * S)
    box(m, body, b + v * 2.45 * S, u, v, nn, 1.55 * S, 1.35 * S, 1.2 * S)
    for sx in (-1, 1):
        box(m, 'ink13', b + v * 2.62 * S + u * sx * 0.36 * S + nn * 0.6 * S, u, v, nn, 0.36 * S, 0.26 * S, 0.12 * S)
        orn_cyl(B(m, 'turq13', False), b + v * 2.4 * S + u * sx * 0.7 * S, u * sx, 0.22 * S, 0.3 * S, sides=10)
    box(m, 'brick13', b + v * 2.02 * S + nn * 0.6 * S, u, v, nn, 0.8 * S, 0.22 * S, 0.12 * S)
    box(m, dark, b + v * 2.32 * S + nn * 0.62 * S, u, v, nn, 0.22 * S, 0.42 * S, 0.16 * S)
    box(m, dark, b + v * 3.2 * S, u, v, nn, 1.75 * S, 0.32 * S, 1.28 * S)
    for k, a in enumerate((-0.55, 0.0, 0.55)):
        feather(m, plumes[k % len(plumes)], b + v * 3.25 * S - nn * 0.15 * S, u * math.sin(a) + v * math.cos(a), nn,
                1.6 * S, 0.66 * S, tip='gold13', thick=0.12)


def catmull(pts, k=8):
    pts = [Vector(p) for p in pts]
    out = []
    for i in range(len(pts) - 1):
        p0 = pts[i - 1] if i > 0 else pts[i]
        p1, p2 = pts[i], pts[i + 1]
        p3 = pts[i + 2] if i + 2 < len(pts) else pts[i + 1]
        for s in range(k):
            t = s / k
            t2, t3 = t * t, t * t * t
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
                              (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    out.append(pts[-1])
    return out


def serpent_body(m, ctrl, r_head, r_tail, key='jade13', band='gold13', every=1.5, scales='jadel13'):
    """Corps de serpent lisse le long des points de contrôle (queue -> tête), effilé vers la queue, bagues d'or,
    petites écailles claires sur le dos."""
    P = catmull(ctrl, 6)
    n = len(P)
    rad = [r_tail + (r_head - r_tail) * min(1.0, (i / (n - 1)) / 0.4) ** 0.8 for i in range(n)]
    tube(B(m, key, True), P, rad, sides=10)
    s, nxt, k = 0.0, every * 0.6, 0
    for i in range(1, n - 1):
        s += (P[i] - P[i - 1]).length
        if s >= nxt:
            t = (P[i + 1] - P[i - 1]).normalized()
            orn_torus(B(m, band, True), P[i], rad[i] * 0.97, rad[i] * 0.2, axis=t, seg=14, sides=5)
            if scales and k % 2 == 0 and i + 3 < n:
                q = (P[i] + P[i + 3]) / 2
                out = Vector((q.x, q.y, 0)).normalized()
                orn_ball(B(m, scales, True), q + out * rad[i] * 0.88, rad[i] * 0.3, scale=(1, 1, 0.7), sub=1)
            k += 1
            nxt += every
    return P, rad


def serpent_head(m, c, fwd, S, body='jade13', jaw='jadex13', mouth='brick13', fang='cream13', eye='gold13',
                 brow='gold13', tongue='fred13', crest=('fred13', 'fblue13', 'jade13')):
    """Tête de serpent à plumes : crâne, museau, mâchoire ouverte, bouche rouge, crochets, yeux d'or, sourcils d'or,
    langue fourchue, petite crête de plumes."""
    f = Vector(fwd).normalized()
    up = (UP - f * UP.dot(f)).normalized()
    sd = f.cross(up).normalized()
    c = Vector(c)
    ell(m, body, c, sd, f, up, 1.0 * S, 1.2 * S, 0.8 * S)
    ell(m, body, c + f * 1.15 * S + up * 0.1 * S, sd, f, up, 0.8 * S, 1.05 * S, 0.5 * S)
    ja = 0.55
    jd = (f * math.cos(ja) - up * math.sin(ja)).normalized()
    ju = (up * math.cos(ja) + f * math.sin(ja)).normalized()
    ell(m, jaw, c + f * 0.3 * S - up * 0.42 * S + jd * 0.8 * S, sd, jd, ju, 0.72 * S, 0.98 * S, 0.28 * S)
    ell(m, mouth, c + f * 0.85 * S - up * 0.28 * S, sd, f, up, 0.62 * S, 0.9 * S, 0.32 * S)
    for sx in (-1, 1):
        orn_cone(B(m, fang, True), c + f * 1.75 * S + sd * sx * 0.42 * S - up * 0.18 * S,
                 (-up + f * 0.25).normalized(), 0.62 * S, 0.14 * S, sides=6)
        e = c + f * 0.45 * S + sd * sx * 0.72 * S + up * 0.46 * S
        orn_ball(B(m, eye, True), e, 0.3 * S, sub=2)
        orn_ball(B(m, 'ink13', True), e + (sd * sx * 0.5 + f * 0.8).normalized() * 0.2 * S, 0.15 * S, sub=1)
        box(m, brow, e + up * 0.3 * S - f * 0.05 * S, f, sd, up, 0.95 * S, 0.42 * S, 0.16 * S)
        orn_ball(B(m, 'ink13', True), c + f * 2.05 * S + sd * sx * 0.25 * S + up * 0.32 * S, 0.09 * S, sub=1)
    t0 = c + f * 1.2 * S - up * 0.32 * S
    t1 = c + f * 2.5 * S - up * 0.55 * S
    tube(B(m, tongue, True), dense([t0, t1], 0.2), 0.08 * S, sides=5)
    for sx in (-1, 1):
        tube(B(m, tongue, True), dense([t1, t1 + f * 0.45 * S + sd * sx * 0.3 * S], 0.15), 0.07 * S, sides=5)
    if crest:
        for k, a in enumerate((-0.45, 0.0, 0.45)):
            d = (-f * 0.85 + up * 0.75 + sd * a * 0.8).normalized()
            feather(m, crest[k % len(crest)], c + up * 0.55 * S - f * 0.2 * S, d, sd, 1.9 * S, 0.7 * S, tip='gold13',
                    thick=0.14)
    return f, up, sd


# CORPS EN PYRAMIDE À GRADINS (COSMIC) ------------------------------------------------------------

def pyramid_body(m, W, H, key, TH=3, t0=0.37, k45=1.36, top_min=4.4):
    """Œuf-pyramide : gradins de TH briques, carrés aux coins coupés, dont la largeur suit le profil d'un œuf
    (le plus large vers 37 % de la hauteur) ; plateforme carrée en haut pour le temple."""
    R = W / 2
    lim = (W - 1) // 2
    m.Hc, m.W = H, W
    nt = int(math.ceil(H / TH))
    A = [egg_r(((k * TH + min(H, (k + 1) * TH) - 1) / 2 + 0.5) / (H + 0.8), R, t0) * 0.93 for k in range(nt)]
    A[-1] = max(A[-1], top_min)
    kw = max(range(nt), key=lambda k: A[k])
    for k in range(nt - 2, kw - 1, -1):
        A[k] = max(A[k], A[k + 1] + 1.0)
    tiers = []
    for k in range(nt):
        z0, z1, a = k * TH, min(H, (k + 1) * TH), A[k]
        tiers.append((z0, z1, a))
        for z in range(z0, z1):
            for x in range(-lim, lim + 1):
                for y in range(-lim, lim + 1):
                    if (max(abs(x), abs(y)) <= a - 0.45 and abs(x) + abs(y) <= a * k45) or (x == 0 and y == 0):
                        m.put((x, y, z), key)
    m.body = set(m.cells)
    return tiers


# LES SIX ŒUFS --------------------------------------------------------------------------------

def build_T2(off):
    """Jade Egg : jade poli (veines claires, nuages plus foncés), pied de jade sombre, sommet clair, mince anneau d'or
    gravé avec trois gemmes turquoise, quelques blocs de ruines au pied."""
    W, H = SIZES[2]
    m = Vox(H, seed=1302)
    egg_body(m, W, H, 'jade13', 13021, bump=0.3)
    m.paint(lambda x, y, z: vnoise(x + 11, y, z, 22, 3.0) > 0.42, 'jadex13')
    veins(m, 'jadel13', 21, 3.4, 0.08)
    m.paint(lambda x, y, z: z <= 1.8 + wave(math.atan2(y, x), 4, 0.5), 'jaded13')
    m.paint(lambda x, y, z: z >= H - 2.6 + wave(math.atan2(y, x), 5, 0.5, 1.0), 'jadel13')
    glow_dots(m, 'G:gjade13', 2, lambda x, y, z: 8 <= z <= 11 and m.cells[(x, y, z)] == 'jade13', mind=5.0)
    gold_band(m, 5.6, h=0.9, n_marks=20, gems=('gemt13', 'gemt13', 'gemt13'), gem_r=0.42)
    nest(m, ['jaded13', 'stoned13', 'jadex13'], 12)
    ruin_litter(m, 3, size=(0.75, 1.0))
    return build(m, 'Egg_R13_T2', P13, off)


def build_T3(off):
    """Idol Egg : pierre sculptée patinée (taches claires, lichen de jade), zigzags rouge brique et jade, sommet de jade
    à gradins d'or, petit visage d'idole en or à l'avant, ruines au pied."""
    W, H = SIZES[3]
    m = Vox(H, seed=1303)
    egg_body(m, W, H, 'stone13', 13031, bump=0.45)
    m.paint(lambda x, y, z: vnoise(x, y, z, 31, 2.6) > 0.55, 'stonel13')
    m.paint(lambda x, y, z: z <= 1.6 + wave(math.atan2(y, x), 4, 0.5), 'stoned13')
    m.paint(lambda x, y, z: z == 2, 'gold13')
    m.paint(lambda x, y, z: 3 <= z <= 5, 'stoned13')
    zigzag_paint(m, 'brick13', 4.0, 1.0, 8, width=0.5)
    m.paint(lambda x, y, z: 11 <= z <= 13, 'stoned13')
    zigzag_paint(m, 'jade13', 12.0, 1.0, 8, width=0.5, phase=0.5)
    m.paint(lambda x, y, z: z >= 14, 'jade13')
    stepzig_paint(m, 'gold13', 14, 6, 1, base=0)
    m.paint(lambda x, y, z: z >= H - 1.2, 'jadel13')
    idol_face(m, FRONT, 8.0, S=0.95)
    medallion(m, FRONT + math.pi, 8.5, 0.75, 'gemt13')
    nest(m, ['jaded13', 'stoned13'], 12)
    ruin_litter(m, 4, size=(0.75, 1.05))
    return build(m, 'Egg_R13_T3', P13, off)


def build_T4(off):
    """Scarab Egg : jade poli, pied de jade sombre bordé de gradins d'or, scarabée d'or aux ailes de plumes déployées
    à l'avant (gemmes turquoise, petit disque solaire à lueur douce), gemme au dos, scarabées et gemmes en orbite."""
    W, H = SIZES[4]
    m = Vox(H, seed=1304)
    egg_body(m, W, H, 'jade13', 13041, bump=0.3)
    m.paint(lambda x, y, z: vnoise(x + 11, y, z, 42, 3.0) > 0.45, 'jadex13')
    veins(m, 'jadel13', 41, 3.6, 0.08)
    m.paint(lambda x, y, z: z <= 3, 'jaded13')
    m.paint(lambda x, y, z: z == 2, 'gold13')
    stepzig_paint(m, 'gold13', 4, 7, 2, base=0)
    m.paint(lambda x, y, z: z >= H - 3.0 + wave(math.atan2(y, x), 5, 0.5), 'jaded13')
    stepzig_paint(m, 'gold13', H - 3, 7, 1, base=0, down=True, phase=0.5)
    glow_dots(m, 'G:gturq13', 3, lambda x, y, z: 6 <= z <= 13 and m.cells[(x, y, z)] == 'jade13' and y > 0, mind=4.0)
    scarab(m, FRONT, 9.2, S=1.0)
    medallion(m, FRONT + math.pi, 9.5, 0.95, 'gemt13')
    nest(m, ['jaded13', 'stoned13', 'jadex13'], 14)
    ruin_litter(m, 4, size=(0.8, 1.1), columns=1)
    with layer(m, 'Orbit'):
        Ro = W / 2 + 3.6
        for i in range(8):
            a = i / 8 * TAU + 0.2
            p = pol(Ro, a, 6.6 + 0.9 * math.sin(i * 1.7))
            nrm = Vector((math.cos(a), math.sin(a), 0.25)).normalized()
            if i % 2 == 0:
                mini_scarab(m, p - Vector((0, 0, 0.6)), nrm, 0.95)
            elif i in (1, 5):
                orn_torus(B(m, 'gold13', True), p, 0.62, 0.15, axis=nrm, seg=20, sides=6)
                orn_gem(B(m, 'gemt13', False), p, 0.55, direction=nrm)
            else:
                orn_ball(B(m, 'jade13', True), p, 0.55, sub=2)
                orn_torus(B(m, 'gold13', True), p, 0.6, 0.12, tilt=0.5, seg=20, sides=5)
                orn_ball(B(m, 'G:gturq13', True), p + Vector((0, 0, 0.75)), 0.2, sub=1)
    return build(m, 'Egg_R13_T4', P13, off)


def sun_crown(m, z, n, Rs, ring='gold13', ring2='goldd13', bead='jade13', out=0.6, rr=0.36, gems=('gemt13', 'gemr13')):
    """Couronne qui tourne : anneau d'or et petits disques solaires debout tournés vers l'extérieur, perles de jade."""
    Rc = rmax(m, z) + out
    orn_torus(B(m, ring, True), (0, 0, z), Rc, rr, seg=64, sides=8)
    orn_torus(B(m, ring2, True), (0, 0, z - rr * 0.9), Rc * 0.99, rr * 0.6, seg=56, sides=6)
    for i in range(n):
        a = i / n * TAU
        nrm = Vector((math.cos(a), math.sin(a), 0.3)).normalized()
        c = pol(Rc + 0.15, a, z + rr + Rs * 1.1)
        sun_disc(m, c, nrm, Rs, nrays=8, thick=0.32, ray2='brick13', inner='jade13', dots=None,
                 gem=gems[i % len(gems)], ray_len=0.5)
        orn_cyl(B(m, ring2, False), pol(Rc, a, z), (0, 0, 1), rr + Rs * 0.5, 0.16, sides=6)
        orn_ball(B(m, bead, True), pol(Rc, a + TAU / (2 * n), z + rr * 0.7), 0.42, sub=1)
    return Rc


def build_T5(off):
    """Sunstone Egg : bandes de jade et d'or (gradins d'or sur jade sombre, liserés rouge brique), grand disque solaire
    d'or à rayons à l'avant, petit soleil au dos, gemmes sur les flancs, sommet à gradins et gemme, couronne de petits
    disques solaires qui tourne."""
    W, H = SIZES[5]
    m = Vox(H, seed=1305)
    egg_body(m, W, H, 'jade13', 13051, bump=0.3)
    m.paint(lambda x, y, z: vnoise(x + 3, y, z, 52, 3.0) > 0.45, 'jadex13')
    veins(m, 'jadel13', 51, 3.6, 0.07)
    m.paint(lambda x, y, z: z <= 1.6, 'stoned13')
    m.paint(lambda x, y, z: 2 <= z <= 5, 'jaded13')
    m.paint(lambda x, y, z: z == 2, 'gold13')
    stepzig_paint(m, 'gold13', 3, 10, 2, base=0)
    m.paint(lambda x, y, z: z == 6, 'brick13')
    m.paint(lambda x, y, z: z == 15, 'brick13')
    m.paint(lambda x, y, z: 16 <= z <= 17, 'gold13')
    stepzig_paint(m, 'jaded13', 17, 12, 1, base=0, down=True, phase=0.5)
    m.paint(lambda x, y, z: z >= 19, 'jadel13')
    body_sun(m, FRONT, 10.4, 2.9, thick=0.55, nrays=14, glow=None)
    body_sun(m, FRONT + math.pi, 10.6, 1.7, thick=0.45, nrays=10, inner='turq13', dots=None)
    for s in (1, -1):
        medallion(m, FRONT + s * 1.25, 8.0, 0.8, 'gemt13')
    glow_dots(m, 'G:ggold13', 3, lambda x, y, z: m.cells[(x, y, z)] == 'gold13' and 16 <= z <= 17, mind=5.0)
    tz = ztop(m, 0, 0)
    nrm = Vector((0, -1, 0))
    for i, (w, key) in enumerate(((3.2, 'gold13'), (2.2, 'jade13'), (1.3, 'gold13'))):
        orn_cyl(B(m, key, False), (0, 0, tz - 0.4 + i * 0.6), (0, 0, 1), 0.62, w / 2, sides=4)
    orn_gem(B(m, 'gemt13', False), (0, 0, tz + 1.75), 0.5, direction=(0, 0, 1))
    nest(m, ['jaded13', 'stoned13', 'jadex13'], 16)
    ruin_litter(m, 5, size=(0.85, 1.2), columns=1)
    with layer(m, 'Crown'):
        sun_crown(m, H - 7.0, 7, 0.95)
    return build(m, 'Egg_R13_T5', P13, off)


def _wing_zone(zr, half=4.2):
    return lambda a, z: abs(math.cos(a)) > 0.8 and zr - half < z < zr + half


def build_T6(off):
    """Serpent Egg : pierre sculptée (bandes de gradins rouge brique, liseré d'or, haut de jade sombre), serpent à
    plumes de jade bagué d'or enroulé autour de l'œuf, tête à l'avant avec collerette de plumes rouges et bleues,
    plumes au bout de la queue, ailes de plumes, gemmes et petits soleils en orbite."""
    W, H = SIZES[6]
    m = Vox(H, seed=1306)
    egg_body(m, W, H, 'stone13', 13061, bump=0.45)
    m.paint(lambda x, y, z: vnoise(x, y, z, 61, 2.6) > 0.45, 'stonel13')
    m.paint(lambda x, y, z: z <= 1.8 + wave(math.atan2(y, x), 5, 0.5), 'stoned13')
    m.paint(lambda x, y, z: z == 3, 'gold13')
    stepzig_paint(m, 'brick13', 4, 8, 2, base=0)
    m.paint(lambda x, y, z: z == 7, 'brick13')
    zigzag_paint(m, 'jaded13', 12.5, 1.0, 9, width=0.5)
    m.paint(lambda x, y, z: z >= H - 6.5, 'jaded13')
    stepzig_paint(m, 'gold13', H - 6.5, 9, 2, down=True, base=0)
    m.paint(lambda x, y, z: z >= H - 2.4, 'jade13')
    zw = 15.5
    # serpent : 1,25 tour du bas (queue à gauche) jusqu'à l'avant, puis il monte et la tête sort vers l'avant
    turns, Nc = 1.25, 15
    ctrl = []
    for k in range(Nc + 1):
        f = k / Nc
        a = FRONT - turns * TAU * (1 - f)
        z = 1.4 + (9.0 - 1.4) * f
        r = max(rs(m, a + da, z + dz) for da in (-0.12, 0, 0.12) for dz in (-0.6, 0, 0.6)) + 0.25
        ctrl.append(pol(r, a, z))
    for z in (11.3, 13.4):
        ctrl.append(pol(surf_r(m, FRONT, z, 0.1, 0.6) + 0.3, FRONT, z))
    rN = surf_r(m, FRONT, 15.2, 0.1, 0.6)
    ctrl += [pol(rN + 1.0, FRONT, 15.4), pol(rN + 2.2, FRONT, 16.0)]
    P, rad = serpent_body(m, ctrl, 0.95, 0.3, every=1.45)
    f = (P[-1] - P[-6]).normalized()
    f = (f + Vector((0, -0.8, 0.1))).normalized()
    hc = P[-1] + f * 1.0
    serpent_head(m, hc, f, 1.5)
    # collerette de plumes rouges et bleues autour de la tête, tournée vers l'avant
    cc = hc - f * 1.0
    orn_torus(B(m, 'gold13', True), cc, 1.45, 0.3, axis=f, seg=28, sides=6)
    plume_ring(m, cc - f * 0.25, f, 1.3, 3.5, ['fred13', 'fblue13'], 16, 1.35, tilt=-0.25, tips=['gold13', 'turq13'],
               a0=TAU / 32)
    plume_ring(m, cc + f * 0.1, f, 1.2, 2.3, ['jade13', 'jadel13'], 12, 1.05, tilt=-0.1, a0=0.2, tips=['gold13'])
    # plumes au bout de la queue
    tq = (P[0] - P[3]).normalized()
    for k, (key, a) in enumerate((('fred13', -0.5), ('fblue13', 0.0), ('jade13', 0.5))):
        side = tq.cross(UP).normalized()
        feather(m, key, P[0], (tq + side * a + UP * 0.25).normalized(), UP, 1.9, 0.75, tip='gold13', thick=0.14)
    # sommet : petit soleil d'or posé à plat sur des gradins
    tz = ztop(m, 0, 0)
    for i, (w, key) in enumerate(((3.0, 'gold13'), (2.0, 'jade13'))):
        orn_cyl(B(m, key, False), (0, 0, tz - 0.4 + i * 0.6), (0, 0, 1), 0.62, w / 2, sides=4)
    sun_disc(m, (0, 0.2, tz + 2.6), (0, -1, 0), 1.3, nrays=10, thick=0.4, inner='turq13', dots=None, post=0.0)
    orn_cyl(B(m, 'goldd13', False), (0, 0.2, tz + 0.5), (0, 0, 1), 1.0, 0.25, sides=8)
    medallion(m, FRONT + math.pi, 13.5, 1.0, 'gemt13')
    nest(m, ['jaded13', 'stoned13', 'jadex13'], 18)
    ruin_litter(m, 5, size=(0.9, 1.25), columns=2)
    for s, g in ((1, 'WingR'), (-1, 'WingL')):
        with layer(m, g):
            r = rs(m, 0 if s > 0 else math.pi, zw) - 0.9
            feather_wing(m, (s * r, 0.4, zw), s, 9.5, a_hi=62, a_lo=-22, n=9, W=1.55, cuff_r=0.95)
    with layer(m, 'Orbit'):
        Ro = W / 2 + 4.8
        gems = ['gemt13', 'gemr13', 'gemj13']
        for i in range(10):
            a = i / 10 * TAU + 0.3
            zz = 3.2 + (i % 3) * 1.1
            p = pol(Ro, a, zz)
            nrm = Vector((math.cos(a), math.sin(a), 0.2)).normalized()
            if i in (0, 4, 7):
                sun_disc(m, p, nrm, 1.15, nrays=10, thick=0.36, inner='jade13', dots=None, ray_len=0.5,
                         gem=gems[(0, 4, 7).index(i)])
            elif i % 2:
                orn_torus(B(m, 'gold13', True), p, 0.82, 0.17, axis=nrm, seg=22, sides=6)
                orn_gem(B(m, gems[i % 3], False), p, 0.76, direction=nrm)
            else:
                orn_ball(B(m, 'G:gturq13', True), p, 0.45, sub=2)
                orn_torus(B(m, 'gold13', True), p, 0.75, 0.13, tilt=0.6, seg=20, sides=5)
    return build(m, 'Egg_R13_T6', P13, off)


def build_T7(off):
    """Temple Egg : grand œuf-pyramide de jade à gradins (marches d'or, rangées de jade sombre, base de pierre et de
    brique), grand escalier crème à rampes rouges et têtes de serpent, temple miniature au sommet (porte lumineuse,
    toit rouge et or, crête à gradins), grand soleil d'or rayonnant derrière, halo d'or et de gemmes autour du temple,
    couronne de petites idoles, grandes ailes de plumes, anneau de soleils, gemmes et blocs de ruines en orbite."""
    W, H = SIZES[7]
    m = Vox(H, seed=1307)
    TH = 3
    tiers = pyramid_body(m, W, H, 'jade13', TH)
    nt = len(tiers)
    for c in m.surface():
        x, y, z = c
        k, r = divmod(z, TH)
        if k <= 1:
            key = 'stoned13' if r == 0 else ('brick13' if r == TH - 1 else 'stone13')
        else:
            key = 'jaded13' if r == 0 else ('gold13' if r == TH - 1 else 'jade13')
            if r == 1 and (x + y) % 4 == 0:
                key = 'jadel13'
        if z == H - 1:
            key = 'gold13'
        m.cells[c] = key
    # escalier à l'avant (au-dessus du gradin le plus large), rampes rouge brique
    zt = H - 1
    a_top = tiers[-1][2]
    kw = max(range(nt), key=lambda k: tiers[k][2])
    zs0 = tiers[kw][1]
    ys = {}
    for z in range(zs0, zt + 1):
        env = a_top + 0.9 + (zt - z) * 0.36
        ys[z] = -int(math.floor(env))
    stairs = []
    for z in range(zs0, zt + 1):
        for x in range(-2, 3):
            y = ys[z] if abs(x) < 2 else ys.get(z - 1, ys[z])
            while (x, y, z) not in m.cells and y < 0:
                m.put((x, y, z), 'brick13' if abs(x) == 2 else 'cream13')
                stairs.append((x, y, z))
                y += 1
    for (x, y, z) in stairs:
        if abs(x) < 2:
            m.cells[(x, y, z)] = 'cream13' if (x, y, z + 1) not in m.cells else 'stone13'
    # temple au sommet
    zp = zt + 1
    for x in range(-2, 3):
        for y in range(-1, 3):
            for z in range(zp, zp + 3):
                if x == 0 and y == -1 and z < zp + 2:
                    continue
                m.put((x, y, z), 'cream13' if abs(x) < 2 and y > -1 else 'stone13')
    for z in (zp, zp + 1):
        m.put((0, 0, z), 'G:ggold13')
        for x in (-1, 1):
            m.put((x, -1, z), 'gold13')
    m.put((0, -1, zp + 2), 'gold13')
    for x in range(-3, 4):
        for y in range(-2, 4):
            m.put((x, y, zp + 3), 'gold13' if abs(x) == 3 or y in (-2, 3) else 'brick13')
    for x in range(-2, 3):
        for y in range(-1, 3):
            m.put((x, y, zp + 4), 'brick13')
    m.body = set(m.cells)
    # crête du toit à gradins et gemme
    for i, (w, h) in enumerate(((4.4, 0.9), (3.0, 0.8), (1.6, 0.8))):
        box(m, 'gold13' if i != 1 else 'goldd13', Vector((0, 0.6, zp + 5.0 + i * 0.8)), Vector((1, 0, 0)), UP,
            Vector((0, -1, 0)), w, h, 0.6)
    orn_gem(B(m, 'gemt13', False), (0, 0.15, zp + 5.85), 0.4, direction=(0, -1, 0))
    # grand soleil d'or derrière le temple, tenu par une poutre
    sc = Vector((0, 9.2, zp + 4.6))
    sun_disc(m, sc, (0, -1, 0), 6.0, nrays=16, thick=0.8, ray_len=0.6, inner='jade13', gem='gemt13', glow='G:ggold13')
    zb = 26.0
    yb = rs(m, math.pi / 2, zb) - 0.5
    orn_cyl(B(m, 'goldd13', False), (0, yb, zb), (0, 1, 0), sc.y - yb, 0.55, sides=10)
    # têtes de serpent au pied des rampes
    for sx in (-1, 1):
        y0 = ys[zs0]
        serpent_head(m, Vector((sx * 3.0, y0 - 1.0, zs0 + 0.4)), Vector((0, -1, 0.12)), 0.8,
                     crest=('fred13', 'fblue13', 'jade13'))
    # gemmes serties au dos et sur les coins arrière
    for th, z in ((math.pi / 2, 16.5), (math.pi / 2, 10.5), (math.pi / 4, 13.5), (3 * math.pi / 4, 13.5)):
        medallion(m, th, z, 0.9, 'gemt13' if z != 10.5 else 'gemr13')
    glow_dots(m, 'G:ggold13', 4, lambda x, y, z: m.cells[(x, y, z)] == 'gold13' and 6 <= z <= 24 and y > 2, mind=6)
    nest(m, ['jaded13', 'stoned13', 'jadex13'], 22)
    ruin_litter(m, 7, size=(1.0, 1.45), columns=2)
    zw = 14.0
    for s, g in ((1, 'WingR'), (-1, 'WingL')):
        with layer(m, g):
            r = rs(m, 0 if s > 0 else math.pi, zw) - 1.0
            feather_wing(m, (s * r, 0.5, zw), s, 13.5, a_hi=64, a_lo=-10, n=11, W=2.1, cuff_r=1.25)
    with layer(m, 'Crown'):
        zc = zp + 0.1
        Rc = 6.2
        orn_torus(B(m, 'gold13', True), (0, 0, zc), Rc, 0.4, seg=72, sides=8)
        orn_torus(B(m, 'goldd13', True), (0, 0, zc - 0.36), Rc * 0.99, 0.24, seg=64, sides=6)
        for i in range(6):
            a = i / 6 * TAU + TAU / 12
            mini_idol(m, pol(Rc, a, zc + 0.3), (math.cos(a), math.sin(a), 0), 0.8)
            ab = a + TAU / 12
            orn_torus(B(m, 'gold13', True), pol(Rc, ab, zc + 0.85), 0.5, 0.12, axis=(math.cos(ab), math.sin(ab), 0),
                      seg=18, sides=5)
            orn_gem(B(m, 'gemt13' if i % 2 else 'gemr13', False), pol(Rc, ab, zc + 0.85), 0.45,
                    direction=(math.cos(ab), math.sin(ab), 0))
    with layer(m, 'Halo'):
        zh, Rh = zp + 6.3, 6.4
        orn_torus(B(m, 'gold13', True), (0, 0, zh), Rh, 0.3, seg=72, sides=8)
        for i in range(8):
            a = i / 8 * TAU + TAU / 16
            if i % 2 == 0:
                orn_ball(B(m, 'G:ggold13', True), pol(Rh, a, zh + 0.5), 0.42, sub=2)
            else:
                nrm = (math.cos(a), math.sin(a), 0)
                orn_torus(B(m, 'goldd13', True), pol(Rh, a, zh + 0.6), 0.5, 0.12, axis=nrm, seg=18, sides=5)
                orn_gem(B(m, 'gemt13' if i % 4 == 1 else 'gemj13', False), pol(Rh, a, zh + 0.6), 0.45, direction=nrm)
    with layer(m, 'Orbit'):
        Ro, zo, tl = 15.6, 4.2, 0.13
        rot = orn_torus(B(m, 'goldd13', True), (0, 0, zo), Ro, 0.3, tilt=tl, seg=96, sides=8)
        gems = ['gemt13', 'gemr13', 'gemj13']
        for i in range(6):
            a = i / 6 * TAU
            p = Vector((0, 0, zo)) + rot @ Vector((Ro * math.cos(a), Ro * math.sin(a), 0))
            nrm = Vector((math.cos(a), math.sin(a), 0.15)).normalized()
            if i % 2 == 0:
                sun_disc(m, p + Vector((0, 0, 0.4)), nrm, 1.2, nrays=10, thick=0.4, inner='jade13', dots=None,
                         gem=gems[i // 2], ray_len=0.55)
            else:
                orn_torus(B(m, 'gold13', True), p + Vector((0, 0, 0.3)), 0.85, 0.18, axis=nrm, seg=24, sides=6)
                orn_gem(B(m, gems[i // 2], False), p + Vector((0, 0, 0.3)), 0.8, direction=nrm)
        for i in range(3):
            a = i / 3 * TAU + 0.5
            c = pol(18.2, a, 1.6 + i * 1.0)
            u = Vector((math.cos(a + 1.2), math.sin(a + 1.2), 0))
            n_ = UP.cross(u)
            box(m, 'stone13', c, u, UP, n_, 2.2, 1.5, 1.5)
            box(m, 'gold13', c + UP * 0.35, u, UP, n_, 2.26, 0.26, 1.56)
            box(m, 'jaded13', c - UP * 0.3, u, UP, n_, 2.26, 0.2, 1.56)
            b = a + TAU / 6
            orn_ball(B(m, 'G:ggold13' if i != 1 else 'jade13', True), pol(17.8, b, 4.4 - i * 1.0), 0.6, sub=2)
            if i == 1:
                orn_torus(B(m, 'gold13', True), pol(17.8, b, 4.4 - i * 1.0), 0.85, 0.14, tilt=0.5, seg=24, sides=6)
    return build(m, 'Egg_R13_T7', P13, off)


BUILDERS = {2: build_T2, 3: build_T3, 4: build_T4, 5: build_T5, 6: build_T6, 7: build_T7}



def drop(name):
    """Retire une collection d'œuf (et ses maillages) pour la reconstruire."""
    cl = bpy.data.collections.get(name)
    if not cl:
        return
    for o in list(cl.objects):
        me = o.data
        bpy.data.objects.remove(o, do_unlink=True)
        if me and me.users == 0:
            bpy.data.meshes.remove(me)
    bpy.data.collections.remove(cl)


def build_one(n):
    drop('Egg_R13_T%d' % n)
    random.seed(1300 + n)
    coll = BUILDERS[n]((OFFSETS[n], 0, 0))
    obs = [o for o in coll.objects if o.type == 'MESH']
    for o in list(obs):
        if not len(o.data.vertices):
            bpy.data.objects.remove(o, do_unlink=True)
    obs = [o for o in coll.objects if o.type == 'MESH']
    tris = sum(len(p.vertices) - 2 for o in obs for p in o.data.polygons)
    zs = [(o.matrix_world @ v.co).z for o in obs for v in o.data.vertices]
    xs = [(o.matrix_world @ v.co).x for o in obs for v in o.data.vertices]
    print('Egg_R13_T%d : %d objets, %d triangles, x %.1f..%.1f, z %.2f..%.2f, max tris/objet %d' % (
        n, len(obs), tris, min(xs), max(xs), min(zs), max(zs),
        max(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in obs)))
    return coll


def build_all():
    for n in sorted(BUILDERS):
        build_one(n)


def save_eggs(path):
    """Enregistre seulement les six collections d'œufs (avec faux utilisateur) sans toucher au fichier ouvert dans
    Blender, partagé avec d'autres travaux. Pour les retrouver : Fichier > Ajouter (Append) > Collection.
    (Écrire aussi une scène dans le fichier a fait planter Blender une fois : on ne le fait plus.)"""
    colls = [bpy.data.collections.get('Egg_R13_T%d' % n) for n in sorted(BUILDERS)]
    colls = [c for c in colls if c]
    bpy.data.libraries.write(path, set(colls), fake_user=True, compress=True)
    print('enregistré', path, [c.name for c in colls])


# CONTRÔLES (comme les anneaux 9 à 11) -------------------------------------------------------

GROUPS = ('Crown', 'Orbit', 'Halo', 'WingL', 'WingR')


def _grp(o):
    for g in GROUPS:
        if '_A' + g + '_' in o.name:
            return g
    return None


def _pts(o):
    mw = o.matrix_world
    me = o.data
    P = [mw @ v.co for v in me.vertices]
    for e in me.edges:
        a, b = me.vertices[e.vertices[0]].co, me.vertices[e.vertices[1]].co
        if (a - b).length > 0.6:
            k = int((a - b).length / 0.4)
            P += [mw @ a.lerp(b, (i + 1) / (k + 1)) for i in range(k)]
    return P


def clash(coll_name, margin=0.3, beat=0.28):
    """Les groupes qui tournent (Crown, Orbit, Halo) balaient un anneau autour de l'axe : rien d'autre (ailes qui
    battent, ornements fixes, autre groupe) ne doit y entrer. Les ailes battent de ±beat autour de leur bord intérieur
    (à mi-hauteur), comme dans Eggs.client : elles ne doivent pas non plus toucher les ornements fixes."""
    from mathutils.kdtree import KDTree
    coll = bpy.data.collections[coll_name]
    obs = [o for o in coll.objects if o.type == 'MESH']
    body = [o for o in obs if _grp(o) is None and '_ORN_' not in o.name]
    bp = [o.matrix_world @ v.co for o in body for v in o.data.vertices]
    cx = (min(p.x for p in bp) + max(p.x for p in bp)) / 2
    cy = (min(p.y for p in bp) + max(p.y for p in bp)) / 2
    if coll_name[-1].isdigit() and int(coll_name[-1]) in OFFSETS:
        cx, cy = OFFSETS[int(coll_name[-1])], 0.0   # axe de l'œuf (l'escalier du Cosmic décale la boîte du corps)
    pts = {}
    for o in obs:
        g = _grp(o) or ('static' if '_ORN_' in o.name else 'body')
        pts.setdefault(g, []).extend(_pts(o))
    moving = {}
    for g in ('WingL', 'WingR'):
        if g not in pts:
            continue
        P = pts[g]
        x0, x1 = min(p.x for p in P), max(p.x for p in P)
        z0, z1 = min(p.z for p in P), max(p.z for p in P)
        side = 1 if (x0 + x1) / 2 > cx else -1
        px, pz = (x0 + x1) / 2 - side * (x1 - x0) * 0.45, (z0 + z1) / 2
        out = []
        for k in range(-4, 5):
            a = beat * k / 4
            ca, sa = math.cos(a), math.sin(a)
            out += [Vector((px + (p.x - px) * ca - (p.z - pz) * sa, p.y, pz + (p.x - px) * sa + (p.z - pz) * ca)) for p in P]
        moving[g] = out
    report = []
    for g in ('Crown', 'Orbit', 'Halo'):
        if g not in pts:
            continue
        bins = {}
        for p in pts[g]:
            b = int(math.floor(p.z / 0.5))
            r = math.hypot(p.x - cx, p.y - cy)
            lo, hi = bins.get(b, (1e9, -1e9))
            bins[b] = (min(lo, r), max(hi, r))
        others = [(k, v) for k, v in moving.items()] + [('static', pts.get('static', []))] + \
                 [(k, pts[k]) for k in ('Crown', 'Orbit', 'Halo') if k in pts and k != g]
        for k, P in others:
            n = 0
            ex = None
            for p in P:
                b = int(math.floor(p.z / 0.5))
                r = math.hypot(p.x - cx, p.y - cy)
                for bb in (b - 1, b, b + 1):
                    if bb in bins and bins[bb][0] - margin <= r <= bins[bb][1] + margin:
                        n += 1
                        ex = (round(r, 2), round(p.z, 2))
                        break
            if n:
                report.append('%s balaie %s : %d points (ex. r=%s z=%s)' % (g, k, n, ex[0], ex[1]))
    st = pts.get('static', [])
    if st:
        kd = KDTree(len(st))
        for i, p in enumerate(st):
            kd.insert(p, i)
        kd.balance()
        for g, P in moving.items():
            n = sum(1 for p in P if kd.find(p)[2] < margin)
            if n:
                report.append('%s (battement) touche des ornements fixes : %d points' % (g, n))
    print(coll_name, 'clash :', report or 'rien')
    return report


def _area(o):
    mw = o.matrix_world
    s = mw.to_scale()
    return sum(p.area for p in o.data.polygons) * abs(s.x * s.y * s.z) ** (2 / 3)


def neon_share(coll_name):
    coll = bpy.data.collections[coll_name]
    obs = [o for o in coll.objects if o.type == 'MESH']
    tot = sum(_area(o) for o in obs)
    glow = sum(_area(o) for o in obs if o.name.split('_')[-1].startswith('Gg'))
    print('%s : néon %.1f %% de la surface (%.0f / %.0f)' % (coll_name, 100 * glow / tot, glow, tot))
    return glow / tot


print("eggs_r13 chargé")
