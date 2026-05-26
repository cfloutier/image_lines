class DataImage extends GenericData
{

  DataImage() {
    super("Image");
  }

  String source_file = "eye.jpg";

  boolean draw = true;
  float imageAlpha = 255;

  float Width = 500;
  int   Blur = 2;
  int Contrast = 0;
  boolean blackAndWhite = false;

  float levelsMin = 0;
  float levelsMax = 255;
  float levelsGamma = 0;

  PImage transformed_image = null;
  boolean reset_image = true;

  PImage image = null;

  public void setImage(String source_file)
  {
    this.source_file = source_file;

    println("setImage " + source_file);

    try {
      String file_path = dataFile(source_file).getAbsolutePath();
      image = loadImage(file_path);
      // image.filter(GRAY);
    }
    catch(Exception e) {
      image = null;

      println("error loading " + source_file);
      return;
    }

    reset_image = true;
    //println("Loaded source file " + source_file);
    //println("Loaded source file " + source_file);
  }

  void buildTransformedImage()
  {
    // Si l'image n'est pas chargée (ex: après LoadJson depuis le thread dialog),
    // on la recharge ici depuis le draw thread pour éviter les problèmes
    // de visibilité mémoire entre threads.
    if (image == null && source_file != null && !source_file.equals(""))
    {
      setImage(source_file);
    }

    if (image == null)
    {
      return;
    }

    if (this.changed || transformed_image == null || reset_image)
    {
      println("----------------- Rebuild transformed image ----------------");

      transformed_image = image.copy();

      if (transformed_image == null)
      {
        println("Error building blurred image");
        return;
      }

      transformed_image.resize((int)Width, (int)Height());
      if (blackAndWhite)
        transformed_image.filter(GRAY);
      transformed_image.filter(BLUR, Blur);
      transformed_image.loadPixels();
      applyLevels(transformed_image);
      transformed_image.updatePixels();

      changed = true;
      reset_image = false;
    }
  }

  void applyLevels(PImage img)
  {
    float inMin  = constrain(levelsMin, 0, 254);
    float inMax  = constrain(levelsMax, inMin + 1, 255);
    float range  = inMax - inMin;
    float gammaInv = 1.0 / pow(5.0, levelsGamma);

    for (int i = 0; i < img.pixels.length; i++)
    {
      color c = img.pixels[i];
      float r = constrain((red(c)   - inMin) / range, 0, 1);
      float g = constrain((green(c) - inMin) / range, 0, 1);
      float b = constrain((blue(c)  - inMin) / range, 0, 1);
      r = pow(r, gammaInv) * 255;
      g = pow(g, gammaInv) * 255;
      b = pow(b, gammaInv) * 255;
      img.pixels[i] = color(r, g, b, alpha(c));
    }
  }

  void draw(float imageAlpha)
  {
    if (transformed_image != null && imageAlpha > 0)
    {
      // draw centered
      PImage image =  this.transformed_image;

      float image_w = image.width;
      float image_h = image.height;

      tint(255, imageAlpha);
      image(image, -image_w/2, -image_h/2, image_w, image_h);
    }
  }

  // computed
  float Height()
  {
    if (image == null)
      return 0;

    return image.height * Width / image.width;
  }

  float getPixelValue(PVector point)
  {
    if (transformed_image == null)
    {
      buildTransformedImage();
    }

    if (transformed_image == null)
      return -1;

    int x_pos = int(point.x + transformed_image.width / 2);
    int y_pos = int(point.y + transformed_image.height / 2);

    if (x_pos < 0 || x_pos >= transformed_image.width ||
      y_pos < 0 || y_pos >= transformed_image.height)

      return -1;

    int loc =  x_pos + y_pos*transformed_image.width;

    float r = red(transformed_image.pixels[loc]);
    float g = green(transformed_image.pixels[loc]);
    float b = blue(transformed_image.pixels[loc]);

    return (r+ g + b ) /3;
  }

  public void LoadJson(JSONObject json) {
    super.LoadJson(json);
    // Ne pas appeler setImage() ici (appel depuis EDT / thread dialog).
    // On force image=null + reset_image pour que buildTransformedImage()
    // recharge l'image depuis le draw thread lors de la prochaine frame.
    image       = null;
    reset_image = true;
  }

}

ImageGUI _image_gui = null;

class ImageGUI extends GUIPanel
{
  DataImage data;

