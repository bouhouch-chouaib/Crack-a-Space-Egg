# Œufs de l'anneau 8 « Star Reef » (récif de corail dans l'espace), même méthode que les anneaux 1 à 7 :
# corps en briques (voxkit.Vox) + ornements lisses (_ORN_), groupes animés (_ACrown_, _AOrbit_, _AHalo_,
# _AWingL_, _AWingR_). Charger voxkit.py avant ce fichier, puis build_all() ou build_one(n).

TAU = math.tau

P8 = dict(
    teal8='#28AAA8', teall8='#58D2C6', teald8='#17808C', aqua8='#A2F0E2', foam8='#F1FAF7',
    coral8='#FF7A6E', corall8='#FFAE9E', corald8='#E2503F',
    sand8='#EFE6D2', sandd8='#E0C088', shell8='#EFC2B6',
    rose8='#F2C4CC', pearl8='#F7F2EA', pearlp8='#FFD4E0', pearla8='#CDF5EE',
    night8='#22347E', nightl8='#3856B8',
    gold8='#FFC21A', goldd8='#E08A10', goldl8='#FFE27A',
    star8='#FF8F45', starl8='#FFD9A0',
    gemc8='#2AE0FF', gemr8='#FF4A6A', geme8='#18E08A', gemv8='#B04AFF',
    gcy8='#3CF2E6', gwhite8='#F2FFFA', gcoral8='#FF8C78', gstar8='#FFF27A',
)

OFFSETS = {2: 0, 3: 34, 4: 70, 5: 112, 6: 162, 7: 222}
SIZES = {2: (11, 15), 3: (11, 17), 4: (13, 19), 5: (15, 22), 6: (17, 25), 7: (21, 29)}


# BRUIT ET PROFIL -----------------------------------------------------------------------------

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
    # ne garder que ce qui tient au corps
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


def hit(m, origin, direction):
    """Point où le rayon parti de origin sort du corps."""
    o, d = Vector(origin), Vector(direction).normalized()
    best = 0.0
    for k in range(400):
        p = o + d * (k * 0.1)
        if (int(round(p.x)), int(round(p.y)), int(round(p.z))) in m.body:
            best = k * 0.1
    return o + d * (best + 0.05)


def pol(r, a, z):
    return Vector((r * math.cos(a), r * math.sin(a), z))


# ORNEMENTS DU RÉCIF --------------------------------------------------------------------------

def coral(m, key, tipkey, base, direction, length, radius, depth, spread=0.75, up=0.35, sides=7, shrink=0.72, rshrink=0.8):
    """Branche de corail qui se divise, bouts arrondis plus clairs."""
    rnd = m.rnd
    d = Vector(direction).normalized()
    side = d.cross(Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1))))
    if side.length < 1e-3:
        side = d.cross(Vector((1, 0, 0)))
    side.normalize()
    p0 = Vector(base)
    p2 = p0 + d * length
    if depth >= 2:
        pts, rad = [p0, p0 + d * length * 0.5 + side * length * 0.10, p2], [radius, radius * 0.88, radius * 0.76]
    else:
        pts, rad = [p0, p2], [radius, radius * 0.78]
    orn_sweep(B(m, key, True), pts, rad, sides=sides)
    if depth <= 0:
        orn_ball(B(m, tipkey, True), p2, radius * 1.12, sub=1)
        return
    orn_ball(B(m, key, True), p2, radius * 0.82, sub=1)
    n = 2 if rnd.random() < 0.6 else 3
    a0 = rnd.uniform(0, TAU)
    perp2 = d.cross(side).normalized()
    for i in range(n):
        a = a0 + i / n * TAU + rnd.uniform(-0.3, 0.3)
        perp = side * math.cos(a) + perp2 * math.sin(a)
        sp = spread * rnd.uniform(0.75, 1.15)
        nd = d * math.cos(sp) + perp * math.sin(sp) + Vector((0, 0, up))
        coral(m, key, tipkey, p2 - d * radius * 0.4, nd, length * shrink * rnd.uniform(0.85, 1.1), radius * rshrink,
              depth - 1, spread, up, sides, shrink, rshrink)


