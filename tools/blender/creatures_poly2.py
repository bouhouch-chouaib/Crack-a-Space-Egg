# Créatures low-poly des anneaux 2 à 7 (charger voxkit.py, creatures.py, polykit.py, creatures_poly.py, puis ce fichier).
# Même règle que l'anneau 1 : animal en blocs mignon en bas de l'échelle, bête réaliste et menaçante en haut.
# Avant vers -y, sol à z = 0. Groupes animés : Tail, WingL, WingR, Orbit.

import math
from mathutils import Vector, Matrix

V = Vector


# GABARITS -----------------------------------------------------------------------------------

def quad(m, k, foot, L=6.0, W=3.2, H=3.0, leg=3.0, legw=1.2, claw=False, slope=0.0):
    """Corps de quadrupède (de y = -L/2 à +L/2). Renvoie la hauteur du milieu du corps."""
    zb = leg + H / 2
    x = W / 2 - legw * 0.4
    for s in (-1, 1):
        for y, fat in ((-L / 2 + legw * 0.8, 1.0), (L / 2 - legw * 0.8, 1.15)):
            chain(B(m, k), [(s * x, y, zb - H * 0.15), (s * x, y, 0.55)], [(legw * 1.2 * fat, legw * 1.25 * fat), (legw * 0.9, legw * 0.95)])
            box(B(m, foot), (s * x, y - 0.15, 0.3), (legw * 1.2, legw * 1.45, 0.6), bevel=0.2)
            if claw:
                claws(m, s * x, y - legw * 0.85, 0.3, n=3, length=legw * 0.45, radius=legw * 0.13, spread=legw * 0.32)
    frustum(B(m, k), (0, L / 2, zb - slope), (0, -L / 2, zb + slope), (W * 0.92, H * 0.92), (W, H))
    return zb


def biped_legs(m, k, foot, x, y, hip, w, claw=True, bend=1.0):
    for s in (-1, 1):
        chain(B(m, k), [(s * x, y, hip), (s * x, y + 1.0 * bend, hip * 0.5), (s * x, y - 0.2, 0.55)], [(w * 1.5, w * 1.6), (w * 0.85, w * 0.9), (w * 0.75, w * 0.8)])
        box(B(m, foot), (s * x, y - 0.5, 0.3), (w * 1.3, w * 2.0, 0.6), bevel=0.2)
        if claw:
            claws(m, s * x, y - w * 1.45, 0.3, n=3, length=w * 0.55, radius=w * 0.14, spread=w * 0.38)


def cute_head(m, k, c, size, muzzle=None, nose='nose', eye_scale=1.0):
    cx, cy, cz = c
    w, d, h = size
    box(B(m, k), c, size, bevel=0.18)
    fy = cy - d / 2
    if muzzle:
        box(B(m, muzzle), (cx, fy - 0.35, cz - h * 0.22), (w * 0.48, 0.8, h * 0.34), bevel=0.22)
        if nose:
            box(D(m, nose), (cx, fy - 0.8, cz - h * 0.12), (w * 0.2, 0.25, h * 0.13), bevel=0.25)
    eyes_cute(m, w * 0.23, cz + h * 0.1, fy, w=w * 0.21 * eye_scale, h=h * 0.28 * eye_scale)
    return fy


def beast_head(m, k, kl, kd, c, size, snout, iris, teeth=4, jaw=0.35, nose='nose', tilt=0.38):
    cx, cy, cz = c
    w, d, h = size
    box(B(m, k), c, size, bevel=0.18)
    fy = cy - d / 2
    frustum(B(m, kl), (cx, fy + 0.3, cz - h * 0.1), (cx, fy - snout, cz - h * 0.2), (w * 0.72, h * 0.52), (w * 0.44, h * 0.34))
    frustum(B(m, kd), (cx, fy + 0.3, cz - h * 0.46), (cx, fy - snout * 0.85, cz - h * 0.46 - jaw), (w * 0.62, h * 0.22), (w * 0.36, h * 0.16))
    box(D(m, 'mouth'), (cx, fy - snout * 0.42, cz - h * 0.36 - jaw * 0.5), (w * 0.46, snout * 0.75, max(0.2, jaw)), bevel=0.1)
    if nose:
        box(D(m, nose), (cx, fy - snout - 0.05, cz - h * 0.06), (w * 0.22, 0.3, h * 0.14), bevel=0.25)
    if teeth:
        teeth_row(m, cx - w * 0.17, cx + w * 0.17, fy - snout * 0.78, cz - h * 0.3, teeth, h * 0.2, h * 0.055)
        teeth_row(m, cx - w * 0.14, cx + w * 0.14, fy - snout * 0.68, cz - h * 0.44 - jaw, max(2, teeth - 1), h * 0.15, h * 0.05, down=False)
    eyes_fierce(m, w * 0.25, cz + h * 0.14, fy - 0.02, w=w * 0.3, h=h * 0.19, iris=iris, tilt=tilt)
    return fy


def ears(m, k, kin, x, y, z, kind, size=1.0):
    for s in (-1, 1):
        if kind == 'cat':
            frustum(B(m, k), (s * x, y, z), (s * (x + 0.3 * size), y + 0.1, z + 1.7 * size), (1.3 * size, 0.5 * size), (0.15, 0.15), up=(0, -1, 0))
            if kin:
                frustum(D(m, kin), (s * x, y - 0.3 * size, z + 0.15), (s * (x + 0.25 * size), y - 0.2 * size, z + 1.25 * size), (0.75 * size, 0.12), (0.1, 0.1), up=(0, -1, 0))
        elif kind == 'round':
            box(B(m, k), (s * x, y, z + 0.4 * size), (1.1 * size, 0.55 * size, 1.1 * size), bevel=0.25)
            if kin:
                box(D(m, kin), (s * x, y - 0.3 * size, z + 0.4 * size), (0.6 * size, 0.1, 0.6 * size), bevel=0.2)
        elif kind == 'long':
            frustum(B(m, k), (s * x, y, z), (s * (x + 0.3 * size), y + 0.3, z + 3.4 * size), (1.1 * size, 0.5 * size), (0.75 * size, 0.4 * size), up=(0, -1, 0))
            if kin:
                frustum(D(m, kin), (s * x, y - 0.27 * size, z + 0.3), (s * (x + 0.28 * size), y + 0.05, z + 3.0 * size), (0.6 * size, 0.1), (0.4 * size, 0.1), up=(0, -1, 0))
        elif kind == 'floppy':
            box(B(m, k), (s * (x + 0.25 * size), y, z - 0.9 * size), (0.5 * size, 1.3 * size, 2.1 * size), rot=(0, s * 0.25, 0), bevel=0.2)


def fan_wing(m, s, root, span, keys, n=7, a0=70, a1=-35, w=0.17):
    root = V(root)
    for i in range(n):
        phi = math.radians(a0 + (a1 - a0) * i / (n - 1))
        L = span * (0.72 + 0.28 * math.sin(i / (n - 1) * math.pi))
        tip = root + V((s * math.cos(phi) * L, 0.5 + i * 0.06, math.sin(phi) * L))
        frustum(B(m, keys[i % len(keys)]), root, tip, (span * w, 0.32), (span * w * 0.3, 0.16), up=(0, 1, 0), bevel=0.1)


def bat_wing(m, s, root, span, memb, bone, claw_key='claw'):
    root = V(root)
    elbow = root + V((s * span * 0.32, 0.4, span * 0.34))
    wrist = root + V((s * span * 0.62, 0.8, span * 0.44))
    chain(D(m, bone), [root, elbow, wrist], [(span * 0.07, span * 0.07), (span * 0.05, span * 0.05), (span * 0.035, span * 0.035)])
    spike(D(m, claw_key), wrist, (s * 0.5, 0, 1), span * 0.11, span * 0.025)
    tips = [wrist + V((s * span * 0.36, 0.5, -span * 0.1)), wrist + V((s * span * 0.28, 0.5, -span * 0.38)),
            wrist + V((s * span * 0.1, 0.4, -span * 0.55)), root + V((s * span * 0.2, 0.6, -span * 0.16))]
    for f in tips[:3]:
        chain(D(m, bone), [wrist, f], [(span * 0.025, span * 0.025), (span * 0.01, span * 0.01)])
    outline = [root, wrist, tips[0], wrist.lerp(tips[1], 0.55) + V((s * span * 0.05, 0, span * 0.03)), tips[1],
               wrist.lerp(tips[2], 0.55) + V((s * span * 0.03, 0, span * 0.05)), tips[2], tips[3]]
    slab(B(m, memb), outline, (0, 1, 0), max(0.2, span * 0.02))


def fish_body(m, k, L, W, H, z):
    chain(B(m, k), [(0, -L * 0.5, z), (0, -L * 0.22, z), (0, L * 0.22, z), (0, L * 0.5, z)], [(W * 0.55, H * 0.6), (W, H), (W * 0.82, H * 0.82), (W * 0.32, H * 0.36)])


def coil(R, turns, z0, z1, n=14, cy=1.5, shrink=0.4, a0=0.0):
    out = []
    for i in range(n + 1):
        t = i / n
        a = a0 + t * turns * math.tau
        r = R * (1 - shrink * t)
        out.append(V((math.cos(a) * r, cy + math.sin(a) * r, z0 + (z1 - z0) * t)))
    return out


def spikes_line(m, key, pts, L, r, lean=0.35):
    for p in pts:
        spike(D(m, key), p, (0, lean, 1), L, r)


def glow_cracks(m, key, n, box_min, box_max, w=0.18):
    for _ in range(n):
        p = V(tuple(m.rnd.uniform(a, b) for a, b in zip(box_min, box_max)))
        box(D(m, key), p, (w, m.rnd.uniform(0.6, 1.5), w), rot=(m.rnd.uniform(-1, 1), 0, m.rnd.uniform(-1, 1)), bevel=0.0)


def orbit_bits(m, R, z, n, keys, kind='crystal', size=1.0, cy=0.5):
    with layer(m, 'Orbit'):
        for i in range(n):
            a = i / n * math.tau + 0.4
            p = V((math.cos(a) * R, cy + math.sin(a) * R, z + (i % 2) * 1.2))
            k = keys[i % len(keys)]
            if kind == 'crystal':
                orn_crystal(D(m, k), p, (0.15, 0.1, 1), 2.2 * size, 0.6 * size, sides=4, tip=0.5, double=True)
            elif kind == 'star':
                orn_star(D(m, k), p, 0.9 * size, 0.38 * size, 0.3 * size, normal=(math.cos(a), math.sin(a), 0))
            elif kind == 'cube':
                box(D(m, k), p, (0.9 * size, 0.9 * size, 0.9 * size), rot=(0.6, 0.4 * i, 0.3), bevel=0.15)
            elif kind == 'ball':
                blob(D(m, k), p, (0.8 * size, 0.8 * size, 0.8 * size), None)


# PALETTE ------------------------------------------------------------------------------------

