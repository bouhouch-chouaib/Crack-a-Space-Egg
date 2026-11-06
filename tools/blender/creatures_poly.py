# Créatures low-poly facettées (charger voxkit.py, puis polykit.py, puis ce fichier).
# Progression : Common = animal en blocs mignon (tête cube, yeux rectangles) ; plus la rareté monte,
# plus la silhouette est réaliste, grande et menaçante (griffes, dents, sourcils, lumière, ailes…).

import math, os
from mathutils import Vector, Matrix

PALP = {
    # communs
    'eyew': '#ffffff', 'eyeb': '#141018', 'browdk': '#1a1218', 'nose': '#1e1620', 'mouth': '#3a1020', 'tooth': '#fff6e0',
    'claw': '#f2ead8', 'pink': '#ff8ab0', 'gold': '#ffc21a', 'golddk': '#d8860c', 'ruby': '#ff2456',
    'eyeglow': '#ffd23a', 'star': '#fff27a',
    # Pebblepup
    'rock': '#9aa4ae', 'rocklt': '#c8d0d8', 'rockdk': '#5e6670', 'pebble': '#8a6e58', 'collar': '#e8402e',
    # Dust Bunny
    'bun': '#ead2a6', 'bunlt': '#fff3dc', 'bundk': '#c8a878',
    # Craterhog
    'hog': '#8a5a3a', 'hoglt': '#efc896', 'hogdk': '#5a3820', 'ame': '#a85cff', 'amelt': '#dca4ff', 'amedk': '#6a2ad0', 'amg': '#c47aff',
    # Orbitoad
    'toad': '#2f7cf0', 'toadlt': '#9fd4ff', 'toaddk': '#1a4cb0', 'moon': '#ece6d6', 'moondk': '#a8a090', 'ringg': '#6ae8ff',
    # Meteor Fox
    'fox': '#f2701a', 'foxlt': '#fff1e0', 'foxdk': '#3a1e12', 'meteor': '#5e4234', 'flame': '#ff5a0a', 'flamey': '#ffd23a',
    # Stardust Dragon
    'drag': '#e8389a', 'draglt': '#ffb0d8', 'dragdk': '#8a1a5a', 'membr': '#ff8ccc', 'starg': '#fff6a0', 'pinkg': '#ff4fd0',
}


# ANNEAU 1 -------------------------------------------------------------------------------------

def p1_1():  # Pebblepup (Common) : chiot de roche en blocs
    m = Poly(11)
    for s in (-1, 1):
        for y in (-2.0, 2.4):
            frustum(B(m, 'rock'), (s * 1.5, y, 3.4), (s * 1.5, y, 0.6), (1.3, 1.3), (1.2, 1.2))
            box(B(m, 'rockdk'), (s * 1.5, y - 0.2, 0.35), (1.55, 1.9, 0.7), bevel=0.2)
    box(B(m, 'rock'), (0, 0.3, 4.4), (4.0, 6.2, 3.0), bevel=0.22)
    box(B(m, 'rocklt'), (0, -2.75, 4.1), (3.0, 0.9, 2.2), bevel=0.2)
    box(B(m, 'rock'), (0, -3.3, 7.6), (4.4, 4.0, 3.8), bevel=0.18)
    fy = -3.3 - 2.0
    box(B(m, 'rocklt'), (0, fy - 0.55, 6.6), (2.3, 1.3, 1.6), bevel=0.2)
    box(D(m, 'nose'), (0, fy - 1.25, 7.15), (0.95, 0.3, 0.62), bevel=0.25)
    box(D(m, 'nose'), (0, fy - 1.25, 6.35), (0.16, 0.2, 0.7), bevel=0.0)
    box(D(m, 'nose'), (0, fy - 1.25, 6.05), (1.0, 0.2, 0.16), bevel=0.0)
    for s in (-1, 1):
        box(B(m, 'rockdk'), (s * 2.45, -3.1, 7.9), (0.55, 1.7, 2.8), rot=(0, s * 0.22, 0), bevel=0.2)
    eyes_cute(m, 1.05, 8.2, fy)
    orn_torus(D(m, 'collar'), (0, -2.6, 6.0), 2.1, 0.32, axis=(0, -0.35, 1), sides=4, seg=8)
    box(D(m, 'gold'), (0, -4.2, 5.2), (0.8, 0.25, 0.8), rot=(0, 0.785, 0), bevel=0.2)
    with layer(m, 'Tail'):
        frustum(B(m, 'rock'), (0, 3.2, 5.0), (0, 4.4, 7.4), (1.0, 1.0), (0.7, 0.7))
    for p, r in (((1.0, 1.2, 6.0), 0.7), ((-1.1, 2.6, 5.95), 0.6), ((0.4, -0.6, 6.0), 0.5)):
        blob(B(m, 'pebble'), p, (r, r, r * 0.7), m.rnd, 0.2)
    return m


