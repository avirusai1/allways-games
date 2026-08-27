"""Generates the Allways Games app icon at every Android density.

    python3 tool/gen_app_icon.py

Original artwork for this app: four marks on a 2x2, in the same geometric
vocabulary the game tiles already use, on the app's teal ground. Circles
and diamonds alternate on the diagonal so the mark is symmetric and still
legible at 48px, where lettering or a fine grid would close up.

Deliberately unlike a black-and-white crossword square, which is the visual
signature of other puzzle apps.
"""

import os
from PIL import Image, ImageDraw

TEAL = (31, 91, 76, 255)        # AppColors.primary
AMBER = (224, 134, 47, 255)     # AppColors.secondary
CREAM = (251, 247, 240, 255)    # AppColors.background

# Rendered large and downsampled, which is what keeps the diagonals smooth.
SUPERSAMPLE = 8

DENSITIES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

RES_DIR = "android/app/src/main/res"


def diamond(draw, cx, cy, radius, colour):
    draw.polygon(
        [(cx, cy - radius), (cx + radius, cy), (cx, cy + radius), (cx - radius, cy)],
        fill=colour,
    )


def build(size):
    canvas = size * SUPERSAMPLE

    icon = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)
    draw.rounded_rectangle(
        [(0, 0), (canvas - 1, canvas - 1)],
        radius=int(canvas * 0.22),
        fill=TEAL,
    )

    # Four marks on a 2x2, in the same geometric vocabulary the games
    # already use for their tiles. Circles and diamonds alternate on the
    # diagonal, so the mark is symmetric and still reads at 48px, where a
    # grid or any lettering would close up.
    offset = int(canvas * 0.21)
    radius = int(canvas * 0.135)
    mid = canvas // 2

    positions = [
        (mid - offset, mid - offset, CREAM, "circle"),
        (mid + offset, mid - offset, AMBER, "diamond"),
        (mid - offset, mid + offset, AMBER, "diamond"),
        (mid + offset, mid + offset, CREAM, "circle"),
    ]

    for cx, cy, colour, shape in positions:
        if shape == "circle":
            draw.ellipse(
                [(cx - radius, cy - radius), (cx + radius, cy + radius)],
                fill=colour,
            )
        else:
            diamond(draw, cx, cy, int(radius * 1.12), colour)

    return icon.resize((size, size), Image.LANCZOS)


def main():
    for density, size in DENSITIES.items():
        out_dir = os.path.join(RES_DIR, f"mipmap-{density}")
        os.makedirs(out_dir, exist_ok=True)
        path = os.path.join(out_dir, "ic_launcher.png")
        build(size).save(path)
        print(f"{path}  {size}x{size}")

    # Play Store listing icon.
    os.makedirs("store", exist_ok=True)
    build(512).save("store/play_store_icon.png")
    print("store/play_store_icon.png  512x512")


if __name__ == "__main__":
    main()
