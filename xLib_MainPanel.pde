
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
    // Pushing data -> UI must not be mistaken for a user edit: Controller.setValue()
    // broadcasts a ControlEvent like a real interaction would, which would otherwise
    // loop back through GUIPanel.controlEvent() -> onUIChanged() and mark that
    // controller's own chapter "changed" again right after we just synced it from data.
    cp5.setBroadcast(false);
    for (GUIPanel panel : panels)
    {
      panel.setGUIValues();
    }
    cp5.setBroadcast(true);
  }

  void update_ui()
  {
    // update all changes in data to controller thats are not user inputs
    // like labels
    // or show hide controls depending on a status

    if (!data.any_change() && !data.need_update_ui )
      return;

    // Same reasoning as setGUIValues(): several panels' update_ui() unconditionally
    // call Controller.setValue() to keep sliders in sync with data (e.g. OcclusionGUI,
    // CameraGUI) even when that specific panel's own chapter isn't what changed. Left
    // broadcasting, that would mark their chapter "changed" again on every unrelated
    // change elsewhere - which used to be harmless (everything triggered a full
    // rebuild anyway) but breaks a targeted partial rebuild like a face-pattern-only
    // change once one exists.
    cp5.setBroadcast(false);
    for (GUIPanel panel : panels)
    {
      panel.update_ui();
    }
    cp5.setBroadcast(true);
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

  void mouseWheel(processing.event.MouseEvent event)
  {
    // optional override in subclasses
    if (event == null)
      return;
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

void mouseWheel(processing.event.MouseEvent event) {
  dataGui.mouseWheel(event);
}