def p1_2():  # Dust Bunny (Uncommon) : lapin de poussière en blocs, étoiles dans la fourrure
    m = Poly(12)
    for s in (-1, 1):
        box(B(m, 'bundk'), (s * 1.4, -1.6, 0.3), (1.2, 1.7, 0.6), bevel=0.2)
        frustum(B(m, 'bun'), (s * 1.4, -1.6, 2.4), (s * 1.4, -1.6, 0.5), (1.0, 1.0), (0.9, 0.9))
        box(B(m, 'bun'), (s * 1.7, 1.6, 1.5), (1.4, 2.8, 2.6), bevel=0.25)
        box(B(m, 'bundk'), (s * 1.7, 0.4, 0.3), (1.3, 2.0, 0.6), bevel=0.2)
    box(B(m, 'bun'), (0, 0.6, 3.6), (3.6, 4.2, 3.4), bevel=0.25)
    box(B(m, 'bunlt'), (0, -1.55, 3.4), (2.6, 0.5, 2.6), bevel=0.2)
    box(B(m, 'bun'), (0, -1.0, 7.3), (4.0, 3.6, 3.6), bevel=0.2)
    fy = -1.0 - 1.8
    box(B(m, 'bunlt'), (0, fy - 0.4, 6.4), (2.0, 0.9, 1.4), bevel=0.25)
    box(D(m, 'pink'), (0, fy - 0.9, 6.95), (0.8, 0.25, 0.5), bevel=0.25)
    box(D(m, 'nose'), (0, fy - 0.9, 6.2), (0.14, 0.2, 0.6), bevel=0.0)
    for s in (-1, 1):
        frustum(B(m, 'bun'), (s * 1.0, -0.7, 8.8), (s * 1.3, -0.4, 13.2), (1.3, 0.7), (1.0, 0.55), up=(0, -1, 0))
        frustum(D(m, 'pink'), (s * 1.02, -1.08, 9.4), (s * 1.3, -0.8, 12.6), (0.7, 0.2), (0.5, 0.2), up=(0, -1, 0))
    eyes_cute(m, 0.95, 7.9, fy, w=1.0, h=1.25)
    with layer(m, 'Tail'):
        blob(B(m, 'bunlt'), (0, 3.0, 3.6), (1.2, 1.0, 1.2), m.rnd, 0.15)
    for p in ((1.8, 0.0, 5.0), (-1.8, 1.4, 4.6), (1.2, 2.4, 5.2), (-0.9, -0.4, 9.1)):
        orn_star(D(m, 'G:star'), p, 0.45, 0.2, 0.14, normal=(math.copysign(1, p[0]), 0, 0.4))
    return m


