



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

// Click handler for StyleGUI's "Invert" button.
class InvertColorsButton
{
  StyleGUI gui;

  InvertColorsButton(StyleGUI gui)
  {
    this.gui = gui;
  }

  void onClic()
  {
    gui.invertColors();
  }
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
  Button backgroundColor;
  Button lineColor;
  Button invertButton;

  void setGUIValues()
  {
    lineWidth.setValue(style.lineWidth);
    lineColor.setColorBackground(style.lineColor);
    backgroundColor.setColorBackground(style.backgroundColor);
  }

  void setupControls()
  {
    super.Init();

    lineWidth = addSlider("lineWidth", "Line Width", 0, 5);
    nextLine();
    lineColor = addColorChooser("Line Color", new ColorSetter()
    {
      public color getColor() {
        return style.lineColor;
      }
      public void setColor(color c) {
        style.lineColor = c;
        style.changed = true;
      }
    }
    );
    backgroundColor = addColorChooser("background Color", new ColorSetter()
    {
      public color getColor() {
        return style.backgroundColor;
      }
      public void setColor(color c) {
        style.backgroundColor = c;
        style.changed = true;
      }
    }
    );

    invertButton = addButton("Invert");
    invertButton.plugTo(new InvertColorsButton(this), "onClic");
  }

  // Swaps lineColor/backgroundColor and re-tints both trigger buttons to
  // match - a plain button click, not tied to any other control's event (the
  // very first attempt at this, tying it to the Dots tab's Invert *toggle* in
  // a different project, hit a ControlP5 double-controlEvent-firing bug that
  // silently swapped the colors back a moment later; a dedicated button click
  // doesn't have that problem).
  void invertColors()
  {
    color tmp = style.lineColor;
    style.lineColor = style.backgroundColor;
    style.backgroundColor = tmp;
    style.changed = true;

    lineColor.setColorBackground(style.lineColor);
    backgroundColor.setColorBackground(style.backgroundColor);
  }

  void update_ui()
  {
    int _color = style.backgroundColor;
    LabelsHandler.set_labels_colors( color(255-red(_color), 255-green(_color), 255-blue(_color))   );
  }
}
