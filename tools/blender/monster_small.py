# Les deux petits monstres des premiers anneaux (28 nov.) : moins impressionnants que ceux des anneaux 3 à 14.
#   DustSkitter (anneau 1) : scarabée de roche à six pattes, il trottine.
#   FrostSlink  (anneau 2) : petit serpent de glace, il ondule à plat.
# Faits avec le kit ropilot.model (px = 8, sans picots, comme les autres monstres), pièces nommées pour
# le découpage (monster_rig.py, à exécuter avant ce fichier : il fournit @rig et les outils).
import math
import ropilot


def sm_plain(color, **kw):
    d = dict(color=color, noise=0.03, shade=0.15, top=0.14)
    d.update(kw)
    return d


def build_dustskitter():
    m = ropilot.model("DustSkitter", px=8, reset=True, symmetric=False, studs=False)
    m.palette(rock=sm_plain("#9A7A56", mottle=("#7E6244", 0.25, 4)), rockd=sm_plain("#6E5440"), rockl=sm_plain("#C4A47A"),
              dark=sm_plain("#3A2E2A"), ink="#1A1420", white="#F2EEE4", glow=dict(color="#FFC64A", glow=True))
    # carapace bombée en trois plaques, tête basse, gros yeux fâchés
    m.box("Shell", size=(4.4, 5.2, 2.2), at=(0, 0.6, 2.7), role="rock", chamfer=0.8)
    m.box("Belly", size=(3.4, 4.4, 0.8), at=(0, 0.6, 1.5), role="rockd", chamfer=0.25)
    for i, (y, w) in enumerate(((-0.9, 3.6), (0.7, 4.0), (2.3, 3.2))):
        m.box("Plate%d" % i, size=(w, 1.3, 0.6), at=(0, y, 3.95 - abs(i - 1) * 0.25), role="rockl", chamfer=0.2)
    m.pyramid("Rump", size=(1.6, 1.4, 1.2), at=(0, 3.4, 2.5), role="rockd", rot=(-70, 0, 0))
    for i, (x, y) in enumerate(((-1.1, 0.0), (1.0, 1.4), (0.2, -1.0))):
        m.crystal("Gem%d" % i, radius=0.34, height=1.0, at=(x, y, 4.3), role="glow", sides=5, tip=0.4, solo=True)
    m.box("Head", size=(3.0, 2.2, 1.9), at=(0, -2.9, 2.3), role="rockl", chamfer=0.5)
    for sx, s in ((-1, "L"), (1, "R")):
        m.box("Eye_" + s, size=(0.9, 0.3, 0.9), at=(sx * 0.8, -4.0, 2.6), role="glow", solo=True)
        m.box("Pupil_" + s, size=(0.4, 0.2, 0.55), at=(sx * 0.7, -4.12, 2.5), role="ink")
        m.box("Brow_" + s, size=(1.2, 0.5, 0.35), at=(sx * 0.85, -4.0, 3.2), role="dark", rot=(0, sx * 22, 0))
        # pinces de la bouche et antennes
        m.beam("Mand_" + s, (sx * 1.0, -3.8, 1.7), (sx * 0.45, -5.3, 1.5), role="dark", width=0.55, taper=0.35)
        m.beam("Ant_" + s, (sx * 0.8, -3.3, 3.2), (sx * 1.7, -4.6, 4.6), role="rockd", width=0.24, taper=0.6)
        m.crystal("AntTip_" + s, radius=0.26, height=0.6, at=(sx * 1.7, -4.6, 4.5), role="glow", sides=5, tip=0.4, base_tip=0.4, solo=True)
        # trois pattes en deux pièces : la cuisse monte vers le genou, la jambe redescend jusqu'au sol
        for i, y in enumerate((-1.4, 0.6, 2.6)):
            hip = (sx * 2.0, y, 2.2)
            knee = (sx * 3.7, y + (i - 1) * 0.5, 3.5)
            foot = (sx * 4.9, y + (i - 1) * 1.0, 0.0)
            m.beam("Thigh%d_%s" % (i, s), hip, knee, role="rockd", width=0.75, taper=0.8)
            m.box("Knee%d_%s" % (i, s), size=(0.9, 0.9, 0.9), at=knee, role="rockl", chamfer=0.25)
            m.beam("Shin%d_%s" % (i, s), knee, foot, role="rock", width=0.65, taper=0.3)
    m.build()
    return m


