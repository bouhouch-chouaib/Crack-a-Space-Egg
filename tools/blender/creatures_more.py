# Créatures des anneaux 2 à 7 (charger voxkit.py puis creatures.py, puis ce fichier).
# Même règle que l'anneau 1 : mignonnes au début, de plus en plus grandes et impressionnantes avec la rareté.

import math
from mathutils import Vector, Matrix


# AIDES COMMUNES ------------------------------------------------------------------------------

def legs4(m, x, ys, r, h, key, foot=None):
    for s in (-1, 1):
        for y in ys:
            m.ell((s * x, y, h * 0.5 + 0.3), (r, r, h * 0.5 + 0.6), key)
            if foot:
                m.ell((s * x, y - 0.5, 0.5), (r * 1.15, r * 1.35, 0.7), foot)


def shadow(m, r):
    """Ombre au sol des créatures qui flottent (elle pose aussi le bas du modèle au sol)."""
    orn_ball(B(m, 'shadow', True), (0, 0, 0.05), r, scale=(1, 1, 0.04))


def flame(m, base, h, w=1.0, k1='G:flame', k2='G:flamey', back=0.4):
    b = Vector(base)
    orn_sweep(B(m, k1, True), [b, b + Vector((0, back * h * 0.5, h * 0.55)), b + Vector((0, back * h, h))], [w, w * 0.62, 0.04], sides=10)
    orn_sweep(B(m, k2, True), [b + Vector((0, 0.1, 0.2 * h)), b + Vector((0, back * h * 0.45, h * 0.5)), b + Vector((0, back * h * 0.8, h * 0.78))], [w * 0.55, w * 0.35, 0.03], sides=8)


def crystals_on(m, center, radii, keys, n=60, zmin=0.15, ymin=-0.4, bias=(0, 0.45, 0.1), L=(2.8, 4.2), R=(0.6, 0.85), glow=None, every=9):
    c = Vector(center)
    for i, d in enumerate(fib_dirs(n)):
        if d.z < zmin or d.y < ymin:
            continue
        base = c + Vector((d.x * radii[0], d.y * radii[1], d.z * radii[2])) * 0.88
        key = glow if (glow and i % every == 0) else keys[i % len(keys)]
        orn_crystal(B(m, key), base, (d + Vector(bias)).normalized(), m.rnd.uniform(*L), m.rnd.uniform(*R))


def spine(m, pts, key, L, r, lean=0.35):
    for p in pts:
        orn_cone(B(m, key), p, (0, lean, 1), L, r, sides=6)


def horns2(m, x, y, z, key, size=1.0, spread=1.0, back=1.0):
    for s in (-1, 1):
        p0 = Vector((s * x, y, z))
        orn_sweep(B(m, key, True), [p0, p0 + Vector((s * 1.2 * spread, 2.4 * back, 2.6)) * size, p0 + Vector((s * 1.6 * spread, 5.4 * back, 3.4)) * size, p0 + Vector((s * 1.2 * spread, 7.2 * back, 2.2)) * size],
                  [0.95 * size, 0.7 * size, 0.4 * size, 0.06], sides=12, profile=ribs(6, 0.08))


def fangs(m, x, z, key='white', L=1.2, r=0.32, up=False):
    for s in (-1, 1):
        y = front_y(m, s * x, z)
        orn_cone(B(m, key), (s * x, y + 0.3, z), (0, -0.25, 1 if up else -1), L, r, sides=6)


def feather_wings(m, rx, y, z, span, k1, k2, kc, arm, glow_cov=False):
    for s, nm in ((-1, 'WingL'), (1, 'WingR')):
        with layer(m, nm):
            root = Vector((s * rx, y, z))
            pts = [root + Vector((s * a * span, b, c * span)) for (a, b, c) in ((0, 0, 0), (0.27, 0.4, 0.33), (0.62, 0.8, 0.53), (0.87, 1.0, 0.56), (1.0, 1.1, 0.5))]
            orn_sweep(B(m, arm, True), pts, [0.75, 0.65, 0.5, 0.35, 0.12], sides=10)

            def on_arm(f):
                i = min(int(f * 4), 3)
                return pts[i].lerp(pts[i + 1], f * 4 - i)
            for k in range(8):
                f = 0.08 + 0.9 * k / 7
                phi = math.radians(12 + 95 * (k / 7))
                L = span * (0.45 + 0.3 * math.sin(k / 7 * math.pi * 0.85))
                r0 = on_arm(f) + Vector((0, 0.25, -0.2))
                tip = r0 + Vector((s * math.sin(phi) * L, 0.5, -math.cos(phi) * L))
                orn_feather(B(m, k1 if k % 2 == 0 else k2, True), r0, tip, span * 0.1)
            for k in range(6):
                f = 0.05 + 0.85 * k / 5
                phi = math.radians(20 + 85 * (k / 5))
                L = span * (0.24 + 0.1 * math.sin(k / 5 * math.pi))
                r0 = on_arm(f) + Vector((0, -0.2, 0.1))
                tip = r0 + Vector((s * math.sin(phi) * L, 0.2, -math.cos(phi) * L))
                orn_feather(B(m, kc, True), r0, tip, span * 0.085)


def membrane_wings(m, rx, y, z, span, membr, arm, vein=None):
    for s, nm in ((-1, 'WingL'), (1, 'WingR')):
        with layer(m, nm):
            root = Vector((s * rx, y, z))
            knuckle = root + Vector((s * 0.55 * span, 0.15 * span, 0.6 * span))
            tip = root + Vector((s * span, 0.25 * span, 0.4 * span))
            orn_sweep(B(m, arm, True), [root, knuckle, tip], [0.08 * span, 0.06 * span, 0.015 * span], sides=10)
            orn_cone(B(m, arm), knuckle, (s * 0.3, 0, 1), 0.15 * span, 0.04 * span, sides=6)
            for f in (tip, root + Vector((s * 0.92 * span, 0.24 * span, -0.07 * span)), root + Vector((s * 0.7 * span, 0.2 * span, -0.33 * span)), root + Vector((s * 0.4 * span, 0.16 * span, -0.43 * span))):
                orn_sweep(B(m, membr, True), [knuckle.lerp(root, 0.35), knuckle.lerp(f, 0.5) + Vector((0, 0.3, -0.06 * span)), f], [0.045 * span, 0.19 * span, 0.005 * span], sides=6, flat=0.2, twist_up=Vector((0, 1, 0)))
                orn_sweep(B(m, vein or arm, True), [knuckle, f], [0.025 * span, 0.01 * span], sides=6)


def orbit_stars(m, center, R, n, key, size=1.0):
    with layer(m, 'Orbit'):
        c = Vector(center)
        for k in range(n):
            a = k / n * math.tau + 0.5
            orn_star(B(m, key), c + Vector((math.cos(a) * R, math.sin(a) * R, math.sin(a * 2) * 1.2)), 1.0 * size, 0.42 * size, 0.33 * size)


def coil(m, key, center, R, turns, z0, z1, r0, r1, n=40):
    c = Vector(center)
    pts, rads = [], []
    for i in range(n + 1):
        t = i / n
        a = t * turns * math.tau
        rr = R * (1 - 0.35 * t)
        pts.append(c + Vector((math.cos(a) * rr, math.sin(a) * rr, z0 + (z1 - z0) * t)))
        rads.append(r0 + (r1 - r0) * t)
    m.chain(pts, rads, key)
    return pts


def fireball(m, p, back, core='G:flamey', tail='G:flame', s=1.0):
    p = Vector(p)
    back = Vector(back).normalized()
    orn_ball(B(m, core, True), p, 0.9 * s)
    orn_cone(B(m, tail, True), p + back * 0.3, back, 3.6 * s, 0.8 * s, sides=12)


def planet(m, p, r, key, ringkey):
    orn_ball(B(m, key, True), p, r, sub=2)
    orn_torus(B(m, ringkey, True), p, r * 1.65, r * 0.16, tilt=0.45, seg=32, sides=6)


# PALETTE DES ANNEAUX 2 À 7 -------------------------------------------------------------------

