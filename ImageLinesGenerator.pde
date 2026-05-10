class ImageLine extends Polyline
{
  int group_id = 0;  // Track which original line this segment belongs to
}

abstract class ImageLinesGenerator {

  ArrayList<ImageLine> lines =  new ArrayList<ImageLine>();

  DataLines data_lines;
  int current_group_id = 0;  // Track group assignment for threshold

  public ImageLinesGenerator(DataLines data_lines) {
    this.data_lines = data_lines;
  }

  ImageLine current_line = null;

  void addPoint(PVector point)
  {
    if (current_line == null)
    {
      current_line = new ImageLine();
      current_line.group_id = current_group_id;
    }

    current_line.points.add(point);
  }

  void closeLine()
  {
    if (current_line != null)
    {
      lines.add(current_line);
      current_line = null;
      current_group_id++;  // Next line gets next group ID
    }
  }

  boolean isPointInClipRect(float x, float y)
  {
    return pointInClipRect(x, y, 0, 0, data.page.clip_width, data.page.clip_height);
  }

  ImageLine addSegmentToLine(ImageLine line, float xFrom, float yFrom, float xTo, float yTo)
  {
    // Simple point addition - clipping is handled separately
    line.addPoint(new PVector(xFrom, yFrom));
    line.addPoint(new PVector(xTo, yTo));
    return line;
  }

  // Apply clipping to lines as a separate post-processing step
  // Preserves group_id for all clipped segments
  ArrayList<ImageLine> clipLines() {
    ArrayList<ImageLine> clipped_lines = new ArrayList<ImageLine>();
    
    if (!data.page.clipping) {
      return lines;  // No clipping, return as is
    }
    
    for (ImageLine source_line : lines) {
      ArrayList<ImageLine> segments = clipLine(source_line);
      clipped_lines.addAll(segments);
    }
    
    return clipped_lines;
  }

  ArrayList<ImageLine> clipLine(ImageLine source_line) {
    ArrayList<ImageLine> result = new ArrayList<ImageLine>();
    ImageLine current_segment = null;
    
    for (int i = 0; i < source_line.points.size() - 1; i++) {
      PVector p1 = source_line.points.get(i);
      PVector p2 = source_line.points.get(i + 1);
      
      boolean p1Inside = isPointInClipRect(p1.x, p1.y);
      boolean p2Inside = isPointInClipRect(p2.x, p2.y);
      
      float[] clipped = new float[4];
      boolean hasClipped = clipLineToCenteredRect(p1.x, p1.y, p2.x, p2.y, 
                                                   0, 0, 
                                                   data.page.clip_width, data.page.clip_height, clipped);
      
      if (p1Inside && p2Inside) {
        // Both inside: accumulate in current segment
        if (current_segment == null) {
          current_segment = new ImageLine();
          current_segment.group_id = source_line.group_id;
          current_segment.addPoint(p1);
        }
        current_segment.addPoint(p2);
      }
      else if (p1Inside && !p2Inside) {
        // Inside → Outside: close current segment at clip boundary
        if (current_segment == null) {
          current_segment = new ImageLine();
          current_segment.group_id = source_line.group_id;
          current_segment.addPoint(p1);
        } else {
          current_segment.addPoint(p1);
        }
        if (hasClipped) {
          current_segment.addPoint(new PVector(clipped[2], clipped[3]));
        }
        if (current_segment.points.size() >= 2) {
          result.add(current_segment);
        }
        current_segment = null;
      }
      else if (!p1Inside && p2Inside) {
        // Outside → Inside: start new segment at clip boundary
        if (hasClipped) {
          if (current_segment == null) {
            current_segment = new ImageLine();
            current_segment.group_id = source_line.group_id;
          }
          current_segment.addPoint(new PVector(clipped[0], clipped[1]));
          current_segment.addPoint(p2);
        }
      }
      else {
        // Both outside: check if segment traverses clip rect
        if (hasClipped) {
          // Segment traverses → create separate segment
          ImageLine traverse_segment = new ImageLine();
          traverse_segment.group_id = source_line.group_id;
          traverse_segment.addPoint(new PVector(clipped[0], clipped[1]));
          traverse_segment.addPoint(new PVector(clipped[2], clipped[3]));
          result.add(traverse_segment);
        }
      }
    }
    
    // Add any remaining open segment
    if (current_segment != null && current_segment.points.size() >= 2) {
      result.add(current_segment);
    }
    
    return result;
  }

  void draw() {
    for (int i = 0; i < lines.size(); i++)
    {
      ImageLine line = lines.get(i);
      line.draw();
    }
  }
}

class MultiLinesGenerator extends ImageLinesGenerator
{
  public MultiLinesGenerator(DataLines data_lines) {

    super(data_lines);
  }

  StraightLines straight;
  CircleLines circle;
  SinusLines sinus;

  void buildLines() {

    if (data_lines.precision < 0.5)
      data_lines.precision = 0.5;

    current_group_id = 0;  // Reset group counter for new build
    //println("MoultiLinesGenerator buildLines");

    switch(data_lines.type)
    {
    default:
    case 0:
      straight.buildLines(this);
      break;
    case 1:
      circle.buildLines(this);
      break;
    case 2:
      sinus.buildLines(this);
      break;
    }
  }
}
