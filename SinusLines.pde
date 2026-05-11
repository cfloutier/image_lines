
class SinusLinesData extends GenericData
{
  SinusLinesData() {
    super("SinusLines");
  }

  float size = 500;
  float high = 20;
  float period = 100;
  float direction_sinus = 0;
}

class SinusLines extends LineMode
{
  DataLines data_lines;
  SinusLinesData sinus_line;

  SinusLines(DataLines data_lines, SinusLinesData data) {
    super(data);
    this.data_lines = data_lines;
    this.sinus_line = data;
  }

  void buildUI(GUIPanel panel)
  {
    add(panel.addSlider("size", "Size", sinus_line, 10, 2000));
    add(panel.addSlider("high", "Amplitude", sinus_line, 0, 100));
    panel.nextLine();
    add(panel.addSlider("period", "Period", sinus_line, 1, 400));
    panel.nextLine();
    add(panel.addSlider("direction_sinus", "Direction", sinus_line, -90, 90));
  }

  void buildLines(ImageLinesGenerator generator)
  {
    this.generator = generator;

    generator.group.clear();

    float radius = sinus_line.size;
    float spacing = data_lines.lines_spacing;

    data_lines.setNbLines( int(2*radius / spacing));

    // compute orientation vectors from direction
    float cos_x = cos(radians(sinus_line.direction_sinus));
    float sin_x = sin(radians(sinus_line.direction_sinus));

    PVector forward = new PVector(cos_x, sin_x);
    PVector right = new PVector(-sin_x, cos_x);

    float advance = -radius;

    while (advance <= radius)
    {
      ImageLine line = new ImageLine();
      line.group_id = generator.current_group_id;  // Assign group ID
      float advance_forward = -radius;
      
      float x_local_prev = advance_forward;
      float y_local_prev = sinus_line.high * sin(TWO_PI * x_local_prev / sinus_line.period) + advance;
      PVector pA_prev = new PVector(
        forward.x * x_local_prev + right.x * y_local_prev,
        forward.y * x_local_prev + right.y * y_local_prev);
      line.addPoint(pA_prev);
      
      advance_forward += data_lines.precision;
      while (advance_forward <= radius)
      {
        float x_local = advance_forward;
        float y_local = sinus_line.high * sin(TWO_PI * x_local / sinus_line.period) + advance;
        PVector pA = new PVector(
          forward.x * x_local + right.x * y_local,
          forward.y * x_local + right.y * y_local);
        line.addPoint(pA);
        pA_prev = pA;
        advance_forward += data_lines.precision;
      }

      advance += spacing;

      if (line.points.size() >= 2)
      {
        generator.group.add(line);
        generator.current_group_id++;  // Next line gets next group ID
      }
    }
  }
}
