String get_xlib_version()
{
  return "2.2.14";
}


/*

 # CHANGELOG

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