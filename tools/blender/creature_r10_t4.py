# Clockwork Fox (R10_T4, Epic) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R10_Refs/Ref_R10_T4_*.png)
# Renard en plaques de cuivre, plus elance que la reference (corps et pattes allonges : Epic, « commence a
# impressionner ») : grandes oreilles pointues (rig EarL / EarR), cadran d'horloge sur le poitrail (aiguille
# rouge, centre turquoise lumineux), yeux turquoise lumineux avec pupille et reflet, queue en panache de plaques
# de laiton qui se termine par un bout blanc et un rouage (rig Tail), genoux boulonnes.
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R10_Refs")
REF4 = {v: os.path.join(R, f"Ref_R10_T4_{v}.png") for v in ("front", "left", "back", "top")}
PAL4 = dict(
    copper=dict(color="#c8703a", noise=0.035, shade=0.16, mottle=("#bd6532", 0.2, 4), top=0.14),
    copper_light=dict(color="#e08a4e", noise=0.03, shade=0.12, top=0.12),
    copper_dark=dict(color="#8e4a26", noise=0.03, shade=0.12),
    brass=dict(color="#e0a84a", noise=0.03, shade=0.14, top=0.14, rim=-0.22),
    brass_light=dict(color="#f5cf7a", noise=0.03, shade=0.1, top=0.12, rim=-0.2),
    brass_dark=dict(color="#b8822e", noise=0.03, shade=0.1),
    steel=dict(color="#7c8c9c", noise=0.025, shade=0.12, top=0.12, rim=-0.2),
    steel_dark=dict(color="#3e4a58", noise=0.025, shade=0.1),
    white=dict(color="#f4fbfa", noise=0.02, shade=0.08, top=0.06),
    white_dark=dict(color="#c9dcd9", noise=0.025),
    dial=dict(color="#f7f0dc", noise=0.015, shade=0.06),
    red="#c83a3a", eye="#16202c", shine="#ffffff", blush="#f09a86",
    glow=dict(color="#5ae6d2", glow=True),
)
TAIL = [(1.15, 1.7, 0.0, 0.56), (1.62, 1.5, 0.18, 0.86), (1.98, 1.85, 0.42, 1.04), (2.02, 2.45, 0.58, 0.96), (1.86, 2.95, 0.62, 0.66), (1.66, 3.25, 0.62, 0.18)]


