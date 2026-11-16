# Gummy Cub (R11_T2, Uncommon) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R11_Refs/Ref_R11_T2_*.png)
# Ourson gelifie rouge cerise debout : grosse tete ronde, oreilles rondes (octogones), museau clair et nez
# chocolat, bras courts tendus vers l'avant, jambes courtes ; ventre en cristaux de sucre rose (mouchete blanc,
# deux eclats en croix), reflets de gomme brillante peints sur la tete et le corps, petite queue.
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R11_Refs")
REF2 = {v: os.path.join(R, f"Ref_R11_T2_{v}.png") for v in ("front", "left", "back", "top")}
PAL2 = dict(
    gum=dict(color="#e8344e", noise=0.03, shade=0.16, mottle=("#f24d65", 0.25, 4), top=0.16, speckle=("#ff8a9c", 0.015)),
    gum_light=dict(color="#ff6f84", noise=0.03, shade=0.1, top=0.12),
    gum_dark=dict(color="#b51f3a", noise=0.03, shade=0.12),
    sugar=dict(color="#ff9bb2", noise=0.05, shade=0.06, speckle=("#ffffff", 0.16), top=0.1),
    choco="#6b3a26", eye="#2a1420", white="#ffffff", blush="#ff9ab0",
    shine=dict(color="#ffd0da", noise=0.02),
)


def build_t2(m):
    MR = dict(mirror=True)
    # corps : poire arrondie, ventre en cristaux de sucre
    m.box("Body", size=(1.5, 1.24, 1.4), at=(0, 0.02, 1.08), role="gum", chamfer=0.5, taper=(0.84, 0.86), faces={"bottom": "gum_dark"})
    m.box("Belly", size=(0.96, 0.2, 0.92), at=(0, -0.57, 0.98), role="sugar", chamfer=0.24, taper=(0.8, 1))
    # tete : grosse, ronde, museau clair, nez chocolat
    m.box("Head", size=(1.66, 1.3, 1.24), at=(0, -0.04, 2.3), role="gum", chamfer=0.56, taper=(0.82, 0.86))
    m.box("Muzzle", size=(0.76, 0.34, 0.46), at=(0, -0.72, 2.06), role="gum_light", chamfer=0.17, axis="y", taper=(0.85, 0.85))
    m.box("Nose", size=(0.28, 0.12, 0.18), at=(0, -0.89, 2.2), role="choco", chamfer=0.05)
    # yeux separes, deux reflets chacun
    m.box("Eye_L", size=(0.3, 0.08, 0.4), at=(-0.37, -0.69, 2.47), role="eye", chamfer=0.04, **MR)
    m.box("Shine_L", size=(0.14, 0.05, 0.14), at=(-0.42, -0.735, 2.57), role="white", **MR)
    m.box("Shine2_L", size=(0.06, 0.05, 0.06), at=(-0.31, -0.735, 2.37), role="white", **MR)
    # oreilles rondes (octogones), interieur clair
    m.prism("Ear_L", radius=0.31, height=0.26, at=(-0.56, 0.0, 2.92), role="gum", sides=8, rot=(90, 0, 0), turn=22.5, **MR)
    m.prism("EarIn_L", radius=0.18, height=0.06, at=(-0.56, -0.14, 2.92), role="gum_light", sides=8, rot=(90, 0, 0), turn=22.5, **MR)
    # bras courts tendus vers l'avant (pivot a l'epaule)
    m.box("Arm_L", size=(0.42, 0.46, 0.72), at=(-0.72, -0.12, 1.32), role="gum", chamfer=0.18, pivot="top", rot=(-38, -10, 0), faces={"bottom": "gum_light"}, **MR)
    # jambes courtes, pieds vers l'avant, semelle en sucre
    m.box("Leg_L", size=(0.56, 0.6, 0.52), at=(-0.42, -0.06, 0.26), role="gum", chamfer=0.18, **MR)
    m.box("Foot_L", size=(0.5, 0.3, 0.36), at=(-0.42, -0.37, 0.205), role="gum", chamfer=0.12, **MR)
    m.box("Sole_L", size=(0.36, 0.06, 0.22), at=(-0.42, -0.525, 0.205), role="sugar", chamfer=0.03, **MR)
    m.box("Tail", size=(0.36, 0.26, 0.32), at=(0, 0.66, 0.66), role="gum_dark", chamfer=0.1)
    return m


def paint_t2(m):
    # reflets de gomme brillante, joues, sourire, cristaux de sucre en croix
    m.rect("Head", "front", (-0.48, 0.32), (0.2, 0.08), "shine")
    m.rect("Head", "front", (-0.56, 0.22), (0.08, 0.12), "shine")
    m.rect("Head", "top", (-0.25, -0.12), (0.24, 0.1), "shine")
    m.rect("Head", "back", (0.38, 0.3), (0.24, 0.08), "shine")
    m.rect("Body", "front", (-0.44, 0.34), (0.08, 0.2), "shine")
    m.rect("Body", "back", (0.4, 0.3), (0.08, 0.24), "shine")
    m.rect("Head", "front", (-0.56, -0.2), (0.2, 0.1), "blush")
    m.rect("Head", "front", (0.56, -0.2), (0.2, 0.1), "blush")
    m.stamp("Muzzle", "front", (0, -0.12), ["K..K", ".KK."], {"K": "eye"})
    m.stamp("Belly", "front", (-0.2, 0.2), [".W.", "WWW", ".W."], {"W": "white"})
    m.stamp("Belly", "front", (0.18, -0.24), [".W.", "WWW", ".W."], {"W": "white"})
    m.line("Body", "back", [(-0.15, -0.35), (0.15, -0.35)], "gum_dark", 1)
    return m


GROUPS_T2 = {'Head': ['Head', 'Muzzle', 'Nose', 'Eye_*', 'Shine*'],
             'EarL': ['Ear_L', 'EarIn_L'], 'EarR': ['Ear_R', 'EarIn_R'],
             'ArmL': ['Arm_L'], 'ArmR': ['Arm_R'],
             'LegL': ['Leg_L', 'Foot_L', 'Sole_L'], 'LegR': ['Leg_R', 'Foot_R', 'Sole_R'],
             'Tail': ['Tail']}

if __name__ == "__main__" or True:
    m2 = ropilot.model("R11_T2", px=8, reset=True)
    m2.reference(REF2)
    m2.palette(**PAL2)
    build_t2(m2); paint_t2(m2)
    print(m2.build()); print(m2.check()); print(m2.compare(image=False)["report"])
    ropilot.check_model(collection="R11_T2", max_lines=6)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R11_T2.blend"), copy=True)

# compare() final : face 0.84, dos 0.84, gauche 0.74, dessus 0.88 (la reference a un ventre et un dos plus bombes
# de profil ; garde volontairement les bras tendus vers l'avant, qui se lisent mieux de face).
# --- suite : exec(rigjoin.py), rig_join("R11_T2", GROUPS_T2), save R11_T2_rig.blend, import -> Work_R11_T2,
# CreatureRig.Install(workspace.Work_R11_T2, "R11_T2", nil, true), puis joints corriges dans le repere du Core :
# ArmL/ArmR (+-0.6, 1.32, -0.12), EarL/EarR (+-0.56, 2.72, 0), Head (0, 1.72, -0.02), LegL/LegR (+-0.42, 0.5, -0.06),
# Tail (0, 0.66, 0.55)
