# Œufs de l'anneau 9 « Storm Halo » (anneau d'orages : nuages violets traversés d'éclairs), même méthode que
# les anneaux 1 à 8 : corps en briques (voxkit.Vox) + ornements lisses (_ORN_), groupes animés (_ACrown_,
# _AOrbit_, _AHalo_, _AWingL_, _AWingR_). Charger voxkit.py avant ce fichier, puis build_all() ou build_one(n).
# clash(coll) vérifie qu'un groupe qui tourne ne traverse ni les ailes qui battent ni les ornements fixes ;
# neon_share(coll) donne la part de surface en néon (à garder sous 5 %).

TAU = math.tau

P9 = dict(
    violet9='#6E5AC8', violetl9='#9E86FF', violetd9='#4E3E9E', night9='#2A1E5A', nightl9='#40308A',
    lilac9='#C9BDFF', cloud9='#E9E5FF', cloudd9='#A99DE2', storm9='#5C5098',
    yellow9='#FFE15A', yellowd9='#F2B21E', white9='#F7F6FF', cyan9='#B4F2FF', cyand9='#6FD6F0',
    copper9='#D97A3A', copperl9='#F2A66A', copperd9='#A8552A',
    gold9='#FFC21A', goldd9='#E08A10', goldl9='#FFE27A',
    gemc9='#3EE6FF', gemv9='#B04AFF', gemy9='#FFD23A', gemw9='#E8F6FF',
    gyellow9='#FFE15A', gviolet9='#B9A2FF', gcyan9='#9CF4FF', gwhite9='#F6F4FF',
)

OFFSETS = {2: 0, 3: 34, 4: 70, 5: 112, 6: 162, 7: 222}
SIZES = {2: (11, 15), 3: (11, 17), 4: (13, 19), 5: (15, 22), 6: (17, 25), 7: (21, 29)}


# BRUIT ET PROFIL (comme l'anneau 8) ----------------------------------------------------------

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


def rsm(m, th, z, dz=1.0, dth=0.15):
    return max(rs(m, th + a, z + b) for a in (-dth, 0, dth) for b in (-dz, 0, dz))


def rss(m, th, z):
    return (rs(m, th - 0.2, z) + rs(m, th, z) + rs(m, th + 0.2, z)) / 3


def rmax(m, z):
    """Le plus grand rayon du corps à la hauteur z (tous côtés), pour ce qui tourne autour."""
    return max(rs(m, i / 32 * TAU, z) for i in range(32))


def pol(r, a, z):
    return Vector((r * math.cos(a), r * math.sin(a), z))


# FORMES DE L'ORAGE ---------------------------------------------------------------------------

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


# éclair de dessin animé : large en haut (y = 1), pointe en bas (y = -1)
BOLT = [(-0.10, 1.0), (0.42, 1.0), (0.10, 0.22), (0.40, 0.22), (-0.32, -1.0), (-0.06, -0.10), (-0.36, -0.10)]


def bolt(m, key, top, tip, normal, width=0.85, thick=0.42, edge='yellowd9', mirror=False):
    """Éclair plat en zigzag, du côté large (top) à la pointe (tip), face vers normal ; liseré plus foncé derrière."""
    top, tip = Vector(top), Vector(tip)
    v = top - tip
    L = v.length
    v.normalize()
    n = Vector(normal)
    n = (n - v * n.dot(v)).normalized()
    u = v.cross(n).normalized()
    if mirror:
        u = -u
    c = (top + tip) / 2
    pts = [(x * width * L / 2, y * L / 2) for x, y in BOLT]
    orn_plate(B(m, key, False), pts, c, u, v, n, thick)
    if edge:
        k = 1.13
        orn_plate(B(m, edge, False), [(x * k, y * k) for x, y in pts], c - n * thick * 0.55, u, v, n, thick * 0.8)


def orn_twinkle(bm, center, R, thick, normal=(0, -1, 0), spin=0.0):
    """Étincelle à 4 grandes pointes et 4 petites."""
    rot = _orient(normal)
    c = Vector(center)
    rim = []
    for i in range(16):
        a = i / 16 * TAU + spin + math.pi / 2
        r = (R if i % 4 == 0 else R * 0.5) if i % 2 == 0 else R * 0.27
        rim.append(bm.verts.new(c + rot @ Vector((math.cos(a) * r, math.sin(a) * r, 0))))
    f = bm.verts.new(c + rot @ Vector((0, 0, thick)))
    k = bm.verts.new(c + rot @ Vector((0, 0, -thick)))
    for i in range(16):
        j = (i + 1) % 16
        bm.faces.new((rim[i], rim[j], f))
        bm.faces.new((rim[j], rim[i], k))


