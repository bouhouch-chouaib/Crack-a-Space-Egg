# Créatures en briques (style des œufs : corps en gros cubes + picots dans Studio, ornements modélisés).
# Charger voxkit.py d'abord, puis ce fichier, puis : build_creatures(1)
# Progression : Common / Uncommon = chibi mignon (grosse tête) ; plus la rareté monte, plus la créature
# est grande, costaude et impressionnante (tête plus petite, yeux menaçants, armure, piques, feu, ailes).
# Avant vers -y, pattes au sol (z = 0).
# Groupes animés (Creatures.client) : Tail (balance), WingL / WingR (battent), Orbit (tourne).
# Nom des modèles : Creature_R<anneau>_T<rareté> (même rareté que l'œuf d'où elle sort).

import math, os
from mathutils import Vector


# AIDES ------------------------------------------------------------------------------------

def front_y(m, x, z):
    """Surface avant (y le plus petit) du modèle à la colonne (x, z)."""
    xs, zs = int(round(x)), int(round(z))
    ys = [c[1] for c in m.cells if c[0] == xs and c[2] == zs]
    return (min(ys) - 0.5) if ys else 0.0


def eyes(m, x, z, r=1.35, key='eye', shine='shine', inset=0.15):
    for s in (-1, 1):
        y = front_y(m, s * x, z) + inset
        c = Vector((s * x, y, z))
        orn_ball(B(m, key, True), c, r, scale=(1, 0.62, 1.15))
        orn_ball(B(m, shine, True), c + Vector((s * 0.3 * r, -0.6 * r, 0.45 * r)), 0.36 * r)
        orn_ball(B(m, shine, True), c + Vector((-s * 0.25 * r, -0.62 * r, -0.35 * r)), 0.16 * r)


def fierce_eyes(m, x, z, r, iris, brow='browdk', inset=0.15):
    """Yeux des créatures rares : iris lumineux, sourcils froncés (l'intérieur plus bas)."""
    for s in (-1, 1):
        y = front_y(m, s * x, z) + inset
        c = Vector((s * x, y, z))
        orn_ball(B(m, 'eye', True), c, r, scale=(1.2, 0.6, 0.8))
        orn_ball(B(m, 'G:' + iris, True), c + Vector((0, -0.42 * r, 0)), 0.55 * r, scale=(1, 0.5, 1))
        orn_ball(B(m, 'eye', True), c + Vector((0, -0.62 * r, 0)), 0.2 * r, scale=(0.7, 0.6, 1.3))
        orn_ball(B(m, 'shine', True), c + Vector((s * 0.3 * r, -0.66 * r, 0.3 * r)), 0.14 * r)
        inner = c + Vector((-s * 0.9 * r, -0.55 * r, 0.55 * r))
        outer = c + Vector((s * 1.05 * r, -0.35 * r, 1.25 * r))
        orn_sweep(B(m, brow, True), [inner, inner.lerp(outer, 0.5) + Vector((0, -0.1, 0.15)), outer], [0.42 * r, 0.36 * r, 0.12 * r], sides=6, flat=0.6, twist_up=Vector((0, -1, 0)))


def cheeks(m, x, z, r=0.9, key='blush'):
    for s in (-1, 1):
        y = front_y(m, s * x, z) + 0.2
        orn_ball(B(m, key, True), (s * x, y, z), r, scale=(1, 0.35, 0.62))


def nose(m, x, z, r=0.8, key='nose'):
    y = front_y(m, x, z) + 0.1
    orn_ball(B(m, key, True), (x, y, z), r, scale=(1.2, 0.8, 0.8))


def glow_specks(m, key, n, test=None):
    surf = [c for c in m.surface() if not test or test(*c)]
    for c in m.rnd.sample(sorted(surf), min(n, len(surf))):
        m.cells[c] = key


def fib_dirs(n):
    g = math.pi * (3 - math.sqrt(5))
    out = []
    for i in range(n):
        z = 1 - (i + 0.5) / n * 2
        r = math.sqrt(1 - z * z)
        out.append(Vector((math.cos(i * g) * r, math.sin(i * g) * r, z)))
    return out


# PALETTE DE L'ANNEAU 1 --------------------------------------------------------------------

