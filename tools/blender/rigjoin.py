# Regroupe les pièces d'une créature faite avec ropilot.model en membres animables, avant l'import dans Studio.
# Usage (dans le Blender de Ropilot) :
#   exec(open(r"<repo>/tools/blender/rigjoin.py", encoding="utf-8").read())
#   rig_join("R1_T1", {"Head": ["Head", "Snout", "Nose", "Fleck*"], "LegFL": ["LegF_L"], ...})
# - Chaque clé est un rôle lu par Creatures.client : Body, Head, Jaw, LegFL/FR/BL/BR, LegL/R, LegF/B,
#   ArmL/R, WingL/R, FinL/R, EarL/R, Tail, Tentacles. Les pièces non listées vont dans Body.
# - Les pièces d'un même rôle sont fusionnées en un seul objet par matériau : le matériau texturé garde le
#   nom du rôle (« Head »), chaque matériau lumineux donne « Head__Glow », « Head__Glow2 »... (Neon dans
#   Studio). tools/creature-rig.lua lit ces noms : « X__... » suit le membre X sans joint à lui.
# - Les motifs (fnmatch) sont acceptés : "Fleck*". Les objets finaux s'appellent « R1_T1:Head » (noms uniques
#   dans Blender quand plusieurs créatures y sont ouvertes) ; creature-rig.lua enlève le préfixe.
import bpy, bmesh, fnmatch, re


def _base(name):
    # « Head.001 » (doublon de nom entre deux modèles) -> « Head »
    return re.sub(r"\.\d+$", "", name)


def rig_join(col_name, groups):
    col = bpy.data.collections[col_name]
    objs = [o for o in col.all_objects if o.type == "MESH"]
    owner = {}
    for role, pats in groups.items():
        for o in objs:
            part = o.get("ropilot_part") or _base(o.name)  # nom de la pièce dans le kit
            if any(fnmatch.fnmatchcase(part, p) for p in pats) and o.name not in owner:
                owner[o.name] = role
    buckets = {}
    for o in objs:
        role = owner.get(o.name, "Body")
        mat = o.material_slots[0].material.name if o.material_slots and o.material_slots[0].material else ""
        glow = "glow" in mat.lower()
        buckets.setdefault((role, mat if glow else ""), []).append(o)
    out = []
    glow_n = {}
    for (role, mat), lst in sorted(buckets.items(), key=lambda kv: (kv[0][0], kv[0][1])):
        if mat:
            glow_n[role] = glow_n.get(role, 0) + 1
            name = role + "__Glow" + ("" if glow_n[role] == 1 else str(glow_n[role]))
        else:
            name = role
        bpy.ops.object.select_all(action="DESELECT")
        for o in lst:
            o.select_set(True)
        bpy.context.view_layer.objects.active = lst[0]
        if len(lst) > 1:
            bpy.ops.object.join()
        o = bpy.context.view_layer.objects.active
        # préfixe « R1_T1: » : noms uniques dans Blender ; creature-rig.lua l'enlève
        o.name = col_name + ":" + name
        o.data.name = col_name + ":" + name
        bm = bmesh.new()
        bm.from_mesh(o.data)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
        bm.to_mesh(o.data)
        bm.free()
        out.append(name)
    return sorted(out)


def rig_clear(col_name):
    # retire la créature de la scène (elle est sauvegardée dans son .blend) : scène légère, noms libres
    col = bpy.data.collections.get(col_name)
    if col:
        for o in list(col.all_objects):
            bpy.data.objects.remove(o, do_unlink=True)
        bpy.data.collections.remove(col)