def twinkle(m, key, c, R, core='white9', thick=0.35, cross=True, normal=(0, -1, 0)):
    """Étincelle en relief : deux étoiles à 4 branches croisées, petite bille claire au centre."""
    n = Vector(normal).normalized()
    orn_twinkle(B(m, key, False), c, R, thick, normal=n)
    if cross:
        side = n.cross(Vector((0, 0, 1)))
        if side.length < 1e-3:
            side = Vector((1, 0, 0))
        orn_twinkle(B(m, key, False), c, R * 0.85, thick, normal=side.normalized())
    if core:
        orn_ball(B(m, core, True), c, max(R * 0.2, thick * 1.3), sub=1)


def puff(m, c, R, lo='cloudd9', hi='cloud9', along=(1, 0, 0)):
    """Petit nuage de dessin animé : rang de boules à plat (dessous plus sombre), deux boules dessus."""
    c = Vector(c)
    a = Vector(along)
    a.z = 0
    a = a.normalized() if a.length > 1e-3 else Vector((1, 0, 0))
    for f, r in ((-0.95, 0.6), (0.0, 0.8), (0.95, 0.6)):
        orn_ball(B(m, lo, True), c + a * f * R, r * R, scale=(1, 1, 0.78), sub=2)
    for f, r, dz in ((-0.38, 0.62, 0.48), (0.42, 0.52, 0.4)):
        orn_ball(B(m, hi, True), c + a * f * R + Vector((0, 0, dz * R)), r * R, sub=2)


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


ZIG = [(-1.0, 2.3), (0.75, 0.55), (-0.75, -0.35), (1.0, -2.3)]


def paint_path(m, key, th0, z0, pts=ZIG, width=0.62, scale=1.0):
    """Trait peint sur les briques le long d'une ligne brisée (s, dz) : s = longueur d'arc autour de l'œuf depuis
    l'angle th0, dz = hauteur depuis z0. Par défaut, un petit zigzag d'éclair vertical."""
    P = [Vector((s * scale, dz * scale)) for s, dz in pts]
    for c in m.surface():
        x, y, z = c
        r = math.hypot(x, y)
        if r < 0.5:
            continue
        d = (math.atan2(y, x) - th0 + math.pi) % TAU - math.pi
        q = Vector((d * r, z - z0))
        best = 1e9
        for a, b in zip(P, P[1:]):
            ab = b - a
            t = max(0.0, min(1.0, (q - a).dot(ab) / ab.length_squared))
            best = min(best, (q - (a + ab * t)).length)
        if best <= width:
            m.cells[c] = key


def glow_dots(m, key, n, test=None, mind=3.0):
    surf = sorted(c for c in m.surface() if not test or test(*c))
    rnd, chosen, tries = m.rnd, [], 0
    while len(chosen) < n and tries < 800 and surf:
        tries += 1
        c = rnd.choice(surf)
        if all((Vector(c) - Vector(d)).length >= mind for d in chosen):
            chosen.append(c)
    for c in chosen:
        m.cells[c] = key


def _arcpos(c, th0, z0):
    x, y, z = c
    r = math.hypot(x, y)
    d = (math.atan2(y, x) - th0 + math.pi) % TAU - math.pi
    return Vector((d * r, z - z0))


def _segdist(q, P):
    best = 1e9
    for a, b in zip(P, P[1:]):
        ab = b - a
        t = max(0.0, min(1.0, (q - a).dot(ab) / ab.length_squared))
        best = min(best, (q - (a + ab * t)).length)
    return best


def cracks(m, n, zmin, zmax, core='yellow9', glow='G:gyellow9', rim='violetl9', glint='G:gviolet9', rim_p=0.5,
           a0=0.0, cw=0.48):
    """Fentes de plasma en zigzag, comme des éclairs dans la coquille : bord violet clair, cœur jaune,
    éclats lumineux à un coude sur deux, une étincelle violette par fente."""
    rnd = m.rnd
    surf = [c for c in m.surface() if math.hypot(c[0], c[1]) > 0.5]
    polys = []
    for i in range(n):
        th0 = a0 + i / n * TAU + rnd.uniform(-0.2, 0.2)
        z0 = rnd.uniform(zmin, zmin + (zmax - zmin) * 0.4)
        pts, s, sign = [Vector((0.0, 0.0))], 0.0, rnd.choice((-1, 1))
        while z0 + pts[-1].y < zmax and len(pts) < 7:
            s += sign * rnd.uniform(0.9, 1.7)
            sign = -sign
            pts.append(Vector((s, pts[-1].y + rnd.uniform(1.6, 2.6))))
        polys.append((th0, z0, pts, True))
        if len(pts) > 3:
            k = rnd.randrange(1, len(pts) - 2)
            d = 1 if pts[k + 1].x < pts[k].x else -1
            b = pts[k]
            polys.append((th0, z0, [b, b + Vector((d * 1.7, 0.9)), b + Vector((d * 2.4, 2.3))], False))
    dist = {}
    for c in surf:
        dist[c] = min(_segdist(_arcpos(c, th0, z0), P) for th0, z0, P, _ in polys)
    for c, d in dist.items():
        if d <= cw:
            m.cells[c] = core
        elif d <= cw + 0.55 and rnd.random() < rim_p:
            m.cells[c] = rim
    for th0, z0, P, main in polys:
        for k, p in enumerate(P):
            if k % 2 == 1:
                m.cells[min(surf, key=lambda c: (_arcpos(c, th0, z0) - p).length)] = glow
        if main:
            ring = [c for c, d in dist.items() if cw < d <= cw + 0.55 and _arcpos(c, th0, z0).length < 6]
            if ring:
                m.cells[rnd.choice(sorted(ring))] = glint