def p1_3():  # Craterhog (Rare) : hérisson aux piquants de cristaux d'améthyste
    m = Poly(13)
    for s in (-1, 1):
        for y in (-1.8, 2.2):
            frustum(B(m, 'hogdk'), (s * 1.8, y, 2.0), (s * 1.8, y, 0.4), (1.1, 1.1), (1.0, 1.0))
            claws(m, s * 1.8, y - 0.55, 0.25, n=3, length=0.55, radius=0.16, spread=0.3)
    frustum(B(m, 'hog'), (0, 3.6, 3.4), (0, -1.6, 3.6), (4.4, 3.6), (4.6, 4.0))
    frustum(B(m, 'hoglt'), (0, -1.4, 3.3), (0, -4.6, 2.6), (3.6, 3.2), (1.4, 1.2))
    box(D(m, 'nose'), (0, -4.85, 2.65), (0.75, 0.4, 0.6), bevel=0.3)
    for s in (-1, 1):
        box(B(m, 'hogdk'), (s * 1.7, -1.4, 5.1), (0.9, 0.5, 0.9), bevel=0.25)
    # yeux sur le front, au-dessus du museau
    eyes_cute(m, 1.1, 5.05, -1.62, w=0.95, h=1.0)
    keys = ('ame', 'amelt', 'amedk', 'ame', 'G:amg')
    c = Vector((0, 1.0, 3.8))
    for i, d in enumerate(fib_dirs(54)):
        if d.z < 0.05 or d.y < -0.45:
            continue
        base = c + Vector((d.x * 2.2, d.y * 2.9, d.z * 2.0))
        orn_crystal(D(m, keys[i % len(keys)]), base, (d + Vector((0, 0.55, 0.15))).normalized(), m.rnd.uniform(2.0, 3.0), m.rnd.uniform(0.42, 0.6), sides=5)
    return m


def p1_4():  # Orbitoad (Epic) : gros crapaud guerrier, lunes en orbite
    m = Poly(14)
    for s in (-1, 1):
        # pattes arrière repliées, pattes avant en piliers
        box(B(m, 'toad'), (s * 3.9, 2.4, 1.6), (2.0, 4.4, 2.6), rot=(0.25, 0, s * 0.2), bevel=0.25)
        box(B(m, 'toadlt'), (s * 4.3, 0.2, 0.3), (2.0, 2.4, 0.6), bevel=0.2)
        frustum(B(m, 'toad'), (s * 2.3, -2.6, 3.0), (s * 2.5, -3.2, 0.5), (1.4, 1.4), (1.2, 1.2))
        box(B(m, 'toadlt'), (s * 2.5, -3.6, 0.3), (1.8, 2.0, 0.6), bevel=0.2)
        claws(m, s * 2.5, -4.6, 0.3, n=3, length=0.6, radius=0.18, spread=0.45)
    frustum(B(m, 'toad'), (0, 3.8, 3.6), (0, -2.0, 4.2), (6.6, 4.4), (7.4, 5.2))
    box(B(m, 'toadlt'), (0, -0.6, 2.2), (6.0, 5.0, 1.0), bevel=0.25)
    box(B(m, 'toad'), (0, -3.0, 5.6), (6.6, 3.0, 3.0), bevel=0.2)
    fy = -4.5
    box(D(m, 'mouth'), (0, fy - 0.05, 4.7), (5.6, 0.2, 0.4), bevel=0.2)
    for s in (-1, 1):
        spike(D(m, 'tooth'), (s * 1.8, fy - 0.15, 4.8), (0, -0.1, -1), 1.1, 0.3, sides=4)
        box(B(m, 'toad'), (s * 2.1, -3.0, 7.6), (2.4, 2.4, 2.0), bevel=0.25)
    eyes_fierce(m, 2.1, 7.7, -4.2, w=1.6, h=1.0, iris='G:ringg')
    for i, (x, y) in enumerate(((0, 0.6), (-1.8, 1.6), (1.8, 1.4), (0, 2.8), (-2.6, -0.2), (2.6, -0.4))):
        box(D(m, 'G:ringg'), (x, y, 6.35 + 0.05 * i), (0.5, 1.5, 0.2), rot=(0, 0, 0.6 if i % 2 else -0.6), bevel=0.1)
    for (x, y, z) in ((1.2, 0.0, 6.4), (-1.0, 2.0, 6.2), (2.8, 2.2, 5.8), (-2.9, 1.0, 5.9)):
        orn_crystal(D(m, 'toadlt'), (x, y, z), (x * 0.1, 0.2, 1), 1.4, 0.4, sides=5)
    with layer(m, 'Orbit'):
        ctr = Vector((0, 0.6, 10.6))
        orn_torus(D(m, 'G:ringg'), ctr, 6.4, 0.18, tilt=0.28, seg=24, sides=4)
        rot = Matrix.Rotation(0.28, 4, 'X')
        for a, r in ((0.4, 1.3), (math.pi + 0.4, 1.3), (2.1, 0.85)):
            p = ctr + rot @ Vector((math.cos(a) * 6.4, math.sin(a) * 6.4, 0))
            blob(D(m, 'moon'), p, (r, r, r), m.rnd, 0.06)
            blob(D(m, 'moondk'), p + Vector((0.4, -r * 0.75, 0.3)), (0.3, 0.2, 0.3), None)
    return m


