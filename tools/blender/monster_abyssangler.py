# Abyss Angler (monstre de l'anneau 8, Model « AbyssAngler ») : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio, workspace.GenM_AbyssAngler) rendue en vues orthogonales
# (Renders/Monster_Refs/GenM_AbyssAngler_*.png). Baudroie geante des abysses : gros corps sarcelle sombre a ventre
# clair, bosse sur le crane, enorme machoire inferieure en avant, gueule sombre bordee de longues dents crème,
# yeux turquoise lumineux sous des arcades froncees, leurre turquoise lumineux qui pend devant la tete au bout
# d'une tige recourbee, coraux roses et orange et bernacles sur le dos et les flancs, nageoires pectorales en
# eventail, nageoire dorsale a rayons, queue en deux lobes ; points lumineux le long des flancs.
# Usage : exec(open(r"<repo>/tools/blender/monster_common_b.py").read()) puis exec de ce fichier.
import ropilot, bpy, math

PAL_MA = dict(
    skin=dict(color="#1f5a63", noise=0.035, shade=0.16, mottle=("#1a4d56", 0.25, 4), top=0.14),
    skin_dark=dict(color="#143c45", noise=0.03, shade=0.12, top=0.1),
    skin_light=dict(color="#2f7a80", noise=0.03, shade=0.14, top=0.14),
    belly=dict(color="#86b9ad", noise=0.03, shade=0.12, top=0.08, rim=-0.15),
    fin=dict(color="#2a6f8a", noise=0.03, shade=0.08, streaks=("#3b88a2", 0.3, "v")),
    fin_light=dict(color="#4fa0b8", noise=0.03, shade=0.08, streaks=("#6cb6ca", 0.3, "v")),
    ray=dict(color="#173f52", noise=0.02, shade=0.1),
    tooth=dict(color="#f2ecd8", noise=0.02, shade=0.14, top=0.1),
    gum=dict(color="#6a1f3a", noise=0.03, shade=0.12),
    mouth=dict(color="#24081a", noise=0.02, shade=0.1),
    coral=dict(color="#f06a8c", noise=0.035, shade=0.14, top=0.15),
    coral_dark=dict(color="#c2456a", noise=0.03, shade=0.12),
    coral_or=dict(color="#ff9a5a", noise=0.03, shade=0.14, top=0.15),
    barn=dict(color="#d9cfb6", noise=0.035, shade=0.16, top=0.12),
    barn_dark=dict(color="#6f6658", noise=0.02),
    eye="#0a1418", shine="#ffffff",
    glow=dict(color="#18c8b4", glow=True),
)
MRA = dict(mirror=True)


def coral_ma(m, name, base, branches, w, role, **kw):
    # corail branchu : un tronc et des branches qui s'affinent, bout arrondi
    for k, (a, b) in enumerate(branches):
        m.beam(f"{name}{k}", start=add_mb(base, a), end=add_mb(base, b), role=role, width=w * (1 - 0.18 * k), depth=w * (1 - 0.18 * k),
               taper=0.7, chamfer=0.08, **kw)