def coil(m, key, z0, z1, turns, r=0.34, lift=0.22, a0=0.0):
    """Bobine : fil de cuivre enroulé autour de la coquille."""
    N = int(turns * 28)
    A = [a0 + i / N * turns * TAU for i in range(N + 1)]
    Z = [z0 + (z1 - z0) * i / N for i in range(N + 1)]
    raw = [rs(m, a, z) for a, z in zip(A, Z)]
    sm = [sum(raw[max(0, i - 3):i + 4]) / len(raw[max(0, i - 3):i + 4]) for i in range(N + 1)]
    pts = [pol(sm[i] + r * 0.5 + lift, A[i], Z[i]) for i in range(N + 1)]
    orn_sweep(B(m, key, True), pts, [r] * len(pts), sides=8)
    for p in (pts[0], pts[-1]):
        orn_ball(B(m, key, True), p, r * 1.45, sub=1)
    return pts


def zigzag_ring(m, key, z0, R, amp, n=14, w=0.55, thick=0.4, tilt=0.0, edge='yellowd9'):
    """Éclair qui fait le tour : bande en zigzag fermée, de hauteur constante (coudes nets comme un éclair dessiné),
    liseré plus foncé derrière."""
    rot = Matrix.Rotation(tilt, 4, 'X')
    up = rot @ Vector((0, 0, 1))
    P = []
    for i in range(n):
        a = i / n * TAU
        P.append(Vector((0, 0, z0)) + rot @ Vector((R * math.cos(a), R * math.sin(a), amp * (1 if i % 2 else -1))))
    for key_, ww, dr, th in ((key, w, 0.0, thick), (edge, w * 1.35, -thick * 0.55, thick * 0.8)):
        if not key_:
            continue
        bm = B(m, key_, False)
        for i in range(n):
            a, b = P[i], P[(i + 1) % n]
            mid = (a + b) / 2 - Vector((0, 0, z0))
            nr = (mid - up * mid.dot(up)).normalized()
            q = [a - up * ww, b - up * ww, b + up * ww, a + up * ww]
            q = [p + nr * dr for p in q]
            top = [bm.verts.new(p + nr * th / 2) for p in q]
            bot = [bm.verts.new(p - nr * th / 2) for p in q]
            bm.faces.new(top)
            bm.faces.new(bot[::-1])
            for k in range(4):
                j = (k + 1) % 4
                bm.faces.new((top[k], bot[k], bot[j], top[j]))
    return P


def energy_ball(m, glow, ring, c, r, tilt=0.5):
    """Boule d'énergie : cœur lumineux et petit anneau autour."""
    orn_ball(B(m, glow, True), c, r, sub=2)
    orn_torus(B(m, ring, True), c, r * 1.16, r * 0.2, tilt=tilt, seg=24, sides=6)


def horn(m, th, z, L, r0, key='violetl9', tipkey='yellow9', out=0.8, up=1.0, curl=0.45):
    """Corne lisse qui sort de la coquille et se relève, bout jaune."""
    n = Vector((math.cos(th), math.sin(th), 0))
    r = rs(m, th, z)
    p0 = pol(r - r0 * 0.9, th, z)
    d = (n * out + Vector((0, 0, up))).normalized()
    side = n.cross(Vector((0, 0, 1))).normalized()
    pts = [p0, p0 + n * r0 * 1.2 + d * L * 0.12, p0 + n * r0 + d * L * 0.5 + Vector((0, 0, L * 0.1)),
           p0 + d * L * 0.85 + Vector((0, 0, L * 0.18)) - n * L * curl * 0.35, p0 + d * L + Vector((0, 0, L * 0.12)) - n * L * curl]
    rad = [r0, r0 * 0.92, r0 * 0.72, r0 * 0.46, r0 * 0.2]
    orn_sweep(B(m, key, True), pts[:4], rad[:4], sides=10)
    orn_sweep(B(m, tipkey, True), pts[2:], [rad[2] * 1.02, rad[3] * 1.04, 0.05], sides=10)
    orn_torus(B(m, 'gold9', True), p0 + n * r0 * 1.0, r0 * 1.02, r0 * 0.24, axis=n, seg=24, sides=7)


# REPRIS DE L'ANNEAU 8 (couleurs de l'orage) --------------------------------------------------

def nest(m, keys, n, zlo=-0.55, zhi=2.0, tube=(0.32, 0.48), off=(0.15, 0.75)):
    """Nid de brindilles enroulées autour de la base (comme les autres anneaux)."""
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


