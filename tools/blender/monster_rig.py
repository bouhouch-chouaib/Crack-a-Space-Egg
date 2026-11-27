# Articulation des monstres : chaque monstre (collection de pièces nommées, faite par les scripts monster_*.py)
# est découpé en groupes qui bougent ensemble (patte, mâchoire, aile, tronçon de queue...), chacun avec sa
# charnière. Les corps de serpent enroulés sont déroulés à plat (chaîne de tronçons posés l'un derrière
# l'autre), pour que le jeu puisse les faire onduler à l'horizontale.
# Sortie : une collection « R_<Nom> » (une pièce par groupe : « <Nom>__<Groupe> », lueurs « <Groupe>_G »)
# à importer dans Studio, et tools/blender/monster_rigs.json (parent, charnière, axe, chaîne de chaque
# groupe), lu par tools/build-monsters.lua.
# Usage dans le Blender de Ropilot (les collections sources chargées par monster_helpers.mk_load) :
#     exec(open(r"<repo>/tools/blender/monster_rig.py", encoding="utf-8").read())
#     print(rig_all())            ou rig_one("GearSpider")
# Repères : dans Blender l'avant est -Y, le haut +Z ; « L » = x < 0, « R » = x > 0.
import bpy, re, math, json, os
from mathutils import Vector, Matrix

RIG_REPO = r"C:\Users\bouho\OneDrive - Conseil régional Grand Est - Numérique Educatif\Documents\Crack the Asteroid"
RIG_JSON = os.path.join(RIG_REPO, "tools", "blender", "monster_rigs.json")


def _verts(objs):
    out = []
    for o in objs:
        mw = o.matrix_world
        out.extend(mw @ v.co for v in o.data.vertices)
    return out


def _box(objs):
    vs = _verts(objs)
    lo = Vector([min(v[i] for v in vs) for i in range(3)])
    hi = Vector([max(v[i] for v in vs) for i in range(3)])
    return lo, hi


def _cen(objs):
    vs = _verts(objs)
    return sum(vs, Vector()) / len(vs)


# range chaque pièce dans le tronçon dont la pièce principale (la première) est la plus proche
def _into(segs, objs):
    cents = [_cen(sg[:1]) for sg in segs]
    for o in objs:
        c = _cen([o])
        i = min(range(len(segs)), key=lambda k: (c - cents[k]).length)
        segs[i].append(o)


# grand axe d'une pièce allongée (poutre) et sa longueur le long de cet axe
def _axis(objs):
    import numpy as np
    vs = np.array([tuple(v) for v in _verts(objs)])
    c = vs.mean(axis=0)
    w, v = np.linalg.eigh(np.cov((vs - c).T))
    f = Vector(v[:, 2])
    t = (vs - c) @ v[:, 2]
    return f.normalized(), float(t.max() - t.min())


# met des poutres bout à bout dans l'ordre, en partant de celle dont un bout est le plus près de `start`
def _order(objs, start):
    ends = {}
    for o in objs:
        f, L = _axis([o])
        c = _cen([o])
        ends[o] = (c - f * L / 2, c + f * L / 2)
    left = set(objs)
    at = Vector(start)
    out = []
    while left:
        o = min(left, key=lambda k: min((ends[k][0] - at).length, (ends[k][1] - at).length))
        a, b = ends[o]
        at = b if (a - at).length < (b - at).length else a
        left.discard(o)
        out.append(o)
    return out


