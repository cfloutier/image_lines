int indexControler = 0;

static final int StartX = 20;
static final int StartY = 20;

static class LabelsHandler
{
  static public ArrayList<Textlabel> labels = new ArrayList<Textlabel>();
  static int label_color;

  static void set_labels_colors(int _color)
  {
    label_color = _color;
    for (Textlabel label : labels)
    {
      label.setColorValue(label_color);
    }
  }
}

class myRadioButton extends RadioButton
{
  public GenericData the_object;

  public myRadioButton(final ControlP5 theControlP5, final ControllerGroup< ? > theParent, final String theName, final int theX, final int theY )
  {
    super(theControlP5, theParent, theName, theX, theY  );
  }

  public void setValue(int value)
  {
    activate(value);
  }
}

// helper class used by panels (e.g. LinesGUI) to group related controls
// and synchronize their values with a DataLines instance via reflection.
// Usage:
//   ControlsGroup group = new ControlsGroup(dataLines);
//   group.add(addSlider("fieldName", "Label", min, max));
//   // later, in setGUIValues():
//   group.updateFromData();
//   // in update_ui():
//   group.show() or group.hide() depending on type
// The class skips Button controllers and only updates Slider/Toggle values.

class ControlsGroup {
  ArrayList<Controller> updatables = new ArrayList<Controller>();
  ArrayList<Button> buttons = new ArrayList<Button>();
  GenericData data;

  ControlsGroup(GenericData data) {
    this.data = data;
  }

  void add(Controller c) {
    if (c instanceof Button) {
      buttons.add((Button)c);
      return;
    }
    updatables.add(c);
  }

  void show() {
    for (Controller c : updatables) c.show();
    for (Button c : buttons)
    {
      c.show();
      // c.plugTo(this, "slash");
    }
  }

  void hide() {
    for (Controller c : updatables) c.hide();
    for (Button c : buttons) c.hide();
  }

  void updateFromData() {
    for (Controller c : updatables) {


      String fieldName = c.getName();
      try {
        java.lang.reflect.Field dataField = data.getClass().getDeclaredField(fieldName);
        dataField.setAccessible(true);
        Object value = dataField.get(data);

        if (c instanceof Slider) {
          Slider slider = (Slider) c;
          slider.setValue(((Number) value).floatValue());
        } else if (c instanceof Toggle) {
          Toggle toggle = (Toggle) c;
          toggle.setValue((Boolean) value);
        }
      }
      catch (Exception e) {
        println("Error updating " + fieldName + " (" + e.getClass().getSimpleName() + "): " + e.getMessage());
      }
    }
  }
}



class GUIPanel implements ControlListener
{
  String pageName;

  float xPos = 0;
  float yPos = 0;

  int xspace = 15;

  int widthCtrl = 300;
  int heightCtrl = 20;

  GenericData associated_data;

  GUIPanel(String pageName, GenericData data)
  {
    this.pageName = pageName;
    this.associated_data = data;
  }

  Tab tab;

  void Init()
  {
    tab = cp5.addTab(pageName);
    // print (" tab " + tab);
    // println("add tab " + pageName);

    cp5.addListener(this);

    yPos = StartY;
    xPos = StartX;
  }

  //////////////////////////// virtual functions ////////////////////////////

  void setupControls()
  {
    // create controls here

    println("Error : setupControls() must be implemented in extended classes ");
  }

  void setGUIValues()
  {
    // overload it to refines all values to controls

    println("Error : setGUIValues() must be implemented in extended classes ");
  }

  // update UI for all non controller (labels or hide/show)
  void update_ui()
  {
    // update all changes in data to controller thats are not user imputs
    // like labels
    // or show hide controls depending on a status

    println("Error : update_ui() must be implemented in extended classes ");
  }


  @SuppressWarnings("unused")
    boolean key_move(PVector key_move, int delta_ms)
  {
    return false;
  }

  void draw()
  {
    // can be optionnally setup to draw figure in the drawing
  }



  boolean mousePressed()
  {
    // return true to start a drag
    return false;
  }

  void mouseDragged()
  {
    // called if drag has started on each mouse move
  }

  void mouseReleased()
  {
    // called if drag has started on mouse up
  }

  //////////////////////////// Association with data changes ////////////////////////////

  public void onUIChanged()
  {
    associated_data.changed = true;
    data.changed = true;
  }

  public void controlEvent(ControlEvent theEvent) {

    String tab_name = "";
    if (theEvent.isController())
    {
      Controller controller = theEvent.getController();
      tab_name = controller.getTab().getName();
    } else if (theEvent.isGroup())
    {
      // used for radio only

      ControllerGroup group = theEvent.getGroup();
      tab_name = group.getTab().getName();

      if (!tab_name.equals(pageName))
        return;

      String class_name = group.getClass().getSimpleName();

      boolean is_radio = class_name.equals("myRadioButton");

      if (is_radio)
      {
        myRadioButton radio = (myRadioButton) group;

        // small fix to setup int_value from radio
        int int_value = int(group.getValue());
        String name = group.getName();
        radio.the_object.setInt(name, int_value);
        update_ui();
      }
    }

    if (tab_name == pageName)
      onUIChanged();
  }

  ////////////////// Controls ///////////////////////////

  Textlabel inlineLabel(String content, int width)
  {
    Textlabel l = cp5.addTextlabel("Label" + this.pageName + indexControler)
      .setText(content)
      .setPosition(xPos, yPos)
      .setSize(width, heightCtrl)
      .setColorValue(LabelsHandler.label_color)
      .moveTo(pageName);

    LabelsHandler.labels.add(l);

    xPos += width;
    indexControler++;

    return l;
  }

