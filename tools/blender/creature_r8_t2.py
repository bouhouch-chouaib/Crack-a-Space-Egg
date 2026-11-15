# Bubble Guppy (R8_T2, Uncommon) v2 : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R8_Refs/Ref_R8_T2_*.png,
# 2e generation : la 1re donnait une boule). Bulles en chapelet depuis le coin de la bouche (pieces translucides).
import ropilot, bpy, os
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R8_Refs")
REF = {v: os.path.join(R, f"Ref_R8_T2_{v}.png") for v in ("front", "left", "back", "top")}
PAL2 = {'teal': {'color': '#28aaa8', 'noise': 0.035, 'shade': 0.15, 'mottle': ('#1f9896', 0.2, 4), 'top': 0.1},
        'teal_dark': {'color': '#1b8587', 'noise': 0.03, 'shade': 0.12},
        'aqua': {'color': '#7fe6d6', 'noise': 0.03},
        'belly': {'color': '#f4e6c4', 'noise': 0.03, 'shade': 0.1},
        'coral': {'color': '#ff7a6e', 'noise': 0.03, 'shade': 0.12, 'top': 0.08},
        'coral_dark': {'color': '#e2564e', 'noise': 0.03},
        'coral_light': {'color': '#ffb59c', 'noise': 0.03, 'shade': 0.08},
        'eye': '#101c30', 'mouth': '#2a1830', 'white': '#ffffff', 'blush': '#ff9fb0', 'tongue': '#ff6f7d',
        'pearl': {'color': '#fbf7ef', 'noise': 0.015, 'shade': 0.1},
        'bubble': {'color': '#c4f1fa', 'noise': 0.015, 'shade': 0.06},
        'bubble_rim': {'color': '#8fd9ec', 'noise': 0.02}}


def loft_y(m, prefix, sl, role, chamfer=0.2, faces=None, lip=0.15):
    # slices (y, centre z, height, width) from front (-y) to back (+y); taper and shear on the front end
    names = []
    for i in range(len(sl) - 1):
        y0, z0, h0, w0 = sl[i]
        y1, z1, h1, w1 = sl[i + 1]
        last = i == len(sl) - 2
        k = 1.0 if last else 1.03
        y1b = y1 if last else y1 + lip
        h1b, w1b = h1 * k, w1 * k
        n = f"{prefix}{i}"
        m.box(n, size=(w1b, y1b - y0, h1b), at=(0, (y0 + y1b) / 2, (z0 + z1) / 2), role=role, axis="y",
              taper=(w0 / w1b, h0 / h1b), shear=(0, z0 - z1), chamfer=chamfer, faces=faces)
        names.append(n)
    return names


BODY = [(-2.3, 1.28, 0.92, 0.88), (-1.85, 1.4, 1.8, 1.5), (-0.95, 1.46, 2.1, 1.62), (0.05, 1.45, 1.9, 1.4), (0.8, 1.52, 0.95, 0.78)]


