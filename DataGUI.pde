import controlP5.*;

class DataGUI extends MainPanel
{
  public DataGUI(ImgProcData data)
  {
    this.data = data;
    file_ui = new FileGUI(data, true);
    images_ui = new ImageGUI(data.image);
    style_ui = new StyleGUI(data.style);
    lines_ui = new LinesGUI(data.lines);
    threshold_ui = new ThresholdGUI(data.threshold);
  }

  ImgProcData data;
  FileGUI file_ui;
  ImageGUI images_ui;
  StyleGUI style_ui;
  LinesGUI lines_ui;
  ThresholdGUI threshold_ui;

  void Init()
  {
    addTab(file_ui);
    addTab(images_ui);
    addTab(lines_ui);
    addTab(threshold_ui);
    addTab(style_ui);

    super.Init();

    cp5.getTab("Lines").bringToFront();
  }
}
