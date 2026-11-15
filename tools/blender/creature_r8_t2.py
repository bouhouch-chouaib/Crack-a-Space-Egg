# Bubble Guppy (R8_T2, Uncommon) : kit ropilot.model, px = 8, sans picots
import ropilot, bpy, os


def save_copy(key):
    fp = os.path.join(ropilot.FILES_DIR, key + ".blend")
    bpy.ops.wm.save_as_mainfile(filepath=fp, copy=True)
    return fp


def make_translucent(key, names, alpha=0.5):
    # la bulle : copie du matériau de l'atlas, en transparence (rendu Blender ; dans Studio : Transparency)
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


def build_guppy():
    m = ropilot.model("R8_T2", px=8, reset=True)
    m.palette(
        teal=dict(color="#28aaa8", noise=0.035, shade=0.15, mottle=("#1f9896", 0.22, 4), top=0.1),
        teal_dark=dict(color="#1b8587", noise=0.03, shade=0.12),
        aqua=dict(color="#7fe6d6", noise=0.03),
        belly=dict(color="#f4e6c4", noise=0.03, shade=0.12),
        coral=dict(color="#ff7a6e", noise=0.03, shade=0.12, top=0.08),
        coral_dark=dict(color="#e2564e", noise=0.03),
        coral_light=dict(color="#ffb59c", noise=0.03),
        eye="#101c30", white="#ffffff", blush="#ff9fb0", tongue="#ff8f8f",
        pearl=dict(color="#fbf7ef", noise=0.015, shade=0.1),
        bubble=dict(color="#c4f1fa", noise=0.015, shade=0.06),
        bubble_rim=dict(color="#8fd9ec", noise=0.02),
    )
    Z = 0.13
    # masses
    m.box("Belly", size=(2.3, 2.4, 0.95), at=(0, 0, 0.52 + Z), role="belly", chamfer=0.3, taper=(1.2, 1.18))
    m.box("Body", size=(2.9, 2.95, 2.3), at=(0, 0, 1.95 + Z), role="teal", taper=(0.88, 0.9), chamfer=0.36)
    # gill covers
    m.box("Gill_L", size=(0.14, 0.5, 1.15), at=(-1.42, -0.55, 1.75 + Z), role="teal_dark", chamfer=0.04, mirror=True)
    # tail
    m.beam("Stalk", start=(0, 1.25, 1.75 + Z), end=(0, 2.15, 1.85 + Z), role="teal", width=0.85, depth=0.95, taper=0.6, chamfer=0.1)
    m.box("TailRing", size=(0.62, 0.22, 0.7), at=(0, 2.05, 1.84 + Z), role="pearl", chamfer=0.05)
    m.box("TailFan", size=(0.22, 1.2, 2.3), at=(0, 2.6, 1.9 + Z), role="coral", taper=(1, 0.3), axis="y")
    m.box("TailTipUp", size=(0.26, 0.42, 0.9), at=(0, 3.32, 2.62 + Z), role="coral_light", slope=(0, 0.25))
    m.box("TailTipDn", size=(0.26, 0.42, 0.9), at=(0, 3.32, 1.18 + Z), role="coral_light", slope=(0, 0.25), rot=(180, 0, 0))
    # side fins
    m.box("Fin_L", size=(1.0, 0.85, 0.22), at=(-1.8, -0.15, 1.2 + Z), role="coral", rot=(0, -24, -12), chamfer=0.05, mirror=True)
    m.box("FinTip_L", size=(0.36, 0.7, 0.24), at=(-2.36, -0.03, 0.95 + Z), role="coral_light", rot=(0, -24, -12), mirror=True)
    # pelvic fins
    m.box("Pelvic_L", size=(0.2, 0.55, 0.42), at=(-0.6, 0.35, 0.12 + Z), role="coral", rot=(-25, 0, 0), taper=(1, 0.5), mirror=True)
    # dorsal crest
    m.box("Dorsal", size=(0.24, 1.25, 0.8), at=(0, 0.78, 3.38 + Z), role="coral", taper=(1, 0.3), shear=(0, 0.45))
    m.box("DorsalTip", size=(0.26, 0.38, 0.22), at=(0, 1.21, 3.86 + Z), role="coral_light")
    # bubble
    m.box("Bubble", size=(1.6, 1.6, 1.6), at=(0, -0.45, 3.8 + Z), role="bubble", chamfer=0.38)
    m.box("BubbleSmall", size=(0.62, 0.62, 0.62), at=(0.74, 0.27, 4.52 + Z), role="bubble", chamfer=0.15, solo=True)

    # --- paint : scales first, then the face ---
    arc = ["A...A", ".AAA."]
    for (u, v, c) in [(-0.75, 0.45, "aqua"), (-0.2, 0.15, "teal_dark"), (-0.8, -0.15, "aqua"), (-0.25, -0.5, "aqua"), (0.15, 0.55, "teal_dark")]:
        m.stamp("Body", "left", (u, v), arc, {"A": c})
        m.stamp("Body", "right", (-u, v), arc, {"A": c})
    for (u, v, c) in [(-0.6, 0.35, "aqua"), (0.55, 0.1, "aqua"), (0.0, -0.35, "teal_dark"), (-0.55, -0.45, "aqua"), (0.6, 0.6, "teal_dark")]:
        m.stamp("Body", "back", (u, v), arc, {"A": c})
    for (u, v, c) in [(-0.85, 0.55, "aqua"), (0.85, 0.55, "aqua"), (-0.55, 0.95, "teal_dark"), (0.55, 0.95, "teal_dark"), (-0.95, -0.2, "teal_dark"), (0.95, -0.2, "teal_dark")]:
        m.stamp("Body", "top", (u, v), arc, {"A": c})
    m.stamp("Body", "front", (-0.66, 0.28), ["KKKKK", "KWWKK", "KWWKK", "KKKKK", "KKKWK", "KKKKK"], {"K": "eye", "W": "white"})
    m.stamp("Body", "front", (0.66, 0.28), ["KKKKK", "KKWWK", "KKWWK", "KKKKK", "KWKKK", "KKKKK"], {"K": "eye", "W": "white"})
    m.rect("Body", "front", (-0.9, -0.36), (0.36, 0.19), "blush")
    m.rect("Body", "front", (0.9, -0.36), (0.36, 0.19), "blush")
    m.stamp("Body", "front", (0, -0.5), ["K....K", ".KKKK.", "..TT.."], {"K": "eye", "T": "tongue"})
    # fin rays
    for v in (-0.22, 0.0, 0.22):
        m.line("Fin_L", "top", [(-0.35, v), (0.45, v)], "coral_dark", 1)
    for (a, b) in [((0.5, 0.0), (-0.55, 0.85)), ((0.5, 0.0), (-0.55, 0.3)), ((0.5, 0.0), (-0.55, -0.3)), ((0.5, 0.0), (-0.55, -0.85))]:
        m.line("TailFan", "left", [a, b], "coral_dark", 1)
        m.line("TailFan", "right", [(-a[0], a[1]), (-b[0], b[1])], "coral_dark", 1)
    for (a, b) in [((0.3, -0.3), (-0.1, 0.3)), ((0.0, -0.3), (-0.4, 0.2))]:
        m.line("Dorsal", "left", [a, b], "coral_dark", 1)
        m.line("Dorsal", "right", [(-a[0], a[1]), (-b[0], b[1])], "coral_dark", 1)
    # bubble highlights
    for face in ("front", "left", "right", "back", "top"):
        m.stamp("Bubble", face, (-0.16, 0.16), ["WWW.", "W...", "W..."], {"W": "white"})
        m.rect("Bubble", face, (0.22, -0.22), (0.13, 0.13), "white")
        m.line("Bubble", face, [(-0.1, -0.36), (0.36, -0.36), (0.36, 0.1)], "bubble_rim", 1)
        m.rect("BubbleSmall", face, (-0.06, 0.06), (0.13, 0.13), "white")
    return m


m = build_guppy()
print(m.build())
print(m.check())
ropilot.check_model(collection="R8_T2", max_lines=8)
make_translucent("R8_T2", {"Bubble", "BubbleSmall"})
print(save_copy("R8_T2"))

# --- suite (faite a la main apres ce script) ---
# rig_join("R8_T2", {"FinL": ["Fin_L", "FinTip_L"], "FinR": ["Fin_R", "FinTip_R"],
#                    "Tail": ["Stalk", "TailRing", "TailFan", "TailTip*"], "Body__Bubble": ["Bubble", "BubbleSmall"]})
# Studio, apres CreatureRig.Install : la piece RopilotBlenderObject == "R8_T2:Body__Bubble" -> Transparency 0.35, CastShadow false
