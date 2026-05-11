import java.util.Locale;

class DataPage extends GenericData
{
  float global_scale = 1;

  boolean clipping = false;
  float clip_width = 800;
  float clip_height = 600;
  
  int paper_format = PAPER_NONE;  // 0: None, 1: A4, 2: A3, 3: A2
  int margin = MARGIN_3CM;  // 0: 1cm, 1: 3cm, 2: 10cm

  DataPage() {
    super("Page");
  }
}


FileGUI file_ui;

class FileGUI extends GUIPanel
{
  boolean show_clipping;

  DataGlobal global_data;
  DataPage page_data;
  
  BoundingBox last_bbox = null;
  float export_scale = 1.0;
  boolean export_should_rotate = false;

  FileGUI(DataGlobal data)
  {
    this(data, false);
  }

  FileGUI(DataGlobal data, boolean show_clipping)
  {
    super("Files", data.page);
    file_ui  = this;
    this.global_data = data;
    this.page_data = data.page;
    this.show_clipping = show_clipping;
  }

  void setGUIValues()
  {
    println("setGUIValues " + data.name);
    main_label.setText("Files : " + data.name);
    scale_slider.setValue(page_data.global_scale -1);
    if (show_clipping)
    {
      clip_toggle.setValue(page_data.clipping);
      clip_slider_width.setValue(page_data.clip_width);
      clip_slider_height.setValue(page_data.clip_height);
    }
    paper_format_radio.activate(page_data.paper_format);
    margin_radio.activate(page_data.margin);
  }

  void update_ui()
  {
    if (show_clipping)
    {
      if (page_data.clipping)
      {
        clip_slider_width.show();
        clip_slider_height.show();
      } else
      {
        clip_slider_width.hide();
        clip_slider_height.hide();
      }
    }
  }

  Textlabel main_label;
  ScaleSlider scale_slider;

  Toggle clip_toggle;

  Slider clip_slider_width;
  Slider clip_slider_height;
  
  RadioButton paper_format_radio;
  RadioButton margin_radio;

  void setupControls()
  {
    super.Init();

    main_label = addLabel("Files : ");

    addButton("Load").plugTo(this, "LoadJson");
    addButton("Save as...").plugTo(this, "SaveJson");
    addButton("Save").plugTo(this, "Save");

    nextLine();

    addLabel("Export : ");

    addButton("Export PDF").plugTo(this, "ExportPDF");
    addButton("Export SVG").plugTo(this, "ExportSVG");

    nextLine();
    addLabel("Page : ");
    nextLine();
    scale_slider = new ScaleSlider(cp5, "Scale");

    scale_slider.setPosition(xPos, yPos)
      .setSize(widthCtrl, heightCtrl)
      .setRange(-9, 9)
      .moveTo("Files")
      .setValue(0)
      .getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE).setPaddingX(0);

    xPos += widthCtrl + 10;

    addButton("Reset Scale").plugTo(this, "Reset_Scale");

    nextLine();

    clip_toggle = addToggle("clipping", "Clip", page_data);

    clip_slider_width = addSlider("clip_width", "Clip width", 0, 2000);
    clip_slider_height = addSlider("clip_height", "Clip height", 0, 2000);

    if (!show_clipping)
    {
      clip_toggle.hide();
      clip_slider_width.hide();
      clip_slider_height.hide();
    }
    
    nextLine();
    addLabel("Export Format :");
    ArrayList<String> paper_formats = new ArrayList<String>();
    paper_formats.add("None");
    paper_formats.add("A4");
    paper_formats.add("A3");
    paper_formats.add("A2");
    paper_format_radio = addRadio("paper_format", paper_formats);
    
    nextLine();
    addLabel("Margins :");
    ArrayList<String> margins = new ArrayList<String>();
    margins.add("0 cm");
    margins.add("1 cm");
    margins.add("3 cm");
    margins.add("10 cm");
    margin_radio = addRadio("margin", margins);
  }

  String default_path()
  {
    if (data.name == "")
      data.name = "default";

    String default_file = "../Settings/"+data.name+".json";
    return default_file;
  }

  void LoadJson()
  {
    println("LoadJson ");
    selectInput("Select data file ", "loadSelected", dataFile("../Settings/default.json")  );
  }

  void SaveJson()
  {
    println("SaveJson ");

    selectInput("Save data file ", "saveSelected", dataFile(default_path()));
  }

  void Save()
  {
    if (data.settings_path != "")
      data.SaveSettings(data.settings_path);
  }

  void ExportPDF()
  {
    _record = true;
    data.changed = true;
    mode = 0;
  }

  void ExportSVG()
  {
    _record = true;
    data.changed = true;
    mode = 2;
  }

  void Reset_Scale()
  {
    scale_slider.setValue(0);
  }
  
  // Update export scale based on bounding box and paper format
  void updateExportScale(BoundingBox bbox)
  {
    last_bbox = bbox;
    export_should_rotate = shouldRotateForExport(bbox);
    export_scale = calculateExportScale(bbox, data.page.paper_format, data.page.margin, export_should_rotate);
  }
}

void saveSelected(File selection)
{
  if (selection == null)
  {
  } else
  {
    String path = selection.getAbsolutePath();
    if (path.length() < 5 || !path.substring(path.length() - 5).equals(".json"))
      path = path + ".json";

    data.SaveSettings(path);

    String name = selection.getName();
    if (name.endsWith(".json"))
      data.name = name.substring(0, name.length() - 5);
    else
      data.name = name;

    file_ui.setGUIValues();
  }
}