PALC.update({
    'shadow': '#2c2a3a', 'gold': '#ffc21a', 'golddk': '#e08a10', 'flame': '#ff5a0a', 'flamey': '#ffd23a', 'beak': '#ff9a2a',
    # 2. Glace
    'peng': '#1e2a4a', 'pengw': '#f4f8ff', 'icec': '#9fe8ff', 'icecd': '#4ec3ff', 'icecg': '#6af0ff',
    'mothw': '#f6f2ff', 'mothfur': '#e2dcff', 'mothwing': '#dff2ff', 'mothant': '#b8a8e8',
    'otter': '#7cc4ff', 'otterlt': '#d6eeff', 'otterdk': '#3a86d0',
    'seal': '#eef6ff', 'seallt': '#ffffff', 'sealdk': '#9cc0e0', 'comet': '#5ff0ff',
    'owl': '#3a2a6a', 'owllt': '#6a4aa8', 'owlface': '#d8d0f0', 'aurg': '#2dffa0', 'aurv': '#a35cff', 'aurp': '#ff5cd6',
    'yeti': '#e8f4ff', 'yetidk': '#b8d4f0', 'yetiface': '#4a7ad0',
    # 3. Magma
    'slug': '#3a2a2a', 'slugdk': '#241818', 'lava': '#ff5a0a', 'lavay': '#ffb21a',
    'crab': '#e8402e', 'crablt': '#ff8a6a', 'crabshell': '#5a3a30',
    'newt': '#ff8a2a', 'newtlt': '#ffd08a', 'newtdk': '#c8501a',
    'obs': '#24182c', 'obslt': '#4a3060',
    'phx': '#ffc21a', 'phxr': '#ff4a1a', 'phxo': '#ff9a1a',
    'wyrm': '#3a2a2a', 'wyrmdk': '#201414', 'wyrmmem': '#ff6a2a',
    # 4. Nébuleuse
    'jelly': '#ff7ad8', 'jellylt': '#ffc4f0', 'jellyt': '#c87aff', 'star': '#fff27a',
    'kit': '#c8a8ff', 'kitlt': '#ece0ff', 'cloud': '#fbf8ff', 'earpink': '#ffb0c4',
    'whale': '#6ac8ff', 'whalelt': '#d4f0ff', 'whaledk': '#3a8ad8', 'nebc': '#ff9ce0', 'nebv': '#b88cff',
    'ray': '#1e1e4a', 'raylt': '#3a3a7a', 'prR': '#ff3a5a', 'prY': '#ffe03a', 'prG': '#4aff7a', 'prB': '#3ac8ff', 'prV': '#a04aff', 'prismc': '#7affff',
    'lion': '#ffd27a', 'lionlt': '#fff0c8', 'liondk': '#c88a3a', 'nova': '#fff27a', 'novaw': '#ffffff', 'novao': '#ffb21a',
    'uni': '#f8f4ff', 'unidk': '#d0c8f0', 'galh': '#c8a8ff', 'galp': '#ff5cd6', 'galc': '#3ae8ff', 'galv': '#8a4aff',
    # 5. Dévoreur
    'beetle': '#1e5a3a', 'beetlelt': '#3a9a5a', 'beetledk': '#123a24',
    'bat': '#5a2a8a', 'batlt': '#8a5ac8', 'batmem': '#3a1a5a', 'baty': '#ffe03a',
    'shark': '#16141e', 'sharkb': '#2a2a5a', 'voidc': '#7a5aff',
    'hound': '#2e2a38', 'houndlt': '#4a4458', 'teal': '#2ff0e0', 'smoke': '#5a3a8a',
    'serp': '#3a1a5a', 'serplt': '#6a3a9a', 'rune': '#c87aff',
    'eclip': '#14101c', 'eclipdk': '#0a080e', 'cosmo': '#ff5cd6', 'eclipg': '#ffc21a', 'eclipm': '#4a1a6a',
    # 6. Faille
    'snail': '#3ac8b8', 'snaillt': '#9af0e0', 'shellc': '#e8b84a', 'clockw': '#fff8e8', 'clockd': '#2a2030',
    'cat': '#2e2e3e', 'catlt': '#5a5a72', 'glc': '#2ff0ff', 'glm': '#ff3ae0',
    'pandaw': '#f8f8f8', 'pandab': '#1e1e26', 'time': '#7affff',
    'tort': '#6aa04a', 'tortdk': '#3a6a2a', 'glass': '#cdeeff', 'sand': '#ffd27a',
    'grif': '#c8902a', 'griflt': '#ffd88a', 'grifw': '#fff8ee', 'rift': '#ff3ae0', 'riftc': '#3af0ff',
    'krak': '#1a3a8a', 'kraklt': '#3a6ad0', 'quasar': '#e8ffff', 'quasarc': '#5ff0ff',
    # 7. Nid
    'chick': '#ffe04a', 'chicklt': '#fff4a0', 'shell7': '#3a2a6a', 'shell7lt': '#6a4aa8',
    'yolk': '#ffc21a', 'yolklt': '#ffe68a', 'yolkdk': '#e8901a',
    'raptor': '#4a8a3a', 'raptorlt': '#9ad06a', 'amber': '#ffaa2a', 'amberdk': '#c8701a',
    'drake': '#8a4a2a', 'drakelt': '#c8804a', 'twig': '#7a4a24', 'eggg': '#ffe27a', 'drakemem': '#e8a060',
    'bee': '#ffc21a', 'beeb': '#1e1a20', 'beewing': '#d8f0ff', 'hivec': '#ff5cd6',
    'cosm': '#2a1a6a', 'cosmp': '#ff5cd6', 'cosmc': '#3ae8ff', 'cosmv': '#a04aff', 'cosmw': '#fffaf0',
})


# ANNEAU 2 : GLACE ----------------------------------------------------------------------------

def c2_1():  # Frostling (Common) : bébé pingouin, couronne de cristaux de glace
    m = Vox(16, seed=21)
    m.ell((0, 1, 5.5), (4.6, 4.2, 5.6), 'peng')
    m.ell((0, -0.5, 11.6), (4.4, 4, 4), 'peng')
    for s in (-1, 1):
        m.ell((s * 4.6, 0.5, 6), (0.9, 1.6, 3.2), 'peng')
        m.ell((s * 1.8, -2.4, 0.5), (1.4, 2, 0.6), 'beak')
    m.paint(lambda x, y, z: y < -1.2 and z < 9.5 and abs(x) < 3.4, 'pengw')
    m.paint(lambda x, y, z: y < -2.3 and 9.4 < z < 13.6 and abs(x) < 3.4, 'pengw')
    eyes(m, 1.8, 12.4, r=1.15)
    cheeks(m, 2.9, 10.8, 0.7)
    orn_cone(B(m, 'beak'), (0, front_y(m, 0, 11) + 0.4, 11), (0, -1, -0.15), 1.6, 0.7, sides=8)
    for (x, y, L, r, d) in ((0, 0, 2.6, 0.7, (0, 0, 1)), (1.4, 0.3, 1.8, 0.5, (0.5, 0.1, 1)), (-1.4, 0.3, 1.8, 0.5, (-0.5, 0.1, 1))):
        orn_crystal(B(m, 'icec' if r > 0.6 else 'icecd'), (x, y - 0.5, 15.0), d, L, r)
    return m


def c2_2():  # Snow Moth (Uncommon) : papillon de nuit duveteux, ailes de flocons
    m = Vox(16, seed=22)
    m.ell((0, 2.5, 7), (2.6, 4.2, 2.6), 'mothw')
    m.ell((0, -1, 7.5), (3.6, 1.8, 3.4), 'mothfur')
    m.ell((0, -3.4, 8.2), (3, 2.6, 2.8), 'mothw')
    eyes(m, 1.5, 8.6, r=1.0)
    cheeks(m, 2.3, 7.4, 0.55)
    for s in (-1, 1):
        orn_sweep(B(m, 'mothant', True), [(s * 0.8, -4.0, 10.6), (s * 1.8, -4.6, 12.6), (s * 2.8, -4.4, 13.6)], [0.2, 0.15, 0.08], sides=6)
        orn_ball(B(m, 'G:icecg', True), (s * 2.9, -4.4, 13.8), 0.45)
    for s, nm in ((-1, 'WingL'), (1, 'WingR')):
        with layer(m, nm):
            orn_ball(B(m, 'mothwing', True), (s * 5.2, 0.5, 9.6), 3.4, scale=(1.1, 0.16, 0.9))
            orn_ball(B(m, 'mothwing', True), (s * 4.0, 3.0, 5.6), 2.4, scale=(1.0, 0.16, 0.8))
            for (cx, cz, r) in ((s * 5.4, 10.0, 1.1), (s * 4.1, 5.6, 0.8)):
                orn_star(B(m, 'G:icecg'), (cx, 0.0 if r > 1 else 2.5, cz), r, r * 0.4, 0.15, normal=(0, -1, 0))
    shadow(m, 3.2)
    return m


def c2_3():  # Glacier Otter (Rare) : loutre bleu clair qui serre un éclat de glace
    m = Vox(17, seed=23)
    m.ell((0, 2, 6), (3.8, 5.4, 4.4), 'otter')
    m.ell((0, -3.8, 10.8), (4, 3.8, 3.6), 'otter')
    m.ell((0, -7.0, 9.8), (2.3, 1.5, 1.6), 'otterlt')
    for s in (-1, 1):
        m.ell((s * 3.0, -2.6, 13.6), (0.9, 0.7, 0.9), 'otterdk')
        m.ell((s * 2.4, 3.5, 1.2), (1.6, 2.4, 1.3), 'otterdk')
        m.chain([(s * 3.2, -1.8, 8.6), (s * 2.2, -4.6, 7.2), (s * 0.9, -5.6, 7.0)], [1.1, 1.0, 0.9], 'otter')
    m.paint(lambda x, y, z: y < -1 and z < 9 and abs(x) < 3, 'otterlt')
    with layer(m, 'Tail'):
        m.chain([(0, 7.2, 3.2), (0, 9.6, 2.2), (0, 11.6, 1.6)], [1.6, 1.4, 1.0], 'otterdk')
    eyes(m, 1.9, 11.6, r=1.15)
    cheeks(m, 3.0, 10.2, 0.7)
    nose(m, 0, 10.4, 0.7)
    orn_crystal(B(m, 'icec'), (0, -6.4, 4.6), (0, -0.2, 1), 5.0, 1.0)
    orn_crystal(B(m, 'G:icecg'), (0.4, -6.6, 5.0), (0.1, -0.3, 1), 3.0, 0.45)
    return m


def c2_4():  # Comet Seal (Epic) : gros phoque blanc, corne de cristal, traîne de comète
    m = Vox(18, seed=24)
    m.ell((0, 2, 5.4), (5.4, 8.5, 5), 'seal')
    m.ell((0, -6.4, 10), (4.6, 4.4, 4.2), 'seal')
    m.ell((0, -10.4, 9.0), (2.8, 2.0, 1.9), 'seallt')
    for s in (-1, 1):
        m.ell((s * 5.4, -2.6, 1.6), (3.0, 1.8, 0.9), 'sealdk')
    m.spots('sealdk', 6, 1.1, test=lambda x, y, z: z > 6)
    m.paint(lambda x, y, z: z > 8 and abs(math.sin(x * 0.7 + y * 0.4)) < 0.1, 'G:comet')
    fierce_eyes(m, 2.2, 11.4, 1.25, 'comet')
    nose(m, 0, 9.6, 0.8)
    fangs(m, 1.2, 8.0, L=1.8, r=0.38)
    orn_crystal(B(m, 'icec'), (0, -8.6, 13.0), (0, -0.55, 1), 5.5, 0.9, sides=8)
    with layer(m, 'Tail'):
        for s in (-1, 1):
            m.ell((s * 2.2, 11.4, 2.2), (2.6, 2.2, 0.9), 'sealdk')
        for k, (dx, h) in enumerate(((0, 9), (-1.6, 6.5), (1.6, 6.5))):
            b = Vector((dx, 8.0, 9.0))
            orn_sweep(B(m, 'G:comet', True), [b, b + Vector((0, h * 0.5, 1.2)), b + Vector((dx * 0.3, h, 0.6))], [1.6 - k * 0.3, 1.0, 0.04], sides=10)
        orn_star(B(m, 'G:star'), (0, 7.4, 10.8), 1.8, 0.8, 0.6, normal=(0, -1, 0.3))
    return m


