# Œufs de l'anneau 14 « Phantom Mist » (une brume hantée, mignonne et rassurante : fantômes souriants, citrouilles
# sculptées au sourire gentil, bougies, vieilles lanternes de fer à flamme turquoise, feux follets, brume pâle, toiles
# d'araignée stylisées, lune ; rien d'effrayant), même méthode que les anneaux 1 à 13 :
# corps en briques (voxkit.Vox) + ornements lisses (_ORN_), groupes animés (_ACrown_, _AOrbit_, _AHalo_, _AWingL_,
# _AWingR_). Charger voxkit.py avant ce fichier, puis build_all() ou build_one(n).
# clash(coll) vérifie qu'un groupe qui tourne ne traverse ni les ailes qui battent ni les ornements fixes ;
# neon_share(coll) donne la part de surface en néon (à garder sous 5 %).
# Les clés de couleur lumineuses commencent par « g » (gturq14...) : neon_share les reconnaît ainsi.
# Les couleurs sont converties sRGB -> linéaire par voxkit.material (l'import Ropilot les relit comme linéaires).
# Les néons sont un peu plus foncés que la palette (un néon trop clair sort blanc dans Studio).
# Blender est partagé : charger voxkit puis ce fichier dans un espace de noms à part, par exemple
#   NS = {}; exec(open(voxkit).read(), NS); exec(open(eggs_r14).read(), NS); NS['build_all']()

TAU = math.tau

