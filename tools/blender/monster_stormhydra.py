# Storm Hydra (monstre de l'anneau 9, Model « StormHydra ») : kit ropilot.model, px = 8, sans picots
# Reference de forme : generate_mesh (Studio, workspace.GenM_StormHydra) rendue en vues orthogonales
# (Renders/Monster_Refs/GenM_StormHydra_*.png) ; elle n'a qu'une vraie tete, la silhouette suit donc le brief :
# hydre trapue a quatre pattes puissantes, trois longs cous (le central plus haut, les deux autres ecartes),
# trois tetes qui rugissent gueule ouverte (dents creme, langue), yeux jaunes lumineux sous des arcades,
# cornes recourbees, eclairs jaunes lumineux en zigzag sur les cretes des tetes, du dos et au bout de la queue ;
# ecailles violet sombre, ventre en plaques lavande ; ailes faites de nuages d'orage (gros blocs gris-violet
# arrondis portes par un bras d'aile) d'ou tombent des eclairs ; queue epaisse a pointes.
# Usage : exec(open(r"<repo>/tools/blender/monster_common_b.py").read()) puis exec de ce fichier.
import ropilot, bpy, math

PAL_MH = dict(
    scale=dict(color="#4a2a6e", noise=0.035, shade=0.16, mottle=("#3f2460", 0.25, 4), top=0.14),
    scale_dark=dict(color="#2e1846", noise=0.03, shade=0.12, top=0.1),
    scale_light=dict(color="#6a43a0", noise=0.03, shade=0.14, top=0.14),
    belly=dict(color="#a58cc8", noise=0.025, shade=0.12, top=0.08, rim=-0.18),
    horn=dict(color="#ddd6ea", noise=0.02, shade=0.14, top=0.12),
    horn_dark=dict(color="#a99fbe", noise=0.02, shade=0.12),
    cloud=dict(color="#77729c", noise=0.04, shade=0.22, mottle=("#837eaa", 0.3, 5), top=0.22),
    cloud_light=dict(color="#aaa5cc", noise=0.04, shade=0.2, mottle=("#b8b4d6", 0.3, 5), top=0.2),
    cloud_dark=dict(color="#4a4664", noise=0.03, shade=0.16, top=0.16),
    tooth=dict(color="#f4f0e0", noise=0.02, shade=0.12),
    tongue=dict(color="#b8507a", noise=0.03, shade=0.12),
    mouth="#1e0a24", eye="#140a08", shine="#ffffff",
    glow=dict(color="#f0cc14", glow=True),
)
MRH = dict(mirror=True)


def rotz_mh(v, deg):
    a = math.radians(deg)
    return (v[0] * math.cos(a) - v[1] * math.sin(a), v[0] * math.sin(a) + v[1] * math.cos(a), v[2])


