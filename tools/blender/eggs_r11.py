# Œufs de l'anneau 11 « Candy Comet » (comète de bonbons : sucre d'orge rayé, guimauve, vermicelles, glaçage qui
# coule, sucettes en spirale, chocolat, bonbons gélifiés), même méthode que les anneaux 1 à 10 :
# corps en briques (voxkit.Vox) + ornements lisses (_ORN_), groupes animés (_ACrown_, _AOrbit_, _AHalo_, _AWingL_,
# _AWingR_). Charger voxkit.py avant ce fichier, puis build_all() ou build_one(n).
# clash(coll) vérifie qu'un groupe qui tourne ne traverse ni les ailes qui battent ni les ornements fixes ;
# neon_share(coll) donne la part de surface en néon (à garder sous 5 %).
# Les clés de couleur lumineuses commencent par « g » (gpink11...) : neon_share les reconnaît ainsi.

TAU = math.tau

P11 = dict(
    pink11='#FF8CC8', pinkl11='#FFC4E1', pinkd11='#E2589F', pinkx11='#B23A7A',
    mint11='#8CEBDC', mintd11='#3FBFA8', mintx11='#2A8F7E',
    lemon11='#FFE66B', lemond11='#E8B42E',
    cream11='#FFF6EC', creamd11='#F0D9C0',
    choc11='#6B3A26', chocd11='#4A2618', milk11='#A0623C', milkl11='#C8874E',
    cherry11='#E8344E', cherryd11='#B01E36', cherryl11='#FF6E80',
    plum11='#9B6BE0', plumd11='#6E44B0', plumx11='#4A2C80',
    blue11='#7FD0FF', blued11='#4FA8E0',
    wafer11='#E8B86A', waferd11='#C08A42', leaf11='#4E9A3C',
    gemp11='#FF4FA8', gemm11='#2FE0C0', geml11='#FFD23A', gemb11='#5AB8FF',
    gpink11='#FF9AD2', gmint11='#9CF5E6', glemon11='#FFF09A', gcream11='#FFF8F0', gplum11='#C9A2FF',
)

OFFSETS = {2: 0, 3: 34, 4: 70, 5: 112, 6: 162, 7: 222}
SIZES = {2: (11, 15), 3: (11, 17), 4: (13, 19), 5: (15, 22), 6: (17, 25), 7: (21, 29)}

SPR = ('cherry11', 'lemon11', 'mintd11', 'blue11', 'plum11', 'cream11')


# BRUIT ET PROFIL (comme les anneaux 8 à 10) --------------------------------------------------

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


# BONBONS ET PÂTISSERIE -----------------------------------------------------------------------

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


def sprinkles(m, n, test, keys=SPR, L=0.8, r=0.15, mind=0.95, up=True):
    """Vermicelles colorés couchés sur les faces des briques."""
    pl = on_faces(m, n, test, mind, up=up)
    for i, (p, nrm, t1, t2, a) in enumerate(pl):
        d = t1 * math.cos(a) + t2 * math.sin(a)
        c = p + nrm * r * 0.75
        capsule(m, keys[i % len(keys)], c - d * L / 2, c + d * L / 2, r)
    return pl


def sugar(m, n, test, key='cream11', r=0.2, mind=0.8):
    """Cristaux de sucre (petits icosaèdres facettés) posés sur les briques."""
    for p, nrm, t1, t2, a in on_faces(m, n, test, mind):
        orn_ball(B(m, key, False), p + nrm * r * 0.5, r * (0.8 + 0.4 * abs(math.sin(a * 3))), sub=0)


def stars(m, n, test, keys=('lemon11', 'cream11'), r=0.6, mind=2.2):
    """Étoiles de sucre collées sur les flancs."""
    for i, (p, nrm, t1, t2, a) in enumerate(on_faces(m, n, test, mind, up=False)):
        orn_star(B(m, keys[i % len(keys)], False), p + nrm * 0.1, r, r * 0.45, 0.2, normal=nrm, spin=a)


def icing(m, key, z0, n, Lr=(1.2, 3.2), seed=0, w=1.1, amp=0.35, drops=True, br=0.62, a0=0.0, drop_key=None,
          avoid=(), gap=0.5):
    """Glaçage qui coule : tout ce qui est au-dessus du bord (ondulé, avec n coulures arrondies) prend la couleur key.
    Une goutte lisse au bout de chaque coulure (aucune coulure à moins de gap des angles avoid, ex. racines d'ailes).
    Renvoie [(angle, z du bout)]."""
    rnd = random.Random(seed)
    D = []
    for i in range(n):
        a = a0 + (i + rnd.uniform(-0.28, 0.28)) / n * TAU
        L = rnd.uniform(*Lr)
        if any(abs((a - b + math.pi) % TAU - math.pi) < gap for b in avoid):
            continue
        D.append((a, L))

    def edge(th, r):
        e = z0 + amp * math.sin(th * (n + 1) + seed)
        for a, L in D:
            da = (th - a + math.pi) % TAU - math.pi
            x = abs(da) * max(r, 1.0)
            if x < w:
                e = min(e, z0 - L * math.sqrt(1 - (x / w) ** 2))
        return e

    m.paint(lambda x, y, z: z >= edge(math.atan2(y, x), math.hypot(x, y)) - 0.01, key)
    ends = []
    for a, L in D:
        ze = z0 - L + 0.15
        if drops:
            orn_ball(B(m, drop_key or key, True), pol(rs(m, a, ze) - br * 0.2, a, ze), br, sub=2)
        ends.append((a, ze))
    return ends


def drizzle(m, key, zf, r=0.26, n=96, lift=0.05):
    """Filet de glaçage lisse qui fait le tour de la coquille à la hauteur zf(angle)."""
    A = [i / n * TAU for i in range(n)]
    raw = [max(rs(m, a, zf(a) + dz) for dz in (-0.5, 0, 0.5)) for a in A]
    env = [max(raw[(i + k) % n] for k in (-2, -1, 0, 1, 2)) for i in range(n)]
    P = [pol(env[i] + r * 0.3 + lift, A[i], zf(A[i])) for i in range(n)]
    tube(B(m, key, True), P + [P[0]], r, sides=6)


