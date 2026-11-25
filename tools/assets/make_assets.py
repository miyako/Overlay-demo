#!/usr/bin/env python3
"""Generate the Overlay demo's PNG assets.

Run with any Python that has Pillow:

    python3 tools/assets/make_assets.py

The generated files are committed under ``Resources/Overlay/`` so the 4D
project does not need a build step. Re-run only when the POI catalogue or the
artwork changes.
"""

from __future__ import annotations

import pathlib

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "Resources" / "Overlay"

CARD_W, CARD_H, POINTER = 300, 150, 16

# id, title, subtitle, accent
POIS = [
    ("tidepools", "Tide Pools", "Sea anemones at low water", "#0E7C86"),
    ("lighthouse", "Lighthouse Bluff", "The oldest light on the coast", "#B45309"),
    ("whale_pier", "Whale Watch Pier", "Boats leave at first light", "#1D4ED8"),
    ("fern_grotto", "Fern Grotto", "Cool air under the canopy", "#15803D"),
    ("copper_mine", "Copper Mine", "Tunnels closed in 1932", "#9A3412"),
    ("sundial", "Sundial Plaza", "Market square centrepiece", "#6D28D9"),
    ("night_market", "Night Market", "Stalls open after sunset", "#BE123C"),
]

FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FONT_REGULAR = "/System/Library/Fonts/Supplemental/Arial.ttf"


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default(size=size)


def rounded_card(index: int, title: str, subtitle: str, accent: str) -> Image.Image:
    """A transparent card with a pointer notch at the bottom centre."""
    img = Image.new("RGBA", (CARD_W, CARD_H + POINTER), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Soft drop shadow: offset rounded rectangles with decreasing alpha.
    for offset, alpha in ((6, 28), (4, 40), (2, 64)):
        draw.rounded_rectangle(
            (offset, offset, CARD_W - offset, CARD_H + 2 - offset),
            radius=18,
            fill=(15, 23, 42, alpha),
        )

    draw.rounded_rectangle(
        (0, 0, CARD_W - 1, CARD_H - 1),
        radius=18,
        fill=(255, 255, 255, 255),
        outline=(15, 23, 42, 22),
        width=1,
    )
    # Accent bar and number badge.
    draw.rounded_rectangle((0, 0, 14, CARD_H - 1), radius=18, fill=accent)
    draw.rectangle((7, 0, 14, CARD_H - 1), fill=accent)
    draw.ellipse((26, 22, 82, 78), fill=accent)
    number = font(FONT_BOLD, 30)
    draw.text((54, 50), str(index), font=number, fill=(255, 255, 255), anchor="mm")

    title_font = font(FONT_BOLD, 22)
    sub_font = font(FONT_REGULAR, 15)
    draw.text((100, 34), title, font=title_font, fill=(15, 23, 42))
    draw.text((100, 64), subtitle, font=sub_font, fill=(71, 85, 105))

    draw.line((100, 92, CARD_W - 26, 92), fill=(15, 23, 42, 28), width=1)
    draw.text((100, 106), "Click the card to accept", font=font(FONT_BOLD, 13), fill=accent)
    draw.text(
        (CARD_W - 26, 116), "overlay", font=font(FONT_REGULAR, 12), fill=(148, 163, 184), anchor="ra"
    )

    # Pointer notch, aligned with the card centre.
    cx = CARD_W // 2
    draw.polygon(
        [(cx - 18, CARD_H - 1), (cx + 18, CARD_H - 1), (cx, CARD_H + POINTER)],
        fill=(255, 255, 255, 255),
    )
    return img


def fragmented_sample() -> Image.Image:
    """A deliberately over-fragmented image (700 alpha islands > 512 rects)."""
    img = Image.new("RGBA", (320, 170), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cols, rows = 35, 20
    for row in range(rows):
        for col in range(cols):
            x = 10 + col * 8
            y = 10 + row * 7
            shade = 40 + (col * row) % 180
            draw.rectangle((x, y, x + 2, y + 2), fill=(shade, shade, 255, 255))
    return img


def write_png(img: Image.Image, path: pathlib.Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, format="PNG", optimize=True)
    print(f"{path.relative_to(ROOT)}  {path.stat().st_size} bytes")


def main() -> None:
    for index, (slug, title, subtitle, accent) in enumerate(POIS, start=1):
        write_png(rounded_card(index, title, subtitle, accent), OUT / f"card_{index:02d}_{slug}.png")
    write_png(fragmented_sample(), OUT / "fragmented.png")


if __name__ == "__main__":
    main()