def p1_5():  # Meteor Fox (Legendary) : renard de feu élancé, crinière de flammes, queue météore
    m = Poly(15)
    # pattes avant et arrière (cuisse -> jarret -> pied), griffes
    for s in (-1, 1):
        chain(B(m, 'fox'), [(s * 1.25, -2.4, 6.0), (s * 1.3, -2.7, 3.0), (s * 1.3, -2.4, 0.7)], [(1.3, 1.4), (0.95, 1.0), (0.85, 0.95)])
        chain(B(m, 'fox'), [(s * 1.35, 3.0, 6.6), (s * 1.45, 4.4, 3.6), (s * 1.35, 3.6, 0.7)], [(1.7, 2.0), (1.0, 1.1), (0.85, 0.95)])
        for y in (-2.4, 3.6):
            box(B(m, 'foxdk'), (s * 1.3, y - 0.25, 0.35), (1.15, 1.6, 0.7), bevel=0.2)
            claws(m, s * 1.3, y - 1.05, 0.3, n=3, length=0.55, radius=0.15, spread=0.33)
    frustum(B(m, 'fox'), (0, 3.6, 6.9), (0, -2.4, 7.0), (2.8, 2.8), (3.2, 3.4))
    blob(B(m, 'foxlt'), (0, -3.0, 6.2), (1.6, 1.2, 1.9), m.rnd, 0.12)
    # cou, tête, museau, mâchoire
    frustum(B(m, 'fox'), (0, -2.6, 7.8), (0, -4.2, 10.0), (2.4, 2.4), (2.0, 2.0))
    box(B(m, 'fox'), (0, -4.9, 10.6), (3.0, 2.8, 2.4), bevel=0.2)
    frustum(B(m, 'foxlt'), (0, -6.0, 10.1), (0, -8.4, 9.7), (2.0, 1.6), (0.9, 0.8))
    frustum(B(m, 'foxlt'), (0, -6.0, 9.4), (0, -7.8, 9.2), (1.6, 0.7), (0.8, 0.4))
    box(D(m, 'nose'), (0, -8.55, 9.8), (0.6, 0.4, 0.5), bevel=0.3)
    teeth_row(m, -0.35, 0.35, -7.6, 9.55, 2, 0.4, 0.12)
    for s in (-1, 1):
        blob(B(m, 'foxlt'), (s * 1.5, -5.2, 9.8), (0.6, 1.0, 0.8), m.rnd, 0.15)
        spike(B(m, 'fox'), (s * 1.0, -4.6, 11.6), (s * 0.35, 0.25, 1), 2.6, 0.95, sides=4)
        spike(D(m, 'foxdk'), (s * 1.05, -4.95, 11.7), (s * 0.35, 0.25, 1), 1.8, 0.5, sides=4)
    eyes_fierce(m, 0.85, 10.9, -6.3, w=0.95, h=0.55, iris='G:flamey', tilt=0.42)
    # crinière de flammes du crâne au dos
    for i, (y, z) in enumerate(((-4.6, 11.8), (-3.4, 11.0), (-2.0, 9.4), (-0.4, 8.6), (1.4, 8.5))):
        flame_shape(D(m, 'G:flame'), (0, y, z), 3.0 - i * 0.3, 0.75, back=0.8)
        flame_shape(D(m, 'G:flamey'), (0, y + 0.2, z + 0.2), 1.8 - i * 0.2, 0.4, back=0.7)
    # plastron d'or + rubis
    box(D(m, 'gold'), (0, -3.95, 6.4), (2.0, 0.4, 2.0), rot=(0, 0.785, 0), bevel=0.15)
    orn_gem(D(m, 'ruby'), (0, -4.25, 6.4), 0.6, direction=(0, -1, 0), sides=6)
    with layer(m, 'Tail'):
        chain(B(m, 'fox'), [(0, 3.8, 7.2), (0, 5.8, 8.4), (0, 6.8, 10.6), (0, 6.6, 12.6)], [(1.4, 1.4), (2.0, 2.0), (2.2, 2.2), (1.6, 1.6)])
        tip = Vector((0, 6.4, 14.0))
        blob(D(m, 'meteor'), tip, (1.7, 1.7, 1.6), m.rnd, 0.18)
        for k in range(7):
            d = Vector((m.rnd.uniform(-1, 1), m.rnd.uniform(-1, 1), m.rnd.uniform(-0.2, 1))).normalized()
            blob(D(m, 'G:flamey'), tip + d * 1.5, (0.35, 0.35, 0.35), None)
        flame_shape(D(m, 'G:flame'), tip + Vector((0, 0, 0.4)), 4.4, 1.4, back=0.5)
        flame_shape(D(m, 'G:flamey'), tip + Vector((0, 0.2, 0.8)), 2.8, 0.8, back=0.5)
    return m