def c2_5():  # Aurora Owl (Legendary) : grand hibou aux plumes d'aurore, aigrettes lumineuses
    m = Vox(24, seed=25)
    m.ell((0, 1.5, 8.5), (5.2, 4.8, 7), 'owl')
    m.ell((0, -0.4, 16.4), (5.6, 4.8, 4.6), 'owl')
    m.ell((0, -4.2, 16.2), (4.4, 1.0, 3.8), 'owlface')
    m.paint(lambda x, y, z: y < -2 and 4 < z < 13 and abs(x) < 4 and (x + z) % 3 == 0, 'owllt')
    for s in (-1, 1):
        m.ell((s * 2.2, -0.5, 0.9), (1.5, 2.2, 1.0), 'gold')
        for k in range(3):
            orn_cone(B(m, 'golddk'), (s * (1.4 + k * 0.8), -2.4, 0.6), (0, -1, -0.4), 1.2, 0.3, sides=6)
        orn_feather(B(m, 'G:aurg', True), (s * 3.6, -1.0, 19.6), (s * 6.4, 0.0, 24.0), 1.1)
        orn_feather(B(m, 'G:aurv', True), (s * 2.8, -0.6, 20.0), (s * 4.6, 0.6, 24.4), 0.8)
    fierce_eyes(m, 2.2, 16.8, 1.5, 'aurg', inset=0.2)
    orn_cone(B(m, 'gold'), (0, front_y(m, 0, 15) + 0.4, 15.0), (0, -0.7, -1), 2.0, 0.7, sides=8)
    feather_wings(m, 4.6, 2.0, 11.5, 11.0, 'aurg', 'aurv', 'G:aurp', 'owllt')
    with layer(m, 'Tail'):
        for k in range(5):
            a = (k - 2) * 0.32
            orn_feather(B(m, 'aurv' if k % 2 else 'aurg', True), (0, 5.0, 4.0), (math.sin(a) * 6, 9.5, 1.0 + math.cos(a) * 2.5), 1.1, up=(0, 0, 1))
    with layer(m, 'Orbit'):
        for i, k in enumerate(('G:aurg', 'G:aurv', 'G:aurp')):
            orn_torus(B(m, k, True), (0, 1, 15 + i * 1.2), 9.0 - i * 0.6, 0.22, tilt=0.25 + i * 0.1, arc=(i / 3, i / 3 + 0.45), seg=60, sides=6)
    return m


def c2_6():  # Crystal Yeti (Mythic) : yéti géant couvert de cristaux de glace
    m = Vox(32, seed=26)
    for s in (-1, 1):
        m.ell((s * 3.0, 1, 3.8), (2.6, 2.8, 4.0), 'yeti')
        m.ell((s * 3.2, -0.6, 0.7), (2.8, 3.2, 1.0), 'yetidk')
    m.ell((0, 1, 13), (7, 5.4, 7.6), 'yeti')
    m.ell((0, -0.8, 22.2), (5.2, 4.8, 4.6), 'yeti')
    m.ell((0, -4.6, 21.6), (3.6, 1.2, 3.2), 'yetiface')
    for s in (-1, 1):
        m.chain([(s * 7.0, 1, 17), (s * 9.0, -0.5, 12), (s * 9.0, -2.5, 8)], [2.6, 2.3, 2.0], 'yeti')
        m.ell((s * 9.0, -3.2, 6.6), (2.6, 2.6, 2.4), 'yetiface')
    m.paint(lambda x, y, z: (x * 3 + z * 2) % 5 == 0 and z > 4, 'yetidk')
    fierce_eyes(m, 1.8, 22.4, 1.2, 'icecg', inset=0.2)
    fangs(m, 1.5, 20.0, L=1.6, r=0.42, up=True)
    crystals_on(m, (0, 2.5, 15), (7, 5.6, 7.6), ['icec', 'icecd'], n=70, zmin=0.25, ymin=-0.2, L=(3.0, 5.5), R=(0.8, 1.2), glow='G:icecg')
    for s in (-1, 1):
        orn_crystal(B(m, 'icec'), (s * 7.4, 1.5, 19.0), (s * 0.6, 0.2, 1), 6.0, 1.3)
    for (x, L) in ((0, 7.0), (2.4, 5.0), (-2.4, 5.0), (4.0, 3.4), (-4.0, 3.4)):
        orn_crystal(B(m, 'G:icecg' if x == 0 else 'icec'), (x, 0, 26.0), (x * 0.12, 0.1, 1), L, 1.0 if x == 0 else 0.75)
    with layer(m, 'Orbit'):
        for k in range(5):
            a = k / 5 * math.tau
            orn_crystal(B(m, 'icecd' if k % 2 else 'icec'), (math.cos(a) * 12, 1 + math.sin(a) * 12, 16 + (k % 2) * 3), (0.15, 0.1, 1), 3.4, 1.0, double=True)
    return m


# ANNEAU 3 : MAGMA ----------------------------------------------------------------------------

def c3_1():  # Cinder Slug (Common) : petite limace sombre à taches de lave
    m = Vox(10, seed=31)
    m.ell((0, 1.5, 2.6), (3.2, 6.4, 2.6), 'slug')
    m.ell((0, -4.2, 4.6), (3.0, 3.0, 3.4), 'slug')
    m.paint(lambda x, y, z: z <= 0, 'slugdk')
    m.spots('G:lava', 6, 0.9, test=lambda x, y, z: z > 3)
    for s in (-1, 1):
        orn_sweep(B(m, 'slug', True), [(s * 1.2, -4.8, 7.4), (s * 1.6, -5.4, 9.2), (s * 1.8, -5.6, 10.4)], [0.45, 0.35, 0.3], sides=8)
        c = Vector((s * 1.8, -5.8, 10.8))
        orn_ball(B(m, 'eye', True), c, 0.85)
        orn_ball(B(m, 'shine', True), c + Vector((s * 0.25, -0.6, 0.35)), 0.3)
    cheeks(m, 2.2, 4.0, 0.6)
    return m


def c3_2():  # Lava Crab (Uncommon) : crabe rouge, carapace en volcan
    m = Vox(12, seed=32)
    m.ell((0, 1, 4), (6, 4.6, 3), 'crab')
    m.paint(lambda x, y, z: z <= 2, 'crablt')
    orn_sweep(B(m, 'crabshell', True), [(0, 1.5, 5.5), (0, 1.5, 8.0), (0, 1.5, 9.6)], [3.6, 2.2, 1.3], sides=14, profile=ribs(7, 0.1))
    orn_ball(B(m, 'G:lava', True), (0, 1.5, 9.6), 1.1, scale=(1, 1, 0.5))
    flame(m, (0, 1.5, 9.8), 2.2, 0.7, back=0.2)
    for s in (-1, 1):
        m.chain([(s * 5.2, -2.4, 4), (s * 7.4, -4.4, 4.6)], [1.0, 1.0], 'crab')
        m.ell((s * 8.0, -6.0, 5.0), (1.9, 2.0, 1.6), 'crab')
        orn_cone(B(m, 'crablt'), (s * 8.4, -7.4, 5.4), (s * 0.2, -1, 0.3), 1.6, 0.7, sides=8)
        for k in range(3):
            y = -0.5 + k * 1.8
            m.chain([(s * 5.4, y, 3.2), (s * 7.6, y + 0.4, 2.4), (s * 8.4, y + 0.6, 0.4)], [0.7, 0.6, 0.5], 'crab')
        orn_sweep(B(m, 'crab', True), [(s * 1.6, -3.2, 5.6), (s * 1.8, -3.6, 7.6)], [0.4, 0.35], sides=8)
        c = Vector((s * 1.8, -3.8, 8.0))
        orn_ball(B(m, 'eye', True), c, 0.85)
        orn_ball(B(m, 'shine', True), c + Vector((s * 0.25, -0.6, 0.35)), 0.3)
    return m


def c3_3():  # Blaze Newt (Rare) : salamandre orange, collerettes de flammes
    m = Vox(12, seed=33)
    m.ell((0, 2.2, 3.2), (3.0, 6.4, 2.6), 'newt')
    m.ell((0, -5, 4.6), (3.4, 3.0, 2.6), 'newt')
    m.paint(lambda x, y, z: z <= 1.5, 'newtlt')
    m.spots('newtdk', 6, 0.9, test=lambda x, y, z: z > 3)
    for s in (-1, 1):
        for y in (-1.5, 5.5):
            m.chain([(s * 2.6, y, 2.6), (s * 4.4, y - 0.5, 1.2), (s * 4.8, y - 1.0, 0.4)], [0.9, 0.8, 0.8], 'newtdk')
        for k in range(3):
            flame(m, (s * 2.6, -5.6 + k * 0.9, 5.4), 2.2 - k * 0.4, 0.6, back=0.6)
    for y in (-1.0, 1.5, 4.0, 6.5):
        flame(m, (0, y, 5.4), 2.0, 0.55, back=0.5)
    with layer(m, 'Tail'):
        m.chain([(0, 8.4, 2.8), (0, 11.4, 2.2), (0, 14, 1.6), (0, 15.6, 1.4)], [1.6, 1.2, 0.8, 0.5], 'newt')
        flame(m, (0, 15.6, 1.8), 1.6, 0.5, back=0.7)
    eyes(m, 1.8, 5.4, r=0.95)
    cheeks(m, 2.6, 4.0, 0.55)
    return m


def c3_4():  # Obsidian Rhino (Epic) : jeune rhino d'obsidienne, corne en feu, fissures de lave
    m = Vox(18, seed=34)
    m.ell((0, 3, 7.4), (6, 8.4, 5.8), 'obs')
    m.ell((0, -6.2, 8.4), (4.6, 4.4, 4.2), 'obs')
    m.ell((0, -9.4, 7.2), (3.0, 2.2, 2.4), 'obslt')
    legs4(m, 3.6, (-2.0, 8.0), 2.2, 4.6, 'obs', foot='obslt')
    m.paint(lambda x, y, z: z > 3 and abs(math.sin(x * 0.8 + y * 0.5 + z * 0.3)) < 0.12, 'G:lava')
    fierce_eyes(m, 2.6, 10.2, 1.2, 'lava')
    nose(m, 0, 7.2, 0.7)
    orn_cone(B(m, 'obslt'), (0, -10.0, 9.0), (0, -0.4, 1), 5.0, 1.4, sides=8)
    orn_cone(B(m, 'G:lava'), (0, -11.2, 12.0), (0, -0.3, 1), 2.0, 0.6, sides=8)
    flame(m, (0, -11.6, 13.6), 2.4, 0.7, back=0.3)
    orn_cone(B(m, 'obslt'), (0, -7.6, 12.0), (0, -0.2, 1), 2.2, 0.8, sides=8)
    for s in (-1, 1):
        orn_cone(B(m, 'obslt'), (s * 3.6, -5.4, 11.6), (s * 0.4, 0.2, 1), 1.6, 0.6, sides=6)
    crystals_on(m, (0, 4, 8), (6, 8.4, 5.8), ['obslt', 'obs'], n=40, zmin=0.45, ymin=-0.3, L=(2.0, 3.2), R=(0.6, 0.9), glow='G:lava', every=5)
    with layer(m, 'Tail'):
        m.chain([(0, 11.4, 8), (0, 13, 6.6)], [0.8, 0.5], 'obs')
    return m


