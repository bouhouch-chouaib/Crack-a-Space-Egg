# Steam Rhino (R10_T5, Legendary) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R10_Refs/Ref_R10_T5_*.png)
# Rhinoceros massif en plaques d'acier : bosse d'epaule, bandes de jointure sombres rivetees, plaques de laiton
# sur l'epaule (avec manometre a aiguille rouge) et la hanche, crete de laiton sur le dos, deux cheminees de
# cuivre a bouche turquoise sur la croupe ; tete large et basse, grande corne de laiton recourbee montee sur un
# piston (manchon de cuivre, tige chromee), petite corne arriere, yeux turquoise lumineux a reflets sous une
# arcade droite, oreilles de cuivre (rig EarL / EarR) ; pattes massives avec rouage a moyeu lumineux a la hanche,
# genou lumineux, pied de laiton a ongles chromes ; petite queue qui s'affine avec un rouage (rig Tail).
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R10_Refs")
REF5 = {v: os.path.join(R, f"Ref_R10_T5_{v}.png") for v in ("front", "left", "back", "top")}
PAL5 = dict(
    steel=dict(color="#7c8c9c", noise=0.03, shade=0.16, mottle=("#73839a", 0.2, 4), top=0.14),
    steel_light=dict(color="#a3b2c0", noise=0.03, shade=0.12, top=0.12, rim=-0.2),
    steel_dark=dict(color="#3e4a58", noise=0.03, shade=0.12),
    chrome=dict(color="#c9d4de", noise=0.02, shade=0.1, top=0.15, rim=-0.2),
    brass=dict(color="#e0a84a", noise=0.03, shade=0.14, top=0.14, rim=-0.22),
    brass_light=dict(color="#f5cf7a", noise=0.03, shade=0.1, top=0.12, rim=-0.2),
    brass_dark=dict(color="#b8822e", noise=0.03, shade=0.1),
    copper=dict(color="#c8703a", noise=0.035, shade=0.16, top=0.14),
    copper_dark=dict(color="#8e4a26", noise=0.03, shade=0.12),
    dial=dict(color="#f7f0dc", noise=0.015, shade=0.06),
    red="#c83a3a", eye="#16202c", shine="#ffffff",
    glow=dict(color="#5ae6d2", glow=True),
)
HORN5 = [(0, -4.62, 4.05), (0, -4.78, 5.25), (0, -4.3, 6.4)]   # corne : base, milieu, pointe (recourbee vers l'arriere)
HW5 = [1.05, 0.6, 0.08]


