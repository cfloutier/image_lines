
class MainPanel
{
  ArrayList<GUIPanel> panels = new ArrayList<GUIPanel>();
  String activeTab = "";
  MainPanel()
  {
  }

  void addTab(GUIPanel panel)
  {
    panels.add(panel);
  }

  void Init()
  {
    // must be called after addTabs

    for (GUIPanel panel : panels)
    {
      panel.Init();
      panel.setupControls();
    }
  }

  void setGUIValues()
  {
    for (GUIPanel panel : panels)
    {
      panel.setGUIValues();
    }
  }

  void update_ui()
  {
    // update all changes in data to controller thats are not user inputs
    // like labels
    // or show hide controls depending on a status

    if (!data.any_change() && !data.need_update_ui )
      return;

    for (GUIPanel panel : panels)
    {
      panel.update_ui();
    }
  }

  void draw()
  {
    // checks if it's not an export
    if (_record)
      return;

    for (GUIPanel panel : panels)
    {
      panel.draw();
    }
  }


  void set_key_move(PVector key_move)
  {
    this.key_move = key_move;
  }


  PVector key_move = new PVector(0, 0) ;

  // key move is sent to active tab
  boolean checkKeyMove( )
  {
    // could be overriden
    return false;
  }

  GUIPanel dragging_panel;

  void mousePressed()
  {
    if (cp5.isMouseOver())
      return;

    //println("mouse pressed " + mouseX);
    for (GUIPanel panel : panels)
    {
      if (!panel.tab.isActive())
        continue;

      if (panel.mousePressed())
      {
        dragging_panel = panel;
        return;
      }
    }

    // if not check the non active panel
    for (GUIPanel panel : panels)
    {
      if (panel.tab.isActive())
        continue;

      if (panel.mousePressed())
      {
        dragging_panel = panel;
        cp5.getTab(dragging_panel.pageName).bringToFront();
        return;
      }
    }
  }

  void mouseDragged()
  {
    if (dragging_panel != null)
    {
      dragging_panel.mouseDragged();
    }
  }

  void mouseReleased() {

    if (dragging_panel != null)
    {
      dragging_panel.mouseReleased();
      dragging_panel = null;
    }
  }
}

void mousePressed() {
  dataGui.mousePressed();
}

void mouseDragged() {
  dataGui.mouseDragged();
}

void mouseReleased() {
  dataGui.mouseReleased();
}