def nest(m, keys, n, zlo=-0.55, zhi=2.0, tube=(0.32, 0.48), off=(0.15, 0.75)):
    k_w = (m.W / 11) ** 0.6
    tube = (tube[0] * k_w, tube[1] * k_w)
    zhi = zhi * k_w
    """Nid de brindilles enroulées autour de la base (comme les autres anneaux), ici en corail."""
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


def bubble(m, c, r, key='pearla8', hi='foam8'):
    orn_ball(B(m, key, True), c, r, sub=2)
    orn_ball(B(m, hi, True), Vector(c) + Vector((-0.42, -0.5, 0.5)) * r, r * 0.38, sub=1)


def bubbles_paint(m, n, zmin=4, zmax=None, sizes=(1.0, 1.45, 1.8), key='aqua8', hi='foam8', mind=4.2):
    """Taches claires « bulles » peintes sur les briques : rond clair, reflet blanc en haut, petite bulle satellite."""
    surf = sorted(c for c in m.surface() if c[2] >= zmin and (zmax is None or c[2] <= zmax))
    sset = set(surf)
    rnd, chosen, tries = m.rnd, [], 0
    while len(chosen) < n and tries < 800:
        tries += 1
        c = rnd.choice(surf)
        if all((Vector(c) - Vector(d)).length >= mind for d in chosen):
            chosen.append(c)
    for c in chosen:
        rad = rnd.choice(sizes)
        cells = [d for d in surf if (Vector(d) - Vector(c)).length <= rad]
        for d in cells:
            m.cells[d] = key
        if rad > 1.2:
            m.cells[max(cells, key=lambda d: d[2] + rnd.random() * 0.5)] = hi
            sat = [d for d in surf if rad + 1.2 <= (Vector(d) - Vector(c)).length <= rad + 1.9 and d[2] > c[2]]
            if sat:
                m.cells[rnd.choice(sat)] = key


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


def necklace(m, key, zf, pr, lift=0.18, sub=2, bead=None, br=0.42, a_off=0.0):
    """Collier de perles posé sur la coquille, à la hauteur zf(angle). bead : petite perle d'or entre deux perles."""
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
        orn_ball(B(m, key, True), P[-1], pr, sub=sub)
    if bead:
        for i in range(N):
            orn_ball(B(m, bead, True), (P[i] + P[(i + 1) % N]) / 2, br, sub=1)
    return P


def starfish(m, key, dotkey, th, z, R, spin=0.0, tilt=0.0):
    """Étoile de mer posée sur la coquille (5 bras effilés, points clairs)."""
    n = Vector((math.cos(th), math.sin(th), tilt)).normalized()
    u = Vector((-math.sin(th), math.cos(th), 0))
    v = n.cross(u).normalized()
    # distance : la plus grande de la surface sous l'étoile, pour ne pas rentrer dans les bosses
    r0 = max(rs(m, th + da, z + dz) for da in (-0.3, 0, 0.3) for dz in (-R * 0.6, 0, R * 0.6))
    c = pol(r0, th, z) + n * 0.22
    bm = B(m, key, True)
    for i in range(5):
        a = spin + i / 5 * TAU + math.pi / 2
        d = u * math.cos(a) + v * math.sin(a)
        tip = c + d * R - n * 0.5
        mid = c + d * R * 0.5 + n * 0.08
        orn_sweep(bm, [c - d * R * 0.1, mid, tip], [R * 0.33, R * 0.25, R * 0.08], sides=8, flat=0.55, twist_up=n)
        for f, s in ((0.3, 0.17), (0.55, 0.13)):
            orn_ball(B(m, dotkey, True), c + d * R * f + n * (R * 0.165 - f * 0.28), s * R / 3.0 + 0.04, sub=1)
    orn_ball(bm, c, R * 0.36, scale=(1, 1, 1), sub=2)
    orn_ball(B(m, dotkey, True), c + n * R * 0.3, 0.2 * R / 3.0 + 0.05, sub=1)


