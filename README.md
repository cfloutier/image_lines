# image_lines

Processing sketch that converts an image into a stippled line drawing by modulating the **amplitude or spacing of lines** based on pixel brightness.

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

## Principle

A set of lines is generated across the canvas — straight, circular, or sinusoidal. Each line is then filtered by the **threshold system**: segments whose underlying pixel brightness falls above or below a set of thresholds are kept or discarded, making the line visible in dark areas and invisible in bright ones (or the reverse).

The result is a plotter-ready vector drawing where the image is encoded in the presence or absence of line segments.

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
| `direction` | Angle of the wave propagation |
| `size` | Half-length (radius) |
| `amplitude` | Peak-to-peak amplitude of the wave |
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
| `distribution_mode` | Threshold order across adjacent lines: `progressive`, `mirror`, or `hachures` (`hatching`) |
| `power` | Curve exponent: `0` = linear, `> 0` = concentrated toward bright, `< 0` = concentrated toward dark |
| `min_value` / `max_value` | Tonal range clamp before threshold evaluation |

With `nb_values > 1`, multiple threshold bands create alternating drawn/undrawn segments — similar to a halftone screen effect.

---

## Architecture

| File | Role |
|------|------|
| `image_lines.pde` | Setup, draw loop, export |
| `DataGlobal.pde` | `ImgProcData` — aggregates image, lines, threshold, style |
| `LinesData.pde` | `DataLines` + `LinesGUI` — common line parameters and tab |
| `StraightLines.pde` | Straight line geometry and UI |
| `CircleLines.pde` | Circular / ellipse geometry and UI |
| `SinusLines.pde` | Sinusoidal line geometry and UI |
| `ImageLinesGenerator.pde` | Abstract generator — polyline accumulation and clipping |
| `ThresholdFilter.pde` | `DataThreshold` + `ThresholdGUI` — brightness-based segment filtering |
| `DataGUI.pde` | `DataGUI` — assembles the 5 tabs (Files, Image, Lines, Threshold, Style) |

---

## Implementation Details

### Line Generation

Each mode computes a set of `ImageLine` objects (polylines). Points are sampled along each line at `precision`-pixel intervals. Each line is assigned a `group_id` so the threshold filter can treat all segments from the same original line consistently.

### Threshold Filtering

After generation, `ThresholdFilter` walks each line segment by segment, samples the pixel brightness at the midpoint, and decides whether to draw it based on the active threshold band(s). The result is a new set of polylines containing only the visible segments.

### Clipping

Optional rectangular clipping is applied as a post-processing step after generation, preserving `group_id` across clipped sub-segments.

### Export

Supports PDF, SVG, and DXF export (plotter-ready).

---

## Usage Tips

- **Straight lines at 45°** with tight spacing give a classic engraving look.
- **Circle lines** centred on an eye or face follow the natural contours and produce a striking result.
- **Sinus lines** add organic texture; keep amplitude small relative to spacing for subtle modulation.
- A negative `power` value concentrates thresholds in the shadows, useful for high-contrast portraits.
- `distribution_mode = mirror` with `nb_values = 3–5` creates a symmetric band pattern that reads well at plotter scale.
- `distribution_mode = hachures` alternates far-apart thresholds on adjacent lines, helping keep hatch separation after plotting.
- Lower `precision` (e.g. 0.5–1.0) is needed for smooth circles at large radii; higher values (3–5) are fine for straight lines.

---

## Changelog

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