PALP.update({
    'white': '#f6f8ff', 'gray': '#8a90a0', 'black': '#1a1a22', 'beak': '#ff9a2a', 'flame': '#ff5a0a', 'flamey': '#ffd23a',
    # 2 glace
    'peng': '#1e2a4a', 'pengw': '#f2f6ff', 'icec': '#9fe8ff', 'icecd': '#4ec3ff', 'icecg': '#6af0ff',
    'mothw': '#f4f0ff', 'mothfur': '#dcd4ff', 'mothwing': '#d8eeff', 'mothant': '#9c8cd0',
    'otter': '#6ab4f0', 'otterlt': '#d6eeff', 'otterdk': '#3a7ac8',
    'seal': '#e8f2ff', 'seallt': '#ffffff', 'sealdk': '#8cb0d8', 'comet': '#5ff0ff',
    'owl': '#3a2a6a', 'owllt': '#6a4aa8', 'owlface': '#d8d0f0', 'aurg': '#2dffa0', 'aurv': '#a35cff', 'aurp': '#ff5cd6',
    'yeti': '#e4f0ff', 'yetidk': '#4a5a8a', 'yetiface': '#7a8ac8',
    # 3 magma
    'slug': '#3a2c2c', 'slugdk': '#1e1616', 'lava': '#ff5a0a', 'lavay': '#ffb21a',
    'crab': '#e03a2a', 'crablt': '#ff8a6a', 'crabshell': '#4a3430',
    'newt': '#ff7a1a', 'newtlt': '#ffd08a', 'newtdk': '#b8400e',
    'obs': '#22182a', 'obslt': '#4a3060', 'horn': '#d8c8b0',
    'phx': '#ffb81a', 'phxr': '#ff3a1a', 'phxo': '#ff8a1a',
    'wyrm': '#3a2a2a', 'wyrmdk': '#1c1212', 'wyrmmem': '#c83a1a',
    # 4 nébuleuse
    'jelly': '#ff7ad8', 'jellylt': '#ffc4f0', 'jellyt': '#c87aff',
    'kit': '#c0a0ff', 'kitlt': '#ece0ff', 'cloud': '#fbf8ff',
    'whale': '#5ab8ff', 'whalelt': '#d4f0ff', 'whaledk': '#2a6ac8', 'nebc': '#ff9ce0', 'nebv': '#b88cff',
    'ray': '#1a1a52', 'raylt': '#3a3a8a', 'prR': '#ff3a5a', 'prY': '#ffe03a', 'prG': '#4aff7a', 'prB': '#3ac8ff', 'prV': '#a04aff', 'prismc': '#7affff',
    'lion': '#f0b84a', 'lionlt': '#ffe8b8', 'liondk': '#a8701e', 'mane': '#8a4a1a', 'nova': '#fff27a', 'novao': '#ffb21a',
    'uni': '#f6f2ff', 'unidk': '#b8b0d8', 'galp': '#ff5cd6', 'galc': '#3ae8ff', 'galv': '#8a4aff',
    # 5 dévoreur
    'beetle': '#1e5a3a', 'beetlelt': '#4aa86a', 'beetledk': '#10301e',
    'bat': '#5a2a8a', 'batlt': '#8a5ac8', 'batmem': '#3a1a5a', 'baty': '#ffe03a',
    'shark': '#1e2040', 'sharkb': '#c8c8e8', 'voidc': '#7a5aff',
    'hound': '#2e2a38', 'houndlt': '#d8d0c0', 'teal': '#2ff0e0',
    'serp': '#3a1a5a', 'serplt': '#e8c8a8', 'rune': '#c87aff',
    'eclip': '#2a1428', 'eclipdk': '#140a14', 'cosmo': '#ff4fd0', 'eclipg': '#ffc21a', 'eclipl': '#f0c8e8',
    # 6 faille
    'snail': '#3ac8b8', 'snaillt': '#9af0e0', 'shellc': '#e8b84a', 'clockw': '#fff8e8', 'clockd': '#2a2030',
    'cat': '#2e2e3e', 'catlt': '#5a5a72', 'glc': '#2ff0ff', 'glm': '#ff3ae0',
    'pandaw': '#f6f6f6', 'pandab': '#1e1e26', 'time': '#7affff',
    'tort': '#6aa04a', 'tortdk': '#3a6a2a', 'tortsh': '#8a5a2a', 'glass': '#cdeeff', 'sand': '#ffd27a',
    'grif': '#c8902a', 'griflt': '#ffd88a', 'grifw': '#fff8ee', 'rift': '#ff3ae0', 'riftc': '#3af0ff',
    'krak': '#d83a3a', 'kraklt': '#ff8ab0', 'quasar': '#e8ffff', 'quasarc': '#5ff0ff',
    # 7 nid
    'chick': '#ffe04a', 'chicklt': '#fff4a0', 'shell7': '#3a2a6a', 'shell7lt': '#7a5ac8',
    'yolk': '#ffc21a', 'yolklt': '#ffe68a', 'yolkdk': '#e8901a', 'albumen': '#fffaf0',
    'raptor': '#4a8a3a', 'raptorlt': '#b8e08a', 'amber': '#ffaa2a', 'amberdk': '#c8701a',
    'drake': '#8a4a2a', 'drakelt': '#e0a070', 'twig': '#7a4a24', 'eggg': '#ffe27a', 'drakemem': '#c87a4a',
    'bee': '#ffc21a', 'beeb': '#1e1a20', 'beewing': '#d8f0ff', 'hivec': '#ff5cd6', 'mantis': '#5aa84a', 'mantisdk': '#2e6a2a',
    'cosm': '#24164e', 'cosmp': '#ff5cd6', 'cosmc': '#3ae8ff', 'cosmv': '#8a4aff', 'cosmw': '#fffaf0',
})


# ANNEAU 2 : GLACE ---------------------------------------------------------------------------

def q2_1():  # Frostling (Common) : bébé pingouin en blocs, couronne de glace
    m = Poly(21)
    for s in (-1, 1):
        box(B(m, 'beak'), (s * 0.9, -0.6, 0.25), (1.2, 1.8, 0.5), bevel=0.25)
        box(B(m, 'peng'), (s * 2.0, 0.2, 3.4), (0.5, 1.6, 2.8), rot=(0, s * 0.35, 0), bevel=0.2)
    box(B(m, 'peng'), (0, 0.2, 3.0), (3.6, 3.0, 4.6), bevel=0.2)
    box(B(m, 'pengw'), (0, -1.25, 2.7), (2.6, 0.3, 3.6), bevel=0.2)
    box(B(m, 'peng'), (0, 0.0, 6.6), (3.4, 3.0, 2.8), bevel=0.18)
    box(B(m, 'pengw'), (0, -1.45, 6.4), (2.5, 0.2, 1.9), bevel=0.15)
    eyes_cute(m, 0.62, 6.7, -1.55, w=0.7, h=0.9)
    frustum(D(m, 'beak'), (0, -1.5, 6.0), (0, -2.6, 5.85), (0.9, 0.6), (0.2, 0.15))
    for x, L in ((0, 2.0), (0.9, 1.4), (-0.9, 1.4)):
        orn_crystal(D(m, 'icec' if x == 0 else 'icecd'), (x, 0, 7.8), (x * 0.3, 0, 1), L, 0.45, sides=5)
    return m


def q2_2():  # Snow Moth (Uncommon) : papillon de nuit duveteux, ailes de flocons
    m = Poly(22)
    for s in (-1, 1):
        for y in (-1, 0, 1):
            chain(D(m, 'mothant'), [(s * 1.0, y * 0.8, 2.8), (s * 2.0, y * 0.8 - 0.2, 1.4), (s * 2.2, y * 0.8 - 0.3, 0.1)], [(0.28, 0.28), (0.22, 0.22), (0.16, 0.16)])
    box(B(m, 'mothfur'), (0, 0, 3.6), (2.6, 2.4, 2.6), bevel=0.25)
    frustum(B(m, 'mothw'), (0, 1.0, 3.4), (0, 4.4, 3.0), (2.2, 2.2), (0.9, 0.9))
    blob(B(m, 'mothfur'), (0, -0.9, 3.8), (1.7, 0.8, 1.6), m.rnd, 0.15)
    box(B(m, 'mothw'), (0, -1.9, 4.2), (2.4, 1.8, 2.2), bevel=0.2)
    eyes_cute(m, 0.6, 4.4, -2.8, w=0.72, h=0.85)
    for s in (-1, 1):
        chain(D(m, 'mothant'), [(s * 0.5, -2.2, 5.2), (s * 1.2, -3.0, 6.8), (s * 1.8, -2.8, 7.6)], [(0.2, 0.2), (0.15, 0.15), (0.1, 0.1)])
        blob(D(m, 'G:icecg'), (s * 1.8, -2.8, 7.7), (0.32, 0.32, 0.32), None)
    for s, nm in ((-1, 'WingL'), (1, 'WingR')):
        with layer(m, nm):
            pts = [(s * 1.1, 0.5, 4.8), (s * 5.4, 0.5, 8.0), (s * 7.0, 0.5, 5.8), (s * 5.2, 0.5, 3.8), (s * 6.0, 0.5, 1.8), (s * 3.4, 0.5, 1.6), (s * 1.1, 0.5, 3.2)]
            slab(B(m, 'mothwing'), pts, (0, 1, 0), 0.25)
            orn_star(D(m, 'G:icecg'), (s * 4.6, 0.25, 5.8), 0.85, 0.35, 0.12, normal=(0, -1, 0))
            orn_star(D(m, 'G:icecg'), (s * 3.9, 0.25, 2.6), 0.55, 0.22, 0.1, normal=(0, -1, 0))
    return m


def q2_3():  # Glacier Otter (Rare) : loutre debout qui serre un éclat de glace
    m = Poly(23)
    for s in (-1, 1):
        box(B(m, 'otterdk'), (s * 1.3, 0.4, 0.8), (1.6, 2.6, 1.6), bevel=0.25)
    frustum(B(m, 'otter'), (0, 0.4, 1.0), (0, -0.2, 5.8), (3.4, 2.8), (2.6, 2.2))
    box(B(m, 'otterlt'), (0, -1.25, 3.1), (2.2, 0.4, 3.4), bevel=0.2)
    box(B(m, 'otter'), (0, -0.4, 7.1), (3.0, 2.6, 2.4), bevel=0.18)
    box(B(m, 'otterlt'), (0, -2.0, 6.6), (1.7, 0.8, 1.0), bevel=0.22)
    box(D(m, 'nose'), (0, -2.45, 6.95), (0.6, 0.2, 0.4), bevel=0.25)
    for s in (-1, 1):
        for k in range(2):
            box(D(m, 'white'), (s * 1.3, -2.35, 6.55 + k * 0.3), (1.4, 0.08, 0.07), rot=(0, s * (0.15 - k * 0.3), 0), bevel=0.0)
        box(B(m, 'otterdk'), (s * 1.2, -0.2, 8.4), (0.6, 0.5, 0.6), bevel=0.25)
        chain(B(m, 'otter'), [(s * 1.5, -0.6, 5.2), (s * 0.8, -2.2, 4.4)], [(0.85, 0.85), (0.7, 0.7)])
    eyes_cute(m, 0.7, 7.6, -1.7, w=0.7, h=0.8)
    orn_crystal(D(m, 'icec'), (0, -2.5, 2.4), (0, -0.25, 1), 4.0, 0.75, sides=5)
    orn_crystal(D(m, 'G:icecg'), (0.3, -2.7, 2.8), (0.1, -0.3, 1), 2.4, 0.35, sides=5)
    with layer(m, 'Tail'):
        chain(B(m, 'otterdk'), [(0, 1.6, 1.0), (0, 3.8, 0.5), (0, 5.4, 0.35)], [(1.5, 0.6), (1.3, 0.5), (0.6, 0.3)])
    return m


def q2_4():  # Comet Seal (Epic) : phoque massif, corne de cristal, traîne de comète
    m = Poly(24)
    frustum(B(m, 'seal'), (0, 4.8, 1.8), (0, -1.0, 2.6), (2.2, 2.0), (4.4, 4.2))
    frustum(B(m, 'seal'), (0, -0.8, 2.6), (0, -2.4, 4.8), (4.4, 4.2), (3.4, 3.2))
    box(B(m, 'seal'), (0, -2.8, 6.2), (3.2, 3.0, 2.6), bevel=0.18)
    fy = -4.3
    frustum(B(m, 'seallt'), (0, -4.0, 5.6), (0, -5.4, 5.3), (2.0, 1.4), (1.4, 1.0))
    box(D(m, 'nose'), (0, -5.45, 5.6), (0.55, 0.25, 0.4), bevel=0.25)
    eyes_fierce(m, 0.9, 6.6, fy, w=0.95, h=0.55, iris='G:comet')
    for s in (-1, 1):
        spike(D(m, 'tooth'), (s * 0.5, -5.2, 4.9), (0, -0.25, -1), 1.8, 0.26)
        box(B(m, 'sealdk'), (s * 2.6, -1.4, 0.6), (2.4, 1.6, 0.5), rot=(0, 0, s * 0.3), bevel=0.2)
    orn_crystal(D(m, 'icec'), (0, -3.6, 7.4), (0, -0.6, 1), 3.6, 0.55, sides=5)
    for p in ((1.2, 1.0, 4.1), (-1.0, 2.6, 3.7), (0.4, 0.0, 4.6), (-1.5, -0.2, 4.0)):
        box(D(m, 'sealdk'), p, (0.7, 0.9, 0.2), rot=(0.1, 0, 0.5), bevel=0.2)
    glow_cracks(m, 'G:comet', 6, (-1.8, -1, 3.6), (1.8, 3.5, 4.4))
    with layer(m, 'Tail'):
        for s in (-1, 1):
            box(B(m, 'sealdk'), (s * 1.0, 5.6, 0.6), (1.8, 2.4, 0.4), rot=(0, 0, s * 0.3), bevel=0.2)
        flame_shape(D(m, 'G:comet'), (0, 4.6, 3.0), 5.0, 1.0, back=1.2)
        flame_shape(D(m, 'G:icecg'), (0, 4.8, 3.2), 3.4, 0.6, back=1.1)
        orn_star(D(m, 'G:star'), (0, 4.2, 4.6), 1.1, 0.45, 0.35, normal=(0, -1, 0.3))
    return m


