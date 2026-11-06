# Créatures en briques (style des œufs : corps en gros cubes + picots dans Studio, ornements modélisés).
# Charger voxkit.py d'abord, puis ce fichier, puis : build_creatures(1)
# Chaque créature : chibi (grosse tête), avant vers -y, pattes au sol (z = 0).
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
    'eye': '#1a1424', 'shine': '#ffffff', 'blush': '#ff8aa8', 'nose': '#2a2030', 'mouth': '#4a1e34', 'white': '#fff8f0',
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
    'drag': '#ff7ac8', 'draglt': '#ffbde2', 'dragdk': '#c83a92', 'golddk': '#e08a10', 'membr': '#ffd6f0', 'starg': '#fff6a0', 'gemp': '#ff3aa0',
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


def c1_4():  # Orbitoad (Epic) : crapaud bleu dodu, deux petites lunes en orbite autour de la tête
    m = Vox(16, seed=14)
    m.ell((0, 0.5, 5), (7, 6.2, 5), 'toad')
    for s in (-1, 1):
        m.ell((s * 3.4, -2.6, 9.6), (2.4, 2.3, 2.3), 'toad')
        m.ell((s * 6.2, 2.8, 2.4), (2.4, 3.6, 2.3), 'toad')
        m.ell((s * 6.7, -0.6, 0.7), (2.1, 2.3, 0.8), 'toadlt')
        m.ell((s * 3.9, -4.4, 1.7), (1.4, 1.4, 1.8), 'toad')
        m.ell((s * 4.0, -5.4, 0.5), (1.7, 1.6, 0.6), 'toadlt')
    m.spots('toaddk', 8, 1.1, test=lambda x, y, z: z > 6)
    m.paint(lambda x, y, z: z < 4.5 and y < 0 and abs(x) < 5.5, 'toadlt')
    m.paint(lambda x, y, z: z == 5 and y < -4.6 and abs(x) < 4.6, 'mouth')
    eyes(m, 3.4, 10.2, r=1.6, inset=0.25)
    cheeks(m, 5.2, 6.4)
    with layer(m, 'Orbit'):
        ctr = Vector((0, 0.3, 15.0))
        orn_torus(B(m, 'G:ringg', True), ctr, 6.6, 0.16, tilt=0.28, seg=64, sides=6)
        rot = Matrix.Rotation(0.28, 4, 'X')
        for a in (0.4, math.pi + 0.4):
            p = ctr + rot @ Vector((math.cos(a) * 6.6, math.sin(a) * 6.6, 0))
            orn_ball(B(m, 'moon', True), p, 1.45, sub=2)
            for k in range(3):
                q = Vector(((k - 1) * 0.6, -0.9, 0.5 - k * 0.45))
                orn_ball(B(m, 'moondk', True), p + q.normalized() * 1.25, 0.38)
        for a in (1.9, 4.9):
            p = ctr + rot @ Vector((math.cos(a) * 6.6, math.sin(a) * 6.6, 0))
            orn_star(B(m, 'G:star'), p, 0.75, 0.32, 0.25)
    return m


def c1_5():  # Meteor Fox (Legendary) : renard orange, queue en météore enflammé
    m = Vox(22, seed=15)
    m.ell((0, 2.5, 6.6), (4.4, 7, 4.4), 'fox')
    m.ell((0, -3.0, 7.6), (3.4, 2.6, 3.6), 'foxw')
    m.ell((0, -6, 12.6), (5.4, 5, 4.8), 'fox')
    m.ell((0, -11, 11.1), (2.2, 2.8, 1.8), 'foxw')
    for s in (-1, 1):
        m.ell((s * 3.2, -5.6, 18.2), (1.8, 1.1, 3.4), 'fox')
        for y in (-1.0, 6.4):
            m.ell((s * 2.6, y, 2.6), (1.5, 1.5, 2.8), 'fox')
    m.paint(lambda x, y, z: z < 12.2 and y < -8.4, 'foxw')
    m.paint(lambda x, y, z: z >= 20, 'foxdk')
    m.paint(lambda x, y, z: 15.5 < z < 19.5 and y <= -6.4 and 2.0 < abs(x) < 4.4, 'foxw')
    m.paint(lambda x, y, z: z <= 2, 'foxdk')
    with layer(m, 'Tail'):
        m.chain([(0, 9.2, 7), (0, 12.2, 9), (0, 13.6, 12.5), (0, 13.2, 15.8)], [1.8, 2.2, 2.4, 2.1], 'fox')
        tip = Vector((0, 13.0, 18.0))
        orn_rock(B(m, 'meteor'), tip, 2.6, m.rnd, squash=0.95)
        for k in range(6):
            d = Vector((m.rnd.uniform(-1, 1), m.rnd.uniform(-1, 1), m.rnd.uniform(-0.2, 1))).normalized()
            orn_ball(B(m, 'G:flamey', True), tip + d * 2.2, 0.45)
        orn_sweep(B(m, 'G:flame', True), [tip, tip + Vector((0, 1.6, 2.8)), tip + Vector((0, 3.6, 5.4))], [2.2, 1.4, 0.05], sides=12)
        orn_sweep(B(m, 'G:flamey', True), [tip + Vector((0, 0.3, 0.8)), tip + Vector((0, 1.6, 3.0)), tip + Vector((0, 2.9, 4.6))], [1.3, 0.8, 0.04], sides=10)
        for s in (-1, 1):
            orn_sweep(B(m, 'G:flame', True), [tip + Vector((s * 1.4, 0, 0.6)), tip + Vector((s * 2.4, 1.2, 2.2)), tip + Vector((s * 2.6, 2.4, 3.8))], [0.8, 0.5, 0.03], sides=8)
    eyes(m, 2.5, 13.3)
    cheeks(m, 3.9, 11.2)
    nose(m, 0, 11.6, 0.9)
    orn_torus(B(m, 'gold', True), (0, -1.6, 9.0), 4.0, 0.55, axis=(0, -0.5, 1), sides=10, seg=40)
    orn_gem(B(m, 'ruby'), (0, -5.0, 7.4), 0.95, direction=(0, -1, 0.2))
    return m