def scallop(m, key1, key2, hinge, up, normal, R, hingekey=None, n=9):
    """Coquille Saint-Jacques : éventail de côtes bombées jointives, bord festonné, autour d'une charnière."""
    up = Vector(up).normalized()
    nrm = Vector(normal).normalized()
    side = up.cross(nrm).normalized()
    up = nrm.cross(side).normalized()
    h = Vector(hinge)
    half = (n - 1) / 2
    for i in range(n):
        a = math.radians((i - half) * 144 / (n - 1))
        d = up * math.cos(a) + side * math.sin(a)
        L = R * (1.0 - 0.14 * (abs(i - half) / half) ** 2)
        orn_sweep(B(m, key1 if i % 2 == 0 else key2, True),
                  [h, h + d * L * 0.5 + nrm * R * 0.2, h + d * L * 0.86 + nrm * R * 0.16, h + d * L],
                  [0.05 * R, 0.13 * R, 0.2 * R, 0.07 * R], sides=8, flat=0.55, twist_up=nrm)
    orn_ball(B(m, hingekey or key1, True), h + nrm * R * 0.06, R * 0.24, scale=(1, 1, 1), sub=1)


def fin(m, root, side, rays, mem_key, ray_key, tip_key, sweep=0.22, thick=0.24, notch=0.8, ray_r=0.34, tip_r=0.3,
        curve=0.0, lead=None, lead_r=0.6):
    """Nageoire en éventail : voile (plaque fine à bord festonné) + rayons + perles au bout.
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
    return tips


def medallion(m, th, z, R, gem_key, gold='gold8', pearl=False):
    """Gemme (ou perle) sertie dans un anneau d'or, posée sur la coquille."""
    n = Vector((math.cos(th), math.sin(th), 0))
    r0 = max(rs(m, th + da, z + dz) for da in (-R / 9, 0, R / 9) for dz in (-R * 0.7, 0, R * 0.7))
    c = pol(r0 + 0.12, th, z)
    orn_torus(B(m, gold, True), c, R, R * 0.24, axis=n, seg=32, sides=8)
    orn_cone(B(m, 'goldd8', True), c + n * R * 0.1, -n, R * 1.2, R * 0.98, sides=16)
    if pearl:
        orn_ball(B(m, gem_key, True), c + n * R * 0.1, R * 0.82, sub=2)
    else:
        orn_gem(B(m, gem_key, False), c + n * R * 0.22, R * 0.84, direction=n)
    return c


def crown(m, z, spikes, gems, ring_r=0.42, tall=3.2, short=2.0, lean=0.22, a0=0.0, skip=(), gem_r=0.6, cone_k=1.15):
    """Couronne d'or autour de la pointe : anneau, pointes, gemmes au bout des grandes, billes sur les petites."""
    Rc = max(rs(m, i / 16 * TAU, z) for i in range(16)) + ring_r - 0.12
    orn_torus(B(m, 'gold8', True), (0, 0, z), Rc, ring_r, seg=40, sides=8)
    orn_torus(B(m, 'goldd8', True), (0, 0, z - ring_r * 1.15), Rc * 0.99, ring_r * 0.6, seg=40, sides=6)
    g = 0
    for i in range(spikes):
        if i in skip:
            continue
        a = a0 + i / spikes * TAU
        L = tall if i % 2 == 0 else short
        base = pol(Rc, a, z)
        dv = Vector((math.cos(a) * lean, math.sin(a) * lean, 1)).normalized()
        orn_cone(B(m, 'gold8', True), base - dv * ring_r * 0.5, dv, L + ring_r * 0.5, ring_r * cone_k, sides=10)
        tip = base + dv * L
        if i % 2 == 0:
            orn_gem(B(m, gems[g % len(gems)], False), tip + Vector((0, 0, gem_r * 0.45)), gem_r, direction=(0, 0, 1))
            g += 1
        else:
            orn_ball(B(m, 'goldl8', True), tip, gem_r * 0.6, sub=1)
    return Rc


# LES SIX ŒUFS --------------------------------------------------------------------------------

