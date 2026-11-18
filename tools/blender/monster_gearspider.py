# Gear Spider (monstre de l'anneau 10, Model « GearSpider ») : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio, workspace.GenM_GearSpider) rendue en vues orthogonales
# (Renders/Monster_Refs/GenM_GearSpider_*.png) : gros corps rond a cadran d'horloge sur l'avant, deux cheminees,
# tete sous le cadran. Refaite plus imposante : huit longues pattes articulees en arc (genoux au-dessus du corps),
# cuivre, laiton et acier, rotules de laiton a rivets, verins d'acier ; gros corps rond a cadran d'horloge creme
# (aiguilles, graduations, couronne de lumieres laiton), chaudiere de cuivre a hublot de fournaise lumineux a
# l'arriere, rouages sur les flancs, tuyaux de vapeur et deux cheminees qui fument ; tete d'acier a six yeux rouges
# lumineux et machoires-pinces d'acier dentelees.
# Usage : exec(open(r"<repo>/tools/blender/monster_common_b.py").read()) puis exec de ce fichier.
import ropilot, bpy, math

PAL_GS = dict(
    brass=dict(color="#d49a3a", noise=0.03, shade=0.18, top=0.2, mottle=("#c88e32", 0.2, 4)),
    brass_dark=dict(color="#9a6a22", noise=0.03, shade=0.14, top=0.14),
    brass_light=dict(color="#f0c66a", noise=0.025, shade=0.14, top=0.16),
    copper=dict(color="#b8602e", noise=0.035, shade=0.18, top=0.18, mottle=("#a85628", 0.25, 4)),
    copper_dark=dict(color="#7c3c1c", noise=0.03, shade=0.14, top=0.12),
    copper_light=dict(color="#d88550", noise=0.03, shade=0.14, top=0.16),
    steel=dict(color="#8e96a2", noise=0.03, shade=0.18, top=0.2),
    steel_dark=dict(color="#4c5260", noise=0.03, shade=0.14, top=0.14),
    iron=dict(color="#2c2f38", noise=0.025, shade=0.12, top=0.12),
    dial=dict(color="#f2e6c4", noise=0.02, shade=0.06, rim=-0.15),
    mark="#2a2420",
    steam=dict(color="#eef0f4", noise=0.03, shade=0.16, top=0.2),
    steam_dark=dict(color="#c4c9d4", noise=0.03, shade=0.14, top=0.14),
    glow=dict(color="#e08a1c", glow=True),
    glow_red=dict(color="#e0201a", glow=True),
)
MRG = dict(mirror=True)


def gear_gs(m, name, c, r, t, axis, role="brass", hub="steel_dark", teeth=10, **kw):
    # roue dentee : disque a 10 pans, dents carrees tout autour, moyeu
    sfx = "_L" if kw.get("mirror") else ""
    if axis == "x":
        m.prism(f"{name}{sfx}", radius=r, height=t, at=c, role=role, sides=teeth, rot=(0, 90, 0), **kw)
        m.prism(f"{name}Hub{sfx}", radius=r * 0.35, height=t + 0.3, at=c, role=hub, sides=6, rot=(0, 90, 0), **kw)
    else:
        m.prism(f"{name}{sfx}", radius=r, height=t, at=c, role=role, sides=teeth, rot=(90, 0, 0), **kw)
        m.prism(f"{name}Hub{sfx}", radius=r * 0.35, height=t + 0.3, at=c, role=hub, sides=6, rot=(90, 0, 0), **kw)
    for k in range(teeth):
        a = 2 * math.pi * (k + 0.5) / teeth
        d = r + 0.12
        if axis == "x":
            m.box(f"{name}T{k}{sfx}", size=(t, 0.5, 0.42), at=(c[0], c[1] + d * math.cos(a), c[2] + d * math.sin(a)), role=role,
                  rot=(math.degrees(a) + 90, 0, 0), **kw)
        else:
            m.box(f"{name}T{k}{sfx}", size=(0.5, t, 0.42), at=(c[0] + d * math.cos(a), c[1], c[2] + d * math.sin(a)), role=role,
                  rot=(0, 90 - math.degrees(a), 0), **kw)