  Textlabel addLabel(String content)
  {
    yPos += 10;

    Textlabel l = cp5.addTextlabel("Label" + this.pageName + indexControler)
      .setText(content)
      .setPosition(xPos, yPos)
      .setSize(100, heightCtrl)
      .setColorValue(LabelsHandler.label_color)
      .moveTo(pageName);

    LabelsHandler.labels.add(l);

    yPos += 15;
    indexControler++;

    return l;
  }

  Slider addIntSlider(String field, String label, int min, int max)
  {
    return addIntSlider(field, label, associated_data, min, max);
  }

  Slider addIntSlider(String field, String label, Object the_data, int min, int max)
  {
    Slider s = addSlider( field, label, the_data, min, max);
    int nbTicks = (int) (max - min + 1);
    s.setNumberOfTickMarks(nbTicks);
    s.showTickMarks(false);
    s.snapToTickMarks(true);

    return s;
  }

  Slider addSlider(String field, String label, float min, float max)
  {
    return addSlider(field, label, associated_data, min, max);
  }

  int getWidthLabel(String label)
  {

    int width = 0;
    for (char c : label.toCharArray()) {

      switch (c)
      {
      case 'I':
      case 'i':
        width +=2;
        break;

      case 'T':
      case 't':
        width += 4;
        break;
      case '.':
      case ',':
      case ';':
        width += 4;
        break;
      case '-':
        width += 3;
        break;
      default:
        width +=5;
        break;
      }
    }

    return width;
  }

  Slider addSlider(String field, String label, Object the_data, float min, float max)
  {
    Slider s = cp5.addSlider(the_data, field)
      .setLabel(label)
      .setPosition(xPos, yPos)
      .setSize(widthCtrl, heightCtrl)
      .setRange(min, max)
      .moveTo(pageName);

    xPos += xspace + widthCtrl;

    controlP5.Label l = s.getCaptionLabel();
    l.getStyle().marginTop = 0; //move upwards (relative to button size)

    s.getCaptionLabel().getStyle().marginLeft = -getWidthLabel(label) - 8; // adjust -10 as needed

    return s;
  }

  Toggle addToggle(String name, String label)
  {
    return addToggle(name, label, associated_data);
  }

  Toggle addToggle(String name, String label, Object the_data)
  {
    Toggle t = cp5.addToggle(the_data, name)
      .setLabel(label)
      .setPosition(xPos, yPos)
      .setSize(100, heightCtrl)
      .setMode(ControlP5.SWITCH)
      .moveTo(pageName);

    CColor controlerColor = t.getColor();
    int tmp = controlerColor.getActive();
    controlerColor.setActive( controlerColor.getBackground());
    controlerColor.setBackground(tmp);

    xPos+=100+5;

    //t.setLabel("The Toggle Name");
    controlP5.Label l = t.getCaptionLabel();
    l.getStyle().marginTop = -heightCtrl + 2; //move upwards (relative to button size)
    l.getStyle().marginLeft = 10; //move to the right

    return t;
  }

  ColorPicker addColorPicker(String name, String label)
  {
    addLabel(label);

    ColorPicker cp = cp5.addColorPicker(associated_data, name)

      .setPosition(xPos, yPos)
      .setSize(100, heightCtrl*3)
      .moveTo(pageName);

    yPos+=heightCtrl*3;

    return cp;
  }

  ColorGroup addColorGroup(String name, ColorRef colorRef)
  {
    ColorGroup grp = new ColorGroup(colorRef, name );

    grp.Init(this);

    return grp;
  }

  Button addButton(String name)
  {
    int width_bt = 100;

    Button bt = cp5.addButton(name + indexControler)
      .setPosition(xPos, yPos)
      .setLabel(name)
      .setSize(width_bt, heightCtrl)
      .moveTo(pageName);

    xPos += width_bt+5;

    indexControler++;
    return bt;
  }

  myRadioButton addRadio(String name, ArrayList<String> labels)
  {
    return addRadio(name, labels, associated_data);
  }

  myRadioButton addRadio(String name, ArrayList<String> labels, GenericData the_data)
  {
    int width_bt = 100;

    // return addRadioButton( the_data , the_data != null ? the_data.toString( ) : "" , name , 0 , 0 );
    myRadioButton r1 = new myRadioButton( cp5, ( Tab ) cp5.controlWindow.getTabs( ).get( 1 ), name, 0, 0 );
    cp5.register( the_data, the_data != null ? the_data.toString( ) : "", r1 );
    r1.registerProperty( "arrayValue" );
    // return myController;
    r1.the_object = the_data;

    r1.setPosition(xPos, yPos)
      .setSize(width_bt, heightCtrl)
      .setItemsPerRow(labels.size())
      .setSpacingColumn(10)
      .moveTo(pageName);

    for (int i = 0; i < labels.size(); i++)
    {
      String _label = labels.get(i);
      r1.addItem(_label, float(i));
    }

    for (Toggle t : r1.getItems()) {
      t.getCaptionLabel().setColorBackground(color(125, 0));

      t.getCaptionLabel().getStyle().moveMargin(-8, 0, 0, -width_bt);
      t.getCaptionLabel().getStyle().movePadding(7, 0, 0, 3);
      t.getCaptionLabel().getStyle().backgroundWidth = 500;
      t.getCaptionLabel().getStyle().backgroundHeight = 20;
    }

    nextLine();
    return r1;
  }

  void start()
  {
    xPos = 20;
    yPos = 20;
  }

  void nextLine()
  {
    xPos = 20;
    yPos += heightCtrl + 1;
  }

  void space()
  {
    yPos += 5;
  }
}
