# image_lines

Processing sketch that converts an image into a stippled line drawing by modulating the **amplitude or spacing of lines** based on pixel brightness.

---

## Getting a Release

No Processing, Java, or ControlP5 installation is required to run a release build — everything needed is bundled in the zip.

1. Download the release zip (see `releases/` or wherever it was shared with you).
2. Unzip it anywhere.
3. Run the `.exe` inside — that's it.

---

## Examples

### Tree — straight lines at 45°

| Source | Result |
|--------|--------|
| <img src="docs/tree.png" width="400"> | <img src="docs/tree_lines.png" width="400"> |

**Mode:** Straight · **direction=**`-44.4°` · **size=**`1144` · **spacing=**`1.13` · **precision=**`3.60`  
**Threshold:** `distribution=mirror` · `black` · `nb_values=6` · `power=-0.13` · range `0–229.5`

---

### Eye — sinus lines

| Source | Result |
|--------|--------|
| <img src="docs/eye3.png" width="400"> | <img src="docs/eye_curve.png" width="400"> |

**Mode:** Sinus · **direction=**`-57.6°` · **size=**`587` · **spacing=**`0.63` · **amplitude=**`20` · **period=**`140.5`  
**Threshold:** `distribution=mirror` · `black` · `nb_values=6` · `power=-0.13` · range `0–129.2`

---

### Moon — circle lines

| Source | Result |
|--------|--------|
| <img src="docs/moon.png" width="400"> | <img src="docs/moon_lines.png" width="400"> |

**Mode:** Circle · **min_radius=**`0` · **max_radius=**`1890` · **center=**`(-960, 493)` · **spacing=**`1.0` · **precision=**`1.44`  
**Threshold:** `distribution=progressive` · `nb_values=11` · `power=-0.33` · range `74.8–255` · bright areas drawn (black off) · black background

close up : <img src="docs/moon_close_up.png" width="400">

---

## Line Modes

Three curve types are available, selectable via a radio button in the Lines tab:

### Straight Lines

Parallel lines at an arbitrary angle.