def q2_5():  # Aurora Owl (Legendary) : grand hibou aux plumes d'aurore, serres d'or
    m = Poly(25)
    for s in (-1, 1):
        chain(D(m, 'gold'), [(s * 0.9, 0.2, 2.8), (s * 0.9, 0.0, 0.4)], [(0.55, 0.55), (0.42, 0.42)])
        claws(m, s * 0.9, -0.5, 0.2, n=3, length=0.75, radius=0.18, key='golddk', spread=0.35)
    frustum(B(m, 'owl'), (0, 0.5, 2.2), (0, 0, 7.8), (4.0, 3.6), (3.6, 3.2))
    box(B(m, 'owllt'), (0, -1.65, 4.6), (2.8, 0.4, 3.8), bevel=0.2)
    for i in range(3):
        box(D(m, 'G:aurg'), (0, -1.9, 3.4 + i * 1.1), (1.6 - i * 0.3, 0.15, 0.25), rot=(0, 0, 0), bevel=0.0)
    box(B(m, 'owl'), (0, -0.2, 9.8), (4.4, 3.4, 3.4), bevel=0.18)
    box(B(m, 'owlface'), (0, -1.95, 9.6), (3.6, 0.3, 2.6), bevel=0.15)
    eyes_fierce(m, 0.95, 9.9, -2.1, w=1.1, h=0.75, iris='G:aurg', tilt=0.3)
    frustum(D(m, 'gold'), (0, -2.0, 9.1), (0, -2.8, 8.2), (0.7, 0.6), (0.1, 0.1))
    for s in (-1, 1):
        frustum(B(m, 'owl'), (s * 1.6, -0.4, 11.2), (s * 2.7, 0.2, 13.4), (1.0, 0.8), (0.2, 0.2), up=(0, -1, 0))
        spike(D(m, 'G:aurv'), (s * 2.7, 0.2, 13.2), (s * 0.3, 0.2, 1), 1.0, 0.25)
    for s, nm in ((-1, 'WingL'), (1, 'WingR')):
        with layer(m, nm):
            fan_wing(m, s, (s * 1.9, 0.6, 7.4), 7.0, ['aurv', 'owllt', 'aurg', 'owl'], n=8, a0=75, a1=-40)
    with layer(m, 'Tail'):
        for i in range(5):
            a = (i - 2) * 0.3
            frustum(B(m, ('aurg', 'aurv', 'owllt')[i % 3]), (0, 1.6, 2.6), (math.sin(a) * 3.0, 5.0, 0.6), (0.9, 0.3), (0.3, 0.15), up=(0, 0, 1))
    with layer(m, 'Orbit'):
        for i, k in enumerate(('G:aurg', 'G:aurv', 'G:aurp')):
            orn_torus(D(m, k), (0, 0.5, 10.5), 6.0 - i * 0.5, 0.16, tilt=0.25 + i * 0.12, arc=(i / 3, i / 3 + 0.45), seg=30, sides=4)
    return m


def q2_6():  # Crystal Yeti (Mythic) : yéti massif façon gorille, cristaux de glace
    m = Poly(26)
    for s in (-1, 1):
        chain(B(m, 'yetidk'), [(s * 1.9, 1.4, 4.2), (s * 2.0, 1.6, 0.6)], [(2.1, 2.1), (1.8, 1.8)])
        box(B(m, 'yetidk'), (s * 2.0, 1.2, 0.35), (2.2, 2.8, 0.7), bevel=0.2)
    frustum(B(m, 'yeti'), (0, 1.2, 3.6), (0, 0.2, 9.8), (4.8, 3.6), (7.6, 4.8))
    box(B(m, 'yetiface'), (0, -2.0, 7.6), (4.2, 0.6, 3.0), rot=(0.15, 0, 0), bevel=0.2)
    box(B(m, 'yeti'), (0, -1.4, 11.2), (3.0, 3.0, 2.6), bevel=0.18)
    box(B(m, 'yetidk'), (0, -2.85, 11.9), (3.0, 0.5, 0.6), bevel=0.2)
    box(B(m, 'yetiface'), (0, -2.95, 10.8), (2.2, 0.3, 1.8), bevel=0.15)
    eyes_fierce(m, 0.6, 11.3, -3.1, w=0.75, h=0.42, iris='G:icecg')
    box(D(m, 'mouth'), (0, -3.15, 10.15), (1.3, 0.2, 0.5), bevel=0.1)
    teeth_row(m, -0.45, 0.45, -3.25, 9.95, 2, 0.6, 0.16, down=False)
    for s in (-1, 1):
        chain(B(m, 'yeti'), [(s * 3.9, 0.2, 9.6), (s * 4.9, -0.6, 6.2), (s * 4.7, -1.4, 3.0)], [(2.3, 2.3), (2.0, 2.0), (1.9, 1.9)])
        box(B(m, 'yetidk'), (s * 4.7, -1.6, 1.5), (2.7, 2.7, 2.5), bevel=0.2)
        claws(m, s * 4.7, -3.0, 0.9, n=3, length=0.7, radius=0.24, spread=0.7)
        for k in range(3):
            orn_crystal(D(m, ('icec', 'icecd', 'G:icecg')[k]), (s * (3.6 + k * 0.5), 0.6 + k * 0.4, 9.8), (s * 0.6, 0.3, 1), 2.6 - k * 0.4, 0.55, sides=5)
    for (x, y, z, L) in ((0, 1.6, 10.4, 3.4), (1.6, 2.0, 9.4, 2.4), (-1.6, 2.0, 9.4, 2.4), (0.8, 2.4, 7.4, 2.0), (-0.8, 2.4, 7.0, 2.0)):
        orn_crystal(D(m, 'G:icecg' if x == 0 else 'icec'), (x, y, z), (x * 0.2, 0.6, 1), L, 0.6, sides=5)
    orbit_bits(m, 8.0, 10.0, 5, ['icec', 'icecd', 'G:icecg'], kind='crystal', size=1.1)
    return m


# ANNEAU 3 : MAGMA ---------------------------------------------------------------------------

def q3_1():  # Cinder Slug (Common) : limace sombre à taches de lave
    m = Poly(31)
    chain(B(m, 'slug'), [(0, 4.0, 0.6), (0, 1.0, 1.2), (0, -1.6, 1.6)], [(1.6, 1.0), (2.8, 2.2), (3.0, 2.8)])
    box(B(m, 'slug'), (0, -2.4, 3.0), (3.0, 2.4, 2.8), bevel=0.22)
    box(B(m, 'slugdk'), (0, 0.0, 0.25), (3.0, 7.0, 0.5), bevel=0.2)
    eyes_cute(m, 0.65, 3.2, -3.6, w=0.75, h=0.95)
    for s in (-1, 1):
        chain(B(m, 'slug'), [(s * 0.8, -2.6, 4.2), (s * 1.2, -2.8, 5.6)], [(0.4, 0.4), (0.3, 0.3)])
        blob(D(m, 'G:lava'), (s * 1.2, -2.8, 5.8), (0.35, 0.35, 0.35), None)
    for p in ((0.9, 0.4, 2.3), (-0.8, 1.4, 2.1), (0.3, -0.8, 2.6), (-1.1, -1.6, 2.9), (0.6, 2.6, 1.5)):
        box(D(m, 'G:lava'), p, (0.7, 0.7, 0.2), rot=(0.2, 0.1, 0.7), bevel=0.2)
    return m


def q3_2():  # Lava Crab (Uncommon) : crabe rouge, carapace en volcan
    m = Poly(32)
    box(B(m, 'crab'), (0, 0.4, 2.6), (5.6, 4.0, 2.2), bevel=0.25)
    frustum(B(m, 'crabshell'), (0, 0.6, 3.6), (0, 0.6, 6.0), (4.0, 3.2), (1.6, 1.3), up=(0, -1, 0))
    box(D(m, 'G:lava'), (0, 0.6, 6.05), (1.2, 1.0, 0.2), bevel=0.2)
    flame_shape(D(m, 'G:flame'), (0, 0.6, 6.0), 1.8, 0.5, back=0.2)
    for s in (-1, 1):
        for k in range(3):
            y = -0.6 + k * 1.4
            chain(B(m, 'crab'), [(s * 2.6, y, 2.2), (s * 4.0, y + 0.3, 1.8), (s * 4.6, y + 0.4, 0.2)], [(0.6, 0.6), (0.5, 0.5), (0.3, 0.3)])
        chain(B(m, 'crab'), [(s * 2.4, -1.4, 2.8), (s * 3.6, -3.0, 3.0)], [(0.8, 0.8), (0.9, 0.9)])
        box(B(m, 'crab'), (s * 3.9, -4.2, 3.2), (1.8, 2.0, 1.4), bevel=0.25)
        box(B(m, 'crablt'), (s * 3.6, -5.6, 3.6), (0.6, 1.4, 0.6), rot=(0, 0, s * 0.3), bevel=0.2)
        box(B(m, 'crablt'), (s * 4.3, -5.4, 2.8), (0.6, 1.2, 0.5), rot=(0, 0, -s * 0.2), bevel=0.2)
    fy = 0.4 - 2.0
    box(B(m, 'crab'), (0, fy + 0.2, 3.9), (2.4, 0.6, 0.8), bevel=0.2)
    eyes_cute(m, 0.65, 4.7, fy - 0.1, w=0.7, h=0.85)
    for s in (-1, 1):
        chain(D(m, 'crab'), [(s * 0.65, fy, 3.8), (s * 0.65, fy, 4.2)], [(0.3, 0.3), (0.3, 0.3)])
    return m


def q3_3():  # Blaze Newt (Rare) : salamandre orange, collerettes de flammes
    m = Poly(33)
    zb = quad(m, 'newt', 'newtdk', L=6.0, W=3.0, H=1.8, leg=1.0, legw=0.9, claw=True)
    box(B(m, 'newtlt'), (0, 0, zb - 0.85), (2.2, 5.0, 0.3), bevel=0.15)
    box(B(m, 'newt'), (0, -4.2, zb + 0.4), (2.8, 2.6, 1.8), bevel=0.2)
    box(B(m, 'newtlt'), (0, -5.2, zb), (2.0, 1.0, 0.6), bevel=0.2)
    eyes_cute(m, 0.6, zb + 0.75, -5.5, w=0.7, h=0.8)
    for s in (-1, 1):
        for k in range(3):
            flame_shape(D(m, 'G:flame' if k != 1 else 'G:flamey'), (s * 1.3, -3.8 + k * 0.6, zb + 0.9), 1.6 - k * 0.3, 0.45, back=0.6)
    for y in (-1.8, 0.0, 1.8):
        flame_shape(D(m, 'G:flame'), (0, y, zb + 0.85), 1.5, 0.45, back=0.6)
    for p in ((0.8, 0.8, zb + 0.9), (-0.9, -0.6, zb + 0.9), (0.4, 2.4, zb + 0.85)):
        box(D(m, 'newtdk'), p, (0.6, 0.6, 0.2), bevel=0.2)
    with layer(m, 'Tail'):
        chain(B(m, 'newt'), [(0, 3.0, zb), (0, 5.2, zb - 0.6), (0, 7.2, zb - 0.6), (0, 8.6, zb - 0.2)], [(1.6, 1.2), (1.2, 0.9), (0.8, 0.6), (0.3, 0.3)])
        flame_shape(D(m, 'G:flamey'), (0, 8.6, zb), 1.4, 0.4, back=0.6)
    return m