def build_t4(m):
    MR = dict(mirror=True)
    # ---- corps : torse, poitrail bombe, croupe, ventre blanc, arete de laiton
    m.box("Body", size=(1.2, 1.9, 1.0), at=(0, 0.1, 1.6), role="copper", chamfer=0.34, faces={"bottom": "white"})
    m.box("Chest", size=(1.16, 0.85, 1.3), at=(0, -0.68, 1.82), role="copper", chamfer=0.34, taper=(0.9, 0.85))
    m.box("Rump", size=(1.12, 0.7, 0.95), at=(0, 0.88, 1.65), role="copper", chamfer=0.3)
    m.box("Belly", size=(0.8, 1.3, 0.2), at=(0, 0.1, 1.1), role="white", chamfer=0.06)
    m.box("Spine", size=(0.36, 1.7, 0.16), at=(0, 0.2, 2.14), role="brass", chamfer=0.04)
    # ---- cadran d'horloge sur le poitrail : cerclage de laiton, aiguilles, centre lumineux
    m.prism("DialRim", radius=0.44, height=0.12, at=(0, -1.1, 1.78), role="brass", sides=12, rot=(90, 0, 0))
    m.prism("Dial", radius=0.36, height=0.06, at=(0, -1.18, 1.78), role="dial", sides=12, rot=(90, 0, 0))
    m.box("HandH", size=(0.06, 0.04, 0.2), at=(0.05, -1.22, 1.86), role="red", rot=(0, 30, 0), solo=True)
    m.box("HandM", size=(0.05, 0.04, 0.28), at=(-0.08, -1.22, 1.88), role="steel_dark", rot=(0, -35, 0), solo=True)
    m.box("DialPin", size=(0.1, 0.06, 0.1), at=(0, -1.23, 1.78), role="glow")
    # ---- epaulieres de laiton rivetees et petite cle a remonter sur le dos (Epic : un peu d'armure)
    m.box("Pauldron_L", size=(0.2, 0.78, 0.56), at=(-0.66, -0.62, 1.88), role="brass", chamfer=0.06, rot=(0, -12, 0), **MR)
    m.box("PauldronRim_L", size=(0.22, 0.82, 0.12), at=(-0.64, -0.62, 1.66), role="brass_dark", chamfer=0.03, rot=(0, -12, 0), **MR)
    m.prism("KeyCollar", radius=0.18, height=0.16, at=(0, 0.42, 2.24), role="copper", sides=8)
    m.box("KeyShaft", size=(0.1, 0.1, 0.54), at=(0, 0.42, 2.48), role="steel", chamfer=0.02)
    m.box("KeyHub", size=(0.14, 0.2, 0.18), at=(0, 0.42, 2.76), role="brass_dark", chamfer=0.04)
    for nm, dy in (("KeyWingF", -0.22), ("KeyWingB", 0.22)):
        m.prism(nm, radius=0.2, height=0.1, at=(0, 0.42 + dy, 2.88), role="brass_light", sides=6, rot=(0, 90, 0), turn=30)
    # ---- cou et collier de laiton
    m.box("Neck", size=(0.9, 0.7, 0.8), at=(0, -0.82, 2.42), role="copper_light", chamfer=0.2)
    m.box("Collar", size=(1.02, 0.82, 0.22), at=(0, -0.82, 2.3), role="brass", chamfer=0.08)
    # ---- tete : large, joues blanches en pointe, museau fin
    m.box("Head", size=(1.7, 1.3, 1.2), at=(0, -1.0, 3.0), role="copper", chamfer=0.38, taper=(0.86, 0.9))
    m.box("Jaw", size=(1.5, 0.8, 0.5), at=(0, -1.18, 2.58), role="white", chamfer=0.16, taper=(0.8, 0.9))
    m.box("Snout", size=(0.72, 0.75, 0.48), at=(0, -1.85, 2.68), role="white", chamfer=0.14, axis="y", taper=(0.5, 0.6))
    m.box("SnoutTop", size=(0.52, 0.72, 0.2), at=(0, -1.84, 2.82), role="copper", chamfer=0.05, axis="y", taper=(0.5, 0.6))
    m.box("Nose", size=(0.26, 0.18, 0.2), at=(0, -2.22, 2.76), role="steel_dark", chamfer=0.04)
    m.prism("ForeBolt", radius=0.13, height=0.14, at=(0, -1.15, 3.58), role="brass", sides=6)
    # yeux turquoise lumineux : iris, pupille haute, reflet (pas de cadre : jamais l'air de lunettes)
    m.box("Eye_L", size=(0.42, 0.12, 0.5), at=(-0.5, -1.6, 3.15), role="eye", chamfer=0.08, **MR)
    m.box("Iris_L", size=(0.28, 0.12, 0.28), at=(-0.49, -1.66, 3.08), role="glow", chamfer=0.04, **MR)
    m.box("Shine_L", size=(0.14, 0.06, 0.14), at=(-0.58, -1.68, 3.29), role="shine", **MR)
    m.box("Shine2_L", size=(0.07, 0.06, 0.07), at=(-0.42, -1.735, 3.02), role="shine", **MR)
    # ---- grandes oreilles pointues ecartees (rig EarL / EarR)
    m.box("Ear_L", size=(1.0, 0.36, 1.5), at=(-0.6, -0.85, 3.42), role="copper", taper=(0.06, 0.4), chamfer=0.04, pivot="bottom", rot=(0, -26, 0), **MR)
    m.box("EarIn_L", size=(0.62, 0.12, 1.0), at=(-0.62, -1.06, 3.5), role="white", taper=(0.06, 1), pivot="bottom", rot=(0, -26, 0), **MR)
    m.box("EarBolt_L", size=(0.34, 0.46, 0.24), at=(-0.6, -0.85, 3.5), role="brass", chamfer=0.05, **MR)
    # ---- pattes longues : cuisse de cuivre, moyeu boulonne, genou de laiton, tibia d'acier, patte sombre
    for n, y, hz in (("LegF", -0.58, 1.45), ("LegB", 0.74, 1.45)):
        m.box(n + "Up_L", size=(0.42, 0.52, 0.62), at=(-0.42, y, hz - 0.25), role="copper", chamfer=0.1, **MR)
        m.prism(n + "Hub_L", radius=0.24, height=0.16, at=(-0.62, y, hz - 0.05), role="steel", sides=8, rot=(0, 90, 0), **MR)
        m.prism(n + "Bolt_L", radius=0.1, height=0.06, at=(-0.72, y, hz - 0.05), role="brass_light", sides=6, rot=(0, 90, 0), **MR)
        m.box(n + "Knee_L", size=(0.4, 0.42, 0.22), at=(-0.42, y, 0.8), role="brass", chamfer=0.05, **MR)
        m.box(n + "Shin_L", size=(0.3, 0.34, 0.62), at=(-0.42, y, 0.46), role="steel_dark", chamfer=0.06, **MR)
        m.box(n + "Paw_L", size=(0.42, 0.56, 0.2), at=(-0.42, y - 0.06, 0.1), role="copper_dark", chamfer=0.06, **MR)
    # ---- queue en panache (rig Tail) : grosses plaques de laiton recourbees vers le haut, bagues sombres,
    # bout blanc ; rouage boulonne sur le flanc
    m.box("TailRoot", size=(0.66, 0.86, 0.66), at=(0, 1.38, 2.04), role="copper_dark", chamfer=0.1, rot=(-35, 0, 0))
    P = [(0.0, 1.05, 1.95), (0.0, 1.72, 2.22), (0.0, 2.12, 2.92), (0.0, 2.16, 3.5), (0.0, 1.9, 4.3)]
    W = [0.62, 1.0, 1.06, 0.9, 0.12]
    roles = ("brass", "brass_light", "white", "white")
    for i in range(4):
        (x0, y0, z0), (x1, y1, z1) = P[i], P[i + 1]
        e = 0.1 if i < 3 else 0.0
        m.beam(f"Tail{i}", start=(x0 - (x1 - x0) * e, y0 - (y1 - y0) * e, z0 - (z1 - z0) * e), end=(x1 + (x1 - x0) * e, y1 + (y1 - y0) * e, z1 + (z1 - z0) * e),
               role=roles[i], width=W[i], depth=W[i] * 0.9, taper=W[i + 1] / W[i], chamfer=0.1 if i < 3 else 0.06, solo=True)
    for i in (1, 2, 3):
        x, y, z = P[i]
        x1, y1, z1 = P[i + 1]
        m.beam(f"TailBand{i}", start=(x, y, z), end=(x + (x1 - x) * 0.1, y + (y1 - y) * 0.1, z + (z1 - z) * 0.1),
               role="brass_dark" if i < 2 else "white_dark", width=W[i] * 1.07, depth=W[i] * 0.97, chamfer=0.1, solo=True)
    gx, gy, gz = 0.5, (P[1][1] + P[2][1]) / 2 + 0.02, (P[1][2] + P[2][2]) / 2
    m.prism("Gear", radius=0.46, height=0.24, at=(gx, gy, gz), role="brass_light", sides=8, rot=(0, 90, 0), turn=22.5, solo=True)
    for k in (0, 1, 2, 5, 7):  # les autres dents s'enfoncent dans la queue
        a = math.radians(k * 45)
        m.box(f"GearTooth{k}", size=(0.4, 0.16, 0.16), at=(gx - 0.06, gy + math.cos(a) * 0.49, gz + math.sin(a) * 0.49), role="brass_dark", rot=(k * 45, 0, 0), solo=True)
    m.prism("GearHub", radius=0.14, height=0.36, at=(gx + 0.02, gy, gz), role="copper", sides=6, rot=(0, 90, 0), solo=True)
    # ---- peinture : plaques rivetees, ventre, joues, cadran
    for face, sg in (("left", 1), ("right", -1)):
        m.line("Body", face, [(sg * 0.35, 0.4), (sg * 0.35, -0.4)], "copper_dark", 1)
        m.line("Body", face, [(sg * -0.35, 0.4), (sg * -0.35, -0.4)], "copper_dark", 1)
        for (u, v) in ((0.5, 0.3), (0.2, 0.3), (-0.2, 0.3), (-0.5, 0.3)):
            m.rect("Body", face, (sg * u, v), (0.1, 0.1), "brass_light")
        m.rect("Head", face, (sg * 0.3, 0.25), (0.1, 0.1), "brass_light")
    for (u, v) in ((0.0, 0.28), (0.0, -0.28), (0.28, 0.0), (-0.28, 0.0)):
        m.rect("Dial", "front", (u, v), (0.06, 0.06), "steel_dark")
    m.rect("Head", "top", (0, 0.1), (0.5, 0.1), "copper_dark")
    for v in (0.5, 0.0, -0.5):
        m.rect("Spine", "top", (0, v), (0.12, 0.12), "brass_light")
    m.rect("Jaw", "front", (-0.42, 0.06), (0.18, 0.1), "blush")
    m.rect("Jaw", "front", (0.42, 0.06), (0.18, 0.1), "blush")
    m.stamp("Snout", "front", (0, -0.12), ["K...K", ".KKK."], {"K": "eye"})
    for n in ("LegFPaw_L", "LegBPaw_L"):
        m.stamp(n, "front", (0, 0.0), ["T.T.T"], {"T": "steel_dark"})
    for n in ("Tail0", "Tail1"):
        m.line(n, "left", [(0.3, 0.0), (-0.3, 0.0)], "brass_dark", 1)
        m.line(n, "right", [(0.3, 0.0), (-0.3, 0.0)], "brass_dark", 1)
    return m


