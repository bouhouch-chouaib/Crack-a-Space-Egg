# Lantern Jelly (R8_T4, Epic) v2 : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R8_Refs/Ref_R8_T4_*.png)
# Cloche a facettes (prismes a 8 pans) translucide, lanterne qui la traverse par le dessous,
# 6 tentacules ondulants (3 a gauche, 3 a droite) et 4 rubans buccaux au centre.
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R8_Refs")
REF = {v: os.path.join(R, f"Ref_R8_T4_{v}.png") for v in ("front", "left", "back", "top")}
PAL4 = {'glass': {'color': '#45cdc4', 'noise': 0.015, 'shade': 0.06, 'top': 0.12},
        'glass_dark': {'color': '#2aa9a5', 'noise': 0.015},
        'coral': {'color': '#ff7a6e', 'noise': 0.03, 'shade': 0.12, 'top': 0.08},
        'coral_dark': {'color': '#d9544c', 'noise': 0.03},
        'coral_light': {'color': '#ffb39c', 'noise': 0.03, 'shade': 0.08},
        'teal': {'color': '#28aaa8', 'noise': 0.035, 'shade': 0.14},
        'aqua': {'color': '#7fe6d6', 'noise': 0.03, 'shade': 0.1},
        'navy': {'color': '#22347e', 'noise': 0.03, 'shade': 0.12, 'top': 0.1},
        'gold': {'color': '#f2c14e', 'noise': 0.03, 'shade': 0.14, 'top': 0.12},
        'pearl': {'color': '#fbf7ef', 'noise': 0.015, 'shade': 0.1},
        'blush': '#ff9fb0', 'white': '#ffffff', 'mouth': '#1a2350',
        'glow': {'color': '#22d8f0', 'glow': True},
        'flame': {'color': '#ffa41c', 'glow': True}}

S = dict(solo=True)
RT = 1.3   # tentacle ring radius
CR = 1.6  # crown branch reach
RW = 0.8   # oral ribbon width
# 6 tentacles, k hangs at angle 60k (0 = +x): mirror pairs 0/3, 1/2, 4/5 (front pair shorter, the sides reach the ground)
A6 = [math.radians(60 * k) for k in range(6)]
TENT_END = {0: 0.12, 3: 0.12, 1: 0.6, 2: 0.6, 4: 1.25, 5: 1.25}
TENT_SIGN = {0: 1, 3: -1, 1: 1, 2: -1, 4: 1, 5: -1}


def ring_pt(a, r, t, z):
    # point at angle a, radius r, tangential offset t
    return (r * math.cos(a) - t * math.sin(a), r * math.sin(a) + t * math.cos(a), z)