def build_T2(off):
    """Bubble Egg : turquoise, bulles claires, nid et brindilles de corail."""
    W, H = SIZES[2]
    m = Vox(H, seed=802)
    egg_body(m, W, H, 'teal8', 8021)
    m.paint(lambda x, y, z: z <= 2.6 + 0.9 * math.sin(math.atan2(y, x) * 3 + 0.5), 'teald8')
    bubbles_paint(m, 12, zmin=4, zmax=H - 3, mind=3.4)
    nest(m, ['coral8', 'corall8', 'corald8'], 15)
    for a, L in ((-2.3, 3.3), (-0.55, 2.9), (2.2, 2.7)):
        r = rs(m, a, 1.0) - 0.2
        coral(m, 'coral8', 'corall8', pol(r, a, 0.5), (math.cos(a) * 1.0, math.sin(a) * 1.0, 0.85), L, 0.52, 2,
              spread=0.6, up=0.55, shrink=0.75)
    for a in (-1.35, 1.0):
        r = rss(m, a, 2.2) + 1.0
        bubble(m, pol(r, a, 1.2), 0.75)
    return build(m, 'Egg_R8_T2', P8, off)


def build_T3(off):
    """Shell Egg : stries de coquillage, étoile de mer, coquille Saint-Jacques, toupet de corail."""
    W, H = SIZES[3]
    m = Vox(H, seed=803)
    egg_body(m, W, H, 'sand8', 8031)
    N = 9
    m.paint(lambda x, y, z: z > 2 and ((math.atan2(y, x) / TAU * N) % 1.0) < 0.36, 'shell8')
    m.paint(lambda x, y, z: z <= 3.0 + 0.8 * math.sin(math.atan2(y, x) * 4), 'teal8')
    for dv, L in (((0.25, 0.1, 1), 3.0), ((-0.5, 0.25, 1), 2.4), ((0.1, -0.5, 1), 2.5)):
        coral(m, 'coral8', 'corall8', (0, 0, H - 1.6), dv, L, 0.5, 1, spread=0.6)
    starfish(m, 'star8', 'starl8', -math.pi / 2 + 0.45, 8.6, 3.3, spin=0.25)
    a = -math.pi / 2 - 0.62
    r = rss(m, a, 2.2) + 0.55
    scallop(m, 'rose8', 'pearlp8', pol(r, a, 0.0), (math.cos(a) * 0.22, math.sin(a) * 0.22, 1),
            (math.cos(a), math.sin(a), -0.22), 3.7, hingekey='coral8')
    nest(m, ['coral8', 'corall8', 'sandd8'], 12)
    return build(m, 'Egg_R8_T3', P8, off)


def build_T4(off):
    """Pearl Egg : nacre rose, collier de perles et d'or avec pendentif, couronne de corail naissante, bulles en orbite."""
    W, H = SIZES[4]
    m = Vox(H, seed=804)
    egg_body(m, W, H, 'rose8', 8041)
    m.paint(lambda x, y, z: vnoise(x + 50, y, z, 11, 4.0) > 0.22, 'pearl8')
    m.paint(lambda x, y, z: vnoise(x, y + 50, z, 12, 4.0) > 0.42, 'pearla8')
    m.paint(lambda x, y, z: z <= 3.4 + 1.2 * abs(math.sin(math.atan2(y, x) * 3)), 'teal8')
    glow_dots(m, 'G:gcy8', 6, lambda x, y, z: 1 <= z <= 3)
    front = -math.pi / 2
    zf = lambda a: 11.4 - 1.9 * (0.5 + 0.5 * math.cos(a - front)) ** 2
    necklace(m, 'pearl8', zf, 0.85, bead='gold8', br=0.42, a_off=front + 0.11)
    c = medallion(m, front, zf(front) - 2.25, 1.3, 'pearlp8', pearl=True)
    orn_ball(B(m, 'gold8', True), c + Vector((0, -0.25, 1.5)), 0.42, sub=1)
    # couronne de corail naissante : petit cercle d'or, jeunes pousses de corail tout autour, perle au sommet
    zc = H - 4.6
    Rk = max(rs(m, i / 16 * TAU, zc) for i in range(16)) + 0.25
    orn_torus(B(m, 'gold8', True), (0, 0, zc), Rk, 0.36, seg=36, sides=8)
    for i in range(8):
        a = i / 8 * TAU + 0.2
        L = 2.5 if i % 2 == 0 else 1.7
        coral(m, 'coral8', 'corall8', pol(Rk, a, zc), (math.cos(a) * 0.4, math.sin(a) * 0.4, 1), L, 0.5,
              1 if i % 2 == 0 else 0, spread=0.5, up=0.5)
    orn_ball(B(m, 'pearl8', True), (0, 0, H - 0.25), 1.0, sub=2)
    nest(m, ['coral8', 'corall8', 'gold8'], 16)
    nest_pearls(m, 'pearl8', 5, pr=0.6, z=1.3)
    with layer(m, 'Orbit'):
        for i, (zz, rr) in enumerate(((5.0, 1.0), (9.5, 0.8), (14.0, 0.95))):
            a = i / 3 * TAU + 0.6
            bubble(m, pol(W / 2 + 4.2, a, zz), rr)
    return build(m, 'Egg_R8_T4', P8, off)


