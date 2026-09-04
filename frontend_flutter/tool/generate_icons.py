"""Generate the favicon and PWA icons for Radha Krishna Thakurbari.

The mark is a temple shikhara (spire) with a kalash finial, drawn in the
"Rose & Peacock" palette from lib/app/theme/app_colors.dart:

    rose    #B5426B   background (Radha)
    ivory   #FFF7F4   the temple silhouette
    gold    #C9971F   the kalash finial
    peacock #1F6F78   the plinth band (Krishna)

A filled rose tile with an ivory glyph stays legible at 16px in a browser tab,
which a thin outline on a light background would not.

Run from frontend_flutter/:   python tool/generate_icons.py

Requires Pillow. Everything is drawn at 4x and downsampled with LANCZOS so the
curves stay clean at small sizes.
"""

from __future__ import annotations

import os

from PIL import Image, ImageDraw

ROSE = (181, 66, 107, 255)
IVORY = (255, 247, 244, 255)
GOLD = (201, 151, 31, 255)
PEACOCK = (31, 111, 120, 255)
TRANSPARENT = (0, 0, 0, 0)

SS = 4  # supersampling factor
BASE = 512


def draw_mark(size: int, *, bleed: bool, corner_ratio: float = 0.18) -> Image.Image:
    """Draw the icon at `size` px.

    bleed=True fills the whole square (maskable icons, which browsers crop to a
    circle); bleed=False uses a rounded tile with a little breathing room.
    """
    s = size * SS
    img = Image.new("RGBA", (s, s), TRANSPARENT)
    d = ImageDraw.Draw(img)

    def px(v: float) -> float:
        """Scale a coordinate expressed against the 512 design grid."""
        return v / BASE * s

    # --- background ---------------------------------------------------------
    if bleed:
        d.rectangle([0, 0, s, s], fill=ROSE)
        # Maskable icons must keep content inside the middle 80%, so the glyph
        # is drawn smaller and centred.
        scale, offset_y = 0.78, px(6)
    else:
        r = px(BASE * corner_ratio)
        d.rounded_rectangle([0, 0, s - 1, s - 1], radius=r, fill=ROSE)
        scale, offset_y = 1.0, 0.0

    cx = s / 2

    def X(v: float) -> float:
        return cx + (px(v) - cx) * scale

    def Y(v: float) -> float:
        return px(v) * scale + (s * (1 - scale) / 2) + offset_y

    # --- plinth (peacock band + ivory steps) --------------------------------
    d.rounded_rectangle(
        [X(96), Y(410), X(416), Y(446)], radius=px(10) * scale, fill=PEACOCK
    )
    d.rounded_rectangle(
        [X(120), Y(378), X(392), Y(412)], radius=px(8) * scale, fill=IVORY
    )

    # --- temple body (tapering walls) ---------------------------------------
    d.polygon(
        [
            (X(146), Y(378)),
            (X(366), Y(378)),
            (X(330), Y(250)),
            (X(182), Y(250)),
        ],
        fill=IVORY,
    )

    # --- shikhara (curved spire), approximated as a smooth taper ------------
    left, right = [], []
    steps = 40
    for i in range(steps + 1):
        t = i / steps
        y = 250 - t * 108                      # 250 -> 142
        half = 62 * (1 - t) ** 1.55 + 12       # meets the wall top (74) exactly
        left.append((X(256 - half), Y(y)))
        right.append((X(256 + half), Y(y)))
    d.polygon(left + list(reversed(right)), fill=IVORY)

    # --- kalash finial ------------------------------------------------------
    d.ellipse([X(238), Y(112), X(274), Y(148)], fill=GOLD)
    d.polygon([(X(256), Y(74)), (X(268), Y(116)), (X(244), Y(116))], fill=GOLD)

    # --- doorway ------------------------------------------------------------
    d.rounded_rectangle(
        [X(228), Y(300), X(284), Y(378)], radius=px(28) * scale, fill=ROSE
    )
    d.rectangle([X(228), Y(350), X(284), Y(378)], fill=ROSE)

    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    web = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "web")
    icons = os.path.join(web, "icons")
    os.makedirs(icons, exist_ok=True)

    targets = [
        (os.path.join(web, "favicon.png"), 128, False),
        (os.path.join(icons, "Icon-192.png"), 192, False),
        (os.path.join(icons, "Icon-512.png"), 512, False),
        (os.path.join(icons, "Icon-maskable-192.png"), 192, True),
        (os.path.join(icons, "Icon-maskable-512.png"), 512, True),
    ]

    for path, size, bleed in targets:
        draw_mark(size, bleed=bleed).save(path, "PNG", optimize=True)
        print(f"wrote {os.path.relpath(path, web)}  {size}x{size}"
              f"{' (maskable)' if bleed else ''}")

    # A small preview sheet, handy when reviewing the mark at real tab sizes.
    preview = Image.new("RGBA", (16 + 32 + 64 + 128 + 5 * 16, 160), (240, 240, 240, 255))
    x = 16
    for size in (16, 32, 64, 128):
        preview.paste(draw_mark(size, bleed=False), (x, 16), draw_mark(size, bleed=False))
        x += size + 16
    # Written next to this script, never into web/, so it is not bundled.
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icon_preview.png")
    preview.save(out, "PNG")
    print("wrote tool/icon_preview.png (review sheet, not shipped)")


if __name__ == "__main__":
    main()
