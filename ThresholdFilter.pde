
class DataThreshold extends GenericData
{
  static final int DISTRIBUTION_PROGRESSIVE = 0;
  static final int DISTRIBUTION_MIRROR = 1;
  static final int DISTRIBUTION_HACHURES = 2;

  DataThreshold() {
    super("Threshold");
  }

  boolean draw = true;
  boolean black = true;
  int distribution_mode = DISTRIBUTION_PROGRESSIVE;

  int nb_values = 1;

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

  int get_distributed_threshold_index(int index)
  {
    if (nb_values <= 1)
      return 0;

    int wrapped = index % nb_values;
    if (wrapped < 0)
      wrapped += nb_values;

    if (distribution_mode == DISTRIBUTION_HACHURES)
    {
      // Hachures mode alternates far-apart thresholds: 0, max, 1, max-1, 2, ...
      if ((wrapped % 2) == 0)
        return wrapped / 2;
      return (nb_values - 1) - (wrapped / 2);
    }

    return wrapped;
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
  RadioButton distribution_mode;

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
    nextLine();

    ArrayList<String> labels = new ArrayList<String>();
    labels.add("Progressive");
    labels.add("Mirror");
    labels.add("Hachures");
    addLabel("Threshold Distribution");
    distribution_mode = addRadio("distribution_mode", labels);

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
    distribution_mode.activate(data.distribution_mode);
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
        int distributed_index = data_threshold.get_distributed_threshold_index(threshold_index);
        threshold = data_threshold.get_threshold_by_index(distributed_index);
        //print("-" + threshold_index);

        if (data_threshold.distribution_mode == DataThreshold.DISTRIBUTION_MIRROR)
        {
          threshold_index += direction_index;
          if (threshold_index >= data_threshold.nb_values || threshold_index < 0)
          {
            direction_index = -direction_index;
            threshold_index += direction_index*2;
          }
        } else
        {
          threshold_index++;
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
