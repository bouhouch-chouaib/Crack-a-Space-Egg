# Œufs de l'anneau 10 « Clockwork Belt » (ceinture d'animaux mécaniques à remonter : laiton, cuivre, acier bleuté,
# rivets, rouages, clés à remonter, cadrans, tuyaux de vapeur, lueurs turquoise), même méthode que les anneaux 1 à 9 :
# corps en briques (voxkit.Vox) + ornements lisses (_ORN_), groupes animés (_ACrown_, _AOrbit_, _AHalo_, _AWingL_,
# _AWingR_). Charger voxkit.py avant ce fichier, puis build_all() ou build_one(n).
# clash(coll) vérifie qu'un groupe qui tourne ne traverse ni les ailes qui battent ni les ornements fixes ;
# neon_share(coll) donne la part de surface en néon (à garder sous 5 %).

TAU = math.tau

P10 = dict(
    brass10='#E0A84A', brassl10='#F5CF7A', brassd10='#B07A2E', brassx10='#7E5420',
    copper10='#C8703A', copperl10='#E39A62', copperd10='#8E4A26',
    steel10='#7C8C9C', steell10='#A8B6C4', steeld10='#3E4A58', steelx10='#2C3540',
    turq10='#5AE6D2', turqd10='#2FA898', steam10='#EAF8F6', steamd10='#BFD6D3',
    red10='#C83A3A', redd10='#8E2626', ink10='#2A2F38',
    gemt10='#3FE8D4', gemr10='#E04646',
    gturq10='#33D9C4', gsteam10='#F2FFFD', gbrass10='#FFD98A',
)

OFFSETS = {2: 0, 3: 34, 4: 70, 5: 112, 6: 162, 7: 222}
SIZES = {2: (11, 15), 3: (11, 17), 4: (13, 19), 5: (15, 22), 6: (17, 25), 7: (21, 29)}


# BRUIT ET PROFIL (comme les anneaux 8 et 9) --------------------------------------------------

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


# PIÈCES MÉCANIQUES ---------------------------------------------------------------------------

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


def orn_annulus(bm, center, axis, outer, inner, thick):
    """Prisme percé : contour extérieur et intérieur (même nombre de points, dans le plan de l'axe)."""
    rot = _orient(axis)
    c = Vector(center)

    def V(x, y, z):
        return bm.verts.new(c + rot @ Vector((x, y, z)))

    n = len(outer)
    ot = [V(x, y, thick / 2) for x, y in outer]
    ob = [V(x, y, -thick / 2) for x, y in outer]
    it = [V(x, y, thick / 2) for x, y in inner]
    ib = [V(x, y, -thick / 2) for x, y in inner]
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((ot[i], ot[j], it[j], it[i]))
        bm.faces.new((ob[j], ob[i], ib[i], ib[j]))
        bm.faces.new((ob[i], ob[j], ot[j], ot[i]))
        bm.faces.new((it[i], it[j], ib[j], ib[i]))
    return rot


def orn_cyl(bm, base, direction, length, r0, r1=None, sides=16):
    """Cylindre (ou tronc de cône si r1) fermé, de base vers base + direction * length."""
    rot = _orient(direction)
    r1 = r0 if r1 is None else r1
    vs = bmesh.ops.create_cone(bm, cap_ends=True, segments=sides, radius1=r0, radius2=r1, depth=length)['verts']
    bmesh.ops.transform(bm, matrix=Matrix.Translation(Vector(base)) @ rot @ Matrix.Translation((0, 0, length / 2)),
                        verts=vs)


def gear_pts(R, teeth, depth, phase=0.0):
    out = []
    for i in range(teeth):
        for f, r in ((0.0, R - depth), (0.14, R), (0.48, R), (0.62, R - depth)):
            a = phase + (i + f) / teeth * TAU
            out.append((r * math.cos(a), r * math.sin(a)))
    return out