  public ImageGUI(DataImage data)
  {
    super("Image", data);
    this.data = data;
    _image_gui = this;
  }


  void SelectSourceImage() {
    println(":::LOAD JPG, GIF or PNG FILE:::");

    //File file = new File("C:/dev/__tracer/stipplegen/MyStippleGen/sourcesImages/");

    selectInput("Select a file to process:", "imgFileSelected", dataFile(data.source_file));  // Opens file chooser
  } //End Load File

  void update_ui()
  {
    if (data.source_file == "")
      file_Label.setText("please select a file");
    else
      file_Label.setText(data.source_file);
  }

  Toggle draw;
  Toggle blackAndWhite;
  Slider Width;
  Slider ImageAlpha;
  Slider Blur;
  Slider levelsMin;
  Slider levelsMax;
  Slider levelsGamma;
  Button resetLevels_bt;
  Button select_bt;

  Textlabel file_Label;

  void setupControls()
  {
    super.Init();

    select_bt = addButton("Select Source Image");
    select_bt.plugTo(this, "SelectSourceImage");

    file_Label = inlineLabel("File Label", 200);

    nextLine();
    draw = addToggle("draw", "Draw");
    blackAndWhite = addToggle("blackAndWhite", "Black & White");
    nextLine();
    Width = addSlider("Width", "Width", 200, 2000);
    ImageAlpha = addSlider("ImageAlpha", "Image Alpha", this, 0, 255);
    nextLine();
    addLabel("add Blur ");
    Blur = addIntSlider("Blur", "Blur", 1, 20);
    nextLine();
    nextLine();
    inlineLabel("Gamma Correction", 200);
    resetLevels_bt = addButton("Reset Levels");
    resetLevels_bt.plugTo(this, "ResetLevels");
    nextLine();
    levelsMin   = addSlider("levelsMin",   "Levels Min",   0, 254);
    levelsGamma = addSlider("levelsGamma", "Levels Gamma", -1.0, 1.0);
    levelsMax   = addSlider("levelsMax",   "Levels Max",   1, 255);


  }

  void setGUIValues()
  {
    draw.setValue(data.draw ? 1 : 0);
    blackAndWhite.setValue(data.blackAndWhite ? 1 : 0);
    Width.setValue(data.Width);
    ImageAlpha.setValue(data.imageAlpha);
    Blur.setValue(data.Blur);
    levelsMin.setValue(data.levelsMin);
    levelsMax.setValue(data.levelsMax);
    levelsGamma.setValue(data.levelsGamma);
  }

  void ResetLevels()
  {
    data.levelsMin   = new DataImage().levelsMin;
    data.levelsMax   = new DataImage().levelsMax;
    data.levelsGamma = new DataImage().levelsGamma;
    data.changed     = true;
    levelsMin.setValue(data.levelsMin);
    levelsMax.setValue(data.levelsMax);
    levelsGamma.setValue(data.levelsGamma);
  }

  public void controlEvent(ControlEvent theEvent)
  {
    if (theEvent.isController() && theEvent.getController() == ImageAlpha)
    {
      // display-only : pas de data.changed
      data.imageAlpha = ImageAlpha.getValue();
      return;
    }
    if (theEvent.isController() && theEvent.getController() == draw)
    {
      // display-only : pas de data.changed
      data.draw = draw.getValue() > 0.5;
      return;
    }
    super.controlEvent(theEvent);
  }
}

void imgFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());

    String loadPath = selection.getAbsolutePath();
    loadPath = loadPath.replaceAll("\\\\", "/");
    String[] p = splitTokens(loadPath, "/");
    String parent_dir = p[p.length - 2];
    String file_name = p[p.length - 1];

    // If a file was selected, print path to file
    println("Selected file: " + file_name);
    //println("parent_dir : " + parent_dir);

    if (!parent_dir.equals("data"))
    {
      println("Invalid Folder. Image must be in data path");
      return;
    }

    p = splitTokens(loadPath, ".");
    boolean fileOK = false;
    String extension = p[p.length - 1].toLowerCase();

    if ( extension.equals("gif"))
      fileOK = true;
    if ( extension.equals("jpg") || extension.equals("jpeg") )
      fileOK = true;
    if ( extension.equals("tga"))
      fileOK = true;
    if ( extension.equals("png"))
      fileOK = true;

    //println("File extension OK: " + fileOK);

    if (fileOK && _image_gui != null)
      _image_gui.data.setImage(file_name);
  }
}
