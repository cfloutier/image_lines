class CircleLinesData extends GenericData
{
  CircleLinesData() {
    super("CircleLines");
  }

  float min_radius = 0;
  float max_radius = 1000;

  float center_x = 0;
  float center_y = 0;

  float ellipse = 0;
}

class CircleLines extends LineMode
{
  DataLines data_lines;
  CircleLinesData circle_data;

  CircleLines(DataLines data_lines, CircleLinesData data) {
    super(data);
    this.data_lines = data_lines;
    this.circle_data = data;
  }

  // kept only for use in helper methods
  Slider center_x;
  Slider center_y;
  Slider ellipse;

  void buildUI(GUIPanel panel)
  {
    // Circle Line

    add(panel.addSlider("min_radius", "Min Radius", circle_data, 0, 3000));
    add(panel.addSlider("max_radius", "Max radius", circle_data, 0, 3000));
    panel.nextLine();
    panel.space();

    center_x = panel.addSlider("center_x", "Center X", circle_data, -2000, 2000);
    add(center_x);
    center_y  = panel.addSlider("center_y", "Center Y", circle_data, -2000, 2000);
    add(center_y);

    Button center_bt = panel.addButton("Center");
    add(center_bt);
    center_bt.onRelease(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        circle_data.center_x = 0;
        circle_data.center_y = 0;

        println("center");

        center_x.setValue(circle_data.center_x);
        center_y.setValue(circle_data.center_y);
      }
    }
    );


    panel.nextLine();

    ellipse = panel.addSlider("ellipse", "Ellipse", circle_data, -3, 3);
    add(ellipse);


    Button circle_bt = panel.addButton("Circle");
    circle_bt.onRelease(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        circle_data.ellipse =0;
        ellipse.setValue(0);
      }
    }
    );

    add(circle_bt);
  }



  PVector _circle_point(float radius_x, float radius_y, float angle)
  {
    return new PVector(
      data_lines.circle_line.center_x +  radius_x * cos(angle),
      data_lines.circle_line.center_y + radius_y * sin(angle));
  }


  void _addCircle(float radius_x, float radius_y)
  {
    float mean_radius = (radius_x + radius_y)/2;

    float len = 2 * PI * mean_radius;
    int nb_parts = ceil(len / data_lines.precision);
    float delta_angle = 2*PI / nb_parts;

    float angle = 0;
    PVector start_pos = _circle_point(radius_x, radius_y, angle);

    if (generator.current_line == null)
    {
      generator.current_line = new ImageLine();
      generator.current_line.group_id = generator.current_group_id;  // Assign group ID
    }
    
    generator.current_line.addPoint(start_pos);

    angle += delta_angle;
    while (angle < 2*PI)
    {
      PVector pos = _circle_point(radius_x, radius_y, angle);
      generator.current_line.addPoint(pos);
      angle += delta_angle;
    }

    // Fermer le cercle en retournant au point de départ
    generator.current_line.addPoint(start_pos);

    if (generator.current_line != null && generator.current_line.points.size() >= 2)
      generator.group.add(generator.current_line);
    
    generator.current_line = null;
  }

  void buildLines(ImageLinesGenerator generator )
  {
    generator.group.clear();
    this.generator = generator;

    float delta_radius = circle_data.max_radius - circle_data.min_radius;

    data_lines.setNbLines(int(delta_radius / data_lines.lines_spacing));

    float radius = circle_data.min_radius;

    float strech = 1;
    if (circle_data.ellipse >= 0)
      strech = 1 + circle_data.ellipse;
    else
      strech = 1 / (1 - circle_data.ellipse);

    while (radius < circle_data.max_radius)
    {
      float radius_x = radius*strech;
      float radius_y = radius/strech;

      _addCircle(radius_x, radius_y);
      generator.current_group_id++;  // Next circle gets next group ID
      radius += data_lines.lines_spacing;
    }
  }
}

