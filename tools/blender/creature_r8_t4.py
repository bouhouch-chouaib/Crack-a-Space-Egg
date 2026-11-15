# Lantern Jelly (R8_T4, Epic) : kit ropilot.model, px = 8, sans picots
import ropilot, bpy, os, math


def save_copy(key):
    fp = os.path.join(ropilot.FILES_DIR, key + ".blend")
    bpy.ops.wm.save_as_mainfile(filepath=fp, copy=True)
    return fp


def make_translucent(key, names, alpha=0.5):
    base = bpy.data.materials[key + "_mat"]
    mat = bpy.data.materials.get(key + "_bubble")
    if mat:
        bpy.data.materials.remove(mat)
    mat = base.copy()
    mat.name = key + "_bubble"
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Alpha"].default_value = alpha
    for attr, val in (("surface_render_method", "BLENDED"), ("blend_method", "BLEND")):
        try:
            setattr(mat, attr, val)
        except Exception as e:
            print(attr, e)
    for o in bpy.data.collections[key].all_objects:
        part = o.get("ropilot_part") or o.name
        if part in names:
            o.material_slots[0].material = mat


def build_jelly():
    m = ropilot.model("R8_T4", px=8, reset=True)
    m.palette(
        teal=dict(color="#28aaa8", noise=0.035, shade=0.15, mottle=("#1f9896", 0.22, 4), top=0.1),
        teal_dark=dict(color="#1b8587", noise=0.03, shade=0.12),
        aqua=dict(color="#7fe6d6", noise=0.03, shade=0.1),
        navy=dict(color="#24326e", noise=0.03, shade=0.14, top=0.12),
        navy_light=dict(color="#3f54a0", noise=0.03),
        pink=dict(color="#ff7a6e", noise=0.03, shade=0.12, top=0.08),
        pink_dark=dict(color="#e2564e", noise=0.03),
        pink_light=dict(color="#ffb59c", noise=0.03, shade=0.1),
        pearl=dict(color="#fbf7ef", noise=0.012, shade=0.1),
        glass=dict(color="#a4efe6", noise=0.012, shade=0.05),
        glass_rim=dict(color="#6fd8cf", noise=0.02),
        eye="#101c30", white="#ffffff", blush="#ff9fb0",
        cyan=dict(color="#2fe2f0", glow=True),
        gold=dict(color="#ffa41c", glow=True),
    )
    S = dict(solo=True)
    # ---------------- bell ----------------
    m.box("Rim", size=(4.3, 3.8, 0.42), at=(0, 0, 2.8), role="pink", chamfer=0.12)
    m.box("Collar", size=(3.96, 3.46, 0.36), at=(0, 0, 3.14), role="navy", chamfer=0.08)
    m.box("FaceBand", size=(3.8, 3.3, 1.8), at=(0, 0, 4.15), role="teal", chamfer=0.24, taper=(0.93, 0.93))
    m.box("Brim", size=(3.64, 3.16, 0.22), at=(0, 0, 5.1), role="navy", chamfer=0.06)
    m.box("Glass", size=(3.9, 3.4, 1.55), at=(0, 0, 5.94), role="glass", taper=(0.56, 0.56), chamfer=0.34)
    # ---------------- lantern flame (inside the glass dome) ----------------
    m.prism("Wick", radius=0.46, height=0.24, at=(0, 0, 5.3), role="navy_light", sides=6)
    m.crystal("Flame", radius=0.44, height=1.05, at=(0, 0, 5.36), role="gold", sides=6, tip=0.45)
    m.crystal("FlameL", radius=0.2, height=0.5, at=(-0.5, 0.05, 5.36), role="gold", sides=6, tip=0.45, **S)
    m.crystal("FlameR", radius=0.17, height=0.42, at=(0.47, -0.1, 5.36), role="gold", sides=6, tip=0.45, **S)
    # ---------------- crown ----------------
    cz = 6.7
    m.box("CrownBase", size=(1.56, 1.36, 0.3), at=(0, 0, cz), role="pink", chamfer=0.06)
    for sx, sd in ((-1, "L"), (1, "R")):
        for sy, fb in ((-1, "F"), (1, "B")):
            m.pyramid("Point%s_%s" % (fb, sd), size=(0.42, 0.42, 0.6), at=(sx * 0.55, sy * 0.45, cz + 0.43), role="pink")
            m.box("Tip%s_%s" % (fb, sd), size=(0.2, 0.2, 0.2), at=(sx * 0.55, sy * 0.45, cz + 0.74), role="pearl", chamfer=0.05)
    m.crystal("Finial", radius=0.24, height=0.95, at=(0, 0, cz + 0.08), role="cyan", sides=6, tip=0.4)
    m.box("CrownGem", size=(0.34, 0.1, 0.22), at=(0, -0.7, cz), role="pearl", chamfer=0.04)
    # ---------------- face ----------------
    for sx, sd in ((-1, "L"), (1, "R")):
        m.box("Eye_" + sd, size=(0.55, 0.68, 0.1), at=m.surface("FaceBand", "front", (sx * 0.82, 0.14)), role="cyan", pivot="bottom")
        m.box("SidePlate_" + sd, size=(1.2, 1.0, 0.14), at=m.surface("FaceBand", "left" if sx < 0 else "right", (0, 0.0)), role="navy", pivot="bottom", chamfer=0.05)
        m.box("SidePearl_" + sd, size=(0.32, 0.32, 0.14), at=m.surface("SidePlate_" + sd, "top", (0, 0)), role="pearl", pivot="bottom", chamfer=0.05)
    # ---------------- collar rivets and gem ----------------
    for i, x in enumerate((-1.45, -0.72, 0.72, 1.45)):
        m.box("Rivet%d" % i, size=(0.2, 0.1, 0.2), at=(x, -1.75, 3.16), role="pearl", chamfer=0.04, **S)
    m.prism("CollarGem", radius=0.26, height=0.14, at=(0, -1.77, 3.16), role="pink", sides=4, rot=(90, 0, 0))
    # ---------------- rim scallops and side fins ----------------
    for i, x in enumerate((-1.4, 0.0, 1.4)):
        m.box("ScallopF%d" % i, size=(1.1, 0.24, 0.44), at=(x, -1.8, 2.46), role="pink_light", taper=(0.7, 1), rot=(180, 0, 0), **S)
        m.box("ScallopB%d" % i, size=(1.1, 0.24, 0.44), at=(x, 1.8, 2.46), role="pink_light", taper=(0.7, 1), rot=(180, 0, 0), **S)
    for sx, sd in ((-1, "L"), (1, "R")):
        m.box("Fin_" + sd, size=(1.0, 2.1, 0.24), at=(sx * 2.5, 0, 2.62), role="pink", rot=(0, sx * 26, 0), chamfer=0.06)
        m.box("FinTip_" + sd, size=(0.34, 1.7, 0.26), at=(sx * 3.05, 0, 2.35), role="pink_light", rot=(0, sx * 26, 0))
    # ---------------- tentacles ----------------
    for k in range(8):
        a = math.radians(22.5 + 45 * k)
        cx, cy = math.cos(a), math.sin(a)
        long_ = k % 2 == 0
        top = (1.5 * cx, 1.3 * cy, 2.7)
        knee = (1.72 * cx, 1.5 * cy, 1.45 if long_ else 1.65)
        end = (1.6 * cx, 1.4 * cy, 0.3 if long_ else 0.75)
        m.beam("Tent%dA" % k, start=top, end=knee, role="teal", width=0.52, depth=0.52, taper=0.8, chamfer=0.07, **S)
        m.beam("Tent%dB" % k, start=knee, end=end, role="aqua", width=0.38, depth=0.38, taper=0.65, **S)
        m.box("TentTip%d" % k, size=(0.26, 0.26, 0.32), at=(end[0], end[1], end[2] - 0.12), role="cyan", **S)
        if long_:
            m.box("TentPearl%d" % k, size=(0.56, 0.56, 0.28), at=knee, role="pearl", chamfer=0.08, **S)
    # inner oral arms
    for i, (x, y, z1, z2) in enumerate([(-0.5, -0.35, 1.4, 0.75), (0.52, -0.25, 1.2, 0.55), (0.0, 0.55, 1.3, 0.85)]):
        m.beam("Oral%dA" % i, start=(x * 0.6, y * 0.6, 2.7), end=(x, y, z1), role="pink", width=0.62, depth=0.62, taper=0.75, **S)
        m.beam("Oral%dB" % i, start=(x, y, z1), end=(x * 1.15, y * 1.15, z2), role="pink_light", width=0.44, depth=0.44, taper=0.55, **S)

    # ---------------- paint ----------------
    arc = ["A...A", ".AAA."]
    for (u, v, c) in [(-1.0, 0.3, "aqua"), (0.0, 0.1, "teal_dark"), (1.0, 0.35, "aqua"), (-0.5, -0.35, "teal_dark"), (0.55, -0.3, "aqua")]:
        m.stamp("FaceBand", "back", (u, v), arc, {"A": c})
    for (u, v) in [(-1.35, -0.45), (1.4, 0.5), (-0.2, 0.52)]:
        m.rect("FaceBand", "back", (u, v), (0.13, 0.13), "aqua")
    # face : dark sockets behind the glowing eyes, smile, blush
    for sx in (-1, 1):
        m.rect("FaceBand", "front", (sx * 0.82, 0.14), (0.8, 0.94), "eye")
        m.rect("FaceBand", "front", (sx * 1.38, -0.42), (0.3, 0.16), "blush")
    m.stamp("FaceBand", "front", (0, -0.46), ["K....K", ".KKKK."], {"K": "eye"})
    # glass dome : ribs, glints, speckles
    for face in ("front", "back", "left", "right"):
        m.rect("Glass", face, (0.55, 0.2), (0.13, 0.13), "glass_rim")
        m.rect("Glass", face, (-0.6, -0.35), (0.13, 0.13), "glass_rim")
        m.stamp("Glass", face, (-0.25, 0.25), ["WWW", "W..", "W.."], {"W": "white"})
        m.rect("Glass", face, (0.3, -0.3), (0.13, 0.13), "white")
    for face in ("front", "back"):
        for u in (-1.35, -0.45, 0.45, 1.35):
            m.rect("Brim", face, (u, 0), (0.13, 0.13), "navy_light")
    for face in ("left", "right"):
        for u in (-1.0, 0.0, 1.0):
            m.rect("Brim", face, (u, 0), (0.13, 0.13), "navy_light")
    # fins : rays
    for sd in ("L", "R"):
        for v in (-0.6, 0.0, 0.6):
            m.line("Fin_" + sd, "top", [(-0.35, v), (0.45, v)], "pink_dark", 1)
    return m


m = build_jelly()
print(m.build())
print(m.check())
ropilot.check_model(collection="R8_T4", max_lines=18)
make_translucent("R8_T4", {"Glass"}, alpha=0.45)
print(save_copy("R8_T4"))

# --- suite (faite a la main apres ce script) ---
# rig_join("R8_T4", {"Tentacles": ["Tent*", "Oral*"], "FinL": ["Fin_L", "FinTip_L"], "FinR": ["Fin_R", "FinTip_R"],
#                    "Body__Glass": ["Glass"]})
# Studio, apres CreatureRig.Install : la piece RopilotBlenderObject == "R8_T4:Body__Glass" -> Transparency 0.45, CastShadow false
