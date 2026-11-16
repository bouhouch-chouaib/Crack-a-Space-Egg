# Donut Turtle (R11_T5, Legendary) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R11_Refs/Ref_R11_T5_*.png)
# Tortue massive a peau menthe dont la carapace est un enorme donut : anneau de pate doree (8 segments
# chanfreines autour d'un vrai trou), glacage rose qui coule en gouttes sur les flancs, vermicelles de couleur,
# cerise posee sur le glacage, bord de carapace en biscuit ; tete ronde menthe qui sort sous le donut (yeux
# separes a reflets, joues roses, sourire malicieux), quatre pattes epaisses a ongles creme, petite queue.
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R11_Refs")
REF5 = {v: os.path.join(R, f"Ref_R11_T5_{v}.png") for v in ("front", "left", "back", "top")}
PAL5 = dict(
    skin=dict(color="#8cebdc", noise=0.03, shade=0.16, mottle=("#7fdccd", 0.2, 4), top=0.12),
    skin_dark=dict(color="#3fbfa8", noise=0.03, shade=0.12),
    skin_light=dict(color="#c4f7ee", noise=0.02, shade=0.1, top=0.1),
    dough=dict(color="#e8a85c", noise=0.035, shade=0.18, mottle=("#dc9a4c", 0.25, 4), top=0.1),
    dough_dark=dict(color="#b8763a", noise=0.03, shade=0.12),
    icing=dict(color="#ff8cc8", noise=0.025, shade=0.12, top=0.14, rim=-0.12),
    icing_light=dict(color="#ffc4e1", noise=0.02, shade=0.08, top=0.1),
    plastron=dict(color="#ffe66b", noise=0.03, shade=0.12, top=0.1),
    cream=dict(color="#fff6ec", noise=0.02, shade=0.1, top=0.08),
    choco=dict(color="#6b3a26", noise=0.03, shade=0.12),
    cherry=dict(color="#e8344e", noise=0.02, shade=0.14, top=0.15, rim=-0.2),
    s_lemon="#ffe66b", s_mint="#3fbfa8", s_blue="#7fd0ff", s_grape="#9b6be0", s_cream="#fff6ec", s_cherry="#e8344e",
    eye="#24161c", shine="#ffffff", blush="#ff8cc8", mouth="#24161c",
    glow=dict(color="#ff5cb0", glow=True),
)
DC = (0.0, 0.9)            # centre du donut (x, y)
RD = 3.05                  # rayon moyen de l'anneau
NSEG = 12
SPR = [  # vermicelles : (angle deg, rayon, rotation, couleur)
    (10, 3.4, 30, "s_lemon"), (35, 2.7, -40, "s_blue"), (58, 3.6, 70, "s_grape"), (80, 2.6, 10, "s_mint"),
    (103, 3.5, -60, "s_cream"), (128, 2.8, 45, "s_cherry"), (150, 3.6, -15, "s_lemon"), (172, 2.6, 80, "s_blue"),
    (196, 3.5, 20, "s_mint"), (220, 2.7, -70, "s_grape"), (242, 3.6, 40, "s_cherry"), (265, 2.6, -30, "s_cream"),
    (288, 3.5, 65, "s_blue"), (312, 2.8, -10, "s_lemon"), (334, 3.55, -55, "s_mint"), (355, 2.65, 15, "s_grape"),
    (22, 2.2, -5, "s_cherry"), (140, 2.15, 60, "s_mint"), (205, 2.2, 0, "s_lemon"), (325, 2.2, 35, "s_blue"),
]
DRIPS = [(-90, 0.9), (-62, 0.55), (-30, 1.0), (0, 0.6), (35, 0.95), (68, 0.5), (90, 0.85), (125, 0.6), (155, 1.0),
         (180, 0.55), (212, 0.9), (245, 0.6), (270, 0.8)]


def ring_xy(a_deg, r):
    a = math.radians(a_deg)
    return DC[0] + r * math.cos(a), DC[1] + r * math.sin(a)