def build_frostslink():
    m = ropilot.model("FrostSlink", px=8, reset=True, symmetric=False, studs=False)
    m.palette(ice=dict(color="#8FCDEE", noise=0.02, shade=0.1, top=0.22), iced=dict(color="#4E8FC4", noise=0.02, shade=0.12, top=0.12),
              belly=sm_plain("#DDF2FA"), dark=sm_plain("#2E4A70"), ink="#141C30", white="#F4FAFF",
              glow=dict(color="#6FE8FF", glow=True), glowT=dict(color="#FF7AA8", glow=True))
    # tête en pointe, mâchoire à part, langue fourchue
    m.box("Head", size=(3.2, 3.6, 1.7), at=(0, -1.6, 2.35), role="ice", chamfer=0.5, taper=(0.62, 1), axis="y", rot=(0, 0, 180))
    m.box("Jaw", size=(2.7, 3.2, 0.8), at=(0, -1.5, 1.1), role="belly", chamfer=0.25, taper=(0.62, 1), axis="y", rot=(0, 0, 180))
    m.beam("Tongue", (0, -2.9, 1.5), (0, -4.6, 1.4), role="glowT", width=0.3, solo=True)
    for sx, s in ((-1, "L"), (1, "R")):
        m.box("Eye_" + s, size=(0.3, 0.9, 0.7), at=(sx * 1.2, -1.9, 2.6), role="glow", solo=True)
        m.box("Brow_" + s, size=(0.5, 1.3, 0.3), at=(sx * 1.2, -1.9, 3.1), role="dark", rot=(sx * -14, 0, 0))
        m.pyramid("Fang_" + s, size=(0.3, 0.3, 0.7), at=(sx * 0.8, -3.0, 1.55), role="white", rot=(180, 0, 0), pivot="bottom")
        m.beam("Fork_" + s, (0, -4.5, 1.4), (sx * 0.45, -5.2, 1.4), role="glowT", width=0.22, solo=True)
        m.crystal("Horn_" + s, radius=0.35, height=1.4, at=(sx * 1.0, -0.4, 3.1), role="iced", sides=5, tip=0.4, rot=(-25, sx * 20, 0))
    # dix tronçons qui s'affinent, un cristal sur le dos un tronçon sur deux, glaçon au bout de la queue
    y = 0.6
    for i in range(10):
        k = i / 9
        w = 2.9 - 1.5 * k
        h = 2.2 - 1.0 * k
        m.box("Seg%d" % i, size=(w, 2.3, h), at=(0, y + 1.0, 1.1 + h / 2 - 0.1), role="ice" if i % 2 == 0 else "iced", chamfer=0.4)
        m.box("Under%d" % i, size=(w * 0.7, 2.0, 0.4), at=(0, y + 1.0, 1.05), role="belly", chamfer=0.1)
        if i % 2 == 1:
            m.crystal("Ridge%d" % i, radius=0.3 + 0.15 * (1 - k), height=1.2 - 0.4 * k, at=(0, y + 1.0, 1.0 + h), role="glow", sides=5, tip=0.4, solo=True)
        y += 2.0
    m.crystal("TailTip", radius=0.5, height=2.4, at=(0, y - 0.3, 1.6), role="glow", sides=5, tip=0.3, base_tip=0.6, rot=(-90, 0, 0), solo=True)
    m.build()
    return m


@rig("DustSkitter")
def DustSkitter(R):
    # scarabée de roche : six pattes (cuisse puis jambe) qui trottinent trois par trois, pinces, antennes
    for s in ("L", "R"):
        for i in range(3):
            a = R.group("Leg%s%dA" % (s, i + 1), R.take(r"(Thigh|Knee)%d_%s" % (i, s)), "Torso", "near")
            R.group("Leg%s%dB" % (s, i + 1), R.take(r"Shin%d_%s" % (i, s)), a, "top")
        R.group("Mand" + s, R.take(r"Mand_%s" % s), "Torso", "back")
        R.group("Ant" + s, R.take(r"Ant_%s|AntTip_%s" % (s, s)), "Torso", "back+bottom")


@rig("FrostSlink")
def FrostSlink(R):
    # petit serpent de glace : déjà modelé à plat, dix tronçons et le glaçon de la queue, mâchoire, langue
    R.span = 2.2
    segs = [R.take(r"(Seg|Under|Ridge)%d" % i) for i in range(10)] + [R.take(r"TailTip")]
    R.chain("Seg", segs)
    R.group("Jaw", R.take(r"Jaw"), "Torso", "back")
    R.group("Tongue", R.take(r"Tongue|Fork_[LR]"), "Jaw", "back")
