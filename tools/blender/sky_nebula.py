# Ciel nébuleuse du jeu, peint de façon procédurale dans Blender puis rendu en 6 faces Roblox.
# À lancer dans le Blender de Ropilot (ropilot_blender_run_python) :
#   exec(open(r"<chemin>/tools/blender/sky_nebula.py", encoding="utf-8").read()); render_sky("A")
# Les faces prêtes pour Roblox sont écrites dans Documents/Ropilot/Blender/sky/roblox_<clé>/.
import bpy, math, os
import ropilot
from mathutils import Euler
from PIL import Image


def hexc(h, a=1.0):
    h = h.lstrip('#')
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    f = lambda c: c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (f(r), f(g), f(b), a)


def build_world(name, p):
    w = bpy.data.worlds.get(name) or bpy.data.worlds.new(name)
    w.use_nodes = True
    nt = w.node_tree
    nt.nodes.clear()
    N = nt.nodes
    Lk = nt.links.new
    out = N.new('ShaderNodeOutputWorld')
    bg = N.new('ShaderNodeBackground')
    bg.inputs['Strength'].default_value = p['strength']
    tc = N.new('ShaderNodeTexCoord')
    sep = N.new('ShaderNodeSeparateXYZ')
    Lk(tc.outputs['Generated'], sep.inputs[0])
    # Dégradé de fond, du bas vers le haut
    mr = N.new('ShaderNodeMapRange')
    mr.inputs['From Min'].default_value = -1
    mr.inputs['From Max'].default_value = 1
    Lk(sep.outputs['Z'], mr.inputs['Value'])
    grad = N.new('ShaderNodeValToRGB')
    cr = grad.color_ramp
    cr.elements[0].position = 0.0
    cr.elements[0].color = hexc(p['bottom'])
    cr.elements[1].position = 1.0
    cr.elements[1].color = hexc(p['top'])
    cr.elements.new(0.5).color = hexc(p['mid'])
    Lk(mr.outputs['Result'], grad.inputs['Fac'])
    # Fondu vers le zénith : pas de nuages au-dessus de ~35°, la face du dessus reste symétrique
    fade = N.new('ShaderNodeMapRange')
    fade.interpolation_type = 'SMOOTHSTEP'
    fade.inputs['From Min'].default_value = 0.35
    fade.inputs['From Max'].default_value = 0.62
    fade.inputs['To Min'].default_value = 1.0
    fade.inputs['To Max'].default_value = 0.0
    Lk(sep.outputs['Z'], fade.inputs['Value'])
    col = grad.outputs['Color']
    # Nuages de nébuleuse
    for layer in p['layers']:
        mp = N.new('ShaderNodeMapping')
        mp.inputs['Location'].default_value = layer['offset']
        Lk(tc.outputs['Generated'], mp.inputs['Vector'])
        nz = N.new('ShaderNodeTexNoise')
        nz.noise_dimensions = '3D'
        nz.inputs['Scale'].default_value = layer['scale']
        nz.inputs['Detail'].default_value = 7
        nz.inputs['Roughness'].default_value = 0.58
        nz.inputs['Distortion'].default_value = layer['distort']
        Lk(mp.outputs['Vector'], nz.inputs['Vector'])
        ramp = N.new('ShaderNodeValToRGB')
        r = ramp.color_ramp
        r.interpolation = 'EASE'
        r.elements[0].position = layer['lo']
        r.elements[0].color = (0, 0, 0, 1)
        r.elements[1].position = layer['hi']
        r.elements[1].color = (layer['alpha'],) * 3 + (1,)
        Lk(nz.outputs['Fac'], ramp.inputs['Fac'])
        mul = N.new('ShaderNodeMath')
        mul.operation = 'MULTIPLY'
        Lk(ramp.outputs['Color'], mul.inputs[0])
        Lk(fade.outputs['Result'], mul.inputs[1])
        nz2 = N.new('ShaderNodeTexNoise')
        nz2.inputs['Scale'].default_value = layer['scale'] * 0.6
        nz2.inputs['Detail'].default_value = 2
        Lk(mp.outputs['Vector'], nz2.inputs['Vector'])
        tint = N.new('ShaderNodeValToRGB')
        t = tint.color_ramp
        t.elements[0].position = 0.35
        t.elements[0].color = hexc(layer['c1'])
        t.elements[1].position = 0.65
        t.elements[1].color = hexc(layer['c2'])
        Lk(nz2.outputs['Fac'], tint.inputs['Fac'])
        mix = N.new('ShaderNodeMix')
        mix.data_type = 'RGBA'
        mix.blend_type = 'SCREEN'
        Lk(mul.outputs['Value'], mix.inputs['Factor'])
        Lk(col, mix.inputs[6])
        Lk(tint.outputs['Color'], mix.inputs[7])
        col = mix.outputs[2]
    # Étoiles (petites et grandes)
    for scale, size, power in p['stars']:
        vor = N.new('ShaderNodeTexVoronoi')
        vor.inputs['Scale'].default_value = scale
        vor.inputs['Randomness'].default_value = 1
        Lk(tc.outputs['Generated'], vor.inputs['Vector'])
        st = N.new('ShaderNodeMapRange')
        st.inputs['From Min'].default_value = size
        st.inputs['From Max'].default_value = 0.0
        st.inputs['To Min'].default_value = 0
        st.inputs['To Max'].default_value = power
        Lk(vor.outputs['Distance'], st.inputs['Value'])
        add = N.new('ShaderNodeMix')
        add.data_type = 'RGBA'
        add.blend_type = 'ADD'
        add.inputs['Factor'].default_value = 1.0
        Lk(col, add.inputs[6])
        rgb = N.new('ShaderNodeCombineColor')
        for k in range(3):
            Lk(st.outputs['Result'], rgb.inputs[k])
        Lk(rgb.outputs['Color'], add.inputs[7])
        col = add.outputs[2]
    Lk(col, bg.inputs['Color'])
    Lk(bg.outputs['Background'], out.inputs['Surface'])
    return w


