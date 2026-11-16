#!/usr/bin/env python3
"""Draws the KymMaths Curious Atelier Family app icon (Vol. I · The Patterned World).

Matches `BookKitBookIdentity.writeAppIconPNG` (`teaching_kit/Sources/KymBookKit/BookKitPatternedChrome.swift`):
Oxford Prussian Navy (`#182B49`) Savile-Row cloth spine with gold foil `I / MATH` stamp,
stepped right fore-edge paper stack, engraved ivory cartouche plate with drafting dot-grid,
top-right vermilion swallowtail bookmark ribbon, and Euclid I.1 intersecting circles enclosing
an ink-keylined golden equilateral triangle.
Needs rsvg-convert and magick (Homebrew librsvg, imagemagick).
Usage: scripts/make-app-icon.py   (writes KymMaths/Assets.xcassets/AppIcon.appiconset)
"""
import json
import os
import subprocess
import tempfile

S = 1024
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "KymMaths", "Assets.xcassets", "AppIcon.appiconset")

PAPER = dict(
    spine="#182B49", cover="#F9F4E8", plate="#FFFDF7",
    step1="#EFE8D9", step2="#E4DBCA", step3="#D6CCBA",
    ink="#1F1B16", foil="#E2BA68", rule="rgba(168,126,58,0.55)",
    red="#AE2B20", red_wash="#F6DCD5",
    yellow="#E2A41C",
    blue="#23519C", blue_wash="#DCE4F2",
)
DUSK = dict(
    spine="#101D33", cover="#1E2226", plate="#262A2F",
    step1="#2B2F35", step2="#22262A", step3="#181A1D",
    ink="#F0ECE2", foil="#E2BA68", rule="rgba(215,170,95,0.48)",
    red="#F07868", red_wash="#3A1D18",
    yellow="#F0BC45",
    blue="#82A8EA", blue_wash="#17233A",
)
TINTED = dict(
    spine="#1C1C1C", cover="#2E2E2E", plate="#3A3A3A",
    step1="#444444", step2="#333333", step3="#222222",
    ink="#FFFFFF", foil="#E0E0E0", rule="rgba(220,220,220,0.45)",
    red="#C8C8C8", red_wash="#525252",
    yellow="#A8A8A8",
    blue="#E8E8E8", blue_wash="#606060",
)


def svg(p):
    dots = []
    for gx in range(298, 800, 36):
        for gy in range(162, 864, 36):
            dots.append(f'<circle cx="{gx}" cy="{gy}" r="2.2" fill="{p["rule"]}" opacity="0.45"/>')
    dots_svg = "\n".join(dots)
    leaves = "\n".join(
        f'<line x1="892" y1="{y}" x2="976" y2="{y}" stroke="{p["ink"]}" stroke-opacity="0.22" stroke-width="2"/>'
        for y in range(96, 929, 28)
    )
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">
<!-- 1. Stepped Right Fore-Edge Paper Stack -->
<rect x="0" y="0" width="{S}" height="{S}" fill="{p['step3']}"/>
<rect x="0" y="0" width="952" height="{S}" fill="{p['step2']}"/>
<rect x="0" y="0" width="922" height="{S}" fill="{p['step1']}"/>
{leaves}
<!-- 2. Main Front Cover Board & Cloth Spine -->
<rect x="0" y="0" width="892" height="{S}" fill="{p['cover']}"/>
<line x1="892" y1="0" x2="892" y2="{S}" stroke="{p['ink']}" stroke-width="8"/>
<rect x="0" y="0" width="208" height="{S}" fill="{p['spine']}"/>
<rect x="198" y="0" width="10" height="{S}" fill="#000000" fill-opacity="0.28"/>
<line x1="180" y1="56" x2="180" y2="968" stroke="{p['foil']}" stroke-width="5" stroke-dasharray="16 14"/>
<line x1="20" y1="164" x2="166" y2="164" stroke="{p['foil']}" stroke-width="5"/>
<line x1="20" y1="180" x2="166" y2="180" stroke="{p['foil']}" stroke-width="5"/>
<line x1="20" y1="844" x2="166" y2="844" stroke="{p['foil']}" stroke-width="5"/>
<line x1="20" y1="860" x2="166" y2="860" stroke="{p['foil']}" stroke-width="5"/>
<rect x="34" y="234" width="122" height="122" rx="18" fill="#000000" fill-opacity="0.24" stroke="{p['foil']}" stroke-width="4"/>
<text x="95" y="317" text-anchor="middle" font-family="Georgia, serif" font-weight="bold" font-size="64" fill="{p['foil']}">I</text>
<text x="95" y="792" text-anchor="middle" font-family="Helvetica Neue, Arial, sans-serif" font-weight="bold" font-size="24" fill="{p['foil']}">MATH</text>
<!-- 3. Engraved Atelier Cartouche Plate -->
<rect x="252" y="116" width="592" height="792" rx="36" fill="{p['plate']}" stroke="{p['ink']}" stroke-width="8"/>
<rect x="270" y="134" width="556" height="756" rx="24" fill="none" stroke="{p['rule']}" stroke-width="3"/>
{dots_svg}
<!-- 4. Top-Right Swallowtail Bookmark Ribbon -->
<polygon points="742,0 802,0 802,182 772,150 742,182" fill="{p['red']}" stroke="{p['ink']}" stroke-width="5" stroke-linejoin="round"/>
<!-- 5. Vol. I Euclid I.1 Intersecting Circles & Golden Equilateral Triangle -->
<circle cx="462" cy="544" r="170" fill="{p['blue_wash']}"/>
<circle cx="632" cy="544" r="170" fill="{p['red_wash']}"/>
<circle cx="462" cy="544" r="170" fill="none" stroke="{p['blue']}" stroke-width="14" stroke-dasharray="22 14"/>
<circle cx="632" cy="544" r="170" fill="none" stroke="{p['red']}" stroke-width="14"/>
<polygon points="462,544 547,397 441,336 356,483" fill="{p['blue']}" stroke="{p['ink']}" stroke-width="10" stroke-linejoin="round"/>
<polygon points="547,397 462,544 632,544" fill="{p['yellow']}" stroke="{p['ink']}" stroke-width="12" stroke-linejoin="round"/>
<circle cx="462" cy="544" r="11" fill="{p['plate']}" stroke="{p['ink']}" stroke-width="6"/>
<circle cx="632" cy="544" r="11" fill="{p['plate']}" stroke="{p['ink']}" stroke-width="6"/>
<circle cx="547" cy="397" r="11" fill="{p['plate']}" stroke="{p['ink']}" stroke-width="6"/>
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