// Slider slider_crop_width;
// Slider slider_crop_height;

//subclass slider
public class ScaleSlider extends Slider {
  //constructor
  public ScaleSlider( ControlP5 cp5, String name ) {
    super(cp5, name);
  }

  void computeScale()
  {
    float value =  getValue();
    if (value >= 0)
    {
      data.page.global_scale = 1 + value;
      getValueLabel().setText(String.format(Locale.US, " x %.1f", 1 + value));
    } else
    {
      data.page.global_scale = 1 / (1-value);
      getValueLabel().setText(String.format(Locale.US, " / %.1f", 1 - value));
    }
  }

  @Override public Slider setValue( float theValue ) {
    super.setValue(theValue);
    computeScale();
    return this;
  }
}

void loadSelected(File selection)
{
  if (selection != null)
  {
    data.LoadSettings(selection.getAbsolutePath());
    dataGui.setGUIValues();
  }
}

boolean _record = false;
int mode  = 0;

String export_fileName = "";
void ExportPDF()
{
  _record = true;
  data.changed = true;
  mode = 0;
}

void ExportDXF()
{
  _record = true;
  mode = 1;
}

void ExportSVG()
{
  _record = true;
  mode = 2;
}

void start_draw()
{
  dataGui.update_ui();

  if (data.changed)
  {

    data.changed = false;
  }

  if (_record)
  {
    String name = data.name;
    if (name == "")
      name = "default";

    float[] paper_dims = getPaperDimensions(data.page.paper_format);
    float newWidth   = (paper_dims != null) ? paper_dims[0] : width;
    float newheight  = (paper_dims != null) ? paper_dims[1] : height;

    // Add paper format to filename
    String format_suffix = "";
    switch(data.page.paper_format) {
      case PAPER_A4: format_suffix = "_A4"; break;
      case PAPER_A3: format_suffix = "_A3"; break;
      case PAPER_A2: format_suffix = "_A2"; break;
    }
    
    export_fileName = "Export/"+ name + format_suffix + "_" + year() + "-" + month() + "-" + day() + "_" + hour() + "-" + minute() + "-" + second();

    if (mode == 0)
    {
      export_fileName = export_fileName + ".pdf";
      current_graphics = createGraphics((int)newWidth, (int)newheight, PDF, export_fileName);
    } else if (mode == 1)
    {
      export_fileName = export_fileName + ".dxf";
      current_graphics = createGraphics((int)newWidth, (int)newheight, DXF, export_fileName);
    } else if (mode == 2)
    {
      export_fileName = export_fileName + ".svg";
      current_graphics = createGraphics((int)newWidth, (int)newheight, SVG, export_fileName);
    }

    println("Exported to " + export_fileName);

    data.setSize(newWidth, newheight);

    current_graphics.beginDraw();
    
    
    // Recalculate scale at export time (margin/format may have changed since buildLines)
    boolean shouldRotate = shouldRotateForExport(file_ui.last_bbox);
    file_ui.export_should_rotate = shouldRotate;
    float active_scale;
    if (data.page.paper_format != PAPER_NONE) {
      active_scale = calculateExportScale(file_ui.last_bbox, data.page.paper_format, data.page.margin, shouldRotate);
      file_ui.export_scale = active_scale;
    } else {
      active_scale = data.page.global_scale;
    }
    printExportDebugInfo(file_ui.last_bbox, active_scale, data.page.paper_format, data.page.margin, getPaperDimensions(data.page.paper_format));

    // Apply transformations to current_graphics (PDF/SVG/DXF)
    current_graphics.pushMatrix();
    current_graphics.stroke(data.style.lineColor.col);
    current_graphics.strokeWeight(data.style.lineWidth * active_scale);
    // Centre the content on the canvas (mirrors screen mode's translate(width/2, height/2))
    current_graphics.translate(newWidth / 2, newheight / 2);
    current_graphics.scale(active_scale, active_scale);
    // Fine-centre using bbox midpoint when available
    if (file_ui.last_bbox != null) {
      float cx = (file_ui.last_bbox.minX + file_ui.last_bbox.maxX) / 2;
      float cy = (file_ui.last_bbox.minY + file_ui.last_bbox.maxY) / 2;
      current_graphics.translate(-cx, -cy);
    }
    // Rotate only if drawing is landscape-oriented (wider than tall)
    if (file_ui.export_should_rotate) {
      current_graphics.rotate(-PI/2);
    }

  } else {

    current_graphics = g;

    background(data.style.backgroundColor.col);
    strokeWeight(data.style.lineWidth);
    stroke(data.style.lineColor.col);

    // Apply transformations to screen display
    pushMatrix();
    translate(width/2, height/2);
    float active_scale = data.page.global_scale;
    scale(active_scale, active_scale);

    current_graphics = g;

    data.setSize(width, height);
  }
}


void end_draw()
{
  if (_record)
  {
    current_graphics.popMatrix();  // Close the pushMatrix from start_draw
    current_graphics.dispose();
    current_graphics.endDraw();
    _record = false;
  } else {
    popMatrix();  // Close the pushMatrix from start_draw
  }
}
