import os
import subprocess
from PIL import Image

output_dir = r"D:\APP\assets\icon"
os.makedirs(output_dir, exist_ok=True)

# 1. Generate Full Icon SVG
svg_full = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#0F1B2D"/>
      <stop offset="100%" stop-color="#0B1220"/>
    </linearGradient>
    <linearGradient id="mintGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#4EEDB6"/>
      <stop offset="100%" stop-color="#3DDCA5"/>
    </linearGradient>
    <filter id="softGlow" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="16" result="blur"/>
      <feComposite in="SourceGraphic" in2="blur" operator="over"/>
    </filter>
  </defs>

  <!-- Background -->
  <rect width="1024" height="1024" fill="url(#bgGrad)"/>

  <!-- Subtle ambient glow behind icon -->
  <circle cx="512" cy="520" r="280" fill="#3DDCA5" opacity="0.07" filter="url(#softGlow)"/>

  <g id="eco-symbol">
    <!-- Lifted Lid Assembly (Tilted -12 degrees around left hinge area ~ x:330, y:400) -->
    <g transform="rotate(-12 330 405)">
      <!-- Lid Handle -->
      <path d="M 460 338 C 460 322 472 310 488 310 L 536 310 C 552 310 564 322 564 338 L 564 346 L 460 346 Z" 
            fill="url(#mintGrad)"/>
      <!-- Main Lid Bar with rounded ends -->
      <rect x="290" y="346" width="444" height="42" rx="21" fill="url(#mintGrad)"/>
    </g>

    <!-- Smart IoT Waves / Ultrasonic Arc (radiating from open right side) -->
    <path d="M 605 385 A 36 36 0 0 1 635 415" 
          fill="none" stroke="#3DDCA5" stroke-width="14" stroke-linecap="round"/>
    <path d="M 635 365 A 66 66 0 0 1 685 418" 
          fill="none" stroke="#3DDCA5" stroke-width="14" stroke-linecap="round" opacity="0.75"/>

    <!-- Bin Container Body -->
    <!-- Tapered container with rounded bottom corners and clean leaf cutout in negative space -->
    <path d="M 334 430 
             L 690 430 
             C 696 430 700 435 699 441 
             L 662 724 
             C 658 755 632 778 600 778 
             L 424 778 
             C 392 778 366 755 362 724 
             L 325 441 
             C 324 435 328 430 334 430 Z" 
          fill="url(#mintGrad)"/>

    <!-- Cutout: Organic Leaf Motif (Negative space cut showing the dark navy background) -->
    <!-- Leaf body -->
    <path d="M 512 490 
             C 575 510 605 565 590 635 
             C 580 680 545 700 512 705 
             C 479 700 444 680 434 635 
             C 419 565 449 510 512 490 Z" 
          fill="#0B1220"/>

    <!-- Leaf Center Stem / Vein (Mint green curve flowing through center of the leaf) -->
    <path d="M 512 498 
             C 512 550 516 610 495 665 
             C 490 678 478 688 465 694" 
          fill="none" stroke="url(#mintGrad)" stroke-width="10" stroke-linecap="round"/>
  </g>
</svg>
'''

# 2. Generate Foreground SVG (Transparent background, Mint Symbol)
svg_foreground = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <linearGradient id="mintGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#4EEDB6"/>
      <stop offset="100%" stop-color="#3DDCA5"/>
    </linearGradient>
    <mask id="leafCutout">
      <!-- White reveals everything -->
      <rect width="1024" height="1024" fill="#FFFFFF"/>
      <!-- Black cuts out the leaf interior to transparent -->
      <path d="M 512 490 
               C 575 510 605 565 590 635 
               C 580 680 545 700 512 705 
               C 479 700 444 680 434 635 
               C 419 565 449 510 512 490 Z" 
            fill="#000000"/>
    </mask>
  </defs>

  <g id="eco-symbol">
    <!-- Lifted Lid Assembly (Tilted -12 degrees around left hinge area ~ x:330, y:400) -->
    <g transform="rotate(-12 330 405)">
      <!-- Lid Handle -->
      <path d="M 460 338 C 460 322 472 310 488 310 L 536 310 C 552 310 564 322 564 338 L 564 346 L 460 346 Z" 
            fill="url(#mintGrad)"/>
      <!-- Main Lid Bar with rounded ends -->
      <rect x="290" y="346" width="444" height="42" rx="21" fill="url(#mintGrad)"/>
    </g>

    <!-- Smart IoT Waves / Ultrasonic Arc -->
    <path d="M 605 385 A 36 36 0 0 1 635 415" 
          fill="none" stroke="#3DDCA5" stroke-width="14" stroke-linecap="round"/>
    <path d="M 635 365 A 66 66 0 0 1 685 418" 
          fill="none" stroke="#3DDCA5" stroke-width="14" stroke-linecap="round" opacity="0.75"/>

    <!-- Bin Container Body with Leaf Cutout Mask -->
    <path d="M 334 430 
             L 690 430 
             C 696 430 700 435 699 441 
             L 662 724 
             C 658 755 632 778 600 778 
             L 424 778 
             C 392 778 366 755 362 724 
             L 325 441 
             C 324 435 328 430 334 430 Z" 
          fill="url(#mintGrad)" mask="url(#leafCutout)"/>

    <!-- Leaf Center Stem / Vein -->
    <path d="M 512 498 
             C 512 550 516 610 495 665 
             C 490 678 478 688 465 694" 
          fill="none" stroke="url(#mintGrad)" stroke-width="10" stroke-linecap="round"/>
  </g>
</svg>
'''

