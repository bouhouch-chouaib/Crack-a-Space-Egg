# Lollipop Snail (R11_T4, Epic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R11_Refs/Ref_R11_T4_*.png)
# Escargot vert menthe joyeux : pied long qui s'affine en queue, cou epais penche vers l'avant, grosse tete ronde,
# grands yeux a reflets, sourire et langue ; coquille = grande sucette : disque blanc a spirale rose peinte des
# deux cotes, bord raye rose et blanc, moyeu rose et coeur lumineux, baton blanc raye qui sort en bas a l'arriere ;
# antennes a billes de sucre lumineuses ; vermicelles multicolores sur les flancs, gommes en gouttes sur la queue.
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R11_Refs")
REF4 = {v: os.path.join(R, f"Ref_R11_T4_{v}.png") for v in ("front", "left", "back", "top")}
PAL4 = dict(
    slug=dict(color="#4fd6a0", noise=0.03, shade=0.16, mottle=("#5fe0ae", 0.25, 4), top=0.14),
    slug_dark=dict(color="#2aa883", noise=0.03, shade=0.12),
    slug_light=dict(color="#8cebdc", noise=0.03, shade=0.08, top=0.08),
    candy=dict(color="#fff6ec", noise=0.02, shade=0.08, top=0.06),
    pink=dict(color="#ff5fae", noise=0.025, shade=0.1, top=0.1),
    pink_dark=dict(color="#e0408e", noise=0.025),
    stick=dict(color="#fff6ec", noise=0.02, shade=0.1, streaks=("#efe2d2", 0.3, "v")),
    cherry="#e8344e", lemon="#ffe66b", grape="#9b6be0", sky="#7fd0ff",
    eye="#22162a", white="#ffffff", blush="#ff9ec8", tongue="#ff7aa0",
    glow=dict(color="#ff4fa3", glow=True),
)
SX, SY, SZ, SR = 0.0, 0.6, 2.32, 2.0     # centre et rayon du disque de la sucette
ST = 1.8                                 # epaisseur de la sucette
HZ = 2.5                                 # hauteur du centre de la tete


def spiral_pts(r0=0.45, r1=1.8, turns=2.25, n=240, phase=0.0):
    pts = []
    for i in range(n + 1):
        t = i / n
        a = phase + t * turns * 2 * math.pi
        r = r0 + (r1 - r0) * t
        pts.append((r * math.cos(a), r * math.sin(a)))
    return pts


def build_t4(m):
    MR = dict(mirror=True)
    # pied de limace, semelle sombre, queue qui s'affine
    m.box("Body", size=(1.9, 4.3, 0.7), at=(0, 0.15, 0.35), role="slug", chamfer=0.3, taper=(0.92, 1), faces={"bottom": "slug_dark"})
    m.box("Belly", size=(1.96, 3.8, 0.2), at=(0, 0.1, 0.1), role="slug_dark", chamfer=0.08)
    m.beam("Tail", start=(0, 1.95, 0.35), end=(0, 3.25, 0.17), role="slug", width=1.6, depth=0.6, taper=0.35, chamfer=0.16)
    # cou epais penche vers l'avant, grosse tete ronde
    m.beam("Neck", start=(0, -1.3, 0.55), end=(0, -2.25, HZ - 0.55), role="slug", width=1.56, depth=1.2, taper=0.9, chamfer=0.36)
    m.box("Head", size=(1.96, 1.56, 1.56), at=(0, -2.4, HZ), role="slug", chamfer=0.42, taper=(0.88, 0.9))
    fy = -2.4 - 0.78
    m.box("Eye_L", size=(0.4, 0.08, 0.54), at=(-0.44, fy + 0.02, HZ + 0.2), role="eye", chamfer=0.06, **MR)
    m.box("Shine_L", size=(0.18, 0.05, 0.18), at=(-0.51, fy - 0.025, HZ + 0.34), role="white", **MR)
    m.box("Shine2_L", size=(0.08, 0.05, 0.08), at=(-0.36, fy - 0.025, HZ + 0.05), role="white", **MR)
    # antennes a billes de sucre lumineuses
    m.beam("Antenna_L", start=(-0.36, -2.36, HZ + 0.62), end=(-0.7, -2.62, HZ + 1.28), role="slug_dark", width=0.18, depth=0.18, **MR)
    m.box("AntBall_L", size=(0.36, 0.36, 0.36), at=(-0.72, -2.64, HZ + 1.36), role="glow", chamfer=0.1, **MR)
    # coquille sucette : disque, bord raye, moyeu rose, coeur lumineux
    side_faces = {f"side{k}": ("pink" if k % 2 else "candy") for k in range(12)}
    m.prism("Shell", radius=SR, height=ST, at=(SX, SY, SZ), role="candy", sides=12, rot=(0, 90, 0), faces=side_faces)
    m.prism("ShellHub", radius=0.42, height=ST + 0.12, at=(SX, SY, SZ), role="pink", sides=8, rot=(0, 90, 0), turn=22.5)
    m.prism("ShellGem", radius=0.2, height=ST + 0.2, at=(SX, SY, SZ), role="glow", sides=8, rot=(0, 90, 0), turn=22.5)
    # baton de la sucette qui sort en bas a l'arriere
    m.beam("Stick", start=(0, 2.0, 1.66), end=(0, 3.35, 1.0), role="stick", width=0.28, depth=0.28, chamfer=0.05)
    # cerise confite posee sur la sucette (reflet blanc, queue chocolat)
    ctop = SZ + SR * math.cos(math.radians(15))
    m.box("Cherry", size=(0.56, 0.56, 0.5), at=(0, SY - 0.15, ctop + 0.2), role="cherry", chamfer=0.17)
    m.box("CherryShine", size=(0.12, 0.05, 0.12), at=(-0.12, SY - 0.45, ctop + 0.3), role="white", solo=True)
    m.beam("CherryStem", start=(0, SY - 0.12, ctop + 0.4), end=(0, SY + 0.12, ctop + 0.82), role="#6b3a26", width=0.09, depth=0.09)
    # gommes en gouttes sur la queue
    m.prism("Gumdrop1", radius=0.2, height=0.24, at=(0, 2.62, 0.47), role="lemon", sides=6, taper=0.55)
    m.prism("Gumdrop2", radius=0.15, height=0.2, at=(0, 2.98, 0.33), role="grape", sides=6, taper=0.55)
    return m