def build_t5(m):
    MR = dict(mirror=True)
    # ---- corps : bosse d'epaule, tronc, croupe en acier, ventre sombre, bandes de jointure, plaques rivetees
    m.box("Chest", size=(4.6, 2.8, 4.0), at=(0, -0.1, 3.5), role="steel", chamfer=0.8)
    m.box("Torso", size=(4.4, 3.0, 3.75), at=(0, 2.3, 3.45), role="steel", chamfer=0.8, slope=(0, -0.2))
    m.box("Rump", size=(4.2, 1.8, 3.4), at=(0, 3.95, 3.35), role="steel", chamfer=0.8)
    m.box("Belly", size=(3.4, 5.4, 0.4), at=(0, 1.9, 1.55), role="steel_dark", chamfer=0.1)
    m.box("Band0", size=(4.72, 0.4, 3.9), at=(0, 1.0, 3.48), role="steel_dark", chamfer=0.8)
    m.box("Band1", size=(4.52, 0.4, 3.56), at=(0, 3.15, 3.37), role="steel_dark", chamfer=0.8)
    m.box("ShoulderPlate_L", size=(0.24, 2.1, 2.3), at=(-2.33, -0.15, 3.75), role="brass", chamfer=0.08, **MR)
    m.box("HipPlate_L", size=(0.24, 1.5, 2.0), at=(-2.12, 4.0, 3.55), role="brass", chamfer=0.08, **MR)
    # manometre sur l'epaule (cadran, aiguille rouge)
    m.prism("GaugeRim_L", radius=0.5, height=0.12, at=(-2.48, -0.2, 3.9), role="brass_dark", sides=10, rot=(0, 90, 0), **MR)
    m.prism("Gauge_L", radius=0.4, height=0.08, at=(-2.55, -0.2, 3.9), role="dial", sides=10, rot=(0, 90, 0), **MR)
    m.box("GaugeNeedle_L", size=(0.04, 0.3, 0.06), at=(-2.6, -0.28, 3.98), role="red", rot=(30, 0, 0), **MR)
    # crete de plaques de laiton sur le dos
    for i, (y, z) in enumerate(((-0.55, 5.5), (0.6, 5.42))):
        m.box(f"Ridge{i}", size=(0.9, 0.95, 0.24), at=(0, y, z), role="brass", chamfer=0.06, taper=(0.8, 0.85))
    # deux cheminees de vapeur : collier, fut de cuivre, bague, bouche sombre a lueur turquoise
    m.prism("ChimBase_L", radius=0.6, height=0.3, at=(-1.0, 3.5, 5.12), role="brass", sides=8, **MR)
    m.prism("Chimney_L", radius=0.42, height=1.3, at=(-1.0, 3.5, 5.8), role="copper", sides=8, **MR)
    m.prism("ChimRim_L", radius=0.53, height=0.26, at=(-1.0, 3.5, 6.47), role="brass_dark", sides=8, **MR)
    m.prism("ChimHole_L", radius=0.32, height=0.04, at=(-1.0, 3.5, 6.6), role="steel_dark", sides=8, **MR)
    m.prism("ChimGlow_L", radius=0.18, height=0.04, at=(-1.0, 3.5, 6.61), role="glow", sides=8, **MR)
    # ---- cou
    m.box("Neck", size=(3.0, 1.4, 2.7), at=(0, -1.75, 3.4), role="steel_dark", chamfer=0.4)
    m.box("Collar", size=(3.2, 0.5, 2.9), at=(0, -1.52, 3.42), role="brass", chamfer=0.35)
    # ---- tete (rig Head) : large, basse, front qui descend vers le museau carre
    m.box("Head", size=(2.9, 2.7, 2.5), at=(0, -3.0, 3.2), role="steel", chamfer=0.45, axis="y", taper=(0.88, 0.82), slope=(0, 0.35))
    m.box("HeadPlate", size=(2.0, 1.9, 0.26), at=(0, -2.75, 4.62), role="brass", chamfer=0.06, taper=(0.8, 0.9), rot=(-8, 0, 0))
    m.box("Cheek_L", size=(0.22, 1.5, 1.2), at=(-1.42, -3.15, 2.85), role="brass", chamfer=0.06, taper=(1, 0.8), **MR)
    m.box("Snout", size=(2.3, 1.5, 1.85), at=(0, -4.5, 2.55), role="steel", chamfer=0.32, axis="y", taper=(0.88, 0.8))
    m.box("Lip", size=(2.0, 1.4, 0.5), at=(0, -4.35, 1.7), role="steel_dark", chamfer=0.14, axis="y", taper=(0.85, 0.9))
    # corne en piston : manchon de cuivre, tige chromee, bague, grande corne de laiton recourbee ; petite corne
    m.prism("HornSleeve", radius=0.66, height=0.5, at=(0, -4.6, 3.6), role="copper", sides=8)
    m.prism("HornRod", radius=0.38, height=0.32, at=(0, -4.6, 3.98), role="chrome", sides=8)
    m.prism("HornCollar", radius=0.6, height=0.18, at=(0, -4.61, 4.12), role="brass_dark", sides=8)
    for i in range(2):
        a, b = HORN5[i], HORN5[i + 1]
        e = 0.06 if i == 0 else 0
        a2 = tuple(a[k] - (b[k] - a[k]) * e for k in range(3))
        b2 = tuple(b[k] + (b[k] - a[k]) * (0.05 if i == 0 else 0) for k in range(3))
        m.beam(f"HornSeg{i}", start=a2, end=b2, role="brass", width=HW5[i], depth=HW5[i], taper=HW5[i + 1] / HW5[i], chamfer=0.2 if i == 0 else 0.12)
    m.prism("HornBack", radius=0.34, height=0.8, at=(0, -3.6, 4.85), role="brass_light", sides=8, taper=0, rot=(-18, 0, 0))
    # yeux turquoise lumineux bien separes, reflets ; arcade presque droite (regard fier)
    m.box("Eye_L", size=(0.62, 0.12, 0.58), at=(-0.9, -4.36, 3.88), role="eye", chamfer=0.06, **MR)
    m.box("Iris_L", size=(0.42, 0.1, 0.42), at=(-0.88, -4.41, 3.84), role="glow", chamfer=0.03, **MR)
    m.box("Shine_L", size=(0.16, 0.06, 0.16), at=(-1.0, -4.45, 4.0), role="shine", **MR)
    m.box("Shine2_L", size=(0.08, 0.06, 0.08), at=(-0.78, -4.45, 3.74), role="shine", **MR)
    m.beam("Brow_L", start=(-1.25, -4.3, 4.24), end=(-0.55, -4.34, 4.2), role="brass_dark", width=0.22, depth=0.2, chamfer=0.04, **MR)
    # oreilles (rig EarL / EarR)
    m.box("Ear_L", size=(0.62, 0.36, 0.95), at=(-1.1, -2.2, 4.42), role="copper", taper=(0.35, 0.6), chamfer=0.05, pivot="bottom",
          rot=(0, -25, 0), faces={"front": "steel_dark"}, **MR)
    # ---- pattes : cuisse d'acier, rouage a moyeu lumineux, genou lumineux, tibia sombre, pied de laiton, ongles chromes
    for n, y in (("LegF", -0.45), ("LegB", 3.9)):
        m.box(n + "Up_L", size=(1.5, 1.7, 1.6), at=(-1.45, y, 2.0), role="steel", chamfer=0.3, **MR)
        m.prism(n + "Gear_L", radius=0.55, height=0.18, at=(-2.22, y, 2.0), role="brass", sides=8, rot=(0, 90, 0), turn=22.5, **MR)
        m.prism(n + "Hub_L", radius=0.22, height=0.12, at=(-2.33, y, 2.0), role="glow", sides=6, rot=(0, 90, 0), **MR)
        m.box(n + "Knee_L", size=(1.36, 1.46, 0.18), at=(-1.45, y, 1.3), role="glow", **MR)
        m.box(n + "Shin_L", size=(1.3, 1.4, 1.2), at=(-1.45, y, 0.8), role="steel_dark", chamfer=0.15, **MR)
        m.box(n + "Foot_L", size=(1.6, 1.8, 0.45), at=(-1.45, y - 0.05, 0.22), role="brass", chamfer=0.1, **MR)
        for k, dx in enumerate((-0.45, 0.0, 0.45)):
            m.box(f"{n}Nail{k}_L", size=(0.32, 0.2, 0.26), at=(-1.45 + dx, y - 1.0, 0.16), role="chrome", chamfer=0.04, **MR)
    # ---- petite queue qui s'affine, rouage au bout (rig Tail)
    m.beam("Tail", start=(0, 4.7, 4.1), end=(0, 5.3, 3.15), role="steel_dark", width=0.42, depth=0.42, taper=0.6, chamfer=0.06)
    m.prism("TailGear", radius=0.3, height=0.14, at=(0, 5.32, 3.05), role="brass", sides=8, rot=(0, 90, 0), turn=22.5)
    # ---- peinture : rivets, joints de plaques, naseaux, bouche
    for n, us, vs in (("ShoulderPlate_L", (-0.85, 0.85), (0.95, -0.95)), ("HipPlate_L", (-0.6, 0.6), (0.8, -0.8)),
                      ("Cheek_L", (-0.5, 0.5), (0.4, -0.4))):
        for u in us:
            for v in vs:
                m.rect(n, "left", (u, v), (0.14, 0.14), "brass_light")
    for n in ("Chest", "Torso", "Rump"):
        m.line(n, "top", [(-1.4, -0.6), (-1.4, 0.6)], "steel_dark", 1)
        m.line(n, "top", [(1.4, -0.6), (1.4, 0.6)], "steel_dark", 1)
    for n in ("Chest", "Torso"):
        for (u, v) in ((-0.9, 0.9), (0.9, 0.9), (-0.9, -0.9), (0.9, -0.9)):
            m.rect(n, "left", (u, v), (0.12, 0.12), "steel_light")
    for u in (-0.6, 0.0, 0.6):
        m.rect("HeadPlate", "top", (u, -0.6), (0.12, 0.12), "brass_light")
    for v in (0.25, -0.25):
        m.rect("Collar", "front", (-1.25, v), (0.12, 0.12), "brass_light")
        m.rect("Collar", "front", (1.25, v), (0.12, 0.12), "brass_light")
    m.stamp("Snout", "front", (0, -0.1), ["KK.......KK", "KK.......KK"], {"K": "steel_dark"})
    m.line("Lip", "front", [(-0.7, 0.05), (0.7, 0.05)], "eye", 1)
    for n in ("Band0", "Band1"):
        for v in (0.9, 0.0, -0.9):
            m.rect(n, "left", (0, v), (0.12, 0.12), "brass")
            m.rect(n, "right", (0, v), (0.12, 0.12), "brass")
    for n in ("LegFUp_L", "LegBUp_L"):
        m.rect(n, "front", (0, 0.4), (0.9, 0.12), "steel_dark")
    return m