def nest_pearls(m, key, n, pr=0.55, z=0.9, sub=1):
    rnd = m.rnd
    a0 = rnd.uniform(0, TAU)
    for i in range(n):
        a = a0 + i / n * TAU + rnd.uniform(-0.25, 0.25)
        zz = z + rnd.uniform(-0.3, 0.5)
        r = rss(m, a, 2.2) + pr * rnd.uniform(0.6, 1.2)
        orn_ball(B(m, key, True), pol(r, a, zz), pr * rnd.uniform(0.85, 1.15), sub=sub)


def necklace(m, key, zf, pr, lift=0.18, sub=2, bead=None, br=0.42, a_off=0.0, keep=None):
    """Collier de billes posé sur la coquille, à la hauteur zf(angle). keep(angle) : billes gardées (laisser la
    place aux ailes)."""
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


def medallion(m, th, z, R, gem_key, gold='gold9'):
    """Gemme sertie dans un anneau d'or, posée sur la coquille."""
    n = Vector((math.cos(th), math.sin(th), 0))
    r0 = max(rs(m, th + da, z + dz) for da in (-R / 9, 0, R / 9) for dz in (-R * 0.7, 0, R * 0.7))
    c = pol(r0 + 0.12, th, z)
    orn_torus(B(m, gold, True), c, R, R * 0.24, axis=n, seg=32, sides=8)
    orn_cone(B(m, 'goldd9', True), c + n * R * 0.1, -n, R * 1.2, R * 0.98, sides=16)
    orn_gem(B(m, gem_key, False), c + n * R * 0.22, R * 0.84, direction=n)
    return c


def crown(m, z, spikes, gems, ring_r=0.42, tall=3.2, short=2.0, lean=0.22, a0=0.0, skip=(), gem_r=0.6, cone_k=1.15):
    """Couronne d'or autour de la pointe : anneau, pointes, gemmes au bout des grandes, billes sur les petites."""
    Rc = max(rs(m, i / 16 * TAU, z) for i in range(16)) + ring_r - 0.12
    orn_torus(B(m, 'gold9', True), (0, 0, z), Rc, ring_r, seg=40, sides=8)
    orn_torus(B(m, 'goldd9', True), (0, 0, z - ring_r * 1.15), Rc * 0.99, ring_r * 0.6, seg=40, sides=6)
    g = 0
    for i in range(spikes):
        if i in skip:
            continue
        a = a0 + i / spikes * TAU
        L = tall if i % 2 == 0 else short
        base = pol(Rc, a, z)
        dv = Vector((math.cos(a) * lean, math.sin(a) * lean, 1)).normalized()
        orn_cone(B(m, 'gold9', True), base - dv * ring_r * 0.5, dv, L + ring_r * 0.5, ring_r * cone_k, sides=10)
        tip = base + dv * L
        if i % 2 == 0:
            orn_gem(B(m, gems[g % len(gems)], False), tip + Vector((0, 0, gem_r * 0.45)), gem_r, direction=(0, 0, 1))
            g += 1
        else:
            orn_ball(B(m, 'goldl9', True), tip, gem_r * 0.6, sub=1)
    return Rc


# LES SIX ŒUFS --------------------------------------------------------------------------------

def build_T2(off):
    """Spark Egg : violet, petits zigzags jaunes peints, une étincelle au sommet."""
    W, H = SIZES[2]
    m = Vox(H, seed=902)
    egg_body(m, W, H, 'violet9', 9021)
    m.paint(lambda x, y, z: z <= 2.6 + 0.9 * math.sin(math.atan2(y, x) * 3 + 0.5), 'night9')
    m.paint(lambda x, y, z: z >= H - 3.4 + 0.7 * math.sin(math.atan2(y, x) * 2), 'violetl9')
    for a, z0 in ((-1.57, 7.6), (-0.35, 9.0), (0.85, 6.6), (2.05, 8.8), (3.25, 6.9)):
        paint_path(m, 'yellow9', a, z0)
    twinkle(m, 'yellow9', (0, 0, H - 0.5 + 1.3), 2.2, core='white9', thick=0.45)
    nest(m, ['nightl9', 'violetl9', 'yellowd9'], 15)
    for a in (-1.35, 1.0):
        r = rss(m, a, 2.2) + 1.0
        puff(m, pol(r, a, 1.3), 1.15, along=(-math.sin(a), math.cos(a), 0))
    return build(m, 'Egg_R9_T2', P9, off)