def build_t5(m):
    MR = dict(mirror=True)
    # ---- corps menthe sous la carapace, plastron creme
    m.box("Body", size=(6.0, 7.4, 1.9), at=(0, 0.6, 2.3), role="skin", chamfer=0.6)
    m.box("Plastron", size=(5.6, 7.0, 0.7), at=(0, 0.6, 1.35), role="plastron", chamfer=0.2)
    # ---- bord de carapace en biscuit (polygone a 12 cotes)
    m.prism("ShellRim", radius=4.7, height=0.55, at=(DC[0], DC[1], 2.85), role="dough_dark", sides=12, turn=15)
    # ---- donut : anneau de pate (12 segments, ventre plus large au milieu), glacage rose bombe par-dessus,
    # vrai trou au centre
    t15 = math.tan(math.radians(15))
    for k in range(NSEG):
        a = k * 360 / NSEG
        x, y = ring_xy(a, RD)
        m.box(f"DoughLow{k}", size=(2.3, 2 * (RD + 1.15) * t15 + 0.2, 1.0), at=(x, y, 3.45), role="dough_dark", chamfer=0.3, rot=(0, 0, a), solo=True)
        m.box(f"Dough{k}", size=(2.95, 2 * (RD + 1.48) * t15 + 0.2, 1.2), at=(x, y, 4.3), role="dough", chamfer=0.45, rot=(0, 0, a), solo=True)
        m.box(f"Icing{k}", size=(3.05, 2 * (RD + 1.53) * t15 + 0.2, 1.95), at=(x, y, 5.65), role="icing", chamfer=0.55, taper=(0.72, 1), rot=(0, 0, a), solo=True)
    # fond du trou : pate sombre (on voit le trou d'en haut)
    m.prism("HoleFloor", radius=1.4, height=0.3, at=(DC[0], DC[1], 3.4), role="dough_dark", sides=12, turn=15)
    # gouttes de glacage sur le flanc exterieur
    for k, (a, ln) in enumerate(DRIPS):
        x, y = ring_xy(a, RD + 1.56)
        m.beam(f"Drip{k}", start=(x, y, 5.05), end=(x, y, 4.75 - ln), role="icing", width=0.8, depth=0.3, taper=0.65, chamfer=0.08,
               roll=a, solo=True)
    # vermicelles sur le glacage
    for k, (a, r, t, col) in enumerate(SPR):
        x, y = ring_xy(a, min(max(r, 2.6), 3.45))
        m.box(f"Sprinkle{k}", size=(0.55, 0.16, 0.14), at=(x, y, 6.6), role=col, rot=(0, 0, t), solo=True)
    # cerise posee sur le glacage, a l'avant droit
    cx, cy = ring_xy(-55, RD)
    m.box("Cherry", size=(0.95, 0.95, 0.85), at=(cx, cy, 6.85), role="cherry", chamfer=0.3, solo=True)
    m.box("CherryShine", size=(0.22, 0.06, 0.22), at=(cx - 0.08, cy - 0.49, 6.93), role="shine", solo=True)
    # ---- cou et tete ronde (rig Head)
    m.beam("Neck", start=(0, -2.4, 3.0), end=(0, -4.3, 3.95), role="skin", width=1.8, depth=1.6, chamfer=0.4)
    m.box("Head", size=(3.0, 2.6, 2.3), at=(0, -5.2, 4.2), role="skin", chamfer=0.7, taper=(0.92, 0.92))
    m.box("Muzzle", size=(2.0, 0.5, 0.95), at=(0, -6.55, 3.65), role="skin_light", chamfer=0.22)
    # grands yeux separes qui depassent du haut de la tete : blanc creme, grande pupille, deux reflets ;
    # sourcils droits (regard fier)
    m.box("Eye_L", size=(1.0, 0.45, 1.1), at=(-0.72, -6.3, 4.95), role="cream", chamfer=0.12, **MR)
    m.box("Pupil_L", size=(0.6, 0.08, 0.78), at=(-0.66, -6.55, 4.88), role="eye", **MR)
    m.box("Shine_L", size=(0.24, 0.06, 0.24), at=(-0.76, -6.59, 5.08), role="shine", **MR)
    m.box("Shine2_L", size=(0.12, 0.06, 0.12), at=(-0.52, -6.59, 4.64), role="shine", **MR)
    m.beam("Brow_L", start=(-1.15, -6.25, 5.62), end=(-0.3, -6.25, 5.62), role="skin_dark", width=0.22, depth=0.3, chamfer=0.04, **MR)
    # ---- pattes epaisses (rig LegFL/FR/BL/BR), pieds plus larges, ongles creme
    for n, y in (("LegF", -2.4), ("LegB", 3.75)):
        m.box(n + "_L", size=(2.0, 2.0, 2.4), at=(-3.2, y, 1.45), role="skin", chamfer=0.5, **MR)
        m.box(n + "Foot_L", size=(2.3, 2.3, 0.6), at=(-3.2, y - 0.1, 0.3), role="skin_dark", chamfer=0.18, **MR)
        for k, dx in enumerate((-0.6, 0.0, 0.6)):
            m.box(f"{n}Nail{k}_L", size=(0.42, 0.25, 0.32), at=(-3.2 + dx, y - 1.32, 0.18), role="cream", chamfer=0.05, **MR)
    # ---- petite queue qui s'affine (rig Tail)
    m.beam("Tail", start=(0, 4.0, 2.3), end=(0, 5.8, 1.6), role="skin", width=1.0, depth=0.8, taper=0.25, chamfer=0.1)
    # ---- peinture
    m.rect("Cherry", "top", (0, 0), (0.18, 0.18), "choco")
    m.line("Muzzle", "front", [(-0.45, -0.02), (-0.25, -0.2), (0.25, -0.2), (0.5, 0.06)], "mouth", 1)
    m.rect("Muzzle", "front", (-0.2, 0.25), (0.14, 0.14), "skin_dark")
    m.rect("Muzzle", "front", (0.2, 0.25), (0.14, 0.14), "skin_dark")
    m.rect("Muzzle", "front", (-0.72, 0.0), (0.3, 0.2), "blush")
    m.rect("Muzzle", "front", (0.72, 0.0), (0.3, 0.2), "blush")
    for (u, v, r) in ((0.5, 0.3, 0.3), (-0.4, -0.3, 0.22)):
        m.blob("Head", "left", (u, v), r, "skin_dark", seed=3)
        m.blob("Head", "right", (-u, v), r, "skin_dark", seed=3)
    for (u, v, r) in ((-0.4, 0.3, 0.28), (0.45, 0.1, 0.22), (0.0, -0.45, 0.2)):
        m.blob("Head", "top", (u, v), r, "skin_dark", seed=5)
    for n in ("LegF_L", "LegB_L", "LegF_R", "LegB_R"):
        m.blob(n, "left" if n.endswith("L") else "right", (0.2, 0.3), 0.3, "skin_dark", seed=7)
        m.blob(n, "front", (-0.3, -0.2), 0.22, "skin_dark", seed=9)
    for k in range(4):
        m.line("Plastron", "bottom", [(-2.3, -2.4 + 1.6 * k), (2.3, -2.4 + 1.6 * k)], "dough", 1)
    return m