def c3_5():  # Solar Phoenix (Legendary) : phénix d'or, ailes en éruptions solaires
    m = Vox(24, seed=35)
    m.ell((0, 1, 8.4), (4.6, 5, 5.8), 'phx')
    m.ell((0, -2.4, 14.6), (3.9, 3.7, 3.6), 'phx')
    m.paint(lambda x, y, z: y < -1.5 and z < 12 and abs(x) < 3.4 and (x + z) % 3 == 0, 'phxo')
    for s in (-1, 1):
        m.chain([(s * 1.8, 0.5, 3.0), (s * 1.8, 0, 0.8)], [0.6, 0.6], 'golddk')
        for k in range(3):
            orn_cone(B(m, 'golddk'), (s * (1.2 + k * 0.6), -1.0, 0.5), (0, -1, -0.3), 1.0, 0.25, sides=6)
    fierce_eyes(m, 1.6, 15.2, 1.1, 'flamey', inset=0.2)
    orn_cone(B(m, 'phxo'), (0, front_y(m, 0, 14) + 0.4, 14.0), (0, -1, -0.4), 2.2, 0.8, sides=8)
    for k in range(5):
        flame(m, (0, -2.0 + k * 0.6, 17.6 - k * 0.3), 3.4 - k * 0.3, 0.8, back=0.8)
    with layer(m, 'Orbit'):
        orn_torus(B(m, 'G:flamey', True), (0, 1.8, 16.0), 6.4, 0.3, axis=(0, 1, 0.15), sides=8, seg=48)
        for k in range(10):
            a = k / 10 * math.tau
            p = Vector((math.cos(a) * 7.0, 2.0, 16.0 + math.sin(a) * 7.0))
            orn_cone(B(m, 'G:flame'), p, (math.cos(a), 0.05, math.sin(a)), 1.6, 0.4, sides=6)
    feather_wings(m, 4.2, 1.5, 11.6, 12.0, 'phxr', 'phxo', 'G:flamey', 'gold')
    with layer(m, 'Tail'):
        for k in range(5):
            a = (k - 2) * 0.28
            b = Vector((0, 5.0, 6.0))
            orn_feather(B(m, 'G:flame' if k % 2 else 'phxr', True), b, b + Vector((math.sin(a) * 4, 9.0, -2.0 + math.cos(a) * 2)), 1.0, up=(0, 0, 1))
    return m


def c3_6():  # Magma Wyrm (Mythic) : dragon enroulé de lave refroidie, fissures lumineuses
    m = Vox(32, seed=36)
    pts = coil(m, 'wyrm', (0, 2, 0), 7.0, 1.6, 2.8, 10.0, 3.4, 2.6)
    m.chain([pts[-1], Vector((0, -2, 15)), Vector((0, -4, 20))], [2.6, 2.6, 2.6], 'wyrm')
    m.ell((0, -5.6, 23), (4.2, 4.8, 3.8), 'wyrm')
    m.ell((0, -10.0, 22.0), (2.6, 3.4, 1.9), 'wyrmdk')
    m.ell((0, -9.4, 20.2), (2.4, 3.0, 1.0), 'wyrmdk')
    m.paint(lambda x, y, z: abs(math.sin(x * 0.9 + y * 0.7 + z * 0.4)) < 0.14, 'G:lava')
    fierce_eyes(m, 2.4, 24.2, 1.2, 'lavay', inset=0.2)
    fangs(m, 1.4, 21.0, L=1.4, r=0.38)
    horns2(m, 2.6, -5.0, 26.0, 'obslt', size=1.2)
    spine(m, [p + Vector((0, 0, 2.8)) for p in pts[::4]], 'obslt', 2.4, 0.8, lean=0.0)
    flame(m, (0, -12.4, 21.6), 3.6, 1.0, back=-0.6)
    membrane_wings(m, 3.4, -1.0, 17.0, 12.0, 'wyrmmem', 'wyrmdk', vein='G:lava')
    with layer(m, 'Orbit'):
        for k in range(4):
            a = k / 4 * math.tau + 0.4
            p = Vector((math.cos(a) * 12, 2 + math.sin(a) * 12, 14 + (k % 2) * 4))
            fireball(m, p, (math.sin(a), -math.cos(a), 0), s=1.2)
    return m


# ANNEAU 4 : NÉBULEUSE --------------------------------------------------------------------------

def c4_1():  # Nebula Jelly (Common) : méduse rose et violette pleine d'étoiles (flotte)
    m = Vox(14, seed=41)
    m.ell((0, 0, 9.5), (4.6, 4.6, 3.8), 'jelly', cut=lambda x, y, z: z < 8)
    m.paint(lambda x, y, z: z <= 8, 'jellylt')
    glow_specks(m, 'G:star', 8, test=lambda x, y, z: z > 9)
    eyes(m, 1.8, 10.0, r=1.0)
    cheeks(m, 2.8, 9.0, 0.6)
    with layer(m, 'Tail'):
        for k in range(6):
            a = k / 6 * math.tau
            r = 2.8
            base = Vector((math.cos(a) * r, math.sin(a) * r, 7.6))
            orn_sweep(B(m, 'jellyt', True), [base, base + Vector((0.6, 0, -2)), base + Vector((-0.4, 0.3, -4)), base + Vector((0.3, 0, -5.6))], [0.45, 0.4, 0.3, 0.1], sides=8)
    shadow(m, 3.6)
    return m


def c4_2():  # Haze Kitten (Uncommon) : chaton lavande brumeux, queue de nuage
    m = Vox(15, seed=42)
    m.ell((0, 2.5, 5), (3.6, 5, 3.6), 'kit')
    m.ell((0, -3.4, 9.6), (4.6, 4, 4), 'kit')
    m.ell((0, -6.8, 8.6), (2.0, 1.2, 1.4), 'kitlt')
    for s in (-1, 1):
        m.ell((s * 2.8, -3.0, 14.0), (1.4, 0.9, 2.2), 'kit')
    m.paint(lambda x, y, z: z > 13 and y <= -3.6 and 1.6 < abs(x) < 3.6, 'earpink')
    m.paint(lambda x, y, z: y < -1 and z < 7 and abs(x) < 2.6, 'kitlt')
    legs4(m, 2.2, (-1.0, 6.0), 1.2, 2.6, 'kit', foot='kitlt')
    eyes(m, 2.0, 10.4, r=1.2)
    cheeks(m, 3.2, 8.8, 0.7)
    nose(m, 0, 9.0, 0.5, key='earpink')
    with layer(m, 'Tail'):
        for k, (y, z, r) in enumerate(((7.6, 6.6, 1.4), (9.0, 8.6, 1.8), (9.6, 11, 2.0), (9.0, 13.2, 1.6))):
            orn_ball(B(m, 'cloud', True), (0.4 * (k % 2), y, z), r)
    return m


def c4_3():  # Dreamfin (Rare) : petite baleine bleu ciel qui nage dans la nébuleuse (flotte)
    m = Vox(16, seed=43)
    m.ell((0, 1, 8.4), (5, 9, 4.8), 'whale')
    m.paint(lambda x, y, z: z < 7.6 and abs(x) < 4.2, 'whalelt')
    m.paint(lambda x, y, z: z < 7.6 and abs(x) < 4.2 and z % 2 == 0, 'whaledk')
    eyes(m, 2.6, 9.4, r=1.1)
    cheeks(m, 3.6, 8.0, 0.7)
    for s in (-1, 1):
        orn_ball(B(m, 'whaledk', True), (s * 5.4, -1.0, 6.4), 2.2, scale=(1.2, 0.8, 0.25))
    with layer(m, 'Tail'):
        m.chain([(0, 9.6, 8.6), (0, 12.0, 9.4)], [2.4, 1.6], 'whale')
        for s in (-1, 1):
            orn_ball(B(m, 'whaledk', True), (s * 2.6, 13.6, 10.0), 2.4, scale=(1.2, 0.7, 0.25))
    orn_sweep(B(m, 'G:nebc', True), [(0, -1, 13.0), (0, -1.4, 15.0), (0, -0.6, 16.6)], [0.5, 0.35, 0.1], sides=8)
    for k in range(7):
        a = k / 7 * math.tau
        orn_ball(B(m, 'nebc' if k % 2 else 'nebv', True), (math.cos(a) * 6, 1 + math.sin(a) * 8, 3.4), 1.6, scale=(1.2, 1.2, 0.6))
    shadow(m, 4.0)
    return m


def c4_4():  # Prism Ray (Epic) : raie manta sombre aux ailes de prisme arc-en-ciel (flotte)
    m = Vox(16, seed=44)
    m.ell((0, 1, 9.0), (10, 6.6, 1.9), 'ray')
    m.ell((0, -2.4, 10.0), (3.6, 3.6, 2.2), 'ray')
    keys = ['prR', 'prY', 'prG', 'prB', 'prV']
    m.paint(lambda x, y, z: abs(x) > 5, 'raylt')
    m.paint(lambda x, y, z: abs(x) > 6.5 and z >= 9, keys[0])
    for i, k in enumerate(keys):
        m.paint(lambda x, y, z, i=i: abs(x) > 6.5 and z >= 9 and int(abs(x) + y) % 5 == i, k)
    fierce_eyes(m, 2.0, 10.4, 1.0, 'prismc', inset=0.2)
    for s in (-1, 1):
        orn_cone(B(m, 'ray'), (s * 2.6, -4.6, 9.6), (s * 0.15, -1, 0.1), 2.6, 0.8, sides=8)
    for k, x in enumerate((-4, -2, 0, 2, 4)):
        orn_crystal(B(m, 'G:prismc' if k == 2 else ('G:' + keys[k])), (x, 1.0 + abs(x) * 0.2, 10.4), (x * 0.05, 0.3, 1), 3.0 - abs(x) * 0.3, 0.6)
    with layer(m, 'Tail'):
        m.chain([(0, 7.2, 9), (0, 11, 8.6), (0, 14.4, 8.4)], [0.9, 0.6, 0.4], 'ray')
        orn_crystal(B(m, 'G:prismc'), (0, 14.6, 8.4), (0, 1, 0.2), 2.4, 0.6, double=True)
    shadow(m, 6.0)
    return m