# 3. Generate Monochrome SVG (Solid White on Transparent Background)
svg_monochrome = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <mask id="leafCutoutMono">
      <rect width="1024" height="1024" fill="#FFFFFF"/>
      <path d="M 512 490 
               C 575 510 605 565 590 635 
               C 580 680 545 700 512 705 
               C 479 700 444 680 434 635 
               C 419 565 449 510 512 490 Z" 
            fill="#000000"/>
    </mask>
  </defs>

  <g id="eco-symbol-mono">
    <!-- Lifted Lid Assembly -->
    <g transform="rotate(-12 330 405)">
      <!-- Lid Handle -->
      <path d="M 460 338 C 460 322 472 310 488 310 L 536 310 C 552 310 564 322 564 338 L 564 346 L 460 346 Z" 
            fill="#FFFFFF"/>
      <!-- Main Lid Bar -->
      <rect x="290" y="346" width="444" height="42" rx="21" fill="#FFFFFF"/>
    </g>

    <!-- Smart IoT Waves / Ultrasonic Arc -->
    <path d="M 605 385 A 36 36 0 0 1 635 415" 
          fill="none" stroke="#FFFFFF" stroke-width="14" stroke-linecap="round"/>
    <path d="M 635 365 A 66 66 0 0 1 685 418" 
          fill="none" stroke="#FFFFFF" stroke-width="14" stroke-linecap="round" opacity="0.8"/>

    <!-- Bin Container Body with Leaf Cutout Mask -->
    <path d="M 334 430 
             L 690 430 
             C 696 430 700 435 699 441 
             L 662 724 
             C 658 755 632 778 600 778 
             L 424 778 
             C 392 778 366 755 362 724 
             L 325 441 
             C 324 435 328 430 334 430 Z" 
          fill="#FFFFFF" mask="url(#leafCutoutMono)"/>

    <!-- Leaf Center Stem / Vein -->
    <path d="M 512 498 
             C 512 550 516 610 495 665 
             C 490 678 478 688 465 694" 
          fill="none" stroke="#FFFFFF" stroke-width="10" stroke-linecap="round"/>
  </g>
</svg>
'''

files = {
    "ecobin_icon_full.svg": svg_full,
    "ecobin_icon_foreground.svg": svg_foreground,
    "ecobin_icon_monochrome.svg": svg_monochrome,
}

for name, content in files.items():
    path = os.path.join(output_dir, name)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content.strip())
    print(f"Wrote {path}")

# Render to 1024x1024 PNGs using Edge headless
msedge_path = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

variants = [
    ("ecobin_icon_full.svg", "ecobin_icon_full.png"),
    ("ecobin_icon_foreground.svg", "ecobin_icon_foreground.png"),
    ("ecobin_icon_monochrome.svg", "ecobin_icon_monochrome.png"),
]

for svg_name, png_name in variants:
    svg_path = os.path.join(output_dir, svg_name)
    png_path = os.path.join(output_dir, png_name)
    html_path = os.path.join(output_dir, f"_render_{png_name}.html")

    with open(html_path, "w", encoding="utf-8") as f:
        f.write(f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
* {{ margin: 0; padding: 0; box-sizing: border-box; }}
html, body {{ width: 1024px; height: 1024px; overflow: hidden; background: transparent; }}
img {{ width: 1024px; height: 1024px; display: block; }}
</style>
</head>
<body>
<img src="{svg_name}"/>
</body>
</html>""")

    cmd = [
        msedge_path,
        "--headless",
        "--disable-gpu",
        "--window-size=1024,1024",
        "--default-background-color=00000000",
        f"--screenshot={png_path}",
        f"file:///{html_path.replace(os.sep, '/')}",
    ]
    subprocess.run(cmd, check=True)
    if os.path.exists(html_path):
        os.remove(html_path)

    im = Image.open(png_path)
    # Ensure exact 1024x1024
    if im.size != (1024, 1024):
        im = im.resize((1024, 1024), Image.Resampling.LANCZOS)
        im.save(png_path)
    print(f"Rendered {png_name}: size={im.size}, mode={im.mode}")