def cane_belt(m, z, r, white='cream11', red='cherry11', n=72):
    """Ceinture de sucre d'orge qui épouse la coquille à la hauteur z : boudin blanc et rayure rouge en hélice."""
    A = [i / n * TAU for i in range(n)]
    raw = [max(rs(m, a, z + dz) for dz in (-r * 0.8, 0, r * 0.8)) for a in A]
    env = [max(raw[(i + k) % n] for k in (-2, -1, 0, 1, 2)) for i in range(n)]
    sm = [max(env[i] - 0.25, sum(env[(i + k) % n] for k in range(-3, 4)) / 7) for i in range(n)]
    P = [pol(sm[i] + r * 0.55, A[i], z) for i in range(n)]
    P = dense(P + [P[0]], 0.22)
    tube(B(m, white, True), P, r, sides=10, ref=(0, 0, 1))
    tube(B(m, red, True), helix_along(P, r * 0.84, r * 3.6, (0, 0, 1)), r * 0.36, sides=6, ref=(0, 0, 1))
    return P


def swirl_paint(m, cols, k=2, pitch=8.0, test=None, phase=0.0):
    """Spirale de sucette : bandes de couleur qui tournent en montant."""
    n = len(cols)
    for c in m.surface():
        x, y, z = c
        if test and not test(*c):
            continue
        th = math.atan2(y, x)
        f = th / TAU * k + z / pitch + phase
        m.cells[c] = cols[int(math.floor(f * n)) % n]


def cane(m, base, d, L, hook, side, r=0.34, white='cream11', red='cherry11', pitch=None, hook_a=1.0, stripes=1):
    """Sucre d'orge : canne blanche (tige + crosse vers side), rayure en hélice."""
    base, d = Vector(base), Vector(d).normalized()
    side = Vector(side)
    side = (side - d * side.dot(d)).normalized()
    top = base + d * L
    ctr = top + side * hook
    pts = [base, base + d * L * 0.5, top]
    for i in range(1, 11):
        a = i / 10 * math.pi * hook_a
        pts.append(ctr - side * hook * math.cos(a) + d * hook * math.sin(a))
    P = dense(pts, 0.12)
    tube(B(m, white, True), P, r, sides=10, ref=side)
    ref = side.cross(d)
    pitch = pitch or r * 3.4
    for k in range(stripes):
        H = helix_along(P[1:-1], r * 0.84, pitch, ref, phase=k * TAU / stripes)
        tube(B(m, red, True), H, r * 0.36, sides=6, ref=ref)
    return P


def cane_ring(m, c, R, r, white='cream11', red='cherry11', axis=None, tilt=0.0, k=None, seg=72):
    """Anneau de sucre d'orge : tore blanc + rayure en hélice tout autour."""
    rot = orn_torus(B(m, white, True), c, R, r, tilt=tilt, seg=seg, sides=10, axis=axis)
    k = k or max(6, int(TAU * R / (r * 3.6)))
    N = k * 12
    pts = []
    for i in range(N + 1):
        a = i / N * TAU
        ph = k * a
        radial = Vector((math.cos(a), math.sin(a), 0))
        p = radial * R + (radial * math.cos(ph) + Vector((0, 0, 1)) * math.sin(ph)) * r * 0.84
        pts.append(Vector(c) + rot @ p)
    tube(B(m, red, True), pts, r * 0.36, sides=6)
    return rot


def lolly(m, c, nrm, R, cols=('pink11',), base='cream11', turns=2.2, thick=0.5, both=True, rim=None, gem=None,
          stick=None, stick_dir=None, stick_L=0.0, stick_r=None):
    """Sucette ronde : disque, spirale(s) en relief sur les deux faces, cerclage, gemme au centre, bâton."""
    c = Vector(c)
    n, u, v = frame(nrm)
    orn_cyl(B(m, base, False), c - n * thick / 2, n, thick, R, sides=40)
    k = len(cols)
    tr = R / (turns * k) * 0.36
    for j, col in enumerate(cols):
        for f in ((1, -1) if both else (1,)):
            pts = []
            N = int(turns * 30)
            for i in range(N + 1):
                q = i / N
                rr = R * 0.12 + (R - tr * 1.3 - R * 0.12) * q
                a = q * turns * TAU + j / k * TAU
                pts.append(c + n * f * thick * 0.5 + (u * math.cos(a) * f + v * math.sin(a)) * rr)
            tube(B(m, col, True), pts, tr, sides=7)
    if rim:
        orn_torus(B(m, rim, True), c, R, thick * 0.5, axis=n, seg=40, sides=8)
    if gem:
        orn_gem(B(m, gem, False), c + n * thick * 0.5, R * 0.2, direction=n)
        if both:
            orn_gem(B(m, gem, False), c - n * thick * 0.5, R * 0.2, direction=-n)
    if stick:
        sd = Vector(stick_dir).normalized()
        sr = stick_r or max(0.18, R * 0.12)
        orn_cyl(B(m, stick, False), c + sd * R * 0.5, sd, R * 0.5 + stick_L, sr, sides=10)
    return n, u, v


def bonbon(m, key, c, axis, r, wrap=None, stripe=None):
    """Bonbon enveloppé : boule, deux papillotes plissées, rayures."""
    c, a = Vector(c), Vector(axis).normalized()
    orn_ball(B(m, key, True), c, r, sub=2)
    w = wrap or key
    for s in (1, -1):
        orn_cyl(B(m, w, False), c + a * s * r * 0.72, a * s, r * 0.3, r * 0.34, r * 0.22, sides=8)
        orn_cyl(B(m, w, False), c + a * s * r * 1.0, a * s, r * 0.72, r * 0.22, r * 0.82, sides=8)
    if stripe:
        for o in (-0.42, 0.42):
            rr = r * math.sqrt(1 - o * o)
            orn_torus(B(m, stripe, True), c + a * o * r, rr, r * 0.13, axis=a, seg=24, sides=6)


