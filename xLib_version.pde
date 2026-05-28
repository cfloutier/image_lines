String get_xlib_version()
{
  return "3.3.0";
}


/*

 # CHANGELOG

 ## [3.3.0] - 2026-05-28
 - xLib_ThresholdData: new file — DataThreshold + ThresholdGUI shared between image_lines and image_contours
   Supports 6 distribution modes: PROGRESSIVE, MIRROR, HACHURES, INTERLEAVED, BISECT, BISECT_BFS
 - xLib_Polyline: added group_id field (default -1) — used by threshold filters to cycle thresholds per line group / contour level

 ## [3.2.0] - 2026-05-26
 - xLib_ExportUtils: PAPER_NONE no longer aborts writeSVGDirect — fallback to canvas pixel dimensions (K=1, units=px)
 - xLib_ExportUtils: added PAPER_RAISIN (4) — Grand Raisin 500x650 mm
 - xLib_ExportUtils: all console prints renamed [SVG] → [SVG direct] for clarity
 - xLib_FileUI: ExportSVG() — removed paper_format != PAPER_NONE condition, direct writer always used when data connected
 - xLib_FileUI: added [SVG direct] / [SVG Processing] console prints to distinguish export paths
 - xLib_FileUI: button renamed "Export SVG" → "SVG direct"
 - xLib_FileUI: added Raisin to paper format radio button and _Raisin filename suffix

 ## [3.1.0] - 2026-05-25
 - xLib_ExportUtils: added writeSVGDirect(ShapesGroup) overload — exports dots as zero-length SVG lines with round linecap (AxiDraw convention)
 - xLib_ShapesGroup: new file — Dot class (PVector pos) and ShapesGroup class (ArrayList<Polyline> + ArrayList<Dot>)
   Includes draw(), getBoundingBox(), addDot(), addPolyline(), clear(), totalCount(), dotCount(), polylineCount()
 - xLib_FileUI: added export_shapes (ShapesGroup) field — checked before export_group in ExportSVG()
 - xLib_ExportUtils: centeredToMM() rotation fixed from -90deg to +90deg (swapped direction)

 ## [3.0.0] - 2026-05-25
 - xLib_ExportUtils: added writeSVGDirect() — direct SVG writer bypassing Processing's SVG renderer
   Writes coordinates in mm using the same transform as start_draw() (auto-centering via bbox, optional -90deg rotation)
   Handles clipping (clipLineToCenteredRect per segment) and non-clipping (continuous path per polyline)
   Prints console progress every 10% of polylines
 - xLib_ExportUtils: added centeredToMM() helper for drawing-space to mm page coordinate conversion
 - xLib_FileUI: FileGUI.export_group (PolylineGroup) — set in sketch setup() to enable direct SVG export
 - xLib_FileUI: ExportSVG() uses direct writer when export_group is set + paper format selected; falls back to Processing renderer otherwise
 - xLib_FileUI: added ExportSVGProcessing() — forces Processing's SVG renderer (legacy fallback button)
 - xLib_FileUI: removed Export PDF button from GUI

 ## [2.4.0] - 2026-05-22
 - xLib_ExportUtils: removed EXPORT_DPI — getPaperDimensions() now returns mm (physical units)
 - xLib_ExportUtils: added mmToSvgPx() — mm to SVG px conversion using fixed standard (96px/inch, not a calibration value)
 - xLib_FileUI: SVG/PDF canvas sized via mmToSvgPx() instead of a configurable DPI
 - xLib_ExportUtils: replaced 10cm margin option with 2cm — margins are now 0cm, 1cm, 2cm, 3cm
 - Fix: A3 export was producing A2 output in Inkscape (EXPORT_DPI=135 ≈ 96×√2 caused one paper size offset)

 ## [2.3.0] - 2026-05-22
 - xLib_FileUI: ScaleSlider caption label aligned consistently with other sliders (marginTop/marginLeft)
 - image_lines: Image tab opened by default

 ## [2.2.20] - 2026-05-22
 - xLib_Image: draw toggle and imageAlpha moved to DataImage (saved/loaded via JSON)
 - xLib_Image: blackAndWhite toggle — applies GRAY filter during buildTransformedImage
 - xLib_Image: levels adjustment (levelsMin, levelsMax, levelsGamma) applied pixel-by-pixel; gamma uses -1..1 slider mapped via pow(5,x)
 - xLib_Image: Reset Levels button restores default level values
 - xLib_Image: buildBlurredImage renamed to buildTransformedImage

 ## [2.2.19] - 2026-05-22
 - processing_xlib: création du fichier .github/copilot-instructions.md avec le contexte xLib (workflow, projets synchronisés, scripts)
 
 ## [2.2.18] - 2026-05-18
 - xLib_Polyline: added getBoundingBox() method to calculate the bounding box of a polyline, used for clipping and export.
 - xLib_Polyline: added PolylineGroup class to manage groups of polylines with integrated clipping and bounding box support.


 ## [2.2.17] - 2026-05-10
 - processing_xlib: switched to PolylineGroup for drawing and bbox — clipping logic no longer duplicated in sketch
 - processing_xlib: buildLines() generates N polylines with random point count (nb_points_min to nb_points_max) on the ellipse
 - processing_xlib: replaced nb_lines with nb_polylines, nb_points_min, nb_points_max parameters


 ## [2.2.16] - 2026-05-18
 - xLib_Image: renamed blurred_image to transformed_image to reflect that it may also include contrast changes (TODO), not just blur 

 ## [2.2.15] - 2026-05-10
 - xLib_FileUI: FileGUI constructor takes optional boolean show_clipping (default false) — hides clipping controls in projects that don't use it

 ## [2.2.14] - 2026-05-10
 - xLib_Image: ImageAlpha removed from DataImage — now GUI-only in ImageGUI (no longer triggers data.changed or regeneration)
 - xLib_Image: draw() now takes imageAlpha as a parameter instead of reading data.ImageAlpha
 - xLib_Image: ImageGUI.controlEvent() overridden to handle the alpha slider without propagating a change
 - xLib_StringUtils: added formatDuration(int ms) — formats a duration in ms/s/min/h/d
 - xLib_StringUtils: fix isEmpty() (spurious blank line removed)

 ## [2.2.13] - 2026-05-02
 - xLib_Image.draw(): coordinates corrected for centring via translate (origin already at centre via start_draw)
 - image drawn at (-image_w/2, -image_h/2) instead of (width/2 - image_w/2, height/2 - image_h/2)

 ## [2.2.12] - 2026-05-01
 - Image.pde renamed to xLib_Image.pde for integration into the shared xLib
 - xLib_Image: _image_gui global variable to avoid errors in projects without an image
 - imgFileSelected() checks _image_gui != null before calling setImage()

 ## [2.2.11] - 2026-04-17
 - SVG and PDF export now use page-adapted dimensions.

 ## [2.2.10] - 2026-04-13
 - Full clipping implementation with line breaking at edges
 - addLineSegment() detects inside↔outside transitions and breaks lines
 - pointInClipRect() shared function to test whether points are inside/outside the clip rect
 - Unified any_change() to re-trigger generation when clipping changes

 ## [2.2.9] - 2026-04-13
 - Simplified Polyline hierarchy: removed SegmentedPolyline
 - SpiralLine now uses base Polyline (continuous drawing)
 - Clipping extracted into shared clipLineToCenteredRect() in xLib_ClippingUtils
 - Full unification of xLib_Polyline and xLib_ClippingUtils across all 3 projects

 ## [2.2.8] - 2026-04-13
 - Renamed generator classes by removing "Drawing"
 - SpiralDrawingGenerator -> SpiralGenerator
 - PerlinDrawingGenerator -> PerlinGenerator
 - Simplified file names

 ## [2.2.7] - 2026-04-13
 - Full refactoring of all 3 projects with uniform Polyline usage
 - Introduced SpiralLine, PerlinLine, ImageLine to clarify types
 - Separated computation/rendering with update() in DrawingGenerator spiral
 - Lazy-update mechanism based on data.any_change()

 ## [2.2.6] - 2026-04-13
 - Generic Polyline abstraction for perlin_mountains and image_processor
 - Created xLib_Polyline with base Polyline class and ValidatedPolylineWithOffset

 ## [2.2.5] - 2025-03-01
 - Cleanup and fix of filename at save time

 ## [2.2.4.1] - 2025-02-28
 - Added ControlGroup to allow grouping UI controls that can be shown/hidden together
 - .1 = fix of filename at save time

 ## [2.2.3] - 2025-02-28
 - Minor cleanup

 ## [2.2.2] - 2025-02-12
 - Complete refactoring of file management: UI + data with added clipping and scale sliders, now properly saved

 ## [2.2.0] - 2024-06-30
 # - added get_xlib_version() function to return the current version of xLib. This
 #   can be used for debugging and to ensure compatibility with different versions of xLib.

 ## [2.1.0] - 2024-05-15
 # - added support for global scale in the DataPage class. This allows users to scale the entire page, which can be useful for printing or exporting to PDF/SVG. The global scale can be adjusted using a slider in the UI.
 
 
 */