def build_T3(off):
    """Static Egg : bandes bleu nuit, petits nuages, éclats d'électricité statique."""
    W, H = SIZES[3]
    m = Vox(H, seed=903)
    egg_body(m, W, H, 'violetl9', 9031)

    def wv(x, y, z):
        return z + 0.8 * math.sin(2 * math.atan2(y, x) + 0.4)

    m.paint(lambda x, y, z: z <= 2.4 + 0.8 * math.sin(math.atan2(y, x) * 3), 'night9')
    for lo in (5.4, 10.4):
        m.paint(lambda x, y, z, lo=lo: lo <= wv(x, y, z) < lo + 2.2, 'night9')
    m.paint(lambda x, y, z: z >= H - 1.6, 'lilac9')
    glow_dots(m, 'G:gcyan9', 5, lambda x, y, z: 3 <= z <= 12, mind=4.0)
    # petits nuages : un qui coiffe la pointe, deux collés sur les flancs
    puff(m, (0, 0, H - 0.1), 1.6, along=(1, 0.3, 0))
    for a, z in ((-math.pi / 2 - 0.9, 12.4), (0.55, 8.4)):
        r = rsm(m, a, z) + 0.15
        puff(m, pol(r, a, z), 1.25, along=(-math.sin(a), math.cos(a), 0))
    # éclats d'électricité statique : petits éclairs qui crépitent sur la coquille, étincelles cyan
    for a, z, s in ((-math.pi / 2 + 0.45, 8.4, 1), (-math.pi / 2 - 1.8, 4.4, -1), (1.9, 12.4, 1),
                    (2.75, 6.0, -1), (-0.55, 13.0, -1)):
        n = Vector((math.cos(a), math.sin(a), 0))
        t = Vector((-math.sin(a), math.cos(a), 0))
        base = pol(rs(m, a, z) - 0.3, a, z)
        tip = base + (t * 0.75 * s + Vector((0, 0, -0.45)) + n * 0.55).normalized() * 3.0
        bolt(m, 'yellow9', base, tip, n, width=1.0, thick=0.4)
    for a, z in ((-math.pi / 2 + 1.25, 13.6), (-math.pi / 2 - 0.25, 3.8), (2.3, 9.4)):
        r = rs(m, a, z) + 0.1
        twinkle(m, 'cyan9', pol(r, a, z), 1.3, core='white9', thick=0.3, normal=(math.cos(a), math.sin(a), 0))
    nest(m, ['night9', 'violet9', 'cyand9'], 13)
    nest_pearls(m, 'cyan9', 4, pr=0.5, z=1.2)
    return build(m, 'Egg_R9_T3', P9, off)


def build_T4(off):
    """Volt Egg : anneau de cuivre à la taille, bobine, borne lumineuse au sommet, éclair jaune qui fait le tour."""
    W, H = SIZES[4]
    m = Vox(H, seed=904)
    egg_body(m, W, H, 'violet9', 9041)
    m.paint(lambda x, y, z: vnoise(x + 40, y, z, 41, 4.0) > 0.35, 'violetd9')
    m.paint(lambda x, y, z: z <= 3.2 + 1.0 * abs(math.sin(math.atan2(y, x) * 3)), 'night9')
    m.paint(lambda x, y, z: z >= H - 4.2, 'violetl9')
    zigzag_paint(m, 'yellow9', 4.6, 0.9, 10)
    zw = 7.0
    Rw = rmax(m, zw) + 0.4
    orn_torus(B(m, 'copper9', True), (0, 0, zw), Rw, 0.62, seg=48, sides=10)
    orn_torus(B(m, 'copperd9', True), (0, 0, zw - 0.75), Rw * 0.985, 0.36, seg=48, sides=7)
    orn_torus(B(m, 'copperl9', True), (0, 0, zw + 0.72), Rw * 0.97, 0.3, seg=48, sides=7)
    for i in range(8):
        a = i / 8 * TAU + TAU / 16
        orn_ball(B(m, 'copperl9', True), pol(Rw + 0.5, a, zw), 0.36, sub=1)
    coil(m, 'copperl9', 9.8, H - 4.6, 3.2, r=0.36, a0=-math.pi / 2)
    # borne de la bobine : tige de cuivre, anneaux, boule lumineuse
    top = H - 0.5
    orn_sweep(B(m, 'copper9', True), [(0, 0, top - 1.2), (0, 0, top + 2.2)], [0.55, 0.42], sides=10)
    for zz, rr in ((top + 0.3, 0.7), (top + 1.3, 0.64)):
        orn_torus(B(m, 'copperd9', True), (0, 0, zz), rr, 0.24, seg=24, sides=7)
    orn_ball(B(m, 'G:gcyan9', True), (0, 0, top + 3.2), 1.15, sub=2)
    orn_ball(B(m, 'white9', True), (-0.35, -0.55, top + 3.75), 0.38, sub=1)
    nest(m, ['copperd9', 'violetl9', 'night9'], 16)
    nest_pearls(m, 'cyan9', 5, pr=0.55, z=1.3)
    with layer(m, 'Orbit'):
        zigzag_ring(m, 'yellow9', 6.6, W / 2 + 3.4, 1.3, n=18, w=0.62, thick=0.42, tilt=0.2)
        for i in range(3):
            a = i / 3 * TAU + 0.5
            twinkle(m, 'yellow9', pol(W / 2 + 3.4, a, 10.6 - i * 1.2), 0.9, core='G:gwhite9', thick=0.22,
                    normal=(math.cos(a), math.sin(a), 0))
    return build(m, 'Egg_R9_T4', P9, off)