def c4_5():  # Nova Lion (Legendary) : lionceau à crinière de lumière d'étoile
    m = Vox(24, seed=45)
    m.ell((0, 3, 8.0), (4.8, 8, 4.8), 'lion')
    m.ell((0, -6.4, 13.2), (4.4, 4.2, 4.0), 'lion')
    m.ell((0, -10.0, 12.0), (2.4, 2.0, 1.8), 'lionlt')
    legs4(m, 3.0, (-2.0, 8.0), 1.8, 4.6, 'lion', foot='lionlt')
    m.paint(lambda x, y, z: y < -1 and z < 10 and abs(x) < 3.2, 'lionlt')
    fierce_eyes(m, 2.0, 14.2, 1.15, 'nova', inset=0.2)
    nose(m, 0, 12.6, 0.8)
    fangs(m, 1.0, 10.8, L=1.2, r=0.32)
    for s in (-1, 1):
        m.ell((s * 3.2, -5.6, 16.8), (1.0, 0.8, 1.0), 'liondk')
    for i, d in enumerate(fib_dirs(46)):
        if d.y > 0.55:
            continue
        base = Vector((0, -5.0, 13.4)) + Vector((d.x * 4.4, d.y * 3.0, d.z * 4.2))
        k = ('G:nova', 'G:novao', 'G:novaw')[i % 3]
        orn_cone(B(m, k), base, (d + Vector((0, 0.8, 0))).normalized(), 3.0 + (i % 4) * 0.5, 0.75, sides=6)
    orn_gem(B(m, 'gold'), (0, -5.0, 8.6), 1.1, direction=(0, -1, 0))
    with layer(m, 'Tail'):
        m.chain([(0, 10.6, 9), (0, 13.6, 11), (0, 15, 14)], [1.0, 0.8, 0.7], 'lion')
        orn_star(B(m, 'G:nova'), (0, 15.4, 15.6), 1.8, 0.8, 0.6, normal=(0, 1, 0))
    orbit_stars(m, (0, -5, 13), 8.0, 5, 'G:nova', size=1.1)
    return m


def c4_6():  # Galaxy Unicorn (Mythic) : licorne ailée, crinière et corne de galaxie
    m = Vox(32, seed=46)
    m.ell((0, 3, 11), (4.8, 8.6, 5.2), 'uni')
    m.chain([(0, -4, 14), (0, -6.6, 19), (0, -7.6, 22)], [3.2, 2.6, 2.4], 'uni')
    m.ell((0, -9.6, 23.4), (3.4, 4.6, 3.2), 'uni')
    m.ell((0, -13.6, 22.0), (2.4, 2.2, 2.0), 'unidk')
    legs4(m, 3.0, (-2.6, 8.6), 1.5, 7.4, 'uni')
    for s in (-1, 1):
        for y in (-2.6, 8.6):
            m.ell((s * 3.0, y - 0.3, 0.6), (1.7, 1.9, 0.9), 'gold')
        m.ell((s * 2.2, -9.0, 27.0), (0.9, 0.7, 1.4), 'uni')
    fierce_eyes(m, 2.1, 24.4, 1.05, 'galp', inset=0.2)
    orn_cone(B(m, 'G:galh'), (0, -11.0, 26.6), (0, -0.55, 1), 7.0, 0.9, sides=12)
    orn_sweep(B(m, 'gold', True), [(0, -11.2, 27.0), (0.4, -12.2, 28.6), (-0.4, -13.2, 30.2), (0.2, -14.0, 31.6)], [0.35, 0.3, 0.25, 0.1], sides=6)
    cols = ('G:galp', 'G:galc', 'G:galv', 'G:galh')
    for k in range(8):
        t = k / 7
        b = Vector((0, -9.0 + t * 7.0, 26.0 - t * 9.0))
        orn_sweep(B(m, cols[k % 4], True), [b, b + Vector((((k % 2) * 2 - 1) * 1.4, 2.2, 0.6)), b + Vector((((k % 2) * 2 - 1) * 1.0, 4.0, -1.4))], [1.0, 0.7, 0.05], sides=8)
    m.paint(lambda x, y, z: z > 9 and abs(math.sin(x * 0.6 + y * 0.5 + z * 0.2)) < 0.09, 'G:galc')
    feather_wings(m, 4.4, 1.0, 15.0, 14.0, 'galv', 'galc', 'G:galp', 'gold')
    with layer(m, 'Tail'):
        for k in range(4):
            b = Vector((0, 11.6, 13.0))
            orn_sweep(B(m, cols[k], True), [b, b + Vector(((k - 1.5) * 1.0, 3.0, -2.0)), b + Vector(((k - 1.5) * 1.4, 5.0, -6.0))], [1.2, 0.8, 0.05], sides=8)
    with layer(m, 'Orbit'):
        for k in range(3):
            a = k / 3 * math.tau + 0.3
            planet(m, Vector((math.cos(a) * 13, 2 + math.sin(a) * 13, 18 + k * 2)), 1.3, ('galp', 'galc', 'galv')[k], 'gold')
    return m


# ANNEAU 5 : DÉVOREUR ---------------------------------------------------------------------------

def c5_2():  # Fang Beetle (Uncommon) : scarabée vert foncé aux gros crocs gentils
    m = Vox(10, seed=52)
    m.ell((0, 2, 4.2), (5, 6, 3.6), 'beetle')
    m.paint(lambda x, y, z: abs(x) < 0.6 and z > 5, 'beetledk')
    m.paint(lambda x, y, z: z > 6 and (abs(x) + y) % 4 == 0, 'beetlelt')
    m.ell((0, -4.6, 4.0), (3.0, 2.6, 2.6), 'beetledk')
    for s in (-1, 1):
        orn_sweep(B(m, 'white', True), [(s * 1.4, -6.6, 3.4), (s * 1.6, -8.6, 3.6), (s * 0.6, -9.8, 4.4)], [0.55, 0.4, 0.1], sides=8)
        for k in range(3):
            y = -1.6 + k * 2.6
            m.chain([(s * 4.4, y, 2.6), (s * 6.2, y, 1.6), (s * 6.8, y + 0.4, 0.4)], [0.5, 0.45, 0.4], 'beetledk')
        orn_sweep(B(m, 'beetledk', True), [(s * 1.0, -6.0, 5.6), (s * 1.8, -7.4, 7.6), (s * 2.6, -7.6, 8.6)], [0.2, 0.15, 0.1], sides=6)
    eyes(m, 1.3, 4.8, r=0.9)
    return m


def c5_3():  # Gloom Bat (Rare) : chauve-souris ronde violette aux yeux jaunes (flotte)
    m = Vox(15, seed=53)
    m.ell((0, 0, 8), (4, 3.6, 4), 'bat')
    m.paint(lambda x, y, z: y < -1.5 and z < 8 and abs(x) < 2.6, 'batlt')
    for s in (-1, 1):
        m.ell((s * 2.6, 0, 12.6), (1.3, 0.8, 2.4), 'bat')
        m.ell((s * 1.4, 0.4, 3.6), (0.7, 0.7, 0.9), 'batlt')
    for s in (-1, 1):
        y = front_y(m, s * 1.6, 9) + 0.15
        c = Vector((s * 1.6, y, 9.0))
        orn_ball(B(m, 'eye', True), c, 1.1, scale=(1, 0.6, 1))
        orn_ball(B(m, 'G:baty', True), c + Vector((0, -0.45, 0)), 0.7, scale=(1, 0.5, 1))
        orn_ball(B(m, 'shine', True), c + Vector((s * 0.3, -0.75, 0.35)), 0.22)
    fangs(m, 0.6, 7.0, L=0.8, r=0.25)
    membrane_wings(m, 3.4, 0.5, 8.6, 8.0, 'batmem', 'bat')
    shadow(m, 3.0)
    return m


def c5_4():  # Void Shark (Epic) : petit requin noir au ventre étoilé (flotte)
    m = Vox(16, seed=54)
    m.ell((0, 1, 8.4), (4.2, 9.4, 4.2), 'shark')
    m.paint(lambda x, y, z: z < 7.4, 'sharkb')
    glow_specks(m, 'G:star', 14, test=lambda x, y, z: z < 7.4)
    fierce_eyes(m, 2.4, 9.6, 1.0, 'voidc', inset=0.2)
    m.paint(lambda x, y, z: z == 7 and y < -6.6 and abs(x) < 3, 'mouth')
    for k in range(6):
        x = -2.2 + k * 0.88
        orn_cone(B(m, 'white'), (x, front_y(m, x, 7.6) + 0.5, 7.6), (0, -0.2, -1), 0.9, 0.28, sides=6)
    orn_cone(B(m, 'shark'), (0, 0.5, 12.0), (0, 0.6, 1), 4.6, 1.5, sides=8)
    for s in (-1, 1):
        orn_cone(B(m, 'shark'), (s * 3.6, -1.6, 7.0), (s * 1, 0.5, -0.4), 3.6, 1.0, sides=8)
    with layer(m, 'Tail'):
        m.chain([(0, 10.0, 8.6), (0, 13, 9.4)], [2.2, 1.4], 'shark')
        orn_cone(B(m, 'shark'), (0, 14.0, 9.6), (0, 0.5, 1), 4.0, 1.2, sides=8)
        orn_cone(B(m, 'shark'), (0, 14.0, 9.4), (0, 0.5, -0.8), 2.8, 1.0, sides=8)
    with layer(m, 'Orbit'):
        for k in range(4):
            a = k / 4 * math.tau
            orn_star(B(m, 'G:voidc'), (math.cos(a) * 8, 1 + math.sin(a) * 11, 9 + (k % 2) * 2), 0.9, 0.4, 0.3)
    shadow(m, 4.2)
    return m


def c5_5():  # Hunger Hound (Legendary) : molosse d'ombre au collier turquoise lumineux
    m = Vox(24, seed=55)
    m.ell((0, 3, 8.4), (4.4, 8.6, 4.6), 'hound')
    m.chain([(0, -3.4, 11), (0, -6, 13)], [3.4, 3.0], 'hound')
    m.ell((0, -7.6, 14.4), (4.0, 4.2, 3.6), 'hound')
    m.ell((0, -12.0, 13.4), (2.0, 3.2, 1.6), 'houndlt')
    m.ell((0, -11.2, 12.0), (1.8, 2.6, 0.8), 'houndlt')
    legs4(m, 3.0, (-2.0, 8.4), 1.5, 5.0, 'hound', foot='houndlt')
    for s in (-1, 1):
        m.ell((s * 2.6, -6.8, 19.2), (1.2, 0.8, 2.8), 'hound')
    fierce_eyes(m, 2.0, 15.4, 1.1, 'teal', inset=0.2)
    fangs(m, 1.2, 12.2, L=1.5, r=0.38)
    orn_torus(B(m, 'G:teal', True), (0, -4.8, 12.4), 3.8, 0.6, axis=(0, -0.6, 1), sides=10, seg=40)
    for k in range(8):
        a = k / 8 * math.tau
        rot = _orient((0, -0.6, 1))
        p = Vector((0, -4.8, 12.4)) + rot @ Vector((math.cos(a) * 4.3, math.sin(a) * 4.3, 0))
        orn_cone(B(m, 'houndlt'), p, (p - Vector((0, -4.8, 12.4))).normalized(), 1.4, 0.4, sides=6)
    spine(m, [Vector((0, y, 12.6 - abs(y - 2) * 0.2)) for y in (-1, 2, 5, 8)], 'houndlt', 2.4, 0.6)
    for k in range(6):
        a = k / 6 * math.tau
        orn_ball(B(m, 'smoke', True), (math.cos(a) * 4.4, 3 + math.sin(a) * 8, 1.0), 1.6, scale=(1.3, 1.3, 0.5))
    with layer(m, 'Tail'):
        m.chain([(0, 11.4, 10), (0, 14, 12.6), (0, 15, 15.4)], [1.2, 0.9, 0.5], 'hound')
        flame(m, (0, 15, 15.6), 2.4, 0.7, k1='G:teal', k2='G:voidc', back=0.4)
    return m