def build_t4(m):
    # ---------------- bell: faceted octagonal cloche (glass) on a coral rim ----------------
    m.prism("Rim", radius=2.6, height=0.32, at=(0, 0, 4.86), role="coral", sides=8)
    m.prism("BellLow", radius=2.55, height=0.95, at=(0, 0, 5.47), role="glass", sides=8, taper=0.97)
    m.prism("BellMid", radius=2.47, height=0.8, at=(0, 0, 6.33), role="glass", sides=8, taper=0.78)
    m.prism("BellTop", radius=1.93, height=0.55, at=(0, 0, 6.99), role="glass", sides=8, taper=0.52)
    # scalloped (festooned) edge under the rim, one lobe per facet
    for k in range(8):
        a = math.radians(-90 + 45 * k)
        x, y, _ = ring_pt(a, 2.22, 0, 0)
        m.box(f"Scallop{k}", size=(1.05, 0.26, 0.32), at=(x, y, 4.6), role="coral_light", taper=(0.45, 1), rot=(180, 0, 45 * k), **S)
    # ---------------- lantern: hangs through the bell, glowing flame inside the dome ----------------
    m.prism("LanternBase", radius=0.56, height=0.3, at=(0, 0, 4.42), role="navy", sides=6)
    m.box("LanternRing", size=(0.72, 0.72, 0.14), at=(0, 0, 4.22), role="gold", chamfer=0.04)
    m.crystal("Flame", radius=0.48, height=1.75, at=(0, 0, 4.5), role="flame", sides=6, tip=0.45, base_tip=0.25)
    for i, a in enumerate((0, 120, 240)):
        ar = math.radians(a + 30)
        m.beam(f"LanternBar{i}", start=(0.48 * math.cos(ar), 0.48 * math.sin(ar), 4.5), end=(0.36 * math.cos(ar), 0.36 * math.sin(ar), 5.6),
               role="gold", width=0.12, depth=0.12, **S)
    # ---------------- crown of coral with pearls and a glowing gem ----------------
    m.prism("CrownBand", radius=1.05, height=0.24, at=(0, 0, 7.33), role="coral", sides=8)
    for k in range(4):
        a = math.radians(90 * k)
        x, y, _ = ring_pt(a, 1.0, 0, 0)
        m.beam(f"CrownBranch{k}", start=(x * 0.75, y * 0.75, 7.3), end=(x * CR, y * CR, 7.95), role="coral", width=0.26, taper=0.7, **S)
        m.box(f"CrownPearl{k}", size=(0.22, 0.22, 0.22), at=(x * CR, y * CR, 7.98), role="pearl", **S)
    m.crystal("CrownGem", radius=0.26, height=0.72, at=(0, 0, 7.25), role="glow", sides=4)
    # ---------------- face on the front facet: glowing eyes, pupils, smile, blush ----------------
    fy = -2.33
    m.box("Eye_L", size=(0.56, 0.16, 0.66), at=(-0.62, fy, 5.5), role="glow", rot=(-2, 0, 0), mirror=True)
    m.box("Pupil_L", size=(0.28, 0.08, 0.38), at=(-0.58, fy - 0.1, 5.47), role="mouth", rot=(-2, 0, 0), mirror=True)
    m.box("Shine_L", size=(0.1, 0.06, 0.1), at=(-0.64, fy - 0.15, 5.59), role="white", rot=(-2, 0, 0), mirror=True)
    m.beam("Smile_L", start=(-0.26, fy - 0.03, 5.12), end=(-0.04, fy - 0.03, 5.05), role="mouth", width=0.1, depth=0.12, mirror=True)
    m.box("Blush_L", size=(0.36, 0.08, 0.16), at=(-1.12, fy + 0.0, 5.18), role="blush", mirror=True)
    # ---------------- tentacles: gentle S-waves of four tapering beams, glowing tips on the long ones ----------------
    for k in range(6):
        a = A6[k]
        z0, z4 = 4.8, TENT_END[k]
        zs = [z0 - (z0 - z4) * f for f in (0, 0.27, 0.52, 0.77, 1.0)]
        sg = TENT_SIGN[k]
        ts = [t * sg for t in (0.0, 0.24, -0.2, 0.18, -0.08)]
        rs = [RT + d for d in (0.0, 0.16, 0.04, 0.14, 0.06)]
        pts = [ring_pt(a, rs[i], ts[i], zs[i]) for i in range(5)]
        for i in range(4):
            m.beam(f"Tent{k}_{i}", start=pts[i], end=pts[i + 1], role=("teal", "teal", "aqua", "aqua")[i],
                   width=(0.3, 0.26, 0.22, 0.18)[i], taper=0.88, **S)
        if z4 < 1.0:
            m.box(f"TentTip{k}", size=(0.2, 0.2, 0.26), at=(pts[4][0], pts[4][1], pts[4][2] + 0.04), role="glow", **S)
    # ---------------- oral arms: frilly ribbons under the lantern (long at the back, shorter at the front) ----------------
    for k in range(4):
        a = math.radians(45 + 90 * k)
        sg = 1 if k in (0, 2) else -1
        z0, z2 = 4.3, (0.12 if k < 2 else 0.9)
        p0 = ring_pt(a, 0.28, 0, z0)
        p1 = ring_pt(a, 0.75, 0.18 * sg, z0 - (z0 - z2) * 0.5)
        p2 = ring_pt(a, 0.5, -0.12 * sg, z2)
        m.beam(f"Ribbon{k}_0", start=p0, end=p1, role="coral", width=RW, depth=0.12, taper=0.9, roll=45 + 90 * k, **S)
        m.beam(f"Ribbon{k}_1", start=p1, end=p2, role="coral_light", width=RW * 0.9, depth=0.1, taper=0.6, roll=45 + 90 * k, **S)
    # ---------------- paint ----------------
    for n in ("BellLow", "BellMid"):
        for face in ("side%d" % i for i in range(8)):
            m.rect(n, face, (0.3, 0.15), (0.13, 0.13), "white")
            m.rect(n, face, (-0.35, -0.2), (0.13, 0.13), "glass_dark")
    for k in range(4):
        m.line(f"Ribbon{k}_0", "front", [(0, -0.5), (0, 0.5)], "coral_dark", 1)
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


m4 = ropilot.model("R8_T4", px=8, reset=True)
m4.reference(REF)
m4.palette(**PAL4)
build_t4(m4)
print(m4.build()); print(m4.check()); print(m4.compare()["report"])
ropilot.check_model(collection="R8_T4", max_lines=8)
make_translucent("R8_T4", {"BellLow", "BellMid", "BellTop"}, alpha=0.45, suffix="glass")
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R8_T4.blend"), copy=True)
# --- suite : rig_join("R8_T4", GROUPS_T4), save R8_T4_rig.blend, import -> Work_R8_T4_v2,
# CreatureRig.Install(workspace.Work_R8_T4_v2, "R8_T4", nil, true)
# Studio, apres Install : la piece RopilotBlenderObject == "R8_T4:Body__Glass" -> Transparency 0.35, CastShadow false ;
# joints FinL / FinR remontes en haut des tentacules (sous le bord de la cloche)
# Tentacles = rubans buccaux (balancement lent) ; FinL / FinR = tentacules gauches / droits (s'ouvrent et se ferment)
GROUPS_T4 = {'Tentacles': ['Ribbon*'], 'FinL': ['Tent2_*', 'Tent3_*', 'Tent4_*', 'TentTip2', 'TentTip3'],
             'FinR': ['Tent0_*', 'Tent1_*', 'Tent5_*', 'TentTip0', 'TentTip1'], 'Body__Glass': ['BellLow', 'BellMid', 'BellTop']}