LEGS_GS = [((-2.6, -2.2, 5.4), (-6.4, -5.4, 11.2), (-9.0, -7.8, 4.4), (-9.4, -8.6, 0.0)),
           ((-3.3, -0.6, 5.6), (-7.4, -2.0, 11.8), (-10.6, -3.0, 4.2), (-11.2, -3.4, 0.0)),
           ((-3.3, 1.6, 5.6), (-7.4, 3.0, 11.6), (-10.6, 4.0, 4.2), (-11.2, 4.5, 0.0)),
           ((-2.6, 3.4, 5.4), (-6.2, 6.8, 10.8), (-8.8, 9.2, 4.2), (-9.2, 10.0, 0.0))]


def build_gs(m):
    # ---- corps rond a cadran : tambour de cuivre (axe avant-arriere), couronne de laiton, cadran creme
    BC = (0, 1.4, 7.6)
    m.prism("Drum", radius=4.3, height=4.6, at=BC, role="copper", sides=12, turn=15, rot=(90, 0, 0))
    m.prism("DrumBand", radius=4.45, height=0.7, at=(0, 2.4, 7.6), role="brass_dark", sides=12, turn=15, rot=(90, 0, 0))
    m.prism("Bezel", radius=4.55, height=0.9, at=(0, -1.15, 7.6), role="brass", sides=12, turn=15, rot=(90, 0, 0))
    m.prism("Dial", radius=3.6, height=0.4, at=(0, -1.5, 7.6), role="dial", sides=12, turn=15, rot=(90, 0, 0))
    for k in (0, 1, 2, 3, 9, 10, 11):          # le bas du cadran est cache par la tete
        a = math.radians(90 - 30 * k)
        big = k % 3 == 0
        rr = 3.0 if big else 3.15
        m.box(f"Mark{k}", size=(0.32 if big else 0.2, 0.12, 0.8 if big else 0.5), at=(rr * math.cos(a), -1.74, 7.6 + rr * math.sin(a)),
              role="iron", rot=(0, 90 - math.degrees(a), 0))
    for k in (0, 1, 2, 3, 4, 7):
        a = math.radians(22.5 + 45 * k)
        m.box(f"BezelLight{k}", size=(0.42, 0.16, 0.42), at=(4.05 * math.cos(a), -1.66, 7.6 + 4.05 * math.sin(a)), role="glow", rot=(0, 45, 0))
    # pointes de laiton qui couronnent le cadran
    for k, a in enumerate((90, 60, 120, 30, 150)):
        r = math.radians(a)
        h = 2.0 if k == 0 else (1.6 if k < 3 else 1.2)
        m.prism(f"CrownSpike{k}", radius=0.45, height=h, at=(4.45 * math.cos(r) + math.cos(r) * h / 2, -1.0, 7.6 + 4.45 * math.sin(r) + math.sin(r) * h / 2),
                role="brass_light", sides=4, taper=0, rot=(0, 90 - a, 0))
    m.beam("HandH", start=(0, -1.8, 7.6), end=(-1.5, -1.8, 9.0), role="iron", width=0.38, depth=0.14, taper=0.6)
    m.beam("HandM", start=(0, -1.86, 7.6), end=(1.6, -1.86, 10.2), role="iron", width=0.26, depth=0.12, taper=0.5)
    m.prism("HandCap", radius=0.42, height=0.3, at=(0, -1.95, 7.6), role="brass_light", sides=8, rot=(90, 0, 0))
    # ---- chaudiere de cuivre a l'arriere, hublot de fournaise lumineux, rivets
    m.prism("Boiler", radius=3.7, height=2.6, at=(0, 4.6, 7.4), role="copper_dark", sides=12, turn=15, rot=(-90, 0, 0), taper=0.8)
    m.prism("PortRim", radius=1.7, height=0.5, at=(0, 6.0, 7.4), role="brass", sides=10, rot=(90, 0, 0))
    m.prism("Furnace", radius=1.3, height=0.3, at=(0, 6.2, 7.4), role="glow", sides=10, rot=(90, 0, 0))
    for k in range(4):
        m.box(f"PortBar{k}", size=(0.18, 0.2, 2.5), at=(-0.75 + 0.5 * k, 6.35, 7.4), role="iron")
    for k in range(10):
        a = math.radians(36 * k + 18)
        m.box(f"Rivet{k}", size=(0.32, 0.25, 0.32), at=(2.6 * math.cos(a), 5.98, 7.4 + 2.6 * math.sin(a)), role="brass_light")
    # ---- rouages sur les flancs
    gear_gs(m, "GearA", (-4.35, 1.4, 8.4), 1.9, 0.5, "x", **MRG)
    gear_gs(m, "GearB", (-4.15, 3.3, 5.9), 1.1, 0.45, "x", role="brass_dark", hub="steel", teeth=8, **MRG)
    # ---- cheminees de cuivre a bagues de laiton, chapeau, lumiere, panaches de vapeur
    for k, (x, y, h) in enumerate(((-1.9, 2.3, 4.6), (1.9, 2.3, 3.8))):
        sfx = "A" if k == 0 else "B"
        m.prism(f"Stack{sfx}", radius=0.75, height=h, at=(x, y, 11.0 + h / 2), role="copper", sides=8, turn=22.5)
        m.prism(f"StackBand{sfx}", radius=0.9, height=0.4, at=(x, y, 11.6 + h * 0.45), role="brass", sides=8, turn=22.5)
        m.prism(f"StackLight{sfx}", radius=0.82, height=0.25, at=(x, y, 11.6 + h * 0.45 + 0.4), role="glow", sides=8, turn=22.5)
        m.prism(f"StackCap{sfx}", radius=1.05, height=0.6, at=(x, y, 11.0 + h + 0.25), role="brass_dark", sides=8, turn=22.5, taper=1.2)
        z0 = 11.0 + h + 0.55
        sx = 1 if k else -1
        for j, (dx, dy, dz, r) in enumerate(((0, 0, 0.6, 0.85), (0.55 * sx, 0.5, 1.4, 1.2), (-0.35 * sx, 0.9, 1.8, 1.0), (0.2 * sx, 1.5, 2.7, 1.3),
                                             (1.0 * sx, 2.1, 2.4, 0.9))):
            m.prism(f"Steam{sfx}{j}", radius=r, height=r * 1.6, at=(x + dx, y + dy, z0 + dz), role="steam" if j % 2 == 0 else "steam_dark", sides=8,
                    turn=22.5, rot=(90, 0, 0), solo=True)
    # tuyaux de vapeur qui courent sur le dessus et les flancs
    m.beam("PipeTop", start=(-1.9, 3.0, 11.6), end=(-1.9, 5.4, 10.4), role="copper_light", width=0.55, depth=0.55, chamfer=0.1, solo=True)
    m.beam("PipeSide_L", start=(-3.9, -0.6, 10.2), end=(-4.5, 3.6, 9.6), role="brass_dark", width=0.5, depth=0.5, chamfer=0.1, **MRG)
    m.beam("PipeDown_L", start=(-4.5, 3.6, 9.6), end=(-4.0, 5.2, 6.0), role="brass_dark", width=0.5, depth=0.5, chamfer=0.1, **MRG)
    m.box("Valve_L", size=(0.5, 0.9, 0.9), at=(-4.5, 3.6, 9.6), role="steel", chamfer=0.15, **MRG)
    # ---- dessous : plaque de laiton, attaches des pattes
    m.box("Belly", size=(6.0, 6.4, 1.8), at=(0, 1.0, 4.4), role="brass_dark", chamfer=0.6, taper=(0.8, 0.85), rot=(180, 0, 0))
    m.box("LegRing_L", size=(1.6, 7.0, 2.0), at=(-3.0, 0.6, 5.5), role="steel_dark", chamfer=0.5, **MRG)
    # ---- tete d'acier sous le cadran : casque, six yeux rouges, arcades, machoires-pinces dentelees
    m.box("Head", size=(5.6, 3.8, 3.6), at=(0, -3.3, 4.4), role="steel", chamfer=1.0, taper=(0.85, 0.85), faces={"bottom": "steel_dark"})
    m.box("HeadPlate", size=(3.8, 1.6, 0.5), at=(0, -3.6, 6.2), role="brass", chamfer=0.2, taper=(0.8, 0.8))
    for k, (x, z, r) in enumerate(((-1.15, 4.9, 0.62), (1.15, 4.9, 0.62), (-1.75, 5.85, 0.36), (1.75, 5.85, 0.36), (-0.55, 5.9, 0.3),
                                   (0.55, 5.9, 0.3))):
        m.prism(f"EyeRim{k}", radius=r + 0.18, height=0.3, at=(x, -4.95 + 0.25 * (r < 0.5), z), role="iron", sides=8, turn=22.5, rot=(90, 0, 0))
        m.prism(f"Eye{k}", radius=r, height=0.3, at=(x, -5.1 + 0.25 * (r < 0.5), z), role="glow_red", sides=8, turn=22.5, rot=(90, 0, 0))
    m.beam("Brow_L", start=(-2.2, -4.9, 5.9), end=(-0.5, -5.15, 5.45), role="iron", width=0.4, depth=0.5, chamfer=0.08, **MRG)
    m.box("Mouth", size=(2.6, 0.4, 1.0), at=(0, -4.95, 3.4), role="iron")
    JW = [(-1.3, -4.7, 3.3), (-2.1, -6.3, 2.6), (-1.8, -7.8, 1.5), (-0.5, -8.3, 0.9)]
    m.box("JawBase_L", size=(1.3, 1.5, 1.4), at=(-1.25, -4.9, 3.2), role="steel_dark", chamfer=0.3, **MRG)
    curve_mb(m, "Pincer_L", JW, [1.15, 0.95, 0.7, 0.35], [1.0, 0.85, 0.62, 0.32], ["steel", "steel", "steel_dark"], ext=0.1, chamf=0.1, **MRG)
    for k, t in enumerate((0.3, 0.55, 0.8)):
        p = mid_mb(JW[1], JW[2], t) if k < 2 else mid_mb(JW[2], JW[3], 0.4)
        m.prism(f"PincerTooth{k}_L", radius=0.22, height=0.7, at=add_mb(p, (0.48, 0, 0)), role="steel", sides=4, taper=0, rot=(0, 90, 0), **MRG)
    # ---- huit pattes articulees : rotule de laiton, cuisse de cuivre qui monte, genou a rivets, verin, tibia de laiton,
    #      cheville, tarse d'acier pointu
    for k, (hip, knee, ank, foot) in enumerate(LEGS_GS):
        m.box(f"Hip{k}_L", size=(1.5, 1.5, 1.5), at=hip, role="brass", chamfer=0.35, **MRG)
        m.beam(f"Femur{k}_L", start=hip, end=knee, role="copper", width=1.4, depth=1.5, chamfer=0.34, taper=0.8, **MRG)
        m.beam(f"FemBand{k}_L", start=mid_mb(hip, knee, 0.45), end=mid_mb(hip, knee, 0.55), role="brass_dark", width=1.55, depth=1.65,
               chamfer=0.35, **MRG)
        m.beam(f"Piston{k}_L", start=add_mb(mid_mb(hip, knee, 0.25), (0, 0, -1.05)), end=add_mb(mid_mb(hip, knee, 0.8), (0, 0, -0.95)),
               role="steel", width=0.32, depth=0.32, **MRG)
        m.prism(f"Knee{k}_L", radius=0.85, height=1.4, at=knee, role="brass", sides=8, turn=22.5, rot=(90, 0, 0), **MRG)
        m.prism(f"KneeCap{k}_L", radius=0.4, height=1.6, at=knee, role="steel_dark", sides=6, rot=(90, 0, 0), **MRG)
        m.beam(f"Tibia{k}_L", start=knee, end=ank, role="brass", width=1.15, depth=1.2, chamfer=0.25, taper=0.75, **MRG)
        m.beam(f"TibBand{k}_L", start=mid_mb(knee, ank, 0.55), end=mid_mb(knee, ank, 0.63), role="copper_dark", width=1.15, depth=1.2,
               chamfer=0.25, **MRG)
        m.box(f"Ankle{k}_L", size=(1.05, 1.05, 1.05), at=ank, role="copper_dark", chamfer=0.22, **MRG)
        m.beam(f"Tarsus{k}_L", start=ank, end=foot, role="steel", width=0.85, depth=0.85, taper=0.15, chamfer=0.12, **MRG)
        m.prism(f"Spur{k}_L", radius=0.2, height=0.8, at=add_mb(mid_mb(knee, ank, 0.35), (-0.45, 0, 0.1)), role="steel_dark", sides=4, taper=0,
                rot=(0, -70, 0), **MRG)
    m.remove("GearBT3_L", "GearBT3_R", "Piston2_L", "Piston2_R")   # caches dans le rouage et la cuisse
    return m


GSp = ropilot.model("M_GearSpider", px=8, reset=True)
GSp.reference(refs_mb("GenM_GearSpider"))
GSp.palette(**PAL_GS)
build_gs(GSp)
print(GSp.build())
print(GSp.compare(image=False)["report"])