def c5_6():  # Abyss Serpent (Mythic) : serpent violet enroulé, capuchon, runes lumineuses
    m = Vox(30, seed=56)
    pts = coil(m, 'serp', (0, 2, 0), 7.6, 1.9, 2.4, 11.0, 3.2, 2.4)
    m.chain([pts[-1], Vector((0, -1.0, 16)), Vector((0, -3.0, 21))], [2.4, 2.4, 2.4], 'serp')
    m.ell((0, -4.4, 24.0), (3.6, 4.4, 3.0), 'serp')
    m.ell((0, -1.6, 21.0), (6.4, 1.2, 5.2), 'serplt')
    m.paint(lambda x, y, z: abs(math.sin(x * 1.1 + z * 0.9)) < 0.1 and z > 3, 'G:rune')
    m.paint(lambda x, y, z: y > -1.4 and abs(x) > 2 and 17 < z < 25 and (int(x) + z) % 3 == 0, 'G:rune')
    fierce_eyes(m, 1.8, 25.0, 1.0, 'rune', inset=0.2)
    fangs(m, 1.0, 22.6, L=2.0, r=0.42)
    horns2(m, 2.0, -3.4, 26.6, 'serplt', size=0.9)
    spine(m, [p + Vector((0, 0, 2.6)) for p in pts[::5]], 'serplt', 2.0, 0.7, lean=0.0)
    with layer(m, 'Orbit'):
        for k in range(5):
            a = k / 5 * math.tau
            p = Vector((math.cos(a) * 12, 2 + math.sin(a) * 12, 14 + (k % 2) * 3))
            orn_torus(B(m, 'G:rune', True), p, 1.2, 0.2, axis=(math.cos(a), math.sin(a), 0), sides=6, seg=24)
            orn_star(B(m, 'G:rune'), p, 0.7, 0.3, 0.2, normal=(math.cos(a), math.sin(a), 0))
    return m


def c5_7():  # Eclipse Devourer (Cosmic) : bête majestueuse, halo d'éclipse, gueule cosmique
    m = Vox(36, seed=57)
    m.ell((0, 3, 10.4), (6.6, 9.4, 6.4), 'eclip')
    m.chain([(0, -4.6, 14), (0, -7.6, 18.6)], [4.4, 3.8], 'eclip')
    m.ell((0, -9.4, 21.4), (5.0, 5.0, 4.4), 'eclip')
    m.ell((0, -13.4, 19.6), (3.4, 2.4, 2.8), 'G:cosmo')
    legs4(m, 4.2, (-2.4, 9.4), 2.4, 6.4, 'eclip', foot='eclipm')
    m.paint(lambda x, y, z: abs(math.sin(x * 0.7 + y * 0.4 + z * 0.3)) < 0.1 and z > 4, 'G:cosmo')
    glow_specks(m, 'G:star', 18, test=lambda x, y, z: z > 6)
    fierce_eyes(m, 2.6, 23.2, 1.35, 'eclipg', inset=0.2)
    for k in range(10):
        a = k / 10 * math.tau
        p = Vector((math.cos(a) * 3.0, -14.6, 19.6 + math.sin(a) * 2.4))
        orn_cone(B(m, 'white'), p, (-math.cos(a), -0.2, -math.sin(a)), 1.4, 0.4, sides=6)
    horns2(m, 3.2, -8.4, 25.2, 'eclipg', size=1.5, spread=1.4)
    spine(m, [Vector((0, y, 16.6 - abs(y - 3) * 0.25)) for y in (-3, 0, 3, 6, 9)], 'eclipm', 3.2, 0.9)
    membrane_wings(m, 5.0, 2.0, 16.0, 16.0, 'eclipm', 'eclip', vein='G:cosmo')
    orn_torus(B(m, 'G:eclipg', True), (0, -4.0, 26.0), 7.0, 0.8, axis=(0, 1, 0.2), sides=12, seg=64)
    orn_ball(B(m, 'eclipdk', True), (0, -3.6, 26.0), 6.2, scale=(1, 0.08, 1))
    with layer(m, 'Tail'):
        m.chain([(0, 12.4, 10), (0, 16.6, 8.6), (0, 20.4, 10.4)], [3.0, 2.0, 1.2], 'eclip')
        orn_gem(B(m, 'cosmo'), (0, 21.8, 11.8), 1.8, direction=(0, 0.6, 1))
    with layer(m, 'Orbit'):
        for k in range(6):
            a = k / 6 * math.tau
            p = Vector((math.cos(a) * 15, 3 + math.sin(a) * 15, 20 + (k % 2) * 4))
            if k % 2:
                planet(m, p, 1.4, 'cosmo', 'eclipg')
            else:
                fireball(m, p, (math.sin(a), -math.cos(a), 0), core='G:eclipg', tail='G:cosmo', s=1.3)
    return m


# ANNEAU 6 : FAILLE -------------------------------------------------------------------------------

def c6_2():  # Chrono Snail (Uncommon) : escargot à coquille-horloge
    m = Vox(13, seed=62)
    m.ell((0, -1, 2.0), (2.6, 6.4, 2.0), 'snail')
    m.ell((0, -6.0, 4.6), (2.4, 2.4, 2.8), 'snail')
    m.paint(lambda x, y, z: z <= 0, 'snaillt')
    m.ell((0, 2, 7.6), (2.6, 4.8, 4.8), 'shellc')
    for s in (-1, 1):
        c = Vector((s * 2.7, 2.0, 7.6))
        orn_ball(B(m, 'clockw', True), c, 3.4, scale=(0.08, 1, 1))
        for k in range(12):
            a = k / 12 * math.tau
            orn_ball(B(m, 'clockd', True), c + Vector((s * 0.25, math.cos(a) * 2.8, math.sin(a) * 2.8)), 0.22)
        orn_sweep(B(m, 'clockd', True), [c + Vector((s * 0.3, 0, 0)), c + Vector((s * 0.3, -1.6, 1.0))], [0.2, 0.12], sides=6)
        orn_sweep(B(m, 'G:time', True), [c + Vector((s * 0.35, 0, 0)), c + Vector((s * 0.35, 0.4, 2.4))], [0.16, 0.1], sides=6)
        orn_sweep(B(m, 'snail', True), [(s * 0.9, -6.4, 7.0), (s * 1.3, -6.8, 8.8)], [0.35, 0.3], sides=8)
        e = Vector((s * 1.4, -7.0, 9.4))
        orn_ball(B(m, 'eye', True), e, 0.8)
        orn_ball(B(m, 'shine', True), e + Vector((s * 0.25, -0.55, 0.3)), 0.28)
    cheeks(m, 1.8, 4.0, 0.5)
    return m


def c6_3():  # Glitch Cat (Rare) : chat aux rayures glitch cyan et magenta
    m = Vox(15, seed=63)
    m.ell((0, 2.5, 5), (3.6, 5.2, 3.6), 'cat')
    m.ell((0, -3.4, 9.6), (4.4, 4, 4), 'cat')
    m.ell((0, -6.8, 8.6), (2.0, 1.2, 1.4), 'catlt')
    for s in (-1, 1):
        m.ell((s * 2.6, -3.0, 14.0), (1.4, 0.9, 2.4), 'cat')
    legs4(m, 2.2, (-1.0, 6.2), 1.2, 2.6, 'cat', foot='catlt')
    m.paint(lambda x, y, z: z % 3 == 0 and z > 2, 'G:glc')
    m.paint(lambda x, y, z: z % 3 == 1 and z > 2 and (x + y) % 4 == 0, 'G:glm')
    eyes(m, 2.0, 10.4, r=1.2)
    cheeks(m, 3.2, 8.8, 0.7)
    nose(m, 0, 9.0, 0.5, key='glm')
    with layer(m, 'Tail'):
        m.chain([(0, 7.6, 5), (0, 9.4, 8), (0, 9.0, 11)], [0.9, 0.8, 0.7], 'cat')
    with layer(m, 'Orbit'):
        for k in range(6):
            a = k / 6 * math.tau
            p = (math.cos(a) * 6.5, 2 + math.sin(a) * 6.5, 10 + (k % 3))
            orn_crystal(B(m, 'G:glc' if k % 2 else 'G:glm'), p, (0.1, 0.1, 1), 1.2, 0.6, sides=4, tip=0.5, double=True)
    return m


def c6_4():  # Paradox Panda (Epic) : panda aux taches inversées, tourbillon du temps
    m = Vox(20, seed=64)
    m.ell((0, 1.5, 7), (6, 5.4, 6.4), 'pandab')
    m.ell((0, -0.5, 15.4), (5.2, 4.6, 4.6), 'pandab')
    for s in (-1, 1):
        m.ell((s * 3.8, -1.6, 2.0), (2.4, 2.8, 2.0), 'pandaw')
        m.chain([(s * 5.6, -0.5, 11), (s * 6.0, -3.0, 7.6)], [1.8, 1.6], 'pandaw')
        m.ell((s * 3.6, -0.4, 19.4), (1.4, 1.0, 1.4), 'pandaw')
        m.ell((s * 2.0, -4.0, 16.2), (1.5, 1.0, 1.6), 'pandaw')
    m.paint(lambda x, y, z: y < -2 and 4 < z < 11 and abs(x) < 3.6, 'pandaw')
    fierce_eyes(m, 2.0, 16.2, 1.1, 'time', inset=0.25)
    nose(m, 0, 14.4, 0.7)
    with layer(m, 'Orbit'):
        ctr = Vector((0, 0, 12))
        for i in range(3):
            orn_torus(B(m, 'G:time', True), ctr, 9.0 - i, 0.25, tilt=0.3 + i * 0.25, arc=(i / 3, i / 3 + 0.55), seg=60, sides=6)
        for k in range(4):
            a = k / 4 * math.tau
            c = ctr + Vector((math.cos(a) * 9, math.sin(a) * 9, 0))
            orn_ball(B(m, 'clockw', True), c, 1.3, scale=(1, 1, 0.3))
            orn_sweep(B(m, 'clockd', True), [c + Vector((0, 0, 0.45)), c + Vector((0.8, 0, 0.45))], [0.12, 0.08], sides=6)
    return m