class Rig:
    def __init__(self, name, col):
        self.name = name
        src = bpy.data.collections[col]
        out = "R_" + name
        old = bpy.data.collections.get(out)
        if old:
            for o in list(old.all_objects):
                bpy.data.objects.remove(o, do_unlink=True)
            bpy.data.collections.remove(old)
        self.col = bpy.data.collections.new(out)
        bpy.context.scene.collection.children.link(self.col)
        self.part = {}
        for o in src.all_objects:
            if o.type != "MESH":
                continue
            c = o.copy()
            c.data = o.data.copy()
            self.col.objects.link(c)
            s = re.sub(r"\.\d+$", "", o.get("ropilot_part") or o.name)
            self.part[c] = re.sub(r"_(Monster_|M_)?" + name + r"$", "", s)
        bpy.context.view_layer.update()
        self.free = set(self.part)
        # longueur du modèle en jeu = Size du monstre x span (un serpent allongé est bien plus long que large)
        self.span = 1.0
        self.groups = {}  # nom -> dict(objs, parent, hinge, axis, chain, index)

    # pièces libres dont le nom correspond (expression entière) ; side = "L" (x < 0) ou "R"
    def take(self, pattern, side=None):
        rx = re.compile(pattern)
        got = [o for o in self.free if rx.fullmatch(self.part[o])]
        if side:
            got = [o for o in got if (_cen([o]).x < 0) == (side == "L")]
        self.free -= set(got)
        return sorted(got, key=lambda o: self.part[o])

    def group(self, name, objs, parent="Torso", hinge="near", axis=None, chain=None, index=0):
        if not objs:
            raise ValueError("%s : groupe vide %s" % (self.name, name))
        g = self.groups.setdefault(name, dict(objs=[], parent=parent, hinge=hinge, axis=axis, chain=chain, index=index))
        g["objs"].extend(objs)
        return name

    # même groupe des deux côtés : « <nom>L » et « <nom>R »
    def sides(self, name, pattern, parent="Torso", hinge="near", axis=None):
        for s in ("L", "R"):
            p = parent.replace("#", s)
            self.group(name + s, self.take(pattern, s), p, hinge, axis)

    # chaque pièce libre qui correspond rejoint le groupe le plus proche parmi `names` (tous par défaut)
    def attach(self, pattern, names=None):
        names = names or [n for n in self.groups]
        cents = {n: [_cen([o]) for o in self.groups[n]["objs"]] for n in names}
        for o in self.take(pattern):
            c = _cen([o])
            best = min(names, key=lambda n: min((c - p).length for p in cents[n]))
            self.groups[best]["objs"].append(o)

    # suite de groupes articulés l'un sur l'autre (cou, queue, tentacule) : name1 tient au parent, name2 à name1...
    def links(self, name, segs, parent="Torso", hinge="near", axis=None):
        prev = parent
        for i, objs in enumerate(segs):
            prev = self.group("%s%d" % (name, i + 1), objs, prev, hinge, axis)
        return prev

    # corps de serpent : tronçons (de la tête vers la queue) déroulés à plat l'un derrière l'autre, vers l'arrière
    # (+Y), le dos en haut. up0 = direction du dos au premier tronçon ; anchor = point où commence la chaîne
    # (par défaut le centre du premier tronçon) ; pack < 1 resserre des tronçons taillés en arc.
    # beams = True : chaque tronçon est une poutre droite, on prend son propre grand axe (et le dos reste en haut
    # dès que la poutre est à peu près couchée) au lieu de la direction entre ses voisins.
    def chain(self, name, segs, up0=(0, 0, 1), anchor=None, pack=1.0, beams=False):
        cents = [_cen(s[:1]) if beams else _cen(s) for s in segs]
        n = len(segs)
        u = Vector(up0)
        dist = 0.0
        base = Vector(anchor) if anchor else Vector((0, cents[0].y, cents[0].z))
        prevL = 0.0
        for i in range(n):
            f = (cents[min(i + 1, n - 1)] - cents[max(i - 1, 0)]).normalized()
            L = 0.0
            if beams:
                own, L = _axis(segs[i][:1])
                f = own if own.dot(f) >= 0 else -own
                if abs(f.z) < 0.6:
                    u = Vector((0, 0, 1))
            u = (u - f * u.dot(f)).normalized()
            r = f.cross(u)
            if i:
                step = (cents[i] - cents[i - 1]).length
                if beams:
                    step = min(step, (L + prevL) / 2)
                dist += step * pack
            prevL = L
            rot = Matrix((r, f, u))  # lignes : envoie r, f, u sur X, Y, Z
            M = Matrix.Translation(base + Vector((0, dist, 0))) @ rot.to_4x4() @ Matrix.Translation(-cents[i])
            for o in segs[i]:
                o.matrix_world = M @ o.matrix_world
            self.group("%s%02d" % (name, i + 1), segs[i], "Torso", "center", None, name, i + 1)
        bpy.context.view_layer.update()

    def _hinge(self, g):
        objs = g["objs"]
        rule = g["hinge"]
        lo, hi = _box(objs)
        c = (lo + hi) / 2
        if isinstance(rule, (tuple, list)):
            return Vector(rule)
        if rule == "center":
            return c
        if rule == "near":
            parent = self.groups.get(g["parent"])
            target = _cen(parent["objs"]) if parent else c
            vs = sorted(_verts(objs), key=lambda v: (v - target).length)
            k = max(6, len(vs) // 8)
            return sum(vs[:k], Vector()) / k
        p = c.copy()
        for word in rule.split("+"):
            if word == "back":
                p.y = hi.y
            elif word == "front":
                p.y = lo.y
            elif word == "top":
                p.z = hi.z
            elif word == "bottom":
                p.z = lo.z
            elif word == "inner":
                p.x = hi.x if c.x < 0 else lo.x
            elif word == "outer":
                p.x = lo.x if c.x < 0 else hi.x
            elif word == "mid":
                p.x = 0
        return p

    def finish(self):
        import bmesh
        if self.free:
            self.group("Torso", sorted(self.free, key=lambda o: self.part[o]), parent="", hinge="center")
            self.free = set()
        elif "Torso" not in self.groups:
            raise ValueError(self.name + " : pas de tronc")
        self.groups["Torso"]["parent"] = ""
        info = {}
        hinges = {n: self._hinge(g) for n, g in self.groups.items()}
        tris = 0
        for n, g in self.groups.items():
            buckets = {}
            for o in g["objs"]:
                mat = o.material_slots[0].material.name if o.material_slots and o.material_slots[0].material else ""
                buckets.setdefault(mat if "glow" in mat.lower() else "", []).append(o)
            keys = sorted(buckets)  # "" (peau) d'abord
            main = None
            gi = 0
            for key in keys:
                lst = buckets[key]
                if len(lst) > 1:
                    with bpy.context.temp_override(active_object=lst[0], selected_editable_objects=lst, object=lst[0]):
                        bpy.ops.object.join()
                o = lst[0]
                if main is None:
                    main = o
                    o.name = "%s__%s" % (self.name, n)
                else:
                    gi += 1
                    o.name = "%s__%s_G%s" % (self.name, n, "" if gi == 1 else str(gi))
                o.data.name = o.name
                bm = bmesh.new()
                bm.from_mesh(o.data)
                bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
                bm.to_mesh(o.data)
                bm.free()
                tris += sum(len(p.vertices) - 2 for p in o.data.polygons)
            bpy.context.view_layer.update()
            lo, hi = _box([main])
            c = (lo + hi) / 2
            h = hinges[n] - c
            ax = g["axis"]
            if ax == "thin":
                # roue, anneau : elle tourne autour de son axe (la direction où elle est la plus mince)
                d = hi - lo
                k = min(range(3), key=lambda i: d[i])
                ax = tuple(1.0 if i == k else 0.0 for i in range(3))
            if ax == "radial":
                # pétale autour de l'axe avant-arrière du parent : il s'ouvre en tournant autour de la tangente
                pc = _cen(self.groups[g["parent"]]["objs"]) if g["parent"] in self.groups else Vector()
                rad = Vector((hinges[n].x - pc.x, 0, hinges[n].z - pc.z))
                ax = tuple(Vector((0, 1, 0)).cross(rad.normalized())) if rad.length > 1e-4 else None
            info[n] = dict(
                parent=g["parent"],
                # passage aux axes de Roblox : (x, z, -y)
                hinge=[round(h.x, 4), round(h.z, 4), round(-h.y, 4)],
                axis=[round(ax[0], 4), round(ax[2], 4), round(-ax[1], 4)] if ax else None,
                chain=g["chain"], index=g["index"], glow=gi)
        bpy.context.view_layer.update()
        lo, hi = _box([o for o in self.col.objects])
        return dict(parts=info, span=self.span, size=[round(hi.x - lo.x, 2), round(hi.z - lo.z, 2), round(hi.y - lo.y, 2)], objects=len(self.col.objects), tris=tris)


RIGS = {}  # nom -> (collection source, fonction qui découpe)


def rig(col):
    def deco(fn):
        RIGS[fn.__name__] = (col, fn)
        return fn
    return deco


def rig_one(name):
    col, fn = RIGS[name]
    R = Rig(name, col)
    fn(R)
    out = R.finish()
    data = {}
    if os.path.exists(RIG_JSON):
        with open(RIG_JSON, encoding="utf-8") as f:
            data = json.load(f)
    data[name] = out
    with open(RIG_JSON, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=1, sort_keys=True)
    return "%s : %d groupes, %d objets, %d triangles, taille %s" % (name, len(out["parts"]), out["objects"], out["tris"], out["size"])


def rig_all(names=None):
    return "\n".join(rig_one(n) for n in (names or RIGS))


# DÉCOUPAGES ---------------------------------------------------------------------------------------------
# Chaque fonction prend d'abord les pièces qui bougent ; tout ce qui reste devient le tronc (« Torso »).

@rig("Monster_CinderMaw")
def CinderMaw(R):
    # ver de lave : grosse tête à gueule ronde (8 lèvres qui s'ouvrent en corolle), queue qui fouette
    R.span = 1.2
    segs = [R.take(r"Seg%d" % i) for i in range(7)] + [R.take(r"TailTip")]
    _into(segs, R.take(r"Core\d|Spine\d+|SpineTip\d+|Frill\d+"))
    R.chain("Seg", segs)
    for i in range(8):
        R.group("Lip%d" % i, R.take(r"Lip%d" % i), "Torso", "back", "radial")
    R.attach(r"Gum\d+|Tooth\d+|Fang\d+", ["Lip%d" % i for i in range(8)])
    R.sides("Horn", r"Horn(Tip)?_[LR]", hinge="near")


@rig("Monster_NebulaStalker")
def NebulaStalker(R):
    # raie manta : quatre panneaux d'aile de chaque côté (onde de battement), queue à dard, mâchoire
    for s in ("L", "R"):
        prev = "Torso"
        for i in range(4):
            prev = R.group("Wing%s%d" % (s, i + 1), R.take(r"(Wing|Lead|Trail)%d_%s" % (i, s)), prev, "inner")
        R.attach(r"Star\d+_%s|CrysS\d+_%s" % (s, s), ["Wing%s%d" % (s, i) for i in range(1, 5)])
    R.links("Tail", [R.take(r"Rump")] + [R.take(r"Tail%d" % i) for i in range(5)], hinge="front")
    R.attach(r"TailSpike\d+|Sting", ["Tail%d" % i for i in range(1, 7)])
    R.group("Jaw", R.take(r"Lip|FangD\d+"), "Torso", "back")
    R.sides("Horn", r"Horn_L\d+_[LR]", hinge="back")


@rig("Monster_Devourer")
def Devourer(R):
    # ver à pinces : corps déroulé (huit anneaux), deux grandes mandibules articulées, mâchoire
    R.span = 1.5
    segs = [R.take(r"Seg%d" % i) for i in range(8)] + [R.take(r"TailTip")]
    _into(segs, R.take(r"Core\d|Scute\d+|Spike\d+|SideSpike\d+[LR]"))
    R.chain("Seg", segs)
    for s in ("L", "R"):
        R.group("Mand%s1" % s, R.take(r"Mand_L[01]_%s" % s), "Torso", "back")
        R.group("Mand%s2" % s, R.take(r"Mand_L[23]_%s|MandFang\d_%s" % (s, s)), "Mand%s1" % s, "near")
    R.group("Jaw", R.take(r"Jaw|Chin|FangD\d+|FangSD\d[LR]"), "Torso", "back")


@rig("Monster_Watcher")
def Watcher(R):
    # œil flottant : six tentacules qui traînent, anneau qui tourne, paupières qui clignent
    for s in ("L", "R"):
        for t in range(3):
            segs = [R.take(r"Tent%d[01]_%s" % (t, s)), R.take(r"Tent%d[23]_%s" % (t, s)), R.take(r"Tent%d[45]_%s" % (t, s))]
            R.links("Tent%s%d_" % (s, t + 1), segs, hinge="top")
    R.attach(r"TentTip\d(_mirror)?", [n for n in R.groups if n.endswith("_3")])
    R.group("Halo", R.take(r"Halo\d+|HaloArm\d"), "Torso", "center", "thin")
    R.group("LidUp", R.take(r"Lid_[LR]"), "Torso", "top")
    R.group("LidLow", R.take(r"LidLow(_[LR])?"), "Torso", "bottom")


@rig("M_Queen")
def Queen(R):
    # reine guêpe : quatre ailes qui vrombissent, quatre pattes pendantes, abdomen qui se recourbe, bras faux
    for s in ("L", "R"):
        R.group("WingUp" + s, R.take(r"WingUp_%s\w+" % s), "Torso", "inner+front")
        R.group("WingLo" + s, R.take(r"WingLo_%s\w+" % s), "Torso", "inner+front")
        for i in range(2):
            thigh = R.group("Leg%s%dA" % (s, i + 1), R.take(r"(Coxa|Femur|KneeCap)%d_%s" % (i, s)), "Torso", "top")
            R.group("Leg%s%dB" % (s, i + 1), R.take(r"(Tibia|Tarsus|LegSpike)%d_%s" % (i, s)), thigh, "top")
        arm = R.group("Arm" + s, R.take(r"(Arm|Elbow)_%s" % s), "Torso", "near")
        R.group("Scythe" + s, R.take(r"(Fore|Scythe|ScytheBack)_%s|Claw\d_%s" % (s, s)), arm, "near")
        R.group("Mandible" + s, R.take(r"Mandible_L\d_%s|MandTooth_%s" % (s, s)), "Head", "back")
    R.links("Abdo", [R.take(r"Waist|Abdo0|AbdoBand0"), R.take(r"Abdo1|AbdoBand1"), R.take(r"Abdo[23]|AbdoBand[23]|Stinger")], hinge="front")
    R.attach(r"AbdoSpike\d_[LR]|Egg\d|EggCell\d|Band\d_[LR]", ["Abdo1", "Abdo2", "Abdo3"])
    R.group("Head", R.take(r"Skull|Snout|SnoutPlate|Neck|MouthIn|Brow_[LR]|Cheek\w*|Crown\w+|Horn_L\d_[LR]|Iris_[LR]|Pupil_[LR]|Shine_[LR]|Nostril_[LR]|Tooth\d_[LR]|Fang\d"), "Torso", "back+bottom")
    R.group("Jaw", R.take(r"Jaw"), "Head", "back")


@rig("M_AbyssAngler")
def AbyssAngler(R):
    # poisson-lanterne : queue qui bat de gauche à droite, nageoires qui rament, mâchoire, leurre au bout de sa tige
    R.links("Tail", [R.take(r"Rear"), R.take(r"Peduncle"), R.take(r"TailCore|TailUp|TailLo")], hinge="front")
    R.sides("Pec", r"PecBase_[LR]|Pec\d_[LR]", hinge="inner+front")
    R.group("Jaw", R.take(r"Jaw|JawLip|JawSpine\d_[LR]|ToothLo\d|GumLo|Chin|Tongue"), "Torso", "back")
    R.links("Stalk", [R.take(r"Stalk[01]"), R.take(r"Stalk[23]"), R.take(r"Stalk4|Lure|LureCap|LureFrond\d")], hinge="near")
    R.group("Dorsal", R.take(r"Dorsal|DorsalRay\d"), "Torso", "bottom")


@rig("M_StormHydra")
def StormHydra(R):
    # hydre d'orage : quatre pattes qui trottent, trois cous qui ondulent chacun pour soi, trois mâchoires, queue, ailes
    for s in ("L", "R"):
        a = R.group("Fore%sA" % s, R.take(r"(Shoulder|ArmF)_%s" % s), "Torso", "top")
        b = R.group("Fore%sB" % s, R.take(r"(ElbowF|ForeF)_%s" % s), a, "top")
        a2 = R.group("Hind%sA" % s, R.take(r"Haunch_%s" % s), "Torso", "top")
        b2 = R.group("Hind%sB" % s, R.take(r"(Shin|Ankle)_%s" % s), a2, "top")
        feet = sorted(R.take(r"Foot\d_%s" % s), key=lambda o: _cen([o]).y)
        R.group("Fore%sC" % s, feet[:1], b, "top")
        R.group("Hind%sC" % s, feet[1:], b2, "top")
        R.attach(r"Claw\d_%s" % s, ["Fore%sC" % s, "Hind%sC" % s])
        wing = R.group("Wing%sA" % s, R.take(r"(WingRoot|WingArm)_%s" % s), "Torso", "near")
        R.group("Wing%sB" % s, R.take(r"(WingFore|WingClaw)_%s|WBolt[AB]\d_%s" % (s, s)), wing, "near")
        neck = R.links("Neck%s" % s, [R.take(r"NeckS%d_%s" % (i, s)) for i in range(3)], hinge="near")
        R.attach(r"NeckSSpike\d_%s" % s, ["Neck%s%d" % (s, i) for i in (1, 2, 3)])
        head = R.group("Head" + s, R.take(r"HS(?!Jaw|ToothL)\w+_%s" % s), neck, "near")
        R.group("Jaw" + s, R.take(r"HS(Jaw|ToothL\d)_%s" % s), head, "back")
    neck = R.links("NeckC", [R.take(r"NeckC%d" % i) for i in range(3)], hinge="near")
    R.attach(r"NeckCPlate\d|NeckCSpike\d", ["NeckC1", "NeckC2", "NeckC3"])
    head = R.group("HeadC", R.take(r"HC(?!Jaw|ToothL)\w+"), neck, "near")
    R.group("JawC", R.take(r"HC(Jaw|ToothL\d)"), head, "back")
    R.links("Tail", [R.take(r"Tail%d" % i) for i in range(4)], hinge="front")
    R.attach(r"TailSpike\d|TailBolt\d", ["Tail%d" % i for i in range(1, 5)])


@rig("M_GearSpider")
def GearSpider(R):
    # araignée mécanique : huit pattes (cuisse puis jambe) qui marchent par quatre, rouages et aiguilles qui tournent, pinces
    for s in ("L", "R"):
        for i in range(4):
            a = R.group("Leg%s%dA" % (s, i + 1), R.take(r"(Femur|FemBand|Knee|KneeCap)%d_%s" % (i, s)), "Torso", "near")
            R.group("Leg%s%dB" % (s, i + 1), R.take(r"(Tibia|TibBand|Ankle|Tarsus|Spur)%d_%s" % (i, s)), a, "near")
        R.group("GearA" + s, R.take(r"GearA(Hub|T\d+)?_%s" % s), "Torso", "center", "thin")
        R.group("GearB" + s, R.take(r"GearB(Hub|T\d+)?_%s" % s), "Torso", "center", "thin")
        R.group("Pincer" + s, R.take(r"Pincer_L\d_%s|PincerTooth\d_%s" % (s, s)), "Torso", "back")
    cap = tuple(_cen([o for o in R.free if R.part[o] == "HandCap"]))
    R.group("HandM", R.take(r"HandM"), "Torso", cap, (0, 1, 0))
    R.group("HandH", R.take(r"HandH"), "Torso", cap, (0, 1, 0))
    R.group("SteamA", R.take(r"SteamA\d"), "Torso", "bottom")
    R.group("SteamB", R.take(r"SteamB\d"), "Torso", "bottom")


@rig("SourWorm")
def SourWorm(R):
    # cobra en bonbon : corps déroulé à plat, poutre par poutre (le cou, l'anneau du haut, celui du bas, la pointe),
    # capuchon, antennes
    R.span = 2.4
    neck = [R.take(p) for p in (r"Neck4", r"Neck3", r"Neck2", r"Neck1", r"Neck0")]
    _into(neck, R.take(r"NeckBelly\d"))
    low = _cen(neck[-1][:1]) - Vector((0, 0, 1.5))
    coil = [[o] for o in _order(R.take(r"Coil2_\d"), low)]
    f, L = _axis(coil[-1])
    end = _cen(coil[-1])
    coil += [[o] for o in _order(R.take(r"Coil\d+"), end - Vector((0, 0, 2.2)))]
    segs = neck + coil
    _into(segs, R.take(r"[CG]?Sugar\d+"))
    segs.append(R.take(r"TailTip"))
    head = R.take(r"Head")
    lo, hi = _box(head)
    R.free |= set(head)
    R.chain("Seg", segs, up0=(0, 1, 0), anchor=(0, hi.y - 1.0, (lo.z + hi.z) / 2), pack=0.72, beams=True)
    R.sides("Hood", r"Hood_[LR]|HoodSpike\d_[LR]", hinge="inner")
    R.sides("Ant", r"Ant_[LR]|AntBall_[LR]", hinge="bottom")


@rig("SporeBehemoth")
def SporeBehemoth(R):
    # gorille champignon : il marche sur les poings (bras en deux pièces), petites jambes, chapeau qui ballotte
    for s in ("L", "R"):
        a = R.group("Arm%sA" % s, R.take(r"(Shoulder|Arm|MossShoulder)_%s" % s), "Torso", "top")
        R.group("Arm%sB" % s, R.take(r"(Elbow|Fore|ForeMoss|Fist)_%s|(Knuckle|Claw)\d_%s" % (s, s)), a, "top")
        R.group("Leg" + s, R.take(r"(Leg|Foot)_%s|Toe\d_%s" % (s, s)), "Torso", "top")
    R.group("Head", R.take(r"Head|Nose|Nostril_[LR]|Brow_[LR]|Iris_[LR]|Pupil_[LR]|Shine_[LR]|TopTooth\d|Lip|MouthIn|Tusk_[LR]|TuskBand_[LR]|Gills"), "Torso", "back+bottom")
    R.group("Jaw", R.take(r"Jaw|Chin|BotTooth\d"), "Head", "back")
    R.group("Cap", R.take(r"Cap|CapRim|CapTop|Stem|Spot\d+"), "Torso", "bottom")


@rig("TempleColossus")
def TempleColossus(R):
    # colosse de pierre : marche lourde sur deux jambes, bras en deux pièces qui balancent, tête, panache de plumes
    for s in ("L", "R"):
        R.group("Leg" + s, R.take(r"(Leg|Foot|FootGold|Anklet)_%s" % s), "Torso", "top")
        a = R.group("Arm%sA" % s, R.take(r"(Arm|Pauldron|PauldronGold|PauldronSpike|MossPad)_%s" % s), "Torso", "inner+top")
        R.group("Arm%sB" % s, R.take(r"(Elbow|Fore|Bracer|Fist|FistRune|FistRuneRim|Thumb)_%s|Knuckle\d_%s" % (s, s)), a, "top")
    head = R.group("Head", R.take(r"Neck|Helm|HelmBack|Mask\w*|Brow_[LR]|Eye\w*_[LR]|Crown|CrownGem|SunRays|Ray\d"), "Torso", "bottom")
    R.group("Plume", R.take(r"Feather\w*\d"), head, "bottom")
    R.group("Skirt", R.take(r"Skirt|Flap|FlapGold"), "Torso", "top")


@rig("PhantomKing")
def PhantomKing(R):
    # roi fantôme : il glisse, la robe traîne en cinq tronçons, bras griffus qui se tendent, lanternes qui se balancent
    for s in ("L", "R"):
        a = R.group("Arm%sA" % s, R.take(r"LArm%s|LArmB%s|Sleeve%s|SleeveTat%s\d" % (s, s, s, s)), "Torso", "near")
        R.group("Arm%sB" % s, R.take(r"LArmTip%s|Fore%s|Cuff%s|Palm%s|Thumb%s|ThumbClaw%s|Claw%s\d" % ((s,) * 7)), a, "near")
        R.group("Lan" + s, R.take(r"Lan%s[A-Z]\w+" % s), "Torso", "top")
        R.group("LanB" + s, R.take(r"LanB%s[A-Z]\w+" % s), "Torso", "top")
        for i in range(4):
            R.group("Fin%s%d" % (s, i + 1), R.take(r"Fin%s%d[abc]" % (s, i)), "Torso", "inner")
    R.links("Tail", [R.take(r"Tail%d" % i) for i in range(5)], hinge="near")
    R.group("Cape", R.take(r"Cape|CapeLining|CapeTat\d"), "Torso", "top")
    R.group("Jaw", R.take(r"LowFang\d"), "Torso", "center")