def c1_6():  # Stardust Dragon (Mythic) : petit dragon rose et or fait de poussière d'étoiles
    m = Vox(24, seed=16)
    m.ell((0, 2, 7), (5, 6.5, 5.5), 'drag')
    m.ell((0, -5.5, 14), (5.4, 5, 4.8), 'drag')
    m.ell((0, -10.4, 12.5), (3, 2.6, 2.2), 'draglt')
    for s in (-1, 1):
        m.ell((s * 3.0, -1.2, 2.6), (1.8, 1.8, 2.8), 'drag')
        m.ell((s * 3.4, 5.6, 2.7), (2.0, 2.2, 2.8), 'drag')
    m.paint(lambda x, y, z: y < -1.5 and z < 11 and abs(x) < 3.6, 'gold')
    m.paint(lambda x, y, z: y < -1.5 and z < 11 and abs(x) < 3.6 and z % 2 == 0, 'golddk')
    glow_specks(m, 'G:starg', 12, test=lambda x, y, z: z > 6 and y > -9)
    with layer(m, 'Tail'):
        m.chain([(0, 8.4, 6), (0, 12, 5), (0, 15, 6), (0, 17, 8.4)], [2.2, 1.7, 1.2, 0.8], 'drag')
        orn_gem(B(m, 'gemp'), (0, 18, 9.8), 1.2, direction=(0, 0.6, 1))
        for y, z in ((10, 7.4), (13, 6.6), (15.6, 7.6)):
            orn_cone(B(m, 'gold'), (0, y, z), (0, 0.4, 1), 1.4, 0.5, sides=6)
    for y, z in ((-2.4, 12.2), (0.5, 12.2), (3.5, 12.0), (6.4, 11.0)):
        orn_cone(B(m, 'gold'), (0, y, z), (0, 0.35, 1), 1.8, 0.65, sides=6)
    for s in (-1, 1):
        orn_sweep(B(m, 'gold', True), [(s * 2.6, -3.8, 17.8), (s * 3.4, -1.8, 20.4), (s * 3.6, 0.6, 21.6)], [0.75, 0.45, 0.08], sides=10)
    for s, nm in ((-1, 'WingL'), (1, 'WingR')):
        with layer(m, nm):
            root = Vector((s * 3.8, 2.6, 11.0))
            knuckle = root + Vector((s * 5.2, 1.2, 5.0))
            tip = root + Vector((s * 8.6, 2.2, 3.4))
            orn_sweep(B(m, 'gold', True), [root, knuckle, tip], [0.7, 0.5, 0.15], sides=10)
            for f in (tip, root + Vector((s * 7.6, 2.0, -1.4)), root + Vector((s * 4.8, 1.6, -3.6))):
                orn_sweep(B(m, 'membr', True), [knuckle.lerp(root, 0.35), knuckle.lerp(f, 0.5) + Vector((0, 0.2, -0.6)), f], [0.5, 1.7, 0.05], sides=6, flat=0.22, twist_up=Vector((0, 1, 0)))
    eyes(m, 2.5, 14.9, r=1.45)
    cheeks(m, 3.9, 12.6)
    for s in (-1, 1):
        orn_ball(B(m, 'dragdk', True), (s * 0.9, front_y(m, s * 0.9, 13.0) + 0.1, 13.0), 0.35)
    with layer(m, 'Orbit'):
        for k in range(3):
            a = k / 3 * math.tau + 0.5
            orn_star(B(m, 'G:starg'), (math.cos(a) * 7.5, -2 + math.sin(a) * 7.5, 17.5 + math.sin(a * 2) * 1.2), 0.9, 0.38, 0.3)
    return m


CREATURES = {
    1: (c1_1, c1_2, c1_3, c1_4, c1_5, c1_6),
}


def build_creatures(ring, rarities=None, pal=None):
    clear_scene()
    funcs = CREATURES[ring]
    rarities = rarities or (list(range(1, 7)) if ring < 5 else list(range(2, 8)))
    x = 0
    for r, f in zip(rarities, funcs):
        m = f()
        build(m, 'Creature_R%d_T%d' % (ring, r), pal or PALC, offset=(x, 0, 0))
        xs = [c[0] for c in m.cells]
        x += (max(xs) - min(xs)) + 26
    import ropilot
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, 'Creatures_R%d.blend' % ring))
    return len(bpy.data.objects)


print("créatures chargées")