def build_ma(m):
    # ---- corps : grosse masse arrondie, bosse du crane, arriere qui s'affine vers la queue
    m.box("Body", size=(10.0, 9.4, 8.8), at=(0, 0.3, 7.4), role="skin", chamfer=3.0, taper=(0.8, 0.88), faces={"bottom": "belly"})
    m.box("Hump", size=(7.6, 7.0, 2.4), at=(0, 1.0, 11.4), role="skin_light", chamfer=1.1, taper=(0.7, 0.75))
    m.beam("Rear", start=(0, 4.0, 7.5), end=(0, 7.0, 7.9), role="skin", width=6.8, depth=7.0, taper=0.48, chamfer=1.1)
    m.box("Peduncle", size=(2.4, 1.4, 2.8), at=(0, 7.3, 7.9), role="skin_dark", chamfer=0.5)
    # queue a deux lobes (eventails qui s'elargissent), rayons sombres
    m.box("TailUp", size=(0.6, 2.0, 3.6), at=(0, 8.3, 8.6), role="fin", taper=(1, 1.9), rot=(-42, 0, 0), pivot="bottom")
    m.box("TailLo", size=(0.6, 2.0, 3.2), at=(0, 8.3, 7.2), role="fin", taper=(1, 1.9), rot=(-138, 0, 0), pivot="bottom")
    m.box("TailCore", size=(0.8, 1.6, 2.2), at=(0, 8.1, 7.9), role="skin_dark", chamfer=0.2)
    # ---- grande gueule : machoire inferieure en avant, levre du haut, interieur sombre, gencives, dents
    m.box("Jaw", size=(10.2, 5.2, 3.4), at=(0, -3.0, 2.5), role="skin", chamfer=1.6, taper=(0.86, 0.72), rot=(180, 0, 0), faces={"top": "belly"})
    m.beam("Chin", start=(0, -1.2, 2.4), end=(0, 3.6, 4.2), role="skin", width=9.2, depth=3.2, taper=0.62, chamfer=1.1)
    # opercules (plaques des ouies) et epines le long de la machoire
    m.box("Operc_L", size=(0.7, 3.4, 4.4), at=(-4.95, -0.6, 6.8), role="skin_light", chamfer=0.3, taper=(1, 0.7), rot=(0, -8, 0), **MRA)
    for k, (y, z) in enumerate(((-4.6, 2.2), (-2.6, 2.0), (-0.6, 2.4))):
        m.prism(f"JawSpine{k}_L", radius=0.32, height=1.1, at=(-5.3, y, z), role="skin_dark", sides=4, taper=0, rot=(0, -95, 0), **MRA)
    m.box("JawLip", size=(9.6, 1.4, 1.8), at=(0, -5.15, 3.95), role="skin_light", chamfer=0.6, taper=(0.9, 1))
    m.box("MouthIn", size=(8.4, 1.0, 4.8), at=(0, -4.45, 6.1), role="mouth")
    m.box("Tongue", size=(6.0, 2.0, 0.7), at=(0, -4.4, 4.6), role="gum", chamfer=0.25)
    m.box("UpperLip", size=(9.6, 1.8, 1.7), at=(0, -4.6, 9.1), role="skin_light", chamfer=0.65, taper=(0.86, 1))
    m.box("GumUp", size=(8.4, 0.6, 0.45), at=(0, -5.35, 8.3), role="gum")
    m.beam("LipCorner_L", start=(-4.3, -4.9, 8.9), end=(-4.7, -5.2, 4.1), role="skin_light", width=1.5, depth=1.6, chamfer=0.45, **MRA)
    m.box("GumLo", size=(8.4, 0.6, 0.45), at=(0, -5.65, 4.75), role="gum")
    for k, x in enumerate((-3.6, -2.0, -0.7, 0.7, 2.0, 3.6)):
        L = 2.9 if k in (1, 4) else (2.2 if k in (0, 5) else 1.7)
        m.prism(f"ToothUp{k}", radius=0.36 if L > 2 else 0.3, height=L, at=(x, -5.45, 8.3 - L / 2), role="tooth", sides=4, taper=0,
                rot=(180, 0, 0), solo=True)
    for k, x in enumerate((-4.1, -2.8, -1.35, 0.0, 1.35, 2.8, 4.1)):
        L = 2.4 if k in (1, 5) else (1.5 if k == 3 else 1.8)
        m.prism(f"ToothLo{k}", radius=0.34 if L > 2 else 0.28, height=L, at=(x, -5.75, 4.75 + L / 2), role="tooth", sides=4, taper=0, solo=True)
    # ---- yeux turquoise lumineux, pupilles, reflets, arcades froncees
    m.box("EyeRim_L", size=(1.9, 0.5, 1.7), at=(-2.7, -4.05, 10.6), role="skin_dark", chamfer=0.25, rot=(0, -12, 0), **MRA)
    m.box("Iris_L", size=(1.4, 0.3, 1.25), at=(-2.7, -4.25, 10.55), role="glow", rot=(0, -12, 0), **MRA)
    m.box("Pupil_L", size=(0.42, 0.1, 0.85), at=(-2.62, -4.42, 10.5), role="eye", rot=(0, -12, 0), **MRA)
    m.box("Shine_L", size=(0.3, 0.06, 0.3), at=(-3.0, -4.46, 10.85), role="shine", **MRA)
    m.beam("Brow_L", start=(-3.9, -4.0, 11.75), end=(-1.5, -4.45, 11.3), role="skin_dark", width=0.55, depth=0.7, chamfer=0.1, **MRA)
    # ---- leurre : tige recourbee qui part du crane, pend devant la gueule, ampoule turquoise lumineuse
    LP = [(0, -1.4, 12.2), (0, -2.6, 13.9), (0, -4.6, 14.6), (0, -6.4, 14.1), (0, -7.3, 12.6), (0, -7.5, 11.3)]
    curve_mb(m, "Stalk", LP, [0.75, 0.62, 0.52, 0.44, 0.38, 0.32], [0.75, 0.62, 0.52, 0.44, 0.38, 0.32], ["skin_light", "skin", "skin_light"],
             ext=0.1, chamf=0.1, solo=True)
    m.box("LureCap", size=(1.1, 1.1, 0.55), at=(0, -7.5, 11.1), role="skin_dark", chamfer=0.15, taper=(0.6, 0.6), rot=(180, 0, 0), solo=True)
    m.crystal("Lure", radius=1.1, height=2.2, at=(0, -7.5, 8.8), role="glow", sides=6, tip=0.35, base_tip=0.3, taper=1.0, solo=True)
    for k, (dx, dz) in enumerate(((-1.0, 0.6), (1.0, 0.6))):
        m.beam(f"LureFrond{k}", start=(0, -7.5, 10.6), end=(dx, -7.5, 10.6 - dz - 0.6), role="fin_light", width=0.22, depth=0.22, taper=0.5, solo=True)
    # ---- nageoires pectorales en eventail, rayons
    m.box("PecBase_L", size=(1.4, 2.2, 2.2), at=(-4.8, 0.4, 4.8), role="skin_dark", chamfer=0.4, **MRA)
    for k, (a, w) in enumerate(((-100, 1.6), (-122, 1.9), (-146, 1.6))):
        m.box(f"Pec{k}_L", size=(w, 0.45, 3.6 - 0.3 * abs(k - 1)), at=(-5.0, 0.4 + (k - 1) * 0.3, 4.8), role="fin" if k != 1 else "fin_light",
              taper=(1.6, 1), rot=(0, a, 0), pivot="bottom", **MRA)
    # ---- nageoire dorsale : rayons sombres et membrane
    m.box("Dorsal", size=(0.5, 4.6, 2.0), at=(0, 4.2, 11.1), role="fin_light", taper=(1, 0.55), shear=(0, 1.2), rot=(-14, 0, 0))
    for k, (y, z, h) in enumerate(((2.3, 11.6, 2.4), (3.6, 11.3, 2.7), (4.9, 10.9, 2.4), (6.1, 10.3, 1.8))):
        m.beam(f"DorsalRay{k}", start=(0, y, z - 0.6), end=(0, y + 1.0, z + h - 0.6), role="ray", width=0.3, depth=0.35, taper=0.4)
    # ---- ouies, points lumineux des flancs
    for k in range(3):
        m.beam(f"Gill{k}_L", start=(-4.75, 0.6 + 0.9 * k, 5.4), end=(-4.55, 1.2 + 0.9 * k, 8.6), role="skin_dark", width=0.28, depth=0.32, **MRA)
    for k, (y, z) in enumerate(((3.2, 6.1), (4.6, 6.4), (6.0, 6.8))):
        m.box(f"Photo{k}_L", size=(0.2, 0.55, 0.55), at=(-4.1 + 0.55 * k - (0.35 if k == 0 else 0), y, z), role="glow", rot=(45, 0, 0), **MRA)
    # ---- coraux et bernacles sur le dos et les flancs
    coral_ma(m, "CoralA", (-2.4, 0.2, 12.2), [((0, 0, -0.3), (-0.2, 0.2, 1.8)), ((-0.1, 0.1, 1.0), (-1.2, 0.0, 2.3)), ((0, 0.1, 0.7), (0.9, 0.4, 1.9))],
             0.6, "coral", solo=True)
    coral_ma(m, "CoralB", (2.6, 2.4, 11.6), [((0, 0, -0.3), (0.3, 0.2, 1.6)), ((0.1, 0.1, 0.8), (1.2, 0.5, 1.9)), ((0, 0, 0.6), (-0.6, 0.9, 1.6))],
             0.55, "coral_or", solo=True)
    coral_ma(m, "CoralC", (-4.3, 3.2, 9.6), [((0.3, 0, -0.2), (-0.9, 0.2, 1.3)), ((-0.3, 0.1, 0.7), (-1.2, 0.8, 1.6))], 0.5, "coral_dark", solo=True)
    coral_ma(m, "CoralD", (4.3, -1.0, 9.8), [((-0.3, 0, -0.2), (0.9, -0.2, 1.3)), ((0.3, -0.1, 0.6), (1.0, 0.6, 1.5))], 0.48, "coral", solo=True)
    m.box("CoralPad", size=(1.6, 1.4, 0.5), at=(-2.4, 0.2, 12.4), role="coral_dark", chamfer=0.15, solo=True)
    for k, (p, r, rot) in enumerate((((1.2, -0.8, 12.5), 0.55, (0, 0, 0)), ((-0.6, 2.8, 12.4), 0.45, (0, 0, 0)), ((0.4, 4.2, 11.9), 0.4, (-20, 0, 0)),
                                     ((-4.55, -1.6, 9.4), 0.5, (0, -70, 0)), ((4.6, 1.6, 9.0), 0.45, (0, 70, 0)), ((-4.8, 2.4, 7.3), 0.4, (0, -88, 0)),
                                     ((3.6, -3.4, 10.6), 0.4, (40, 30, 0)), ((-1.8, -3.8, 11.0), 0.38, (50, -10, 0)))):
        m.prism(f"Barn{k}", radius=r, height=r * 1.1, at=p, role="barn", sides=6, taper=0.55, rot=rot, solo=True)
        n = (math.sin(math.radians(rot[1])) * math.cos(math.radians(rot[0])), -math.sin(math.radians(rot[0])),
             math.cos(math.radians(rot[1])) * math.cos(math.radians(rot[0])))
        m.prism(f"BarnH{k}", radius=r * 0.3, height=0.15, at=add_mb(p, n, r * 0.52), role="barn_dark", sides=6, rot=rot, solo=True)
    coral_ma(m, "CoralE", (-4.6, 0.6, 6.0), [((0.3, 0, 0), (-1.4, -0.1, 0.9)), ((0.0, 0, 0.3), (-1.2, 0.4, -0.8)), ((-0.6, 0, 0.4), (-1.3, -0.5, 1.6))],
             0.5, "coral_or", solo=True)
    coral_ma(m, "CoralF", (4.6, 3.0, 6.4), [((-0.3, 0, 0), (1.4, 0.2, 1.0)), ((0.0, 0, 0.2), (1.2, -0.4, -0.7))], 0.5, "coral", solo=True)
    coral_ma(m, "CoralG", (0.6, 5.2, 10.6), [((0, -0.2, -0.3), (0.2, 0.3, 1.5)), ((0.1, 0, 0.6), (1.1, 0.4, 1.5))], 0.45, "coral_dark", solo=True)
    for k, (p, r, rot) in enumerate((((-4.75, -0.4, 4.2), 0.42, (0, -95, 0)), ((4.75, -0.8, 7.6), 0.42, (0, 92, 0)), ((4.7, 3.4, 8.8), 0.36, (0, 88, 0)),
                                     ((-3.0, 4.6, 10.2), 0.4, (-40, -30, 0)), ((2.4, -2.4, 12.1), 0.34, (20, 10, 0)), ((-3.4, 6.0, 7.2), 0.36, (0, -60, 0)))):
        m.prism(f"BarnS{k}", radius=r, height=r * 1.1, at=p, role="barn", sides=6, taper=0.55, rot=rot, solo=True)
    # taches claires et sombres sur le corps (peinture)
    for k, (f, u, v, r, c) in enumerate((("left", -1.5, 1.0, 0.9, "#2a6e75"), ("left", 1.8, -0.6, 0.7, "#163f48"), ("right", 1.4, 0.8, 0.8, "#2a6e75"),
                                       ("right", -1.9, -0.8, 0.7, "#163f48"), ("top", -1.0, -1.5, 1.0, "#2a6e75"), ("top", 1.4, 1.2, 0.8, "#163f48"))):
        m.blob("Body", f, (u, v), r, c, seed=k)
    return m


AA = ropilot.model("M_AbyssAngler", px=8, reset=True)
AA.reference(refs_mb("GenM_AbyssAngler"))
AA.palette(**PAL_MA)
build_ma(AA)
print(AA.build())
print(AA.compare(image=False)["report"])
