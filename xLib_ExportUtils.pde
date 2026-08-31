// Paper format constants
// Values renumbered when A6/A5 were added (ascending size order in the UI) -
// any settings file saved before this change will load with a shifted/wrong
// paper_format index. Accepted tradeoff: the user notices at export time.
final int PAPER_NONE = 0;
final int PAPER_A6 = 1;
final int PAPER_A5 = 2;
final int PAPER_A4 = 3;
final int PAPER_A3 = 4;
final int PAPER_A2 = 5;
final int PAPER_RAISIN = 6;  // Grand Raisin 50x65 cm

// Margin constants (in mm)
final int MARGIN_0CM = 0;
final int MARGIN_1CM = 1;
final int MARGIN_2CM = 2;
final int MARGIN_3CM = 3;

final float MARGIN_0CM_MM = 0;
final float MARGIN_1CM_MM = 10;
final float MARGIN_3CM_MM = 30;
final float MARGIN_2CM_MM = 20;

// Paper dimensions in mm
final float A6_WIDTH_MM = 105;
final float A6_HEIGHT_MM = 148;
final float A5_WIDTH_MM = 148;
final float A5_HEIGHT_MM = 210;
final float A4_WIDTH_MM = 210;
final float A4_HEIGHT_MM = 297;
final float A3_WIDTH_MM = 297;
final float A3_HEIGHT_MM = 420;
final float A2_WIDTH_MM = 420;
final float A2_HEIGHT_MM = 594;
final float RAISIN_WIDTH_MM  = 500;
final float RAISIN_HEIGHT_MM = 650;

// SVG unit conversion: 1 inch = 96px (SVG standard, fixed - not a calibration value)
float mmToSvgPx(float mm) { return mm * 96.0 / 25.4; }

// Calculate bounding box of all drawn lines
class BoundingBox
{
  float minX = Float.MAX_VALUE;
  float maxX = Float.MIN_VALUE;
  float minY = Float.MAX_VALUE;
  float maxY = Float.MIN_VALUE;
  
  float getWidth() { return maxX - minX; }
  float getHeight() { return maxY - minY; }
  
  void addPoint(PVector p) {
    minX = min(minX, p.x);
    maxX = max(maxX, p.x);
    minY = min(minY, p.y);
    maxY = max(maxY, p.y);
  }

  // Merges another bounding box into this one. No-op if other is still empty
  // (minX > maxX, its default state before any addPoint call).
  void addBoundingBox(BoundingBox other) {
    if (other.minX > other.maxX) return;
    addPoint(new PVector(other.minX, other.minY));
    addPoint(new PVector(other.maxX, other.maxY));
  }
}

// Get paper dimensions in mm based on format (portrait orientation)
// Returns [width, height] in mm
float[] getPaperDimensions(int format_enum)
{
  return getPaperDimensions(format_enum, false);
}

// Get paper dimensions in mm based on format.
// landscape=true swaps width/height so the page orientation matches the drawing.
// Returns [width, height] in mm
float[] getPaperDimensions(int format_enum, boolean landscape)
{
  float[] dims;
  switch(format_enum) {
    case PAPER_A6: dims = new float[]{ A6_WIDTH_MM, A6_HEIGHT_MM }; break;
    case PAPER_A5: dims = new float[]{ A5_WIDTH_MM, A5_HEIGHT_MM }; break;
    case PAPER_A4: dims = new float[]{ A4_WIDTH_MM, A4_HEIGHT_MM }; break;
    case PAPER_A3: dims = new float[]{ A3_WIDTH_MM, A3_HEIGHT_MM }; break;
    case PAPER_A2: dims = new float[]{ A2_WIDTH_MM, A2_HEIGHT_MM }; break;
    case PAPER_RAISIN: dims = new float[]{ RAISIN_WIDTH_MM, RAISIN_HEIGHT_MM }; break;
    default: return null;
  }
  if (landscape) { float t = dims[0]; dims[0] = dims[1]; dims[1] = t; }
  return dims;
}

