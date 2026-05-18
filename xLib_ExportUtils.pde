// Paper format constants
final int PAPER_NONE = 0;
final int PAPER_A4 = 1;
final int PAPER_A3 = 2;
final int PAPER_A2 = 3;

// DPI for export - adjust this value to match your actual paper dimensions
// Start with 96.0 (screen DPI) and adjust based on export results
final float EXPORT_DPI = 135.0;

// Margin constants (in mm)
final int MARGIN_0CM = 0;
final int MARGIN_1CM = 1;
final int MARGIN_3CM = 2;
final int MARGIN_10CM = 3;

final float MARGIN_0CM_MM = 0;
final float MARGIN_1CM_MM = 10;
final float MARGIN_3CM_MM = 30;
final float MARGIN_10CM_MM = 100;

// Paper dimensions in mm
final float A4_WIDTH_MM = 210;
final float A4_HEIGHT_MM = 297;
final float A3_WIDTH_MM = 297;
final float A3_HEIGHT_MM = 420;
final float A2_WIDTH_MM = 420;
final float A2_HEIGHT_MM = 594;

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
}

// Get paper dimensions in pixels based on format and DPI
// Returns [width, height] in pixels
float[] getPaperDimensions(int format_enum)
{
  float[] dims = new float[2];
  
  switch(format_enum) {
    case PAPER_A4:
      dims[0] = A4_WIDTH_MM / 25.4 * EXPORT_DPI;   // Convert mm to pixels
      dims[1] = A4_HEIGHT_MM / 25.4 * EXPORT_DPI;
      break;
    case PAPER_A3:
      dims[0] = A3_WIDTH_MM / 25.4 * EXPORT_DPI;
      dims[1] = A3_HEIGHT_MM / 25.4 * EXPORT_DPI;
      break;
    case PAPER_A2:
      dims[0] = A2_WIDTH_MM / 25.4 * EXPORT_DPI;
      dims[1] = A2_HEIGHT_MM / 25.4 * EXPORT_DPI;
      break;
    default:  // PAPER_NONE or invalid
      return null;
  }
  
  return dims;
}

// Print export debug info (bounding box + scale)
// Call this only once per export frame
void printExportDebugInfo(BoundingBox bbox, float scale, int paper_format)
{
  String format_name = "UNKNOWN";
  switch(paper_format) {
    case PAPER_NONE: format_name = "None"; break;
    case PAPER_A4: format_name = "A4"; break;
    case PAPER_A3: format_name = "A3"; break;
    case PAPER_A2: format_name = "A2"; break;
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
    case MARGIN_3CM: return MARGIN_3CM_MM;
    case MARGIN_10CM: return MARGIN_10CM_MM;
    default: return MARGIN_3CM_MM;
  }
}

// Determine if drawing should be rotated for portrait export
// Rotate if drawing is landscape (wider than tall)
boolean shouldRotateForExport(BoundingBox bbox)
{
  return bbox != null && bbox.getWidth() > bbox.getHeight();
}

float calculateExportScale(BoundingBox bbox, int paper_format, int margin, boolean shouldRotate)
{
  if (paper_format == PAPER_NONE || bbox == null) {
    return 1.0;
  }
  
  float[] paper_dims = getPaperDimensions(paper_format);
  if (paper_dims == null) {
    return 1.0;
  }
  
  float bbox_width = bbox.getWidth();
  float bbox_height = bbox.getHeight();
  
  // If rotating -90°, dimensions are swapped visually
  if (shouldRotate) {
    float temp = bbox_width;
    bbox_width = bbox_height;
    bbox_height = temp;
  }
  
  // Get margin in mm and convert to pixels
  float margin_mm = getMarginMM(margin);
  float margin_px = margin_mm / 25.4 * EXPORT_DPI;  // Convert mm to pixels
  
  float usable_width = paper_dims[0] - 2 * margin_px;
  float usable_height = paper_dims[1] - 2 * margin_px;
  
  // Calculate scale to fit both dimensions
  float scale_x = (bbox_width > 0) ? usable_width / bbox_width : 1.0;
  float scale_y = (bbox_height > 0) ? usable_height / bbox_height : 1.0;
  
  // Use minimum scale to fit everything
  return min(scale_x, scale_y);
}
