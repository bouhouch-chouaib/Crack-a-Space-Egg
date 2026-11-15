# Coral Crab (R8_T3, Rare) : kit ropilot.model, px = 8, sans picots
import ropilot, bpy, os


def save_copy(key):
    fp = os.path.join(ropilot.FILES_DIR, key + ".blend")
    bpy.ops.wm.save_as_mainfile(filepath=fp, copy=True)
    return fp


def build_crab():
    m = ropilot.model("R8_T3", px=8, reset=True)
    m.palette(
        pink=dict(color="#f8707e", noise=0.035, shade=0.16, mottle=("#ea5c70", 0.22, 4), top=0.1),
        pink_dark=dict(color="#d24a63", noise=0.03, shade=0.12),
        pink_light=dict(color="#ffb0ac", noise=0.03, shade=0.1),
        cream=dict(color="#f6e7c6", noise=0.03, shade=0.12),
        sand=dict(color="#ecd9a8", noise=0.05, speckle=("#cdb47c", 0.12), top=0.08),
        orange=dict(color="#ff9a45", noise=0.03, shade=0.12, top=0.1),
        orange_light=dict(color="#ffd08a", noise=0.02),
        teal=dict(color="#28aaa8", noise=0.03, shade=0.14, top=0.1),
        teal_dark=dict(color="#167a80", noise=0.03),
        aqua=dict(color="#7fe6d6", noise=0.03),
        weed=dict(color="#3fc48e", noise=0.03, shade=0.12),
        pearl=dict(color="#fbf7ef", noise=0.012, shade=0.1),
        eye="#101c30", white="#ffffff", blush="#ff9fb0", star="#ffc44a",
        glow=dict(color="#2fe2f0", glow=True),
    )
    # ---- body ----
    m.box("Under", size=(3.0, 2.5, 0.5), at=(0, 0.2, 0.8), role="cream", chamfer=0.14)
    m.box("Shell", size=(3.6, 2.9, 1.7), at=(0, 0.25, 1.75), role="pink", taper=(0.86, 0.86), chamfer=0.34, faces={"bottom": "cream"})
    m.box("Rim", size=(3.8, 3.1, 0.36), at=(0, 0.25, 1.12), role="pink_light", chamfer=0.1)
    # ---- eyes on stalks ----
    for sx, sd in ((-1, "L"), (1, "R")):
        m.box("Stalk_" + sd, size=(0.28, 0.28, 0.6), at=(sx * 0.98, -0.95, 2.5), role="pink_dark")
        m.box("Eye_" + sd, size=(0.9, 0.66, 0.9), at=(sx * 0.98, -1.02, 3.1), role="pink", chamfer=0.08)
    # ---- pincers ----
    for sx, sd in ((-1, "L"), (1, "R")):
        m.beam("ArmUp_" + sd, start=(sx * 1.45, -0.85, 1.0), end=(sx * 2.05, -1.75, 1.1), role="pink_dark", width=0.46, depth=0.46)
        m.box("Claw_" + sd, size=(1.0, 0.95, 1.05), at=(sx * 2.15, -2.05, 1.12), role="pink", chamfer=0.16)
        m.box("FingerT_" + sd, size=(0.86, 0.85, 0.4), at=(sx * 2.15, -2.85, 1.42), role="pink", taper=(0.55, 0.6), axis="y", faces={"front": "pink_light"})
        m.box("FingerB_" + sd, size=(0.74, 0.7, 0.3), at=(sx * 2.15, -2.75, 0.78), role="pink", taper=(0.55, 0.6), axis="y", faces={"front": "pink_light"})
        m.box("ClawBand_" + sd, size=(1.06, 0.2, 1.1), at=(sx * 2.15, -1.68, 1.12), role="pink_light", chamfer=0.05)
    # ---- legs (3 per side) ----
    for sx, sd in ((-1, "L"), (1, "R")):
        for i, y in enumerate((-0.35, 0.45, 1.2)):
            hip = (sx * 1.4, y, 0.95)
            knee = (sx * 2.2, y * 1.15 + 0.05, 1.4)
            foot = (sx * 2.65, y * 1.3 + 0.1, 0.0)
            m.beam("LegU%d_%s" % (i, sd), start=hip, end=knee, role="pink", width=0.36, depth=0.36)
            m.beam("LegD%d_%s" % (i, sd), start=knee, end=foot, role="pink_dark", width=0.34, depth=0.34, taper=0.4)
    # ---- coral garden ----
    top = 2.6
    S = dict(solo=True)
    m.box("Sand", size=(2.3, 1.7, 0.16), at=(0, 0.3, top + 0.03), role="sand", chamfer=0.05)
    # orange branching coral (center back) : reads between and above the eyes
    T = (0.0, 0.75)
    m.beam("CoralTrunk", start=(T[0], T[1] - 0.05, top), end=(T[0], T[1], top + 1.05), role="orange", width=0.36, depth=0.36, **S)
    ends = []
    for i, (z0, e, w) in enumerate([(0.45, (-0.85, 0.65, 1.35), 0.26), (0.65, (0.7, 0.85, 1.5), 0.26), (0.95, (-0.12, 0.65, 2.0), 0.24)]):
        m.beam("CoralB%d" % (i + 1), start=(T[0], T[1], top + z0), end=(e[0], e[1], top + e[2]), role="orange", width=w, depth=w, **S)
        ends.append(e)
    m.beam("CoralB4", start=(-0.5, 0.69, top + 0.98), end=(-0.55, 0.6, top + 1.75), role="orange", width=0.2, depth=0.2, **S)
    ends.append((-0.55, 0.6, 1.75))
    m.beam("CoralB5", start=(0.42, 0.81, top + 1.15), end=(0.5, 0.7, top + 1.9), role="orange", width=0.2, depth=0.2, **S)
    ends.append((0.5, 0.7, 1.9))
    for i, e in enumerate(ends):
        m.box("CoralT%d" % (i + 1), size=(0.3, 0.3, 0.2), at=(e[0], e[1], top + e[2] + 0.05), role="orange_light", **S)
    # teal tube corals (right)
    for i, (x, y, h, r) in enumerate([(0.98, 0.5, 1.25, 0.28), (1.12, -0.08, 0.8, 0.24), (0.62, 1.0, 0.6, 0.22)]):
        m.prism("Tube%d" % i, radius=r, height=h, at=(x, y, top + h / 2), role="teal", sides=6, taper=1.15, faces={"top": "teal_dark"}, **S)
        m.prism("TubeLip%d" % i, radius=r * 1.3, height=0.12, at=(x, y, top + h - 0.03), role="aqua", sides=6, faces={"top": "teal_dark"}, **S)
    # seaweed blades (back left)
    m.beam("Weed1", start=(-0.5, 1.0, top), end=(-0.38, 1.2, top + 0.9), role="weed", width=0.26, depth=0.1, taper=0.5, **S)
    m.beam("Weed2", start=(-0.75, 1.0, top), end=(-0.98, 1.2, top + 0.65), role="weed", width=0.24, depth=0.1, taper=0.5, **S)
    # clam with a pearl (front), loose pearls
    m.box("ClamBase", size=(0.56, 0.46, 0.14), at=(-0.78, -0.02, top + 0.16), role="aqua", chamfer=0.04, **S)
    m.box("ClamLid", size=(0.56, 0.46, 0.12), at=(-0.78, 0.21, top + 0.23), role="aqua", rot=(-50, 0, 0), pivot=(0, 0.23, -0.06), faces={"bottom": "pink_light"}, **S)
    m.box("Pearl1", size=(0.26, 0.26, 0.26), at=(-0.78, -0.04, top + 0.33), role="pearl", chamfer=0.07, **S)
    m.box("Pearl2", size=(0.22, 0.22, 0.22), at=(0.62, -0.42, top + 0.2), role="pearl", chamfer=0.06, **S)
    m.box("Pearl3", size=(0.24, 0.24, 0.24), at=(0.5, 0.15, top + 0.21), role="pearl", chamfer=0.06, **S)
    # glowing crystals
    m.crystal("Crys1", radius=0.25, height=1.1, at=(-0.1, -0.22, top - 0.02), role="glow", sides=6, tip=0.35, **S)
    m.crystal("Crys2", radius=0.17, height=0.7, at=(0.27, -0.4, top - 0.02), role="glow", sides=6, tip=0.35, **S)
    m.crystal("Crys3", radius=0.14, height=0.5, at=(-0.45, -0.45, top - 0.02), role="glow", sides=6, tip=0.35, **S)
    m.crystal("Crys4", radius=0.16, height=0.7, at=(-0.98, 0.5, top - 0.02), role="glow", sides=6, tip=0.35, **S)
    # barnacles on the shell sides
    m.box("Barn1", size=(0.4, 0.4, 0.2), at=m.surface("Shell", "left", (-0.5, 0.1)), role="sand", taper=0.6, **S)
    m.box("Barn2", size=(0.32, 0.32, 0.18), at=m.surface("Shell", "right", (-0.4, -0.05)), role="sand", taper=0.6, **S)
    m.box("Barn3", size=(0.36, 0.36, 0.2), at=m.surface("Shell", "back", (0.7, 0.05)), role="sand", taper=0.6, **S)

    # ---- paint ----
    for face, pts in (("left", [(0.4, 0.2), (-0.1, -0.2), (0.75, -0.15)]), ("right", [(0.5, 0.15), (0.0, -0.2), (-0.7, 0.2)]),
                      ("back", [(-0.9, 0.2), (-0.2, -0.15), (0.1, 0.25), (1.2, -0.2)]), ("front", [(-1.2, 0.15), (1.2, 0.15)])):
        for i, (u, v) in enumerate(pts):
            m.rect("Shell", face, (u, v), (0.25, 0.25) if i % 2 == 0 else (0.13, 0.13), "pink_light")
    m.stamp("Shell", "back", (-0.6, 0.0), ["..S..", "SSSSS", ".SSS.", ".S.S."], {"S": "star"})
    # face : smile and blush on the shell front, eyes on the eye blocks
    m.stamp("Shell", "front", (0, -0.05), ["K......K", ".KKKKKK.", "...TT..."], {"K": "eye", "T": "blush"})
    m.rect("Shell", "front", (-0.8, -0.02), (0.36, 0.19), "blush")
    m.rect("Shell", "front", (0.8, -0.02), (0.36, 0.19), "blush")
    m.stamp("Eye_L", "front", (0, 0), ["KKKKK", "KWWKK", "KWWKK", "KKKKK", "KKKWK"], {"K": "eye", "W": "white"})
    m.stamp("Eye_R", "front", (0, 0), ["KKKKK", "KKWWK", "KKWWK", "KKKKK", "KWKKK"], {"K": "eye", "W": "white"})
    for sd in ("L", "R"):
        m.rect("Claw_" + sd, "top", (0, 0), (0.25, 0.25), "pink_light")
    return m


m = build_crab()
print(m.build())
print(m.check())
ropilot.check_model(collection="R8_T3", max_lines=25)
print(save_copy("R8_T3"))

# --- suite (faite a la main apres ce script) ---
# rig_join("R8_T3", {"ArmL": [ArmUp_L, Claw_L, FingerT_L, FingerB_L, ClawBand_L], "LegFL": [LegU0_L, LegD0_L],
#                    "LegL": [LegU1_L, LegD1_L], "LegBL": [LegU2_L, LegD2_L], idem cote R})