// Print export debug info (bounding box + scale)
// Call this only once per export frame
void printExportDebugInfo(BoundingBox bbox, float scale, int paper_format)
{
  String format_name = "UNKNOWN";
  switch(paper_format) {
    case PAPER_NONE: format_name = "None"; break;
    case PAPER_A6: format_name = "A6"; break;
    case PAPER_A5: format_name = "A5"; break;
    case PAPER_A4: format_name = "A4"; break;
    case PAPER_A3: format_name = "A3"; break;
    case PAPER_A2: format_name = "A2"; break;
    case PAPER_RAISIN: format_name = "Raisin"; break;
  }
  println("\n>>> EXPORT FRAME <<<");
  println("Paper format: " + format_name);
  if (bbox != null) {
    println("BoundingBox: width=" + bbox.getWidth() + ", height=" + bbox.getHeight());
    println("  minX=" + bbox.minX + ", maxX=" + bbox.maxX);
    println("  minY=" + bbox.minY + ", maxY=" + bbox.maxY);
  }
  println("Export scale: " + scale);
}

// Calculate scale to fit bounding box into paper format
// Returns scale factor to apply
// Convert margin enum to mm
float getMarginMM(int margin_enum)
{
  switch(margin_enum) {
    case MARGIN_0CM: return MARGIN_0CM_MM;
    case MARGIN_1CM: return MARGIN_1CM_MM;
    case MARGIN_2CM: return MARGIN_2CM_MM;
    case MARGIN_3CM: return MARGIN_3CM_MM;
    default: return MARGIN_3CM_MM;
  }
}

// Post-process a Processing-generated SVG to make it plotter-ready:
//  - Removes Batik DOCTYPE (SVG 1.0)
//  - Sets width/height in mm, viewBox in mm (1 unit = 1mm)
//  - Converts <g> transforms from px-space to mm-space (translate * K, scale * K)
//  - Adds explicit stroke:#000000 on <g> elements (AxiDraw requires it on direct parent)
//  - Sets version="1.1"
void postProcessSVGForPlotter(String filepath, int paper_format, boolean landscape) {
  if (paper_format == PAPER_NONE) return;

  float[] paper_dims = getPaperDimensions(paper_format, landscape);
  if (paper_dims == null) return;

  final float K    = 25.4 / 96.0; // SVG user px → mm
  final float w_mm = paper_dims[0];
  final float h_mm = paper_dims[1];

  String[] rawLines = loadStrings(sketchPath(filepath));
  if (rawLines == null) { println("SVG post-process: cannot load " + filepath); return; }
  String content = join(rawLines, "\n");

  // 1. Remove DOCTYPE
  content = content.replaceAll("(?s)<!DOCTYPE[^>]*>\\s*", "");

  // 2. Set mm dimensions + viewBox in mm + version 1.1
  content = content.replaceAll(
    "width=\"(\\d+)\" height=\"(\\d+)\"",
    "width=\"" + (int)w_mm + "mm\" height=\"" + (int)h_mm + "mm\"" +
    " viewBox=\"0 0 " + (int)w_mm + " " + (int)h_mm + "\" version=\"1.1\""
  );

  // 3. Convert <g> transforms from px-space to mm-space
  //    Processing always emits: translate(tx,ty) scale(sx,sy)
  java.util.regex.Pattern p0 = java.util.regex.Pattern.compile(
    "transform=\"translate\\(([\\d.]+),([\\d.]+)\\) scale\\(([\\d.]+),([\\d.]+)\\)\""
  );
  java.util.regex.Matcher m0 = p0.matcher(content);
  StringBuffer sb0 = new StringBuffer();
  while (m0.find()) {
    float tx = Float.parseFloat(m0.group(1)) * K;
    float ty = Float.parseFloat(m0.group(2)) * K;
    float sx = Float.parseFloat(m0.group(3)) * K;
    float sy = Float.parseFloat(m0.group(4)) * K;
    String nt = String.format(java.util.Locale.US,
      "transform=\"translate(%.4f,%.4f) scale(%.6f,%.6f)\"", tx, ty, sx, sy);
    m0.appendReplacement(sb0, java.util.regex.Matcher.quoteReplacement(nt));
  }
  m0.appendTail(sb0);
  content = sb0.toString();

  // 4. Add explicit stroke to <g> elements (AxiDraw needs stroke on direct parent, not inherited from <svg>)
  content = content.replace(
    "style=\"stroke-linecap:round; stroke-width:",
    "style=\"stroke:#000000; stroke-linecap:round; stroke-width:"
  );

  PrintWriter writer = createWriter(sketchPath(filepath));
  writer.print(content);
  writer.flush();
  writer.close();
  println("SVG fixed for plotter (mm viewBox + transforms): " + filepath);
}