PALC = {
    # communs à toutes les créatures
    'eye': '#1a1424', 'shine': '#ffffff', 'blush': '#ff8aa8', 'nose': '#2a2030', 'mouth': '#4a1e34', 'white': '#fff8f0', 'browdk': '#1e1420',
    # Pebblepup
    'rock1': '#9aa3ad', 'rock1lt': '#c9cfd8', 'rock1dk': '#6b737e', 'pebble': '#8a7262', 'collar': '#e8402e', 'tag': '#ffc21a',
    # Dust Bunny
    'beige': '#e8cfa0', 'cream': '#fff1d6', 'earpink': '#ffb0c4', 'star': '#fff27a',
    # Craterhog
    'hog': '#8a5a3a', 'hogdk': '#5e3a24', 'hogtan': '#efc896', 'ame': '#a85cff', 'amelt': '#e0a8ff', 'amedk': '#6a2ad0',
    # Orbitoad
    'toad': '#3a8cff', 'toadlt': '#a8dcff', 'toaddk': '#1f5cc8', 'moon': '#ece6d6', 'moondk': '#b8b0a0', 'ringg': '#7ae8ff',
    # Meteor Fox
    'fox': '#ff7a1a', 'foxdk': '#4a2414', 'foxw': '#fff4e6', 'meteor': '#6a4a3a', 'flame': '#ff5a0a', 'flamey': '#ffd23a', 'gold': '#ffc21a', 'ruby': '#ff2456',
    # Stardust Dragon
    'drag': '#ff4fae', 'draglt': '#ffa6d6', 'dragdk': '#a8287a', 'golddk': '#e08a10', 'membr': '#ffd6f0', 'starg': '#fff6a0', 'gemp': '#ff3aa0',
}


# ANNEAU 1 --------------------------------------------------------------------------------

def c1_1():  # Pebblepup (Common) : chiot de roche grise à taches de cailloux
    m = Vox(16, seed=11)
    m.ell((0, 3, 6), (5, 6.5, 4.6), 'rock1')
    m.ell((0, -4.5, 11), (6, 5.4, 5.4), 'rock1')
    m.ell((0, -9.4, 9.2), (3, 2.2, 2.3), 'rock1lt')
    for s in (-1, 1):
        m.ell((s * 5.7, -3.6, 11.0), (1.5, 2.4, 3.9), 'rock1dk')
        for y in (-0.3, 6.6):
            m.ell((s * 3, y, 2.2), (1.9, 1.9, 2.6), 'rock1')
            m.ell((s * 3, y - 0.6, 0.6), (2.1, 2.4, 1.1), 'rock1lt')
    with layer(m, 'Tail'):
        m.chain([(0, 9.2, 8), (0, 10.6, 10), (0, 11.2, 12.2)], [1.4, 1.2, 1.0], 'rock1dk')
    m.spots('rock1dk', 7, 1.2, test=lambda x, y, z: z > 6)
    m.paint(lambda x, y, z: z <= 4 and -1 < y < 6 and abs(x) < 3.5, 'rock1lt')
    eyes(m, 2.6, 12.3)
    cheeks(m, 4.1, 10.1)
    nose(m, 0, 10.4, 0.95)
    orn_torus(B(m, 'collar', True), (0, -1.4, 8.4), 4.4, 0.65, axis=(0, -0.45, 1), sides=10, seg=40)
    orn_ball(B(m, 'tag', True), (0, -5.6, 6.6), 0.95, scale=(1, 0.45, 1))
    for p in ((1.6, 3.0, 10.4), (-2.0, 5.6, 9.9), (0.6, 7.8, 9.4)):
        orn_rock(B(m, 'pebble'), p, 1.0, m.rnd)
    return m