def gear(m, key, c, axis, R, teeth=None, thick=None, hub=None, cap=None, spokes=None, phase=0.0, gem=None,
         post=0.0, post_key=None):
    """Rouage : couronne dentée percée, rayons, moyeu, rivet (ou gemme) au centre.
    post : axe qui part de l'arrière du moyeu (pour le tenir contre la coquille)."""
    teeth = teeth or max(7, int(round(R * 4.4)))
    thick = thick or max(0.32, R * 0.26)
    depth = min(0.6, max(0.24, R * 0.2))
    hub = hub or key
    c = Vector(c)
    rot = _orient(axis)
    n = rot @ Vector((0, 0, 1))
    outer = gear_pts(R, teeth, depth, phase)
    nsp = spokes if spokes is not None else (0 if R < 1.15 else 4 if R < 2.6 else 6)
    rin = (R - depth) * (0.66 if nsp else 0.5)
    inner = [(rin * math.cos(math.atan2(y, x)), rin * math.sin(math.atan2(y, x))) for x, y in outer]
    orn_annulus(B(m, key, False), c, n, outer, inner, thick)
    rh = max(0.2, R * 0.24)
    if nsp:
        w = max(0.12, R * 0.075)
        for k in range(nsp):
            a = phase + (k + 0.5) / nsp * TAU
            d = rot @ Vector((math.cos(a), math.sin(a), 0))
            s = n.cross(d)
            orn_plate(B(m, key, False), [(rh * 0.6, -w), (rin + 0.12, -w), (rin + 0.12, w), (rh * 0.6, w)], c, d, s, n,
                      thick * 0.72)
    else:
        orn_cyl(B(m, hub, False), c - n * thick * 0.3, n, thick * 0.6, rin + 0.04, sides=max(12, len(outer) // 2))
    orn_cyl(B(m, hub, False), c - n * thick * 0.8, n, thick * 1.6, rh, sides=12)
    if gem:
        orn_gem(B(m, gem, False), c + n * (thick * 0.8 + rh * 0.35), rh * 1.05, direction=n)
    else:
        orn_ball(B(m, cap or hub, True), c + n * thick * 0.8, rh * 0.6, sub=1)
    if post > 0:
        orn_cyl(B(m, post_key or hub, False), c - n * (thick * 0.8 + post), n, post, rh * 0.8, sides=12)
    return n


def body_gear(m, key, th, z, R, hub='brass10', gem=None, teeth=None, phase=0.0, spokes=None):
    """Rouage posé sur la coquille (face vers l'extérieur), tenu par son axe."""
    n = Vector((math.cos(th), math.sin(th), 0))
    k = R * 0.8 / max(rs(m, th, z), 1.0)
    r0 = max(rs(m, th + da, z + dz) for da in (-k, 0, k) for dz in (-R * 0.8, 0, R * 0.8))
    thick = max(0.32, R * 0.26)
    c = pol(r0 + thick * 0.5 + 0.15, th, z)
    gear(m, key, c, n, R, hub=hub, gem=gem, teeth=teeth, phase=phase, spokes=spokes, post=1.4)
    return c


def hexnut(m, key, c, n, r, thick=None, hole=True, washer=None):
    """Écrou (percé) ou tête de boulon (pleine) hexagonale, face vers n ; rondelle derrière si washer."""
    n = Vector(n).normalized()
    thick = thick or r * 0.7
    c = Vector(c)
    hexo = [(r * math.cos(i / 6 * TAU + math.pi / 6), r * math.sin(i / 6 * TAU + math.pi / 6)) for i in range(6)]
    if hole:
        orn_annulus(B(m, key, False), c, n, hexo, [(x * 0.45, y * 0.45) for x, y in hexo], thick)
    else:
        rot = _orient(n)
        orn_plate(B(m, key, False), hexo, c, rot @ Vector((1, 0, 0)), rot @ Vector((0, 1, 0)), n, thick)
    if washer:
        orn_cyl(B(m, washer, False), c - n * thick * 0.75, n, thick * 0.5, r * 1.22, sides=16)


def body_bolt(m, key, th, z, r=0.55, washer='brassd10'):
    n = Vector((math.cos(th), math.sin(th), 0))
    k = r / max(rs(m, th, z), 1.0)
    r0 = max(rs(m, th + da, z + dz) for da in (-k, 0, k) for dz in (-r, 0, r))
    hexnut(m, key, pol(r0 + 0.38, th, z), n, r, thick=0.45, hole=False, washer=washer)


def rivet(m, key, th, z, r=0.3):
    orn_ball(B(m, key, True), pol(rs(m, th, z) - r * 0.25, th, z), r, sub=1)


def rivet_ring(m, key, z, n, r=0.3, a0=0.0, keep=None):
    for i in range(n):
        a = a0 + i / n * TAU
        if keep and not keep(a):
            continue
        rivet(m, key, a, z, r)


def belt(m, key, z, r, lift=0.1, n=64, smooth=3):
    """Ceinture lisse qui épouse la coquille à la hauteur z (tube fermé). Renvoie les points du tracé."""
    A = [i / n * TAU for i in range(n)]
    raw = [max(rs(m, a, z + dz) for dz in (-r * 0.8, 0, r * 0.8)) for a in A]
    env = [max(raw[(i + k) % n] for k in (-2, -1, 0, 1, 2)) for i in range(n)]
    sm = [max(env[i] - 0.25, sum(env[(i + k) % n] for k in range(-smooth, smooth + 1)) / (2 * smooth + 1))
          for i in range(n)]
    P = [pol(sm[i] + r * 0.55 + lift, A[i], z) for i in range(n)]
    bm = B(m, key, True)
    rings = []
    sides = 10
    for i in range(n):
        tan = (P[(i + 1) % n] - P[i - 1]).normalized()
        side = tan.cross(Vector((0, 0, 1))).normalized()
        up = side.cross(tan).normalized()
        rings.append([bm.verts.new(P[i] + (side * math.cos(j / sides * TAU) + up * math.sin(j / sides * TAU)) * r)
                      for j in range(sides)])
    for i in range(n):
        a, b = rings[i], rings[(i + 1) % n]
        for j in range(sides):
            k = (j + 1) % sides
            bm.faces.new((a[j], a[k], b[k], b[j]))
    return P


def clock(m, th, z, R, face='steam10', rim='brass10', back='brassd10', tick='ink10', big='red10',
          hands=(('ink10', 300), ('red10', 60)), gems=None, depth=None):
    """Cadran d'horloge posé sur la coquille : fond, cerclage, 12 graduations (ou gemmes aux quarts), deux aiguilles."""
    n = Vector((math.cos(th), math.sin(th), 0))
    k = R * 0.8 / max(rs(m, th, z), 1.0)
    r0 = max(rs(m, th + da, z + dz) for da in (-k, 0, k) for dz in (-R * 0.75, 0, R * 0.75))
    c = pol(r0 + 0.15, th, z)
    n, u, v = frame(n)
    depth = depth or max(1.6, R * 0.5)
    orn_cyl(B(m, back, False), c - n * depth, n, depth, R * 0.92, sides=32)
    orn_cyl(B(m, face, False), c - n * 0.1, n, 0.32, R, sides=40)
    tr = max(0.2, R * 0.1)
    orn_torus(B(m, rim, True), c + n * 0.12, R + tr * 0.4, tr, axis=n, seg=48, sides=8)
    f = c + n * 0.24
    for i in range(12):
        a = i / 12 * TAU
        d = v * math.cos(a) + u * math.sin(a)
        s = n.cross(d)
        if gems and i % 3 == 0:
            orn_gem(B(m, gems, False), f + d * R * 0.74 + n * 0.1, R * 0.11, direction=n)
            continue
        q = i % 3 == 0
        L, w = R * (0.2 if q else 0.12), R * (0.05 if q else 0.032)
        orn_plate(B(m, big if q else tick, False), [(-w, R * 0.86 - L), (w, R * 0.86 - L), (w, R * 0.86), (-w, R * 0.86)],
                  f, s, d, n, 0.12)
    for idx, (key, ang) in enumerate(hands):
        L = R * (0.5 if idx == 0 else 0.74)
        w = R * (0.075 if idx == 0 else 0.05)
        a = math.radians(ang)
        d = v * math.cos(a) + u * math.sin(a)
        s = n.cross(d)
        pts = [(-w, -R * 0.14), (w, -R * 0.14), (w, L * 0.76), (w * 2.3, L * 0.76), (0, L), (-w * 2.3, L * 0.76),
               (-w, L * 0.76)]
        orn_plate(B(m, key, False), pts, f + n * (0.1 + idx * 0.13), s, d, n, 0.13)
    orn_ball(B(m, rim, True), f + n * 0.36, max(0.22, R * 0.1), sub=1)
    return c


def windkey(m, base, d, L, S, side=(1, 0, 0), key='brass10', light='brassl10', dark='brassd10'):
    """Clé à remonter : collerette, tige, papillon à deux lobes (trous foncés), bouton."""
    base, d = Vector(base), Vector(d).normalized()
    side = Vector(side)
    side = (side - d * side.dot(d)).normalized()
    nrm = side.cross(d)
    orn_cyl(B(m, dark, False), base - d * 0.6 * S, d, 0.95 * S, 0.62 * S, sides=14)
    orn_torus(B(m, light, True), base + d * 0.3 * S, 0.6 * S, 0.14 * S, axis=d, seg=24, sides=6)
    orn_cyl(B(m, key, False), base, d, L + 0.4 * S, 0.27 * S, sides=12)
    orn_torus(B(m, light, True), base + d * L * 0.55, 0.31 * S, 0.1 * S, axis=d, seg=20, sides=6)
    top = base + d * L
    circ = [(-0.95 * S, 0.95 * S, 0.8 * S), (0.95 * S, 0.95 * S, 0.8 * S), (0.0, 0.62 * S, 0.5 * S)]
    O = (0.0, 0.85 * S)
    pts = []
    for i in range(64):
        ph = i / 64 * TAU
        dx, dy = math.cos(ph), math.sin(ph)
        best = 0.0
        for cx, cy, r in circ:
            ox, oy = O[0] - cx, O[1] - cy
            b = ox * dx + oy * dy
            disc = b * b - (ox * ox + oy * oy - r * r)
            if disc >= 0:
                best = max(best, -b + math.sqrt(disc))
        pts.append((O[0] + dx * best, O[1] + dy * best))
    orn_plate(B(m, key, False), pts, top, side, d, nrm, 0.42 * S)
    for sx in (-1, 1):
        cc = top + side * sx * 1.0 * S + d * 0.98 * S
        orn_cyl(B(m, dark, False), cc - nrm * 0.24 * S, nrm, 0.48 * S, 0.36 * S, sides=16)
        orn_torus(B(m, light, True), cc, 0.62 * S, 0.12 * S, axis=nrm, seg=28, sides=6)
    orn_ball(B(m, light, True), top + d * 0.15 * S, 0.34 * S, sub=1)
    return top


def spring(m, key, base, d, R, r, turns, length, cap=None, cap_r=None):
    """Ressort à boudin le long de d ; bille au bout si cap."""
    base, d = Vector(base), Vector(d).normalized()
    rot = _orient(d)
    N = int(turns * 9)
    pts = []
    for i in range(N + 1):
        f = i / N
        a = f * turns * TAU
        pts.append(base + rot @ Vector((R * math.cos(a), R * math.sin(a), f * length)))
    orn_sweep(B(m, key, True), pts, [r] * len(pts), sides=8)
    if cap:
        orn_ball(B(m, cap, True), base + d * (length + (cap_r or R) * 0.8), cap_r or R * 1.1, sub=2)
    return pts


def coil(m, key, z0, z1, turns, r=0.34, lift=0.22, a0=0.0):
    """Ressort enroulé autour de la coquille."""
    N = int(turns * 12)
    A = [a0 + i / N * turns * TAU for i in range(N + 1)]
    Z = [z0 + (z1 - z0) * i / N for i in range(N + 1)]
    raw = [rs(m, a, z) for a, z in zip(A, Z)]
    sm = [sum(raw[max(0, i - 3):i + 4]) / len(raw[max(0, i - 3):i + 4]) for i in range(N + 1)]
    pts = [pol(sm[i] + r * 0.5 + lift, A[i], Z[i]) for i in range(N + 1)]
    orn_sweep(B(m, key, True), pts, [r] * len(pts), sides=8)
    for p in (pts[0], pts[-1]):
        orn_ball(B(m, key, True), p, r * 1.45, sub=1)
    return pts


def pipe(m, key, pts, r, flange='copperd10'):
    """Tuyau lisse avec une bride à chaque bout."""
    pts = [Vector(p) for p in pts]
    orn_sweep(B(m, key, True), pts, [r] * len(pts), sides=10)
    for p, q in ((pts[0], pts[1]), (pts[-1], pts[-2])):
        d = (p - q).normalized()
        orn_torus(B(m, flange, True), p - d * r * 0.4, r * 1.05, r * 0.4, axis=d, seg=20, sides=6)


def piston(m, th, z0, h, rr, sleeve='steel10', rod='steell10', cap='brass10', band='brassd10'):
    """Piston debout contre la coquille : cylindre, tige, tête, colliers, attache."""
    r = rs(m, th, z0 + h * 0.3) + rr * 0.55
    n = Vector((math.cos(th), math.sin(th), 0))
    b = pol(r, th, z0)
    up = Vector((0, 0, 1))
    hs = h * 0.6
    orn_cyl(B(m, sleeve, False), b, up, hs, rr, sides=16)
    orn_cyl(B(m, band, False), b - up * 0.2, up, 0.6, rr * 1.18, sides=16)
    orn_cyl(B(m, band, False), b + up * (hs - 0.45), up, 0.6, rr * 1.18, sides=16)
    orn_cyl(B(m, rod, False), b + up * hs, up, h - hs, rr * 0.42, sides=12)
    orn_cyl(B(m, cap, False), b + up * (h - 0.1), up, 0.55, rr * 0.95, sides=16)
    orn_ball(B(m, cap, True), b + up * (h + 0.45), rr * 0.45, sub=1)
    for zz in (z0 + hs * 0.12, z0 + hs * 0.88):
        orn_torus(B(m, band, True), pol(r, th, zz), rr * 1.06, rr * 0.16, seg=24, sides=6)
    return b, r


def stack(m, base, h, r0, r1, key='copper10', rim='brass10', band='copperd10', puffs=3, lean=(0, 0)):
    """Cheminée : tronc de cône, bagues, rebord, panache de vapeur."""
    base = Vector(base)
    up = Vector((lean[0], lean[1], 1)).normalized()
    orn_cyl(B(m, key, False), base, up, h, r0, r1, sides=16)
    top = base + up * h
    orn_torus(B(m, rim, True), top, r1 * 1.08, max(0.2, r1 * 0.24), axis=up, seg=28, sides=7)
    orn_torus(B(m, band, True), base + up * h * 0.45, (r0 + r1) / 2 * 1.03, 0.18, axis=up, seg=28, sides=6)
    p = top + up * r1 * 0.5
    for k in range(puffs):
        rr = r1 * (0.85 + 0.38 * k)
        orn_ball(B(m, 'steam10', True), p + Vector((0.25 * k, -0.1 * k, 0)), rr, sub=2)
        orn_ball(B(m, 'steamd10', True), p + Vector((0.25 * k - rr * 0.45, 0.2, -rr * 0.3)), rr * 0.7, sub=2)
        p = p + up * rr * 1.25 + Vector((0.3, 0, 0))
    return top


def porthole(m, th, z, R, glow='G:gturq10', rim='brass10', bolts='brassd10', back='steeld10'):
    """Hublot : vitre turquoise lumineuse, cerclage de laiton boulonné, croisillon."""
    n = Vector((math.cos(th), math.sin(th), 0))
    k = R * 0.8 / max(rs(m, th, z), 1.0)
    r0 = max(rs(m, th + da, z + dz) for da in (-k, 0, k) for dz in (-R * 0.8, 0, R * 0.8))
    c = pol(r0 + 0.1, th, z)
    n, u, v = frame(n)
    orn_cyl(B(m, back, False), c - n * 1.5, n, 1.5, R * 1.08, sides=24)
    orn_cyl(B(m, glow, False), c - n * 0.25, n, 0.4, R * 0.9, sides=24)
    orn_torus(B(m, rim, True), c + n * 0.1, R, R * 0.2, axis=n, seg=36, sides=8)
    for i in range(8):
        a = i / 8 * TAU + TAU / 16
        orn_ball(B(m, bolts, True), c + n * 0.32 + (u * math.cos(a) + v * math.sin(a)) * R, R * 0.12, sub=1)
    w = R * 0.07
    for d in (u, v):
        s = n.cross(d)
        orn_plate(B(m, back, False), [(-R * 0.9, -w), (R * 0.9, -w), (R * 0.9, w), (-R * 0.9, w)], c + n * 0.02, d, s,
                  n, 0.16)
    orn_ball(B(m, 'steam10', True), c + n * 0.05 + (v - u) * R * 0.45, R * 0.13, sub=1)
    return c


def energy_ball(m, glow, ring, c, r, tilt=0.5):
    """Lampe turquoise : cœur lumineux et cerclage autour."""
    orn_ball(B(m, glow, True), c, r, sub=2)
    orn_torus(B(m, ring, True), c, r * 1.16, r * 0.2, tilt=tilt, seg=24, sides=6)


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


def teeth_edge(th, n=12, amp=0.7, phase=0.0):
    """Bord crénelé comme les dents d'un rouage (pour les bandes peintes)."""
    f = (n * th / TAU + phase) % 1.0
    return amp if f < 0.5 else -amp


# REPRIS DES ANNEAUX 8 ET 9 -------------------------------------------------------------------

def nest(m, keys, n, zlo=-0.55, zhi=2.0, tube=(0.32, 0.48), off=(0.15, 0.75)):
    """Nid de fils et de tuyaux enroulés autour de la base (comme les autres anneaux)."""
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


def gear_litter(m, keys, n, Rr=(0.8, 1.25), hub='brassl10', gem=None):
    """Petits rouages posés au pied de l'œuf, appuyés contre la coquille (à la place des perles des autres anneaux)."""
    rnd = m.rnd
    a0 = rnd.uniform(0, TAU)
    for i in range(n):
        a = a0 + i / n * TAU + rnd.uniform(-0.25, 0.25)
        Rg = rnd.uniform(*Rr)
        nn = Vector((math.cos(a), math.sin(a), 1.0)).normalized()
        r = rss(m, a, 2.2) + Rg * 0.72 + 0.35
        gear(m, keys[i % len(keys)], pol(r, a, Rg * 0.72 - 0.1), nn, Rg, hub=hub,
             gem=(gem if gem and i % 2 == 0 else None), phase=rnd.uniform(0, 1))


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


def mech_wing(m, root, s, rays, mem='steel10', ray='brass10', tip='brassl10', inner=None, gear_key='brass10',
              gear_R=1.6, gem=None, rivets='brassd10', thick=0.26, notch=0.66, ray_r=0.4, tip_r=0.42, lead=None,
              lead_r=0.6):
    """Aile mécanique : voile d'acier (ou de cuivre) tendue sur des baleines de laiton, rivets le long des baleines,
    rouage à la racine. inner = (voile, baleines) d'une seconde aile plus courte devant."""
    root = Vector(root)
    tips, P, nrm = fin(m, root, s, rays, mem, ray, tip, notch=notch, ray_r=ray_r, tip_r=tip_r, thick=thick,
                       lead=lead, lead_r=lead_r)
    if inner:
        fin(m, root + Vector((0, -0.24, 0)), s, [(a, L * 0.58) for a, L in rays], inner[0], inner[1], None,
            notch=0.8, ray_r=ray_r * 0.75, thick=thick * 0.8)
    if rivets:
        for a, L in rays[1:-1]:
            for f in (0.45, 0.7):
                orn_ball(B(m, rivets, True), P(a, L * f) - nrm * (thick * 0.5 + 0.12), 0.2, sub=1)
    g = root + Vector((s * gear_R * 0.95, -0.45, gear_R * 0.15))
    gear(m, gear_key, g, (0, -1, 0), gear_R, hub='brassd10', gem=gem, phase=0.1)
    return tips, P, nrm


def medallion(m, th, z, R, gem_key, gold='brass10', dark='brassd10'):
    """Gemme sertie dans un anneau de laiton, posée sur la coquille."""
    n = Vector((math.cos(th), math.sin(th), 0))
    r0 = max(rs(m, th + da, z + dz) for da in (-R / 9, 0, R / 9) for dz in (-R * 0.7, 0, R * 0.7))
    c = pol(r0 + 0.12, th, z)
    orn_torus(B(m, gold, True), c, R, R * 0.24, axis=n, seg=32, sides=8)
    orn_cone(B(m, dark, True), c + n * R * 0.1, -n, R * 1.2, R * 0.98, sides=16)
    orn_gem(B(m, gem_key, False), c + n * R * 0.22, R * 0.84, direction=n)
    return c


def gear_crown(m, z, n, Rg, keys, ring='brass10', ring2='brassd10', gems=None, hub='brassd10', lift=0.85, out=0.5):
    """Couronne de rouages debout autour de la pointe (face vers l'extérieur), sur un anneau de laiton."""
    Rc = rmax(m, z) + out
    orn_torus(B(m, ring, True), (0, 0, z), Rc, 0.44, seg=48, sides=8)
    orn_torus(B(m, ring2, True), (0, 0, z - 0.5), Rc * 0.99, 0.28, seg=48, sides=6)
    for i in range(n):
        a = i / n * TAU
        c = pol(Rc, a, z + Rg * lift)
        gear(m, keys[i % len(keys)], c, (math.cos(a), math.sin(a), 0), Rg, hub=hub,
             gem=(gems[(i // 2) % len(gems)] if gems and i % 2 == 0 else None), phase=i * 0.37)
    return Rc


# LES SIX ŒUFS --------------------------------------------------------------------------------

FRONT = -math.pi / 2


def build_T2(off):
    """Cog Egg : laiton, ceinture de cuivre rivetée, un rouage d'acier sur le côté, écrou au sommet."""
    W, H = SIZES[2]
    m = Vox(H, seed=1002)
    egg_body(m, W, H, 'brass10', 10021)
    m.paint(lambda x, y, z: z <= 2.6 + 0.9 * math.sin(math.atan2(y, x) * 3 + 0.5), 'brassd10')
    m.paint(lambda x, y, z: z >= H - 3.4 + teeth_edge(math.atan2(y, x), 10, 0.5), 'brassl10')
    m.paint(lambda x, y, z: 5.5 <= z <= 6.5, 'copper10')
    rivet_ring(m, 'copperl10', 6.0, 11, r=0.3, a0=0.2)
    body_gear(m, 'steel10', FRONT + 0.8, 9.6, 2.3, hub='brass10', teeth=11)
    body_gear(m, 'copper10', FRONT + 1.25, 7.0, 1.1, hub='brassd10', teeth=8, phase=0.3)
    top = H - 0.5
    hexnut(m, 'brass10', (0, 0, top + 0.25), (0, 0, 1), 1.0, thick=0.6, hole=False, washer='brassd10')
    orn_ball(B(m, 'brassl10', True), (0, 0, top + 0.7), 0.42, sub=1)
    nest(m, ['brassd10', 'copperd10', 'steel10'], 15)
    return build(m, 'Egg_R10_T2', P10, off)


def build_T3(off):
    """Spring Egg : acier bleuté, ressort de cuivre enroulé, deux ressorts à boule sur les flancs,
    clé à remonter au sommet."""
    W, H = SIZES[3]
    m = Vox(H, seed=1003)
    egg_body(m, W, H, 'steel10', 10031)
    m.paint(lambda x, y, z: vnoise(x + 20, y, z, 31, 4.0) > 0.4, 'steell10')
    m.paint(lambda x, y, z: z <= 2.4 + 0.8 * math.sin(math.atan2(y, x) * 3), 'steeld10')
    m.paint(lambda x, y, z: 4.0 <= z <= 5.0, 'copper10')
    m.paint(lambda x, y, z: z >= H - 3.2, 'copper10')
    m.paint(lambda x, y, z: z == H - 4, 'copperd10')
    rivet_ring(m, 'brass10', 4.5, 10, r=0.3)
    coil(m, 'copperl10', 6.2, H - 5.0, 2.6, r=0.38, a0=FRONT + 0.3)
    for s in (1, -1):
        th = 0 if s > 0 else math.pi
        z = 5.6
        d = Vector((math.cos(th), math.sin(th), 0.55)).normalized()
        b = pol(rs(m, th, z) - 0.5, th, z)
        orn_cyl(B(m, 'brassd10', False), b - d * 0.2, d, 0.75, 0.75, sides=14)
        spring(m, 'copper10', b + d * 0.4, d, 0.72, 0.2, 5, 3.1, cap='brassl10', cap_r=0.7)
    top = H - 0.5
    windkey(m, (0, 0, top - 0.2), (0, 0, 1), 2.0, 1.3, side=(1, 0, 0))
    nest(m, ['copperd10', 'steeld10', 'brassd10'], 13)
    gear_litter(m, ['brass10', 'copper10'], 3, Rr=(0.95, 1.2))
    return build(m, 'Egg_R10_T3', P10, off)


def build_T4(off):
    """Bolt Egg : plaques d'acier rivetées, ceinture de laiton boulonnée, hublot turquoise, gros écrou au sommet,
    écrous et rouages en orbite."""
    W, H = SIZES[4]
    m = Vox(H, seed=1004)
    egg_body(m, W, H, 'steel10', 10041)
    seg = TAU / 6

    def panel(th):
        return int(math.floor(((th - FRONT + seg / 2) % TAU) / seg))

    for c in m.surface():
        x, y, z = c
        th = math.atan2(y, x)
        r = math.hypot(x, y)
        f = ((th - FRONT + seg / 2) % seg) / seg
        k = 'steell10' if (panel(th) + (z > 9)) % 2 == 0 else 'steel10'
        if z <= 2.8 + 0.6 * math.sin(th * 3):
            k = 'steeld10'
        elif z in (5, 14):
            k = 'steeld10'
        elif min(f, 1 - f) * r * seg < 0.5 and 5 < z < 14:
            k = 'steeld10'
        elif z >= H - 3.4:
            k = 'brass10'
        m.cells[c] = k
    for j in range(6):
        a = FRONT + seg / 2 + j * seg
        for z in (6.6, 12.4) if j not in (0, 5) else (6.6,):
            rivet(m, 'steell10', a, z, 0.28)
    for z in (5, 14):
        r = rmax(m, z)
        n = int(TAU * r / 1.7)
        rivet_ring(m, 'steell10', z, n, r=0.28, a0=0.1)
    zw = 9.4
    P = belt(m, 'brass10', zw, 0.6, n=64)
    belt(m, 'brassd10', zw - 0.72, 0.34, n=64, lift=-0.2)
    for i in range(8):
        p = P[(i * 8 + 4) % 64]
        n = Vector((p.x, p.y, 0)).normalized()
        hexnut(m, 'brassl10', p + n * 0.55, n, 0.5, thick=0.4, hole=False)
    porthole(m, FRONT, 12.0, 1.6)
    for th in (FRONT + math.pi * 0.6, FRONT - math.pi * 0.6, FRONT + math.pi):
        body_bolt(m, 'brass10', th, 12.0, r=0.62)
    top = H - 0.5
    hexnut(m, 'brass10', (0, 0, top + 0.35), (0, 0, 1), 1.35, thick=0.8, hole=True, washer='brassd10')
    orn_cyl(B(m, 'steell10', False), (0, 0, top - 0.4), (0, 0, 1), 2.2, 0.55, sides=12)
    for zz in (top + 1.05, top + 1.45):
        orn_torus(B(m, 'steel10', True), (0, 0, zz), 0.58, 0.1, seg=20, sides=6)
    nest(m, ['steeld10', 'brassd10', 'copperd10'], 16)
    gear_litter(m, ['steel10', 'brass10'], 4, Rr=(0.8, 1.15))
    with layer(m, 'Orbit'):
        Ro = W / 2 + 3.6
        for i in range(8):
            a = i / 8 * TAU + 0.2
            p = pol(Ro, a, 6.4 + 0.9 * math.sin(i * 1.7))
            n = Vector((math.cos(a), math.sin(a), 0))
            if i % 2 == 0:
                hexnut(m, 'brass10', p, n, 0.95, thick=0.6, hole=True)
            else:
                gear(m, 'steel10', p, n, 1.25, hub='brass10', phase=i * 0.2)
    return build(m, 'Egg_R10_T4', P10, off)


def build_T5(off):
    """Piston Egg : cuivre, quatre pistons d'acier, tuyaux de laiton, manomètre, gemme turquoise,
    couronne de rouages qui tourne autour d'une lampe turquoise."""
    W, H = SIZES[5]
    m = Vox(H, seed=1005)
    egg_body(m, W, H, 'copper10', 10051)
    m.paint(lambda x, y, z: vnoise(x, y + 30, z, 51, 4.0) > 0.35, 'copperd10')
    m.paint(lambda x, y, z: z <= 3.6 + teeth_edge(math.atan2(y, x), 12, 0.6), 'steeld10')
    m.paint(lambda x, y, z: z in (4, 5) or (z == 6 and teeth_edge(math.atan2(y, x), 16, 1) > 0), 'brass10')
    m.paint(lambda x, y, z: z >= 15.0 + teeth_edge(math.atan2(y, x), 12, 0.6, 0.25), 'brass10')
    m.paint(lambda x, y, z: z >= H - 3.0, 'brassl10')
    glow_dots(m, 'G:gturq10', 5, lambda x, y, z: 7 <= z <= 13 and y > -3, mind=4.0)
    rivet_ring(m, 'brassd10', 4.5, 12, r=0.32, a0=0.13)
    tops = []
    for th in (FRONT + 0.85, FRONT - 0.85, FRONT + math.pi - 0.85, FRONT + math.pi + 0.85):
        b, r = piston(m, th, 3.4, 8.0, 0.85)
        tops.append((th, r))
    # tuyaux : de chaque piston, ils remontent contre la coquille et y rentrent sous la couronne
    for th, r in tops:
        z0 = 3.4 + 8.0 * 0.6 - 0.6
        p0 = pol(r - 0.2, th, z0) + Vector((0, 0, 0))
        side = 0.35 if th % TAU < math.pi else -0.35
        pts = [p0 + Vector((0, 0, 0)), pol(r - 0.4, th + side * 0.3, z0 + 1.6),
               pol(rs(m, th + side * 0.6, 12.0) + 0.45, th + side * 0.6, 12.0),
               pol(rs(m, th + side * 0.75, 14.0) - 0.2, th + side * 0.75, 14.2)]
        pipe(m, 'brass10', pts, 0.36, flange='brassd10')
    clock(m, FRONT, 9.2, 2.0, hands=(('ink10', 0), ('red10', 115)))
    medallion(m, FRONT + math.pi, 9.0, 1.6, 'gemt10')
    # lampe turquoise au sommet, dans une cage de laiton
    top = H - 0.5
    orn_cyl(B(m, 'brassd10', False), (0, 0, top - 0.6), (0, 0, 1), 1.2, 1.25, sides=16)
    orn_ball(B(m, 'G:gturq10', True), (0, 0, top + 1.5), 1.0, sub=2)
    for i in range(4):
        a = i / 4 * TAU + TAU / 8
        orn_sweep(B(m, 'brass10', True), [pol(1.05, a, top + 0.4), pol(1.3, a, top + 1.5), pol(0.25, a, top + 2.75)],
                  [0.17, 0.17, 0.17], sides=7)
    orn_ball(B(m, 'brassl10', True), (0, 0, top + 2.85), 0.38, sub=1)
    nest(m, ['steeld10', 'brassd10', 'copperd10', 'brass10'], 18)
    gear_litter(m, ['brass10', 'steel10'], 4, Rr=(0.85, 1.25))
    with layer(m, 'Crown'):
        gear_crown(m, H - 5.6, 7, 1.55, ['brass10', 'copperl10'], gems=['gemt10'])
    return build(m, 'Egg_R10_T5', P10, off)


def build_T6(off):
    """Steam Egg : acier sombre et cuivre, trois cheminées qui fument, cadran d'horloge, tuyaux,
    ailes mécaniques, lampes turquoise et rouages en orbite."""
    W, H = SIZES[6]
    m = Vox(H, seed=1006)
    egg_body(m, W, H, 'steeld10', 10061)
    m.paint(lambda x, y, z: vnoise(x, y, z, 61, 4.5) > 0.3, 'steel10')
    m.paint(lambda x, y, z: z <= 3.8 + teeth_edge(math.atan2(y, x), 14, 0.6), 'copperd10')
    m.paint(lambda x, y, z: z in (6, 7), 'brass10')
    m.paint(lambda x, y, z: z >= H - 6.5 + teeth_edge(math.atan2(y, x), 12, 0.6), 'copper10')
    m.paint(lambda x, y, z: z == H - 7, 'brassd10')
    glow_dots(m, 'G:gturq10', 5, lambda x, y, z: 9 <= z <= 16 and y > 0, mind=4.0)
    rivet_ring(m, 'brassl10', 6.5, 14, r=0.32)
    clock(m, FRONT, 12.6, 3.0, hands=(('ink10', 300), ('red10', 60)))
    for s in (1, -1):
        body_gear(m, 'brass10', FRONT + s * 0.95, 9.0, 1.3, hub='copperd10', phase=0.2 * s)
    # tuyaux de vapeur dans le dos, de la base jusqu'aux cheminées
    back = FRONT + math.pi
    for s in (1, -1):
        a0 = back + s * 0.5
        pts = [pol(rs(m, a0, z) + 0.45, a0 + s * 0.05 * (z / H), z) for z in (3.5, 8.0, 12.5, 16.5)]
        pts.append(pol(rs(m, a0, 19.0) - 0.1, a0, 19.2))
        pipe(m, 'copperl10', pts, 0.42, flange='brass10')
    # cheminées
    top = H - 0.5
    stack(m, (0, 0.5, ztop(m, 0, 0.5) - 0.8), 4.4, 1.75, 1.35, puffs=3)
    for s in (1, -1):
        x = s * 3.1
        stack(m, (x, 0.9, ztop(m, x, 0.9) - 0.9), 3.2, 1.1, 0.9, key='copperl10', puffs=2, lean=(s * 0.22, 0.05))
    nest(m, ['copperd10', 'brassd10', 'steel10'], 20)
    gear_litter(m, ['brass10', 'copper10', 'steel10'], 5, Rr=(0.9, 1.35))
    for s, g in ((1, 'WingR'), (-1, 'WingL')):
        with layer(m, g):
            r = rs(m, 0 if s > 0 else math.pi, 14.5) - 0.9
            mech_wing(m, (s * r, 0.4, 14.5), s, [(58, 7.4), (34, 9.4), (11, 10.2), (-12, 8.8), (-33, 6.6)],
                      mem='steel10', ray='brass10', tip='brassl10', gear_R=1.5, gem='gemt10')
    with layer(m, 'Orbit'):
        Ro = W / 2 + 4.8
        for i in range(6):
            a = i / 6 * TAU + 0.3
            zz = 3.0 + (i % 3) * 1.2
            n = Vector((math.cos(a), math.sin(a), 0))
            if i % 2 == 0:
                energy_ball(m, 'G:gturq10', 'brass10', pol(Ro, a, zz), 0.88)
            else:
                gear(m, 'copper10', pol(Ro, a, zz), n, 1.55, hub='brass10', phase=i * 0.3)
    return build(m, 'Egg_R10_T6', P10, off)


def build_T7(off):
    """Titan Egg : bandes crénelées de l'acier au laiton, grand cadran à gemmes, rouages et médaillons,
    clé à remonter, couronne de rouages à gemmes, halo-rouage, grandes ailes de laiton,
    anneau en orbite avec rouages et lampes turquoise."""
    W, H = SIZES[7]
    m = Vox(H, seed=1007)
    egg_body(m, W, H, 'brass10', 10071)
    seq = ['steelx10', 'steeld10', 'copperd10', 'copper10', 'brass10', 'brassl10']
    edges = [4.6, 9.6, 14.8, 19.8, 24.2]
    for c in m.surface():
        x, y, z = c
        th = math.atan2(y, x)
        idx, line = 0, None
        for i, e in enumerate(edges):
            lim = e + teeth_edge(th, 14, 0.75, i * 0.25)
            if z > lim:
                idx = i + 1
                line = ('turq10' if i == 1 else 'brassl10' if i == 3 else None) if z <= lim + 1 else None
        m.cells[c] = line or seq[idx]
    glow_dots(m, 'G:gturq10', 10, lambda x, y, z: 1 <= z <= 8, mind=3.6)
    clock(m, FRONT, 13.2, 4.6, hands=(('ink10', 300), ('red10', 50)), gems='gemt10')
    for s in (1, -1):
        medallion(m, FRONT + s * 0.9, 13.2, 1.5, 'gemt10')
        body_gear(m, 'copper10', FRONT + s * 0.78, 7.6, 1.6, hub='brassl10', phase=0.15 * s)
    body_gear(m, 'brassl10', FRONT + math.pi, 12.4, 3.4, hub='copperd10', gem='gemt10')
    for s in (1, -1):
        medallion(m, FRONT + math.pi + s * 0.85, 8.0, 1.4, 'gemr10')
    necklace(m, 'brassl10', lambda a: 18.6 - 1.4 * abs(math.sin(3 * (a - FRONT))), 0.62, sub=1, lift=0.12,
             bead='copperd10', br=0.34, keep=lambda a: abs(math.cos(a)) < 0.72)
    top = H - 0.5
    windkey(m, (0, 0, top - 0.3), (0, 0, 1), 2.4, 1.55, side=(1, 0, 0))
    nest(m, ['brass10', 'brassl10', 'copper10', 'brassd10'], 24)
    gear_litter(m, ['brass10', 'copper10', 'brassl10'], 6, Rr=(1.0, 1.5), gem='gemt10')
    with layer(m, 'Crown'):
        gear_crown(m, H - 6.6, 8, 1.8, ['brass10', 'copperl10'], gems=['gemt10', 'gemr10'], out=0.6)
    with layer(m, 'Halo'):
        zh, Rh = H + 6.8, 5.0
        out = gear_pts(Rh, 22, 0.55)
        inn = [((Rh - 1.25) * math.cos(math.atan2(y, x)), (Rh - 1.25) * math.sin(math.atan2(y, x))) for x, y in out]
        orn_annulus(B(m, 'brass10', False), (0, 0, zh), (0, 0, 1), out, inn, 0.5)
        orn_torus(B(m, 'brassl10', True), (0, 0, zh + 0.2), Rh - 1.25, 0.2, seg=48, sides=6)
        for i in range(6):
            a = i / 6 * TAU
            orn_ball(B(m, 'G:gturq10', True), pol(Rh - 0.7, a, zh + 0.35), 0.45, sub=1)
    for s, g in ((1, 'WingR'), (-1, 'WingL')):
        with layer(m, g):
            r = rs(m, 0 if s > 0 else math.pi, 16) - 1.0
            mech_wing(m, (s * r, 0.5, 16), s, [(58, 11.0), (42, 14.5), (26, 16.5), (9, 16.5), (-6, 14.0), (-14, 9.8)],
                      mem='copper10', ray='brass10', tip='brassl10', inner=('brass10', 'brassd10'), gear_R=2.2,
                      gem='gemt10', rivets='brassl10', notch=0.72, ray_r=0.42, tip_r=0.45, lead='brassl10', lead_r=0.7)
    with layer(m, 'Orbit'):
        Ro, zo, tl = 14.2, 5.2, 0.13
        rot = orn_torus(B(m, 'brass10', True), (0, 0, zo), Ro, 0.28, tilt=tl, seg=72, sides=7)
        for i in range(6):
            a = i / 6 * TAU
            p = Vector((0, 0, zo)) + rot @ Vector((Ro * math.cos(a), Ro * math.sin(a), 0))
            if i % 2 == 0:
                energy_ball(m, 'G:gturq10', 'brass10', p, 0.92, tilt=0.9)
            else:
                gear(m, 'brassl10', p, (math.cos(a), math.sin(a), 0), 1.65, hub='copperd10', phase=i * 0.2)
        for i in range(3):
            a = i / 3 * TAU + 0.5
            gear(m, 'copper10', pol(17.6, a, 2.8 + i * 1.6), (math.cos(a), math.sin(a), 0), 1.95, hub='brass10',
                 gem='gemt10', phase=i * 0.4)
            b = a + TAU / 6
            hexnut(m, 'steell10', pol(17.4, b, 7.0 - i * 1.4), (math.cos(b), math.sin(b), 0), 1.2, thick=0.7)
    return build(m, 'Egg_R10_T7', P10, off)


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
    drop('Egg_R10_T%d' % n)
    random.seed(1000 + n)
    coll = BUILDERS[n]((OFFSETS[n], 0, 0))
    obs = [o for o in coll.objects if o.type == 'MESH']
    for o in list(obs):
        if not len(o.data.vertices):
            bpy.data.objects.remove(o, do_unlink=True)
    obs = [o for o in coll.objects if o.type == 'MESH']
    tris = sum(len(p.vertices) - 2 for o in obs for p in o.data.polygons)
    zs = [(o.matrix_world @ v.co).z for o in obs for v in o.data.vertices]
    xs = [(o.matrix_world @ v.co).x for o in obs for v in o.data.vertices]
    print('Egg_R10_T%d : %d objets, %d triangles, x %.1f..%.1f, z %.2f..%.2f, max tris/objet %d' % (
        n, len(obs), tris, min(xs), max(xs), min(zs), max(zs),
        max(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in obs)))
    return coll


def build_all():
    for n in sorted(BUILDERS):
        build_one(n)


# CONTRÔLES (comme l'anneau 9) ----------------------------------------------------------------

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


print("eggs_r10 chargé")