P14 = dict(
    night14='#1E2A3A', nightl14='#2B3B50',
    slate14='#4A5868', slatel14='#66778A', slated14='#36424F',
    mist14='#DDEFF0', mistd14='#B9D3D8',
    turq14='#6EF0DC', turqd14='#2FA79A',
    pump14='#F2862E', pumpd14='#B8561C', pumpl14='#FFA552',
    stem14='#5E8A3A', stemd14='#40632A',
    violet14='#7A5AB8', violetd14='#563F8C',
    cream14='#F6E9C8', creamd14='#DCCA9F',
    ink14='#22202A', iron14='#3A3844',
    moon14='#F4E6B4', moond14='#D9C88C',
    blush14='#F4A9B8', tongue14='#E8708A',
    gturq14='#3FD2BC', gflame14='#E8801E', gwin14='#EFA830',
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


def surf_pt(m, p, lift):
    """Ramène le point p sur la coquille (à lift au-dessus), dans sa direction depuis l'axe."""
    th = math.atan2(p.y, p.x)
    return pol(rs(m, th, p.z) + lift, th, p.z)


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

# REPRIS DE L'ANNEAU 12 (aile en éventail, filament, croissant de lune) ---------------------------------

def fin(m, root, side, rays, mem_key, ray_key, tip_key, sweep=0.22, thick=0.24, notch=0.8, ray_r=0.34, tip_r=0.3,
        curve=0.0, lead=None, lead_r=0.6):
    """Aile en éventail : voile (plaque fine à bord découpé) + rayons + billes au bout.
    rays : [(angle en degrés au-dessus de l'horizontale, longueur)], du haut vers le bas. side = +1 ou -1 (x)."""
    R0 = Vector(root)

    def P(ang, L):
        a = math.radians(ang)
        u, v = math.cos(a) * L, math.sin(a) * L
        return R0 + Vector((side * u, sweep * u + curve * u * u, v))

    tips = [P(a, L) for a, L in rays]
    outline = [R0]
    for i, (a, L) in enumerate(rays):
        outline.append(tips[i])
        if i + 1 < len(rays):
            a2, L2 = rays[i + 1]
            outline.append(P((a + a2) / 2, (L + L2) / 2 * notch))
    nrm = Vector((-side * sweep, 1, 0)).normalized()
    bm = B(m, mem_key, False)
    top = [bm.verts.new(p + nrm * thick / 2) for p in outline]
    bot = [bm.verts.new(p - nrm * thick / 2) for p in outline]
    for k in range(1, len(outline) - 1):
        bm.faces.new((top[0], top[k], top[k + 1]))
        bm.faces.new((bot[0], bot[k + 1], bot[k]))
    for k in range(len(outline)):
        j = (k + 1) % len(outline)
        bm.faces.new((top[k], bot[k], bot[j], top[j]))
    for i, (a, L) in enumerate(rays):
        key, rr = ray_key, ray_r
        if i == 0 and lead:
            key, rr = lead, lead_r
        mid = P(a + (3 if i < len(rays) / 2 else -3), L * 0.5)
        orn_sweep(B(m, key, True), [R0, mid, tips[i]], [rr, rr * 0.82, rr * 0.5], sides=7)
        if tip_key:
            orn_ball(B(m, tip_key, True), tips[i], tip_r, sub=1)
    return tips, P, nrm


def filament(m, key, a0, z0, z1, turns, lift=0.12, r=0.2, wob=0.6, seed=0, nodes=None, node_r=0.38, n_nodes=3,
             avoid=None):
    """Filament de mycélium qui s'enroule sur la coquille ; billes lumineuses (nodes) ; avoid(a, z) coupe le tracé."""
    rnd = random.Random(seed)
    ph = rnd.uniform(0, TAU)
    N = int(abs(turns) * 70 + abs(z1 - z0) * 3) + 10
    A, Z = [], []
    for i in range(N + 1):
        f = i / N
        A.append(a0 + turns * TAU * f)
        Z.append(z0 + (z1 - z0) * f + wob * math.sin(f * 9 + ph))
    raw = [max(rs(m, A[i], Z[i] + d) for d in (-0.5, 0, 0.5)) for i in range(N + 1)]
    env = [max(raw[max(0, i - 2):i + 3]) for i in range(N + 1)]
    sm = [sum(env[max(0, i - 3):i + 4]) / len(env[max(0, i - 3):i + 4]) for i in range(N + 1)]
    P = [pol(max(sm[i], env[i] - 0.2) + lift + r * 0.4, A[i], Z[i]) for i in range(N + 1)]
    runs, cur = [], []
    for i, p in enumerate(P):
        if avoid and avoid(A[i], Z[i]):
            if len(cur) > 3:
                runs.append(cur)
            cur = []
        else:
            cur.append(p)
    if len(cur) > 3:
        runs.append(cur)
    for run in runs:
        tube(B(m, key, True), run, [r * (0.6 + 0.4 * math.sin(math.pi * (j + 0.5) / len(run))) for j in range(len(run))],
             sides=6)
    if nodes:
        allp = [p for run in runs for p in run]
        for k in range(n_nodes):
            if allp:
                orn_ball(B(m, nodes, True), allp[int((k + 0.5) / n_nodes * len(allp))], node_r, sub=1)
    return runs


def crescent_slab(bm, pts, n, origin, u, v, nn, thick):
    """Plaque épaisse en croissant, faite en bandes entre l'arc extérieur (pts[0..n]) et l'arc intérieur (le reste,
    du bas vers le haut) : la triangulation automatique d'un contour concave retournait des triangles."""
    O = pts[:n + 1]
    I = [O[0]] + pts[n + 1:][::-1] + [O[n]]
    sides = []
    for sd in (1, -1):
        off = Vector(origin) + Vector(nn) * (sd * thick / 2)
        Ov = [bm.verts.new(off + u * x + v * y) for x, y in O]
        Iv = [Ov[0]] + [bm.verts.new(off + u * x + v * y) for x, y in I[1:-1]] + [Ov[-1]]
        for i in range(n):
            q = []
            for vv in (Ov[i], Ov[i + 1], Iv[i + 1], Iv[i]):
                if vv not in q:
                    q.append(vv)
            bm.faces.new(q)
        sides.append(Ov + Iv[1:-1][::-1])
    a, b = sides
    k = len(a)
    for i in range(k):
        j = (i + 1) % k
        bm.faces.new((a[i], b[i], b[j], a[j]))


def crescent(m, key, c, R, k=0.8, off=0.42, normal=(0, -1, 0), spin=0.0, thick=0.9, n=36, back=None, craters=None,
             glow_rim=None, glow_r=0.3):
    """Croissant de lune : plaque épaisse (cercle moins un cercle décalé), cornes vers spin ; plaque plus sombre
    derrière (back) qui fait le contour, petits cratères en creux (craters) sur la face avant."""
    d, ri = off * R, k * R
    x = (R * R - ri * ri + d * d) / (2 * d)
    y = math.sqrt(max(0.0, R * R - x * x))
    al, be = math.atan2(y, x), math.atan2(y, x - d)
    pts = [(R * math.cos(al + (TAU - 2 * al) * i / n), R * math.sin(al + (TAU - 2 * al) * i / n)) for i in range(n + 1)]
    pts += [(d + ri * math.cos(TAU - be - (TAU - 2 * be) * i / n), ri * math.sin(TAU - be - (TAU - 2 * be) * i / n))
            for i in range(1, n)]
    cs, sn = math.cos(spin), math.sin(spin)
    pts = [(px * cs - py * sn, px * sn + py * cs) for px, py in pts]
    nn, u, v = frame(normal)
    c = Vector(c)
    crescent_slab(B(m, key, False), pts, n, c, u, v, nn, thick)
    if back:
        crescent_slab(B(m, back, False), [(px * 1.07, py * 1.07) for px, py in pts], n, c - nn * thick * 0.45, u, v,
                      nn, thick * 0.6)
    if glow_rim:
        P = [c + u * px + v * py for px, py in pts]
        tube(B(m, glow_rim, True), dense(P + [P[0]], 0.2), glow_r, sides=6)
    if craters:
        for (cx, cy, cr) in craters:
            px, py = cx * cs - cy * sn, cx * sn + cy * cs
            orn_cyl(B(m, craters_key(key), False), c + u * px * R + v * py * R + nn * (thick * 0.5 - 0.1), nn, 0.18,
                    cr * R, sides=10)
    return nn, u, v



def craters_key(key):
    return 'moond14' if key == 'moon14' else key


# FORMES DE L'ANNEAU 14 ---------------------------------------------------------------------------

def nrm_at(th):
    return Vector((math.cos(th), math.sin(th), 0))


def shell_pt(m, th, z, hw=0.4, hh=0.4, lift=0.0):
    """Point posé sur la coquille : le plus grand rayon sur une petite zone hw x hh autour de (th, z)."""
    k = hw / max(rs(m, th, z), 1.0)
    r0 = max(rs(m, th + da, z + dz) for da in (-k, 0, k) for dz in (-hh, 0, hh))
    return pol(r0 + lift, th, z)


def shell_path(m, A, Z, lift=0.1, k=0.05, dz=0.35):
    """Tracé qui suit la coquille (rayon lissé, jamais rentré de plus de 0.12) aux angles A et hauteurs Z."""
    raw = [max(rs(m, a + da, z + d) for da in (-k, 0, k) for d in (-dz, 0, dz)) for a, z in zip(A, Z)]
    n = len(raw)
    sm = [sum(raw[max(0, i - 2):i + 3]) / len(raw[max(0, i - 2):i + 3]) for i in range(n)]
    sm = [max(a, b - 0.12) for a, b in zip(sm, raw)]
    return [pol(r + lift, a, z) for r, a, z in zip(sm, A, Z)]


def hem_paint(m, key, z0, n=7, amp=0.9, phase=0.0, down=False):
    """Bord festonné sous lequel on peint key : festons arrondis vers le haut (brume, vagues) ou, si down, vers le bas
    (ourlet d'un drap de fantôme qui pend au-dessus de key)."""
    def edge(th):
        f = (n * th / TAU + phase) % 1.0
        s = math.sqrt(max(0.0, 1 - (2 * f - 1) ** 2)) * 2 - 1
        return z0 + amp * (-s if down else s)
    m.paint(lambda x, y, z: z <= edge(math.atan2(y, x)), key)


def wax_paint(m, z0, n=8, seed=3, key='cream14', tip='creamd14', drip=(1.0, 3.4)):
    """Cire de bougie qui coule du sommet : z >= z0, avec des coulures arrondies de longueurs variées."""
    for c in m.surface():
        x, y, z = c
        th = math.atan2(y, x)
        g = n * (th + math.pi) / TAU
        b, f = int(math.floor(g)) % n, g % 1.0
        edge = z0
        if 0.15 < f < 0.65:
            L = drip[0] + (drip[1] - drip[0]) * _h(b, 0, 0, seed)
            edge = z0 - L * math.sin(math.pi * (f - 0.15) / 0.5) ** 0.6
        if z >= edge:
            m.cells[c] = tip if z < edge + 0.9 and edge < z0 - 0.5 else key


def shell_face(m, th, z, S=1.0, eye='ink14', shine='cream14', mouth='ink14', blush='blush14', open_mouth=False,
               tongue=None):
    """Visage de fantôme mignon sur la coquille : grands yeux ovales sombres à reflets, joues roses, sourire
    (fin, ou bouche ouverte en D avec langue)."""
    R = max(rs(m, th, z), 1.0)
    dep = 0.5 * S ** 0.5
    for sx in (-1, 1):
        a = th + sx * 1.15 * S / R
        p = shell_pt(m, a, z + 0.55 * S, 0.45 * S, 0.7 * S, lift=-0.12)
        nn, ue, ve = frame(nrm_at(a))
        ell(m, eye, p, ue, ve, nn, 0.5 * S, 0.75 * S, dep, sub=2)
        orn_ball(B(m, shine, True), p + nn * dep * 0.72 - ue * 0.16 * S + ve * 0.3 * S, 0.19 * S, sub=1)
        orn_ball(B(m, shine, True), p + nn * dep * 0.78 + ue * 0.15 * S - ve * 0.27 * S, 0.1 * S, sub=1)
        ab = th + sx * 2.05 * S / R
        pb = shell_pt(m, ab, z - 0.35 * S, 0.45 * S, 0.3 * S, lift=-0.16)
        nb, ub, vb = frame(nrm_at(ab))
        ell(m, blush, pb, ub, vb, nb, 0.46 * S, 0.29 * S, 0.3, sub=1)
    K = 14
    T = [-1 + 2 * i / K for i in range(K + 1)]
    A = [th + t * 0.95 * S / R for t in T]
    N = [nrm_at(a) for a in A]
    if not open_mouth:
        Z = [z - 0.75 * S + 0.36 * S * t * t for t in T]
        P = shell_path(m, A, Z, lift=0.02)
        tube(B(m, mouth, True), P, [0.13 * S * (0.75 + 0.25 * math.cos(t * math.pi / 2)) for t in T], sides=6)
    else:
        zc = z - 0.5 * S
        Wd = [0.55 * S * max(0.0, 1 - t * t) ** 0.7 for t in T]
        C = shell_path(m, A, [zc + 0.2 * S * t * t - w for t, w in zip(T, Wd)], lift=0.0)
        ribbon(B(m, mouth, False), C, Wd, [UP] * len(C), N, 0.44)
        if tongue:
            pt = shell_pt(m, th, zc - 0.8 * S, 0.4 * S, 0.2 * S, lift=0.06)
            nt, ut, vt = frame(nrm_at(th))
            ell(m, tongue, pt, ut, vt, nt, 0.4 * S, 0.24 * S, 0.24, sub=1)


def ghost(m, c, fwd, S, body='mist14', eye='ink14', blush='blush14', mouth='ink14', wave_arm=1, hem=7,
          open_mouth=False, shine='cream14'):
    """Petit fantôme lisse et souriant : tête ronde, corps qui s'évase, ourlet ondulé (boules), petits bras (l'un
    salue), grands yeux à reflets, joues roses, sourire. c : centre du bas du corps ; fwd : où il regarde."""
    nn, u, v = frame(fwd)
    c = Vector(c)
    hc = c + v * 1.75 * S
    orn_ball(B(m, body, True), hc, 1.05 * S, sub=3)
    orn_cyl(B(m, body, True), c + v * 0.25 * S, v, 1.55 * S, 1.24 * S, 1.03 * S, sides=20)
    for k in range(hem):
        a = k / hem * TAU + 0.25
        orn_ball(B(m, body, True), c + v * 0.32 * S + (u * math.cos(a) + nn * math.sin(a)) * 0.92 * S, 0.42 * S, sub=2)

    def onhead(du, dv, lift):
        d = (nn + u * du + v * dv).normalized()
        return hc + d * (1.05 * S + lift), d

    for sx in (-1, 1):
        e, d = onhead(sx * 0.4, 0.1, -0.05 * S)
        n2, u2, v2 = frame(d)
        ell(m, eye, e, u2, v2, n2, 0.17 * S, 0.27 * S, 0.14 * S, sub=2)
        orn_ball(B(m, shine, True), e + n2 * 0.1 * S + v2 * 0.1 * S - u2 * 0.05 * S, 0.065 * S, sub=1)
        b, d = onhead(sx * 0.7, -0.22, -0.04 * S)
        n2, u2, v2 = frame(d)
        ell(m, blush, b, u2, v2, n2, 0.17 * S, 0.1 * S, 0.08 * S, sub=1)
    if open_mouth:
        p, d = onhead(0, -0.3, -0.04 * S)
        n2, u2, v2 = frame(d)
        ell(m, mouth, p, u2, v2, n2, 0.2 * S, 0.15 * S, 0.1 * S, sub=1)
    else:
        P = [onhead(t * 0.26, -0.3 + 0.12 * t * t, 0.0)[0] for t in [i / 6 - 1 for i in range(13)]]
        tube(B(m, mouth, True), P, 0.055 * S, sides=5)
    for sx in (-1, 1):
        sh = c + v * 1.15 * S + u * sx * 0.95 * S
        if sx == wave_arm:
            tip = sh + (u * sx * 0.5 + v * 0.75 + nn * 0.15) * S
        else:
            tip = sh + (u * sx * 0.6 - v * 0.2 + nn * 0.25) * S
        orn_sweep(B(m, body, True), [sh - u * sx * 0.3 * S, sh + (tip - sh) * 0.5, tip], [0.34 * S, 0.29 * S, 0.24 * S],
                  sides=10)
        orn_ball(B(m, body, True), tip, 0.25 * S, sub=2)
    return hc


def wisp(m, c, r, d, glow='G:gturq14', tail='turq14', curl=0.6, L=None):
    """Feu follet : boule lumineuse et traînée turquoise qui s'effile en ondulant (d : direction de la traînée)."""
    c, d = Vector(c), Vector(d).normalized()
    L = L or r * 3.4
    sd = d.cross(UP)
    if sd.length < 1e-3:
        sd = d.orthogonal()
    sd.normalize()
    pts = [c + d * (r * 0.3 + L * t) + sd * curl * r * math.sin(t * math.pi * 1.5) for t in (0, 0.25, 0.5, 0.75, 1.0)]
    orn_sweep(B(m, tail, True), pts, [r * 0.82, r * 0.62, r * 0.42, r * 0.24, r * 0.06], sides=8)
    orn_ball(B(m, glow, True), c, r, sub=2)


def flame(m, c, fr, key='G:gflame14', up=UP):
    """Flamme en goutte (boule + pointe)."""
    up, c = Vector(up).normalized(), Vector(c)
    orn_ball(B(m, key, True), c, fr, sub=2)
    orn_cone(B(m, key, True), c, up, fr * 2.1, fr * 0.92, sides=12)


def candle(m, base, h, r, wax='cream14', drip='cream14', key='G:gflame14', holder=None, seed=0, up=UP, n_drips=3):
    """Bougie crème : cire qui coule (bourrelet en haut, coulures), mèche, flamme ; bougeoir de fer si holder."""
    up, base = Vector(up).normalized(), Vector(base)
    e1 = up.orthogonal().normalized()
    e2 = up.cross(e1).normalized()
    orn_cyl(B(m, wax, True), base - up * 0.3, up, h + 0.3, r, sides=14)
    top = base + up * h
    orn_torus(B(m, drip, True), top - up * 0.04, r * 0.9, r * 0.2, axis=up, seg=12, sides=5)
    rnd = random.Random(seed)
    for k in range(n_drips):
        a = k / n_drips * TAU + rnd.uniform(-0.4, 0.4)
        dd = e1 * math.cos(a) + e2 * math.sin(a)
        L = rnd.uniform(0.25, 0.55) * h
        rr = max(0.08, r * 0.2)
        capsule(m, drip, top + dd * r * 0.97 - up * 0.1, top + dd * r * 0.97 - up * L, rr, sides=6)
        orn_ball(B(m, drip, True), top + dd * r * 0.97 - up * (L + 0.04), rr * 1.3, sub=1)
    orn_cyl(B(m, 'ink14', False), top - up * 0.1, up, 0.12 + r * 0.45, max(0.05, r * 0.09), sides=5)
    fr = r * 0.46 + 0.08
    flame(m, top + up * (r * 0.42 + fr * 0.9), fr, key, up)
    if holder:
        orn_cyl(B(m, holder, False), base - up * 0.35, up, 0.3, r * 1.7, sides=16)
        orn_torus(B(m, holder, True), base - up * 0.05, r * 1.6, 0.08 + r * 0.06, axis=up, seg=24, sides=5)
    return top


def pumpkin_mesh(bm, c, R, up=UP, lobes=8, squash=0.8, sides=None, rings=10, phase=0.0, groove=0.14):
    """Citrouille à côtes : sphère aplatie creusée de lobes, petit creux autour de la tige (creux à l'angle phase)."""
    sides = sides or (32 if R > 1.3 else 24)
    rot = _orient(up)
    c = Vector(c)
    top = bm.verts.new(c + rot @ Vector((0, 0, R * squash * 0.78)))
    bot = bm.verts.new(c + rot @ Vector((0, 0, -R * squash * 0.86)))
    rows = []
    for i in range(1, rings):
        ph = math.pi * i / rings
        z = math.cos(ph) * R * squash
        rr = math.sin(ph) * R
        row = []
        for j in range(sides):
            az = j / sides * TAU + phase
            g = abs(math.sin(lobes * (az - phase) / 2))
            k = 1 - groove + groove * g ** 0.5
            row.append(bm.verts.new(c + rot @ Vector((rr * k * math.cos(az), rr * k * math.sin(az), z))))
        rows.append(row)
    n = sides
    for j in range(n):
        k = (j + 1) % n
        bm.faces.new((top, rows[0][j], rows[0][k]))
        bm.faces.new((bot, rows[-1][k], rows[-1][j]))
    for a, b in zip(rows, rows[1:]):
        for j in range(n):
            k = (j + 1) % n
            bm.faces.new((a[j], b[j], b[k], a[k]))


def half_disc(r, k=9, dy=0.0):
    return [(r * math.cos(math.pi * i / (k - 1)), r * math.sin(math.pi * i / (k - 1)) + dy) for i in range(k)]


def pumpkin(m, c, R, key='pump14', fwd=None, face=False, glow='G:gwin14', stem='stem14', leaf=None, lobes=8,
            squash=0.8, tendril=None):
    """Petite citrouille à côtes, tige courbée, feuille ; visage sculpté gentil qui brille (yeux en demi-lune, sourire)
    tourné vers fwd si face."""
    c = Vector(c)
    th = math.atan2(fwd[1], fwd[0]) if fwd is not None else 0.0
    pumpkin_mesh(B(m, key, True), c, R, lobes=lobes, squash=squash, phase=th)
    t0 = c + UP * R * squash * 0.6
    lean = Vector((math.cos(th + 2.2), math.sin(th + 2.2), 0))
    orn_sweep(B(m, stem, True), [t0, t0 + UP * R * 0.4, t0 + UP * R * 0.62 + lean * R * 0.22],
              [R * 0.17, R * 0.14, R * 0.11], sides=6)
    if leaf:
        d = (lean * -1 + UP * 0.1).normalized()
        feather(m, leaf, t0 + UP * R * 0.12 - lean * R * 0.1, d, UP, R * 1.05, R * 0.75, K=8, thick=0.1, bend=-0.25)
    if tendril:
        P = [t0 + UP * R * 0.25 + Vector((math.cos(th - 1.0 + a), math.sin(th - 1.0 + a), 0)) * R * (0.15 + 0.12 * a)
             + UP * R * 0.08 * a for a in [i * 0.35 for i in range(18)]]
        tube(B(m, tendril, True), P, max(0.04, R * 0.05), sides=5)
    if face:
        f = nrm_at(th)
        nn, u, v = frame(f)

        def onp(du, dv, lift):
            d = (f + u * du + v * dv).normalized()
            s = 1 / math.sqrt(d.x * d.x + d.y * d.y + (d.z / squash) ** 2)
            return c + d * (R * s + lift), d
        ea = math.tan(math.pi / lobes)
        for sx in (-1, 1):
            p, d = onp(sx * ea, 0.2, -0.04 * R)
            n2, u2, v2 = frame(d)
            plate(m, glow, half_disc(0.21 * R, dy=-0.08 * R), p, u2, v2, n2, 0.16 * R)
        T = [i / 8 * 2 - 1 for i in range(9)]
        C, Wd, Ns = [], [], []
        for t in T:
            w = 0.13 * R * max(0.0, 1 - t * t) ** 0.6 + 0.02
            p, d = onp(t * 0.48, -0.24 + 0.16 * t * t, -0.04 * R)
            C.append(p - UP * w * 0.6)
            Wd.append(w)
            Ns.append(d)
        ribbon(B(m, glow, False), C, Wd, [UP] * len(C), Ns, 0.16 * R)


def lantern(m, top, S, iron='ink14', iron2='iron14', fkey='G:gturq14', wax='cream14', ring=True, panes='turq14'):
    """Vieille lanterne de fer suspendue par son anneau à top : chapeau pointu carré, cadre à quatre montants,
    barreaux, socle, bougie et flamme turquoise ; vitres turquoise opaques (lueur douce, pas de Glass) sur le bas du
    cadre, la flamme dépasse au-dessus. Renvoie le bas."""
    t = Vector(top)
    if ring:
        orn_torus(B(m, iron, True), t - UP * 0.32 * S, 0.3 * S, 0.075 * S, axis=(1, 0, 0), seg=16, sides=5)
    apex = t - UP * 0.6 * S
    capb = apex - UP * 0.85 * S
    lathe(B(m, iron, False), capb, UP, [(1.08 * S, 0), (1.08 * S, 0.14 * S), (0.62 * S, 0.42 * S), (0.0, 0.85 * S)],
          sides=4, phase=math.pi / 4)
    orn_ball(B(m, iron, True), apex + UP * 0.02 * S, 0.13 * S, sub=1)
    fh = 1.8 * S
    lathe(B(m, iron2, False), capb - UP * 0.2 * S, UP, [(0.0, 0), (0.86 * S, 0), (0.86 * S, 0.2 * S), (0.0, 0.2 * S)],
          sides=4, phase=math.pi / 4)
    bot = capb - UP * fh
    lathe(B(m, iron, False), bot - UP * 0.24 * S, UP, [(0.0, 0), (0.98 * S, 0), (0.98 * S, 0.24 * S), (0.0, 0.24 * S)],
          sides=4, phase=math.pi / 4)
    corners = [Vector((math.cos(math.pi / 4 + k * math.pi / 2), math.sin(math.pi / 4 + k * math.pi / 2), 0)) * 0.8 * S
               for k in range(4)]
    for p in corners:
        orn_cyl(B(m, iron, False), bot + p, UP, fh, 0.085 * S, sides=6)
    for hz in (0.3, 0.72):
        for k in range(4):
            a, b = bot + corners[k] + UP * fh * hz, bot + corners[(k + 1) % 4] + UP * fh * hz
            tube(B(m, iron, True), [a, b], 0.05 * S, sides=5)
    if panes:
        for k in range(4):
            c0, c1 = corners[k], corners[(k + 1) % 4]
            mid = (c0 + c1) / 2
            box(m, panes, bot + mid + UP * fh * 0.36, (c1 - c0).normalized(), UP, mid.normalized(),
                (c1 - c0).length - 0.1 * S, fh * 0.7, 0.07 * S)
    orn_cyl(B(m, wax, True), bot, UP, 0.92 * S, 0.24 * S, sides=10)
    flame(m, bot + UP * (0.92 + 0.34) * S, 0.27 * S, fkey)
    orn_cone(B(m, iron, True), bot - UP * 0.2 * S, -UP, 0.35 * S, 0.22 * S, sides=6)
    return bot - UP * 0.55 * S


def cobweb(m, th, z, R, key='mist14', spokes=7, rings=3, r=0.07, lift=0.1, arc=None):
    """Toile d'araignée stylisée couchée sur la coquille : rayons et fils qui pendent un peu entre eux."""
    c = shell_pt(m, th, z, 0.2, 0.2)
    nn, u, v = frame(nrm_at(th))
    full = arc is None
    angs = [i / spokes * TAU for i in range(spokes)] if full else \
        [arc[0] + arc[1] * i / (spokes - 1) for i in range(spokes)]

    def P(a, rr):
        return surf_pt(m, c + (u * math.cos(a) + v * math.sin(a)) * rr, lift)
    for a in angs:
        tube(B(m, key, True), [P(a, R * i / 10) for i in range(11)], r, sides=5)
    for k in range(1, rings + 1):
        rr = R * k / (rings + 0.35)
        for i in range(len(angs) if full else len(angs) - 1):
            a0 = angs[i]
            a1 = angs[(i + 1) % len(angs)] + (TAU if full and i == len(angs) - 1 else 0)
            pts = [P(a0 + (a1 - a0) * f, rr * (1 - 0.16 * math.sin(math.pi * f))) for f in [j / 6 for j in range(7)]]
            tube(B(m, key, True), pts, r * 0.8, sides=5)
    orn_ball(B(m, key, True), P(0, 0), r * 2.2, sub=1)


def mist_puffs(m, n, keys=('mist14', 'mistd14'), r=(0.7, 1.1), zr=0.4, out=0.35):
    """Petits nuages de brume pâle au pied de l'œuf."""
    rnd = m.rnd
    a0 = rnd.uniform(0, TAU)
    for i in range(n):
        a = a0 + i / n * TAU + rnd.uniform(-0.2, 0.2)
        rr = rnd.uniform(*r)
        R0 = max(rs(m, a + d, zr + 0.5) for d in (-0.2, 0, 0.2)) + rr * 0.3 + out * rnd.random()
        c = pol(R0, a, -0.5 + rr * 0.72)
        orn_ball(B(m, keys[i % len(keys)], True), c, rr, scale=(1, 1, 0.72), sub=2)
        c2 = pol(R0 + rr * 0.15, a + rr * 0.9 / max(R0, 1), -0.5 + rr * 0.5)
        orn_ball(B(m, keys[(i + 1) % len(keys)], True), c2, rr * 0.7, scale=(1, 1, 0.72), sub=1)


def haunt_litter(m, kinds, zr=0.6, size=1.0):
    """Petites citrouilles, bougies et lanternes posées au pied de l'œuf."""
    rnd = m.rnd
    n = len(kinds)
    a0 = rnd.uniform(0, TAU)
    for i, kind in enumerate(kinds):
        a = a0 + i / n * TAU + rnd.uniform(-0.2, 0.2)
        base_r = max(rs(m, a + d, zr + dz) for d in (-0.3, 0, 0.3) for dz in (0, 0.8))
        if kind == 'pumpkin':
            R = rnd.uniform(0.75, 0.95) * size
            pumpkin(m, pol(base_r + R + 0.25, a, -0.5 + R * 0.8 * 0.86), R, fwd=nrm_at(a), face=(i % 2 == 0),
                    leaf='stem14')
        elif kind == 'candle':
            rr = 0.32 * size
            candle(m, pol(base_r + 0.75 * size, a, -0.15), rnd.uniform(1.0, 1.7) * size, rr, holder='iron14', seed=i)
        elif kind == 'lantern':
            S = 0.6 * size
            lantern(m, pol(base_r + 1.0 * size, a, -0.5 + 3.75 * S), S, ring=True)


def mist_wing(m, root, s, R, a_hi=60, a_lo=-24, n=8, mem='mist14', ray='mistd14', inner=('turq14', 'turqd14'),
              glow='G:gturq14', n_glow=3, thick=0.22, knob='mist14', knob_r=1.0):
    """Aile de brume en lambeaux : voile en éventail aux pointes inégales (longues et courtes en alternance), bouts
    arrondis en petites bouffées qui pendent en volutes, voile intérieure turquoise plus courte, feux follets au bout
    de quelques pointes."""
    root = Vector(root)
    rays = []
    for i in range(n):
        f = i / (n - 1)
        a = a_hi + (a_lo - a_hi) * f
        L = R * (0.8 + 0.2 * math.sin(math.pi * (0.25 + 0.75 * f))) * (0.84 if i % 2 else 1.0)
        rays.append((a, L))
    tips, P, nrm = fin(m, root, s, rays, mem, ray, None, thick=thick, notch=0.84, ray_r=0.09)
    for i, (a, L) in enumerate(rays):
        t = tips[i]
        d = (P(a, L) - P(a, L * 0.85)).normalized()
        orn_ball(B(m, mem, True), t, 0.42 if i % 2 == 0 else 0.34, scale=(1, 0.75, 1), sub=2)
    if inner:
        fin(m, root - nrm * 0.3, s, [(a, L * 0.6) for a, L in rays[::2]], inner[0], inner[1], None, notch=0.86,
            ray_r=0.09, thick=thick * 0.9)
        for a, L in rays[::2]:
            orn_ball(B(m, inner[0], True), P(a, L * 0.6) - nrm * 0.3, 0.3, scale=(1, 0.75, 1), sub=1)
    if glow and n_glow:
        for k in range(n_glow):
            i = int((k + 0.5) / n_glow * n)
            d = (P(rays[i][0], rays[i][1]) - P(rays[i][0], rays[i][1] * 0.85)).normalized()
            orn_ball(B(m, glow, True), tips[i] + d * 0.5 + UP * 0.25, 0.3, sub=1)
    if knob:
        orn_ball(B(m, knob, True), root + Vector((s * 0.3, -0.2, 0)), knob_r, sub=2)
    return tips, P, nrm


def full_moon(m, c, nrm, R, key='moon14', dark='moond14', rim='G:gturq14', rim2='turqd14', thick=0.8,
              craters=((-0.38, 0.28, 0.2), (0.3, -0.22, 0.26), (0.45, 0.42, 0.12), (-0.18, -0.52, 0.14),
                       (0.02, 0.12, 0.09), (-0.6, -0.1, 0.1))):
    """Pleine lune : disque crème épais, cratères en relief plus sombres, cercle lumineux turquoise autour."""
    nn, u, v = frame(nrm)
    c = Vector(c)
    # disque fait au tour (éventails de triangles) : le grand polygone de 48 côtés d'orn_cyl sortait invisible dans Studio
    lathe(B(m, key, False), c, nn, [(0.0, -thick / 2), (R, -thick / 2), (R, thick / 2), (0.0, thick / 2)], sides=48)
    for cx, cy, cr in craters:
        orn_cyl(B(m, dark, False), c + u * cx * R + v * cy * R + nn * (thick / 2 - 0.08), nn, 0.18, cr * R, sides=14)
        orn_cyl(B(m, dark, False), c - u * cx * R + v * cy * R - nn * (thick / 2 + 0.1), nn, 0.18, cr * R, sides=14)
    if rim:
        orn_torus(B(m, rim, True), c, R * 1.0, 0.2, axis=nn, seg=72, sides=6)
    if rim2:
        orn_torus(B(m, rim2, True), c - nn * 0.1, R * 1.1, 0.14, axis=nn, seg=72, sides=6)
    return nn, u, v


def top_curl(m, key, S=1.0, lift=0.0):
    """Petite mèche enroulée au sommet (comme le bout d'un drap de fantôme)."""
    tz = ztop(m, 0, 0) + lift
    pts = [Vector((0, 0, tz - 0.5)), Vector((0.05 * S, 0, tz + 0.45 * S)), Vector((0.45 * S, 0, tz + 1.05 * S)),
           Vector((1.0 * S, 0, tz + 0.95 * S)), Vector((1.05 * S, 0, tz + 0.5 * S)), Vector((0.75 * S, 0, tz + 0.4 * S))]
    orn_sweep(B(m, key, True), pts, [0.8 * S, 0.6 * S, 0.42 * S, 0.3 * S, 0.2 * S, 0.12 * S], sides=10)


def light_paint(m, c, r1, r2, key1='turq14', key2='turqd14', front=True):
    """Lumière portée sur la coquille autour du point c (projeté sur le plan xz si front) : key1 au centre, key2 autour."""
    for cc in m.surface():
        if cc not in m.body:
            continue
        x, y, z = cc
        if front and y > -1:
            continue
        d = math.hypot(x - c[0], z - c[2])
        if d < r1:
            m.cells[cc] = key1
        elif d < r2 or (d < r2 + 1.2 and (x + y + z) % 2 == 0):
            m.cells[cc] = key2


def shell_stars(m, n, test, key='cream14', r=(0.4, 0.6), mind=2.4):
    """Petites étoiles crème en relief posées sur les briques."""
    for i, (p, nrm, t1, t2, a) in enumerate(on_faces(m, n, test, mind, up=False)):
        rr = r[0] + (r[1] - r[0]) * abs(math.sin(a * 3))
        orn_star(B(m, key, False), p + nrm * 0.04, rr, rr * 0.45, 0.13, normal=nrm, spin=a)


def orbit_wisps(m, n, Ro, z, r=0.42, a0=0.0, dz=0.6, tilt=None):
    for i in range(n):
        a = a0 + i / n * TAU
        p = pol(Ro, a, z + dz * math.sin(i * 2.1))
        tg = Vector((math.sin(a), -math.cos(a), -0.15))
        wisp(m, p, r, tg)


# LES SIX ŒUFS --------------------------------------------------------------------------------

def build_T2(off):
    """Boo Egg : œuf blanc-brume, petit visage de fantôme souriant (grands yeux à reflets, joues roses), ourlet
    festonné bleu nuit au pied avec deux points turquoise lumineux, mèche enroulée au sommet, brume et petites
    citrouilles au pied."""
    W, H = SIZES[2]
    m = Vox(H, seed=1402)
    egg_body(m, W, H, 'mist14', 14021, bump=0.3)
    m.paint(lambda x, y, z: vnoise(x + 5, y, z, 23, 2.8) > 0.5, 'mistd14')
    hem_paint(m, 'night14', 3.3, n=7, amp=0.9, down=True)
    m.paint(lambda x, y, z: z <= 0.6, 'slate14')
    glow_dots(m, 'G:gturq14', 2, lambda x, y, z: 1 <= z <= 2 and m.cells[(x, y, z)] == 'night14' and y > 0, mind=4.0)
    shell_face(m, FRONT, 8.4, S=1.0)
    top_curl(m, 'mist14', 0.9)
    nest(m, ['slate14', 'night14', 'stemd14'], 10)
    mist_puffs(m, 5)
    haunt_litter(m, ['pumpkin', 'pumpkin'])
    return build(m, 'Egg_R14_T2', P14, off)


def build_T3(off):
    """Candle Egg : œuf ardoise couvert de cire crème qui coule du sommet, trois bougies aux petites flammes orange
    plantées dessus, anneau de fer riveté, petit fantôme souriant à l'avant, brume, bougies et citrouille au pied."""
    W, H = SIZES[3]
    m = Vox(H, seed=1403)
    egg_body(m, W, H, 'slate14', 14031, bump=0.4)
    m.paint(lambda x, y, z: vnoise(x, y, z, 31, 2.6) > 0.5, 'slatel14')
    m.paint(lambda x, y, z: vnoise(x + 9, y, z, 33, 2.6) < -0.55, 'slated14')
    hem_paint(m, 'night14', 1.6, n=6, amp=0.6)
    wax_paint(m, H - 4.6, n=7, seed=34, drip=(2.2, 5.2), tip='cream14')
    ro = ring_band(m, 'ink14', 4.3, 0.8, out=0.05, thick=0.24)
    for k in range(12):
        a = k / 12 * TAU + 0.13
        orn_ball(B(m, 'iron14', True), pol(ro(a) + 0.02, a, 4.3), 0.16, sub=1)
    ghost(m, shell_pt(m, FRONT, 8.0, 1.0, 1.2, lift=-0.35) - Vector((0, 0, 1.1)), (0, -1, 0), 0.95, hem=7)
    tz = ztop(m, 0, 0)
    for (x, y, h, r, s) in ((0, 0, 3.4, 0.85, 1), (1.7, -0.8, 2.4, 0.62, 2), (-1.6, 0.9, 1.9, 0.58, 3),
                            (0.7, 1.9, 1.4, 0.5, 4)):
        up = Vector((x * 0.07, y * 0.07, 1)).normalized()
        candle(m, (x, y, ztop(m, x, y) - 0.1), h, r, seed=s, up=up)
    nest(m, ['slate14', 'night14', 'stemd14'], 12)
    mist_puffs(m, 5)
    haunt_litter(m, ['candle', 'pumpkin', 'candle'])
    return build(m, 'Egg_R14_T3', P14, off)


def build_T4(off):
    """Lantern Egg : œuf bleu nuit étoilé, brume pâle au pied, vieille lanterne de fer accrochée à une potence à l'avant
    (cadre noir, flamme turquoise) qui éclaire doucement la coquille en turquoise, toile d'araignée au dos, feux
    follets en orbite."""
    W, H = SIZES[4]
    m = Vox(H, seed=1404)
    egg_body(m, W, H, 'night14', 14041, bump=0.3)
    m.paint(lambda x, y, z: vnoise(x + 3, y, z, 41, 3.0) > 0.42, 'nightl14')
    m.paint(lambda x, y, z: z >= H - 2.6 + wave(math.atan2(y, x), 5, 0.5), 'slate14')
    hem_paint(m, 'mist14', 2.4, n=7, amp=0.8)
    m.paint(lambda x, y, z: z <= 0.6, 'mistd14')
    # potence de fer et lanterne, assez loin de la coquille pour ne jamais la toucher
    S = 1.5
    za = 12.6
    zl = za + 0.32 * S - 0.15
    zbot = zl - 3.85 * S
    rh = max(rs(m, FRONT + da, z) for da in (-0.3, 0, 0.3) for z in range(int(zbot), int(zl) + 1)) + 1.0 * S + 0.35
    light_paint(m, (0, 0, zl - 2.7 * S), 1.3, 2.5)
    lz = zl - 2.7 * S
    shell_stars(m, 10, lambda x, y, z: 4 <= z <= H - 4 and m.cells[(x, y, z)] in ('night14', 'nightl14')
                and math.hypot(x, z - lz) > 4.0)
    r0 = rs(m, FRONT, za) - 0.3
    tube(B(m, 'ink14', True), dense([pol(r0, FRONT, za), pol(rh + 0.6, FRONT, za)], 0.3), 0.15, sides=6)
    orn_ball(B(m, 'ink14', True), pol(rh + 0.7, FRONT, za), 0.24, sub=1)
    sc = [pol(rs(m, FRONT, za - 2.2) - 0.2, FRONT, za - 2.2)]
    for k in range(9):
        f = k / 8
        sc.append(pol(r0 + 0.3 + (rh - r0 - 0.6) * f, FRONT, za - 2.0 + 2.0 * math.sin(f * math.pi / 2) - 0.1))
    tube(B(m, 'ink14', True), sc, 0.1, sides=5)
    box(m, 'iron14', pol(rs(m, FRONT, za - 1.0) + 0.05, FRONT, za - 1.0), Vector((1, 0, 0)), UP, Vector((0, -1, 0)),
        1.0, 3.0, 0.3)
    lantern(m, pol(rh, FRONT, zl), S)
    cobweb(m, math.pi / 2 + 0.4, H - 5.5, 2.8, spokes=7, rings=3)
    nest(m, ['slate14', 'night14', 'stemd14'], 12)
    mist_puffs(m, 6)
    haunt_litter(m, ['pumpkin', 'candle', 'pumpkin'])
    with layer(m, 'Orbit'):
        Ro = W / 2 + 4.8
        orbit_wisps(m, 6, Ro, 4.3, r=0.6, a0=0.3, dz=0.5)
        for i in range(6):
            a = 0.3 + (i + 0.5) / 6 * TAU
            orn_star(B(m, 'cream14', False), pol(Ro, a, 4.8 - 0.5 * math.sin(i * 1.7)), 0.6, 0.26, 0.16,
                     normal=(math.cos(a), math.sin(a), 0))
    return build(m, 'Egg_R14_T4', P14, off)


def pumpkin_body(m, W, H, key, seed, lobes=10, depth=0.075, bump=0.2, t0=0.4, phase=FRONT):
    """Œuf-citrouille en briques : profil d'œuf creusé de lobes (côtes), un lobe face à phase."""
    R = W / 2
    lim = (W - 1) // 2
    m.Hc, m.W = H, W
    for z in range(H):
        t = (z + 0.5) / (H + 0.8)
        r = egg_r(t, R, t0)
        for x in range(-lim, lim + 1):
            for y in range(-lim, lim + 1):
                d = math.hypot(x, y)
                th = math.atan2(y, x)
                lob = 1 - depth * (1 - abs(math.cos(lobes * (th - phase) / 2)))
                n = vnoise(x, y, z, seed) * bump
                if d <= r * lob - 0.45 + n or (x == 0 and y == 0):
                    m.put((x, y, z), key)
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


def carved_face(m, th, z, S=1.0, glow='G:gwin14', rim='pumpd14', tooth='pump14'):
    """Visage sculpté gentil qui brille : yeux en demi-lune, petit nez, large sourire avec deux dents ; bord creusé
    plus sombre autour de chaque ouverture."""
    R = max(rs(m, th, z), 1.0)
    for sx in (-1, 1):
        a = th + sx * 1.75 * S / R
        p = shell_pt(m, a, z + 1.5 * S, 1.0 * S, 0.8 * S)
        nn, u, v = frame(nrm_at(a))
        plate(m, rim, half_disc(1.08 * S, 11, -0.42 * S), p - nn * 0.12, u, v, nn, 0.75)
        plate(m, glow, half_disc(0.86 * S, 11, -0.32 * S), p + nn * 0.2, u, v, nn, 0.3)
    p = shell_pt(m, th, z + 0.1 * S, 0.5 * S, 0.4 * S)
    nn, u, v = frame(nrm_at(th))
    plate(m, rim, [(-0.5 * S, -0.35 * S), (0.5 * S, -0.35 * S), (0, 0.45 * S)], p - nn * 0.12, u, v, nn, 0.75)
    plate(m, glow, [(-0.34 * S, -0.24 * S), (0.34 * S, -0.24 * S), (0, 0.32 * S)], p + nn * 0.2, u, v, nn, 0.3)
    K = 16
    T = [-1 + 2 * i / K for i in range(K + 1)]
    A = [th + t * 2.7 * S / R for t in T]
    N = [nrm_at(a) for a in A]
    Wd = [0.62 * S * max(0.0, 1 - t * t) ** 0.55 + 0.06 for t in T]
    Zt = [z - 1.05 * S + 0.85 * S * t * t for t in T]
    Ci = shell_path(m, A, [zt - w for zt, w in zip(Zt, Wd)], lift=0.0)
    ribbon(B(m, rim, False), [c - n * 0.12 for c, n in zip(Ci, N)], [w + 0.2 * S for w in Wd], [UP] * len(Ci), N, 0.75)
    ribbon(B(m, glow, False), [c + n * 0.2 for c, n in zip(Ci, N)], Wd, [UP] * len(Ci), N, 0.3)
    for t in (-0.36, 0.36):
        i = int(round((t + 1) / 2 * K))
        nn, u, v = frame(N[i])
        box(m, tooth, Ci[i] + UP * (Wd[i] - 0.22 * S) + nn * 0.22, u, UP, nn, 0.55 * S, 0.5 * S, 0.42)


def build_T5(off):
    """Pumpkin Egg : œuf-citrouille orange à côtes, visage sculpté gentil qui brille, grosse tige verte, deux feuilles
    et une vrille au sommet, croissant de lune et étoile sculptés au dos, couronne de petites citrouilles sur une
    tige de vigne qui tourne, bougies et brume au pied."""
    W, H = SIZES[5]
    m = Vox(H, seed=1405)
    pumpkin_body(m, W, H, 'pump14', 14051, lobes=10)
    m.paint(lambda x, y, z: abs(math.cos(10 * (math.atan2(y, x) - FRONT) / 2)) < 0.3 and z > 0, 'pumpd14')
    m.paint(lambda x, y, z: abs(math.cos(10 * (math.atan2(y, x) - FRONT) / 2)) > 0.985 and 6 <= z <= H - 6, 'pumpl14')
    m.paint(lambda x, y, z: z <= 0.6, 'pumpd14')
    m.paint(lambda x, y, z: z >= H - 1.4, 'pumpd14')
    carved_face(m, FRONT, 10.4, S=1.25)
    nb = nrm_at(FRONT + math.pi)
    pc = shell_pt(m, FRONT + math.pi, 11.0, 1.6, 1.6, lift=0.1)
    crescent(m, 'G:gwin14', pc, 1.6, k=0.78, off=0.45, normal=nb, spin=0.6, thick=0.3, back='pumpd14')
    orn_star(B(m, 'G:gwin14', False), shell_pt(m, FRONT + math.pi - 0.3, 13.2, 0.5, 0.5, lift=0.1), 0.6, 0.27, 0.14,
             normal=nrm_at(FRONT + math.pi - 0.3))
    tz = ztop(m, 0, 0)
    st = [Vector((0, 0, tz - 0.8)), Vector((0, 0, tz + 0.6)), Vector((0.2, 0, tz + 1.7)), Vector((0.75, 0, tz + 2.35)),
          Vector((1.35, 0, tz + 2.45))]
    orn_sweep(B(m, 'stem14', True), st, [1.05, 0.95, 0.8, 0.66, 0.55], sides=12, profile=ribs(6, 0.14))
    orn_ball(B(m, 'stemd14', True), st[-1] + Vector((0.12, 0, 0)), 0.5, scale=(0.6, 1, 1), sub=2)
    for d, L, Wl in (((-0.9, -0.55, -0.5), 4.6, 3.0), ((0.35, 0.95, -0.5), 4.0, 2.6)):
        d = Vector(d).normalized()
        feather(m, 'stem14', Vector((0, 0, tz + 0.1)) + d * 0.6, d, UP, L, Wl, K=12, thick=0.2, bend=-0.22,
                rachis='stemd14')
    cc = Vector((-1.7, -0.3, tz + 1.5))
    P = [Vector((-0.45, -0.1, tz + 0.5)), Vector((-1.0, -0.25, tz + 0.75))]
    for i in range(34):
        f = i / 33
        a = -math.pi / 2 - f * 2.6 * math.pi
        rr = 0.95 * (1 - 0.8 * f)
        P.append(cc + Vector((-math.cos(a) * rr, -0.03 * i, math.sin(a) * rr)))
    tube(B(m, 'stemd14', True), P, 0.11, sides=6)
    nest(m, ['stem14', 'stemd14', 'night14'], 14)
    mist_puffs(m, 7)
    haunt_litter(m, ['candle', 'pumpkin', 'candle', 'candle'])
    with layer(m, 'Crown'):
        zc = H - 6.6
        Rc = rmax(m, zc) + 0.75
        orn_torus(B(m, 'stem14', True), (0, 0, zc), Rc, 0.34, seg=64, sides=8)
        orn_torus(B(m, 'stemd14', True), (0, 0, zc - 0.3), Rc * 0.99, 0.2, seg=56, sides=6)
        n = 6
        for i in range(n):
            a = i / n * TAU + FRONT
            pumpkin(m, pol(Rc, a, zc + 0.3 + 0.95 * 0.8 * 0.86), 0.95, fwd=nrm_at(a), face=True)
            ab = a + TAU / (2 * n)
            dd = Vector((math.cos(ab), math.sin(ab), 0.25)).normalized()
            feather(m, 'stem14', pol(Rc - 0.2, ab, zc + 0.15), dd, UP, 1.6, 1.05, K=8, thick=0.12, rachis='stemd14',
                    bend=-0.2)
    return build(m, 'Egg_R14_T5', P14, off)


def _wing_zone(zr, half=4.2):
    return lambda a, z: abs(math.cos(a)) > 0.75 and zr - half < z < zr + half


def build_T6(off):
    """Wisp Egg : œuf bleu nuit enveloppé de volutes de brume pâle et turquoise (bandes en spirale sur les briques,
    volutes lisses avec des perles lumineuses), sommet violet coiffé d'un croissant de lune et d'une étoile, fantôme
    souriant qui sort de la coquille à l'avant, toile au dos, ailes de brume en lambeaux, feux follets et petits
    fantômes en orbite."""
    W, H = SIZES[6]
    m = Vox(H, seed=1406)
    egg_body(m, W, H, 'night14', 14061, bump=0.3)
    m.paint(lambda x, y, z: vnoise(x + 3, y, z, 61, 3.0) > 0.4, 'nightl14')

    def sw(x, y, z):
        return (2 * math.atan2(y, x) / TAU + z / 11.0) % 1.0
    m.paint(lambda x, y, z: sw(x, y, z) < 0.1, 'turqd14')
    m.paint(lambda x, y, z: 0.1 <= sw(x, y, z) < 0.15, 'turq14')
    m.paint(lambda x, y, z: z >= H - 3.2 + wave(math.atan2(y, x), 6, 0.6), 'violet14')
    m.paint(lambda x, y, z: z >= H - 1.6, 'violetd14')
    hem_paint(m, 'mist14', 2.6, n=8, amp=0.8)
    m.paint(lambda x, y, z: z <= 0.6, 'mistd14')
    zw = 15.5
    wz = _wing_zone(zw, 4.6)
    gz = lambda a, z: abs((a - FRONT + math.pi) % TAU - math.pi) < 0.55 and 7.5 < z < 15.5
    avoid = lambda a, z: wz(a, z) or gz(a, z)
    filament(m, 'mist14', 0.4, 2.6, H - 4.5, 1.15, lift=0.3, r=0.7, wob=1.0, seed=61, nodes='G:gturq14',
             node_r=0.42, n_nodes=3, avoid=avoid)
    filament(m, 'turq14', 2.6, 3.2, H - 5.5, 1.0, lift=0.25, r=0.48, wob=0.9, seed=62, avoid=avoid)
    gp = shell_pt(m, FRONT, 10.5, 1.6, 1.5, lift=-0.2)
    ghost(m, gp - Vector((0, 0, 1.6)), (0, -1, 0), 1.55, hem=8)
    tz = ztop(m, 0, 0)
    crescent(m, 'moon14', (0, 0.2, tz + 2.15), 2.5, k=0.78, off=0.45, normal=(0, -1, 0), spin=0.55, thick=0.7,
             back='moond14', craters=((-0.55, -0.1, 0.12), (-0.3, -0.55, 0.1)))
    orn_star(B(m, 'cream14', False), (1.6, 0.0, tz + 4.3), 0.6, 0.26, 0.16, normal=(0, -1, 0))
    cobweb(m, math.pi / 2, 9.5, 3.2, spokes=8, rings=3)
    nest(m, ['slate14', 'night14', 'stemd14'], 16)
    mist_puffs(m, 8)
    haunt_litter(m, ['pumpkin', 'candle', 'pumpkin', 'candle'])
    for s, g in ((1, 'WingR'), (-1, 'WingL')):
        with layer(m, g):
            r = rs(m, 0 if s > 0 else math.pi, zw) - 0.9
            mist_wing(m, (s * r, 0.4, zw), s, 9.2, a_hi=60, a_lo=-24, n=8, n_glow=3)
    with layer(m, 'Orbit'):
        Ro = W / 2 + 4.6
        orbit_wisps(m, 5, Ro, 5.4, r=0.6, a0=0.2, dz=0.6)
        for i in range(3):
            a = 0.2 + (i * 5 / 3 + 0.5) / 5 * TAU
            ghost(m, pol(Ro, a, 3.6), (math.cos(a), math.sin(a), 0), 0.85, hem=6, wave_arm=1 if i % 2 else -1)
    return build(m, 'Egg_R14_T6', P14, off)


def build_T7(off):
    """Phantom Egg : grand œuf-fantôme blanc-brume au bas turquoise festonné, grand visage souriant (yeux à reflets,
    joues roses, bouche ouverte et langue), manoir hanté miniature au sommet (murs d'ardoise, toits violets, tour
    pointue, cheminée qui fume, fenêtres lumineuses, lanternes aux coins), grande pleine lune derrière, petit fantôme
    qui salue, couronne de bougies, halo de feux follets, grandes ailes de brume, anneau de lanternes, citrouilles et
    feux follets en orbite."""
    W, H = SIZES[7]
    m = Vox(H, seed=1407)
    egg_body(m, W, H, 'mist14', 14071, bump=0.3)
    zcut = H - 6
    for c in list(m.cells):
        if c[2] > zcut:
            del m.cells[c]
    m.body = set(m.cells)
    m.paint(lambda x, y, z: vnoise(x + 7, y, z, 71, 3.2) > 0.5, 'mistd14')
    hem_paint(m, 'turq14', 5.4, n=8, amp=1.1)
    hem_paint(m, 'turqd14', 2.8, n=8, amp=0.9, phase=0.5)
    m.paint(lambda x, y, z: z <= 0.6, 'night14')
    m.paint(lambda x, y, z: z == zcut, 'slate14')
    m.paint(lambda x, y, z: z == zcut and vnoise(x, y, 0, 72, 2.0) > 0.3, 'stemd14')
    # manoir hanté
    z0 = zcut + 1

    def put(x, y, z, k):
        m.put((x, y, z), k)
    for x in range(-3, 4):
        for y in range(-2, 3):
            for z in range(z0, z0 + 4):
                k = 'slated14' if (abs(x) == 3 and abs(y) == 2) else 'slate14'
                if z == z0 + 3 and (abs(x) == 3 or abs(y) == 2):
                    k = 'night14'
                put(x, y, z, k)
    for k in range(4):
        for x in range(-4, 5):
            for y in range(-3 + k, 4 - k):
                put(x, y, z0 + 4 + k, 'violet14' if abs(y) == 3 - k else 'violetd14')
    for x in range(-4, 5):
        put(x, 0, z0 + 7, 'night14')
    for z in (z0 + 1, z0 + 2):
        for x in (-2, 2):
            put(x, -2, z, 'G:gwin14')
        put(3, 0, z, 'G:gwin14')
        for x in (-1, 1):
            put(x, 2, z, 'G:gwin14')
    put(0, -2, z0, 'violetd14')
    put(0, -2, z0 + 1, 'violetd14')
    put(0, -2, z0 + 2, 'G:gturq14')
    put(0, -2, z0 + 5, 'G:gwin14')
    for x in (-5, -4, -3):
        for y in (-1, 0, 1):
            for z in range(z0, z0 + 9):
                k = 'slated14' if (x != -4 and y != 0) else 'slate14'
                if z == z0 + 8:
                    k = 'night14' if (x + y) % 2 else 'slated14'
                put(x, y, z, k)
    for z in (z0 + 5, z0 + 6):
        put(-4, -1, z, 'G:gwin14')
        put(-5, 0, z, 'G:gwin14')
    put(-4, 1, z0 + 6, 'G:gwin14')
    for z in range(z0 + 5, z0 + 9):
        put(2, 1, z, 'slated14')
    put(2, 1, z0 + 9, 'night14')
    m.body = set(m.cells)
    m.Hc = H + 16
    orn_cone(B(m, 'violet14', False), (-4, 0, z0 + 8.5), (0, 0, 1), 3.6, 2.3, sides=8)
    orn_torus(B(m, 'violetd14', True), (-4, 0, z0 + 8.6), 2.15, 0.22, seg=24, sides=6)
    orn_ball(B(m, 'G:gturq14', True), (-4, 0, z0 + 12.2), 0.3, sub=1)
    for p, rr in (((2.0, 1.0, z0 + 10.2), 0.5), ((2.5, 1.3, z0 + 11.1), 0.62), ((3.2, 1.5, z0 + 11.9), 0.75)):
        orn_ball(B(m, 'mist14', True), p, rr, sub=2)
    for sx in (-1, 1):
        lantern(m, (sx * 3.2, -4.1, z0 + 3.0), 0.5)
        tube(B(m, 'ink14', True), dense([Vector((sx * 3.2, -2.4, z0 + 2.9)), Vector((sx * 3.2, -4.35, z0 + 2.9))], 0.3),
             0.08, sides=5)
        orn_ball(B(m, 'ink14', True), Vector((sx * 3.2, -4.4, z0 + 2.9)), 0.13, sub=1)
    ghost(m, (0.0, -0.25, z0 + 7.35), (0, -1, 0), 0.6, hem=6, wave_arm=1)
    # grande lune derrière, tenue par un support d'ardoise
    mc = Vector((0, 4.6, 31.4))
    full_moon(m, mc, (0, -1, 0), 6.0, thick=0.8)
    tube(B(m, 'slated14', True), dense([Vector((0, 5.25, zcut + 0.1)), Vector((0, 5.25, 28.0))], 0.4), 0.33, sides=8)
    # grand visage de fantôme
    shell_face(m, FRONT, 14.0, S=2.0, open_mouth=True, tongue='tongue14')
    zw = 17.0
    wz = _wing_zone(zw, 5.5)
    gz = lambda a, z: abs((a - FRONT + math.pi) % TAU - math.pi) < 0.75
    filament(m, 'turq14', 0.9, 5.5, 20.0, 1.1, lift=0.3, r=0.55, wob=1.0, seed=71, nodes='G:gturq14', node_r=0.45,
             n_nodes=2, avoid=lambda a, z: wz(a, z) or gz(a, z))
    filament(m, 'mist14', 2.3, 6.5, 19.0, -0.9, lift=0.3, r=0.7, wob=0.9, seed=72,
             avoid=lambda a, z: wz(a, z) or gz(a, z))
    cobweb(m, math.pi / 2 + 0.9, 19.0, 3.4, spokes=8, rings=3)
    nest(m, ['slate14', 'night14', 'stemd14'], 16)
    mist_puffs(m, 9, r=(1.0, 1.5))
    haunt_litter(m, ['pumpkin', 'candle', 'lantern', 'pumpkin', 'candle', 'pumpkin', 'candle'], size=1.15)
    for s, g in ((1, 'WingR'), (-1, 'WingL')):
        with layer(m, g):
            r = rs(m, 0 if s > 0 else math.pi, zw) - 1.0
            mist_wing(m, (s * r, 0.5, zw), s, 13.5, a_hi=62, a_lo=-14, n=10, n_glow=4, thick=0.26, knob_r=1.3)
    with layer(m, 'Crown'):
        zc = zcut + 0.25
        Rc = max(rmax(m, zcut), 5.6) + 0.75
        orn_torus(B(m, 'ink14', True), (0, 0, zc), Rc, 0.3, seg=72, sides=8)
        orn_torus(B(m, 'iron14', True), (0, 0, zc - 0.28), Rc * 0.99, 0.18, seg=64, sides=6)
        for i in range(10):
            a = i / 10 * TAU + TAU / 20
            candle(m, pol(Rc, a, zc + 0.2), 0.7 + 0.25 * (i % 2), 0.3, seed=i, n_drips=2)
    with layer(m, 'Halo'):
        zh, Rh = 38.4, 6.5
        orn_torus(B(m, 'mist14', True), (0, 0, zh), Rh, 0.22, seg=72, sides=8)
        for i in range(10):
            a = i / 10 * TAU
            p = pol(Rh, a, zh + 0.35)
            if i % 2 == 0:
                wisp(m, p, 0.46, Vector((math.sin(a), -math.cos(a), -0.2)))
            else:
                orn_star(B(m, 'cream14', False), p + Vector((0, 0, 0.2)), 0.55, 0.24, 0.14,
                         normal=(math.cos(a), math.sin(a), 0))
    with layer(m, 'Orbit'):
        Ro, zo, tl = 16.8, 5.6, 0.08
        rot = orn_torus(B(m, 'turqd14', True), (0, 0, zo), Ro, 0.26, tilt=tl, seg=96, sides=8)
        for i in range(6):
            a = i / 6 * TAU
            p = Vector((0, 0, zo)) + rot @ Vector((Ro * math.cos(a), Ro * math.sin(a), 0))
            if i % 2 == 0:
                lantern(m, p + UP * 0.3 * 1.25, 1.25)
            else:
                pumpkin(m, p + UP * (0.2 + 1.5 * 0.8 * 0.86), 1.5, fwd=nrm_at(a), face=True, leaf='stem14')
            b = a + TAU / 12
            q = Vector((0, 0, zo)) + rot @ Vector((Ro * math.cos(b), Ro * math.sin(b), 0))
            wisp(m, q + UP * 1.4, 0.65, Vector((math.sin(b), -math.cos(b), -0.2)))
    return build(m, 'Egg_R14_T7', P14, off)


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
    drop('Egg_R14_T%d' % n)
    random.seed(1400 + n)
    coll = BUILDERS[n]((OFFSETS[n], 0, 0))
    obs = [o for o in coll.objects if o.type == 'MESH']
    for o in list(obs):
        if not len(o.data.vertices):
            bpy.data.objects.remove(o, do_unlink=True)
    obs = [o for o in coll.objects if o.type == 'MESH']
    tris = sum(len(p.vertices) - 2 for o in obs for p in o.data.polygons)
    zs = [(o.matrix_world @ v.co).z for o in obs for v in o.data.vertices]
    xs = [(o.matrix_world @ v.co).x for o in obs for v in o.data.vertices]
    print('Egg_R14_T%d : %d objets, %d triangles, x %.1f..%.1f, z %.2f..%.2f, max tris/objet %d' % (
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
    colls = [bpy.data.collections.get('Egg_R14_T%d' % n) for n in sorted(BUILDERS)]
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


print("eggs_r14 chargé")