def gumdrop(m, key, base, up, r, sugar_key='cream11', n=7, seed=0):
    """Bonbon gélifié en dôme, saupoudré de sucre."""
    base, up = Vector(base), Vector(up).normalized()
    h = r * 0.75
    orn_cyl(B(m, key, False), base, up, h, r, r * 0.84, sides=16)
    top = base + up * h
    orn_ball(B(m, key, True), top, r * 0.84, sub=2)
    rnd = random.Random(seed)
    rot = _orient(up)
    for i in range(n):
        a = i / n * TAU + rnd.uniform(-0.3, 0.3)
        el = rnd.uniform(0.25, 1.3)
        d = rot @ Vector((math.cos(a) * math.cos(el), math.sin(a) * math.cos(el), math.sin(el)))
        orn_ball(B(m, sugar_key, False), top + d * r * 0.84, r * 0.12, sub=0)


def whip(m, key, base, R, h, turns=2.6, tube_r=None, up=(0, 0, 1)):
    """Chantilly / meringue : boudin cannelé en spirale qui se resserre, pointe au sommet."""
    base, up = Vector(base), Vector(up).normalized()
    rot = _orient(up)
    tr = tube_r or R * 0.45
    N = int(turns * 14)
    pts, rad = [], []
    for i in range(N + 1):
        f = i / N
        a = f * turns * TAU
        rr = R * (1 - f * 0.88)
        pts.append(base + rot @ Vector((rr * math.cos(a), rr * math.sin(a), h * f)))
        rad.append(tr * (1 - 0.5 * f))
    tube(B(m, key, True), pts, rad, sides=12, profile=ribs(6, 0.2))
    orn_cone(B(m, key, True), base + up * (h - tr * 0.2), up, tr * 1.6, tr * 0.55, sides=12)
    return base + up * (h + tr * 1.3)


def cherry(m, c, r, stem_dir=(0.35, 0.1, 1.0)):
    """Cerise confite : boule, reflet, queue."""
    c = Vector(c)
    orn_ball(B(m, 'cherry11', True), c, r, sub=3)
    orn_ball(B(m, 'cherryl11', True), c + Vector((-0.35, -0.5, 0.42)).normalized() * r * 0.78, r * 0.26, sub=2)
    sd = Vector(stem_dir).normalized()
    p0 = c + Vector((0, 0, r * 0.8))
    tube(B(m, 'leaf11', True), dense([p0, p0 + sd * r * 0.9, p0 + sd * r * 1.6 + Vector((r * 0.4, 0, -r * 0.1))], 0.1),
         r * 0.12, sides=6)


def roll(m, base, d, L, r, key='wafer11', stripe='choc11'):
    """Gaufrette roulée (pirouline) : cylindre et spirale de chocolat."""
    base, d = Vector(base), Vector(d).normalized()
    orn_cyl(B(m, key, False), base, d, L, r, sides=14)
    P = dense([base + d * 0.1, base + d * (L - 0.1)], 0.1)
    tube(B(m, stripe, True), helix_along(P, r * 0.9, r * 3.0, d.orthogonal()), r * 0.28, sides=6)
    orn_cyl(B(m, stripe, False), base + d * (L - 0.05), d, 0.12, r * 0.75, sides=14)


def truffle(m, key, c, r, drizzle='cream11', spr=True, seed=0):
    """Truffe en chocolat : boule, filets de glaçage, quelques vermicelles."""
    c = Vector(c)
    orn_ball(B(m, key, True), c, r, sub=2)
    for i, z in enumerate((0.45, 0.1)):
        rr = r * math.sqrt(1 - z * z)
        orn_torus(B(m, drizzle, True), c + Vector((0, 0, z * r)), rr, r * 0.1, tilt=0.25 * (1 if i else -1), seg=24,
                  sides=5)
    if spr:
        rnd = random.Random(seed)
        for i in range(5):
            a, el = rnd.uniform(0, TAU), rnd.uniform(0.7, 1.3)
            nn = Vector((math.cos(a) * math.cos(el), math.sin(a) * math.cos(el), math.sin(el)))
            t = nn.cross(Vector((0, 0, 1))).normalized()
            p = c + nn * (r + 0.05)
            capsule(m, SPR[i % len(SPR)], p - t * r * 0.22, p + t * r * 0.22, r * 0.08, sides=6)


def dragee(m, key, c, r):
    """Dragée : amande sucrée lisse, un peu aplatie."""
    orn_ball(B(m, key, True), c, r, scale=(1.25, 1.0, 0.82), sub=2)


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


# REPRIS DES ANNEAUX 8 À 10 -------------------------------------------------------------------

def nest(m, keys, n, zlo=-0.55, zhi=2.0, tube=(0.32, 0.48), off=(0.15, 0.75)):
    """Nid de bonbons-serpents enroulés autour de la base (comme les autres anneaux)."""
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


def candy_litter(m, n, keys, kinds=('gum', 'bon'), Rr=(0.85, 1.2)):
    """Petits bonbons posés au pied de l'œuf (à la place des rouages de l'anneau 10)."""
    rnd = m.rnd
    a0 = rnd.uniform(0, TAU)
    for i in range(n):
        a = a0 + i / n * TAU + rnd.uniform(-0.25, 0.25)
        Rg = rnd.uniform(*Rr)
        r = rss(m, a, 2.2) + Rg * 0.85 + 0.35
        key = keys[i % len(keys)]
        kind = kinds[i % len(kinds)]
        if kind == 'gum':
            gumdrop(m, key, pol(r, a, -0.45), (0, 0, 1), Rg * 0.8, seed=i)
        elif kind == 'bon':
            bonbon(m, key, pol(r, a, Rg * 0.6 - 0.45), (-math.sin(a), math.cos(a), 0.15), Rg * 0.6, stripe='cream11')
        elif kind == 'truffle':
            truffle(m, key, pol(r, a, Rg * 0.7 - 0.45), Rg * 0.7, seed=i)
        elif kind == 'lolly':
            n_ = Vector((math.cos(a), math.sin(a), 0.7))
            lolly(m, pol(r, a, Rg * 0.95 - 0.2), n_, Rg * 0.95, cols=(key,), thick=0.4, turns=1.6)


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


