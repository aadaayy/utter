"""Draws Utter's app icon (a white mic with sound waves on Utter blue).

Run: python3 Tools/make_icon.py  (needs Pillow). Writes the 1024 px icon
into Utter/Assets.xcassets/AppIcon.appiconset.
"""
from PIL import Image, ImageDraw

S = 2048  # drawn at twice the size, then shrunk, for smooth edges
top, bottom = (64, 120, 255), (24, 72, 230)
img = Image.new("RGB", (S, S))
px = img.load()
for y in range(S):
    t = y / (S - 1)
    row = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
    for x in range(S):
        px[x, y] = row
d = ImageDraw.Draw(img)
white = (255, 255, 255)
cx, cy = S // 2, int(S * 0.45)
# Mic head
w, h = int(S * 0.20), int(S * 0.36)
d.rounded_rectangle([cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2], radius=w // 2, fill=white)
# Cradle
r = int(S * 0.17)
lw = int(S * 0.035)
d.arc([cx - r, cy - r + int(S * 0.02), cx + r, cy + r + int(S * 0.06)], start=0, end=180, fill=white, width=lw)
# Stand
d.rectangle([cx - lw // 2, cy + r + int(S * 0.05), cx + lw // 2, cy + r + int(S * 0.13)], fill=white)
d.rounded_rectangle([cx - int(S * 0.09), cy + r + int(S * 0.12), cx + int(S * 0.09), cy + r + int(S * 0.12) + lw],
                    radius=lw // 2, fill=white)
# Sound waves either side
for i, (rad, alpha) in enumerate([(0.29, 235), (0.38, 150)]):
    rr = int(S * rad)
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    box = [cx - rr, cy - rr, cx + rr, cy + rr]
    ld.arc(box, start=-35, end=35, fill=(255, 255, 255, alpha), width=lw)
    ld.arc(box, start=145, end=215, fill=(255, 255, 255, alpha), width=lw)
    img.paste(layer, (0, 0), layer)
img = img.resize((1024, 1024), Image.LANCZOS)
img.save("Utter/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
print("wrote AppIcon.png")