def head_mh(m, pre, origin, yaw, s, **kw):
    # tete de dragon qui rugit, construite en coordonnees locales (avant -Y) puis tournee de `yaw` et mise a l'echelle `s`
    # (Blender : rotation de -yaw autour de z pour que +yaw tourne l'avant vers +X, comme rot=(0, 0, +z) du kit)
    def P(v):
        r = rotz_mh(v, yaw)
        return (origin[0] + r[0] * s, origin[1] + r[1] * s, origin[2] + r[2] * s)

    def S(v):
        return tuple(c * s for c in v)

    def R(rx=0, ry=0, rz=0):
        return (rx, ry, rz + yaw)

    sfx = "_L" if kw.get("mirror") else ""
    m.box(f"{pre}Skull{sfx}", size=S((2.8, 2.6, 2.4)), at=P((0, 0.3, 0.55)), role="scale", chamfer=0.65 * s, taper=(0.78, 0.8), rot=R(),
          faces={"bottom": "belly"}, **kw)
    m.box(f"{pre}Snout{sfx}", size=S((1.9, 2.7, 0.95)), at=P((0, -2.0, 0.62)), role="scale", chamfer=0.3 * s, axis="y", taper=(0.75, 0.8),
          rot=R(-7), **kw)
    m.box(f"{pre}SnoutTop{sfx}", size=S((1.2, 2.2, 0.2)), at=P((0, -1.9, 1.12)), role="scale_light", chamfer=0.05 * s, axis="y", taper=(0.6, 1),
          rot=R(-7), **kw)
    m.box(f"{pre}Nose{sfx}", size=S((0.26, 0.2, 0.2)), at=P((-0.34, -3.33, 0.98)), role="scale_dark", rot=R(-7), **kw)
    m.box(f"{pre}NoseB{sfx}", size=S((0.26, 0.2, 0.2)), at=P((0.34, -3.33, 0.98)), role="scale_dark", rot=R(-7), **kw)
    m.box(f"{pre}MouthIn{sfx}", size=S((1.5, 2.0, 0.85)), at=P((0, -1.5, -0.12)), role="mouth", rot=R(), **kw)
    m.box(f"{pre}Jaw{sfx}", size=S((1.9, 2.5, 0.55)), at=P((0, -1.75, -0.85)), role="scale", chamfer=0.15 * s, axis="y", taper=(0.75, 0.85),
          rot=R(16), faces={"top": "tongue", "bottom": "belly"}, **kw)
    for k, x in enumerate((-0.62, -0.25, 0.25, 0.62)):
        L = 0.95 if k in (0, 3) else 0.55
        m.prism(f"{pre}ToothU{k}{sfx}", radius=0.2 * s, height=L * s, at=P((x * 0.92, -2.75 + 0.3 * abs(x), 0.2 - L / 2 + 0.1)), role="tooth", sides=4,
                taper=0, rot=R(180), **kw)
    for k, x in enumerate((-0.55, 0.55)):
        m.prism(f"{pre}ToothL{k}{sfx}", radius=0.19 * s, height=0.85 * s, at=P((x, -2.5, -0.35)), role="tooth", sides=4, taper=0, rot=R(-16), **kw)
    m.box(f"{pre}Iris{sfx}", size=S((0.85, 0.22, 0.6)), at=P((-0.82, -0.98, 1.45)), role="glow", rot=R(0, 0, -16), **kw)
    m.box(f"{pre}IrisB{sfx}", size=S((0.85, 0.22, 0.6)), at=P((0.82, -0.98, 1.45)), role="glow", rot=R(0, 0, 16), **kw)
    m.box(f"{pre}Pupil{sfx}", size=S((0.22, 0.06, 0.48)), at=P((-0.78, -1.12, 1.43)), role="eye", rot=R(0, 0, -16), **kw)
    m.box(f"{pre}PupilB{sfx}", size=S((0.22, 0.06, 0.48)), at=P((0.78, -1.12, 1.43)), role="eye", rot=R(0, 0, 16), **kw)
    m.beam(f"{pre}Brow{sfx}", start=P((-1.35, -0.85, 2.05)), end=P((-0.3, -1.05, 1.8)), role="scale_dark", width=0.32 * s, depth=0.42 * s, **kw)
    m.beam(f"{pre}BrowB{sfx}", start=P((1.35, -0.85, 2.05)), end=P((0.3, -1.05, 1.8)), role="scale_dark", width=0.32 * s, depth=0.42 * s, **kw)
    for side, nm in ((-1, "HornA"), (1, "HornB")):
        HN = [(0.75 * side, 0.6, 1.3), (1.25 * side, 1.6, 2.0), (1.5 * side, 2.8, 2.25), (1.35 * side, 3.7, 1.85)]
        for i in range(3):
            m.beam(f"{pre}{nm}{i}{sfx}", start=P(HN[i]), end=P(HN[i + 1]), role=("horn", "horn", "horn_dark")[i],
                   width=(0.55, 0.45, 0.32)[i] * s, depth=(0.55, 0.45, 0.32)[i] * s, taper=(0.82, 0.7, 0.45)[i], **kw)
        m.prism(f"{pre}Cheek{nm}{sfx}", radius=0.25 * s, height=0.9 * s, at=P((1.45 * side, -0.2, -0.1)), role="horn_dark", sides=4, taper=0,
                rot=R(-60, 70 * side), **kw)
    # crete : eclair jaune en zigzag sur le dessus du crane, sur une crete sombre
    m.box(f"{pre}CrestBase{sfx}", size=S((0.35, 2.0, 0.6)), at=P((0, 0.5, 1.5)), role="scale_dark", rot=R(), **kw)
    ZZ = [(0, -0.4, 1.6), (0, 0.15, 2.7), (0, 0.65, 2.25), (0, 1.25, 3.55)]
    for i in range(len(ZZ) - 1):
        m.beam(f"{pre}Bolt{i}{sfx}", start=P(ZZ[i]), end=P(ZZ[i + 1]), role="glow", width=0.28 * s, depth=0.32 * s, taper=0.8 if i < 2 else 0.3, **kw)


def bolt_mh(m, name, pts, w, **kw):
    # eclair en zigzag (glow) : segments qui s'affinent
    for i in range(len(pts) - 1):
        m.beam(f"{name}{i}" + ("_L" if kw.get("mirror") else ""), start=pts[i], end=pts[i + 1], role="glow", width=w * (1 - 0.18 * i),
               depth=w * (1 - 0.18 * i), taper=0.8 if i < len(pts) - 2 else 0.2, **kw)