def c1_2():  # Dust Bunny (Uncommon) : lapin de poussière beige, petites étoiles dans la fourrure
    m = Vox(24, seed=12)
    m.ell((0, 2, 5.5), (5, 5.2, 5.2), 'beige')
    m.ell((0, -3, 11.6), (5.6, 5, 5), 'beige')
    m.ell((0, -7.4, 10.1), (2.6, 1.3, 1.7), 'cream')
    for s in (-1, 1):
        m.ell((s * 2.4, -2.4, 19.2), (1.7, 1.3, 5.2), 'beige')
        m.ell((s * 2.8, -2.6, 1.1), (1.8, 3, 1.3), 'cream')
        m.ell((s * 3.0, -3.4, 5.2), (1.3, 1.3, 1.5), 'cream')
    m.paint(lambda x, y, z: z > 15 and y <= -3.2 and 1.2 < abs(x) < 3.6, 'earpink')
    m.paint(lambda x, y, z: 2 < z < 9 and y < -1.5 and abs(x) < 3.4, 'cream')
    glow_specks(m, 'G:star', 10, test=lambda x, y, z: z > 3 and y > -6)
    with layer(m, 'Tail'):
        orn_ball(B(m, 'cream', True), (0, 7.6, 5.2), 2.4, sub=2)
    eyes(m, 2.4, 12.6)
    cheeks(m, 3.8, 10.6)
    nose(m, 0, 11.1, 0.6, key='earpink')
    for s in (-1, 1):
        orn_star(B(m, 'G:star'), (s * 2.4, -2.6, 25.2), 0.9, 0.4, 0.3)
    return m


def c1_3():  # Craterhog (Rare) : hérisson aux piquants de cristaux d'améthyste
    m = Vox(15, seed=13)
    m.ell((0, 1.5, 6), (5.6, 7, 5.6), 'hog')
    m.ell((0, -5.2, 5.6), (3.9, 3.4, 3.7), 'hogtan')
    m.ell((0, -8.3, 5.0), (1.9, 1.7, 1.6), 'hogtan')
    for s in (-1, 1):
        m.ell((s * 3.1, -3.6, 9.0), (1.1, 0.8, 1.1), 'hogdk')
        for y in (-2.5, 5.5):
            m.ell((s * 3.2, y, 1.1), (1.6, 1.9, 1.3), 'hogdk')
    m.paint(lambda x, y, z: z <= 3, 'hogtan')
    eyes(m, 1.9, 7.0, r=1.1)
    cheeks(m, 3.0, 5.2, 0.7)
    nose(m, 0, 5.2, 0.75)
    center = Vector((0, 2.6, 4.5))
    keys = ['ame', 'amelt', 'amedk', 'ame']
    for i, d in enumerate(fib_dirs(70)):
        if d.z < 0.12 or d.y < -0.42:
            continue
        base = center + Vector((d.x * 5.6, d.y * 7.0, d.z * 5.6)) * 0.86
        direction = (d + Vector((0, 0.45, 0.1))).normalized()
        key = 'G:ame' if i % 9 == 0 else keys[i % len(keys)]
        orn_crystal(B(m, key), base, direction, m.rnd.uniform(2.8, 4.2), m.rnd.uniform(0.62, 0.85))
    return m


