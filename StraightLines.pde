
class StraightLinesData extends GenericData
{
  StraightLinesData() {
    super("StraightLines");
  }

  float direction = 0;
  float size = 500;
}


class StraightLines extends LineMode
{
  DataLines data_lines;
  StraightLinesData line_data;

  StraightLines(DataLines data_lines, StraightLinesData data) {
    super(data);
    this.data_lines = data_lines;
    line_data = data;
  }

  Slider direction_slider;

  void buildUI(GUIPanel panel)
  {
    direction_slider = panel.addSlider("direction", "Direction", line_data, -90, 90);
    add(direction_slider);

    Button horizontal = panel.addButton("---");
    Button slash = panel.addButton("///");

    Button vertical = panel.addButton("|||");
    Button antislash = panel.addButton("\\\\\\");

    add(horizontal);
    add(slash);
    add(vertical);
    add(antislash);

    horizontal.onRelease(new CallbackListener() { // ajouter le Callback Listener au bouton
      public void controlEvent(CallbackEvent theEvent) {
        line_data.direction = 0;
        direction_slider.setValue(line_data.direction);
      }
    }
    );

    slash.onRelease(new CallbackListener() { // ajouter le Callback Listener au bouton
      public void controlEvent(CallbackEvent theEvent) {
        line_data.direction = -45;
        direction_slider.setValue(line_data.direction);
      }
    }
    );

    vertical.onRelease(new CallbackListener() { // ajouter le Callback Listener au bouton
      public void controlEvent(CallbackEvent theEvent) {
        line_data.direction = 90;
        direction_slider.setValue(line_data.direction);
      }
    }
    );

    antislash.onRelease(new CallbackListener() { // ajouter le Callback Listener au bouton
      public void controlEvent(CallbackEvent theEvent) {
        line_data.direction = 45;
        direction_slider.setValue(line_data.direction);
      }
    }
    );


    // add(panel.addSlider("direction", "Direction", line_data, -90, 90));
    panel.nextLine();
    add(panel.addSlider("size", "Size", line_data, 10, 2000));
  }

  void buildLines(ImageLinesGenerator generator)
  {
    generator.group.clear();

    float cos_x = cos(radians(line_data.direction));
    float sin_x = sin(radians(line_data.direction));

    PVector forward = new PVector(cos_x, sin_x);
    PVector right = new PVector(-sin_x, cos_x);

    float radius = line_data.size;
    float spacing = data_lines.lines_spacing;

    data_lines.setNbLines( int(2*radius / spacing));

    float advance = -radius;

    while (advance <= radius)
    {
      PVector center_line = new PVector(advance * right.x, advance * right.y );
      PVector start_pos = new PVector(center_line.x-forward.x*radius, center_line.y-forward.y*radius);

      float advance_forward = 0;

      ImageLine line = new ImageLine();
      line.group_id = generator.current_group_id;  // Assign group ID
      PVector pA = start_pos;
      line.addPoint(pA);
      
      advance_forward += data_lines.precision;
      while (advance_forward <= radius*2)
      {
        PVector pA_new = new PVector(start_pos.x + forward.x * advance_forward, start_pos.y + forward.y * advance_forward);
        line.addPoint(pA_new);
        pA = pA_new;
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