def build_mh(m):
    # ---- corps trapu, ventre en plaques, epaules et hanches
    m.box("Body", size=(7.4, 9.0, 5.6), at=(0, 1.6, 5.6), role="scale", chamfer=1.9, taper=(0.86, 0.9), faces={"bottom": "belly"})
    m.box("Chest", size=(6.6, 3.4, 4.6), at=(0, -2.2, 6.4), role="scale", chamfer=1.4, taper=(0.82, 0.85))
    for k, (y, z, w) in enumerate(((-3.85, 5.0, 3.4), (-3.95, 6.6, 3.2), (-3.6, 8.0, 2.6))):
        m.box(f"ChestPlate{k}", size=(w, 0.45, 1.5), at=(0, y, z), role="belly", chamfer=0.18, taper=(0.85, 1), rot=(-12, 0, 0))
    for k, y in enumerate((-1.2, 1.0, 3.2, 5.0)):
        m.box(f"BellyPlate{k}", size=(4.6 - 0.3 * k, 1.9, 0.4), at=(0, y, 2.82), role="belly", chamfer=0.14)
    m.box("Shoulder_L", size=(2.6, 3.0, 2.8), at=(-3.3, -1.4, 6.0), role="scale_light", chamfer=0.7, **MRH)
    m.box("Haunch_L", size=(2.8, 3.6, 3.4), at=(-3.3, 4.4, 5.6), role="scale", chamfer=0.8, **MRH)
    # ---- pattes : avant (bras), arriere (cuisse, jambe digitigrade), pieds a griffes
    m.beam("ArmF_L", start=(-3.6, -1.5, 5.4), end=(-4.3, -2.0, 2.4), role="scale", width=1.9, depth=2.1, chamfer=0.45, taper=0.8, **MRH)
    m.box("ElbowF_L", size=(1.5, 1.5, 1.2), at=(-4.35, -1.7, 3.0), role="scale_dark", chamfer=0.3, **MRH)
    m.beam("ForeF_L", start=(-4.3, -2.0, 2.8), end=(-4.4, -2.6, 0.8), role="scale", width=1.6, depth=1.7, chamfer=0.35, taper=0.9, **MRH)
    m.beam("Shin_L", start=(-4.0, 4.6, 4.4), end=(-4.3, 3.0, 2.0), role="scale", width=2.0, depth=2.2, chamfer=0.45, taper=0.75, **MRH)
    m.beam("Ankle_L", start=(-4.3, 3.0, 2.2), end=(-4.4, 4.2, 0.8), role="scale_dark", width=1.4, depth=1.5, chamfer=0.3, **MRH)
    for k, (fx, fy) in enumerate(((-4.4, -2.9), (-4.4, 3.4))):
        m.box(f"Foot{k}_L", size=(2.0, 2.4, 0.95), at=(fx, fy, 0.48), role="scale_dark", chamfer=0.3, taper=(0.9, 0.8), **MRH)
        for j, dx in enumerate((-0.65, 0.0, 0.65)):
            m.prism(f"Claw{k}{j}_L", radius=0.25, height=0.75, at=(fx + dx, fy - 1.35, 0.3), role="horn", sides=4, taper=0, rot=(100, 0, 0), **MRH)
    # ---- trois cous : central plus haut, deux ecartes ; plaques de ventre a l'avant, pointes sur la crete
    NC = [(0, -2.2, 7.6), (0, -2.9, 10.0), (0, -3.0, 12.4), (0, -3.5, 14.3)]
    curve_mb(m, "NeckC", NC, [2.6, 2.3, 2.1, 1.9], [2.6, 2.3, 2.1, 1.9], ["scale"], ext=0.3, chamf=0.25)
    NS = [(-2.0, -2.0, 7.4), (-3.6, -2.6, 9.0), (-5.0, -2.8, 10.6), (-5.8, -3.3, 11.9)]
    curve_mb(m, "NeckS", NS, [2.3, 2.1, 1.9, 1.75], [2.3, 2.1, 1.9, 1.75], ["scale"], ext=0.3, chamf=0.25, **MRH)
    for k in range(2):
        a, b = NC[k + 1], NC[k + 2]
        m.beam(f"NeckCPlate{k}", start=add_mb(a, (0, -1.05, -0.3)), end=add_mb(b, (0, -0.95, -0.2)), role="belly", width=1.4, depth=0.35)
        m.prism(f"NeckCSpike{k}", radius=0.4, height=1.2, at=add_mb(mid_mb(a, b), (0, 1.05, 0.2)), role="scale_dark", sides=4, taper=0, rot=(-60, 0, 0))
    for k in range(2):
        a, b = NS[k + 1], NS[k + 2]
        m.prism(f"NeckSSpike{k}_L", radius=0.35, height=1.0, at=add_mb(mid_mb(a, b), (0.3, 0.9, 0.5)), role="scale_dark", sides=4, taper=0,
                rot=(-55, -20, 0), **MRH)
    # ---- trois tetes qui rugissent
    head_mh(m, "HC", (0, -4.1, 15.2), 0, 1.45)
    head_mh(m, "HS", (-6.2, -4.0, 12.5), -16, 1.1, **MRH)
    # ---- pointes du dos et eclair sur l'echine
    for k, (y, z, h) in enumerate(((0.0, 8.3, 1.6), (2.2, 8.4, 1.9), (4.4, 8.1, 1.6))):
        m.prism(f"BackSpike{k}", radius=0.6, height=h, at=(0, y, z + h / 2 - 0.25), role="scale_dark", sides=4, taper=0, rot=(-20, 0, 0))
    bolt_mh(m, "BackBolt", [(0, 0.9, 8.4), (0, 1.5, 9.6), (0, 2.1, 9.1), (0, 2.8, 10.4)], 0.32)
    # ---- ailes d'orage : bras d'aile, doigt, gros nuages arrondis, eclairs qui tombent
    WR, WE, WT = (-2.8, 2.4, 7.8), (-6.2, 3.0, 11.2), (-11.0, 3.4, 13.0)
    m.box("WingRoot_L", size=(1.8, 2.0, 1.8), at=WR, role="scale_dark", chamfer=0.45, **MRH)
    m.beam("WingArm_L", start=WR, end=WE, role="scale", width=1.2, depth=1.3, chamfer=0.3, taper=0.85, **MRH)
    m.beam("WingFore_L", start=WE, end=WT, role="scale", width=1.0, depth=1.1, chamfer=0.25, taper=0.6, **MRH)
    m.prism("WingClaw_L", radius=0.3, height=1.0, at=add_mb(WT, (-0.3, 0, 0.3)), role="horn", sides=4, taper=0, rot=(0, -60, 0), **MRH)
    # nuages : prismes a 8 pans couches (ronds vus de face et de dos), gros en haut, sombres en bas
    CL = [((-4.4, 3.3, 10.8), 1.7, "cloud_light"), ((-6.6, 3.4, 12.3), 1.95, "cloud_light"), ((-9.2, 3.5, 12.9), 1.75, "cloud_light"),
          ((-11.3, 3.6, 12.1), 1.35, "cloud"), ((-5.6, 3.6, 9.2), 1.6, "cloud"), ((-8.0, 3.7, 10.4), 1.85, "cloud"),
          ((-10.5, 3.8, 10.2), 1.45, "cloud_dark"), ((-7.0, 3.9, 8.2), 1.35, "cloud_dark"), ((-9.0, 3.9, 8.6), 1.2, "cloud_dark"),
          ((-7.8, 3.0, 14.1), 1.25, "cloud_light")]
    for k, (p, r, role) in enumerate(CL):
        m.prism(f"Cloud{k}_L", radius=r, height=2.4 + 0.3 * r, at=p, role=role, sides=8, turn=22.5, rot=(90, 0, 0), **MRH)
    bolt_mh(m, "WBoltA", [(-6.4, 3.4, 7.6), (-5.8, 3.4, 6.4), (-6.7, 3.4, 5.9), (-6.1, 3.4, 4.4)], 0.34, **MRH)
    bolt_mh(m, "WBoltB", [(-9.9, 3.6, 8.4), (-9.3, 3.6, 7.2), (-10.2, 3.6, 6.7), (-9.7, 3.6, 5.4)], 0.3, **MRH)
    # ---- queue epaisse a pointes, bout en eclair
    TP = [(0, 5.6, 4.8), (0, 7.8, 3.4), (0.9, 9.8, 2.4), (2.2, 11.3, 1.8), (3.2, 12.4, 1.7)]
    curve_mb(m, "Tail", TP, [3.2, 2.5, 1.9, 1.4, 0.9], [3.0, 2.3, 1.8, 1.3, 0.85], ["scale", "scale", "scale_light", "scale"], ext=0.3, chamf=0.25,
             solo=True)
    for k in range(3):
        a, b = TP[k], TP[k + 1]
        hw = (3.0, 2.3, 1.8)[k] * 0.5
        m.prism(f"TailSpike{k}", radius=0.45 - 0.08 * k, height=1.2 - 0.2 * k, at=add_mb(mid_mb(a, b), (0, 0, hw + 0.25)), role="scale_dark", sides=4,
                taper=0, rot=(-30, 0, 0), solo=True)
    bolt_mh(m, "TailBolt", [(3.0, 12.2, 1.8), (3.6, 13.2, 2.9), (4.2, 13.3, 2.3), (4.9, 14.3, 3.4)], 0.42, solo=True)
    return m


SH = ropilot.model("M_StormHydra", px=8, reset=True)
SH.reference(refs_mb("GenM_StormHydra"))
SH.palette(**PAL_MH)
build_mh(SH)
print(SH.build())
print(SH.compare(image=False)["report"])
