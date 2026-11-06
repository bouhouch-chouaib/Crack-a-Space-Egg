# Étincelle en traînée (blanche, teintée dans Roblox) : tête brillante en haut, queue qui s'efface.
# Utilisée avec ParticleEmitter.Orientation = VelocityParallel : la traînée suit la vitesse.
# Usage : python tools/fx/make_spark.py <dossier de sortie>
import math
import sys
from PIL import Image

out = sys.argv[1]
S = 128
img = Image.new("RGBA", (S, S), (255, 255, 255, 0))
px = img.load()
for y in range(S):
    for x in range(S):
        t = y / (S - 1)  # 0 = tête (haut), 1 = bout de queue
        dx = abs(x - (S - 1) / 2) / (S / 2)
        width = 0.10 * (1 - t) + 0.025
        core = max(0.0, 1 - dx / width)
        halo = max(0.0, 1 - dx / (width * 3.2)) * 0.45
        along = (1 - t) ** 1.4 * min(1.0, (1 - abs(t - 0.06) * 0) if t > 0.03 else t / 0.03)
        a = min(1.0, (core + halo) * along)
        px[x, y] = (255, 255, 255, int(255 * a))
img.save(out + "/FxSpark.png")
print("ok")