def q3_4():  # Obsidian Rhino (Epic) : rhinocéros d'obsidienne, corne en feu, fissures de lave
    m = Poly(34)
    zb = quad(m, 'obs', 'obslt', L=8.0, W=4.6, H=4.4, leg=2.4, legw=1.7, claw=False, slope=0.3)
    for s in (-1, 1):
        for y in (-3.4, 3.4):
            for k in range(3):
                box(D(m, 'horn'), (s * 1.9 + (k - 1) * 0.5 * s, y - 1.3, 0.35), (0.45, 0.35, 0.5), bevel=0.2)
    frustum(B(m, 'obs'), (0, -3.8, zb + 0.4), (0, -5.2, zb + 0.2), (3.4, 3.4), (3.2, 3.2))
    fy = beast_head(m, 'obs', 'obslt', 'obs', (0, -6.2, zb), (3.2, 2.4, 2.8), 1.8, 'G:lava', teeth=0, jaw=0.15)
    spike(D(m, 'horn'), (0, fy - 1.3, zb + 0.2), (0, -0.55, 1), 3.4, 0.75)
    spike(D(m, 'G:lava'), (0, fy - 1.9, zb + 1.7), (0, -0.4, 1), 1.6, 0.35)
    flame_shape(D(m, 'G:flame'), (0, fy - 2.3, zb + 2.8), 2.2, 0.55, back=0.4)
    spike(D(m, 'horn'), (0, fy + 0.2, zb + 1.4), (0, -0.2, 1), 1.4, 0.45)
    for s in (-1, 1):
        frustum(B(m, 'obs'), (s * 1.0, -5.6, zb + 1.3), (s * 1.2, -5.4, zb + 2.3), (0.8, 0.4), (0.2, 0.2), up=(0, -1, 0))
    for (y, z) in ((-2.8, zb + 2.4), (-0.8, zb + 2.6), (1.2, zb + 2.5), (3.0, zb + 2.3)):
        orn_crystal(D(m, 'obslt'), (0, y, z), (0, 0.2, 1), 1.8, 0.6, sides=4)
    glow_cracks(m, 'G:lava', 14, (-2.4, -4, zb - 1.6), (2.4, 4, zb + 2.2), w=0.22)
    with layer(m, 'Tail'):
        chain(B(m, 'obs'), [(0, 4.0, zb + 0.6), (0, 5.4, zb - 0.6)], [(0.6, 0.6), (0.3, 0.3)])
    return m


def q3_5():  # Solar Phoenix (Legendary) : phénix d'or, ailes de feu, crête de flammes
    m = Poly(35)
    for s in (-1, 1):
        chain(D(m, 'golddk'), [(s * 0.9, 0.4, 3.0), (s * 1.0, 0.0, 0.4)], [(0.5, 0.5), (0.4, 0.4)])
        claws(m, s * 1.0, -0.6, 0.2, n=3, length=0.8, radius=0.17, key='golddk', spread=0.35)
    frustum(B(m, 'phx'), (0, 1.4, 3.0), (0, -0.6, 7.2), (3.6, 3.6), (2.8, 2.8))
    box(B(m, 'phxo'), (0, -1.3, 4.6), (2.4, 0.4, 3.0), bevel=0.2)
    frustum(B(m, 'phx'), (0, -0.8, 7.0), (0, -1.4, 9.0), (2.2, 2.2), (1.8, 1.8))
    box(B(m, 'phx'), (0, -1.6, 9.8), (2.4, 2.6, 2.0), bevel=0.18)
    frustum(D(m, 'beak'), (0, -2.9, 9.7), (0, -4.2, 9.1), (0.9, 0.8), (0.12, 0.12))
    eyes_fierce(m, 0.65, 10.2, -2.9, w=0.7, h=0.42, iris='G:flamey')
    for i in range(5):
        flame_shape(D(m, 'G:flame' if i % 2 else 'G:flamey'), (0, -1.6 + i * 0.6, 10.6 - i * 0.2), 2.8 - i * 0.3, 0.55, back=0.9)
    for s, nm in ((-1, 'WingL'), (1, 'WingR')):
        with layer(m, nm):
            fan_wing(m, s, (s * 1.4, 0.6, 7.0), 8.0, ['phxr', 'phxo', 'phx', 'G:flame'], n=8, a0=80, a1=-30)
            for i in range(3):
                flame_shape(D(m, 'G:flamey'), (s * (5.0 + i * 1.2), 1.2, 9.5 + i), 1.6, 0.4, back=0.4)
    with layer(m, 'Tail'):
        for i in range(5):
            a = (i - 2) * 0.26
            frustum(B(m, ('phxr', 'phxo', 'G:flame')[i % 3]), (0, 1.8, 3.6), (math.sin(a) * 3.0, 7.0, 1.0 + math.cos(a)), (0.9, 0.3), (0.25, 0.15))
    with layer(m, 'Orbit'):
        orn_torus(D(m, 'G:flamey'), (0, 0.2, 10.0), 5.2, 0.2, axis=(0, 1, 0.2), seg=30, sides=4)
    return m


def q3_6():  # Magma Wyrm (Mythic) : dragon serpent de lave refroidie, fissures lumineuses
    m = Poly(36)
    pts = coil(5.2, 1.4, 1.4, 5.4, n=16, cy=1.8, shrink=0.35)
    sizes = [(3.0 - 1.0 * i / 16, 2.6 - 0.8 * i / 16) for i in range(17)]
    chain(B(m, 'wyrm'), pts, sizes)
    neck = [pts[-1], V((0, -0.6, 8.6)), V((0, -2.0, 11.8))]
    chain(B(m, 'wyrm'), neck, [sizes[-1], (2.2, 2.0), (2.0, 1.8)])
    fy = beast_head(m, 'wyrm', 'wyrm', 'wyrmdk', (0, -2.8, 13.0), (2.8, 2.6, 2.4), 2.4, 'G:lavay', teeth=4, jaw=0.6)
    for s in (-1, 1):
        orn_sweep(D(m, 'obslt'), [(s * 0.9, -2.2, 14.0), (s * 1.6, -0.8, 15.6), (s * 1.9, 1.0, 16.2), (s * 1.6, 2.0, 15.6)], [0.45, 0.32, 0.18, 0.03], sides=5)
    for s, nm in ((-1, 'WingL'), (1, 'WingR')):
        with layer(m, nm):
            bat_wing(m, s, (s * 1.1, 0.0, 9.6), 9.0, 'wyrmmem', 'wyrmdk')
    spikes_line(m, 'obslt', [p + V((0, 0, 1.3)) for p in pts[::3]], 1.4, 0.45, lean=0.0)
    for p in pts[::2]:
        box(D(m, 'G:lava'), p + V((m.rnd.uniform(-1, 1), m.rnd.uniform(-0.5, 0.5), 0.9)), (0.22, 1.2, 0.22), rot=(m.rnd.uniform(-1, 1), 0, m.rnd.uniform(-1, 1)), bevel=0.0)
    flame_shape(D(m, 'G:flame'), (0, fy - 2.6, 12.0), 2.4, 0.7, back=-0.7)
    orbit_bits(m, 8.5, 9.0, 4, ['G:flamey', 'G:flame'], kind='ball', size=0.9)
    return m


# ANNEAU 4 : NÉBULEUSE -------------------------------------------------------------------------

def q4_1():  # Nebula Jelly (Common) : méduse rose pleine d'étoiles
    m = Poly(41)
    frustum(B(m, 'jelly'), (0, 0, 4.0), (0, 0, 7.4), (4.6, 4.6), (2.6, 2.6), up=(0, -1, 0))
    box(B(m, 'jellylt'), (0, 0, 3.8), (4.8, 4.8, 0.6), bevel=0.25)
    eyes_cute(m, 0.8, 5.3, -2.15, w=0.75, h=0.9)
    for p in ((1.4, -1.0, 6.4), (-1.0, 0.8, 6.8), (0.6, 1.4, 6.0)):
        orn_star(D(m, 'G:star'), p, 0.4, 0.17, 0.12, normal=(0, -1, 0.5))
    with layer(m, 'Tail'):
        for k in range(6):
            a = k / 6 * math.tau
            b = V((math.cos(a) * 1.6, math.sin(a) * 1.6, 3.5))
            chain(B(m, 'jellyt'), [b, b + V((0.4, 0, -1.4)), b + V((-0.3, 0.2, -2.6)), b + V((0.2, 0, -3.4))], [(0.6, 0.6), (0.5, 0.5), (0.4, 0.4), (0.2, 0.2)])
    return m


def q4_2():  # Haze Kitten (Uncommon) : chaton lavande, queue de nuage
    m = Poly(42)
    zb = quad(m, 'kit', 'kitlt', L=4.2, W=3.0, H=2.4, leg=1.6, legw=1.0)
    box(B(m, 'kitlt'), (0, -2.0, zb - 0.2), (2.0, 0.4, 1.8), bevel=0.2)
    fy = cute_head(m, 'kit', (0, -2.4, zb + 2.4), (3.6, 3.0, 3.0), muzzle='kitlt', nose='pink')
    ears(m, 'kit', 'pink', 1.1, -2.4, zb + 3.8, 'cat', 0.9)
    for s in (-1, 1):
        for k in range(2):
            box(D(m, 'white'), (s * 1.4, fy - 0.7, zb + 1.6 + k * 0.3), (1.5, 0.07, 0.06), rot=(0, s * (0.15 - k * 0.3), 0), bevel=0.0)
    with layer(m, 'Tail'):
        for k, (y, z, r) in enumerate(((2.6, zb + 0.8, 1.0), (3.4, zb + 2.0, 1.3), (3.6, zb + 3.4, 1.4), (3.2, zb + 4.6, 1.1))):
            blob(B(m, 'cloud'), (0.3 * (k % 2), y, z), (r, r, r * 0.85), m.rnd, 0.15)
    return m


def q4_3():  # Dreamfin (Rare) : petite baleine bleu ciel sur un nuage de nébuleuse
    m = Poly(43)
    for k in range(6):
        a = k / 6 * math.tau
        blob(B(m, 'nebc' if k % 2 else 'nebv'), (math.cos(a) * 2.6, 0.5 + math.sin(a) * 3.0, 1.0), (1.8, 1.8, 1.0), m.rnd, 0.15)
    fish_body(m, 'whale', 9.0, 4.4, 3.8, 3.8)
    box(B(m, 'whalelt'), (0, -0.8, 2.1), (3.2, 5.6, 0.4), bevel=0.2)
    for i in range(4):
        box(D(m, 'whaledk'), (0, -2.0 + i * 1.0, 1.9), (2.6, 0.15, 0.2), bevel=0.0)
    eyes_cute(m, 1.1, 4.4, -3.2, w=0.8, h=0.9)
    box(D(m, 'G:nebc'), (0, 0.2, 5.8), (0.6, 0.6, 0.25), bevel=0.2)
    for s in (-1, 1):
        slab(B(m, 'whaledk'), [(s * 2.0, -1.0, 3.0), (s * 4.2, 0.2, 1.8), (s * 3.6, 1.2, 2.0), (s * 2.0, 0.8, 2.8)], (0, 0, 1), 0.35)
    with layer(m, 'Tail'):
        for s in (-1, 1):
            slab(B(m, 'whaledk'), [(0, 4.2, 3.8), (s * 2.8, 6.2, 4.4), (s * 2.4, 5.0, 3.6)], (0, 0, 1), 0.35)
    orbit_bits(m, 6.0, 6.4, 4, ['G:star', 'G:nebc'], kind='star', size=0.8)
    return m


