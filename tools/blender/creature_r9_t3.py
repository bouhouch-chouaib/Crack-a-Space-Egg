# Volt Beetle (R9_T3, Rare) : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio) rendue en vues orthogonales (Renders/R9_Refs/Ref_R9_T3_*.png)
# Carapace = pile : deux elytres violettes (cellule penchee vers la tete), bande doree « copper top » et borne
# d'acier a l'arriere, fenetre de charge avec eclair lumineux sur le dos, cellules de charge sur les flancs.
# compare() final : face 0.51, dos 0.51, gauche 0.63 (corps abaisse et pattes ecartees volontairement :
# la version la plus proche de la reference (0.72 / 0.75) avait l'air d'une table sur pieds).
import ropilot, bpy, os, math
R = os.path.join(os.path.dirname(ropilot.FILES_DIR), "Renders", "R9_Refs")
REF3 = {v: os.path.join(R, f"Ref_R9_T3_{v}.png") for v in ("front", "left", "back", "top")}
PAL3 = dict(
    shell=dict(color="#7b63dc", noise=0.035, shade=0.16, mottle=("#6c55cc", 0.2, 4), top=0.14),
    shell_dark=dict(color="#4a3a9e", noise=0.03, shade=0.12),
    shell_light=dict(color="#9e86ff", noise=0.03, shade=0.1),
    navy=dict(color="#2a1e5a", noise=0.03, shade=0.12),
    navy_light=dict(color="#3c2f7a", noise=0.03, shade=0.1),
    gold=dict(color="#ffcf3a", noise=0.03, shade=0.12, top=0.12, rim=-0.2),
    gold_dark=dict(color="#d99a1e", noise=0.03),
    steel=dict(color="#c9d3ea", noise=0.02, shade=0.12, top=0.12, rim=-0.25),
    cyan=dict(color="#a8ecff", noise=0.02, shade=0.08),
    eye="#140f33", white="#ffffff", blush="#ff9ab8",
    glow=dict(color="#ffd21a", glow=True), glow_cyan=dict(color="#3fd8ff", glow=True),
)
L, yc, tilt, zc = 2.8, 0.45, -14, 1.1     # longueur de la cellule, centre, inclinaison, hauteur du centre
T = (tilt, 0, 0)
FEET3 = ((-0.45, -0.95, -2.1), (0.25, 0.3, -2.35), (0.9, 1.55, -2.2))   # (y hanche, y pied, x pied)


def shell(T, zc=1.42, yc=0.4):
    # point (y, z) dans le repere de la cellule inclinee -> monde
    a = math.radians(-T[0])
    def P(y, z):
        return (0, yc + y * math.cos(a) - z * math.sin(a), zc - y * math.sin(a) + z * math.cos(a))
    return P


P = shell(T, zc=zc, yc=yc)
TOPZ, HZ = 0.65, 1.5


def shell_bottom_z(yw, off=-0.55):
    lo, hi = -3, 3
    for _ in range(40):
        mid = (lo + hi) / 2
        if P(mid, off)[1] < yw:
            lo = mid
        else:
            hi = mid
    return P(lo, off)[2]


def build_t3(m, H=1.3, UH=0.7, hz=1.5):
    MR = dict(mirror=True)
    global P, TOPZ, HZ
    P = shell(T, zc=zc, yc=yc); TOPZ = H / 2; HZ = hz
    px, py, pz = P(0, 0)
    m.box("Elytron_L", size=(1.5, L, H), at=(-0.75, py, pz), role="shell", chamfer=0.5, rot=T, faces={"bottom": "navy"}, **MR)
    m.box("SeamStrip", size=(0.1, L - 0.2, H + 0.05), at=(0, py, pz + 0.02), role="navy", rot=T)
    m.box("Under", size=(2.2, L - 0.3, UH), at=P(0.0, -H / 2 - UH / 2 + 0.2), role="navy", chamfer=0.25, rot=T, taper=(1.2, 1))
    m.box("RearBand", size=(3.04, 0.5, H + 0.06), at=P(L / 2 - 0.2, 0), role="gold", chamfer=0.5, rot=T)
    m.box("Terminal", size=(0.95, 0.3, 0.7), at=P(L / 2 + 0.1, 0), role="steel", chamfer=0.12, rot=T)
    m.box("TerminalNub", size=(0.46, 0.22, 0.36), at=P(L / 2 + 0.3, 0), role="steel", chamfer=0.05, rot=T)
    _, ty, tz = P(-L / 2 - 0.2, 0.05)
    m.box("Thorax", size=(2.1, 0.8, 1.1), at=(0, ty, tz), role="navy_light", chamfer=0.3, taper=(0.85, 0.9), axis="y", rot=T)
    _, ty2, tz2 = P(-L / 2 - 0.2, 0.62)
    m.box("ThoraxPlate", size=(1.5, 0.62, 0.14), at=(0, ty2, tz2), role="shell_light", chamfer=0.04, rot=T)
    m.box("Head", size=(1.3, 0.85, 0.95), at=(0, ty - 0.6, hz), role="shell_light", chamfer=0.26, taper=(0.9, 0.9), axis="y")
    return m


