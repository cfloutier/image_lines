
class DataThreshold extends GenericData
{
  DataThreshold() {
    super("Threshold");
  }

  boolean draw = true;
  boolean black = true;
  boolean mirror = false;

  int nb_values = 1;

  boolean use_power;
  float power;
  float min_value = 0;
  float max_value = 255;

  float threshold_1 = 125;
  float threshold_2 = 125;
  float threshold_3 = 125;
  float threshold_4 = 125;
  float threshold_5 = 125;
  float threshold_6 = 125;
  float threshold_7 = 125;
  float threshold_8 = 125;
  float threshold_9 = 125;
  float threshold_10 = 125;
  float threshold_11 = 125;
  float threshold_12 = 125;

  float lerp(float v0, float v1, float t) {
    return (1 - t) * v0 + t * v1;
  }

  float get_threshold_by_index(int index)
  {
    if (use_power)
    {
      float ratio = 0.5;
      if (nb_values > 1)
        ratio = ((float)index) / (nb_values-1);

      float factor =  1;
      if (power >= 0)
      {
        factor = 1 + power;
      } else
      {
        factor = 1 / (1 - power);
      }

      float value =  pow(ratio, factor);

      return lerp(min_value, max_value, value);
    } else
    {
      switch (index)
      {
      case 0:
        return threshold_1;
      case 1:
        return threshold_2;
      case 2:
        return threshold_3;
      case 3:
        return threshold_4;
      case 4:
        return threshold_5;
      case 5:
        return threshold_6;
      case 6:
        return threshold_7;
      case 7:
        return threshold_8;
      case 8:
        return threshold_9;
      case 9:
        return threshold_10;
      case 10:
        return threshold_11;
      case 11:
        return threshold_12;
      default:
        return 0;
      }
    }
  }


  public void LoadJson(JSONObject json) {
    super.LoadJson(json);
  }
}

class ThresholdGUI extends GUIPanel
{
  DataThreshold data;

  public ThresholdGUI(DataThreshold data)
  {
    super("Seuils", data);
    this.data = data;
  }

  Toggle draw;
  Toggle black;
  Toggle mirror;
  Toggle use_power;


  Slider nb_values;

  Slider threshold_1;
  Slider threshold_2;
  Slider threshold_3;
  Slider threshold_4;
  Slider threshold_5;
  Slider threshold_6;
  Slider threshold_7;
  Slider threshold_8;
  Slider threshold_9;
  Slider threshold_10;
  Slider threshold_11;
  Slider threshold_12;

  Slider canvas_height;

  Slider direction;
  Slider step_size;

  Slider power;
  Slider min_value;
  Slider max_value;


  void setupControls()
  {
    super.Init();

    draw = addToggle("draw", "Draw");

    nextLine();

    black = addToggle("black", "Black Lines");
    mirror = addToggle("mirror", "Mirror order");

    nextLine();

    use_power = addToggle("use_power", "Power Curve");

    nb_values = addIntSlider("nb_values", "Nb values used", 1, 12);
    nextLine();
    nextLine();

    float savedPos = yPos;

    threshold_1 = addSlider("threshold_1", "Threshold 1", 0, 255);
    nextLine();
    threshold_2 = addSlider("threshold_2", "Threshold 2", 0, 255);
    nextLine();
    threshold_3 = addSlider("threshold_3", "Threshold 3", 0, 255);
    nextLine();
    threshold_4 = addSlider("threshold_4", "Threshold 4", 0, 255);
    nextLine();
    threshold_5 = addSlider("threshold_5", "Threshold 5", 0, 255);
    nextLine();
    threshold_6 = addSlider("threshold_6", "Threshold 6", 0, 255);
    nextLine();
    threshold_7 = addSlider("threshold_7", "Threshold 7", 0, 255);
    nextLine();
    threshold_8 = addSlider("threshold_8", "Threshold 8", 0, 255);
    nextLine();
    threshold_9 = addSlider("threshold_9", "Threshold 9", 0, 255);
    nextLine();
    threshold_10 = addSlider("threshold_10", "Threshold 10", 0, 255);
    nextLine();
    threshold_11 = addSlider("threshold_11", "Threshold 11", 0, 255);
    nextLine();
    threshold_12 = addSlider("threshold_12", "Threshold 12", 0, 255);
    nextLine();

    yPos = savedPos;

    power = addSlider("power", "Power", -10, 10);
    nextLine();
    min_value = addSlider("min_value", "Min", 0, 255);
    max_value = addSlider("max_value", "Max", 0, 255);
    nextLine();
  }

