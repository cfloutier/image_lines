// xLib_ThresholdData — shared threshold distribution data + GUI
//
// Used by: image_lines (ThresholdFilter), image_contours (ContourShadeFilter)
//
// DataThreshold holds all distribution logic; actual filtering (pixel sampling)
// is project-specific and lives in each project's own filter class.

// ------------------------------------------------------------------
// Data
// ------------------------------------------------------------------

class DataThreshold extends GenericData
{
  static final int DISTRIBUTION_PROGRESSIVE = 0;
  static final int DISTRIBUTION_MIRROR      = 1;
  static final int DISTRIBUTION_HACHURES    = 2;
  static final int DISTRIBUTION_INTERLEAVED = 3;
  static final int DISTRIBUTION_BISECT      = 4;
  static final int DISTRIBUTION_BISECT_BFS  = 5;

  DataThreshold() {
    super("Threshold");
  }

  boolean enabled          = true;
  boolean black            = true;
  int     distribution_mode = DISTRIBUTION_PROGRESSIVE;

  int   nb_values = 1;
  float power     = 0;
  float min_value = 0;
  float max_value = 255;

  int   cached_interleaved_nb_values   = -1;
  int[] cached_interleaved_thresholds  = null;
  int   cached_bisect_bfs_nb_values    = -1;
  int[] cached_bisect_bfs_thresholds   = null;

  float get_threshold_by_index(int index)
  {
    float ratio = 0.5;
    if (nb_values > 1)
      ratio = ((float)index) / (nb_values - 1);

    float factor = (power >= 0) ? (1 + power) : (1.0 / (1 - power));
    float value  = pow(ratio, factor);
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
      if ((wrapped % 2) == 0)
        return wrapped / 2;
      return (nb_values - 1) - (wrapped / 2);
    }

    if (distribution_mode == DISTRIBUTION_INTERLEAVED)
      return get_interleaved_threshold_index(wrapped);

    if (distribution_mode == DISTRIBUTION_BISECT)
    {
      // Period = 2^(nb_values-1). Sequence for n=4: 0 3 2 3 1 3 2 3
      int period = 1 << (nb_values - 1);
      int i = wrapped % period;
      if (i < 0) i += period;
      if (i == 0) return 0;
      int tz = Integer.numberOfTrailingZeros(i);
      return max(0, (nb_values - 1) - tz);
    }

    if (distribution_mode == DISTRIBUTION_BISECT_BFS)
      return get_bisect_bfs_threshold_index(wrapped);

    return wrapped;
  }

  int get_interleaved_threshold_index(int wrapped)
  {
    if (cached_interleaved_thresholds == null || cached_interleaved_nb_values != nb_values)
      compute_interleaved_thresholds();
    return cached_interleaved_thresholds[wrapped];
  }

  void compute_interleaved_thresholds()
  {
    cached_interleaved_nb_values = nb_values;
    cached_interleaved_thresholds = new int[nb_values];
    boolean[] used_positions = new boolean[nb_values];
    cached_interleaved_thresholds[0] = 0;
    used_positions[0] = true;

    for (int threshold_index = 1; threshold_index < nb_values; threshold_index++)
    {
      int best_position = -1;
      int best_score    = -1;

      for (int candidate_position = 0; candidate_position < nb_values; candidate_position++)
      {
        if (used_positions[candidate_position])
          continue;

        int nearest_used_distance = nb_values;
        for (int used_position = 0; used_position < nb_values; used_position++)
        {
          if (!used_positions[used_position])
            continue;
          int distance = abs(candidate_position - used_position);
          distance = min(distance, nb_values - distance);
          if (distance < nearest_used_distance)
            nearest_used_distance = distance;
        }

        if (nearest_used_distance > best_score)
        {
          best_score    = nearest_used_distance;
          best_position = candidate_position;
        }
      }

      used_positions[best_position] = true;
      cached_interleaved_thresholds[best_position] = threshold_index;
    }
  }

  int get_bisect_bfs_threshold_index(int wrapped)
  {
    if (cached_bisect_bfs_thresholds == null || cached_bisect_bfs_nb_values != nb_values)
      compute_bisect_bfs_thresholds();
    return cached_bisect_bfs_thresholds[wrapped];
  }

  void compute_bisect_bfs_thresholds()
  {
    // BFS midpoint subdivision — each threshold used exactly once, period = nb_values.
    // For n=8 the sequence is [0, 4, 2, 6, 1, 3, 5, 7].
    cached_bisect_bfs_nb_values  = nb_values;
    cached_bisect_bfs_thresholds = new int[nb_values];
    if (nb_values == 0) return;

    cached_bisect_bfs_thresholds[0] = 0;
    if (nb_values == 1) return;

    int   MAX_Q  = nb_values + 4;
    int[] q_lo   = new int[MAX_Q];
    int[] q_hi   = new int[MAX_Q];
    int   q_head = 0, q_tail = 0;
    int   line_index = 1;

    q_lo[q_tail] = 1; q_hi[q_tail] = nb_values - 1; q_tail++;

    while (q_head < q_tail && line_index < nb_values)
    {
      int lo  = q_lo[q_head];
      int hi  = q_hi[q_head];
      q_head++;

      int mid = (lo + hi) / 2;
      cached_bisect_bfs_thresholds[line_index++] = mid;

      if (lo  < mid) { q_lo[q_tail] = lo;      q_hi[q_tail] = mid - 1; q_tail++; }
      if (mid < hi)  { q_lo[q_tail] = mid + 1; q_hi[q_tail] = hi;      q_tail++; }
    }
  }
}

// ------------------------------------------------------------------
// GUI
// ------------------------------------------------------------------

class ThresholdGUI extends GUIPanel
{
  DataThreshold data;

  ThresholdGUI(DataThreshold data)
  {
    super("Seuils", data);
    this.data = data;
  }

  Toggle      enabled;
  Toggle      black;
  RadioButton distribution_mode;
  Slider      nb_values;
  Slider      power;
  Slider      min_value;
  Slider      max_value;

  void setupControls()
  {
    super.Init();

    enabled = addToggle("enabled", "Active");
    nextLine();
    black = addToggle("black", "Black Lines");
    nextLine();

    ArrayList<String> labels = new ArrayList<String>();
    labels.add("Progressive");
    labels.add("Mirror");
    labels.add("Hachures");
    labels.add("Interleaved");
    labels.add("Bisect");
    labels.add("Bisect BFS");
    addLabel("Threshold Distribution");
    distribution_mode = addRadio("distribution_mode", labels);

    nb_values = addIntSlider("nb_values", "Nb values used", 1, 12);
    nextLine();

    power     = addSlider("power",     "Power", -10, 10); nextLine();
    min_value = addSlider("min_value", "Min",     0, 255);
    max_value = addSlider("max_value", "Max",     0, 255); nextLine();
  }

  void update_ui() {}

  void setGUIValues()
  {
    enabled.setValue(data.enabled);
    black.setValue(data.black);
    distribution_mode.activate(data.distribution_mode);
    nb_values.setValue(data.nb_values);
    power.setValue(data.power);
    min_value.setValue(data.min_value);
    max_value.setValue(data.max_value);
  }
}