def on_top(m, name, size, y, x=0.0, role="navy", zrot=0, lift=0.0, **kw):
    _, py, pz = P(y, TOPZ + size[2] / 2 - 0.04 + lift)
    m.box(name, size=size, at=(x, py, pz), role=role, rot=(tilt, 0, zrot), **kw)


def details(m):
    MR = dict(mirror=True)
    # fenetre de charge sur le dos, eclair lumineux (3 morceaux)
    on_top(m, "WinRim", (1.25, 1.75, 0.1), -0.15, role="gold", chamfer=0.03)
    on_top(m, "Window", (1.05, 1.55, 0.12), -0.15, role="navy", chamfer=0.03, lift=0.04)
    on_top(m, "BoltA", (0.2, 0.58, 0.08), -0.55, x=0.1, role="glow", zrot=-28, lift=0.13, solo=True)
    on_top(m, "BoltB", (0.5, 0.2, 0.08), -0.18, role="glow", lift=0.13)
    on_top(m, "BoltC", (0.2, 0.58, 0.08), 0.2, x=-0.1, role="glow", zrot=-28, lift=0.13, solo=True)
    # cellules de charge sur les flancs (la premiere luit en cyan)
    for i, y in enumerate((-0.75, -0.2, 0.35)):
        _, py, pz = P(y, -0.05)
        m.box(f"Cell{i}_L", size=(0.1, 0.45, 0.45), at=(-1.52, py, pz), role="glow_cyan" if i == 0 else "gold", rot=T, **MR)
    # visage
    hz = HZ
    _, ty, tz = P(-L / 2 - 0.2, 0.05)
    fy = ty - 0.6 - 0.43
    m.box("Eye_L", size=(0.38, 0.08, 0.42), at=(-0.3, fy - 0.02, hz + 0.1), role="eye", chamfer=0.02, **MR)
    m.box("Shine_L", size=(0.15, 0.05, 0.15), at=(-0.37, fy - 0.06, hz + 0.19), role="white", **MR)
    m.box("Shine2_L", size=(0.07, 0.05, 0.07), at=(-0.21, fy - 0.06, hz - 0.03), role="white", **MR)
    m.prism("Mandible_L", radius=0.11, height=0.34, at=(-0.3, fy - 0.01, hz - 0.36), role="gold", sides=4, taper=0, rot=(90, 0, 25), **MR)
    # antennes a etincelles
    ay = fy + 0.3
    m.box("AntBase_L", size=(0.22, 0.22, 0.16), at=(-0.3, ay, hz + 0.47), role="gold", chamfer=0.04, **MR)
    m.beam("Antenna_L", start=(-0.3, ay, hz + 0.45), end=(-0.6, ay - 0.35, hz + 0.95), role="navy", width=0.14, depth=0.14, **MR)
    m.beam("Antenna2_L", start=(-0.6, ay - 0.35, hz + 0.95), end=(-0.95, ay - 0.6, hz + 1.3), role="navy", width=0.13, depth=0.13, **MR)
    m.box("AntBall_L", size=(0.2, 0.2, 0.2), at=(-0.6, ay - 0.35, hz + 0.95), role="steel", **MR)
    m.crystal("Spark_L", radius=0.17, height=0.45, at=(-0.97, ay - 0.62, hz + 1.25), role="glow", sides=4, tip=0.5, rot=(25, -20, 0), **MR)
    # peinture
    for sd, face, sg in (("L", "left", 1), ("R", "right", -1)):
        m.line("Elytron_" + sd, face, [(sg * -0.35, 0.4), (sg * 0.05, 0.05), (sg * -0.3, 0.0), (sg * 0.1, -0.35)], "gold", 2)
    m.stamp("RearBand", "back", (0, 0.05), [".G.", "GGG", ".G."], {"G": "navy"}, cell=0.125)
    m.rect("Head", "front", (-0.45, -0.25), (0.18, 0.1), "blush")
    m.rect("Head", "front", (0.45, -0.25), (0.18, 0.1), "blush")
    m.stamp("Head", "front", (0, -0.22), ["K..K", ".KK."], {"K": "eye"})
    m.line("Thorax", "front", [(-0.75, 0.3), (0.75, 0.3)], "shell", 1)