def c6_5():  # Hourglass Tortoise (Legendary) : tortue portant un sablier doré
    m = Vox(22, seed=65)
    m.ell((0, 1, 4.6), (6.4, 7.4, 3.6), 'tort')
    m.ell((0, -8.2, 6.4), (3.4, 3.4, 3.0), 'tort')
    legs4(m, 4.6, (-4.0, 5.0), 2.0, 3.6, 'tortdk')
    m.paint(lambda x, y, z: (int(x * 0.6) + int(y * 0.5)) % 2 == 0 and z > 5, 'tortdk')
    fierce_eyes(m, 1.6, 7.2, 1.0, 'sand', inset=0.2)
    c = Vector((0, 1, 8.4))
    for z in (0.0, 9.0):
        orn_torus(B(m, 'gold', True), c + Vector((0, 0, z)), 4.2, 0.55, sides=10, seg=40)
    for k in range(4):
        a = k / 4 * math.tau + math.pi / 4
        p = c + Vector((math.cos(a) * 4.2, math.sin(a) * 4.2, 0))
        orn_sweep(B(m, 'gold', True), [p, p + Vector((0, 0, 9))], [0.45, 0.45], sides=8)
    orn_ball(B(m, 'glass', True), c + Vector((0, 0, 2.4)), 3.0, scale=(1, 1, 0.85))
    orn_ball(B(m, 'glass', True), c + Vector((0, 0, 6.6)), 3.0, scale=(1, 1, 0.85))
    orn_ball(B(m, 'G:sand', True), c + Vector((0, 0, 1.6)), 2.2, scale=(1, 1, 0.6))
    orn_cone(B(m, 'G:sand'), c + Vector((0, 0, 7.6)), (0, 0, -1), 3.0, 1.6, sides=10)
    orn_gem(B(m, 'time'), c + Vector((0, 0, 10.2)), 1.2, direction=(0, 0, 1))
    with layer(m, 'Tail'):
        m.chain([(0, 8.6, 3.6), (0, 10.4, 2.6)], [1.0, 0.5], 'tortdk')
    orbit_stars(m, (0, 1, 13), 9.0, 4, 'G:sand')
    return m


def c6_6():  # Rift Griffin (Mythic) : griffon aux ailes déchirées de failles lumineuses
    m = Vox(32, seed=66)
    m.ell((0, 3, 10), (5.2, 9, 5.4), 'grif')
    m.chain([(0, -4, 13), (0, -6.6, 18)], [3.6, 3.2], 'grifw')
    m.ell((0, -8.0, 21.0), (3.8, 4.0, 3.6), 'grifw')
    legs4(m, 3.2, (-2.6, 8.6), 1.8, 6.4, 'grif')
    for s in (-1, 1):
        for k in range(3):
            orn_cone(B(m, 'gold'), (s * (2.6 + k * 0.6), -4.6, 0.6), (0, -1, -0.3), 1.4, 0.32, sides=6)
    m.paint(lambda x, y, z: y < -3 and z > 10, 'grifw')
    fierce_eyes(m, 1.9, 22.0, 1.1, 'riftc', inset=0.2)
    orn_sweep(B(m, 'gold', True), [(0, front_y(m, 0, 21) + 0.6, 21.4), (0, -13.4, 20.6), (0, -13.6, 18.6)], [1.2, 0.8, 0.1], sides=10)
    for s in (-1, 1):
        orn_feather(B(m, 'grifw', True), (s * 2.0, -6.4, 24.0), (s * 3.6, -3.0, 27.0), 0.8)
    feather_wings(m, 4.6, 1.0, 14.0, 15.0, 'griflt', 'G:rift', 'G:riftc', 'grif')
    with layer(m, 'Tail'):
        m.chain([(0, 11.8, 11), (0, 15, 9), (0, 17.6, 11)], [1.2, 0.9, 0.7], 'grif')
        flame(m, (0, 17.8, 11.2), 3.0, 0.9, k1='G:rift', k2='G:riftc', back=0.6)
    with layer(m, 'Orbit'):
        for k in range(5):
            a = k / 5 * math.tau
            p = (math.cos(a) * 14, 3 + math.sin(a) * 14, 18 + (k % 2) * 3)
            orn_crystal(B(m, 'G:rift' if k % 2 else 'G:riftc'), p, (0.15, 0.1, 1), 2.6, 1.0, sides=4, tip=0.5, double=True)
    return m


def c6_7():  # Quasar Kraken (Cosmic) : kraken dont la tête brille comme un quasar
    m = Vox(34, seed=67)
    m.ell((0, 1, 15), (7.4, 7.4, 8.6), 'krak')
    m.paint(lambda x, y, z: z > 18 and (int(x) + int(y) + z) % 4 == 0, 'kraklt')
    m.paint(lambda x, y, z: abs(math.sin(x * 0.7 + z * 0.5)) < 0.1, 'G:quasarc')
    fierce_eyes(m, 3.0, 13.4, 1.6, 'quasarc', inset=0.25)
    orn_ball(B(m, 'G:quasar', True), (0, 1, 24.6), 2.8)
    orn_torus(B(m, 'G:quasarc', True), (0, 1, 24.6), 4.6, 0.3, tilt=0.2, seg=48, sides=8)
    orn_cone(B(m, 'G:quasarc'), (0, 1, 26.4), (0, 0, 1), 9.0, 1.2, sides=12)
    for k in range(8):
        a = k / 8 * math.tau
        o = Vector((math.cos(a), math.sin(a), 0))
        base = Vector((0, 1, 8.0)) + o * 5.0
        pts = [base, base + o * 4 + Vector((0, 0, -5)), base + o * 8 + Vector((0, 0, -6.6)), base + o * 10.4 + Vector((0, 0, -4.6)), base + o * 10.0 + Vector((0, 0, -2.4))]
        if k % 2:
            with layer(m, 'Tail'):
                orn_sweep(B(m, 'krak', True), pts, [2.0, 1.6, 1.1, 0.7, 0.2], sides=12)
        else:
            orn_sweep(B(m, 'krak', True), pts, [2.0, 1.6, 1.1, 0.7, 0.2], sides=12)
        for t in (0.3, 0.55, 0.75):
            i = int(t * 4)
            p = pts[i].lerp(pts[i + 1], t * 4 - i)
            orn_ball(B(m, 'G:quasarc', True), p + Vector((0, 0, -0.8)), 0.4)
    with layer(m, 'Orbit'):
        for i in range(3):
            orn_torus(B(m, 'G:quasarc' if i != 1 else 'G:quasar', True), (0, 1, 16), 13.0 + i * 1.6, 0.24, tilt=0.15 + i * 0.25, seg=72, sides=6)
        for k in range(4):
            a = k / 4 * math.tau
            planet(m, Vector((math.cos(a) * 14, 1 + math.sin(a) * 14, 16)), 1.2, 'kraklt', 'quasarc')
    return m


# ANNEAU 7 : NID ------------------------------------------------------------------------------------

def c7_2():  # Hatchling (Uncommon) : poussin dans la moitié de sa coquille cosmique
    m = Vox(12, seed=72)
    m.ell((0, 0, 7.0), (3.6, 3.4, 3.8), 'chick')
    m.ell((0, 0, 4.4), (4.4, 4.4, 4.6), 'shell7', cut=lambda x, y, z: z > 5 or (x * x + y * y) < 9 and z > 1)
    m.paint(lambda x, y, z: z == 5, 'shell7lt')
    glow_specks(m, 'G:star', 8, test=lambda x, y, z: z < 5)
    eyes(m, 1.4, 8.0, r=0.95)
    cheeks(m, 2.3, 6.8, 0.55)
    orn_cone(B(m, 'beak'), (0, front_y(m, 0, 7) + 0.3, 7.0), (0, -1, -0.1), 1.2, 0.5, sides=8)
    for s in (-1, 1):
        orn_ball(B(m, 'chicklt', True), (s * 3.6, 0.4, 7.0), 1.2, scale=(0.4, 1, 1))
    orn_feather(B(m, 'chicklt', True), (0, 0, 10.4), (0.4, 0.6, 12.4), 0.6)
    return m


def c7_3():  # Yolk Slime (Rare) : slime de jaune d'œuf doré, visage joyeux
    m = Vox(12, seed=73)
    m.ell((0, 0, 4.4), (5.2, 5.2, 4.6), 'yolk', cut=lambda x, y, z: z < 0)
    m.paint(lambda x, y, z: z <= 1, 'yolkdk')
    eyes(m, 2.0, 5.6, r=1.15)
    cheeks(m, 3.2, 4.2, 0.7)
    m.paint(lambda x, y, z: z == 3 and y < -4.2 and abs(x) < 1.6, 'mouth')
    orn_ball(B(m, 'yolklt', True), (-1.8, -2.6, 7.8), 1.0, scale=(1, 1, 0.6))
    orn_ball(B(m, 'shine', True), (-2.2, -3.2, 8.0), 0.5)
    for k in range(5):
        a = k / 5 * math.tau
        orn_ball(B(m, 'yolk', True), (math.cos(a) * 5.4, math.sin(a) * 5.4, 0.6), 1.0, scale=(1, 1, 0.6))
    for (x, L) in ((0, 2.4), (1.4, 1.6), (-1.4, 1.6)):
        orn_crystal(B(m, 'gold'), (x, 0, 8.6), (x * 0.25, 0, 1), L, 0.5, sides=4)
    return m