| Parameter | Role |
|-----------|------|
| `direction` | Angle of the lines in degrees (−90 to 90). Shortcuts: `---` `///` `|||` `\\\` |
| `size` | Half-length of the lines (radius around the canvas centre) |

### Circle Lines

Concentric ellipses (or circles) around a configurable centre.

| Parameter | Role |
|-----------|------|
| `min_radius` | Radius of the innermost circle |
| `max_radius` | Radius of the outermost circle |
| `center_x` / `center_y` | Offset of the centre from the canvas centre |
| `ellipse` | Ellipse ratio: `0` = perfect circle, positive/negative = stretched |

### Sinus Lines

Sinusoidal waves, parallel, at an arbitrary angle.

| Parameter | Role |
|-----------|------|
| `direction_sinus` | Angle of the wave propagation (shown as "Direction" in the GUI) |
| `size` | Half-length (radius) |
| `high` | Peak-to-peak amplitude of the wave (shown as "Amplitude" in the GUI) |
| `period` | Wavelength of the sinusoid |

---

## Common Lines Parameters

| Parameter | Role |
|-----------|------|
| `lines_spacing` | Distance between adjacent lines |
| `precision` | Step size along each line when sampling pixels (lower = smoother, slower) |
| `nb_lines` | Computed automatically from `size` and `lines_spacing` |

---

## Threshold Filter

The threshold system controls which segments of each line are drawn, based on pixel brightness.

| Parameter | Role |
|-----------|------|
| `nb_values` | Number of threshold levels (1 to 12) |
| `black` | If on, draw segments in dark areas; if off, draw in bright areas |
| `distribution_mode` | Threshold order across adjacent lines: `progressive`, `mirror`, `hachures`, `interleaved`, or `bisect` |
| `power` | Curve exponent: `0` = linear, `> 0` = concentrated toward bright, `< 0` = concentrated toward dark |
| `min_value` / `max_value` | Tonal range clamp before threshold evaluation |

With `nb_values > 1`, multiple threshold bands create alternating drawn/undrawn segments — similar to a halftone screen effect.

---

For the algorithm details, file architecture, and how to build a release yourself, see [DEVELOPMENT.md](DEVELOPMENT.md).

---

## Usage Tips

- **Straight lines at 45°** with tight spacing give a classic engraving look.
- **Circle lines** centred on an eye or face follow the natural contours and produce a striking result.
- **Sinus lines** add organic texture; keep amplitude small relative to spacing for subtle modulation.
- A negative `power` value concentrates thresholds in the shadows, useful for high-contrast portraits.
- `distribution_mode = mirror` with `nb_values = 3–5` creates a symmetric band pattern that reads well at plotter scale.
- `distribution_mode = hachures` alternates far-apart thresholds on adjacent lines, helping keep hatch separation after plotting.
- `distribution_mode = interleaved` spreads successive thresholds between already-used lines to keep transitions more evenly distributed.
- `distribution_mode = bisect` places les seuils par subdivision binaire pondérée : i=0 → seuil 0, puis chaque position est déterminée par le nombre de zéros terminaux de son indice. La période vaut 2^(n-1) et les seuils hauts sont plus fréquents (seuil n-1 toutes les 2 lignes, seuil n-2 toutes les 4 lignes, etc.). Pour n=4 : `0 3 2 3 1 3 2 3`.
- `distribution_mode = bisect_bfs` variante équifréquente : chaque seuil apparaît exactement une fois (période = n). Subdivision BFS du milieu de chaque sous-intervalle. Pour n=8 : `0 4 2 6 1 3 5 7`.
- Lower `precision` (e.g. 0.5–1.0) is needed for smooth circles at large radii; higher values (3–5) are fine for straight lines.

---

## Changelog

### 2026-08-19 — xLib 3.13.4
- **File picker**: Load/Save now use an in-app file browser (folder navigation, file list) instead of the native OS dialog.
- **Clip Ratio**: the clipping rectangle can be locked to a fixed aspect ratio (None, A4, 16:9, 4:3, Raisin, 1:1), with a Landscape toggle to swap orientation.
- **Build**: added `export_app.ps1` to produce a standalone, installer-free release build (no Processing/Java/ControlP5 needed by end users).
- **Docs**: split into `README.md` (usage) and `DEVELOPMENT.md` (algorithm, architecture, build); fixed the Sinus Lines parameter table (was documenting non-existent `direction`/`amplitude` fields instead of the actual `direction_sinus`/`high`).

### 2026-05-11
- **Refactoring**: switched `ImageLinesGenerator` to `PolylineGroup` — clipping now delegated to `PolylineGroup.draw()`, removed `clipLines()`, `clipLine()`, `isPointInClipRect()`, `addSegmentToLine()`.
- **ThresholdFilter**: `buildLines()` now takes `PolylineGroup` instead of `ArrayList<ImageLine>`.
- **StraightLines / SinusLines / CircleLines**: updated to use `group.add/clear`.

### 2026-05-10
- **README**: initial documentation.

### 2026-05-02
- **Fix**: image centering correction.

### 2026-05-01
- **Renaming**: `Image` moved to `xLib_Image`.

### 2026-04-26
- **Fix**: circle centre offset correction.
- **Settings**: added `artemis` presets.

### 2026-04-17 — v2.2.11
- **Export**: SVG and PDF export now use page-adapted dimensions.

### 2026-04-14
- **Fix**: alignment corrections.

### 2026-04-13 — v2.2.9
- **Polyline**: simplified hierarchy — removed `SegmentedPolyline`.
- **Clipping**: extracted common `clipLineToCenteredRect()` into `xLib_ClippingUtils`, unified across all 3 projects.

### 2026-04-13 — v2.2.7
- **Refactoring**: unified `Polyline` usage across all 3 projects.
- **Types**: introduced `ImageLine` to clarify line types.
- **Lazy update**: `data.any_change()` mechanism to avoid unnecessary redraws.

### 2026-04-13 — v2.2.6
- **xLib**: generic `Polyline` abstraction extracted into `xLib_Polyline`.

### 2026-03-01
- **Refactoring**: major data restructuring, data moved to dedicated files, xLib extraction.
- **Fix**: filename fix on save.

### 2026-02-28 — v2.2.4
- **Sinus lines**: sinusoidal line mode added.
- **Scaling**: global scale support added.
- **xLib ControlGroup**: UI controls can now be grouped and shown/hidden together.
- **Fixes**: canvas fix, toggle fix, xLib fixes.

### 2026-02-14
- **Processing compatibility**: adaptations for Processing 3 retrocompatibility.

### 2026-01-07
- **Navigation**: added Next / Prev file navigation.

### 2026-01-03
- **Fix**: line spacing correction.
- **xLib**: update and cleanup.

### 2025-05-16
- **Clean version**: scanlines stabilised (straight lines working cleanly).
- **Settings**: `default` tree preset added.

### 2025-05-10
- **Ellipse mode**: ellipse support added to circle lines.

### 2025-05-09
- **Fix**: post-load correction.
- **Cleanup**: major code cleanup.

### 2025-05-06
- **Straight lines**: first working implementation of image-mapped straight lines.

### 2025-05-05
- **First steps**: project created.