def q4_4():  # Prism Ray (Epic) : raie manta sombre, ailes de prisme arc-en-ciel
    m = Poly(44)
    box(B(m, 'ray'), (0, 0.4, 3.0), (4.0, 6.0, 1.6), bevel=0.25)
    for s in (-1, 1):
        slab(B(m, 'ray'), [(s * 1.8, -2.4, 3.2), (s * 7.4, 0.2, 4.6), (s * 8.0, 1.4, 4.2), (s * 1.8, 3.2, 3.0)], (0, 0, 1), 0.7)
        for i, k in enumerate(('prR', 'prY', 'prG', 'prB', 'prV')):
            f = 0.25 + i * 0.13
            box(D(m, 'G:' + k), (s * (1.8 + 5.6 * f), -2.4 + 2.6 * f + 1.6, 3.65 + f * 1.0), (0.4, 1.8, 0.15), rot=(0, 0, s * 0.4), bevel=0.0)
        frustum(B(m, 'raylt'), (s * 1.2, -2.6, 2.8), (s * 1.0, -4.2, 2.4), (0.8, 0.6), (0.3, 0.3))
    box(B(m, 'raylt'), (0, -2.6, 2.6), (2.8, 0.6, 1.0), bevel=0.2)
    box(D(m, 'mouth'), (0, -2.95, 2.3), (2.0, 0.2, 0.35), bevel=0.15)
    eyes_fierce(m, 0.95, 3.4, -2.6, w=0.8, h=0.4, iris='G:prismc')
    for k, x in enumerate((-1.2, -0.4, 0.4, 1.2)):
        orn_crystal(D(m, 'G:prismc' if k % 2 else 'prismc'), (x, 0.8, 3.7), (x * 0.1, 0.4, 1), 1.8, 0.4, sides=4)
    with layer(m, 'Tail'):
        chain(B(m, 'ray'), [(0, 3.4, 3.0), (0, 6.6, 3.2), (0, 9.4, 3.6)], [(0.8, 0.6), (0.5, 0.4), (0.2, 0.2)])
        orn_crystal(D(m, 'G:prismc'), (0, 9.6, 3.6), (0, 1, 0.2), 1.6, 0.4, sides=4, double=True)
    for x in (-2.4, 0, 2.4):
        chain(D(m, 'raylt'), [(x, 0.4, 2.2), (x, 0.4, 0.0)], [(0.25, 0.25), (0.2, 0.2)])
    orbit_bits(m, 8.5, 5.4, 5, ['G:prR', 'G:prY', 'G:prG', 'G:prB', 'G:prV'], kind='crystal', size=0.8)
    return m


def q4_5():  # Nova Lion (Legendary) : lion à crinière de lumière d'étoile
    m = Poly(45)
    zb = quad(m, 'lion', 'lionlt', L=7.0, W=3.4, H=3.2, leg=3.0, legw=1.3, claw=True)
    fy = beast_head(m, 'lion', 'lionlt', 'liondk', (0, -4.6, zb + 1.6), (2.8, 2.4, 2.6), 1.4, 'G:nova', teeth=4, jaw=0.4)
    for i, d in enumerate(fib_dirs(26)):
        if d.y > 0.4:
            continue
        p = V((0, -4.0, zb + 1.6)) + V((d.x * 2.3, d.y * 1.8 + 0.6, d.z * 2.4))
        blob(B(m, 'mane'), p, (1.0, 0.9, 1.0), m.rnd, 0.15)
        if i % 3 == 0:
            spike(D(m, ('G:nova', 'G:novao')[i % 2]), p, (d + V((0, 0.8, 0))).normalized(), 1.6, 0.4)
    ears(m, 'lion', 'liondk', 1.0, -4.4, zb + 2.8, 'round', 0.7)
    with layer(m, 'Tail'):
        chain(B(m, 'lion'), [(0, 3.4, zb + 0.6), (0, 5.0, zb + 1.4), (0, 6.0, zb + 2.8)], [(0.6, 0.6), (0.5, 0.5), (0.4, 0.4)])
        orn_star(D(m, 'G:nova'), (0, 6.2, zb + 3.6), 1.1, 0.45, 0.4, normal=(0, 1, 0))
    orbit_bits(m, 6.5, zb + 3.0, 5, ['G:nova', 'G:novao'], kind='star', size=0.9)
    return m


def q4_6():  # Galaxy Unicorn (Mythic) : licorne ailée, crinière et corne de galaxie
    m = Poly(46)
    zb = quad(m, 'uni', 'gold', L=7.0, W=3.0, H=3.0, leg=4.4, legw=1.0)
    chain(B(m, 'uni'), [(0, -3.0, zb + 0.6), (0, -4.4, zb + 3.2), (0, -5.0, zb + 4.6)], [(2.4, 2.4), (1.9, 1.9), (1.7, 1.7)])
    box(B(m, 'uni'), (0, -5.4, zb + 5.2), (2.2, 2.4, 2.0), bevel=0.18)
    frustum(B(m, 'uni'), (0, -6.4, zb + 4.9), (0, -8.2, zb + 4.3), (1.8, 1.6), (1.3, 1.1))
    box(D(m, 'nose'), (0, -8.3, zb + 4.3), (0.9, 0.2, 0.4), bevel=0.2)
    eyes_fierce(m, 0.65, zb + 5.5, -6.6, w=0.7, h=0.38, iris='G:galp')
    ears(m, 'uni', 'unidk', 0.7, -5.2, zb + 6.0, 'cat', 0.6)
    spike(D(m, 'G:galc'), (0, -6.2, zb + 6.0), (0, -0.55, 1), 3.6, 0.45, sides=6)
    for i in range(7):
        t = i / 6
        flame_shape(D(m, ('G:galp', 'G:galc', 'G:galv')[i % 3]), (0, -5.0 + t * 3.6, zb + 6.2 - t * 4.6), 2.0, 0.55, back=0.9)
    for s, nm in ((-1, 'WingL'), (1, 'WingR')):
        with layer(m, nm):
            fan_wing(m, s, (s * 1.2, -1.2, zb + 1.2), 7.0, ['galv', 'uni', 'galc', 'galp'], n=8, a0=80, a1=-20)
    with layer(m, 'Tail'):
        for k in range(3):
            flame_shape(D(m, ('G:galp', 'G:galc', 'G:galv')[k]), (0.4 * (k - 1), 3.4, zb + 0.6), 3.2, 0.7, back=-0.8)
    orbit_bits(m, 8.0, zb + 5.0, 3, ['galp', 'galc', 'galv'], kind='ball', size=1.0)
    return m


# ANNEAU 5 : DÉVOREUR ------------------------------------------------------------------------

def q5_2():  # Fang Beetle (Uncommon) : scarabée vert, grosses mandibules gentilles
    m = Poly(52)
    box(B(m, 'beetle'), (0, 0.6, 2.4), (4.4, 5.0, 2.4), bevel=0.3)
    box(B(m, 'beetledk'), (0, 0.6, 3.65), (0.25, 5.0, 0.2), bevel=0.0)
    box(B(m, 'beetledk'), (0, -2.6, 2.2), (3.0, 1.8, 1.8), bevel=0.25)
    eyes_cute(m, 0.65, 2.4, -3.5, w=0.75, h=0.8)
    for s in (-1, 1):
        chain(D(m, 'white'), [(s * 0.9, -3.4, 1.6), (s * 1.0, -4.8, 1.6), (s * 0.3, -5.6, 1.9)], [(0.5, 0.5), (0.4, 0.4), (0.15, 0.15)])
        for k in range(3):
            y = -1.0 + k * 1.6
            chain(B(m, 'beetledk'), [(s * 2.0, y, 1.6), (s * 3.2, y, 1.0), (s * 3.6, y + 0.3, 0.1)], [(0.45, 0.45), (0.4, 0.4), (0.3, 0.3)])
        chain(D(m, 'beetledk'), [(s * 0.6, -3.2, 3.0), (s * 1.4, -4.0, 4.4)], [(0.18, 0.18), (0.12, 0.12)])
    for p in ((1.2, 0.4, 3.62), (-1.3, 1.6, 3.6), (1.0, 2.4, 3.55)):
        box(D(m, 'beetlelt'), p, (0.7, 0.7, 0.1), bevel=0.2)
    return m


def q5_3():  # Gloom Bat (Rare) : chauve-souris ronde violette, yeux jaunes lumineux
    m = Poly(53)
    for s in (-1, 1):
        chain(D(m, 'batlt'), [(s * 0.8, 0.2, 1.8), (s * 0.8, 0, 0.2)], [(0.4, 0.4), (0.3, 0.3)])
        claws(m, s * 0.8, -0.3, 0.15, n=3, length=0.5, radius=0.12, spread=0.25)
    box(B(m, 'bat'), (0, 0, 3.8), (3.6, 3.0, 3.8), bevel=0.3)
    box(B(m, 'batlt'), (0, -1.55, 3.4), (2.4, 0.3, 2.4), bevel=0.2)
    fy = -1.5
    for s in (-1, 1):
        box(D(m, 'eyew'), (s * 0.75, fy - 0.05, 4.9), (0.9, 0.2, 0.9), bevel=0.2)
        box(D(m, 'G:baty'), (s * 0.75, fy - 0.15, 4.85), (0.6, 0.2, 0.65), bevel=0.15)
        spike(D(m, 'tooth'), (s * 0.35, fy - 0.1, 3.9), (0, 0, -1), 0.6, 0.18)
        frustum(B(m, 'bat'), (s * 1.0, 0, 5.6), (s * 1.6, 0.2, 7.6), (1.2, 0.5), (0.2, 0.2), up=(0, -1, 0))
    box(D(m, 'nose'), (0, fy - 0.15, 4.3), (0.5, 0.2, 0.35), bevel=0.25)
    for s, nm in ((-1, 'WingL'), (1, 'WingR')):
        with layer(m, nm):
            bat_wing(m, s, (s * 1.6, 0.2, 4.8), 7.0, 'batmem', 'bat')
    return m


def q5_4():  # Void Shark (Epic) : requin noir au ventre étoilé, sur ses nageoires
    m = Poly(54)
    fish_body(m, 'shark', 10.0, 3.6, 3.4, 3.2)
    box(B(m, 'sharkb'), (0, -1.0, 1.75), (2.6, 6.4, 0.4), bevel=0.2)
    fy = -5.0
    box(D(m, 'mouth'), (0, -3.6, 2.4), (2.0, 1.6, 0.6), bevel=0.1)
    teeth_row(m, -0.8, 0.8, -4.2, 2.75, 5, 0.6, 0.16)
    teeth_row(m, -0.7, 0.7, -4.0, 2.1, 4, 0.5, 0.15, down=False)
    eyes_fierce(m, 0.95, 3.7, -3.8, w=0.65, h=0.38, iris='G:voidc', tilt=0.5)
    for i in range(4):
        box(D(m, 'G:voidc'), (1.75, -1.4 + i * 0.6, 3.4), (0.15, 0.25, 1.0), bevel=0.0)
        box(D(m, 'G:voidc'), (-1.75, -1.4 + i * 0.6, 3.4), (0.15, 0.25, 1.0), bevel=0.0)
    for p in ((0.6, 0.0, 1.5), (-0.7, 1.2, 1.5), (0.2, 2.4, 1.6), (-0.4, -1.8, 1.5)):
        orn_star(D(m, 'G:star'), p, 0.35, 0.15, 0.1, normal=(0, 0, -1))
    slab(B(m, 'shark'), [(0, -0.8, 4.6), (0, 1.6, 8.0), (0, 2.6, 4.6)], (1, 0, 0), 0.5)
    for s in (-1, 1):
        slab(B(m, 'shark'), [(s * 1.6, -1.6, 2.4), (s * 4.6, 0.4, 0.2), (s * 3.4, 1.0, 0.2), (s * 1.6, 0.6, 2.2)], (0, 0, 1), 0.45)
    with layer(m, 'Tail'):
        slab(B(m, 'shark'), [(0, 4.6, 3.2), (0, 7.4, 7.0), (0, 6.6, 3.2), (0, 7.2, 0.6)], (1, 0, 0), 0.5)
    return m