def build_t2(m, bubbles=True):
    MR = dict(mirror=True)
    # ---- body: chubby oval, sand belly
    loft_y(m, "Body", BODY, "teal", 0.52, faces={"bottom": "belly"})
    # ---- tail: stalk + big fan (rig Tail)
    m.box("Stalk", size=(0.62, 0.55, 0.8), at=(0, 0.95, 1.53), role="teal", chamfer=0.12)
    m.box("TailBand", size=(0.7, 0.18, 0.9), at=(0, 0.72, 1.53), role="coral_dark", chamfer=0.05)
    m.box("TailFan", size=(0.46, 1.45, 2.3), at=(0, 1.85, 1.5), role="coral", axis="y", taper=(1.1, 0.38), chamfer=0.1)
    m.beam("TailLobeUp", start=(0, 2.0, 2.2), end=(0, 2.45, 2.62), role="coral", width=0.3, depth=0.5, taper=0.6)
    m.beam("TailLobeDn", start=(0, 2.0, 0.8), end=(0, 2.45, 0.12), role="coral", width=0.3, depth=0.5, taper=0.6)
    m.box("TailEdge", size=(0.48, 0.2, 1.6), at=(0, 2.6, 1.5), role="coral_light", chamfer=0.03)
    # ---- dorsal fin swept back
    m.box("Dorsal", size=(0.4, 1.9, 0.85), at=(0, -0.25, 2.6), role="coral", taper=(0.8, 0.5), shear=(0, 0.3), chamfer=0.06)
    m.box("DorsalTip", size=(0.32, 0.5, 0.18), at=(0, -0.08, 3.08), role="coral_light")
    # ---- pectoral fins (rig FinL / FinR)
    m.box("Fin_L", size=(0.12, 0.8, 0.62), at=(-0.9, -0.42, 1.08), role="coral", axis="y", taper=(1, 0.45), rot=(0, -15, -32), chamfer=0.03, **MR)
    # gill covers behind the eyes
    m.box("Gill_L", size=(0.16, 0.7, 0.1), at=m.surface("Body1", "left", (-0.36, -0.02)), role="teal_dark", chamfer=0.04, **MR)
    # ---- pelvic fins
    m.beam("Pelvic_L", start=(-0.36, -0.82, 0.7), end=(-0.5, -0.32, 0.1), role="coral", width=0.18, depth=0.55, taper=0.6, **MR)
    # ---- anal fin under the rear belly
    m.box("Anal", size=(0.3, 0.75, 0.42), at=(0, 0.4, 0.48), role="coral", taper=(1, 0.55), shear=(0, 0.2), rot=(180, 0, 0), chamfer=0.04)
    # ---- eyes: big square happy eyes, bulging on the sides of the head (seen from front and side)
    m.box("Eye_L", size=(0.2, 0.82, 0.84), at=(-0.86, -1.6, 1.44), role="white", chamfer=0.05, rot=(0, 0, 40), **MR)
    if bubbles:
        # bubble stream rising from the corner of the mouth (rig Body__Bubble : translucent in Studio)
        m.box("BubbleSmall", size=(0.28, 0.28, 0.28), at=(0.26, -2.34, 1.76), role="bubble", chamfer=0.05, solo=True)
        m.box("BubbleMid", size=(0.42, 0.42, 0.42), at=(0.36, -2.6, 2.06), role="bubble", chamfer=0.08, solo=True)
        m.box("Bubble", size=(0.84, 0.84, 0.84), at=(0.42, -2.88, 2.58), role="bubble", chamfer=0.17, solo=True)
    # ---- paint
    arc = ["A...A", ".AAA."]
    for face, sg in (("left", 1), ("right", -1)):
        for (u, v, c) in [(-0.35, 0.45, "aqua"), (0.1, 0.1, "teal_dark"), (-0.4, -0.2, "aqua"), (0.35, 0.5, "aqua")]:
            m.stamp("Body2", face, (sg * u, v), arc, {"A": c})
        for (u, v, c) in [(-0.2, 0.3, "teal_dark"), (0.2, -0.05, "aqua"), (-0.1, -0.35, "aqua")]:
            m.stamp("Body3", face, (sg * u, v), arc, {"A": c})
        # blush on the cheeks
        m.rect("Body0", face, (0.0, -0.12), (0.28, 0.18), "blush")
    m.stamp("Body0", "front", (0, -0.12), ["K......K", ".K....K.", "..KKKK..", "...TT..."], {"K": "mouth", "T": "tongue"})
    m.stamp("Eye_L", "left", (0.06, -0.04), ["KKKK", "KWKK", "KKKK", "KKKK", "KKKK"], {"K": "eye", "W": "white"})
    m.rect("Body0", "front", (-0.38, 0.2), (0.2, 0.13), "blush")
    m.rect("Body0", "front", (0.38, 0.2), (0.2, 0.13), "blush")
    for v in (-0.15, 0.05, 0.22):
        m.line("Fin_L", "left", [(0.35, 0.0), (-0.35, v)], "coral_dark", 1)
    for (a, b) in [((0.6, 0.0), (-0.65, 0.9)), ((0.6, 0.0), (-0.65, 0.3)), ((0.6, 0.0), (-0.65, -0.3)), ((0.6, 0.0), (-0.65, -0.9))]:
        m.line("TailFan", "left", [a, b], "coral_dark", 1)
        m.line("TailFan", "right", [(-a[0], a[1]), (-b[0], b[1])], "coral_dark", 1)
    for (a, b) in [((0.4, -0.3), (0.0, 0.25)), ((0.05, -0.3), (-0.3, 0.2))]:
        m.line("Dorsal", "left", [a, b], "coral_dark", 1)
        m.line("Dorsal", "right", [(-a[0], a[1]), (-b[0], b[1])], "coral_dark", 1)
    if bubbles:
        for face in ("front", "left", "right", "back", "top"):
            m.stamp("Bubble", face, (-0.14, 0.14), ["WWW", "W..", "W.."], {"W": "white"})
            m.line("Bubble", face, [(-0.05, -0.3), (0.3, -0.3), (0.3, 0.05)], "bubble_rim", 1)
            m.rect("BubbleMid", face, (-0.08, 0.08), (0.13, 0.13), "white")
    return m


def make_translucent(key, names, alpha=0.5, suffix="bubble"):
    # copie du materiau de l'atlas, en transparence (rendu Blender ; dans Studio : Transparency apres Install)
    base = bpy.data.materials[key + "_mat"]
    mat = bpy.data.materials.get(key + "_" + suffix)
    if mat:
        bpy.data.materials.remove(mat)
    mat = base.copy()
    mat.name = key + "_" + suffix
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


m = ropilot.model("R8_T2", px=8, reset=True)
m.reference(REF)
m.palette(**PAL2)
# compare() sans les bulles (absentes de la reference : elles changeraient l'echelle)
build_t2(m, bubbles=False)
print(m.build()); print(m.compare()["report"])
build_t2(m, bubbles=True)
print(m.build()); print(m.check())
ropilot.check_model(collection="R8_T2", max_lines=8)
make_translucent("R8_T2", {"Bubble", "BubbleMid", "BubbleSmall"}, alpha=0.5)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R8_T2.blend"), copy=True)
# --- suite : rig_join("R8_T2", GROUPS_T2), save R8_T2_rig.blend, import -> Work_R8_T2_v2,
# CreatureRig.Install(workspace.Work_R8_T2_v2, "R8_T2", nil, true)
# Studio, apres Install : la piece RopilotBlenderObject == "R8_T2:Body__Bubble" -> Transparency 0.35, CastShadow false
GROUPS_T2 = {'FinL': ['Fin_L'], 'FinR': ['Fin_R'], 'Tail': ['Stalk', 'TailBand', 'TailFan', 'TailLobe*', 'TailEdge'],
             'Body__Bubble': ['Bubble*']}