def paint_t4(m):
    sp = spiral_pts()
    for face in ("top", "bottom"):   # les deux faces du disque (prisme tourne de 90 degres)
        m.line("Shell", face, sp, "pink", 3)
    m.rect("Head", "front", (-0.5, -0.2), (0.22, 0.1), "blush")
    m.rect("Head", "front", (0.5, -0.2), (0.22, 0.1), "blush")
    m.stamp("Head", "front", (0, -0.24), ["K....K", ".KKKK.", "..TT.."], {"K": "eye", "T": "tongue"})
    cols = ("cherry", "lemon", "grape", "sky", "white")
    k = 0
    for face, sg in (("left", 1), ("right", -1)):
        for (u, v) in ((1.7, 0.08), (1.1, -0.08), (0.5, 0.08), (-0.1, -0.08), (-0.7, 0.08), (-1.3, -0.08)):
            m.rect("Body", face, (sg * u, v), (0.18, 0.08), cols[k % 5]); k += 1
    for (u, v) in ((-0.45, 0.1), (0.4, -0.15), (0.0, 0.3)):
        m.rect("Neck", "front", (u, v), (0.16, 0.08), cols[k % 5]); k += 1
    for v in (-0.4, 0.0, 0.4):
        m.line("Stick", "left", [(v - 0.1, -0.15), (v + 0.1, 0.15)], "pink", 1)
        m.line("Stick", "right", [(v - 0.1, -0.15), (v + 0.1, 0.15)], "pink", 1)
    return m


GROUPS_T4 = {'Head': ['Head', 'Eye_*', 'Shine*', 'Antenna_*', 'AntBall_*'],
             'Tail': ['Tail', 'Gumdrop*']}


# compare() : face 0.88, dos 0.88, gauche 0.84, dessus 0.73 avant la cerise ; avec la cerise (piece la plus haute,
# donc toutes les vues sont remises a l'echelle) : 0.65 / 0.65 / 0.67 / 0.73. Dessus plus etroit que la reference
# (sucette de 1,8 d'epaisseur au lieu de 2,3 : au-dela elle se lit comme une meule de fromage).
# --- suite : exec(rigjoin.py), rig_join("R11_T4", GROUPS_T4), save R11_T4_rig.blend, import -> Work_R11_T4,
# CreatureRig.Install(workspace.Work_R11_T4, "R11_T4", nil, true), puis joints corriges dans le repere du Core :
# Head (0, 1.95, -2.3) (haut du cou), Tail (0, 0.35, 1.85). Le coeur de la sucette devient Body2 (Neon),
# les billes des antennes Head__Glow (Follow = Head).


def make_t4(save=True):
    m4 = ropilot.model("R11_T4", px=8, reset=True)
    m4.reference(REF4)
    m4.palette(**PAL4)
    build_t4(m4); paint_t4(m4)
    print(m4.build()); print(m4.check()); print(m4.compare()["report"])
    ropilot.check_model(collection="R11_T4", max_lines=6)
    if save:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R11_T4.blend"), copy=True)
    return m4