PRESETS = {
    # A : nébuleuse lumineuse (violet, rose, touches turquoise)
    "A": dict(strength=1.1, bottom="#1E2452", mid="#3B2E8C", top="#2A4BA0",
              layers=[dict(offset=(0, 0, 0), scale=1.0, distort=0.9, lo=0.46, hi=0.76, alpha=0.95, c1="#8E5BE8", c2="#F06EB5"),
                      dict(offset=(7.3, 2.1, 4.4), scale=2.0, distort=0.6, lo=0.55, hi=0.8, alpha=0.85, c1="#3FC9D8", c2="#B57CF2")],
              stars=[(90, 0.05, 2.2), (28, 0.035, 4.0)]),
    # B : joyeux (bleu clair, pastels rose, lavande, menthe, pêche)
    "B": dict(strength=1.05, bottom="#2B44A0", mid="#3F5CC4", top="#3A86D6",
              layers=[dict(offset=(0, 0, 0), scale=1.0, distort=0.9, lo=0.45, hi=0.78, alpha=0.95, c1="#FF8FCB", c2="#A98BFF"),
                      dict(offset=(7.3, 2.1, 4.4), scale=2.0, distort=0.6, lo=0.55, hi=0.82, alpha=0.85, c1="#5FF0D6", c2="#FFD07A")],
              stars=[(90, 0.05, 2.6), (28, 0.035, 4.5)]),
}

# Directions des 6 rendus dans le repère Blender (Z en haut)
DIRS = {"PX": (90, 0, -90), "NX": (90, 0, 90), "PY": (90, 0, 0), "NY": (90, 0, 180), "PZ": (180, 0, 0), "NZ": (0, 0, 0)}


def render_sky(key):
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 6
    scene.cycles.device = 'CPU'
    scene.cycles.use_denoising = False
    scene.view_settings.view_transform = 'Standard'
    scene.render.resolution_x = scene.render.resolution_y = 1024
    for o in list(scene.objects):
        if o.type != 'CAMERA':
            o.hide_render = True
    cam = bpy.data.objects.get("SkyCam")
    if not cam:
        cam = bpy.data.objects.new("SkyCam", bpy.data.cameras.new("SkyCam"))
        scene.collection.objects.link(cam)
    cam.data.lens = 18
    cam.data.sensor_width = 36
    cam.data.sensor_fit = 'HORIZONTAL'
    cam.location = (0, 0, 0)
    scene.camera = cam
    scene.world = build_world("Sky_" + key, PRESETS[key])
    outdir = os.path.join(ropilot.FILES_DIR, "sky")
    os.makedirs(outdir, exist_ok=True)
    for face, rot in DIRS.items():
        cam.rotation_euler = Euler([math.radians(a) for a in rot], 'XYZ')
        scene.render.filepath = os.path.join(outdir, f"{key}_{face}.png")
        bpy.ops.render.render(write_still=True)
    # Faces au format Roblox (vérifié dans Studio le 5 nov. 2026) :
    # Ft = -Z = Blender +Y ; Bk = +Z = Blender -Y ; Rt = -X = Blender -X ; Lf = +X = Blender +X
    # Dn = Blender -Z tourné de 90° horaire ; Up = Blender +Z (sans nuages, donc symétrique)
    rb = os.path.join(outdir, "roblox_" + key)
    os.makedirs(rb, exist_ok=True)
    src = lambda f: Image.open(os.path.join(outdir, f"{key}_{f}.png"))
    src("PY").save(os.path.join(rb, f"Sky{key}_Ft.png"))
    src("NY").save(os.path.join(rb, f"Sky{key}_Bk.png"))
    src("NX").save(os.path.join(rb, f"Sky{key}_Rt.png"))
    src("PX").save(os.path.join(rb, f"Sky{key}_Lf.png"))
    src("NZ").rotate(-90).save(os.path.join(rb, f"Sky{key}_Dn.png"))
    src("PZ").save(os.path.join(rb, f"Sky{key}_Up.png"))
    # Bande de contrôle des 4 côtés, dans l'ordre où on les voit : Rt | Ft | Lf | Bk
    S = 256
    strip = Image.new("RGB", (S * 4, S))
    for i, f in enumerate(["Rt", "Ft", "Lf", "Bk"]):
        strip.paste(Image.open(os.path.join(rb, f"Sky{key}_{f}.png")).resize((S, S)), (i * S, 0))
    strip.save(os.path.join(outdir, f"{key}_bande.png"))
    return rb
