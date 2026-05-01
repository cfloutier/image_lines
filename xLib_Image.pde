class DataImage extends GenericData
{

  DataImage() {
    super("Image");
  }

  String source_file = "eye.jpg";

  float Width = 500;
  float ImageAlpha = 0;
  int   Blur = 2;
  int Contrast = 0;

  PImage blurred_image = null;
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
    if (image == null)
    {
      //println("no image ?? ");
      return;
    }

    if (this.changed || blurred_image == null || reset_image)
    {
      println("Rebuild blurred ----------------");



      blurred_image = image.copy();

      if (blurred_image == null)
      {
        println("Error building blurred image");
        return;
      }

      blurred_image.resize((int)Width, (int)Height());
      blurred_image.filter(BLUR, Blur);
      blurred_image.loadPixels();

      changed = true;

      reset_image = false;
    }
  }

  void draw()
  {
    if (blurred_image != null && ImageAlpha > 0)
    {
      // draw centered
      PImage image =  this.blurred_image;

      float image_w = image.width;
      float image_h = image.height;

      tint(255, ImageAlpha);
      image(image, width/2 - image_w/2, height/2- image_h/2, image_w, image_h);
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
    if (blurred_image == null)
    {
      buildBlurredImage();
    }

    if (blurred_image == null)
      return -1;

    int x_pos = int(point.x + blurred_image.width / 2);
    int y_pos = int(point.y + blurred_image.height / 2);

    if (x_pos < 0 || x_pos >= blurred_image.width ||
      y_pos < 0 || y_pos >= blurred_image.height)

      return -1;

    int loc =  x_pos + y_pos*blurred_image.width;

    float r = red(blurred_image.pixels[loc]);
    float g = green(blurred_image.pixels[loc]);
    float b = blue(blurred_image.pixels[loc]);

    return (r+ g + b ) /3;
  }

  public void LoadJson(JSONObject json) {
    super.LoadJson(json);
    setImage(source_file);
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
    ImageAlpha = addSlider("ImageAlpha", "Image Alpha", 0, 255);
    nextLine();
    Blur = addIntSlider("Blur", "Blur", 1, 20);
  }

  void setGUIValues()
  {
    Width.setValue(data.Width);
    ImageAlpha.setValue(data.ImageAlpha);
    Blur.setValue(data.Blur);
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
