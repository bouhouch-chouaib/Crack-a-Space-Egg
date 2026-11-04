#!/usr/bin/env bash
# Copie les scripts de Studio (dossier local de Ropilot) vers src/, pour l'historique Git.
# Studio est la source de vérité : src/ n'est qu'une copie, ne pas la modifier à la main.
# Avant de lancer : demander chaque script à Ropilot (ropilot_sourcecontrol_requestscript)
# pour que sa copie locale soit à jour.
set -euo pipefail

PLACE_ID="${PLACE_ID:-87721638618474}"
MIRROR="${LOCALAPPDATA:-$HOME/AppData/Local}/Temp/ropilot-src/$PLACE_ID/src"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -d "$MIRROR" ]; then
	echo "Dossier Ropilot introuvable : $MIRROR" >&2
	exit 1
fi

# Dossier Studio -> dossier du dépôt (mêmes correspondances que default.project.json)
copy() {
	local from="$MIRROR/$1" to="$ROOT/src/$2"
	[ -d "$from" ] || return 0
	mkdir -p "$to"
	find "$from" -type f -name '*.lua' | while read -r f; do
		local rel="${f#"$from"/}"
		mkdir -p "$to/$(dirname "$rel")"
		# Fins de ligne Unix, comme dans le dépôt
		tr -d '\r' <"$f" >"$to/$rel"
	done
}

copy "ReplicatedStorage/Shared" "shared"
copy "ServerScriptService/Server" "server"
copy "StarterPlayer/StarterPlayerScripts/Client" "client"

# Scripts hors de ces trois dossiers : à ranger à la main (ou à ajouter ci-dessus)
find "$MIRROR" -type f -name '*.lua' | while read -r f; do
	rel="${f#"$MIRROR"/}"
	case "$rel" in
		ReplicatedStorage/Shared/* | ServerScriptService/Server/* | StarterPlayer/StarterPlayerScripts/Client/*) ;;
		*) echo "Non exporté : $rel" ;;
	esac
done

echo "Export terminé vers src/"
