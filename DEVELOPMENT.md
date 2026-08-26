# image_lines — Development

Implementation notes, architecture, and build procedure for `image_lines`. For usage/parameters, see [README.md](README.md).

---

## Development Setup

Only needed to open/edit/run the sketch from source — not needed to just run a release build (see [README.md](README.md#getting-a-release)).

1. **Install Processing**: download from https://processing.org/download and install (Java Mode, the default one).
2. **Install ControlP5**: in the Processing IDE, go to `Sketch > Import Library... > Manage Libraries...`, search for **ControlP5**, and click Install. This puts it straight into your sketchbook's `libraries/` folder — no manual download/unzip needed. (Library home page, for reference: http://www.sojamo.de/libraries/controlP5)
3. Open `image_lines.pde` in Processing and press Run.

---

## Principle

A set of lines is generated across the canvas — straight, circular, or sinusoidal. Each line is then filtered by the **threshold system**: segments whose underlying pixel brightness falls above or below a set of thresholds are kept or discarded, making the line visible in dark areas and invisible in bright ones (or the reverse).

The result is a plotter-ready vector drawing where the image is encoded in the presence or absence of line segments.

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

## Building a Release

`export_app.ps1` (project root) builds a standalone, installer-free application and packages it as a release zip.

```powershell
.\export_app.ps1
```

This will:
1. Export the sketch as a standalone application via `processing-java --export` (embeds a JRE and all libraries, including ControlP5 — end users install nothing).
2. Copy `Settings/` into the export (the Processing export step does **not** include it, and the sketch crashes on startup without a `Settings/default.json` to load).
3. Zip the result into `releases/image_lines_<variant>_<date>.zip`, ready to hand out.

Useful options:
```powershell
.\export_app.ps1 -ProcessingPath "D:\tools\processing-4.3\processing-java.exe"  # different Processing install
.\export_app.ps1 -Zip $false                                                    # skip the release zip
```

**Note:** the build always targets the OS you run the script on — `-Variant` does not cross-compile for another platform (verified empirically: requesting `linux-amd64` from Windows still produced a Windows build). To produce a macOS or Linux build, run this script on a machine running that OS.