def build_T5(off):
    """Thunder Egg : nuage d'orage qui coiffe l'œuf (tourne lentement), éclairs qui en tombent, ailes d'éclairs."""
    W, H = SIZES[5]
    m = Vox(H, seed=905)
    egg_body(m, W, H, 'violet9', 9051)
    m.paint(lambda x, y, z: vnoise(x, y + 30, z, 51, 4.0) > 0.3, 'violetd9')
    m.paint(lambda x, y, z: z <= 4.2 + 1.2 * math.sin(math.atan2(y, x) * 3 + 0.6), 'night9')
    m.paint(lambda x, y, z: z >= 13.5 + 0.8 * math.sin(math.atan2(y, x) * 3), 'violetl9')
    zigzag_paint(m, 'yellow9', 9.6, 1.2, 8, width=0.6)
    zigzag_paint(m, 'yellowd9', 5.6, 0.8, 8, width=0.5, phase=0.5)
    glow_dots(m, 'G:gyellow9', 5, lambda x, y, z: 6 <= z <= 13, mind=4.0)
    front = -math.pi / 2
    medallion(m, front, 7.4, 1.6, 'gemc9')
    nest(m, ['night9', 'violetl9', 'yellowd9', 'gold9'], 18)
    nest_pearls(m, 'cyan9', 5, pr=0.6, z=1.3)
    with layer(m, 'Crown'):
        zc = H - 4.6
        rr = rmax(m, zc)
        for i in range(9):
            a = i / 9 * TAU
            orn_ball(B(m, 'storm9', True), pol(rr + 0.2, a, zc), 2.0, scale=(1, 1, 0.82), sub=2)
        for i in range(6):
            a = i / 6 * TAU + 0.4
            orn_ball(B(m, 'cloudd9', True), pol(rr * 0.62, a, zc + 1.9), 2.1, sub=2)
        orn_ball(B(m, 'cloud9', True), (0, 0, zc + 3.6), 2.3, sub=2)
        for i in range(5):
            a = i / 5 * TAU + 0.9
            orn_ball(B(m, 'cloud9', True), pol(rr * 0.62 + 0.4, a, zc + 2.7), 1.25, sub=2)
        # éclairs qui tombent du nuage, collés au ras de la coquille sans la toucher
        for i in range(4):
            a = i / 4 * TAU + TAU / 8
            zt, zb = zc - 0.7, zc - 4.5
            rt = rmax(m, zt) + 1.2
            rb = max(rmax(m, z) for z in (zb, zb + 1, zb + 2, zb + 3)) + 1.3
            n = Vector((math.cos(a), math.sin(a), 0))
            bolt(m, 'yellow9', pol(rt, a, zt), pol(rb, a, zb), n, width=0.8, thick=0.4)
        twinkle(m, 'yellow9', (0, 0, zc + 7.0), 2.2, core='G:gwhite9', thick=0.4)
    for s, g in ((1, 'WingR'), (-1, 'WingL')):
        with layer(m, g):
            zr = 8.4
            r = rs(m, 0 if s > 0 else math.pi, zr) - 0.8
            root = Vector((s * r, 0.2, zr))
            for k, (ang, L, w) in enumerate(((24, 8.4, 0.85), (0, 9.4, 0.85), (-26, 7.2, 0.8))):
                d = Vector((s * math.cos(math.radians(ang)), 0, math.sin(math.radians(ang))))
                bolt(m, 'yellow9', root + d * 0.6 + Vector((0, 0.12 * k, 0)), root + d * L + Vector((0, 0.12 * k, 0)),
                     (0, -1, 0), width=w, thick=0.45, mirror=(s < 0))
            puff(m, root + Vector((s * 0.9, -0.4, 0.2)), 1.25, lo='cloudd9', hi='cloud9', along=(0, 1, 0))
    return build(m, 'Egg_R9_T5', P9, off)