def under(m, W=1.8, UH=0.4):
    m.box("Under", size=(W, L - 0.4, UH), at=P(0.0, -0.65 - UH / 2 + 0.2), role="navy", chamfer=0.2, rot=T, taper=(1.2, 1))


def legs(m, w=0.34, feet=FEET3, up=0.4, kx=-1.75):
    # six pattes d'insecte : cuisse vers le haut et l'exterieur, genou dore, tibia vers le sol, griffe sombre
    MR = dict(mirror=True)
    for i, (y, fy, fx) in enumerate(feet):
        hz_ = shell_bottom_z(y, -0.45)
        hip, knee, foot = (-0.95, y, hz_), (kx, (y + fy) / 2, hz_ + up), (fx, fy, 0.16)
        m.beam(f"LegU{i}_L", start=hip, end=knee, role="navy", width=w * 0.9, depth=w * 0.9, **MR)
        m.beam(f"LegD{i}_L", start=knee, end=foot, role="navy_light", width=w, depth=w, taper=0.8, **MR)
        m.box(f"Knee{i}_L", size=(w + 0.08,) * 3, at=knee, role="gold", chamfer=0.05, **MR)
        m.box(f"Claw{i}_L", size=(w + 0.1, w + 0.16, 0.16), at=(fx, fy - 0.04, 0.08), role="navy", chamfer=0.04, **MR)


def extra(m):
    # bandes claires sur les elytres (arrondit le dos)
    _, py, pz = P(-0.05, TOPZ + 0.05)
    m.box("Dome_L", size=(0.5, L - 0.7, 0.16), at=(-0.95, py, pz - 0.06), role="shell_light", chamfer=0.05, rot=T, mirror=True)


m3 = ropilot.model("R9_T3", px=8, reset=True)
m3.reference(REF3)
m3.palette(**PAL3)
build_t3(m3, 1.3, hz=1.5); details(m3); under(m3); legs(m3); extra(m3)
print(m3.build()); print(m3.check()); print(m3.compare()["report"])
ropilot.check_model(collection="R9_T3", max_lines=8)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ropilot.FILES_DIR, "R9_T3.blend"), copy=True)
# --- suite : exec(rigjoin.py), rig_join("R9_T3", GROUPS_T3), save R9_T3_rig.blend, import -> Work_R9_T3,
# CreatureRig.Install(workspace.Work_R9_T3, "R9_T3", nil, true), puis joints des pattes mis aux hanches
# (Install les met au centre de la patte) : LegF (+-1.0, 0.95, -0.45), Leg (+-1.0, 0.78, 0.25), LegB (+-1.0, 0.62, 0.9)
def lg(i, s):
    return [f"LegU{i}_{s}", f"LegD{i}_{s}", f"Knee{i}_{s}", f"Claw{i}_{s}"]
GROUPS_T3 = {'Head': ['Head', 'Eye_*', 'Shine*', 'Mandible_*', 'AntBase_*', 'Antenna*', 'AntBall_*', 'Spark_*'],
             'LegFL': lg(0, 'L'), 'LegFR': lg(0, 'R'), 'LegL': lg(1, 'L'), 'LegR': lg(1, 'R'), 'LegBL': lg(2, 'L'), 'LegBR': lg(2, 'R')}