m4 = ropilot.model("R10_T4", px=8, reset=True)
m4.reference(REF4)
m4.palette(**PAL4)
build_t4(m4)
print(m4.build()); print(m4.check()); print(m4.compare()["report"])
ropilot.check_model(collection="R10_T4", max_lines=10)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R10_T4.blend"), copy=True)


def lg(n, s):
    return [f"{n}Up_{s}", f"{n}Hub_{s}", f"{n}Bolt_{s}", f"{n}Knee_{s}", f"{n}Shin_{s}", f"{n}Paw_{s}"]


GROUPS_T4 = {'Head': ['Head', 'Cheek_*', 'Jaw', 'Snout', 'SnoutTop', 'Nose', 'ForeBolt', 'Eye_*', 'Iris_*', 'Shine*'],
             'EarL': ['Ear_L', 'EarIn_L', 'EarBolt_L'], 'EarR': ['Ear_R', 'EarIn_R', 'EarBolt_R'],
             'LegFL': lg('LegF', 'L'), 'LegFR': lg('LegF', 'R'), 'LegBL': lg('LegB', 'L'), 'LegBR': lg('LegB', 'R'),
             'Tail': ['TailRoot', 'Tail[0-9]', 'TailBand*', 'Gear', 'GearTooth*', 'GearHub']}

# compare() final : face 0.61, dos 0.61, gauche 0.45, dessus 0.47 : la reference est un renard chibi a grosse tete
# et queue enroulee sur le cote ; ici corps et pattes allonges (Epic « elance ») et queue dressee au milieu (anime
# proprement, se lit de dos), choix voulu au-dessus du score.
# --- suite : rig_join("R10_T4", GROUPS_T4), save R10_T4_rig.blend, import -> Work_R10_T4,
# CreatureRig.Install(workspace.Work_R10_T4, "R10_T4", nil, true), puis joints corriges dans le repere du Core :
# EarL/EarR (+-0.6, 3.45, -1.05), Head (0, 2.45, -0.95), pattes a la hanche y = 1.4, Tail (0, 1.95, 0.85)