def wafer_wing(m, root, s, rays, mem='wafer11', ray='waferd11', tips=('pink11', 'mintd11', 'lemon11'),
               inner=None, thick=0.3, notch=0.7, ray_r=0.36, tip_r=0.6, grid=1.5, lead=None, lead_r=0.6,
               root_lolly=None, gem=None):
    """Aile en gaufrette : voile dorée quadrillée (baleines + traverses sur les deux faces), bonbons au bout des
    baleines, voile de sucre filé plus courte devant (inner = (voile, baleines)), sucette à la racine."""
    root = Vector(root)
    tps, P, nrm = fin(m, root, s, rays, mem, ray, None, thick=thick, notch=notch, ray_r=ray_r, lead=lead,
                      lead_r=lead_r)
    # quadrillage en losanges (comme un cornet de gaufre), découpé au contour de la voile, sur les deux faces
    poly = [(0.0, 0.0)]
    for i, (a, L) in enumerate(rays):
        poly.append((math.cos(math.radians(a)) * L, math.sin(math.radians(a)) * L))
        if i + 1 < len(rays):
            a2, L2 = rays[i + 1]
            am, Lm = math.radians((a + a2) / 2), (L + L2) / 2 * notch
            poly.append((math.cos(am) * Lm, math.sin(am) * Lm))

    def clip(p0, d):
        ts = []
        for i in range(len(poly)):
            a, b = poly[i], poly[(i + 1) % len(poly)]
            ex, ey = b[0] - a[0], b[1] - a[1]
            den = d[0] * ey - d[1] * ex
            if abs(den) < 1e-9:
                continue
            wx, wy = a[0] - p0[0], a[1] - p0[1]
            t = (wx * ey - wy * ex) / den
            q = (wx * d[1] - wy * d[0]) / den
            if 0 <= q < 1:
                ts.append(t)
        ts.sort()
        return [(ts[i], ts[i + 1]) for i in range(0, len(ts) - 1, 2)]

    sp = grid if isinstance(grid, (int, float)) else 1.5
    span = max(L for a, L in rays) * 1.5
    for d in ((0.7071, 0.7071), (0.7071, -0.7071)):
        nv = (-d[1], d[0])
        for k in range(-int(span / sp), int(span / sp) + 1):
            p0 = (nv[0] * k * sp, nv[1] * k * sp)
            for t0, t1 in clip(p0, d):
                t0, t1 = t0 + 0.35, t1 - 0.35
                if t1 - t0 < 0.6:
                    continue
                for sd in (1, -1):
                    ends = [root + Vector((s * u, 0.22 * u, v)) + nrm * sd * thick * 0.5
                            for u, v in ((p0[0] + d[0] * t, p0[1] + d[1] * t) for t in (t0, t1))]
                    tube(B(m, ray, True), dense(ends, 0.5), ray_r * 0.36, sides=5)
    for i, t in enumerate(tps):
        orn_ball(B(m, tips[i % len(tips)], True), t, tip_r, sub=2)
    if inner:
        fin(m, root + Vector((0, -0.3, 0)), s, [(a, L * 0.58) for a, L in rays], inner[0], inner[1], None,
            notch=0.8, ray_r=ray_r * 0.75, thick=thick * 0.8)
    if root_lolly:
        R = root_lolly[0]
        g = root + Vector((s * R * 0.95, -0.55, R * 0.15))
        lolly(m, g, (0, -1, 0), R, cols=root_lolly[1], base='cream11', thick=0.5, rim=root_lolly[2], gem=gem,
              turns=1.8)
    return tps, P, nrm


def medallion(m, th, z, R, gem_key, gold='pink11', dark='pinkd11'):
    """Gemme de sucre sertie dans un anneau de bonbon, posée sur la coquille."""
    n = Vector((math.cos(th), math.sin(th), 0))
    r0 = max(rs(m, th + da, z + dz) for da in (-R / 9, 0, R / 9) for dz in (-R * 0.7, 0, R * 0.7))
    c = pol(r0 + 0.12, th, z)
    orn_torus(B(m, gold, True), c, R, R * 0.24, axis=n, seg=32, sides=8)
    orn_cone(B(m, dark, True), c + n * R * 0.1, -n, R * 1.2, R * 0.98, sides=16)
    orn_gem(B(m, gem_key, False), c + n * R * 0.22, R * 0.84, direction=n)
    return c


def body_lolly(m, th, z, R, cols, base='cream11', rim=None, gem=None, turns=2.2, thick=0.6):
    """Sucette ronde plaquée sur la coquille (face vers l'extérieur), tenue par un plot caché derrière."""
    n = Vector((math.cos(th), math.sin(th), 0))
    k = R * 0.8 / max(rs(m, th, z), 1.0)
    r0 = surf_r(m, th, z, k, R * 0.75)
    c = pol(r0 + thick * 0.5 + 0.12, th, z)
    orn_cyl(B(m, base, False), c - n * 1.6, n, 1.6, R * 0.55, sides=16)
    lolly(m, c, n, R, cols=cols, base=base, rim=rim, gem=gem, turns=turns, thick=thick, both=False)
    return c


def body_bonbon(m, key, th, z, r, stripe='cream11', wrap=None):
    """Bonbon enveloppé collé sur le flanc (papillotes de côté)."""
    n = Vector((math.cos(th), math.sin(th), 0))
    r0 = surf_r(m, th, z, r * 1.6 / max(rs(m, th, z), 1.0), r * 0.6)
    bonbon(m, key, pol(r0 + r * 0.55, th, z), (-math.sin(th), math.cos(th), 0.25), r, wrap=wrap, stripe=stripe)


