class DataImage extends GenericData
{

  DataImage() {
    super("Image");
  }

  String source_file = "eye.jpg";

  float Width = 500;
  int   Blur = 2;
  int Contrast = 0;

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
      image.filter(GRAY);
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

  void buildBlurredImage()
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
      println("Rebuild blurred ----------------");



      transformed_image = image.copy();

      if (transformed_image == null)
      {
        println("Error building blurred image");
        return;
      }

      transformed_image.resize((int)Width, (int)Height());
      transformed_image.filter(BLUR, Blur);
      transformed_image.loadPixels();

      changed = true;

      reset_image = false;
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
      buildBlurredImage();
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
    // On force image=null + reset_image pour que buildBlurredImage()
    // recharge l'image depuis le draw thread lors de la prochaine frame.
    image       = null;
    reset_image = true;
  }

  // void LoadJson(JSONObject src)
  // {
  //   if (src == null)
  //     return;

  //   Width = src.getFloat("Width", Width);
  //   ImageAlpha = src.getFloat("ImageAlpha", ImageAlpha);
  //   Blur = src.getInt("Blur", Blur);
  //   Contrast = src.getInt("Contrast", Contrast);

  //   setImage(src.getString("source_file", source_file));
  // }

  // JSONObject SaveJson()
  // {
  //   JSONObject dest = new JSONObject();

  //   dest.setFloat("Width", Width);
  //   dest.setString("source_file", source_file);
  //   dest.setFloat("ImageAlpha", ImageAlpha);
  //   dest.setInt("Blur", Blur);
  //   dest.setFloat("Contrast", Contrast);

  //   return dest;
  // }
}

ImageGUI _image_gui = null;

class ImageGUI extends GUIPanel
{
  DataImage data;
  float imageAlpha = 0; // GUI-only : n'affecte pas data.changed

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

  Slider Width;
  Slider ImageAlpha;
  Slider Blur;
  Button select_bt;

  Textlabel file_Label;

  void setupControls()
  {
    super.Init();

    select_bt = addButton("Select Source Image");
    select_bt.plugTo(this, "SelectSourceImage");

    file_Label = inlineLabel("File Label", 200);

    nextLine();
    Width = addSlider("Width", "Width", 200, 2000);
    ImageAlpha = addSlider("ImageAlpha", "Image Alpha", this, 0, 255);
    nextLine();
    Blur = addIntSlider("Blur", "Blur", 1, 20);
  }

  void setGUIValues()
  {
    Width.setValue(data.Width);
    ImageAlpha.setValue(imageAlpha);
    Blur.setValue(data.Blur);
  }

  public void controlEvent(ControlEvent theEvent)
  {
    if (theEvent.isController() && theEvent.getController() == ImageAlpha)
    {
      // GUI-only : pas de data.changed
      imageAlpha = ImageAlpha.getValue();
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