def build_T6(off):
    """Plasma Egg : coquille sombre fendue de plasma jaune et violet, cornes, orbe au sommet,
    ailes d'orage, orbite de boules d'énergie."""
    W, H = SIZES[6]
    m = Vox(H, seed=906)
    egg_body(m, W, H, 'night9', 9061)
    m.paint(lambda x, y, z: vnoise(x, y, z, 61, 4.5) > 0.25, 'nightl9')
    m.paint(lambda x, y, z: z <= 3.6 + 1.2 * math.sin(math.atan2(y, x) * 3), 'storm9')
    cracks(m, 6, 3, H - 9, a0=-math.pi / 2)
    # cornes
    front = -math.pi / 2
    for s in (1, -1):
        horn(m, front + s * 1.0, H - 6.0, 7.0, 1.15, key='violetl9', tipkey='yellow9', out=0.7, up=1.0, curl=0.35)
    # orbe de plasma au sommet, tenu par trois griffes d'or
    top = H - 0.5
    for i in range(3):
        a = i / 3 * TAU + 0.3
        orn_sweep(B(m, 'gold9', True), [pol(1.0, a, top - 1.0), pol(1.6, a, top + 0.9), pol(1.0, a, top + 2.4)],
                  [0.42, 0.36, 0.14], sides=8)
    orn_ball(B(m, 'G:gviolet9', True), (0, 0, top + 1.8), 1.45, sub=2)
    orn_torus(B(m, 'yellow9', True), (0, 0, top + 1.8), 1.95, 0.22, tilt=0.5, seg=32, sides=6)
    nest(m, ['nightl9', 'violetl9', 'yellowd9'], 20)
    for a in (-2.0, 0.2, 2.4):
        r = rss(m, a, 1.0) + 0.9
        orn_ball(B(m, 'G:gyellow9', True), pol(r, a, 1.0), 0.5, sub=1)
    for s, g in ((1, 'WingR'), (-1, 'WingL')):
        with layer(m, g):
            r = rs(m, 0 if s > 0 else math.pi, 12.5) - 0.9
            tips, P, nrm = fin(m, (s * r, 0.4, 12.5), s, [(60, 8.0), (36, 10.2), (12, 10.8), (-12, 9.2), (-34, 7.0)],
                               'violetd9', 'yellow9', 'G:gyellow9', notch=0.62, ray_r=0.4, tip_r=0.38)
            bolt(m, 'yellow9', P(26, 3.4) - nrm * 0.25, P(22, 8.6) - nrm * 0.25, -nrm, width=0.75, thick=0.3,
                 mirror=(s < 0))
    with layer(m, 'Orbit'):
        for i in range(6):
            a = i / 6 * TAU + 0.3
            zz = 3.0 + (i % 3) * 1.4
            if i % 2 == 0:
                energy_ball(m, 'G:gyellow9', 'violetl9', pol(W / 2 + 4.8, a, zz), 0.85)
            else:
                energy_ball(m, 'G:gviolet9', 'yellow9', pol(W / 2 + 4.8, a, zz), 0.8, tilt=-0.5)
    return build(m, 'Egg_R9_T6', P9, off)