m5 = ropilot.model("R10_T5", px=8, reset=True)
m5.reference(REF5)
m5.palette(**PAL5)
build_t5(m5)
print(m5.build()); print(m5.check()); print(m5.compare()["report"])
ropilot.check_model(collection="R10_T5", max_lines=8)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R10_T5.blend"), copy=True)


def lg5(n, s):
    return [f"{n}Up_{s}", f"{n}Gear_{s}", f"{n}Hub_{s}", f"{n}Knee_{s}", f"{n}Shin_{s}", f"{n}Foot_{s}", f"{n}Nail*_{s}"]


GROUPS_T5 = {'Head': ['Head', 'HeadPlate', 'Cheek_*', 'Snout', 'Lip', 'HornSleeve', 'HornRod', 'HornCollar', 'HornSeg*', 'HornBack',
                      'Eye_*', 'Iris_*', 'Shine*', 'Brow_*'],
             'EarL': ['Ear_L'], 'EarR': ['Ear_R'],
             'LegFL': lg5('LegF', 'L'), 'LegFR': lg5('LegF', 'R'), 'LegBL': lg5('LegB', 'L'), 'LegBR': lg5('LegB', 'R'),
             'Tail': ['Tail', 'TailGear']}
# --- suite : exec(rigjoin.py), rig_join("R10_T5", GROUPS_T5), save R10_T5_rig.blend, import -> Work_R10_T5,
# CreatureRig.Install(workspace.Work_R10_T5, "R10_T5", nil, true), puis joints corriges dans le repere du Core :
# Head (0, 3.3, -1.9) au cou, EarL/EarR (+-1.0, 4.45, -2.42) a la base, Tail (0, 4.1, 4.45) a la racine, pattes a la hanche y = 2.65
# compare() final : face 0.88, dos 0.88, gauche 0.82, dessus 0.85 (tete agrandie et corne recourbee en piston, plus lisibles que la reference)