float calculateExportScale(BoundingBox bbox, int paper_format, int margin)
{
  if (paper_format == PAPER_NONE || bbox == null) {
    return 1.0;
  }

  boolean landscape = bbox.getWidth() > bbox.getHeight();
  float[] paper_dims = getPaperDimensions(paper_format, landscape);
  if (paper_dims == null) {
    return 1.0;
  }

  float bbox_width = bbox.getWidth();
  float bbox_height = bbox.getHeight();

  // Usable paper area: subtract margins (in mm) then convert to SVG px
  float margin_mm = getMarginMM(margin);
  float usable_width = mmToSvgPx(paper_dims[0] - 2 * margin_mm);
  float usable_height = mmToSvgPx(paper_dims[1] - 2 * margin_mm);
  
  // Calculate scale to fit both dimensions
  float scale_x = (bbox_width > 0) ? usable_width / bbox_width : 1.0;
  float scale_y = (bbox_height > 0) ? usable_height / bbox_height : 1.0;
  
  // Use minimum scale to fit everything
  return min(scale_x, scale_y);
}

// ─── Direct SVG writer ────────────────────────────────────────────────────────
// Convert a point already in centered drawing space to mm page coordinates.
// s   = export_scale (drawing units → SVG px)
// K   = 25.4/96 (SVG px → mm)
float[] centeredToMM(float cx, float cy, float s, float K,
                     float page_cx_mm, float page_cy_mm) {
  return new float[]{ cx * s * K + page_cx_mm, cy * s * K + page_cy_mm };
}

// Write a PolylineGroup directly to an SVG file, bypassing Processing's SVG renderer.
// - Coordinates converted to mm using the same transform as start_draw()
// - Auto-centers the drawing using its bounding-box center
// - Clipping is applied when data.page.clipping is true
// - Progress is printed to the console every 10 %
void writeSVGDirect(String filepath, PolylineGroup polylines, int paper_format) {
  final boolean clipping = data.page.clipping;
  final float   clip_w   = data.page.clip_width;
  final float   clip_h   = data.page.clip_height;

  // Auto-center: map bbox center to page center (respect clipping when enabled)
  BoundingBox bbox = polylines.getBoundingBox(clipping, clip_w, clip_h);
  float bcx = (bbox.minX + bbox.maxX) / 2.0;
  float bcy = (bbox.minY + bbox.maxY) / 2.0;

  // Page orientation follows the drawing's aspect ratio (no content rotation).
  // Uses the same file_ui.export_landscape as export_scale (updateExportScale) so
  // orientation and scale always stay in sync — see xLib_FileUI.updateExportScale().
  boolean landscape = file_ui.export_landscape;

  float[] paper_dims      = getPaperDimensions(paper_format, landscape);
  final boolean has_paper = (paper_dims != null);
  final String  dim_u     = has_paper ? "mm" : "px";
  final float   K         = has_paper ? (25.4 / 96.0) : 1.0;
  final float   w_mm      = (paper_dims != null) ? paper_dims[0] : (float)width;
  final float   h_mm      = (paper_dims != null) ? paper_dims[1] : (float)height;
  final float   cx_mm     = w_mm / 2.0;
  final float   cy_mm     = h_mm / 2.0;
  final float s       = file_ui.export_scale;          // drawing units → SVG px
  // stroke-width in mm: lineWidth (drawing units) × scale (units→px) × K (px→mm)
  final float stroke_mm = data.style.lineWidth * s * K;

  int total = polylines.size();
  println("[SVG direct] " + total + " polylines  |  " + (int)w_mm + "x" + (int)h_mm + " " + dim_u +
          "  |  scale=" + String.format(java.util.Locale.US, "%.4f", s) +
          "  |  stroke=" + String.format(java.util.Locale.US, "%.4f", stroke_mm) + " " + dim_u);

  // Ensure Export directory exists
  new java.io.File(sketchPath("Export")).mkdirs();

  PrintWriter out = createWriter(filepath);

  // SVG header
  out.println("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>");
  out.println("<svg");
  out.println("  xmlns=\"http://www.w3.org/2000/svg\"");
  out.println("  version=\"1.1\"");
  out.println("  width=\""  + (int)w_mm + "mm\"");
  out.println("  height=\"" + (int)h_mm + "mm\"");
  out.println("  viewBox=\"0 0 " + (int)w_mm + " " + (int)h_mm + "\">");
  out.println("<g stroke=\"#000000\" fill=\"none\"");
  out.println("   stroke-width=\"" + String.format(java.util.Locale.US, "%.4f", stroke_mm) + "\"");
  out.println("   stroke-linecap=\"round\" stroke-linejoin=\"round\">");

  float[] clipOut = new float[4];
  int done = 0, written = 0, last_pct = -1;

  for (Polyline pl : polylines.polylines) {
    if (pl.size() < 2) { done++; continue; }

    if (!clipping) {
      // Continuous path – one pen-down stroke per polyline
      out.print("<path d=\"");
      boolean first = true;
      for (PVector p : pl.points) {
        float[] mm = centeredToMM(p.x - bcx, p.y - bcy, s, K, cx_mm, cy_mm);
        if (first) {
          out.print(String.format(java.util.Locale.US, "M %.4f,%.4f", mm[0], mm[1]));
          first = false;
        } else {
          out.print(String.format(java.util.Locale.US, " L %.4f,%.4f", mm[0], mm[1]));
        }
      }
      out.println("\" />");
      written++;
    } else {
      // Clipped path – each visible segment is an independent M-L pair
      StringBuilder sb = new StringBuilder();
      int segs = 0;
      for (int i = 0; i < pl.size() - 1; i++) {
        PVector a = pl.get(i), b = pl.get(i + 1);
        // Clip in original drawing space (centered on 0,0), then apply export centering.
        if (clipLineToCenteredRect(a.x, a.y, b.x, b.y, 0, 0, clip_w, clip_h, clipOut)) {
          float[] p0 = centeredToMM(clipOut[0] - bcx, clipOut[1] - bcy, s, K, cx_mm, cy_mm);
          float[] p1 = centeredToMM(clipOut[2] - bcx, clipOut[3] - bcy, s, K, cx_mm, cy_mm);
          sb.append(String.format(java.util.Locale.US,
            "M %.4f,%.4f L %.4f,%.4f ", p0[0], p0[1], p1[0], p1[1]));
          segs++;
        }
      }
      if (segs > 0) {
        out.println("<path d=\"" + sb.toString().trim() + "\" />");
        written++;
      }
    }

    done++;
    int pct = (total > 0) ? (100 * done / total) : 100;
    if (pct != last_pct && pct % 10 == 0) { println("[SVG direct]   " + done + " / " + total + " (" + pct + "%)"); last_pct = pct; }
  }

  out.println("</g>");
  out.println("</svg>");
  out.flush();
  out.close();

  println("[SVG direct] Done - " + written + " elements written.");
}

