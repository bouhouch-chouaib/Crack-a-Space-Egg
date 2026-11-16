# Œufs de l'anneau 12 « Mushroom Moon » (lune couverte de champignons lumineux, de mousse et de spores : amanites
# rouges à pois blancs, chapeaux lumineux turquoise et violets, mousse, champignons en étagère orange, filaments de
# mycélium, spores qui brillent), même méthode que les anneaux 1 à 11 :
# corps en briques (voxkit.Vox) + ornements lisses (_ORN_), groupes animés (_ACrown_, _AOrbit_, _AHalo_, _AWingL_,
# _AWingR_). Charger voxkit.py avant ce fichier, puis build_all() ou build_one(n).
# clash(coll) vérifie qu'un groupe qui tourne ne traverse ni les ailes qui battent ni les ornements fixes ;
# neon_share(coll) donne la part de surface en néon (à garder sous 5 %).
# Les clés de couleur lumineuses commencent par « g » (gturq12...) : neon_share les reconnaît ainsi.
# Les couleurs sont converties sRGB -> linéaire par voxkit.material (l'import Ropilot les relit comme linéaires).

TAU = math.tau

P12 = dict(
    night12='#2C2148', nightd12='#1E1634',
    violet12='#7A52C8', violetd12='#5A3A9E', violetl12='#9470DC',
    lav12='#B89BFF', lavl12='#D9CCFF',
    turq12='#6EF0D2', turqd12='#36BFA6', turqx12='#1F8478',
    moss12='#6FB04A', mossd12='#3E7A32', mossl12='#9ACF6A',
    red12='#D8382E', redd12='#A3241E', redl12='#F0614F',
    cream12='#F4EEDC', creamd12='#DCD0B4',
    orange12='#F09A3C', oranged12='#C26E22', orangel12='#FFC27A',
    bark12='#6A4A30', barkd12='#4A3220',
    nblue12='#2E3E7A', nblued12='#1E2A58', nbluel12='#4A5CA8',
    moon12='#FFF4C8', moond12='#E8D48A',
    gemt12='#2FE0C0', gemv12='#9B6BFF',
    gturq12='#6EF0D2', glav12='#B89BFF', gmoon12='#FFF6D0',
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


def medallion(m, th, z, R, gem_key, gold='lav12', dark='violetd12'):
    """Gemme sertie dans un anneau, posée sur la coquille."""
    n = Vector((math.cos(th), math.sin(th), 0))
    r0 = max(rs(m, th + da, z + dz) for da in (-R / 9, 0, R / 9) for dz in (-R * 0.7, 0, R * 0.7))
    c = pol(r0 + 0.12, th, z)
    orn_torus(B(m, gold, True), c, R, R * 0.24, axis=n, seg=32, sides=8)
    orn_cone(B(m, dark, True), c + n * R * 0.1, -n, R * 1.2, R * 0.98, sides=16)
    orn_gem(B(m, gem_key, False), c + n * R * 0.22, R * 0.84, direction=n)
    return c


# CHAMPIGNONS, MOUSSE, SPORES, MYCÉLIUM, LUNE -----------------------------------------------------

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


CAP_TOPS = {
    'dome': [(1.0, 0.16), (0.97, 0.38), (0.86, 0.6), (0.66, 0.8), (0.38, 0.95), (0.0, 1.0)],   # amanite, bombé
    'cone': [(1.0, 0.12), (0.88, 0.34), (0.68, 0.58), (0.44, 0.8), (0.2, 0.95), (0.0, 1.0)],   # mycène pointue
    'flat': [(1.0, 0.18), (0.96, 0.42), (0.8, 0.62), (0.5, 0.74), (0.0, 0.78)],               # chapeau large
}


def cap_prof(R, ch, kind='dome'):
    under = [(0.0, 0.24), (0.5, 0.15), (0.92, 0.06)]
    top = CAP_TOPS[kind]
    return [(r * R, z * ch) for r, z in under + top], [(r * R, z * ch) for r, z in top]


def shroom(m, base, up, h, R, cap, stem='cream12', gills='creamd12', kind='dome', ch=None, spots=None, n_spots=0,
           spot_r=None, skirt=None, sides=None, seed=0, stem_r=None):
    """Champignon : pied (léger cône), chapeau tourné (dôme, cône ou plat), lamelles dessous, pois sur le chapeau,
    anneau (jupe) sur le pied si skirt. base : pied du champignon ; up : son axe. Renvoie le sommet du chapeau."""
    base, up = Vector(base), Vector(up).normalized()
    ch = ch or R * 0.8
    sides = sides or (12 if R < 1.0 else 14 if R < 2.0 else 18)
    r0 = stem_r or max(0.16, R * 0.3)
    orn_cyl(B(m, stem, True), base - up * 0.3, up, h + 0.3 + 0.3 * ch, r0, r0 * 0.78, sides=10)
    cb = base + up * h
    prof, top = cap_prof(R, ch, kind)
    rot = lathe(B(m, cap, True), cb, up, prof, sides)
    if gills:
        lathe(B(m, gills, True), cb, up, [(0.24 * R, 0.2 * ch), (0.9 * R, 0.06 * ch), (0.86 * R, 0.0),
                                          (0.24 * R, 0.12 * ch)], sides, closed=True)
    if skirt:
        zs = h * 0.62
        lathe(B(m, skirt, True), base + up * zs, up, [(r0 * 0.8, 0.12), (r0 * 1.9, -0.32), (r0 * 1.75, -0.46),
                                                    (r0 * 0.8, -0.12)], 12, closed=True)
    if spots and n_spots:
        rnd = random.Random(seed)
        sr = spot_r or R * 0.16
        for i in range(n_spots):
            az = i / n_spots * TAU + rnd.uniform(-0.35, 0.35)
            s = (0.72 if i == 0 else rnd.uniform(0.1, 0.55)) * (len(top) - 1)
            i0 = min(int(s), len(top) - 2)
            f = s - i0
            (ra, za), (rb, zb) = top[i0], top[i0 + 1]
            r, z = ra + (rb - ra) * f, za + (zb - za) * f
            N = Vector((zb - za, -(rb - ra)))
            N.normalize()
            pt = cb + rot @ Vector((r * math.cos(az), r * math.sin(az), z))
            nw = rot @ Vector((N.x * math.cos(az), N.x * math.sin(az), N.y))
            orn_ball(B(m, spots, True), pt - nw * sr * 0.35, sr * (0.8 + 0.4 * rnd.random()),
                     sub=2 if sr > 0.5 else 1)
    return cb + up * ch


def body_shroom(m, th, z, h, R, cap, lean=0.6, sink=0.3, **kw):
    """Champignon qui pousse sur la coquille, penché vers l'extérieur."""
    n = Vector((math.cos(th), math.sin(th), 0))
    up = (n * lean + Vector((0, 0, 1))).normalized()
    base = pol(rs(m, th, z) - sink, th, z)
    return shroom(m, base, up, h, R, cap, **kw)


def top_shroom(m, x, y, h, R, cap, lean=0.0, **kw):
    """Champignon planté sur le dessus (penché vers l'extérieur de lean)."""
    d = Vector((x, y, 0))
    up = Vector((0, 0, 1)) + (d.normalized() * lean if d.length > 1e-3 else Vector())
    return shroom(m, (x, y, ztop(m, x, y) - 0.35), up, h, R, cap, **kw)


def shroom_litter(m, n, caps, Rr=(0.7, 1.0), lean=0.25, spots=None, gills='creamd12', stem='cream12', kind='dome',
                  zr=1.6):
    """Petits champignons au pied de l'œuf (à la place des bonbons de l'anneau 11)."""
    rnd = m.rnd
    a0 = rnd.uniform(0, TAU)
    for i in range(n):
        a = a0 + i / n * TAU + rnd.uniform(-0.25, 0.25)
        Rg = rnd.uniform(*Rr)
        r = max(rs(m, a + d, zr + dz) for d in (-0.3, 0, 0.3) for dz in (0, 1.0)) + Rg * 0.9 + 0.35
        cap = caps[i % len(caps)]
        sp = spots[i % len(spots)] if spots else None
        shroom(m, pol(r, a, -0.5), (math.cos(a) * lean, math.sin(a) * lean, 1), Rg * 1.25, Rg, cap, stem=stem,
               gills=gills, kind=kind if cap != 'red12' else 'dome', spots=sp, n_spots=4 if sp else 0, seed=i)


def moss_tufts(m, n, test, keys=('mossl12', 'moss12'), r=(0.32, 0.52), mind=0.95):
    """Touffes de mousse (petites boules facettées par deux) posées sur les briques."""
    for i, (p, nrm, t1, t2, a) in enumerate(on_faces(m, n, test, mind)):
        rr = r[0] + (r[1] - r[0]) * abs(math.sin(a * 3))
        k = keys[i % len(keys)]
        orn_ball(B(m, k, False), p + nrm * rr * 0.15, rr, sub=1)
        d = t1 * math.cos(a) + t2 * math.sin(a)
        orn_ball(B(m, k, False), p + d * rr * 0.85 + nrm * rr * 0.05, rr * 0.7, sub=1)


def spore_bumps(m, n, test, key='turq12', r=0.3, mind=1.6):
    """Spores en relief (petites boules lisses) sur les flancs."""
    for p, nrm, t1, t2, a in on_faces(m, n, test, mind, up=False):
        orn_ball(B(m, key, True), p + nrm * r * 0.1, r * (0.85 + 0.3 * abs(math.sin(a * 2))), sub=1)


def shelf(m, th, z, R, keys=('oranged12', 'orange12', 'orangel12'), depth=0.85, thick=0.42, n=14):
    """Champignon en étagère : demi-disques plats en gradins, collés à la coquille."""
    nrm = Vector((math.cos(th), math.sin(th), 0))
    tg = Vector((-math.sin(th), math.cos(th), 0))
    r0 = surf_r(m, th, z, R / max(rs(m, th, z), 1.0), 0.5)
    for i, k in enumerate(keys):
        Ri = R * (1 - 0.27 * i)
        pts = [(Ri * math.cos(math.pi * j / n), Ri * depth * math.sin(math.pi * j / n) + 0.6) for j in range(n + 1)]
        orn_plate(B(m, k, False), pts, pol(r0 - 0.6, th, z + i * thick * 0.85), tg, nrm, Vector((0, 0, 1)), thick)


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


def gill_wing(m, root, s, R, a_hi=62, a_lo=-30, n=11, mem='lav12', gill='lavl12', rim='violet12',
              glow='G:gturq12', inner=None, thick=0.22, rim_r=0.42, gill_r=0.17, n_glow=4, glow_r=0.38, knob=None):
    """Aile en lamelles de champignon : voile en éventail, lamelles rayonnantes, bord de chapeau en boudin,
    spores lumineuses sur le bord, voile intérieure plus courte (inner = (voile, lamelles))."""
    root = Vector(root)
    angs = [a_hi + (a_lo - a_hi) * i / (n - 1) for i in range(n)]
    tips, P, nrm = fin(m, root, s, [(a, R) for a in angs], mem, gill, None, thick=thick, notch=0.985, ray_r=gill_r)
    k = int((a_hi - a_lo) / 2.5) + 1
    arc = [P(a_hi + (a_lo - a_hi) * i / (k - 1), R) for i in range(k)]
    tube(B(m, rim, True), arc, rim_r, sides=8)
    for p in (arc[0], arc[-1]):
        orn_ball(B(m, rim, True), p, rim_r * 1.25, sub=1)
    if glow and n_glow:
        for i in range(n_glow):
            a = a_hi + (a_lo - a_hi) * (i + 0.5) / n_glow
            orn_ball(B(m, glow, True), P(a, R + rim_r * 0.7), glow_r, sub=1)
    if inner:
        fin(m, root + Vector((0, -0.3, 0)), s, [(a, R * 0.58) for a in angs[::2]], inner[0], inner[1], None,
            notch=0.95, ray_r=gill_r * 0.9, thick=thick * 0.9)
        k2 = int((a_hi - a_lo) / 4) + 1
        arc2 = [P(a_hi + (a_lo - a_hi) * i / (k2 - 1), R * 0.58) + Vector((0, -0.3, 0)) for i in range(k2)]
        tube(B(m, inner[1], True), arc2, rim_r * 0.6, sides=6)
    if knob:
        orn_ball(B(m, knob, True), root + Vector((s * 0.4, -0.2, 0)), 1.0, sub=2)
    return tips, P, nrm


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
    return 'moond12' if key == 'moon12' else key


def paint_craters(m, n, test, rad=(1.4, 2.2), rim='lavl12', inside='violetl12', mind=4.5):
    """Cratères de lune peints en briques : bord clair, creux plus sombre."""
    surf = sorted(c for c in m.surface() if c in m.body and test(*c))
    rnd, chosen, tries = m.rnd, [], 0
    while len(chosen) < n and tries < 600 and surf:
        tries += 1
        c = rnd.choice(surf)
        if all((Vector(c) - Vector(q[0])).length >= mind for q in chosen):
            chosen.append((c, rnd.uniform(*rad)))
    for c, r in chosen:
        for d in surf:
            dd = (Vector(d) - Vector(c)).length
            if dd <= r:
                m.cells[d] = inside if dd <= r - 0.9 else rim


def spore(m, key, c, r, ring=None, tilt=0.6):
    """Spore qui flotte : boule, petit anneau penché autour si ring."""
    orn_ball(B(m, key, True), c, r, sub=2 if r > 0.5 else 1)
    if ring:
        orn_torus(B(m, ring, True), c, r * 1.35, r * 0.16, tilt=tilt, seg=20, sides=5)


def shroom_crown(m, z, items, Rg, ring='moss12', ring2='mossd12', out=0.5, rr=0.42):
    """Couronne de petits champignons debout sur un anneau de mousse, autour du haut de l'œuf."""
    Rc = rmax(m, z) + out
    orn_torus(B(m, ring, True), (0, 0, z), Rc, rr, seg=56, sides=8)
    orn_torus(B(m, ring2, True), (0, 0, z - rr * 0.9), Rc * 0.985, rr * 0.6, seg=48, sides=6)
    n = len(items)
    for i, (cap, kind, spots) in enumerate(items):
        a = i / n * TAU
        g = cap.startswith('G:')
        R = Rg * (0.72 if g else 1.0)
        shroom(m, pol(Rc, a, z + rr * 0.3), (math.cos(a) * 0.18, math.sin(a) * 0.18, 1), Rg * (1.05 if g else 1.2),
               R, cap, stem='lavl12', gills=None if g else ('turqd12' if cap == 'turq12' else 'creamd12'),
               kind=kind, spots=spots, n_spots=3 if spots else 0, seed=i)
    return Rc


# LES SIX ŒUFS --------------------------------------------------------------------------------

FRONT = -math.pi / 2


def build_T2(off):
    """Spore Egg : violet, taché de points de spores turquoise (quelques-uns lumineux), sommet lavande,
    tout petit champignon turquoise au pied (et son bébé)."""
    W, H = SIZES[2]
    m = Vox(H, seed=1202)
    egg_body(m, W, H, 'violet12', 12021, bump=0.45)
    m.paint(lambda x, y, z: z <= 2.2 + wave(math.atan2(y, x), 3, 0.7, 0.5), 'violetd12')
    m.paint(lambda x, y, z: z >= H - 3.4 + wave(math.atan2(y, x), 5, 0.6, 1.0), 'lav12')
    glow_dots(m, 'turq12', 14, lambda x, y, z: 3 <= z <= H - 4, mind=2.3)
    glow_dots(m, 'lavl12', 6, lambda x, y, z: 3 <= z <= H - 4 and m.cells[(x, y, z)] == 'violet12', mind=2.6)
    glow_dots(m, 'G:gturq12', 3, lambda x, y, z: 5 <= z <= 10 and m.cells[(x, y, z)] == 'violet12', mind=4.0)
    spore_bumps(m, 6, lambda x, y, z: 5 <= z <= 11, key='turq12', r=0.3, mind=2.6)
    a = FRONT + 0.75
    r = max(rs(m, a + d, 1.8) for d in (-0.3, 0, 0.3)) + 1.5
    shroom(m, pol(r, a, -0.5), (math.cos(a) * 0.25, math.sin(a) * 0.25, 1), 1.9, 1.45, 'turq12', gills='turqd12',
           stem='cream12', spots='lavl12', n_spots=4, spot_r=0.22)
    a2 = a + 0.5
    r2 = max(rs(m, a2 + d, 1.0) for d in (-0.3, 0, 0.3)) + 0.9
    shroom(m, pol(r2, a2, -0.5), (math.cos(a2) * 0.35, math.sin(a2) * 0.35, 1), 0.95, 0.75, 'lav12',
           gills='creamd12', stem='cream12')
    nest(m, ['mossd12', 'bark12', 'violetd12'], 15)
    return build(m, 'Egg_R12_T2', P12, off)


def build_T3(off):
    """Moss Egg : violet couvert de plaques de mousse (deux verts), touffes de mousse, petits champignons blancs
    qui sortent de la mousse, deux au sommet."""
    W, H = SIZES[3]
    m = Vox(H, seed=1203)
    egg_body(m, W, H, 'violet12', 12031, bump=0.45)
    m.paint(lambda x, y, z: vnoise(x, y, z, 31, 3.2) + (0.7 if z < 4 else 0) + (0.25 if z > H - 5 else 0) > -0.12,
            'moss12')
    m.paint(lambda x, y, z: m.cells[(x, y, z)] == 'moss12' and vnoise(x + 20, y, z, 32, 2.2) > 0.4, 'mossd12')
    m.paint(lambda x, y, z: z <= 1.6, 'mossd12')
    glow_dots(m, 'lavl12', 6, lambda x, y, z: m.cells[(x, y, z)] == 'violet12', mind=2.6)
    moss_tufts(m, 26, lambda x, y, z: m.cells.get((x, y, z)) in ('moss12', 'mossd12') and z >= 2, r=(0.4, 0.62),
               mind=1.4)
    for th, z, R in ((FRONT + 0.5, 6.0, 1.3), (FRONT - 0.95, 9.0, 1.1), (FRONT + 2.3, 7.5, 1.35),
                     (FRONT + 3.7, 10.5, 1.15), (FRONT - 2.4, 5.0, 1.0)):
        body_shroom(m, th, z, R * 1.3, R, 'cream12', lean=0.8, gills='creamd12', stem='cream12', seed=int(z))
    for i, (x, y, R) in enumerate(((0.7, -0.5, 1.35), (-1.2, 0.8, 1.0))):
        top_shroom(m, x, y, R * 1.5, R, 'cream12', lean=0.35, gills='creamd12', seed=i)
    nest(m, ['mossd12', 'moss12', 'bark12'], 13)
    shroom_litter(m, 3, ['cream12', 'lav12', 'cream12'], Rr=(0.75, 1.0))
    return build(m, 'Egg_R12_T3', P12, off)


def build_T4(off):
    """Toadstool Egg : pied crème, chapeau d'amanite rouge à pois blancs qui coiffe l'œuf (bord évasé, lamelles,
    verrues blanches), anneau sous le chapeau, mousse au pied, lueur turquoise, petits champignons autour,
    champignons et spores en orbite."""
    W, H = SIZES[4]
    m = Vox(H, seed=1204)
    egg_body(m, W, H, 'cream12', 12041, bump=0.25)
    m.paint(lambda x, y, z: z <= 2.4 + wave(math.atan2(y, x), 4, 0.6), 'mossd12')
    m.paint(lambda x, y, z: m.cells[(x, y, z)] == 'cream12' and z <= 3.4 + wave(math.atan2(y, x), 6, 0.6, 1),
            'moss12')
    zb = H - 7.6
    m.paint(lambda x, y, z: z >= zb + wave(math.atan2(y, x), 6, 0.4), 'red12')
    glow_dots(m, 'G:gturq12', 3, lambda x, y, z: 5 <= z <= 9 and m.cells[(x, y, z)] == 'cream12', mind=4.0)
    glow_dots(m, 'creamd12', 8, lambda x, y, z: 4 <= z <= zb - 1 and m.cells[(x, y, z)] == 'cream12', mind=2.2)
    # chapeau d'amanite (lisse) qui coiffe le haut de l'œuf : dôme, lamelles dessous, pois blancs en relief
    z0 = zb - 0.6
    Rh = rmax(m, z0) + 1.9
    shroom(m, (0, 0, z0 - 0.6), (0, 0, 1), 0.6, Rh, 'red12', stem='cream12', gills='creamd12', kind='dome',
           ch=H + 1.4 - z0, spots='cream12', n_spots=15, spot_r=0.85, sides=36, stem_r=1.0, seed=4)
    # anneau (jupe) d'amanite sous le chapeau
    zs = 7.4
    Rs = rmax(m, zs)
    lathe(B(m, 'cream12', True), (0, 0, zs), (0, 0, 1), [(Rs - 1.2, 0.35), (Rs - 0.1, 0.15), (Rs + 0.3, -0.75),
                                                         (Rs + 0.1, -0.95), (Rs - 1.2, -0.3)], 40, closed=True)
    nest(m, ['mossd12', 'moss12', 'bark12'], 16)
    shroom_litter(m, 4, ['red12', 'turq12', 'red12', 'lav12'], Rr=(0.85, 1.1),
                  spots=['cream12', 'G:gturq12', 'cream12', None])
    with layer(m, 'Orbit'):
        Ro2 = W / 2 + 3.6
        for i in range(8):
            a = i / 8 * TAU + 0.2
            p = pol(Ro2, a, 6.6 + 0.9 * math.sin(i * 1.7))
            if i % 2 == 0:
                cap = ['red12', 'turq12', 'red12', 'lav12'][i // 2]
                shroom(m, p - Vector((0, 0, 0.8)), (0, 0, 1), 0.85, 1.05, cap, stem='cream12',
                       gills='turqd12' if cap == 'turq12' else 'creamd12',
                       spots='cream12' if cap == 'red12' else None, n_spots=4, seed=i)
            else:
                spore(m, 'G:glav12' if i in (1, 5) else 'lav12', p, 0.5 if i in (1, 5) else 0.62,
                      ring=None if i in (1, 5) else 'lavl12')
    return build(m, 'Egg_R12_T4', P12, off)


def build_T5(off):
    """Glowcap Egg : bleu nuit couvert de champignons lumineux (chapeaux turquoise et lavande, pois lumineux),
    points de spores, gemme turquoise à l'avant, bouquet de champignons au sommet, mousse au pied,
    couronne de petits champignons qui tourne."""
    W, H = SIZES[5]
    m = Vox(H, seed=1205)
    egg_body(m, W, H, 'nblue12', 12051, bump=0.4)
    m.paint(lambda x, y, z: vnoise(x, y + 30, z, 51, 2.5) > 0.5, 'nblued12')
    m.paint(lambda x, y, z: vnoise(x + 9, y, z, 53, 2.0) > 0.62, 'nbluel12')
    m.paint(lambda x, y, z: z <= 2.0 + wave(math.atan2(y, x), 5, 0.6), 'mossd12')
    m.paint(lambda x, y, z: z == 3 and wave(math.atan2(y, x), 7, 1, 0.5) > -0.2, 'moss12')
    glow_dots(m, 'G:gturq12', 5, lambda x, y, z: 4 <= z <= 13, mind=4.0)
    glow_dots(m, 'turq12', 10, lambda x, y, z: 4 <= z <= 17, mind=2.4)
    glow_dots(m, 'lav12', 7, lambda x, y, z: 4 <= z <= 17, mind=2.4)
    medallion(m, FRONT, 11.8, 1.45, 'gemt12', gold='lav12', dark='violetd12')
    for i, (th, z, R, cap) in enumerate(((FRONT + 0.8, 6.0, 1.55, 'turq12'), (FRONT - 0.85, 7.6, 1.35, 'lav12'),
                                         (FRONT + 1.75, 9.6, 1.3, 'lav12'), (FRONT - 1.8, 5.0, 1.6, 'turq12'),
                                         (FRONT + 2.75, 5.6, 1.5, 'turq12'), (FRONT + 3.55, 9.4, 1.25, 'lav12'),
                                         (FRONT - 2.65, 9.4, 1.2, 'turq12'))):
        body_shroom(m, th, z, R * 1.25, R, cap, lean=0.8, kind='cone', stem='lavl12',
                    gills='turqd12' if cap == 'turq12' else 'creamd12', spots='G:gturq12' if cap == 'turq12' else
                    'turq12', n_spots=3, spot_r=0.2, seed=i)
    top_shroom(m, 0, 0, 1.9, 2.7, 'turq12', kind='cone', ch=2.8, stem='lavl12', gills='turqd12', spots='G:gturq12',
               n_spots=6, spot_r=0.28, seed=5)
    for i, (x, y) in enumerate(((2.6, -1.2), (-2.5, 1.0))):
        top_shroom(m, x, y, 1.3, 1.2, 'lav12', lean=0.6, kind='cone', stem='lavl12', gills='creamd12',
                   spots='turq12', n_spots=3, seed=10 + i)
    nest(m, ['mossd12', 'nblued12', 'moss12', 'bark12'], 18)
    shroom_litter(m, 4, ['turq12', 'lav12', 'turq12', 'violet12'], Rr=(0.75, 1.05), kind='cone', stem='lavl12',
                  spots=['G:gturq12', 'turq12', None, 'lavl12'])
    with layer(m, 'Crown'):
        shroom_crown(m, H - 7.0, [('turq12', 'cone', 'G:gturq12'), ('lav12', 'cone', 'turq12'),
                                  ('G:gturq12', 'cone', None), ('turq12', 'cone', 'lavl12'),
                                  ('lav12', 'cone', 'G:gturq12'), ('turq12', 'cone', None),
                                  ('violet12', 'cone', 'lavl12')], 1.2)
    return build(m, 'Egg_R12_T5', P12, off)


def _wing_zone(zr, half=4.2):
    return lambda a, z: abs(math.cos(a)) > 0.8 and zr - half < z < zr + half


def build_T6(off):
    """Mycelium Egg : violet nuit marbré, filaments de mycélium turquoise et lavande qui enlacent l'œuf (nœuds
    lumineux), champignons en étagère orange, bouquet de champignons au sommet, trio de champignons à l'avant,
    ailes en lamelles de champignon, spores et petits champignons en orbite."""
    W, H = SIZES[6]
    m = Vox(H, seed=1206)
    egg_body(m, W, H, 'night12', 12061, bump=0.45)
    m.paint(lambda x, y, z: vnoise(x, y, z, 61, 4.0) > 0.3, 'violetd12')
    m.paint(lambda x, y, z: vnoise(x, y + 7, z, 62, 2.5) > 0.6, 'nightd12')
    m.paint(lambda x, y, z: z <= 2.4 + wave(math.atan2(y, x), 6, 0.6), 'mossd12')
    m.paint(lambda x, y, z: z >= H - 3.2 + wave(math.atan2(y, x), 6, 0.6), 'violet12')
    glow_dots(m, 'lav12', 8, lambda x, y, z: 4 <= z <= 20, mind=3.0)
    zw = 14.5
    av = _wing_zone(zw)
    for i in range(6):
        filament(m, 'turq12', i / 6 * TAU + 0.3, 1.2, H - 4.5, 0.55 * (1 if i % 2 else -1), r=0.22, seed=i,
                 nodes='G:gturq12', n_nodes=2, avoid=av)
    for i in range(3):
        filament(m, 'lavl12', i / 3 * TAU + 1.1, 2.5, H - 7, -0.4, r=0.15, seed=20 + i, wob=0.9, avoid=av)
    for th, z, R in ((FRONT + 0.62, 7.0, 2.7), (FRONT - 0.7, 9.8, 2.4), (FRONT + math.pi, 8.0, 3.0),
                     (FRONT + math.pi + 0.65, 18.0, 2.1), (FRONT - 0.15, 3.6, 2.2)):
        shelf(m, th, z, R)
    for i, (da, z, R, cap) in enumerate(((0.0, 16.6, 1.6, 'turq12'), (-0.42, 14.6, 1.2, 'lav12'),
                                         (0.42, 14.8, 1.15, 'lav12'))):
        body_shroom(m, FRONT + da, z, R * 1.25, R, cap, lean=0.85, kind='cone', stem='lavl12',
                    gills='turqd12' if cap == 'turq12' else 'creamd12',
                    spots='G:gturq12' if cap == 'turq12' else 'turq12', n_spots=3, spot_r=0.16, seed=30 + i)
    top_shroom(m, 0, 0.3, 2.0, 3.1, 'violet12', ch=2.5, stem='lavl12', gills='lavl12', spots='lavl12', n_spots=7,
               spot_r=0.38, seed=7)
    for i, (x, y) in enumerate(((2.6, -1.5), (-2.6, -1.1))):
        top_shroom(m, x, y, 1.3, 1.25, 'turq12', lean=0.7, kind='cone', stem='lavl12', gills='turqd12',
                   spots='G:gturq12', n_spots=2, spot_r=0.15, seed=12 + i)
    nest(m, ['mossd12', 'violetd12', 'bark12', 'turqd12'], 20)
    shroom_litter(m, 5, ['orange12', 'turq12', 'lav12', 'red12', 'turq12'], Rr=(0.8, 1.1),
                  spots=[None, 'G:gturq12', 'turq12', 'cream12', None])
    for s, g in ((1, 'WingR'), (-1, 'WingL')):
        with layer(m, g):
            r = rs(m, 0 if s > 0 else math.pi, zw) - 0.9
            gill_wing(m, (s * r, 0.4, zw), s, 9.6, a_hi=60, a_lo=-34, n=11, mem='lav12', gill='lavl12',
                      rim='violet12', glow='G:gturq12', n_glow=4, inner=('violetl12', 'lav12'), knob='violet12')
    with layer(m, 'Orbit'):
        Ro = W / 2 + 4.8
        for i in range(10):
            a = i / 10 * TAU + 0.3
            zz = 3.2 + (i % 3) * 1.1
            p = pol(Ro, a, zz)
            if i in (0, 4, 7):
                cap = ['turq12', 'orange12', 'violet12'][(0, 4, 7).index(i)]
                shroom(m, p - Vector((0, 0, 0.9)), (0, 0, 1), 0.95, 1.2, cap, stem='lavl12',
                       gills='turqd12' if cap == 'turq12' else 'creamd12',
                       spots='G:gturq12' if cap == 'turq12' else None, n_spots=3, kind='cone', seed=i)
            elif i % 2:
                spore(m, 'G:gturq12' if i in (1, 5) else 'G:glav12', p, 0.55)
            else:
                spore(m, 'lav12', p, 0.75, ring='turq12')
    return build(m, 'Egg_R12_T6', P12, off)


def build_T7(off):
    """Moonshroom Egg : grand œuf violet et lune (bandes de la mousse au violet nuit puis lavande, cratères de lune),
    forêt de champignons lumineux au sommet devant un croissant de lune, filaments de mycélium, champignons en
    étagère, gemme de lune, collier de spores, couronne de champignons lumineux, halo de spores, grandes ailes en
    lamelles lumineuses, anneau de spores et champignons en orbite."""
    W, H = SIZES[7]
    m = Vox(H, seed=1207)
    egg_body(m, W, H, 'violet12', 12071, bump=0.45)
    seq = ['mossd12', 'moss12', 'night12', 'violetd12', 'violet12', 'lav12', 'moss12']
    edges = [2.8, 4.2, 8.2, 12.6, 17.4, 25.6]
    for c in m.surface():
        x, y, z = c
        th = math.atan2(y, x)
        idx = 0
        for i, e in enumerate(edges):
            if z > e + wave(th, 7 if i != 1 else 9, 0.7, i * 0.9):
                idx = i + 1
        m.cells[c] = seq[idx]
    paint_craters(m, 7, lambda x, y, z: 18.5 <= z <= 24.5 and m.cells[(x, y, z)] == 'lav12', rad=(1.3, 2.1),
                  rim='lavl12', inside='violetl12', mind=4.6)
    paint_craters(m, 5, lambda x, y, z: 13.5 <= z <= 16.5 and m.cells[(x, y, z)] == 'violet12', rad=(1.1, 1.6),
                  rim='violetl12', inside='violetd12', mind=5.0)
    glow_dots(m, 'G:gturq12', 6, lambda x, y, z: 5 <= z <= 12, mind=4.0)
    glow_dots(m, 'turq12', 10, lambda x, y, z: 5 <= z <= 17, mind=3.0)
    moss_tufts(m, 18, lambda x, y, z: m.cells.get((x, y, z)) in ('moss12', 'mossd12') and 1 <= z <= 5, mind=1.6)
    moss_tufts(m, 10, lambda x, y, z: m.cells.get((x, y, z)) == 'moss12' and z >= 25, mind=1.4)
    zw = 16.0
    av = _wing_zone(zw, 4.6)
    for i in range(4):
        filament(m, 'turq12', i / 4 * TAU + 0.9, 1.5, 12.0, 0.5 * (1 if i % 2 else -1), r=0.24, seed=40 + i,
                 nodes='G:gturq12', n_nodes=2, avoid=av)
    for th, z, R in ((FRONT + math.pi, 9.5, 3.2), (FRONT + math.pi - 0.75, 6.4, 2.6), (FRONT + math.pi + 0.8, 11.4,
                                                                                       2.4)):
        shelf(m, th, z, R)
    medallion(m, FRONT, 10.0, 1.9, 'gemt12', gold='lav12', dark='violetd12')
    for s in (1, -1):
        body_shroom(m, FRONT + s * 0.78, 6.2, 2.0, 1.75, 'turq12', lean=0.7, kind='cone', stem='lavl12',
                    gills='turqd12', spots='G:gturq12', n_spots=4, spot_r=0.24, seed=50 + s)
        body_shroom(m, FRONT + s * 1.55, 9.8, 1.6, 1.35, 'lav12', lean=0.8, kind='cone', stem='lavl12',
                    gills='creamd12', spots='turq12', n_spots=3, seed=52 + s)
    body_shroom(m, FRONT + math.pi + 0.05, 13.2, 2.4, 2.2, 'red12', lean=0.75, stem='cream12', gills='creamd12',
                spots='cream12', n_spots=7, spot_r=0.34, skirt='cream12', seed=55)
    necklace(m, 'lavl12', lambda a: 13.0 + 0.8 * math.sin(3 * (a - FRONT)), 0.5, sub=2, lift=0.12, bead='turq12',
             br=0.3, keep=lambda a: abs(math.cos(a)) < 0.72 and abs((a - FRONT + math.pi) % TAU - math.pi) > 0.42
             and abs((a - FRONT) % TAU - math.pi) > 0.5)
    # forêt de champignons lumineux au sommet, devant un croissant de lune
    tz = ztop(m, 0, 0)
    CR, cz, ck, co, csp = 5.4, tz + 4.6, 0.9, 0.34, math.pi / 2 - 0.4
    crescent(m, 'moon12', (0, 2.6, cz), CR, k=ck, off=co, spin=csp, thick=1.0, back='moond12',
             craters=[(-0.79, 0.05, 0.06), (-0.66, -0.45, 0.05), (-0.62, 0.5, 0.045)], glow_rim='G:gmoon12', glow_r=0.3)
    hx = (1 - ck ** 2 + co ** 2) / (2 * co)
    ha = csp + math.atan2(math.sqrt(max(0.0, 1 - hx * hx)), hx)
    orn_star(B(m, 'G:gmoon12', False), Vector((CR * math.cos(ha), 1.9, cz + CR * math.sin(ha))), 0.9, 0.36, 0.25,
             normal=(0, -1, 0))
    top_shroom(m, 0, -0.8, 2.8, 3.2, 'turq12', kind='cone', ch=3.3, stem='lavl12', gills='turqd12',
               spots='G:gturq12', n_spots=7, spot_r=0.32, seed=60)
    forest = [(-2.0, 3.6, 1.9, 'lav12', 'turq12'), (-1.2, 3.8, 1.5, 'red12', 'cream12'),
              (-0.42, 3.3, 1.3, 'violet12', 'G:glav12'), (0.42, 3.3, 1.3, 'turq12', 'G:gturq12'),
              (1.2, 3.8, 1.6, 'lav12', 'turq12'), (2.0, 3.6, 1.8, 'turq12', 'lavl12')]
    for i, (da, rr, R, cap, sp) in enumerate(forest):
        a = FRONT + da
        top_shroom(m, rr * math.cos(a), rr * math.sin(a), R * 1.3, R, cap, lean=0.5,
                   kind='dome' if cap == 'red12' else 'cone', stem='lavl12' if cap != 'red12' else 'cream12',
                   gills='turqd12' if cap == 'turq12' else 'creamd12', spots=sp, n_spots=4, spot_r=R * 0.17,
                   seed=61 + i)
    nest(m, ['mossd12', 'violetd12', 'bark12', 'moss12'], 24)
    shroom_litter(m, 6, ['turq12', 'red12', 'lav12', 'orange12', 'turq12', 'violet12'], Rr=(0.9, 1.3),
                  kind='cone', stem='lavl12', spots=['G:gturq12', 'cream12', 'turq12', None, 'lavl12', 'lavl12'])
    with layer(m, 'Crown'):
        shroom_crown(m, H - 7.6, [('turq12', 'cone', 'G:gturq12'), ('lav12', 'cone', 'turq12'),
                                  ('G:gturq12', 'cone', None), ('violet12', 'cone', 'lavl12'),
                                  ('turq12', 'cone', 'lavl12'), ('lav12', 'cone', 'G:gturq12'),
                                  ('G:glav12', 'cone', None), ('red12', 'dome', 'cream12')], 1.35)
    with layer(m, 'Halo'):
        zh, Rh = cz + CR * math.sin(ha) + 2.6, 5.6
        orn_torus(B(m, 'lav12', True), (0, 0, zh), Rh, 0.36, seg=64, sides=8)
        for i in range(8):
            a = i / 8 * TAU
            if i % 2 == 0:
                spore(m, 'G:gturq12', pol(Rh, a, zh + 0.5), 0.46)
            else:
                spore(m, 'lavl12', pol(Rh, a, zh + 0.55), 0.55, ring='turq12', tilt=0.4)
    for s, g in ((1, 'WingR'), (-1, 'WingL')):
        with layer(m, g):
            r = rs(m, 0 if s > 0 else math.pi, zw) - 1.0
            gill_wing(m, (s * r, 0.5, zw), s, 14.5, a_hi=60, a_lo=-12, n=15, mem='lav12', gill='lavl12',
                      rim='turq12', glow='G:gturq12', n_glow=6, glow_r=0.45, rim_r=0.5, gill_r=0.2,
                      inner=('violetl12', 'lav12'), knob='turq12')
    with layer(m, 'Orbit'):
        Ro, zo, tl = 14.2, 5.2, 0.13
        rot = orn_torus(B(m, 'violetl12', True), (0, 0, zo), Ro, 0.3, tilt=tl, seg=96, sides=8)
        caps = ['turq12', 'red12', 'lav12']
        for i in range(6):
            a = i / 6 * TAU
            p = Vector((0, 0, zo)) + rot @ Vector((Ro * math.cos(a), Ro * math.sin(a), 0))
            if i % 2 == 0:
                spore(m, 'G:glav12', p, 0.75, ring='lav12', tilt=0.9)
            else:
                cap = caps[i // 2]
                shroom(m, p - Vector((0, 0, 1.2)), (0, 0, 1), 1.2, 1.45, cap, stem='lavl12' if cap != 'red12' else
                       'cream12', gills='turqd12' if cap == 'turq12' else 'creamd12', kind='dome' if cap == 'red12'
                       else 'cone', spots='cream12' if cap == 'red12' else 'G:gturq12', n_spots=4, seed=70 + i)
        for i in range(3):
            a = i / 3 * TAU + 0.5
            cap = ['red12', 'turq12', 'lav12'][i]
            shroom(m, pol(17.6, a, 0.6 + i * 1.0), (0, 0, 1), 1.5, 2.1, cap,
                   stem='cream12' if cap == 'red12' else 'lavl12', gills='turqd12' if cap == 'turq12' else 'creamd12',
                   kind='dome' if cap == 'red12' else 'cone', spots='cream12' if cap == 'red12' else 'lavl12',
                   n_spots=5, spot_r=0.26, seed=80 + i)
            b = a + TAU / 6
            spore(m, 'G:gturq12' if i != 1 else 'lav12', pol(17.4, b, 4.6 - i * 1.0), 0.7,
                  ring=None if i != 1 else 'turq12')
    return build(m, 'Egg_R12_T7', P12, off)


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
    drop('Egg_R12_T%d' % n)
    random.seed(1200 + n)
    coll = BUILDERS[n]((OFFSETS[n], 0, 0))
    obs = [o for o in coll.objects if o.type == 'MESH']
    for o in list(obs):
        if not len(o.data.vertices):
            bpy.data.objects.remove(o, do_unlink=True)
    obs = [o for o in coll.objects if o.type == 'MESH']
    tris = sum(len(p.vertices) - 2 for o in obs for p in o.data.polygons)
    zs = [(o.matrix_world @ v.co).z for o in obs for v in o.data.vertices]
    xs = [(o.matrix_world @ v.co).x for o in obs for v in o.data.vertices]
    print('Egg_R12_T%d : %d objets, %d triangles, x %.1f..%.1f, z %.2f..%.2f, max tris/objet %d' % (
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
    colls = [bpy.data.collections.get('Egg_R12_T%d' % n) for n in sorted(BUILDERS)]
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


print("eggs_r12 chargé")