def build_T7(off):
    """Tempest Egg : bandes de la nuit à l'éclair, médaillons de gemmes, collier, couronne de nuages et d'éclairs,
    halo, grandes ailes d'orage, anneau d'or en orbite avec boules d'énergie, nuages et éclairs."""
    W, H = SIZES[7]
    m = Vox(H, seed=907)
    egg_body(m, W, H, 'violet9', 9071)
    seq = ['night9', 'violetd9', 'violet9', 'violetl9', 'lilac9', 'cloud9']
    edges = [4.6, 9.6, 14.8, 19.8, 24.2]
    for c in m.surface():
        x, y, z = c
        th = math.atan2(y, x)
        idx, line = 0, False
        for i, e in enumerate(edges):
            f = (4 * th / TAU + i * 0.3) % 1.0
            lim = e + 1.6 * (2 * abs(f - 0.5)) - 0.8
            if z > lim:
                idx = i + 1
                line = (i in (1, 3)) and z <= lim + 1
        m.cells[c] = 'yellow9' if line else seq[idx]
    glow_dots(m, 'G:gcyan9', 12, lambda x, y, z: 1 <= z <= 8, mind=3.6)
    front = -math.pi / 2
    medallion(m, front, 11.5, 2.7, 'gemy9')
    medallion(m, front + 0.72, 12.0, 1.55, 'gemc9')
    medallion(m, front - 0.72, 12.0, 1.55, 'gemc9')
    medallion(m, front + math.pi, 11.5, 2.1, 'gemv9')
    necklace(m, 'cyan9', lambda a: 17.6 - 1.7 * abs(math.sin(3 * (a - front))), 0.8, sub=1, lift=0.12,
             bead='gold9', br=0.38, keep=lambda a: abs(math.cos(a)) < 0.72)
    nest(m, ['gold9', 'goldl9', 'violetl9', 'goldd9'], 24)
    nest_pearls(m, 'cyan9', 7, pr=0.7, z=1.5)
    with layer(m, 'Crown'):
        zc = H - 6.5
        sk = (1, 3, 5, 7)
        Rc = crown(m, zc, 8, ['gemc9', 'gemv9', 'gemy9', 'gemw9'], tall=4.4, short=2.8, a0=TAU / 16, ring_r=0.58,
                   gem_r=0.9, cone_k=1.3, skip=sk)
        for i in sk:
            a = TAU / 16 + i / 8 * TAU
            n = Vector((math.cos(a), math.sin(a), 0))
            base = pol(Rc + 0.15, a, zc - 0.2)
            tipp = base + Vector((math.cos(a) * 1.0, math.sin(a) * 1.0, 4.4))
            bolt(m, 'yellow9', base, tipp, n, width=0.95, thick=0.45)
        for i in range(8):
            a = i / 8 * TAU + TAU / 16
            puff(m, pol(Rc + 0.5, a, zc - 1.35), 1.3, lo='lilac9', hi='cloud9', along=(-math.sin(a), math.cos(a), 0))
        twinkle(m, 'G:gyellow9', (0, 0, H - 0.5 + 2.6), 3.4, core='white9', thick=0.5, cross=False)
        twinkle(m, 'yellow9', (0, 0, H - 0.5 + 2.6), 2.8, core=None, thick=0.45, cross=False, normal=(1, 0, 0))
    with layer(m, 'Halo'):
        for i in range(6):
            orn_torus(B(m, ('G:gyellow9', 'white9', 'G:gviolet9')[i % 3], True), (0, 0, H + 8.6), 5.8, 0.46, tilt=0.42,
                      seg=48, sides=8, arc=(i / 6, (i + 1) / 6))
    for s, g in ((1, 'WingR'), (-1, 'WingL')):
        with layer(m, g):
            r = rs(m, 0 if s > 0 else math.pi, 16) - 1.0
            root = Vector((s * r, 0.5, 16))
            rays = [(58, 11.0), (42, 14.5), (26, 16.5), (9, 16.5), (-6, 14.0), (-14, 9.8)]
            tips, P, nrm = fin(m, root, s, rays, 'violetl9', 'yellow9', 'white9', notch=0.72, ray_r=0.42, tip_r=0.45,
                               lead='gold9', lead_r=0.7, thick=0.26)
            inner = [(a, L * 0.58) for a, L in rays]
            fin(m, root + Vector((0, -0.22, 0)), s, inner, 'violet9', 'gold9', None, notch=0.8, ray_r=0.3, thick=0.2)
            for a0, a1, l0, l1 in ((40, 35, 9.5, 14.0), (5, 0, 9.5, 14.2)):
                bolt(m, 'yellow9', P(a0, l0) - nrm * 0.3, P(a1, l1) - nrm * 0.3, -nrm, width=0.7, thick=0.3,
                     mirror=(s < 0))
            g0 = root + Vector((s * 2.2, -0.75 + 0.22 * 2.2, 1.0))
            orn_torus(B(m, 'gold9', True), g0, 0.95, 0.26, axis=(0, -1, 0), seg=24, sides=7)
            orn_gem(B(m, 'gemc9', False), g0 + Vector((0, -0.1, 0)), 0.8, direction=(0, -1, 0))
            orn_ball(B(m, 'goldd9', True), g0 + Vector((0, 0.3, 0)), 0.95, scale=(1, 0.5, 1), sub=1)
    with layer(m, 'Orbit'):
        Ro, zo, tl = 14.2, 5.2, 0.13
        rot = orn_torus(B(m, 'gold9', True), (0, 0, zo), Ro, 0.26, tilt=tl, seg=64, sides=7)
        for i in range(6):
            a = i / 6 * TAU
            p = Vector((0, 0, zo)) + rot @ Vector((Ro * math.cos(a), Ro * math.sin(a), 0))
            energy_ball(m, 'G:gyellow9' if i % 2 == 0 else 'G:gviolet9', 'gold9', p, 0.78, tilt=0.9)
        for i in range(3):
            a = i / 3 * TAU + 0.5
            puff(m, pol(17.4, a, 2.8 + i * 1.6), 1.35, lo='lilac9', hi='cloud9', along=(-math.sin(a), math.cos(a), 0))
            b = a + TAU / 6
            c = pol(17.2, b, 7.6 - i * 1.6)
            bolt(m, 'yellow9', c + Vector((0, 0, 1.7)), c - Vector((0, 0, 1.7)), (math.cos(b), math.sin(b), 0),
                 width=0.9, thick=0.38)
    return build(m, 'Egg_R9_T7', P9, off)


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
    drop('Egg_R9_T%d' % n)
    random.seed(900 + n)
    coll = BUILDERS[n]((OFFSETS[n], 0, 0))
    obs = [o for o in coll.objects if o.type == 'MESH']
    for o in list(obs):
        if not len(o.data.vertices):
            bpy.data.objects.remove(o, do_unlink=True)
    obs = [o for o in coll.objects if o.type == 'MESH']
    tris = sum(len(p.vertices) - 2 for o in obs for p in o.data.polygons)
    zs = [(o.matrix_world @ v.co).z for o in obs for v in o.data.vertices]
    xs = [(o.matrix_world @ v.co).x for o in obs for v in o.data.vertices]
    print('Egg_R9_T%d : %d objets, %d triangles, x %.1f..%.1f, z %.2f..%.2f, max tris/objet %d' % (
        n, len(obs), tris, min(xs), max(xs), min(zs), max(zs),
        max(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in obs)))
    return coll


def build_all():
    for n in sorted(BUILDERS):
        build_one(n)


# CONTRÔLES -----------------------------------------------------------------------------------

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
    # ailes : positions pendant le battement
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
    # anneaux balayés
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
    # ailes contre ornements fixes
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


print("eggs_r9 chargé")