def candy_crown(m, z, items, Rg, ring=('cream11', 'cherry11'), out=0.5, rr=0.45):
    """Couronne de bonbons debout sur un anneau de sucre d'orge, autour de la pointe."""
    Rc = rmax(m, z) + out
    cane_ring(m, (0, 0, z), Rc, rr, ring[0], ring[1])
    n = len(items)
    for i, (kind, key) in enumerate(items):
        a = i / n * TAU
        if kind == 'gum':
            gumdrop(m, key, pol(Rc, a, z + rr * 0.4), (0, 0, 1), Rg, seed=i)
        elif kind == 'bon':
            bonbon(m, key, pol(Rc, a, z + rr + Rg * 0.62), (-math.sin(a), math.cos(a), 0), Rg * 0.66,
                   stripe='cream11')
        elif kind == 'glow':
            orn_cyl(B(m, ring[0], False), pol(Rc, a, z), (0, 0, 1), rr + 0.4, Rg * 0.3, sides=10)
            orn_ball(B(m, key, True), pol(Rc, a, z + rr + Rg * 0.75), Rg * 0.62, sub=2)
        elif kind == 'lolly':
            lolly(m, pol(Rc, a, z + rr + Rg * 1.25), (math.cos(a), math.sin(a), 0), Rg * 0.95, cols=(key,),
                  thick=0.42, turns=1.6, stick='cream11', stick_dir=(0, 0, -1), stick_L=0.4)
    return Rc


def cane_crown(m, z, n, L, hook, cols, Rr=0.5, out=0.55, r=0.36, ring=('pink11', 'pinkl11')):
    """Couronne de sucres d'orge debout (crosses vers l'extérieur) sur un anneau rayé."""
    Rc = rmax(m, z) + out
    cane_ring(m, (0, 0, z), Rc, Rr, ring[0], ring[1])
    orn_torus(B(m, 'pinkd11', True), (0, 0, z - Rr * 1.1), Rc * 0.98, Rr * 0.6, seg=48, sides=6)
    for i in range(n):
        a = i / n * TAU
        cane(m, pol(Rc, a, z - Rr * 0.3), (0, 0, 1), L, hook, (math.cos(a), math.sin(a), 0), r=r,
             red=cols[i % len(cols)])
    return Rc


# LES SIX ŒUFS --------------------------------------------------------------------------------

FRONT = -math.pi / 2


def build_T2(off):
    """Gummy Egg : bonbon gélifié rouge cerise, reflet clair, sommet sucré, petit dôme citron saupoudré."""
    W, H = SIZES[2]
    m = Vox(H, seed=1102)
    egg_body(m, W, H, 'cherry11', 11021, bump=0.45)
    m.paint(lambda x, y, z: z <= 2.2 + wave(math.atan2(y, x), 3, 0.7, 0.5), 'cherryd11')
    # reflet de gomme : traînée claire en haut à gauche de la face avant
    fl = FRONT - 0.55
    m.paint(lambda x, y, z: 6 <= z <= 10 and abs((math.atan2(y, x) - fl + math.pi) % TAU - math.pi) < 0.2
            + 0.05 * (z - 6), 'cherryl11')
    m.paint(lambda x, y, z: z == 11 and abs((math.atan2(y, x) - fl - 0.1 + math.pi) % TAU - math.pi) < 0.18,
            'pinkl11')
    # sucre au sommet
    m.paint(lambda x, y, z: 7 <= z <= 9 and abs((math.atan2(y, x) - fl + math.pi) % TAU - math.pi) < 0.08, 'pinkl11')
    m.paint(lambda x, y, z: z >= H - 3.4 + wave(math.atan2(y, x), 5, 0.7, 1.0), 'cream11')
    top = H - 0.5
    sugar(m, 22, lambda x, y, z: z >= 7, r=0.24, mind=1.4)
    gumdrop(m, 'lemon11', (0, 0, top - 0.25), (0, 0, 1), 1.15, seed=2)
    nest(m, ['cherryd11', 'lemon11', 'mintd11'], 15)
    return build(m, 'Egg_R11_T2', P11, off)


def build_T3(off):
    """Sprinkle Egg : rose, glaçage blanc qui coule, vermicelles de toutes les couleurs, chantilly rose au sommet."""
    W, H = SIZES[3]
    m = Vox(H, seed=1103)
    egg_body(m, W, H, 'pink11', 11031, bump=0.45)
    m.paint(lambda x, y, z: z <= 2.4 + wave(math.atan2(y, x), 3, 0.8), 'pinkd11')
    m.paint(lambda x, y, z: z == 3, 'pinkx11')
    icing(m, 'cream11', H - 6.5, 7, Lr=(2.0, 4.6), seed=31, br=0.66, w=1.3)
    sprinkles(m, 30, lambda x, y, z: m.cells.get((x, y, z)) == 'cream11', mind=1.0)
    sprinkles(m, 8, lambda x, y, z: 4 <= z <= 8 and m.cells.get((x, y, z)) == 'pink11', mind=2.4, up=False)
    top = H - 0.5
    whip(m, 'pinkl11', Vector((0, 0, top - 0.2)), 1.35, 1.7)
    nest(m, ['pinkd11', 'mintd11', 'lemon11'], 13)
    candy_litter(m, 3, ['mint11', 'lemon11', 'blue11'], kinds=('gum',), Rr=(0.9, 1.15))
    return build(m, 'Egg_R11_T3', P11, off)


