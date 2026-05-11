class ImageLine extends Polyline
{
  int group_id = 0;  // Track which original line this segment belongs to
}

abstract class ImageLinesGenerator {

  PolylineGroup group = new PolylineGroup();

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
      group.add(current_line);
      current_line = null;
      current_group_id++;  // Next line gets next group ID
    }
  }

  void draw() {
    group.draw(data.page.clipping, data.page.clip_width, data.page.clip_height);
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