def c7_4():  # Brood Raptor (Epic) : bébé raptor en armure de coquille ambrée
    m = Vox(18, seed=74)
    for s in (-1, 1):
        m.chain([(s * 2.4, 2.0, 7.0), (s * 2.6, 3.2, 3.6), (s * 2.6, 1.6, 0.8)], [1.8, 1.2, 1.0], 'raptor')
        m.ell((s * 2.6, 0.4, 0.5), (1.4, 2.4, 0.7), 'raptorlt')
        for k in range(3):
            orn_cone(B(m, 'white'), (s * (2.0 + k * 0.6), -1.6, 0.5), (0, -1, -0.3), 1.0, 0.25, sides=6)
    m.ell((0, 1, 8.6), (3.8, 6, 3.6), 'raptor')
    m.chain([(0, -4, 10), (0, -6, 13)], [2.6, 2.3], 'raptor')
    m.ell((0, -8.0, 14.6), (3.0, 4.4, 2.8), 'raptor')
    m.ell((0, -8.4, 12.8), (2.6, 3.8, 1.0), 'raptorlt')
    m.paint(lambda x, y, z: y < -2 and z < 12 and abs(x) < 2.6, 'raptorlt')
    for s in (-1, 1):
        m.chain([(s * 3.0, -3.6, 9.6), (s * 3.4, -5.6, 8.0)], [0.7, 0.6], 'raptor')
        orn_cone(B(m, 'white'), (s * 3.4, -6.2, 7.8), (0, -1, -0.6), 1.2, 0.25, sides=6)
    fierce_eyes(m, 1.8, 15.6, 0.95, 'amber', inset=0.2)
    fangs(m, 1.2, 13.6, L=1.1, r=0.3)
    for k, (y, z) in enumerate(((-2, 12.2), (1, 12.0), (4, 11.4), (7, 10.0))):
        orn_ball(B(m, 'amber' if k % 2 else 'amberdk', True), (0, y, z), 2.6, scale=(1.3, 0.8, 0.45))
        orn_cone(B(m, 'amberdk'), (0, y, z + 0.8), (0, 0.3, 1), 1.6, 0.5, sides=6)
    with layer(m, 'Tail'):
        m.chain([(0, 6.8, 8.6), (0, 11, 8.2), (0, 15, 8.6), (0, 18, 9.4)], [2.2, 1.6, 1.0, 0.5], 'raptor')
    return m


def c7_5():  # Nest Drake (Legendary) : drake qui porte un nid d'œufs lumineux sur le dos
    m = Vox(24, seed=75)
    m.ell((0, 3, 8.4), (5.6, 8.6, 5.4), 'drake')
    m.chain([(0, -4, 11), (0, -6.4, 15)], [3.4, 3.0], 'drake')
    m.ell((0, -8.0, 17.2), (3.8, 4.6, 3.4), 'drake')
    m.ell((0, -12.0, 16.2), (2.4, 3.0, 1.8), 'drakelt')
    legs4(m, 3.6, (-2.4, 8.4), 2.0, 4.8, 'drake', foot='drakelt')
    m.paint(lambda x, y, z: y < -2 and z < 12 and abs(x) < 3.4 and z % 2 == 0, 'drakelt')
    fierce_eyes(m, 2.1, 18.4, 1.1, 'eggg', inset=0.2)
    fangs(m, 1.2, 15.4, L=1.3, r=0.35)
    horns2(m, 2.2, -7.6, 20.4, 'gold', size=1.0)
    c = Vector((0, 3, 13.4))
    for k in range(26):
        a = k / 26 * math.tau
        r = 4.2 + (k % 3) * 0.4
        p0 = c + Vector((math.cos(a) * r, math.sin(a) * r, (k % 4) * 0.4))
        p1 = c + Vector((math.cos(a + 0.6) * (r + 0.4), math.sin(a + 0.6) * (r + 0.4), 0.6 + (k % 2) * 0.4))
        orn_sweep(B(m, 'twig', True), [p0, p0.lerp(p1, 0.5) + Vector((0, 0, 0.3)), p1], [0.28, 0.25, 0.18], sides=6)
    for k, (dx, dy) in enumerate(((0, 0), (1.8, 1.6), (-1.8, 1.2))):
        orn_ball(B(m, 'G:eggg', True), c + Vector((dx, dy, 1.6)), 1.6, scale=(0.85, 0.85, 1.15))
    membrane_wings(m, 4.4, 1.0, 13.0, 12.0, 'drakemem', 'drake')
    with layer(m, 'Tail'):
        m.chain([(0, 11.8, 8), (0, 15.4, 6.6), (0, 18.4, 8)], [2.2, 1.5, 0.9], 'drake')
        spine(m, [Vector((0, 14, 8.6)), Vector((0, 17, 8.8))], 'gold', 1.6, 0.5)
    return m


def c7_6():  # Hive Queen (Mythic) : reine abeille de l'espace, couronne de cristal
    m = Vox(28, seed=76)
    m.ell((0, 0, 11), (4.4, 4.0, 4.4), 'bee')
    m.ell((0, 7, 9.4), (5.2, 6.6, 5.0), 'bee')
    m.paint(lambda x, y, z: y > 2.6 and int(y) % 3 == 0, 'beeb')
    m.ell((0, -5.6, 13.6), (3.8, 3.6, 3.6), 'beeb')
    for s in (-1, 1):
        for k in range(3):
            y = -1.6 + k * 1.8
            m.chain([(s * 3.4, y, 9.0), (s * 5.4, y - 0.4, 5.0), (s * 5.6, y - 0.8, 0.6)], [0.6, 0.5, 0.45], 'beeb')
        orn_sweep(B(m, 'beeb', True), [(s * 1.2, -7.4, 16.0), (s * 2.6, -9.4, 19.0), (s * 3.6, -9.0, 20.4)], [0.25, 0.2, 0.15], sides=6)
        orn_ball(B(m, 'G:hivec', True), (s * 3.6, -9.0, 20.6), 0.5)
    fierce_eyes(m, 1.8, 14.2, 1.15, 'hivec', inset=0.25)
    orn_cone(B(m, 'beeb'), (0, 13.4, 8.2), (0, 1, -0.3), 3.4, 1.0, sides=8)
    for k in range(7):
        a = k / 7 * math.tau
        orn_crystal(B(m, 'G:hivec' if k % 2 == 0 else 'gold'), (math.cos(a) * 2.2, -5.6 + math.sin(a) * 2.2, 16.8), (math.cos(a) * 0.3, math.sin(a) * 0.3, 1), 3.4 if k % 2 == 0 else 2.2, 0.55)
    orn_torus(B(m, 'gold', True), (0, -5.6, 16.6), 2.4, 0.4, sides=8, seg=32)
    for s, nm in ((-1, 'WingL'), (1, 'WingR')):
        with layer(m, nm):
            orn_ball(B(m, 'beewing', True), (s * 6.4, 1.0, 16.0), 5.0, scale=(1.0, 0.1, 0.55))
            orn_ball(B(m, 'beewing', True), (s * 5.2, 3.0, 12.4), 3.6, scale=(1.0, 0.1, 0.5))
            orn_sweep(B(m, 'G:hivec', True), [(s * 2.4, 1.0, 15.6), (s * 7.0, 1.0, 17.2), (s * 11.0, 1.0, 16.2)], [0.15, 0.12, 0.06], sides=6)
    with layer(m, 'Orbit'):
        for k in range(6):
            a = k / 6 * math.tau
            p = Vector((math.cos(a) * 11, 2 + math.sin(a) * 11, 12 + (k % 2) * 3))
            orn_ball(B(m, 'G:eggg', True), p, 0.8, scale=(1, 1, 1.25))
    return m


def c7_7():  # Cosmic Mother (Cosmic) : la mère cosmique de tous les œufs, ailée, faite de galaxies
    m = Vox(38, seed=77)
    m.ell((0, 2, 13), (6.4, 6.0, 9.0), 'cosm')
    m.chain([(0, -1.6, 21), (0, -3.4, 26)], [4.0, 3.4], 'cosm')
    m.ell((0, -4.6, 29.0), (4.6, 4.6, 4.2), 'cosm')
    for s in (-1, 1):
        m.chain([(s * 2.8, 2, 6), (s * 3.0, 1, 2), (s * 3.0, -0.6, 0.6)], [2.2, 1.6, 1.4], 'cosm')
        for k in range(3):
            orn_cone(B(m, 'gold'), (s * (2.2 + k * 0.7), -2.4, 0.5), (0, -1, -0.3), 1.4, 0.32, sides=6)
    m.paint(lambda x, y, z: ((math.atan2(y, x) * 2 + z * 0.25) % 2.0) < 0.5, 'cosmv')
    m.paint(lambda x, y, z: abs(math.sin(math.atan2(y, x) * 3 + z * 0.4)) < 0.12, 'G:cosmp')
    m.paint(lambda x, y, z: abs(math.sin(math.atan2(y, x) * 2 - z * 0.5)) < 0.08, 'G:cosmc')
    glow_specks(m, 'G:cosmw', 24)
    fierce_eyes(m, 2.2, 30.0, 1.3, 'cosmc', inset=0.2)
    orn_cone(B(m, 'gold'), (0, front_y(m, 0, 28.6) + 0.4, 28.6), (0, -1, -0.3), 2.4, 0.8, sides=8)
    for k in range(9):
        a = k / 9 * math.pi
        x = math.cos(a) * 3.2
        z = 32.6 + math.sin(a) * 1.0
        L = 4.2 if k % 2 == 0 else 2.8
        orn_crystal(B(m, 'G:cosmp' if k % 2 == 0 else 'gold'), (x, -4.4, z), (x * 0.15, 0.1, 1), L, 0.6)
    orn_torus(B(m, 'G:cosmw', True), (0, -2.4, 34.4), 5.6, 0.45, tilt=0.35, seg=56, sides=10)
    feather_wings(m, 5.6, 2.0, 20.0, 20.0, 'cosmv', 'cosmc', 'G:cosmp', 'gold')
    with layer(m, 'Tail'):
        for k in range(6):
            a = (k - 2.5) * 0.3
            b = Vector((0, 7.0, 8.0))
            orn_feather(B(m, ('G:cosmp', 'cosmv', 'G:cosmc')[k % 3], True), b, b + Vector((math.sin(a) * 6, 13.0, -3.0 + math.cos(a) * 3)), 1.6, up=(0, 0, 1))
    with layer(m, 'Orbit'):
        for k in range(8):
            a = k / 8 * math.tau
            p = Vector((math.cos(a) * 17, 2 + math.sin(a) * 17, 18 + (k % 3) * 3))
            if k % 2:
                planet(m, p, 1.4, ('cosmp', 'cosmc', 'cosmv', 'gold')[k // 2 % 4], 'cosmw')
            else:
                orn_ball(B(m, 'G:eggg', True), p, 1.2, scale=(0.85, 0.85, 1.15))
    return m


CREATURES.update({
    2: (c2_1, c2_2, c2_3, c2_4, c2_5, c2_6),
    3: (c3_1, c3_2, c3_3, c3_4, c3_5, c3_6),
    4: (c4_1, c4_2, c4_3, c4_4, c4_5, c4_6),
    5: (c5_2, c5_3, c5_4, c5_5, c5_6, c5_7),
    6: (c6_2, c6_3, c6_4, c6_5, c6_6, c6_7),
    7: (c7_2, c7_3, c7_4, c7_5, c7_6, c7_7),
})
print("créatures des anneaux 2 à 7 chargées")