def c1_4():  # Orbitoad (Epic) : gros crapaud guerrier, peintures de guerre lumineuses, lunes en orbite
    m = Vox(18, seed=14)
    m.ell((0, 0.5, 6.2), (8, 7, 5.8), 'toad')
    for s in (-1, 1):
        m.ell((s * 3.8, -3.0, 11.2), (2.6, 2.5, 2.4), 'toad')
        m.ell((s * 7.2, 3.2, 2.8), (2.8, 4.2, 2.8), 'toad')
        m.ell((s * 7.8, -0.8, 0.8), (2.4, 2.8, 0.9), 'toadlt')
        m.ell((s * 4.6, -5.0, 2.4), (2.0, 2.0, 2.6), 'toad')
        m.ell((s * 4.8, -6.4, 0.6), (2.2, 2.0, 0.7), 'toadlt')
    m.paint(lambda x, y, z: z < 5 and y < 0 and abs(x) < 6, 'toadlt')
    m.paint(lambda x, y, z: z == 6 and y < -5.2 and abs(x) < 5.6, 'mouth')
    # peintures de guerre lumineuses sur le dos
    m.paint(lambda x, y, z: z > 9 and abs((abs(x) - y * 0.6) % 4 - 2) < 0.5 and y > -2, 'G:ringg')
    m.spots('toaddk', 6, 1.1, test=lambda x, y, z: z > 8 and y > 0)
    fierce_eyes(m, 3.8, 11.6, 1.5, 'ringg', inset=0.3)
    for s in (-1, 1):
        y = front_y(m, s * 4.4, 5.6)
        orn_cone(B(m, 'white'), (s * 4.4, y + 0.3, 5.4), (s * 0.15, -0.2, 1), 1.6, 0.42, sides=8)
    # verrues de cristal
    for i, d in enumerate(fib_dirs(40)):
        if d.z > 0.35 and d.y > -0.3 and i % 3 == 0:
            base = Vector((0, 0.5, 6.2)) + Vector((d.x * 8, d.y * 7, d.z * 5.8)) * 0.95
            orn_crystal(B(m, 'G:ringg' if i % 2 else 'toadlt'), base, d, 1.6, 0.45)
    with layer(m, 'Orbit'):
        ctr = Vector((0, 0.3, 17.0))
        orn_torus(B(m, 'G:ringg', True), ctr, 8.0, 0.22, tilt=0.28, seg=64, sides=6)
        rot = Matrix.Rotation(0.28, 4, 'X')
        for a in (0.4, math.pi + 0.4, 2.0):
            p = ctr + rot @ Vector((math.cos(a) * 8.0, math.sin(a) * 8.0, 0))
            orn_ball(B(m, 'moon', True), p, 1.6 if a != 2.0 else 1.1, sub=2)
            for k in range(3):
                q = Vector(((k - 1) * 0.6, -0.9, 0.5 - k * 0.45))
                orn_ball(B(m, 'moondk', True), p + q.normalized() * 1.3, 0.4)
    return m


def c1_5():  # Meteor Fox (Legendary) : grand renard de feu, crinière de flammes, armure d'or, queue météore
    m = Vox(26, seed=15)
    m.ell((0, 3, 8.6), (4.6, 9, 4.6), 'fox')
    m.ell((0, -4.6, 10.4), (3.8, 3.2, 4.2), 'foxw')
    m.chain([(0, -3.5, 11.5), (0, -6, 14.5)], [3.4, 3.0], 'fox')
    m.ell((0, -7.6, 16.2), (4.4, 4.4, 3.9), 'fox')
    m.ell((0, -12.6, 15.0), (1.9, 3.8, 1.6), 'foxw')
    for s in (-1, 1):
        m.ell((s * 2.8, -7.0, 21.6), (1.5, 1.0, 4.2), 'fox')
        for y in (-2.0, 8.2):
            m.ell((s * 2.8, y, 3.8), (1.4, 1.4, 4.0), 'fox')
            m.ell((s * 2.8, y - 0.7, 0.7), (1.7, 2.2, 0.9), 'foxdk')
    m.paint(lambda x, y, z: z < 15.6 and y < -9.6, 'foxw')
    m.paint(lambda x, y, z: z >= 24, 'foxdk')
    m.paint(lambda x, y, z: z <= 2, 'foxdk')
    m.paint(lambda x, y, z: z > 8 and abs(x) > 3.6 and int(y) % 3 == 0 and 0 < y < 10, 'G:flame')
    fierce_eyes(m, 2.2, 16.8, 1.2, 'flamey', inset=0.2)
    nose(m, 0, 15.4, 0.85)
    # crinière de flammes (du crâne au dos)
    for i, (y, z) in enumerate(((-6.5, 19.5), (-4.5, 18.0), (-2.5, 15.5), (0.0, 13.5), (2.5, 13.0))):
        h = 4.2 - i * 0.5
        base = Vector((0, y, z))
        orn_sweep(B(m, 'G:flame', True), [base, base + Vector((0, 1.6, h * 0.55)), base + Vector((0, 3.4, h))], [1.5, 1.0, 0.05], sides=10)
        orn_sweep(B(m, 'G:flamey', True), [base + Vector((0, 0.3, 0.4)), base + Vector((0, 1.5, h * 0.45)), base + Vector((0, 2.6, h * 0.75))], [0.8, 0.5, 0.04], sides=8)
    # armure d'or sur le poitrail, bracelets
    orn_ball(B(m, 'gold', True), (0, -7.6, 10.6), 3.2, scale=(1.05, 0.35, 1.0))
    orn_gem(B(m, 'ruby'), (0, -8.8, 10.8), 1.2, direction=(0, -1, 0.1))
    for s in (-1, 1):
        orn_torus(B(m, 'gold', True), (s * 2.8, -2.0, 3.0), 1.55, 0.35, sides=8, seg=24)
        orn_sweep(B(m, 'G:flame', True), [(s * 2.8, -2.6, 0.6), (s * 3.4, -1.6, 1.8), (s * 3.6, -0.4, 2.8)], [0.6, 0.35, 0.03], sides=8)
    with layer(m, 'Tail'):
        m.chain([(0, 11.6, 9), (0, 15, 11), (0, 16.6, 15), (0, 16, 19)], [2.0, 2.5, 2.7, 2.4], 'fox')
        tip = Vector((0, 15.6, 21.6))
        orn_rock(B(m, 'meteor'), tip, 3.4, m.rnd, squash=0.95)
        for k in range(9):
            d = Vector((m.rnd.uniform(-1, 1), m.rnd.uniform(-1, 1), m.rnd.uniform(-0.2, 1))).normalized()
            orn_ball(B(m, 'G:flamey', True), tip + d * 2.9, 0.55)
        orn_sweep(B(m, 'G:flame', True), [tip, tip + Vector((0, 2.2, 3.6)), tip + Vector((0, 4.6, 7.2))], [2.9, 1.8, 0.05], sides=12)
        orn_sweep(B(m, 'G:flamey', True), [tip + Vector((0, 0.4, 1.0)), tip + Vector((0, 2.0, 3.8)), tip + Vector((0, 3.8, 6.0))], [1.7, 1.0, 0.04], sides=10)
        for s in (-1, 1):
            orn_sweep(B(m, 'G:flame', True), [tip + Vector((s * 1.8, 0, 0.8)), tip + Vector((s * 3.0, 1.6, 2.8)), tip + Vector((s * 3.3, 3.2, 5.0))], [1.0, 0.6, 0.03], sides=8)
    return m