  void update_ui()
  {
    if (data.use_power)
    {
      threshold_1.hide();
      threshold_2.hide();
      threshold_3.hide();
      threshold_4.hide();
      threshold_5.hide();
      threshold_6.hide();
      threshold_7.hide();
      threshold_8.hide();
      threshold_9.hide();
      threshold_10.hide();
      threshold_11.hide();
      threshold_12.hide();

      power.show();
      min_value.show();
      max_value.show();

      threshold_1.setValue(data.get_threshold_by_index(0));
      threshold_2.setValue(data.get_threshold_by_index(1));
      threshold_3.setValue(data.get_threshold_by_index(2));
      threshold_4.setValue(data.get_threshold_by_index(3));
      threshold_5.setValue(data.get_threshold_by_index(4));
      threshold_6.setValue(data.get_threshold_by_index(5));
      threshold_7.setValue(data.get_threshold_by_index(6));
      threshold_8.setValue(data.get_threshold_by_index(7));
      threshold_9.setValue(data.get_threshold_by_index(8));
      threshold_10.setValue(data.get_threshold_by_index(9));
      threshold_11.setValue(data.get_threshold_by_index(10));
      threshold_12.setValue(data.get_threshold_by_index(11));
    } else
    {
      if (data.nb_values >= 1)  threshold_1.show();
      else threshold_1.hide();
      if (data.nb_values >= 2)  threshold_2.show();
      else threshold_2.hide();
      if (data.nb_values >= 3)  threshold_3.show();
      else threshold_3.hide();
      if (data.nb_values >= 4)  threshold_4.show();
      else threshold_4.hide();
      if (data.nb_values >= 5)  threshold_5.show();
      else threshold_5.hide();
      if (data.nb_values >= 6)  threshold_6.show();
      else threshold_6.hide();
      if (data.nb_values >= 7)  threshold_7.show();
      else threshold_7.hide();
      if (data.nb_values >= 8)  threshold_8.show();
      else threshold_8.hide();
      if (data.nb_values >= 9)  threshold_9.show();
      else threshold_9.hide();
      if (data.nb_values >= 10) threshold_10.show();
      else threshold_10.hide();
      if (data.nb_values >= 11) threshold_11.show();
      else threshold_11.hide();
      if (data.nb_values >= 12) threshold_12.show();
      else threshold_12.hide();

      power.hide();
      min_value.hide();
      max_value.hide();
    }
  }

  void setGUIValues()
  {
    draw.setValue(data.draw);
    black.setValue(data.black);
    nb_values.setValue(data.nb_values);

    threshold_1.setValue(data.threshold_1);
    threshold_2.setValue(data.threshold_2);
    threshold_3.setValue(data.threshold_3);
    threshold_4.setValue(data.threshold_4);
    threshold_5.setValue(data.threshold_5);
    threshold_6.setValue(data.threshold_6);
    threshold_7.setValue(data.threshold_7);
    threshold_8.setValue(data.threshold_8);
    threshold_9.setValue(data.threshold_9);
    threshold_10.setValue(data.threshold_10);
    threshold_11.setValue(data.threshold_11);
    threshold_12.setValue(data.threshold_12);

    power.setValue(data.power);
    min_value.setValue(data.min_value);
    max_value.setValue(data.max_value);

    use_power.setValue(data.use_power);
  }
}

class ThresholdFilter extends ImageLinesGenerator
{
  public ThresholdFilter(DataLines data_lines, DataThreshold data_threshold) {

    super(data_lines);
    this.data_threshold = data_threshold;
  }

  DataThreshold data_threshold;

  void buildLines(ImageLinesGenerator source_generator, DataImage image)
  {
    buildLines(source_generator.group, image);
  }

  void buildLines(PolylineGroup source_group, DataImage image)
  {
    //println("ThresholdFilter. buildLines");

    group.clear();

    int direction_index = 1;
    int threshold_index = 0;
    int current_group_id = -1;
    float threshold = 0;

    for (int i_line = 0; i_line < source_group.size(); i_line++)
    {
      ImageLine source_line = (ImageLine) source_group.polylines.get(i_line);

      // Only update threshold when we change to a new group
      if (source_line.group_id != current_group_id)
      {
        current_group_id = source_line.group_id;
        threshold = data_threshold.get_threshold_by_index(threshold_index);
        //print("-" + threshold_index);

        threshold_index += direction_index;
        if (data_threshold.mirror)
        {
          if (threshold_index >= data_threshold.nb_values || threshold_index < 0)
          {
            direction_index = -direction_index;
            threshold_index += direction_index*2;
          }
        } else
        {
          if (threshold_index >= data_threshold.nb_values)
            threshold_index = 0;
        }
      }

      for (int i_point = 0; i_point < source_line.points.size(); i_point++ )
      {
        PVector point = source_line.points.get(i_point);
        float value = image.getPixelValue(point);
        if (value == -1)
          closeLine();

        else if (data_threshold.black)
        {
          if (value < threshold)
          {
            addPoint(point);
          } else
          {
            closeLine();
          }
        } else
        {
          if (value > threshold)
          {
            addPoint(point);
          } else
          {
            closeLine();
          }
        }
      }

      closeLine();
    }
  }
}