def build_T5(off):
    """Tide Egg : vagues turquoise bordées d'or, grands bois de corail sur couronne d'or, petites nageoires."""
    W, H = SIZES[5]
    m = Vox(H, seed=805)
    egg_body(m, W, H, 'teal8', 8051)

    def wv(x, y, z):
        return z + 1.3 * math.sin(3 * math.atan2(y, x) + 0.6)

    bands = [(4.2, 'teald8'), (5.2, 'gold8'), (10.6, 'teal8'), (11.6, 'gold8'), (16.2, 'teall8'), (17.2, 'gold8'), (99, 'aqua8')]
    for c in m.surface():
        w = wv(*c)
        m.cells[c] = next(k for lim, k in bands if w < lim)
        for lim in (5.2, 11.6, 17.2):
            if lim <= w < lim + 1 and math.sin(3 * math.atan2(c[1], c[0]) + 0.6 + 1.2) > 0.45:
                m.cells[c] = 'foam8'
    front = -math.pi / 2
    medallion(m, front, 8.0, 1.7, 'pearl8', pearl=True)
    nest(m, ['coral8', 'gold8', 'goldd8', 'corall8'], 18)
    nest_pearls(m, 'pearl8', 5, pr=0.62, z=1.3)
    with layer(m, 'Crown'):
        zc = H - 5.5
        Rc = crown(m, zc, 8, ['gemc8', 'gemr8'], tall=2.6, short=1.7, a0=TAU / 16, ring_r=0.45, gem_r=0.68)
        for s in (1, -1):
            coral(m, 'coral8', 'corall8', (s * (Rc - 0.1), 0, zc), (s * 0.62, 0, 1), 4.4, 0.78, 3, spread=0.62, up=0.4,
                  shrink=0.74, rshrink=0.8)
    for s, g in ((1, 'WingR'), (-1, 'WingL')):
        with layer(m, g):
            r = rs(m, 0 if s > 0 else math.pi, 11.5) - 0.9
            fin(m, (s * r, 0.3, 11.5), s, [(58, 5.4), (38, 6.8), (18, 7.6), (-2, 7.6), (-22, 6.6), (-42, 5.0)],
                'corall8', 'coral8', 'pearl8', notch=0.9)
    return build(m, 'Egg_R8_T5', P8, off)


