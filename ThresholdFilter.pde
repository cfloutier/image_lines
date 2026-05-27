
class DataThreshold extends GenericData
{
  DataThreshold() {
    super("Threshold");
  }

  boolean draw = true;
  boolean black = true;
  boolean mirror = false;

  int nb_values = 6;

  float power = 0;
  float min_value = 0;
  float max_value = 255;

  float lerp(float v0, float v1, float t) {
    return (1 - t) * v0 + t * v1;
  }

  float get_threshold_by_index(int index)
  {
    float ratio = 0.5;
    if (nb_values > 1)
      ratio = ((float)index) / (nb_values-1);

    float factor = 1;
    if (power >= 0)
    {
      factor = 1 + power;
    } else
    {
      factor = 1 / (1 - power);
    }

    float value = pow(ratio, factor);

    return lerp(min_value, max_value, value);
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

  Slider nb_values;

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

    nb_values = addIntSlider("nb_values", "Nb values used", 1, 12);
    nextLine();

    power = addSlider("power", "Power", -10, 10);
    nextLine();
    min_value = addSlider("min_value", "Min", 0, 255);
    max_value = addSlider("max_value", "Max", 0, 255);
    nextLine();
  }

  void update_ui()
  {
  }

  void setGUIValues()
  {
    draw.setValue(data.draw);
    black.setValue(data.black);
    mirror.setValue(data.mirror);
    nb_values.setValue(data.nb_values);

    power.setValue(data.power);
    min_value.setValue(data.min_value);
    max_value.setValue(data.max_value);
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