def q5_5():  # Hunger Hound (Legendary) : loup d'ombre, marques et collier turquoise lumineux
    m = Poly(55)
    zb = quad(m, 'hound', 'houndlt', L=7.6, W=3.0, H=3.0, leg=3.4, legw=1.1, claw=True, slope=0.4)
    for i, (y, z) in enumerate(((-2.0, zb + 1.8), (-0.4, zb + 1.9), (1.2, zb + 1.8), (2.8, zb + 1.6))):
        spike(D(m, 'hound'), (0, y, z - 0.4), (0, 0.6, 1), 1.6, 0.6)
    frustum(B(m, 'hound'), (0, -3.6, zb + 0.6), (0, -4.8, zb + 2.0), (2.8, 2.8), (2.4, 2.4))
    fy = beast_head(m, 'hound', 'houndlt', 'hound', (0, -5.2, zb + 2.6), (2.6, 2.4, 2.4), 2.2, 'G:teal', teeth=4, jaw=0.5)
    ears(m, 'hound', 'G:teal', 0.9, -4.8, zb + 3.6, 'cat', 0.9)
    orn_torus(D(m, 'G:teal'), (0, -3.9, zb + 1.2), 1.9, 0.3, axis=(0, -0.6, 1), seg=10, sides=4)
    for k in range(6):
        a = k / 6 * math.tau
        rot = _orient((0, -0.6, 1))
        p = V((0, -3.9, zb + 1.2)) + rot @ V((math.cos(a) * 2.2, math.sin(a) * 2.2, 0))
        spike(D(m, 'houndlt'), p, (p - V((0, -3.9, zb + 1.2))).normalized(), 0.8, 0.22)
    for s in (-1, 1):
        box(D(m, 'G:teal'), (s * 1.52, -1.0, zb + 0.6), (0.15, 2.6, 0.3), rot=(0.5, 0, 0), bevel=0.0)
        box(D(m, 'G:teal'), (s * 1.52, 1.6, zb + 0.4), (0.15, 1.8, 0.3), rot=(-0.4, 0, 0), bevel=0.0)
    with layer(m, 'Tail'):
        chain(B(m, 'hound'), [(0, 3.8, zb + 0.8), (0, 5.6, zb + 1.8), (0, 6.8, zb + 3.2)], [(1.0, 1.0), (1.2, 1.2), (0.5, 0.5)])
        flame_shape(D(m, 'G:teal'), (0, 6.8, zb + 3.2), 2.0, 0.55, back=0.5)
    return m


def q5_6():  # Abyss Serpent (Mythic) : cobra violet géant, capuchon, runes lumineuses
    m = Poly(56)
    pts = coil(5.0, 1.6, 1.2, 4.8, n=16, cy=1.6, shrink=0.35)
    sizes = [(2.8 - 0.8 * i / 16, 2.4 - 0.6 * i / 16) for i in range(17)]
    chain(B(m, 'serp'), pts, sizes)
    neck = [pts[-1], V((0, -0.2, 8.0)), V((0, -1.0, 12.0))]
    chain(B(m, 'serp'), neck, [sizes[-1], (2.2, 1.8), (2.0, 1.6)])
    box(B(m, 'serplt'), (0, -1.4, 9.6), (1.4, 0.4, 4.4), rot=(-0.2, 0, 0), bevel=0.2)
    slab(B(m, 'serp'), [(0, -0.8, 13.2), (3.6, -0.4, 11.6), (3.4, -0.2, 8.8), (0, -0.6, 8.6), (-3.4, -0.2, 8.8), (-3.6, -0.4, 11.6)], (0, 1, 0), 0.6)
    for p in ((1.8, -1.15, 11.2), (-1.8, -1.15, 11.2), (2.2, -1.15, 9.6), (-2.2, -1.15, 9.6)):
        orn_star(D(m, 'G:rune'), p, 0.5, 0.2, 0.12, normal=(0, -1, 0))
    fy = beast_head(m, 'serp', 'serp', 'serp', (0, -1.6, 13.6), (2.4, 2.4, 1.8), 1.6, 'G:rune', teeth=0, jaw=0.4, nose=None)
    for s in (-1, 1):
        spike(D(m, 'tooth'), (s * 0.45, fy - 1.3, 13.2), (0, -0.2, -1), 1.2, 0.2)
        spike(D(m, 'serp'), (s * 0.9, -0.8, 14.6), (s * 0.3, 0.6, 1), 1.4, 0.4)
    chain(D(m, 'mouth'), [(0, fy - 1.6, 13.0), (0, fy - 2.6, 12.8), (0.3, fy - 3.0, 12.4)], [(0.18, 0.08), (0.12, 0.06), (0.06, 0.04)])
    for p in pts[::2]:
        box(D(m, 'G:rune'), p + V((0, 0, 1.25)), (0.6, 0.6, 0.15), rot=(0, 0, 0.785), bevel=0.0)
    orbit_bits(m, 8.5, 9.0, 5, ['G:rune', 'serp'], kind='crystal', size=0.9)
    return m


def q5_7():  # Eclipse Devourer (Cosmic) : kaïju debout, cœur cosmique, halo d'éclipse
    m = Poly(57)
    biped_legs(m, 'eclip', 'eclipdk', 2.2, 1.0, 5.6, 1.6, claw=True)
    frustum(B(m, 'eclip'), (0, 1.0, 5.0), (0, 0.0, 11.4), (5.0, 4.0), (6.4, 4.6))
    box(D(m, 'G:cosmo'), (0, -2.3, 8.6), (3.0, 0.4, 3.6), rot=(0.1, 0, 0), bevel=0.25)
    for k in range(3):
        box(D(m, 'eclipl'), (0, -2.45, 7.2 + k * 1.2), (3.6 - k * 0.4, 0.3, 0.35), bevel=0.1)
    for s in (-1, 1):
        chain(B(m, 'eclip'), [(s * 3.4, -0.2, 10.6), (s * 4.4, -1.0, 8.0), (s * 4.2, -2.2, 6.0)], [(1.9, 1.9), (1.6, 1.6), (1.4, 1.4)])
        claws(m, s * 4.2, -3.0, 5.6, n=3, length=0.9, radius=0.25, key='eclipl', spread=0.45)
        for k in range(3):
            spike(D(m, 'eclipl'), (s * (2.4 + k * 0.4), 0.8, 11.0 - k * 1.8), (s * 0.4, 0.8, 0.6), 1.6 - k * 0.3, 0.5)
    fy = beast_head(m, 'eclip', 'eclip', 'eclipdk', (0, -1.2, 13.0), (3.0, 2.8, 2.4), 2.0, 'G:cosmo', teeth=5, jaw=0.7)
    box(D(m, 'G:cosmo'), (0, fy - 1.0, 12.1), (1.4, 1.6, 0.5), bevel=0.1)
    for s in (-1, 1):
        orn_sweep(D(m, 'eclipl'), [(s * 1.0, -0.8, 14.0), (s * 1.8, 0.4, 15.4), (s * 2.0, 1.8, 16.0)], [0.45, 0.3, 0.04], sides=5)
    spikes_line(m, 'eclipl', [V((0, y, z)) for y, z in ((0.6, 14.0), (1.4, 12.2), (2.2, 10.2), (2.6, 8.2), (2.6, 6.2))], 1.8, 0.6, lean=0.7)
    orn_torus(D(m, 'G:eclipg'), (0, 2.0, 13.4), 4.4, 0.4, axis=(0, 1, 0.1), seg=28, sides=6)
    with layer(m, 'Tail'):
        chain(B(m, 'eclip'), [(0, 2.6, 5.4), (0, 5.6, 3.4), (0, 8.4, 2.2), (0, 10.6, 2.0)], [(2.6, 2.4), (1.8, 1.6), (1.0, 1.0), (0.4, 0.4)])
        spikes_line(m, 'eclipl', [V((0, 4.4, 5.0)), V((0, 7.0, 3.4)), V((0, 9.4, 2.6))], 1.2, 0.4, lean=0.8)
    orbit_bits(m, 9.5, 11.0, 6, ['G:cosmo', 'G:eclipg', 'eclip'], kind='crystal', size=1.1)
    return m


# ANNEAU 6 : FAILLE -------------------------------------------------------------------------

def q6_2():  # Chrono Snail (Uncommon) : escargot à coquille-horloge
    m = Poly(62)
    chain(B(m, 'snail'), [(0, 3.4, 0.5), (0, 0.0, 0.8), (0, -2.4, 1.0)], [(1.4, 0.6), (2.4, 1.4), (2.4, 1.6)])
    box(B(m, 'snail'), (0, -3.0, 2.6), (2.4, 2.0, 2.6), bevel=0.25)
    eyes_cute(m, 0.55, 2.8, -4.0, w=0.65, h=0.8)
    for s in (-1, 1):
        chain(B(m, 'snaillt'), [(s * 0.6, -3.2, 3.8), (s * 0.9, -3.4, 5.2)], [(0.35, 0.35), (0.25, 0.25)])
        blob(D(m, 'snaillt'), (s * 0.9, -3.4, 5.35), (0.3, 0.3, 0.3), None)
    box(B(m, 'shellc'), (0, 0.8, 3.6), (2.6, 4.4, 4.4), bevel=0.3)
    for s in (-1, 1):
        c = V((s * 1.35, 0.8, 3.6))
        box(D(m, 'clockw'), c, (0.2, 3.4, 3.4), rot=(0.785, 0, 0), bevel=0.15)
        for k in range(4):
            a = k / 4 * math.tau
            box(D(m, 'clockd'), c + V((s * 0.12, math.cos(a) * 1.3, math.sin(a) * 1.3)), (0.1, 0.3, 0.3), bevel=0.0)
        box(D(m, 'clockd'), c + V((s * 0.15, -0.4, 0.3)), (0.1, 0.9, 0.2), rot=(0.6, 0, 0), bevel=0.0)
        box(D(m, 'G:time'), c + V((s * 0.17, 0.0, 0.6)), (0.1, 0.18, 1.3), bevel=0.0)
    return m


def q6_3():  # Glitch Cat (Rare) : chat aux rayures glitch cyan et magenta
    m = Poly(63)
    zb = quad(m, 'cat', 'catlt', L=4.6, W=3.0, H=2.6, leg=1.8, legw=1.0)
    fy = cute_head(m, 'cat', (0, -2.6, zb + 2.6), (3.6, 3.0, 3.0), muzzle='catlt', nose='glm')
    ears(m, 'cat', 'glm', 1.1, -2.6, zb + 4.0, 'cat', 0.9)
    for z in (zb - 0.6, zb + 0.2, zb + 1.0):
        for s in (-1, 1):
            box(D(m, 'G:glc' if z != zb + 0.2 else 'G:glm'), (s * 1.52, m.rnd.uniform(-1, 1), z), (0.12, m.rnd.uniform(1.0, 2.4), 0.3), bevel=0.0)
    with layer(m, 'Tail'):
        chain(B(m, 'cat'), [(0, 2.4, zb + 0.4), (0, 3.6, zb + 1.6), (0, 3.4, zb + 3.4)], [(0.7, 0.7), (0.6, 0.6), (0.5, 0.5)])
    orbit_bits(m, 5.0, zb + 3.0, 6, ['G:glc', 'G:glm'], kind='cube', size=0.6)
    return m