def build_T6(off):
    """Abyss Egg : bleu nuit, points bioluminescents, crête d'épines, nageoires, leurre lumineux de poisson-lanterne."""
    W, H = SIZES[6]
    m = Vox(H, seed=806)
    egg_body(m, W, H, 'night8', 8061)
    m.paint(lambda x, y, z: vnoise(x, y, z, 21, 4.5) > 0.22, 'nightl8')
    m.paint(lambda x, y, z: vnoise(x + 30, y, z + 30, 22, 3.5) > 0.5, 'teald8')
    m.paint(lambda x, y, z: z <= 4.4 + 1.2 * math.sin(math.atan2(y, x) * 3), 'teald8')
    glow_dots(m, 'G:gcy8', 18, lambda x, y, z: z >= 2, mind=3.4)
    # crête d'épines du sommet vers le dos (deux tons : base corail, pointe claire)
    o = Vector((0, 0, 10))
    for k in range(7):
        ph = math.radians(10 + k * 15.5)
        d = Vector((0, math.sin(ph), math.cos(ph)))
        p = hit(m, o, d)
        L = 5.4 - 0.36 * k
        rb = 1.05 - 0.05 * k
        orn_cone(B(m, 'coral8', True), p - d * 0.8, d, L + 0.8, rb, sides=10)
        orn_cone(B(m, 'corall8', True), p + d * (L * 0.56), d, L * 0.44 + 0.02, rb * 0.5, sides=10)
    # leurre : tige qui part du sommet vers l'avant, boule lumineuse au bout
    top = H - 0.5
    pts = [(0, -1.2, top - 1.6), (0, -2.2, top + 2.6), (0, -5.4, top + 4.9), (0, -9.0, top + 3.6), (0, -10.4, top + 0.9)]
    orn_sweep(B(m, 'coral8', True), pts, [0.72, 0.58, 0.46, 0.38, 0.34], sides=9)
    bulb = Vector((0, -10.6, top - 0.6))
    orn_ball(B(m, 'G:gcy8', True), bulb, 1.55, sub=2)
    orn_torus(B(m, 'corall8', True), bulb + Vector((0, 0.05, 1.25)), 0.72, 0.3, seg=20, sides=7)
    nest(m, ['nightl8', 'teal8', 'coral8'], 20)
    for a in (-2.0, 0.2, 2.4):
        r = rss(m, a, 1.0) + 0.9
        orn_ball(B(m, 'G:gcy8', True), pol(r, a, 1.0), 0.55, sub=1)
    for s, g in ((1, 'WingR'), (-1, 'WingL')):
        with layer(m, g):
            r = rs(m, 0 if s > 0 else math.pi, 12.5) - 0.9
            fin(m, (s * r, 0.4, 12.5), s, [(62, 8.0), (38, 10.2), (14, 10.8), (-10, 9.2), (-32, 7.0)],
                'teal8', 'coral8', 'G:gcy8', notch=0.68, ray_r=0.42, tip_r=0.4)
    with layer(m, 'Orbit'):
        for i in range(3):
            a = i / 3 * TAU + 0.9
            bubble(m, pol(W / 2 + 4.6, a, 2.6 + i * 1.7), 1.25 - 0.12 * i)
            orn_ball(B(m, 'G:gcy8', True), pol(W / 2 + 5.4, a + TAU / 6, 6.0 - i * 1.6), 0.6, sub=1)
    return build(m, 'Egg_R8_T6', P8, off)


