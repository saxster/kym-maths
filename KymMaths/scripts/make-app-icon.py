#!/usr/bin/env python3
"""Draws the KymMaths app icon: Euclid I.47 as Oliver Byrne coloured it in 1847.

A 3-4-5 right triangle stands on the square of its hypotenuse (blue), with the squares of
its legs (red, yellow) above. Paper for light, Dusk for dark, grey values for tinted.
Needs rsvg-convert and magick (Homebrew librsvg, imagemagick).
Usage: scripts/make-app-icon.py   (writes KymMaths/Assets.xcassets/AppIcon.appiconset)
"""
import json
import math
import os
import subprocess
import tempfile

S = 1024
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "KymMaths", "Assets.xcassets", "AppIcon.appiconset")

# Byrne values from Design/Patterned/PatternedPalette.swift.
PAPER = dict(bg0="#FBF6EC", bg1="#EFE6D3", ink="#1E1A15", tri="#FBF6EC",
             red="#C3362B", yellow="#E2A41C", blue="#23519C")
DUSK = dict(bg0="#25221E", bg1="#141210", ink="#EFE6D3", tri="#25221E",
            red="#E5614F", yellow="#F0BC45", blue="#7097DA")
TINTED = dict(bg0="#000000", bg1="#000000", ink="#FFFFFF", tri="#000000",
              red="#B4B4B4", yellow="#7A7A7A", blue="#F2F2F2")


def figure():
    """Triangle and squares in unit coordinates, turned so the hypotenuse lies flat with its square below."""
    C, B, A = (0.0, 0.0), (4.0, 0.0), (0.0, 3.0)
    shapes = dict(
        hyp=[A, B, (7.0, 4.0), (3.0, 7.0)],
        long_leg=[C, B, (4.0, -4.0), (0.0, -4.0)],
        short_leg=[C, A, (-3.0, 3.0), (-3.0, 0.0)],
        tri=[C, B, A],
        right_angle=[(0.0, 0.5), (0.5, 0.5), (0.5, 0.0)],
    )
    t = math.pi - math.atan2(-3, 4)
    turn = lambda p: (p[0] * math.cos(t) - p[1] * math.sin(t), p[0] * math.sin(t) + p[1] * math.cos(t))
    return {k: [turn(p) for p in v] for k, v in shapes.items()}


def svg(p, extent=0.62):
    sh = figure()
    pts_all = [q for k, v in sh.items() if k != "right_angle" for q in v]
    xs = [q[0] for q in pts_all]
    ys = [q[1] for q in pts_all]
    u = extent * S / max(max(xs) - min(xs), max(ys) - min(ys))
    mx, my = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
    pts = lambda P: " ".join(f"{S / 2 + (x - mx) * u:.1f},{S / 2 - (y - my) * u:.1f}" for x, y in P)
    stroke = 0.17 * u
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">
<defs><radialGradient id="g" cx="50%" cy="42%" r="75%"><stop offset="0" stop-color="{p['bg0']}"/><stop offset="1" stop-color="{p['bg1']}"/></radialGradient></defs>
<rect width="{S}" height="{S}" fill="url(#g)"/>
<polygon points="{pts(sh['hyp'])}" fill="{p['blue']}"/>
<polygon points="{pts(sh['long_leg'])}" fill="{p['red']}"/>
<polygon points="{pts(sh['short_leg'])}" fill="{p['yellow']}"/>
<polygon points="{pts(sh['tri'])}" fill="{p['tri']}" stroke="{p['ink']}" stroke-width="{stroke:.1f}" stroke-linejoin="round"/>
<polyline points="{pts(sh['right_angle'])}" fill="none" stroke="{p['ink']}" stroke-width="{stroke * 0.6:.1f}"/>
</svg>'''


def render(svg_text, png, tmp):
    src = os.path.join(tmp, os.path.basename(png) + ".svg")
    with open(src, "w") as f:
        f.write(svg_text)
    subprocess.run(["rsvg-convert", "-w", str(S), "-h", str(S), src, "-o", png], check=True)


def mac_icon(full_png, size, png):
    """macOS 14 and 15 draw the file as given, so the Mac sizes carry their own rounded tile and margin."""
    tile = round(size * 824 / 1024)
    radius = round(tile * 0.2237)
    subprocess.run([
        "magick", full_png, "-resize", f"{tile}x{tile}",
        "(", "-size", f"{tile}x{tile}", "xc:black", "-fill", "white",
        "-draw", f"roundrectangle 0,0,{tile - 1},{tile - 1},{radius},{radius}", ")",
        "-alpha", "off", "-compose", "CopyOpacity", "-composite",
        "-compose", "Over", "-background", "none", "-gravity", "center", "-extent", f"{size}x{size}", png,
    ], check=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    images = []
    with tempfile.TemporaryDirectory() as tmp:
        for name, palette, appearance in [("AppIcon.png", PAPER, None), ("AppIcon-Dark.png", DUSK, "dark"),
                                          ("AppIcon-Tinted.png", TINTED, "tinted")]:
            render(svg(palette), os.path.join(OUT, name), tmp)
            entry: dict[str, object] = dict(filename=name, idiom="universal", platform="ios", size="1024x1024")
            if appearance:
                entry["appearances"] = [dict(appearance="luminosity", value=appearance)]
            images.append(entry)
        full = os.path.join(OUT, "AppIcon.png")
        for pt in (16, 32, 128, 256, 512):
            for scale in (1, 2):
                name = f"AppIcon-mac-{pt}@{scale}x.png"
                mac_icon(full, pt * scale, os.path.join(OUT, name))
                images.append(dict(filename=name, idiom="mac", scale=f"{scale}x", size=f"{pt}x{pt}"))
    with open(os.path.join(OUT, "Contents.json"), "w") as f:
        json.dump(dict(images=images, info=dict(author="xcode", version=1)), f, indent=2)
    with open(os.path.join(OUT, "..", "Contents.json"), "w") as f:
        json.dump(dict(info=dict(author="xcode", version=1)), f, indent=2)
    print(f"wrote {len(images)} images to {os.path.normpath(OUT)}")


if __name__ == "__main__":
    main()