def q6_4():  # Paradox Panda (Epic) : panda aux taches inversées, anneaux du temps
    m = Poly(64)
    zb = quad(m, 'pandaw', 'pandab', L=6.0, W=5.0, H=4.2, leg=2.0, legw=1.7, claw=True)
    box(B(m, 'pandab'), (0, -0.4, zb + 0.4), (5.2, 2.4, 4.4), bevel=0.25)
    fy = beast_head(m, 'pandab', 'pandaw', 'pandab', (0, -3.8, zb + 2.2), (3.6, 3.0, 3.0), 1.0, 'G:time', teeth=2, jaw=0.25)
    for s in (-1, 1):
        box(D(m, 'pandaw'), (s * 0.95, fy - 0.05, zb + 2.6), (1.3, 0.15, 1.0), rot=(0, s * 0.4, 0), bevel=0.2)
    ears(m, 'pandaw', 'pandab', 1.4, -3.6, zb + 3.6, 'round', 0.9)
    with layer(m, 'Orbit'):
        for i in range(3):
            orn_torus(D(m, 'G:time'), (0, 0, zb + 2.0), 6.0 - i * 0.6, 0.16, tilt=0.3 + i * 0.3, arc=(i / 3, i / 3 + 0.55), seg=28, sides=4)
        for k in range(4):
            a = k / 4 * math.tau
            c = V((math.cos(a) * 6.2, math.sin(a) * 6.2, zb + 2.0))
            box(D(m, 'clockw'), c, (1.4, 0.3, 1.4), rot=(0, 0, a), bevel=0.2)
            box(D(m, 'clockd'), c + V((0, 0, 0.3)), (0.12, 0.35, 0.6), rot=(0, 0, a), bevel=0.0)
    return m


def q6_5():  # Hourglass Tortoise (Legendary) : tortue portant un sablier doré
    m = Poly(65)
    zb = quad(m, 'tort', 'tortdk', L=6.0, W=4.6, H=1.6, leg=1.4, legw=1.5, claw=True)
    frustum(B(m, 'tortsh'), (0, 0, zb - 0.4), (0, 0, zb + 1.8), (6.4, 7.6), (4.4, 5.4), up=(0, -1, 0))
    for (x, y) in ((0, 0), (1.6, -1.6), (-1.6, -1.6), (1.6, 1.6), (-1.6, 1.6)):
        box(D(m, 'tortdk'), (x, y, zb + 1.85), (1.4, 1.4, 0.2), rot=(0, 0, 0.785), bevel=0.2)
    chain(B(m, 'tort'), [(0, -3.4, zb), (0, -4.6, zb + 0.6)], [(1.6, 1.6), (1.4, 1.4)])
    fy = beast_head(m, 'tort', 'tort', 'tortdk', (0, -5.2, zb + 1.0), (2.2, 2.0, 1.8), 0.8, 'G:sand', teeth=0, jaw=0.15, nose=None)
    c = V((0, 0, zb + 2.0))
    for z in (0.2, 6.2):
        box(D(m, 'gold'), c + V((0, 0, z)), (3.6, 3.6, 0.5), rot=(0, 0, 0.785), bevel=0.2)
    for k in range(4):
        a = k / 4 * math.tau
        chain(D(m, 'golddk'), [c + V((math.cos(a) * 1.6, math.sin(a) * 1.6, 0.2)), c + V((math.cos(a) * 1.6, math.sin(a) * 1.6, 6.2))], [(0.35, 0.35), (0.35, 0.35)])
    frustum(D(m, 'glass'), c + V((0, 0, 0.5)), c + V((0, 0, 3.2)), (2.4, 2.4), (0.4, 0.4), up=(0, -1, 0))
    frustum(D(m, 'glass'), c + V((0, 0, 5.9)), c + V((0, 0, 3.2)), (2.4, 2.4), (0.4, 0.4), up=(0, -1, 0))
    frustum(D(m, 'G:sand'), c + V((0, 0, 0.55)), c + V((0, 0, 1.6)), (2.0, 2.0), (1.1, 1.1), up=(0, -1, 0))
    frustum(D(m, 'G:sand'), c + V((0, 0, 4.4)), c + V((0, 0, 3.3)), (1.4, 1.4), (0.3, 0.3), up=(0, -1, 0))
    orn_gem(D(m, 'time'), c + V((0, 0, 7.0)), 0.8, direction=(0, 0, 1), sides=6)
    with layer(m, 'Tail'):
        chain(B(m, 'tort'), [(0, 3.2, zb - 0.2), (0, 4.2, zb - 0.8)], [(0.7, 0.7), (0.3, 0.3)])
    orbit_bits(m, 6.5, zb + 5.0, 4, ['G:sand', 'G:time'], kind='star', size=0.8)
    return m


def q6_6():  # Rift Griffin (Mythic) : griffon (aigle + lion), ailes de failles lumineuses
    m = Poly(66)
    zb = quad(m, 'grif', 'golddk', L=7.0, W=3.2, H=3.2, leg=3.2, legw=1.2, claw=True)
    frustum(B(m, 'grifw'), (0, -2.8, zb + 0.4), (0, -4.0, zb + 2.6), (3.0, 3.0), (2.4, 2.4))
    box(B(m, 'grifw'), (0, -4.4, zb + 3.6), (2.4, 2.6, 2.2), bevel=0.18)
    frustum(D(m, 'gold'), (0, -5.6, zb + 3.6), (0, -7.2, zb + 2.6), (1.2, 1.2), (0.15, 0.15))
    eyes_fierce(m, 0.65, zb + 4.0, -5.7, w=0.7, h=0.38, iris='G:riftc')
    for i in range(4):
        frustum(B(m, 'grifw'), (0, -3.6 + i * 0.6, zb + 4.6 - i * 0.4), (0, -2.4 + i * 0.6, zb + 5.8 - i * 0.4), (1.0, 0.3), (0.2, 0.15))
    for s, nm in ((-1, 'WingL'), (1, 'WingR')):
        with layer(m, nm):
            fan_wing(m, s, (s * 1.3, -1.6, zb + 1.4), 8.5, ['grif', 'griflt', 'G:rift', 'grif', 'G:riftc'], n=9, a0=85, a1=-20)
            for i in range(3):
                box(D(m, 'G:rift'), (s * (3.5 + i * 1.6), -0.8, zb + 5.5 - i * 0.6), (0.2, 0.2, 1.6), rot=(0, s * 0.5, 0), bevel=0.0)
    with layer(m, 'Tail'):
        chain(B(m, 'grif'), [(0, 3.6, zb + 0.6), (0, 5.4, zb + 0.2), (0, 6.6, zb + 1.2)], [(0.6, 0.6), (0.5, 0.5), (0.4, 0.4)])
        flame_shape(D(m, 'G:rift'), (0, 6.8, zb + 1.4), 2.0, 0.6, back=0.6)
    orbit_bits(m, 9.0, zb + 5.0, 5, ['G:rift', 'G:riftc'], kind='crystal', size=1.0)
    return m


def q6_7():  # Quasar Kraken (Cosmic) : poulpe géant, tête qui brille comme un quasar
    m = Poly(67)
    frustum(B(m, 'krak'), (0, 0, 3.6), (0, 0.8, 11.6), (5.6, 5.4), (3.0, 3.0), up=(0, -1, 0))
    box(B(m, 'krak'), (0, 0, 4.6), (6.0, 5.6, 3.4), bevel=0.25)
    eyes_fierce(m, 1.6, 5.2, -2.8, w=1.2, h=0.7, iris='G:quasarc', tilt=0.5)
    for i in range(4):
        box(D(m, 'kraklt'), (0, -1.0 + i * 0.4, 7.4 + i * 1.0), (0.6, 0.6, 0.6), rot=(0.785, 0.785, 0), bevel=0.0)
    blob(D(m, 'G:quasar'), (0, 0.9, 12.2), (1.5, 1.5, 1.5), None)
    orn_torus(D(m, 'G:quasarc'), (0, 0.9, 12.2), 2.6, 0.18, tilt=0.2, seg=24, sides=4)
    spike(D(m, 'G:quasarc'), (0, 0.9, 13.4), (0, 0, 1), 4.0, 0.5, sides=6)
    for k in range(8):
        a = k / 8 * math.tau + 0.2
        o = V((math.cos(a), math.sin(a), 0))
        b = V((0, 0, 3.2)) + o * 2.4
        pts = [b, b + o * 2.4 + V((0, 0, -2.4)), b + o * 5.0 + V((0, 0, -2.8)), b + o * 6.8 + V((0, 0, -1.0)), b + o * 6.6 + V((0, 0, 1.0))]
        sz = [(1.6, 1.4), (1.3, 1.1), (1.0, 0.8), (0.6, 0.5), (0.3, 0.3)]
        if k % 2:
            with layer(m, 'Tail'):
                chain(B(m, 'krak'), pts, sz)
        else:
            chain(B(m, 'krak'), pts, sz)
        for t in (0.3, 0.55, 0.78):
            i = int(t * 4)
            p = pts[i].lerp(pts[i + 1], t * 4 - i)
            blob(D(m, 'kraklt'), p + V((0, 0, -0.55)), (0.4, 0.4, 0.2), None)
    orbit_bits(m, 11.0, 8.0, 4, ['G:quasarc', 'G:quasar'], kind='ball', size=1.0)
    return m


# ANNEAU 7 : NID ---------------------------------------------------------------------------------

def q7_2():  # Hatchling (Uncommon) : poussin dans la moitié de sa coquille cosmique
    m = Poly(72)
    frustum(B(m, 'shell7'), (0, 0, 0.3), (0, 0, 3.4), (3.6, 3.6), (5.0, 5.0), up=(0, -1, 0))
    for k in range(6):
        a = k / 6 * math.tau
        spike(D(m, 'shell7lt'), (math.cos(a) * 2.2, math.sin(a) * 2.2, 3.3), (math.cos(a) * 0.3, math.sin(a) * 0.3, 1), 1.0, 0.6)
    for p in ((1.6, -2.4, 2.2), (-1.2, -2.4, 1.4), (2.3, 0.6, 2.0)):
        orn_star(D(m, 'G:star'), p, 0.35, 0.15, 0.1, normal=(p[0] * 0.3, -1, 0))
    box(B(m, 'chick'), (0, 0, 4.6), (3.2, 3.0, 3.0), bevel=0.22)
    eyes_cute(m, 0.65, 5.1, -1.5, w=0.7, h=0.85)
    frustum(D(m, 'beak'), (0, -1.5, 4.5), (0, -2.4, 4.4), (0.8, 0.6), (0.15, 0.12))
    for s in (-1, 1):
        box(B(m, 'chicklt'), (s * 1.75, 0.2, 4.4), (0.4, 1.4, 1.6), rot=(0, s * 0.3, 0), bevel=0.2)
    frustum(B(m, 'chicklt'), (0, 0, 6.0), (0.3, 0.3, 7.0), (0.6, 0.3), (0.15, 0.15))
    return m


def q7_3():  # Yolk Slime (Rare) : slime de jaune d'œuf doré, visage joyeux
    m = Poly(73)
    box(B(m, 'albumen'), (0, 0, 0.3), (6.4, 6.4, 0.6), rot=(0, 0, 0.3), bevel=0.4)
    frustum(B(m, 'yolk'), (0, 0, 0.5), (0, 0, 5.2), (4.8, 4.8), (3.0, 3.0), up=(0, -1, 0))
    box(B(m, 'yolk'), (0, 0, 5.4), (3.2, 3.2, 0.8), bevel=0.35)
    eyes_cute(m, 0.75, 3.6, -2.15, w=0.8, h=0.9)
    box(D(m, 'mouth'), (0, -2.35, 2.2), (1.2, 0.2, 0.4), bevel=0.2)
    box(D(m, 'pink'), (0, -2.38, 2.05), (0.6, 0.15, 0.2), bevel=0.2)
    box(D(m, 'yolklt'), (-0.9, -1.2, 5.2), (0.8, 0.8, 0.3), bevel=0.3)
    for x, L in ((0, 1.6), (1.0, 1.1), (-1.0, 1.1)):
        orn_crystal(D(m, 'gold'), (x, 0, 5.7), (x * 0.25, 0, 1), L, 0.4, sides=4)
    return m