def c1_6():  # Stardust Dragon (Mythic) : vrai dragon de poussière d'étoiles, grandes ailes, armure d'or
    m = Vox(32, seed=16)
    m.ell((0, 3, 9.5), (5.8, 8.5, 6.2), 'drag')
    m.chain([(0, -3.5, 13), (0, -6.2, 17.5), (0, -7.6, 21)], [3.8, 3.2, 3.0], 'drag')
    m.ell((0, -9.4, 23.2), (4.0, 4.6, 3.6), 'drag')
    m.ell((0, -14.0, 22.2), (2.6, 3.6, 2.1), 'draglt')
    m.ell((0, -13.2, 20.4), (2.2, 3.0, 1.0), 'dragdk')
    for s in (-1, 1):
        m.ell((s * 3.6, -2.0, 3.8), (2.4, 2.4, 4.2), 'drag')
        m.ell((s * 3.8, -3.0, 0.8), (2.6, 3.0, 1.0), 'dragdk')
        m.ell((s * 4.0, 8.0, 4.0), (2.8, 3.0, 4.2), 'drag')
        m.ell((s * 4.2, 7.0, 0.8), (2.8, 3.2, 1.0), 'dragdk')
    m.paint(lambda x, y, z: y < -2 and 5 < z < 20 and abs(x) < 3.4, 'gold')
    m.paint(lambda x, y, z: y < -2 and 5 < z < 20 and abs(x) < 3.4 and z % 2 == 0, 'golddk')
    m.paint(lambda x, y, z: z > 10 and abs(math.sin(x * 0.9 + y * 0.6)) < 0.12, 'G:starg')
    glow_specks(m, 'G:starg', 14, test=lambda x, y, z: z > 8)
    fierce_eyes(m, 2.4, 24.4, 1.2, 'gemp', inset=0.2)
    for s in (-1, 1):
        orn_ball(B(m, 'G:gemp', True), (s * 0.9, front_y(m, s * 0.9, 22.6) + 0.1, 22.6), 0.35)
        # grandes cornes d'or recourbées
        orn_sweep(B(m, 'gold', True), [(s * 2.4, -8.2, 26.2), (s * 3.6, -5.6, 28.8), (s * 4.0, -2.4, 29.6), (s * 3.6, -0.4, 28.4)], [0.95, 0.7, 0.4, 0.06], sides=12, profile=ribs(6, 0.08))
        orn_cone(B(m, 'white'), (s * 1.6, front_y(m, s * 1.6, 20.6) + 0.4, 20.6), (0, -0.2, -1), 1.2, 0.35, sides=6)
    # crête de piques d'or : cou, dos
    for y, z, L in ((-6.6, 25.2, 2.2), (-5.4, 21.0, 2.6), (-3.2, 17.0, 2.8), (0.0, 15.6, 3.2), (3.4, 15.6, 3.2), (6.8, 14.6, 2.8), (9.6, 12.6, 2.2)):
        orn_cone(B(m, 'gold'), (0, y, z), (0, 0.35, 1), L, 0.85, sides=6)
    # plaques d'armure sur les épaules
    for s in (-1, 1):
        orn_ball(B(m, 'gold', True), (s * 5.2, -1.2, 12.0), 2.6, scale=(0.45, 1.0, 0.8))
        orn_gem(B(m, 'gemp'), (s * 6.4, -1.2, 12.2), 0.9, direction=(s, 0, 0.2))
    with layer(m, 'Tail'):
        m.chain([(0, 11, 8), (0, 15.5, 6.5), (0, 19.5, 7), (0, 22.5, 9.5)], [3.0, 2.3, 1.7, 1.1], 'drag')
        orn_gem(B(m, 'gemp'), (0, 23.8, 11.4), 1.8, direction=(0, 0.6, 1))
        for y, z in ((13, 9.6), (16.5, 8.6), (20, 9.4)):
            orn_cone(B(m, 'gold'), (0, y, z), (0, 0.4, 1), 2.0, 0.65, sides=6)
    for s, nm in ((-1, 'WingL'), (1, 'WingR')):
        with layer(m, nm):
            root = Vector((s * 4.4, 2.0, 14.0))
            knuckle = root + Vector((s * 7.5, 2.0, 8.0))
            tip = root + Vector((s * 14.0, 3.6, 5.5))
            orn_sweep(B(m, 'gold', True), [root, knuckle, tip], [1.0, 0.75, 0.2], sides=10)
            orn_cone(B(m, 'gold'), knuckle, (s * 0.3, 0, 1), 2.0, 0.5, sides=6)
            for f in (tip, root + Vector((s * 13.0, 3.4, -1.0)), root + Vector((s * 10.0, 3.0, -4.6)), root + Vector((s * 5.6, 2.4, -6.0))):
                orn_sweep(B(m, 'membr', True), [knuckle.lerp(root, 0.35), knuckle.lerp(f, 0.5) + Vector((0, 0.3, -0.8)), f], [0.6, 2.6, 0.05], sides=6, flat=0.2, twist_up=Vector((0, 1, 0)))
                orn_sweep(B(m, 'golddk', True), [knuckle, f], [0.32, 0.12], sides=6)
    with layer(m, 'Orbit'):
        for k in range(4):
            a = k / 4 * math.tau + 0.5
            orn_star(B(m, 'G:starg'), (math.cos(a) * 11, 1 + math.sin(a) * 11, 26 + math.sin(a * 2) * 1.5), 1.2, 0.5, 0.4)
    return m


CREATURES = {
    1: (c1_1, c1_2, c1_3, c1_4, c1_5, c1_6),
}


def build_creatures(ring, rarities=None, pal=None, prefix='Creature', only=None):
    # prefix : changer le nom à chaque nouvelle version (l'import Ropilot écrase les objets de même nom)
    # only : liste de raretés à construire (None = toutes)
    clear_scene()
    funcs = CREATURES[ring]
    rarities = rarities or (list(range(1, 7)) if ring < 5 else list(range(2, 8)))
    x = 0
    for r, f in zip(rarities, funcs):
        if only and r not in only:
            continue
        m = f()
        build(m, '%s_R%d_T%d' % (prefix, ring, r), pal or PALC, offset=(x, 0, 0))
        xs = [c[0] for c in m.cells]
        x += (max(xs) - min(xs)) + 26
    import ropilot
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, 'Creatures_R%d.blend' % ring))
    return len(bpy.data.objects)


print("créatures chargées")