m5 = ropilot.model("R11_T5", px=8, reset=True)
m5.reference(REF5)
m5.palette(**PAL5)
build_t5(m5)
print(m5.build()); print(m5.check()); print(m5.compare()["report"])
ropilot.check_model(collection="R11_T5", max_lines=8)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R11_T5.blend"), copy=True)


def lg5(n, s):
    return [f"{n}_{s}", f"{n}Foot_{s}", f"{n}Nail*_{s}"]


GROUPS_T5 = {'Head': ['Head', 'Muzzle', 'Eye_*', 'Pupil_*', 'Shine_*', 'Shine2_*', 'Brow_*'],
             'LegFL': lg5('LegF', 'L'), 'LegFR': lg5('LegF', 'R'), 'LegBL': lg5('LegB', 'L'), 'LegBR': lg5('LegB', 'R'),
             'Tail': ['Tail']}
# --- suite : exec(rigjoin.py), rig_join("R11_T5", GROUPS_T5), save R11_T5_rig.blend, import -> Work_R11_T5,
# CreatureRig.Install(workspace.Work_R11_T5, "R11_T5", nil, true), puis joints corriges dans le repere du Core :
# Head (0, 3.7, -3.5) a la base du cou, LegFL/FR (+-3.2, 2.4, -1.95) et LegBL/BR (+-3.2, 2.4, 4.2) a la hanche (au lieu du
# centre de la boite avec les ongles), Tail (0, 2.3, 4.45) a la racine
# compare() final : face 0.86, dos 0.86, gauche 0.83, dessus 0.91 (cerise sans queue : sinon elle fixe l'echelle)