def q7_4():  # Brood Raptor (Epic) : raptor façon T-rex, armure de coquille ambrée
    m = Poly(74)
    biped_legs(m, 'raptor', 'raptor', 1.6, 1.0, 5.0, 1.1, claw=True)
    frustum(B(m, 'raptor'), (0, 3.4, 5.6), (0, -2.4, 6.6), (3.0, 3.0), (3.4, 3.6))
    box(B(m, 'raptorlt'), (0, -1.0, 5.0), (2.4, 3.6, 0.6), bevel=0.2)
    frustum(B(m, 'raptor'), (0, -2.4, 7.2), (0, -3.6, 9.0), (2.8, 2.8), (2.4, 2.4))
    fy = beast_head(m, 'raptor', 'raptor', 'raptorlt', (0, -4.0, 9.8), (2.6, 2.6, 2.2), 2.2, 'G:amber', teeth=5, jaw=0.7)
    for s in (-1, 1):
        chain(B(m, 'raptor'), [(s * 1.5, -2.6, 6.6), (s * 1.7, -3.6, 5.4)], [(0.55, 0.55), (0.4, 0.4)])
        claws(m, s * 1.7, -3.9, 5.2, n=2, length=0.5, radius=0.14, spread=0.25)
    for i, (y, z) in enumerate(((-1.8, 8.4), (0.0, 8.4), (1.8, 8.0), (3.2, 7.4))):
        box(D(m, 'amber' if i % 2 else 'amberdk'), (0, y, z), (3.0, 1.6, 0.6), rot=(0.2, 0, 0), bevel=0.3)
        spike(D(m, 'amberdk'), (0, y, z + 0.3), (0, 0.4, 1), 1.4, 0.45)
    with layer(m, 'Tail'):
        chain(B(m, 'raptor'), [(0, 3.4, 6.2), (0, 6.4, 6.2), (0, 9.0, 6.8), (0, 10.8, 7.4)], [(2.4, 2.4), (1.6, 1.6), (0.9, 0.9), (0.3, 0.3)])
    return m


def q7_5():  # Nest Drake (Legendary) : drake qui porte un nid d'œufs lumineux sur le dos
    m = Poly(75)
    zb = quad(m, 'drake', 'drakelt', L=7.6, W=3.6, H=3.4, leg=2.8, legw=1.4, claw=True, slope=0.3)
    frustum(B(m, 'drake'), (0, -3.6, zb + 0.6), (0, -5.0, zb + 2.6), (3.0, 3.0), (2.4, 2.4))
    fy = beast_head(m, 'drake', 'drakelt', 'drake', (0, -5.6, zb + 3.2), (2.6, 2.4, 2.2), 2.0, 'G:eggg', teeth=4, jaw=0.5)
    for s in (-1, 1):
        orn_sweep(D(m, 'gold'), [(s * 0.8, -5.2, zb + 4.2), (s * 1.4, -3.8, zb + 5.4), (s * 1.6, -2.4, zb + 5.6)], [0.4, 0.28, 0.04], sides=5)
    c = V((0, 0.6, zb + 1.8))
    for k in range(16):
        a = k / 16 * math.tau
        p0 = c + V((math.cos(a) * 2.6, math.sin(a) * 2.6, (k % 3) * 0.3))
        p1 = c + V((math.cos(a + 0.7) * 2.8, math.sin(a + 0.7) * 2.8, 0.4))
        chain(D(m, 'twig'), [p0, p1], [(0.3, 0.3), (0.25, 0.25)])
    for (dx, dy) in ((0, 0), (1.1, 1.0), (-1.1, 0.8), (0.2, -1.2)):
        blob(D(m, 'G:eggg'), c + V((dx, dy, 1.1)), (0.75, 0.75, 1.0), None)
    for s, nm in ((-1, 'WingL'), (1, 'WingR')):
        with layer(m, nm):
            bat_wing(m, s, (s * 1.6, -1.6, zb + 1.4), 8.0, 'drakemem', 'drake')
    with layer(m, 'Tail'):
        chain(B(m, 'drake'), [(0, 3.8, zb + 0.4), (0, 6.2, zb - 0.6), (0, 8.4, zb - 0.4)], [(1.6, 1.6), (1.0, 1.0), (0.4, 0.4)])
        spikes_line(m, 'gold', [V((0, 5.0, zb + 0.3)), V((0, 7.2, zb - 0.2))], 1.0, 0.35)
    return m


def q7_6():  # Hive Queen (Mythic) : reine abeille-mante debout, couronne de cristal
    m = Poly(76)
    for s in (-1, 1):
        for k in range(2):
            y = -0.4 + k * 1.6
            chain(B(m, 'beeb'), [(s * 1.0, y, 4.6), (s * 2.4, y, 2.6), (s * 2.6, y - 0.4, 0.2)], [(0.5, 0.5), (0.4, 0.4), (0.25, 0.25)])
    frustum(B(m, 'bee'), (0, 1.0, 4.2), (0, 4.2, 3.0), (3.0, 3.0), (1.2, 1.2))
    for k in range(3):
        box(B(m, 'beeb'), (0, 1.6 + k * 0.9, 3.9 - k * 0.35), (2.8 - k * 0.5, 0.4, 2.6 - k * 0.5), bevel=0.15)
    frustum(B(m, 'mantis'), (0, 0.4, 4.4), (0, -0.6, 9.8), (2.2, 2.0), (2.8, 2.4))
    box(B(m, 'mantisdk'), (0, -1.6, 8.0), (1.8, 0.4, 2.6), bevel=0.2)
    box(B(m, 'mantis'), (0, -1.0, 11.0), (2.4, 2.2, 1.8), bevel=0.2)
    frustum(B(m, 'mantis'), (0, -1.8, 10.6), (0, -2.8, 10.0), (1.6, 1.2), (0.6, 0.5))
    for s in (-1, 1):
        box(D(m, 'eyew'), (s * 0.8, -2.0, 11.4), (0.8, 0.3, 0.6), rot=(0, s * 0.4, 0), bevel=0.25)
        box(D(m, 'G:hivec'), (s * 0.8, -2.15, 11.4), (0.6, 0.2, 0.42), rot=(0, s * 0.4, 0), bevel=0.2)
        chain(D(m, 'mantisdk'), [(s * 0.5, -1.6, 12.0), (s * 1.6, -3.0, 14.0), (s * 2.6, -2.6, 15.2)], [(0.2, 0.2), (0.14, 0.14), (0.1, 0.1)])
        chain(B(m, 'mantis'), [(s * 1.4, -0.8, 9.4), (s * 2.6, -2.4, 9.8), (s * 2.4, -3.2, 7.8)], [(0.8, 0.8), (0.7, 0.7), (0.5, 0.5)])
        slab(B(m, 'mantis'), [(s * 2.4, -3.2, 7.6), (s * 3.2, -3.6, 10.4), (s * 2.6, -3.0, 7.0)], (1, 0, 0), 0.3)
    for k in range(5):
        a = (k - 2) * 0.45
        orn_crystal(D(m, 'G:hivec' if k % 2 == 0 else 'gold'), (math.sin(a) * 0.9, -0.8, 11.9), (math.sin(a) * 0.4, 0, 1), 2.0 if k % 2 == 0 else 1.3, 0.35, sides=5)
    for s, nm in ((-1, 'WingL'), (1, 'WingR')):
        with layer(m, nm):
            slab(B(m, 'beewing'), [(s * 1.0, 1.2, 9.0), (s * 6.4, 2.4, 12.8), (s * 7.4, 2.6, 10.6), (s * 3.0, 1.8, 7.6)], (0, 1, 0), 0.25)
            slab(B(m, 'beewing'), [(s * 1.0, 1.4, 8.0), (s * 5.4, 2.6, 7.0), (s * 4.6, 2.4, 5.6), (s * 1.6, 1.6, 6.8)], (0, 1, 0), 0.25)
            box(D(m, 'G:hivec'), (s * 4.0, 1.9, 10.4), (4.0, 0.1, 0.18), rot=(0, s * 0.55, 0), bevel=0.0)
    orbit_bits(m, 8.0, 9.0, 6, ['G:eggg', 'G:hivec'], kind='ball', size=0.7)
    return m


def q7_7():  # Cosmic Mother (Cosmic) : mère cosmique de tous les œufs, dragonne ailée de galaxies
    m = Poly(77)
    zb = quad(m, 'cosm', 'gold', L=8.4, W=4.0, H=4.0, leg=3.6, legw=1.5, claw=True, slope=0.4)
    chain(B(m, 'cosm'), [(0, -3.6, zb + 0.8), (0, -5.0, zb + 3.6), (0, -5.6, zb + 6.0)], [(3.2, 3.2), (2.6, 2.6), (2.2, 2.2)])
    for i in range(4):
        box(D(m, 'gold'), (0, -4.0 - i * 0.5, zb + 1.2 + i * 1.3), (1.8, 0.5, 1.0), rot=(0.5, 0, 0), bevel=0.2)
    fy = beast_head(m, 'cosm', 'cosm', 'cosmv', (0, -6.2, zb + 7.0), (2.8, 2.6, 2.4), 2.2, 'G:cosmc', teeth=4, jaw=0.5)
    for s in (-1, 1):
        orn_sweep(D(m, 'gold'), [(s * 0.9, -5.8, zb + 8.0), (s * 1.8, -4.4, zb + 9.6), (s * 2.2, -2.6, zb + 10.2), (s * 2.0, -1.4, zb + 9.6)], [0.5, 0.36, 0.2, 0.04], sides=5)
    orn_torus(D(m, 'G:cosmw'), (0, -5.0, zb + 10.2), 2.4, 0.22, tilt=0.4, seg=24, sides=4)
    for (y, z) in ((-2.4, zb + 2.4), (-0.4, zb + 2.6), (1.6, zb + 2.5), (3.4, zb + 2.2)):
        spike(D(m, 'G:cosmp'), (0, y, z), (0, 0.4, 1), 1.8, 0.55)
    for k in range(14):
        p = V((m.rnd.choice((-1, 1)) * 2.02, m.rnd.uniform(-3.6, 3.6), m.rnd.uniform(zb - 1.4, zb + 1.6)))
        orn_star(D(m, ('G:cosmw', 'G:cosmc', 'G:cosmp')[k % 3]), p, 0.3, 0.13, 0.08, normal=(math.copysign(1, p.x), 0, 0))
    for s, nm in ((-1, 'WingL'), (1, 'WingR')):
        with layer(m, nm):
            fan_wing(m, s, (s * 1.6, -1.6, zb + 1.8), 10.0, ['cosmv', 'G:cosmp', 'cosmc', 'cosm', 'G:cosmc'], n=10, a0=88, a1=-25)
    with layer(m, 'Tail'):
        chain(B(m, 'cosm'), [(0, 4.2, zb + 0.6), (0, 7.4, zb - 0.4), (0, 10.2, zb + 0.4)], [(2.2, 2.2), (1.4, 1.4), (0.5, 0.5)])
        for k in range(3):
            flame_shape(D(m, ('G:cosmp', 'G:cosmc', 'G:cosmv')[k]), (0.5 * (k - 1), 10.2, zb + 0.6), 2.4, 0.6, back=0.8)
    with layer(m, 'Orbit'):
        for k in range(6):
            a = k / 6 * math.tau
            p = V((math.cos(a) * 11.0, math.sin(a) * 11.0, zb + 6.0 + (k % 2) * 1.5))
            if k % 2:
                blob(D(m, 'G:eggg'), p, (0.8, 0.8, 1.05), None)
            else:
                blob(D(m, ('cosmp', 'cosmc', 'cosmv')[k // 2]), p, (1.1, 1.1, 1.1), None)
                orn_torus(D(m, 'gold'), p, 1.8, 0.14, tilt=0.45, seg=16, sides=4)
    return m


POLY.update({
    2: (q2_1, q2_2, q2_3, q2_4, q2_5, q2_6),
    3: (q3_1, q3_2, q3_3, q3_4, q3_5, q3_6),
    4: (q4_1, q4_2, q4_3, q4_4, q4_5, q4_6),
    5: (q5_2, q5_3, q5_4, q5_5, q5_6, q5_7),
    6: (q6_2, q6_3, q6_4, q6_5, q6_6, q6_7),
    7: (q7_2, q7_3, q7_4, q7_5, q7_6, q7_7),
})
print("créatures low-poly des anneaux 2 à 7 chargées")
