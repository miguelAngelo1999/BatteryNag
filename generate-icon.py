#!/usr/bin/env python3
"""Generate BatteryNag app icon - a battery with an angry/nagging face"""
from PIL import Image, ImageDraw, ImageFont
import math

SIZE = 1024
PADDING = 80

img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Background: rounded rectangle with gradient feel
# Dark blue-gray background circle
cx, cy = SIZE // 2, SIZE // 2
r = SIZE // 2 - 20
for i in range(r, 0, -1):
    ratio = i / r
    red = int(30 + (1 - ratio) * 20)
    green = int(30 + (1 - ratio) * 15)
    blue = int(50 + (1 - ratio) * 30)
    draw.ellipse([cx - i, cy - i, cx + i, cy + i], fill=(red, green, blue, 255))

# Battery body
batt_left = PADDING + 100
batt_right = SIZE - PADDING - 100
batt_top = 280
batt_bottom = 740
corner_r = 40

# Battery terminal (top nub)
nub_width = 120
nub_height = 40
nub_left = cx - nub_width // 2
draw.rounded_rectangle(
    [nub_left, batt_top - nub_height + 10, nub_left + nub_width, batt_top + 10],
    radius=15,
    fill=(200, 80, 60, 255)
)

# Battery outline
draw.rounded_rectangle(
    [batt_left, batt_top, batt_right, batt_bottom],
    radius=corner_r,
    fill=None,
    outline=(255, 90, 60, 255),
    width=12
)

# Battery fill (low - about 25%)
fill_margin = 20
fill_height = batt_bottom - batt_top - fill_margin * 2
fill_level = int(fill_height * 0.25)
fill_top = batt_bottom - fill_margin - fill_level

# Red gradient fill for low battery
for y in range(fill_top, batt_bottom - fill_margin):
    ratio = (y - fill_top) / fill_level if fill_level > 0 else 0
    red = int(255 - ratio * 40)
    green = int(60 + ratio * 20)
    blue = 40
    draw.rectangle(
        [batt_left + fill_margin, y, batt_right - fill_margin, y + 1],
        fill=(red, green, blue, 200)
    )

# Angry face on the battery
# Eyes - angry slanted eyebrows
eye_y = 440
eye_size = 35

# Left eye
draw.ellipse([cx - 100 - eye_size, eye_y - eye_size, cx - 100 + eye_size, eye_y + eye_size],
             fill=(255, 255, 255, 255))
draw.ellipse([cx - 100 - 15, eye_y - 15, cx - 100 + 15, eye_y + 15],
             fill=(40, 40, 40, 255))

# Right eye
draw.ellipse([cx + 100 - eye_size, eye_y - eye_size, cx + 100 + eye_size, eye_y + eye_size],
             fill=(255, 255, 255, 255))
draw.ellipse([cx + 100 - 15, eye_y - 15, cx + 100 + 15, eye_y + 15],
             fill=(40, 40, 40, 255))

# Angry eyebrows
brow_width = 8
# Left eyebrow (angled down toward center)
draw.line([cx - 145, eye_y - 55, cx - 60, eye_y - 35], fill=(255, 90, 60, 255), width=brow_width)
# Right eyebrow (angled down toward center)
draw.line([cx + 145, eye_y - 55, cx + 60, eye_y - 35], fill=(255, 90, 60, 255), width=brow_width)

# Open yelling mouth
mouth_y = 580
mouth_rx = 80
mouth_ry = 50
draw.ellipse([cx - mouth_rx, mouth_y - mouth_ry, cx + mouth_rx, mouth_y + mouth_ry],
             fill=(180, 40, 30, 255))
# Teeth
teeth_w = 20
teeth_h = 18
for tx in range(-2, 3):
    tooth_x = cx + tx * (teeth_w + 4) - teeth_w // 2
    # Top teeth
    draw.rectangle([tooth_x, mouth_y - mouth_ry, tooth_x + teeth_w, mouth_y - mouth_ry + teeth_h],
                   fill=(255, 255, 255, 255))
    # Bottom teeth
    draw.rectangle([tooth_x, mouth_y + mouth_ry - teeth_h, tooth_x + teeth_w, mouth_y + mouth_ry],
                   fill=(255, 255, 255, 255))

# Lightning bolt (exclamation/energy symbol) top-right
bolt_x = batt_right - 40
bolt_y = batt_top + 30
bolt_points = [
    (bolt_x, bolt_y),
    (bolt_x - 30, bolt_y + 60),
    (bolt_x - 5, bolt_y + 55),
    (bolt_x - 20, bolt_y + 100),
    (bolt_x + 15, bolt_y + 45),
    (bolt_x - 5, bolt_y + 50),
    (bolt_x, bolt_y),
]
draw.polygon(bolt_points, fill=(255, 220, 50, 255))

# Save as PNG
img.save('/Users/virgoh/fix-issues/BatteryNag/icon.png')

# Also create 512x512 for README
img_512 = img.resize((512, 512), Image.LANCZOS)
img_512.save('/Users/virgoh/fix-issues/BatteryNag/icon-512.png')

# Create .icns for the app bundle
import subprocess
import tempfile
import os

iconset_dir = '/Users/virgoh/fix-issues/BatteryNag/BatteryNag.iconset'
os.makedirs(iconset_dir, exist_ok=True)

sizes = [16, 32, 64, 128, 256, 512, 1024]
for s in sizes:
    resized = img.resize((s, s), Image.LANCZOS)
    resized.save(os.path.join(iconset_dir, f'icon_{s}x{s}.png'))
    if s <= 512:
        resized2x = img.resize((s * 2, s * 2), Image.LANCZOS)
        resized2x.save(os.path.join(iconset_dir, f'icon_{s}x{s}@2x.png'))

subprocess.run(['iconutil', '-c', 'icns', iconset_dir, '-o',
                '/Users/virgoh/fix-issues/BatteryNag/BatteryNag.app/Contents/Resources/AppIcon.icns'])

# Clean up iconset
import shutil
shutil.rmtree(iconset_dir)

print("Done! Created icon.png, icon-512.png, and AppIcon.icns")