// Write a ShapesGroup (polylines + dots) directly to an SVG file.
// Dots are rendered as zero-length lines with round linecap — same stroke-width as polylines.
// This is the AxiDraw convention: a capped zero-length stroke = filled dot of diameter=stroke-width.
void writeSVGDirect(String filepath, ShapesGroup shapes, int paper_format) {
  final boolean clipping = data.page.clipping;
  final float   clip_w   = data.page.clip_width;
  final float   clip_h   = data.page.clip_height;

  BoundingBox bbox = shapes.getBoundingBox(clipping, clip_w, clip_h);
  float bcx = (bbox.minX + bbox.maxX) / 2.0;
  float bcy = (bbox.minY + bbox.maxY) / 2.0;

  // Page orientation follows the drawing's aspect ratio (no content rotation).
  // Uses the same file_ui.export_landscape as export_scale (updateExportScale) so
  // orientation and scale always stay in sync — see xLib_FileUI.updateExportScale().
  boolean landscape = file_ui.export_landscape;

  float[] paper_dims      = getPaperDimensions(paper_format, landscape);
  final boolean has_paper = (paper_dims != null);
  final String  dim_u     = has_paper ? "mm" : "px";
  final float   K         = has_paper ? (25.4 / 96.0) : 1.0;
  final float   w_mm      = (paper_dims != null) ? paper_dims[0] : (float)width;
  final float   h_mm      = (paper_dims != null) ? paper_dims[1] : (float)height;
  final float   cx_mm     = w_mm / 2.0;
  final float   cy_mm     = h_mm / 2.0;
  final float s         = file_ui.export_scale;
  final float stroke_mm = data.style.lineWidth * s * K;

  int total = shapes.totalCount();
  println("[SVG direct] " + shapes.polylineCount() + " polylines, " + shapes.dotCount() + " dots  |  " +
          (int)w_mm + "x" + (int)h_mm + " " + dim_u +
          "  |  scale=" + String.format(java.util.Locale.US, "%.4f", s) +
          "  |  stroke=" + String.format(java.util.Locale.US, "%.4f", stroke_mm) + " " + dim_u);

  new java.io.File(sketchPath("Export")).mkdirs();
  PrintWriter out = createWriter(filepath);

  out.println("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>");
  out.println("<svg");
  out.println("  xmlns=\"http://www.w3.org/2000/svg\"");
  out.println("  version=\"1.1\"");
  out.println("  width=\""  + (int)w_mm + dim_u + "\"");
  out.println("  height=\"" + (int)h_mm + dim_u + "\"");
  out.println("  viewBox=\"0 0 " + (int)w_mm + " " + (int)h_mm + "\">");
  out.println("<g stroke=\"#000000\" fill=\"none\"");
  out.println("   stroke-width=\"" + String.format(java.util.Locale.US, "%.4f", stroke_mm) + "\"");
  out.println("   stroke-linecap=\"round\" stroke-linejoin=\"round\">");

  float[] clipOut = new float[4];
  int done = 0, written = 0, last_pct = -1;

  // ── Polylines ──────────────────────────────────────────────────────────────
  for (Polyline pl : shapes.polylines) {
    if (pl.size() < 2) { done++; continue; }

    if (!clipping) {
      out.print("<path d=\"");
      boolean first = true;
      for (PVector p : pl.points) {
        float[] mm = centeredToMM(p.x - bcx, p.y - bcy, s, K, cx_mm, cy_mm);
        if (first) { out.print(String.format(java.util.Locale.US, "M %.4f,%.4f", mm[0], mm[1])); first = false; }
        else        { out.print(String.format(java.util.Locale.US, " L %.4f,%.4f", mm[0], mm[1])); }
      }
      out.println("\" />");
      written++;
    } else {
      StringBuilder sb = new StringBuilder();
      int segs = 0;
      for (int i = 0; i < pl.size() - 1; i++) {
        PVector a = pl.get(i), b = pl.get(i + 1);
        // Clip in original drawing space (centered on 0,0), then apply export centering.
        if (clipLineToCenteredRect(a.x, a.y, b.x, b.y, 0, 0, clip_w, clip_h, clipOut)) {
          float[] p0 = centeredToMM(clipOut[0] - bcx, clipOut[1] - bcy, s, K, cx_mm, cy_mm);
          float[] p1 = centeredToMM(clipOut[2] - bcx, clipOut[3] - bcy, s, K, cx_mm, cy_mm);
          sb.append(String.format(java.util.Locale.US,
            "M %.4f,%.4f L %.4f,%.4f ", p0[0], p0[1], p1[0], p1[1]));
          segs++;
        }
      }
      if (segs > 0) { out.println("<path d=\"" + sb.toString().trim() + "\" />"); written++; }
    }

    done++;
    int pct = (total > 0) ? (100 * done / total) : 100;
    if (pct != last_pct && pct % 10 == 0) { println("[SVG direct]   " + done + " / " + total + " (" + pct + "%)"); last_pct = pct; }
  }

  // ── Dots: zero-length line with round linecap = filled dot (AxiDraw convention) ──
  for (Dot d : shapes.dots) {
    float px = d.pos.x, py = d.pos.y;
    if (clipping && !pointInClipRect(px, py, 0, 0, clip_w, clip_h)) continue;
    px -= bcx;
    py -= bcy;
    float[] mm = centeredToMM(px, py, s, K, cx_mm, cy_mm);
    out.println(String.format(java.util.Locale.US,
      "<line x1=\"%.4f\" y1=\"%.4f\" x2=\"%.4f\" y2=\"%.4f\" />",
      mm[0], mm[1], mm[0] + 0.0001f, mm[1] + 0.0001f));
    written++;
    done++;
    int pct = (total > 0) ? (100 * done / total) : 100;
    if (pct != last_pct && pct % 10 == 0) { println("[SVG direct]   " + done + " / " + total + " (" + pct + "%)"); last_pct = pct; }
  }

  out.println("</g>");
  out.println("</svg>");
  out.flush();
  out.close();
  println("[SVG direct] Done - " + written + " elements written.");
}