def build_T4(off):
    """Swirl Egg : spirale de sucette rose et menthe, bâton et nœud au sommet, deux mini-sucettes plantées,
    lueur douce, bonbons enveloppés et sucettes en orbite."""
    W, H = SIZES[4]
    m = Vox(H, seed=1104)
    egg_body(m, W, H, 'cream11', 11041, bump=0.2)
    swirl_paint(m, ['pinkd11', 'pink11', 'cream11', 'mintd11', 'mint11', 'cream11'], k=2, pitch=13.0)
    m.paint(lambda x, y, z: z <= 2.6 + wave(math.atan2(y, x), 4, 0.6), 'mintd11')
    m.paint(lambda x, y, z: z >= H - 2.4, 'pinkd11')
    glow_dots(m, 'G:gpink11', 4, lambda x, y, z: 6 <= z <= 13, mind=4.5)
    top = H - 0.5
    # bâton de sucette et nœud de ruban menthe
    orn_cyl(B(m, 'cream11', False), (0, 0, top - 0.6), (0, 0, 1), 3.6, 0.42, sides=12)
    orn_ball(B(m, 'G:gpink11', True), (0, 0, top + 3.3), 0.62, sub=2)
    kc = Vector((0, -0.2, top + 0.9))
    for s in (1, -1):
        loop = [kc, kc + Vector((s * 0.9, -0.1, 0.75)), kc + Vector((s * 1.8, -0.15, 0.55)),
                kc + Vector((s * 1.9, -0.15, -0.15)), kc + Vector((s * 1.1, -0.1, -0.35)), kc]
        tube(B(m, 'mintd11', True), dense(loop, 0.12), 0.2, sides=8, flat=2.2, ref=(0, 1, 0))
        tail = [kc, kc + Vector((s * 0.55, -0.35, -0.8)), kc + Vector((s * 0.95, -0.45, -1.45))]
        tube(B(m, 'mint11', True), dense(tail, 0.12), 0.18, sides=8, flat=2.0, ref=(0, 1, 0))
    orn_ball(B(m, 'mint11', True), kc + Vector((0, -0.05, 0)), 0.5, sub=2)
    # deux mini-sucettes plantées sur les flancs
    for s in (1, -1):
        th = FRONT + s * 1.15
        z = 9.5
        nn = Vector((math.cos(th), math.sin(th), 0))
        c = pol(rs(m, th, z) + 1.4, th, z + 1.6)
        lolly(m, c, nn, 1.25, cols=('pink11' if s > 0 else 'mintd11',), thick=0.42, turns=1.7, stick='cream11',
              stick_dir=(-nn * 0.75 + Vector((0, 0, -1))).normalized(), stick_L=1.0)
    nest(m, ['mintd11', 'pinkd11', 'cream11'], 16)
    candy_litter(m, 4, ['pink11', 'mint11', 'lemon11', 'plum11'], kinds=('gum', 'bon'), Rr=(0.85, 1.15))
    with layer(m, 'Orbit'):
        Ro = W / 2 + 3.6
        cols = ['pink11', 'mint11', 'lemon11', 'plum11']
        for i in range(8):
            a = i / 8 * TAU + 0.2
            p = pol(Ro, a, 6.4 + 0.9 * math.sin(i * 1.7))
            if i % 2 == 0:
                bonbon(m, cols[(i // 2) % 4], p, (-math.sin(a), math.cos(a), 0.3), 0.85, stripe='cream11')
            else:
                lolly(m, p, (math.cos(a), math.sin(a), 0), 1.05, cols=(cols[(i // 2 + 1) % 4],), thick=0.4,
                      turns=1.6)
    return build(m, 'Egg_R11_T4', P11, off)


def build_T5(off):
    """Frosted Egg : gâteau (génoise, crème, confiture) sous un glaçage rose qui coule, vermicelles, chantilly et
    cerise au sommet entourées de rosettes, sucette à l'avant, couronne de bonbons qui tourne."""
    W, H = SIZES[5]
    m = Vox(H, seed=1105)
    egg_body(m, W, H, 'milk11', 11051, bump=0.4)
    m.paint(lambda x, y, z: vnoise(x, y + 30, z, 51, 2.5) > 0.62, 'milkl11')
    m.paint(lambda x, y, z: z <= 2.0 + wave(math.atan2(y, x), 5, 0.6), 'choc11')
    m.paint(lambda x, y, z: z in (4, 9), 'cream11')
    m.paint(lambda x, y, z: z == 6 or (z == 7 and wave(math.atan2(y, x), 9, 1) > 0.3), 'cherry11')
    ends = icing(m, 'pink11', H - 8.5, 9, Lr=(1.6, 4.4), seed=52, br=0.7)
    m.paint(lambda x, y, z: z >= H - 2.2, 'pinkl11')
    zc = H - 5.6
    sprinkles(m, 34, lambda x, y, z: m.cells.get((x, y, z)) in ('pink11', 'pinkl11')
              and not (zc - 1.5 <= z <= zc + 3.5), mind=1.0)
    sprinkles(m, 10, lambda x, y, z: zc - 1.5 <= z <= zc + 3.5 and math.hypot(x, y) < rmax(m, zc) - 3.2,
              mind=1.0)
    # sucette ronde à l'avant, gemme menthe à l'arrière
    body_lolly(m, FRONT, 9.6, 1.9, ('cherry11',), rim='pinkd11', gem='gemp11', turns=2.0)
    medallion(m, FRONT + math.pi, 9.6, 1.5, 'gemm11', gold='mint11', dark='mintd11')
    for s in (1, -1):
        body_bonbon(m, 'lemon11' if s > 0 else 'blue11', FRONT + s * 1.05, 6.4, 0.85)
    top = H - 0.5
    tip = whip(m, 'cream11', Vector((0, 0, top - 0.3)), 1.7, 2.0)
    cherry(m, tip + Vector((0, 0, 0.55)), 1.0)
    for i in range(6):
        a = i / 6 * TAU + 0.3
        x, y = 2.6 * math.cos(a), 2.6 * math.sin(a)
        whip(m, 'cream11', Vector((x, y, ztop(m, x, y) - 0.25)), 0.75, 0.95, turns=2.0)
    nest(m, ['choc11', 'pinkd11', 'cream11', 'mintd11'], 18)
    candy_litter(m, 4, ['mint11', 'cherry11', 'lemon11', 'plum11'], kinds=('gum', 'bon'), Rr=(0.9, 1.25))
    with layer(m, 'Crown'):
        candy_crown(m, zc, [('gum', 'mint11'), ('bon', 'cherry11'), ('glow', 'G:glemon11'), ('gum', 'plum11'),
                            ('bon', 'blue11'), ('gum', 'lemon11'), ('bon', 'mintd11')], 1.15)
    return build(m, 'Egg_R11_T5', P11, off)


def build_T6(off):
    """Cocoa Egg : chocolat noir en tablette, bande de sucre d'orge, ganache au lait qui coule, chantilly,
    sucre d'orge et gaufrettes roulées au sommet, grande sucette à l'avant, truffes, ailes en gaufrette,
    dragées en orbite."""
    W, H = SIZES[6]
    m = Vox(H, seed=1106)
    egg_body(m, W, H, 'choc11', 11061, bump=0.45)
    m.paint(lambda x, y, z: vnoise(x, y, z, 61, 4.5) > 0.35, 'chocd11')
    # carrés de tablette sur le bas
    for c in m.surface():
        x, y, z = c
        if 3 <= z <= 6:
            arc = (math.atan2(y, x) + math.pi) * math.hypot(x, y)
            m.cells[c] = 'chocd11' if (z in (3, 6) or int(math.floor(arc)) % 3 == 0) else 'choc11'
    m.paint(lambda x, y, z: z <= 2.4 + wave(math.atan2(y, x), 6, 0.6), 'milk11')
    # bande de sucre d'orge (rayures en biais)
    m.paint(lambda x, y, z: z in (6, 9), 'cherry11')
    m.paint(lambda x, y, z: z in (7, 8), 'cream11')
    icing(m, 'milk11', H - 7.0, 10, Lr=(1.6, 4.2), seed=62, br=0.72, avoid=(0.0, math.pi), gap=0.55)
    m.paint(lambda x, y, z: z >= H - 2.5, 'milkl11')
    drizzle(m, 'cream11', lambda a: H - 4.6 + 0.9 * math.sin(5 * a), r=0.24)
    drizzle(m, 'pinkl11', lambda a: H - 6.2 + 0.8 * math.sin(4 * a + 1.3), r=0.22)
    cane_belt(m, 7.5, 0.85)
    sprinkles(m, 22, lambda x, y, z: m.cells.get((x, y, z)) in ('milk11', 'milkl11') and z > 10,
              keys=('cream11', 'pink11', 'blue11', 'lemon11'), mind=1.1)
    body_lolly(m, FRONT, 14.0, 2.7, ('pink11', 'mintd11'), rim='cherry11', turns=1.8)
    medallion(m, FRONT + math.pi, 13.5, 1.6, 'gemp11', gold='lemon11', dark='lemond11')
    for s in (1, -1):
        th = FRONT + s * 1.05
        truffle(m, 'chocd11', pol(rs(m, th, 12.5) + 0.7, th, 12.5), 1.05, seed=3 + s)
        body_bonbon(m, 'pink11' if s > 0 else 'mint11', FRONT + s * 0.62, 4.6, 0.75)
    top = H - 0.5
    whip(m, 'cream11', Vector((0, 0, top - 0.3)), 2.0, 2.3)
    cane(m, (0.6, 0.9, top - 0.2), (0.25, 0.2, 1), 3.2, 0.7, (1, 0, 0), r=0.34)
    for s in (1, -1):
        x = s * 2.2
        roll(m, (x, 0.6, ztop(m, x, 0.6) - 0.5), (s * 0.35, -0.1, 1), 3.4, 0.36)
    nest(m, ['chocd11', 'milk11', 'cherry11', 'cream11'], 20)
    candy_litter(m, 5, ['chocd11', 'pink11', 'milk11', 'mint11', 'choc11'], kinds=('truffle', 'bon'),
                 Rr=(0.95, 1.3))
    for s, g in ((1, 'WingR'), (-1, 'WingL')):
        with layer(m, g):
            r = rs(m, 0 if s > 0 else math.pi, 14.5) - 0.9
            wafer_wing(m, (s * r, 0.4, 14.5), s, [(58, 7.4), (34, 9.4), (11, 10.2), (-12, 8.8), (-33, 6.6)],
                       tips=('pink11', 'mintd11', 'lemon11', 'blue11', 'cherry11'),
                       root_lolly=(1.4, ('cherry11',), 'pinkd11'), gem='gemp11')
    with layer(m, 'Orbit'):
        Ro = W / 2 + 4.8
        cols = ['blue11', 'pink11', 'G:glemon11', 'mint11', 'plum11', 'G:gpink11', 'cream11', 'lemon11']
        for i in range(8):
            a = i / 8 * TAU + 0.3
            zz = 3.0 + (i % 3) * 1.2
            dragee(m, cols[i], pol(Ro, a, zz), 0.8 if cols[i].startswith('G:') else 0.95)
    return build(m, 'Egg_R11_T6', P11, off)


def build_T7(off):
    """Sugarplum Egg : bandes festonnées du prune au rose, étoiles et éclats de sucre, grande sucette à gemmes,
    gemmes de sucre, bonbons, collier de boules de gomme, chantilly et étoile au sommet, couronne de sucres d'orge,
    halo de sucre d'orge, grandes ailes de gaufrette et de sucre filé, anneau de bonbons en orbite."""
    W, H = SIZES[7]
    m = Vox(H, seed=1107)
    egg_body(m, W, H, 'plum11', 11071, bump=0.45)
    seq = ['plumx11', 'plumd11', 'plum11', 'pinkd11', 'pink11', 'pinkl11']
    edges = [4.6, 9.6, 14.8, 19.8, 24.2]
    for c in m.surface():
        x, y, z = c
        th = math.atan2(y, x)
        idx, line = 0, None
        for i, e in enumerate(edges):
            lim = e + wave(th, 7, 0.75, i * 0.9)
            if z > lim:
                idx = i + 1
                line = ('lemon11' if i == 1 else 'cream11' if i == 3 else None) if z <= lim + 1 else None
        m.cells[c] = line or seq[idx]
    glow_dots(m, 'G:gcream11', 10, lambda x, y, z: 1 <= z <= 9, mind=3.6)
    stars(m, 16, lambda x, y, z: 2 <= z <= 19 and not (abs(x) < 6 and y < 0 and 7 < z < 19)
          and not (abs(x) < 5 and y > 0 and 8 < z < 17) and not (abs(y) < 4.5 and 10 < z), r=0.85, mind=2.8)
    body_lolly(m, FRONT, 13.2, 4.4, ('pink11', 'mintd11'), rim='cherry11', gem='gemp11', turns=2.2, thick=0.7)
    for s in (1, -1):
        medallion(m, FRONT + s * 0.95, 13.4, 1.5, 'gemm11', gold='lemon11', dark='lemond11')
        body_bonbon(m, 'cherry11' if s > 0 else 'blue11', FRONT + s * 0.8, 7.4, 1.1)
    body_lolly(m, FRONT + math.pi, 12.4, 3.4, ('plum11', 'pink11'), rim='plumd11', gem='gemm11', turns=2.0)
    for s in (1, -1):
        medallion(m, FRONT + math.pi + s * 0.85, 7.8, 1.4, 'gemp11', gold='mint11', dark='mintd11')
    necklace(m, 'lemon11', lambda a: 18.6 - 1.4 * abs(math.sin(3 * (a - FRONT))), 0.62, sub=2, lift=0.12,
             bead='cherry11', br=0.36, keep=lambda a: abs(math.cos(a)) < 0.72)
    top = H - 0.5
    tip = whip(m, 'cream11', Vector((0, 0, top - 0.3)), 2.2, 2.4)
    orn_cyl(B(m, 'cream11', False), tip - Vector((0, 0, 0.8)), (0, 0, 1), 2.0, 0.3, sides=10)
    orn_star(B(m, 'lemon11', False), tip + Vector((0, 0, 2.6)), 2.1, 0.9, 0.6, normal=(0, -1, 0))
    orn_ball(B(m, 'G:glemon11', True), tip + Vector((0, -0.55, 2.6)), 0.38, sub=1)
    nest(m, ['plumd11', 'pink11', 'cream11', 'mintd11'], 24)
    candy_litter(m, 6, ['pink11', 'mint11', 'lemon11', 'plum11', 'blue11', 'cherry11'],
                 kinds=('gum', 'bon', 'lolly'), Rr=(1.0, 1.4))
    with layer(m, 'Crown'):
        cane_crown(m, H - 6.6, 8, 2.4, 0.75, ['cherry11', 'mintd11'])
    with layer(m, 'Halo'):
        zh, Rh = H + 6.8, 5.0
        cane_ring(m, (0, 0, zh), Rh - 0.6, 0.5, 'pinkl11', 'pink11')
        for i in range(6):
            a = i / 6 * TAU
            if i % 2 == 0:
                orn_ball(B(m, 'G:gpink11', True), pol(Rh - 0.6, a, zh + 0.55), 0.48, sub=2)
            else:
                orn_gem(B(m, 'gemm11', False), pol(Rh - 0.6, a, zh + 0.5), 0.55, direction=(0, 0, 1))
    for s, g in ((1, 'WingR'), (-1, 'WingL')):
        with layer(m, g):
            r = rs(m, 0 if s > 0 else math.pi, 16) - 1.0
            wafer_wing(m, (s * r, 0.5, 16), s, [(58, 11.0), (42, 14.5), (26, 16.5), (9, 16.5), (-6, 14.0),
                                                (-14, 9.8)],
                       tips=('pink11', 'mintd11', 'lemon11', 'cherry11', 'blue11', 'plum11'),
                       inner=('pinkl11', 'pink11'), notch=0.72, ray_r=0.42, tip_r=0.7, lead='lemon11', lead_r=0.7,
                       root_lolly=(2.1, ('pink11', 'mintd11'), 'cherry11'), gem='gemm11', grid=1.8)
    with layer(m, 'Orbit'):
        Ro, zo, tl = 14.2, 5.2, 0.13
        rot = cane_ring(m, (0, 0, zo), Ro, 0.32, 'cream11', 'cherry11', tilt=tl, seg=96)
        cols = ['pink11', 'mint11', 'lemon11']
        for i in range(6):
            a = i / 6 * TAU
            p = Vector((0, 0, zo)) + rot @ Vector((Ro * math.cos(a), Ro * math.sin(a), 0))
            if i % 2 == 0:
                orn_ball(B(m, 'G:gplum11', True), p, 0.8, sub=2)
                orn_torus(B(m, 'lemon11', True), p, 0.95, 0.16, tilt=0.9, seg=24, sides=6)
            else:
                bonbon(m, cols[i // 2], p, (-math.sin(a), math.cos(a), 0.2), 1.05, stripe='cream11')
        for i in range(3):
            a = i / 3 * TAU + 0.5
            lolly(m, pol(17.6, a, 2.8 + i * 1.6), (math.cos(a), math.sin(a), 0), 1.8, cols=('pink11', 'mintd11'),
                  rim='cherry11', gem='gemp11', thick=0.5, turns=1.8)
            b = a + TAU / 6
            gumdrop(m, ['plum11', 'lemon11', 'blue11'][i], pol(17.4, b, 6.2 - i * 1.4), (0, 0, 1), 1.1, seed=i)
    return build(m, 'Egg_R11_T7', P11, off)


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
    drop('Egg_R11_T%d' % n)
    random.seed(1100 + n)
    coll = BUILDERS[n]((OFFSETS[n], 0, 0))
    obs = [o for o in coll.objects if o.type == 'MESH']
    for o in list(obs):
        if not len(o.data.vertices):
            bpy.data.objects.remove(o, do_unlink=True)
    obs = [o for o in coll.objects if o.type == 'MESH']
    tris = sum(len(p.vertices) - 2 for o in obs for p in o.data.polygons)
    zs = [(o.matrix_world @ v.co).z for o in obs for v in o.data.vertices]
    xs = [(o.matrix_world @ v.co).x for o in obs for v in o.data.vertices]
    print('Egg_R11_T%d : %d objets, %d triangles, x %.1f..%.1f, z %.2f..%.2f, max tris/objet %d' % (
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
    colls = [bpy.data.collections.get('Egg_R11_T%d' % n) for n in sorted(BUILDERS)]
    colls = [c for c in colls if c]
    bpy.data.libraries.write(path, set(colls), fake_user=True, compress=True)
    print('enregistré', path, [c.name for c in colls])


# CONTRÔLES (comme les anneaux 9 et 10) -------------------------------------------------------

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


print("eggs_r11 chargé")