def build_T7(off):
    """Leviathan Egg : écailles du fond de la mer à la surface, médaillons de gemmes, collier de perles,
    couronne d'or à bois de corail et étoile, halo, grandes nageoires-ailes, anneau de perles en orbite."""
    W, H = SIZES[7]
    m = Vox(H, seed=807)
    egg_body(m, W, H, 'teal8', 8071)
    seq = ['night8', 'teald8', 'teal8', 'teall8', 'aqua8', 'pearl8']
    edges = [4.6, 9.6, 14.8, 19.8, 24.2]
    for c in m.surface():
        x, y, z = c
        th = math.atan2(y, x)
        idx, line = 0, False
        for i, e in enumerate(edges):
            lim = e + 1.5 * abs(math.sin(th * 4 + i * 0.9)) - 0.75
            if z > lim:
                idx = i + 1
                line = (i in (1, 3)) and z <= lim + 1
        m.cells[c] = 'coral8' if line else seq[idx]
    glow_dots(m, 'G:gcy8', 12, lambda x, y, z: 1 <= z <= 8, mind=3.6)
    front = -math.pi / 2
    medallion(m, front, 11.5, 2.7, 'gemc8')
    medallion(m, front + 0.72, 12.0, 1.55, 'gemr8')
    medallion(m, front - 0.72, 12.0, 1.55, 'gemr8')
    medallion(m, front + math.pi, 11.5, 2.1, 'gemv8')
    necklace(m, 'pearl8', lambda a: 17.6 - 1.7 * abs(math.sin(3 * (a - front))), 0.8, sub=1, lift=0.35)
    nest(m, ['gold8', 'goldl8', 'coral8', 'goldd8'], 24)
    nest_pearls(m, 'pearl8', 7, pr=0.7, z=1.5)
    with layer(m, 'Crown'):
        zc = H - 6.5
        Rc = crown(m, zc, 8, ['gemc8', 'gemr8', 'geme8', 'gemv8'], tall=4.4, short=2.8, a0=TAU / 16, ring_r=0.58,
                   gem_r=0.9, cone_k=1.3)
        for s in (1, -1):
            coral(m, 'coral8', 'corall8', (s * (Rc - 0.1), 0, zc), (s * 0.5, 0, 1), 4.6, 0.72, 3, spread=0.6, up=0.45,
                  shrink=0.7)
        orn_star(B(m, 'G:gstar8', False), (0, 0, H - 0.5 + 1.75), 3.0, 1.3, 0.9, normal=(0, -1, 0))
    with layer(m, 'Halo'):
        for i in range(6):
            orn_torus(B(m, ('G:gcy8', 'G:gwhite8', 'G:gcoral8')[i % 3], True), (0, 0, H + 8.6), 5.8, 0.46, tilt=0.42,
                      seg=48, sides=8, arc=(i / 6, (i + 1) / 6))
    for s, g in ((1, 'WingR'), (-1, 'WingL')):
        with layer(m, g):
            r = rs(m, 0 if s > 0 else math.pi, 16) - 1.0
            root = Vector((s * r, 0.5, 16))
            rays = [(70, 11.0), (52, 14.5), (34, 16.5), (16, 16.5), (0, 14.0), (-15, 10.5)]
            fin(m, root, s, rays, 'teall8', 'coral8', 'pearl8', notch=0.84, ray_r=0.42, tip_r=0.45, lead='gold8',
                lead_r=0.7, thick=0.26)
            inner = [(a, L * 0.58) for a, L in rays]
            fin(m, root + Vector((0, -0.22, 0)), s, inner, 'teal8', 'gold8', None, notch=0.86, ray_r=0.3, thick=0.2)
            g0 = root + Vector((s * 2.2, -0.75, 1.0))
            orn_torus(B(m, 'gold8', True), g0, 0.95, 0.26, axis=(0, -1, 0), seg=24, sides=7)
            orn_gem(B(m, 'gemc8', False), g0 + Vector((0, -0.1, 0)), 0.8, direction=(0, -1, 0))
            orn_ball(B(m, 'goldd8', True), g0 + Vector((0, 0.3, 0)), 0.95, scale=(1, 0.5, 1), sub=1)
    with layer(m, 'Orbit'):
        Ro, zo, tl = 14.2, 5.2, 0.13
        rot = orn_torus(B(m, 'gold8', True), (0, 0, zo), Ro, 0.26, tilt=tl, seg=64, sides=7)
        for i in range(6):
            a = i / 6 * TAU
            p = Vector((0, 0, zo)) + rot @ Vector((Ro * math.cos(a), Ro * math.sin(a), 0))
            orn_ball(B(m, 'pearl8', True), p, 0.78, sub=2)
        for i in range(3):
            a = i / 3 * TAU + 0.5
            bubble(m, pol(17.6, a, 2.6 + i * 1.9), 1.15 - 0.1 * i)
            orn_star(B(m, 'star8', False), pol(17.2, a + TAU / 6, 7.4 - i * 1.8), 1.35, 0.6, 0.42,
                     normal=(math.cos(a + TAU / 6), math.sin(a + TAU / 6), 0.3), spin=i * 0.4)
    return build(m, 'Egg_R8_T7', P8, off)


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
    drop('Egg_R8_T%d' % n)
    random.seed(800 + n)
    coll = BUILDERS[n]((OFFSETS[n], 0, 0))
    obs = [o for o in coll.objects if o.type == 'MESH']
    for o in list(obs):
        if not len(o.data.vertices):
            bpy.data.objects.remove(o, do_unlink=True)
    obs = [o for o in coll.objects if o.type == 'MESH']
    tris = sum(len(p.vertices) - 2 for o in obs for p in o.data.polygons)
    zs = [(o.matrix_world @ v.co).z for o in obs for v in o.data.vertices]
    xs = [(o.matrix_world @ v.co).x for o in obs for v in o.data.vertices]
    print('Egg_R8_T%d : %d objets, %d triangles, x %.1f..%.1f, z %.2f..%.2f, max tris/objet %d' % (
        n, len(obs), tris, min(xs), max(xs), min(zs), max(zs),
        max(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in obs)))
    return coll


def build_all():
    for n in sorted(BUILDERS):
        build_one(n)


print("eggs_r8 chargé")
