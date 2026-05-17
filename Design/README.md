# Design source

Master art for the app's visual identity. The shipping assets are generated
from these and live in `Sources/Support/Assets.xcassets/`.

| File | Role |
|---|---|
| `app-icon-master.png` | 1254×1254 master for the macOS app icon (violet squircle, white swing). |
| `menubar-glyph-source.png` | Black swing glyph; source for the monochrome menu-bar template image. |
| `app-icon-hero.png` | Downscaled copy used only by the project README. |

## Regenerating the shipped assets

```sh
ICON=Sources/Support/Assets.xcassets/AppIcon.appiconset
STAT=Sources/Support/Assets.xcassets/StatusIcon.imageset

# App icon: key the near-white background to transparency, emit every size.
magick Design/app-icon-master.png -alpha set -fuzz 14% -fill none \
  -draw "alpha 0,0 floodfill"       -draw "alpha 1253,0 floodfill" \
  -draw "alpha 0,1253 floodfill"    -draw "alpha 1253,1253 floodfill" \
  -resize 1024x1024 /tmp/appmaster.png
for s in 16 32 64 128 256 512 1024; do
  magick /tmp/appmaster.png -resize ${s}x${s} "$ICON/icon_${s}.png"
done

# Menu-bar glyph: threshold the black strokes into a proper alpha template.
magick Design/menubar-glyph-source.png -colorspace Gray -negate -threshold 55% /tmp/m.png
magick -size 1254x1254 xc:black /tmp/m.png -alpha off \
  -compose CopyOpacity -composite -trim +repage /tmp/g.png
for k in 1 2 3; do px=$((18*k)); \
  magick /tmp/g.png -bordercolor none -border 6%x6% -background none \
    -gravity center -resize ${px}x${px} -extent ${px}x${px} "$STAT/status_${k}x.png"; done
```

Then `xcodegen generate` and rebuild.
