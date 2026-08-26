
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
    group.clear();

    int direction_index  = 1;
    int threshold_index  = 0;
    int current_group_id = -1;
    float threshold      = 0;

    for (int i_line = 0; i_line < source_group.size(); i_line++)
    {
      Polyline source_line = source_group.polylines.get(i_line);

      if (source_line.group_id != current_group_id)
      {
        current_group_id = source_line.group_id;
        int distributed_index = data_threshold.get_distributed_threshold_index(threshold_index);
        threshold = data_threshold.get_threshold_by_index(distributed_index);

        if (data_threshold.distribution_mode == DataThreshold.DISTRIBUTION_MIRROR)
        {
          threshold_index += direction_index;
          if (threshold_index >= data_threshold.nb_values || threshold_index < 0)
          {
            direction_index  = -direction_index;
            threshold_index += direction_index * 2;
          }
        }
        else
        {
          threshold_index++;
          if (threshold_index >= data_threshold.nb_values)
            threshold_index = 0;
        }
      }

      for (int i_point = 0; i_point < source_line.points.size(); i_point++)
      {
        PVector point = source_line.points.get(i_point);
        float value = image.getPixelValue(point);
        if (value == -1)
          closeLine();
        else if (data_threshold.black)
        {
          if (value < threshold) addPoint(point);
          else                   closeLine();
        }
        else
        {
          if (value > threshold) addPoint(point);
          else                   closeLine();
        }
      }

      closeLine();
    }
  }
}