def p1_6():  # Stardust Dragon (Mythic) : vrai dragon rose et or, ailes membraneuses, crocs, cornes
    m = Poly(16)
    for s in (-1, 1):
        chain(B(m, 'drag'), [(s * 1.9, -2.0, 6.4), (s * 2.1, -2.6, 3.2), (s * 2.0, -2.2, 0.7)], [(1.7, 1.9), (1.2, 1.3), (1.1, 1.2)])
        chain(B(m, 'drag'), [(s * 2.0, 3.6, 7.2), (s * 2.2, 5.2, 3.8), (s * 2.0, 4.2, 0.7)], [(2.2, 2.6), (1.3, 1.4), (1.1, 1.2)])
        for y in (-2.2, 4.2):
            box(B(m, 'dragdk'), (s * 2.0, y - 0.3, 0.35), (1.4, 1.8, 0.7), bevel=0.2)
            claws(m, s * 2.0, y - 1.15, 0.3, n=3, length=0.75, radius=0.2, spread=0.42)
    frustum(B(m, 'drag'), (0, 4.6, 7.4), (0, -2.4, 7.6), (3.8, 3.8), (4.2, 4.6))
    for i in range(5):  # plaques du ventre
        box(D(m, 'gold'), (0, -2.0 + i * 1.4, 5.25 + i * 0.05), (2.4 - i * 0.15, 1.2, 0.5), bevel=0.25)
    # cou et tête
    chain(B(m, 'drag'), [(0, -2.6, 8.6), (0, -4.2, 11.4), (0, -5.0, 14.2)], [(2.8, 2.8), (2.2, 2.2), (1.9, 1.9)])
    for i in range(3):
        box(D(m, 'gold'), (0, -3.6 - i * 0.55, 9.6 + i * 1.6), (1.4, 0.5, 1.0), rot=(0.5, 0, 0), bevel=0.2)
    box(B(m, 'drag'), (0, -5.6, 15.2), (2.6, 2.8, 2.2), bevel=0.18)
    frustum(B(m, 'drag'), (0, -6.8, 15.4), (0, -9.4, 14.8), (2.1, 1.6), (1.3, 1.0))
    frustum(B(m, 'dragdk'), (0, -6.6, 14.2), (0, -9.0, 13.6), (1.9, 0.8), (1.1, 0.5))
    box(D(m, 'mouth'), (0, -7.6, 14.3), (1.5, 2.2, 0.35), bevel=0.2)
    teeth_row(m, -0.55, 0.55, -8.4, 14.55, 4, 0.5, 0.13)
    teeth_row(m, -0.5, 0.5, -8.0, 14.15, 3, 0.4, 0.12, down=False)
    for s in (-1, 1):
        box(D(m, 'G:pinkg'), (s * 0.4, -9.45, 15.0), (0.25, 0.2, 0.2), bevel=0.0)
        orn_sweep(D(m, 'gold'), [(s * 0.9, -5.0, 16.0), (s * 1.6, -3.8, 17.4), (s * 2.0, -2.0, 18.0), (s * 1.8, -0.8, 17.4)], [0.5, 0.36, 0.2, 0.04], sides=5)
        spike(D(m, 'gold'), (s * 1.3, -5.2, 14.6), (s * 1, 0.4, 0.1), 1.0, 0.3, sides=4)
    eyes_fierce(m, 0.75, 15.7, -7.05, w=0.8, h=0.45, iris='G:pinkg', tilt=0.45)
    # crête de piques le long du dos et du cou
    for (y, z, L) in ((-5.4, 16.4, 1.2), (-4.6, 13.6, 1.5), (-3.6, 10.6, 1.8), (-1.6, 9.6, 2.0), (0.6, 9.6, 2.2), (2.8, 9.4, 2.0), (4.6, 9.1, 1.6)):
        spike(D(m, 'gold'), (0, y, z), (0, 0.35, 1), L, 0.55, sides=4)
    # veines d'étoiles
    for k in range(10):
        x = m.rnd.choice((-1, 1)) * m.rnd.uniform(1.6, 2.1)
        box(D(m, 'G:starg'), (x, m.rnd.uniform(-2, 4.5), m.rnd.uniform(6.8, 9.0)), (0.2, m.rnd.uniform(0.6, 1.4), 0.2), rot=(m.rnd.uniform(-1, 1), 0, 0), bevel=0.0)
    with layer(m, 'Tail'):
        chain(B(m, 'drag'), [(0, 4.8, 7.6), (0, 7.4, 6.8), (0, 10.0, 7.2), (0, 12.2, 8.6)], [(3.0, 3.0), (2.0, 2.0), (1.3, 1.3), (0.7, 0.7)])
        for (y, z) in ((6.6, 8.6), (9.0, 8.4), (11.2, 9.6)):
            spike(D(m, 'gold'), (0, y, z), (0, 0.4, 1), 1.4, 0.45, sides=4)
        orn_gem(D(m, 'G:pinkg'), (0, 13.0, 9.4), 1.1, direction=(0, 0.6, 1), sides=4)
    for s, nm in ((-1, 'WingL'), (1, 'WingR')):
        with layer(m, nm):
            root = Vector((s * 1.8, -0.6, 9.2))
            elbow = root + Vector((s * 4.0, 0.8, 4.2))
            wrist = root + Vector((s * 8.0, 1.6, 5.4))
            chain(D(m, 'dragdk'), [root, elbow, wrist], [(0.9, 0.9), (0.6, 0.6), (0.4, 0.4)])
            spike(D(m, 'gold'), wrist, (s * 0.5, 0, 1), 1.2, 0.3, sides=4)
            tips = [wrist + Vector((s * 4.6, 1.0, -1.2)), wrist + Vector((s * 3.6, 1.0, -4.8)), wrist + Vector((s * 1.4, 0.8, -7.0)), root + Vector((s * 2.6, 1.2, -2.0))]
            for f in tips[:3]:
                chain(D(m, 'dragdk'), [wrist, f], [(0.32, 0.32), (0.12, 0.12)])
            outline = [root + Vector((0, 0.2, 0)), wrist, tips[0], wrist.lerp(tips[1], 0.55) + Vector((s * 0.6, 0, 0.4)), tips[1], wrist.lerp(tips[2], 0.55) + Vector((s * 0.4, 0, 0.6)), tips[2], tips[3]]
            slab(B(m, 'membr'), outline, (0, 1, 0), 0.25)
    with layer(m, 'Orbit'):
        for k in range(4):
            a = k / 4 * math.tau + 0.5
            orn_star(D(m, 'G:starg'), (math.cos(a) * 9, 1 + math.sin(a) * 9, 16 + math.sin(a * 2) * 1.2), 0.9, 0.38, 0.3)
    return m


POLY = {1: (p1_1, p1_2, p1_3, p1_4, p1_5, p1_6)}


def build_poly_ring(ring, prefix='Poly', only=None):
    clear_scene()
    rar = list(range(1, 7)) if ring < 5 else list(range(2, 8))
    x = 0
    for r, f in zip(rar, POLY[ring]):
        if only and r not in only:
            continue
        m = f()
        coll = build_poly(m, '%s_R%d_T%d' % (prefix, ring, r), PALP, offset=(x, 0, 0))
        xs = [(o.matrix_world @ Vector(c)).x for o in coll.objects for c in o.bound_box]
        x = max(xs) + 14
    import ropilot
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, 'CreaturesPoly_R%d.blend' % ring))
    return len(bpy.data.objects)


print("créatures low-poly chargées")
