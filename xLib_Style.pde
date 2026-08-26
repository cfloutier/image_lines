



class Style extends GenericData
{
  Style() {
    super("Style");
  }

  color lineColor       = color(255, 255, 255);
  color backgroundColor = color(0, 0, 0);
  float lineWidth       = 1;
  // no LoadJson/SaveJson override - GenericData's generic reflection already
  // handles `color` fields (color IS int at the JVM level, same as any other
  // int field), and keeps the same JSON keys ("lineColor", "backgroundColor")
  // the old ColorRef-based version used.
}

class StyleGUI extends GUIPanel
{
  Style style;

  StyleGUI(Style dataStyle)
  {
    super("Style", dataStyle);
    this.style = dataStyle;
  }

  Slider lineWidth;
  ColorGroup backgroundColor;
  ColorGroup lineColor;

  void setGUIValues()
  {
    lineWidth.setValue(style.lineWidth);
  }

  void setupControls()
  {
    super.Init();

    lineWidth = addSlider("lineWidth", "Line Width", 0, 5);
    nextLine();
    lineColor = addColorGroup("Line Color", new ColorSetter()
    {
      public void setColor(color c) { style.lineColor = c; style.changed = true; }
    });
    backgroundColor = addColorGroup("background Color", new ColorSetter()
    {
      public void setColor(color c) { style.backgroundColor = c; style.changed = true; }
    });
  }

  void update_ui()
  {
    int _color = style.backgroundColor;
    LabelsHandler.set_labels_colors( color(255-red(_color), 255-green(_color), 255-blue(_color))   );
  }
}
