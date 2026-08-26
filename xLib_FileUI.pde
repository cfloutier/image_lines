import java.util.Locale;
import java.util.Collections;

// On some Processing renderer/OS combinations (seen with P3D/JOGL sketches), the native
// file dialog opened by selectInput()/selectOutput() appears behind the main window - which
// can also auto-minimize - instead of getting focus. This doesn't happen with the default
// (non-OpenGL) renderer. Call right after selectInput()/selectOutput() to force the dialog
// to front once AWT has finished creating it; polls briefly since dialog creation isn't
// synchronous with the selectInput() call returning.
// Note: the very first LoadJson()/SaveJson() call of a run can still open the dialog behind
// the main window even with this fix (tried a warmupNativeFileDialog() companion to
// pre-create AWT's native FileDialog peer at setup() time, but it didn't help - reverted).
// Every call after the first one is fixed correctly.
void bringNativeFileDialogToFront() {
  // First call after sketch startup is much slower to show the dialog (class loading /
  // JIT warmup for AWT FileDialog + the Swing Timer/ActionListener machinery itself) -
  // seen taking longer than a 1.2s poll budget on the very first LoadJson()/SaveJson().
  // Subsequent calls find the dialog almost immediately, but keep a generous budget
  // throughout since it's cheap to poll and just stops as soon as the dialog is found.
  final javax.swing.Timer t = new javax.swing.Timer(150, null);
  final int[] tries = {0};
  t.addActionListener(new java.awt.event.ActionListener() {
    public void actionPerformed(java.awt.event.ActionEvent e) {
      for (java.awt.Window w : java.awt.Window.getWindows()) {
        if (w.isShowing() && (w instanceof java.awt.FileDialog || w.getClass().getName().contains("FileChooser"))) {
          w.toFront();
          w.requestFocus();
          t.stop();
          return;
        }
      }
      if (++tries[0] >= 40) t.stop();  // give up after ~6s - dialog may have been cancelled instantly
    }
  }
  );
  t.setRepeats(true);
  t.start();
}

class DataPage extends GenericData
{
  static final int ASPECT_NONE  = 0;  // free proportions - width/height independent
  static final int ASPECT_A4    = 1;
  static final int ASPECT_16_9  = 2;
  static final int ASPECT_4_3   = 3;
  static final int ASPECT_RAISIN = 4;
  // Appended rather than inserted alongside the others (would renumber A4/16:9/4:3/
  // Raisin and silently reinterpret any settings file already saved with a
  // clip_aspect_ratio value) - square, orientation-invariant.
  static final int ASPECT_1_1   = 5;

  float global_scale = 1;

  boolean clipping = false;
  float clip_width = 800;
  float clip_height = 600;
  // When not ASPECT_NONE, clip_width/clip_height are kept locked to a fixed ratio -
  // dragging either slider recomputes the other (see FileGUI.applyAspectRatioFrom*()).
  int clip_aspect_ratio = ASPECT_NONE;
  // Orientation for clip_aspect_ratio: true = wide side horizontal (e.g. A4 lying
  // down), false = wide side vertical (e.g. A4 upright). Irrelevant for ASPECT_NONE.
  boolean clip_landscape = false;

  int paper_format = PAPER_NONE;  // 0: None, 1: A4, 2: A3, 3: A2, 4: Raisin (50x65 cm)
  int margin = MARGIN_3CM;  // 0: 0cm, 1: 1cm, 2: 2cm, 3: 3cm

  DataPage() {
    super("Page");
  }
}

// Long-side/short-side ratio (always >= 1) for a clip aspect-ratio preset, or <= 0
// for ASPECT_NONE (unconstrained). A4/Raisin reuse the exact same mm dimensions as
// the export paper formats (getPaperDimensions(), xLib_ExportUtils.pde) rather than
// duplicating the numbers; 16:9 and 4:3 are plain screen-ratio constants.
float getClipAspectRatioMagnitude(int mode)
{
  switch (mode)
  {
  case DataPage.ASPECT_A4:
    float[] a4 = getPaperDimensions(PAPER_A4);
    return max(a4[0], a4[1]) / min(a4[0], a4[1]);
  case DataPage.ASPECT_16_9:
    return 16.0 / 9.0;
  case DataPage.ASPECT_4_3:
    return 4.0 / 3.0;
  case DataPage.ASPECT_RAISIN:
    float[] raisin = getPaperDimensions(PAPER_RAISIN);
    return max(raisin[0], raisin[1]) / min(raisin[0], raisin[1]);
  case DataPage.ASPECT_1_1:
    return 1.0;
  default:
    return -1;
  }
}

// Actual clip_width/clip_height ratio for a preset+orientation pair: landscape puts
// the long side on width (ratio >= 1), portrait puts it on height (ratio <= 1).
// <= 0 for ASPECT_NONE (unconstrained).
float getClipAspectRatioValue(int mode, boolean landscape)
{
  float magnitude = getClipAspectRatioMagnitude(mode);
  if (magnitude <= 0)
    return -1;
  return landscape ? magnitude : (1.0 / magnitude);
}


FileGUI file_ui;

interface ExportBusyGuard
{
  boolean isBusy();
}

class FileGUI extends GUIPanel
{
  boolean show_clipping;

  DataGlobal global_data;
  DataPage page_data;

  BoundingBox last_bbox = null;
  float export_scale = 1.0;
  boolean export_landscape = false;  // page orientation follows the drawing's aspect ratio

  // Set one of these in sketch setup() to enable direct SVG export:
  //   export_group  → PolylineGroup  (spiral, perlin_mountains, image_lines)
  //   export_shapes → ShapesGroup    (image_dots and projects with dots+polylines)
  // export_shapes is checked first; falls back to export_group, then Processing renderer.
  PolylineGroup export_group  = null;
  ShapesGroup   export_shapes = null;

  // Optional: set in sketch setup() if line generation is async/incremental and export
  // should be refused while it's still running (e.g. trace_3d's HLR builder). Left null
  // by default - projects that never set it are never blocked.
  ExportBusyGuard export_busy_guard = null;

  int last_save_duration = -1;

  // ---- In-app Load/Save file picker (replaces the native selectInput() modal,
  // which on P3D/JOGL sketches can open behind the main window). See enterState(). ----
  static final int FILE_UI_NORMAL = 0;
  static final int FILE_UI_LOAD_PICK = 1;
  static final int FILE_UI_SAVE_PICK = 2;
  static final int FILE_UI_CONFIRM_OVERWRITE = 3;

  static final int FILE_SLOT_COLUMNS = 4;
  static final int FILE_SLOT_ROWS = 4;
  static final int MAX_FILE_SLOTS = FILE_SLOT_COLUMNS * FILE_SLOT_ROWS;
  static final int FILE_SLOT_WIDTH = 220;
  static final int FILE_SLOT_HEIGHT = 20;
  static final int FILE_SLOT_XGAP = 10;
  static final int FILE_SLOT_YGAP = 2;

  int file_ui_state = FILE_UI_NORMAL;
  // Path relative to Settings/ currently being browsed ("" = Settings/ itself).
  // Only ever reset to "" by LoadJson()/SaveJson() (a fresh Load/Save-as click) -
  // navigating folders, paginating, or cancelling out of a confirm step must NOT
  // lose it.
  String current_relpath = "";
  int file_list_page = 0;
  String pending_overwrite_name = null;
  // When true, refreshFileList() runs on the NEXT draw() frame instead of
  // immediately - see setPendingRefresh()/draw() for why.
  boolean pending_refresh = false;
  // ControlP5 re-fires a click within the same frame if the button under the mouse
  // is still present but its meaning changed mid-dispatch (confirmed empirically:
  // navigating into a folder immediately re-triggered a second "navigate" call,
  // doubling the path segment - deferring the relabel alone wasn't enough, since the
  // ghost click still runs the same handler again with the metadata unchanged).
  // shouldSkipDuplicateNavAction() blocks a second nav action within one frame.
  int last_nav_action_frame = -1;

  Button[] file_slot_buttons = new Button[MAX_FILE_SLOTS];
  String[] file_slot_name = new String[MAX_FILE_SLOTS];
  boolean[] file_slot_is_dir = new boolean[MAX_FILE_SLOTS];

  Textlabel file_ui_status_label;
  Button up_dir_bt;
  Button prev_page_bt;
  Button next_page_bt;
  Textfield new_filename_field;
  Button create_bt;
  Button confirm_overwrite_bt;
  Button cancel_bt;

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
      clip_aspect_radio.activate(page_data.clip_aspect_ratio);
      clip_landscape_toggle.setValue(page_data.clip_landscape);
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
        clip_aspect_radio.show();
        clip_landscape_toggle.show();
      } else
      {
        clip_slider_width.hide();
        clip_slider_height.hide();
        clip_aspect_radio.hide();
        clip_landscape_toggle.hide();
      }
    }
  }

  Textlabel main_label;
  ScaleSlider scale_slider;

  Toggle clip_toggle;

  Slider clip_slider_width;
  Slider clip_slider_height;
  myRadioButton clip_aspect_radio;
  Toggle clip_landscape_toggle;

  RadioButton paper_format_radio;
  RadioButton margin_radio;

  // Guards against the reentrant setValue() call each applyAspectRatioFrom*() makes
  // on the OTHER clip slider from re-triggering the same logic in a loop.
  boolean applying_aspect_ratio = false;

  void setupControls()
  {
    super.Init();

    main_label = addLabel("Files : ");

    addButton("Load").plugTo(this, "LoadJson");
    addButton("Save as...").plugTo(this, "SaveJson");
    addButton("Save").plugTo(this, "Save");
    xPos += 10;
    addButton("Export SVG").plugTo(this, "ExportSVG");
    nextLine();

    // addButton("SVG (Processing)").plugTo(this, "ExportSVGProcessing");

    addLabel("Scale (applied only on screen) :");
    scale_slider = new ScaleSlider(cp5, "Scale");

    scale_slider.setPosition(xPos, yPos)
      .setSize(widthCtrl, heightCtrl)
      .setRange(-9, 9)
      .moveTo("Files")
      .setValue(0);

    scale_slider.getCaptionLabel().getStyle().marginTop = 0;
    scale_slider.getCaptionLabel().getStyle().marginLeft = -getWidthLabel("Scale") - 8;

    xPos += widthCtrl + 10;

    addButton("Reset Scale").plugTo(this, "Reset_Scale");

    nextLine();

    if (show_clipping)
    {
      addLabel("Clipping : ");
      // clip_toggle.hide();
      // clip_slider_width.hide();
      // clip_slider_height.hide();
      clip_toggle = addToggle("clipping", "Clip", page_data);
      clip_slider_width = addSlider("clip_width", "Clip width", 0, 2000);
      clip_slider_height = addSlider("clip_height", "Clip height", 0, 2000);
      nextLine();

      addLabel("Clip Ratio :");
      ArrayList<String> clip_ratios = new ArrayList<String>();
      clip_ratios.add("None");
      clip_ratios.add("A4");
      clip_ratios.add("16:9");
      clip_ratios.add("4:3");
      clip_ratios.add("Raisin");
      // Appended, not inserted - addRadio() assigns each item's value by its
      // position in this list, which must line up with the ASPECT_* constants.
      clip_ratios.add("1:1");
      clip_aspect_radio = addRadio("clip_aspect_ratio", clip_ratios);

      clip_landscape_toggle = addToggle("clip_landscape", "Landscape", page_data);
      nextLine();
    }

    addLabel("Export Page size :");
    ArrayList<String> paper_formats = new ArrayList<String>();
    paper_formats.add("None");
    paper_formats.add("A4");
    paper_formats.add("A3");
    paper_formats.add("A2");
    paper_formats.add("Raisin");
    paper_format_radio = addRadio("paper_format", paper_formats);

    // nextLine();
    addLabel("Margins :");
    ArrayList<String> margins = new ArrayList<String>();
    margins.add("0 cm");
    margins.add("1 cm");
    margins.add("2 cm");
    margins.add("3 cm");
    margin_radio = addRadio("margin", margins);

    setupFilePickerControls();
  }

  // The picker's controls live on cp5's built-in "default" tab (labeled "Hide GUI"
  // in trace_3d.pde's setup()) instead of the "Files" tab, so opening Load/Save-as
  // doesn't pile a busy button grid onto the Files tab's own permanent controls.
  // enterState() brings that tab to front while a picker state is active and back
  // to "Files" on return - same bringToFront() mechanism already used for the
  // initial tab in DataGUI.Init().
  void setupFilePickerControls()
  {
    float px = StartX;
    float py = StartY;

    file_ui_status_label = addLabel("");
    file_ui_status_label.setPosition(px, py).moveTo("default");
    py += heightCtrl + 6;

    float slot_start_x = px;
    float slot_start_y = py;

    for (int i = 0; i < MAX_FILE_SLOTS; i++)
    {
      int col = i % FILE_SLOT_COLUMNS;
      int row = i / FILE_SLOT_COLUMNS;
      float bx = slot_start_x + col * (FILE_SLOT_WIDTH + FILE_SLOT_XGAP);
      float by = slot_start_y + row * (FILE_SLOT_HEIGHT + FILE_SLOT_YGAP);

      Button bt = cp5.addButton("file_slot_" + i)
        .setPosition(bx, by)
        .setSize(FILE_SLOT_WIDTH, FILE_SLOT_HEIGHT)
        .setLabel("")
        .moveTo("default");
      bt.hide();
      file_slot_buttons[i] = bt;
    }

    py = slot_start_y + FILE_SLOT_ROWS * (FILE_SLOT_HEIGHT + FILE_SLOT_YGAP) + 10;

    up_dir_bt = addButton("..");
    up_dir_bt.setPosition(px, py).moveTo("default");
    up_dir_bt.plugTo(this, "onUpDir");
    px += 105;
    prev_page_bt = addButton("< Prev");
    prev_page_bt.setPosition(px, py).moveTo("default");
    prev_page_bt.plugTo(this, "onPrevPage");
    px += 105;
    next_page_bt = addButton("Next >");
    next_page_bt.setPosition(px, py).moveTo("default");
    next_page_bt.plugTo(this, "onNextPage");

    px = StartX;
    py += heightCtrl + 6;

    new_filename_field = cp5.addTextfield("new_filename_field")
      .setPosition(px, py)
      .setSize(widthCtrl, heightCtrl)
      .setAutoClear(false)
      .moveTo("default");
    new_filename_field.hide();
    px += widthCtrl + xspace;

    create_bt = addButton("Create");
    create_bt.setPosition(px, py).moveTo("default");
    create_bt.plugTo(this, "onCreateNewFile");

    px = StartX;
    py += heightCtrl + 6;

    confirm_overwrite_bt = addButton("Yes, overwrite");
    confirm_overwrite_bt.setPosition(px, py).moveTo("default");
    confirm_overwrite_bt.plugTo(this, "onConfirmOverwrite");
    px += 140;
    cancel_bt = addButton("Cancel");
    cancel_bt.setPosition(px, py).moveTo("default");
    cancel_bt.plugTo(this, "onCancel");

    // addButton() advances xPos/yPos on the Files-tab layout cursor as a side effect
    // of building the controls above - reset it since setupControls() is otherwise
    // done with the Files tab at this point.
    xPos = StartX;
    yPos = StartY;

    enterState(FILE_UI_NORMAL);
  }

  void LoadJson()
  {
    current_relpath = "";
    file_list_page = 0;
    enterState(FILE_UI_LOAD_PICK);
  }

  void SaveJson()
  {
    current_relpath = "";
    file_list_page = 0;
    enterState(FILE_UI_SAVE_PICK);
  }

  void Save()
  {
    if (data.settings_path != "")
    {
      stop_compute = true;
      data.SaveSettings(data.settings_path);
      stop_compute = false;
    }
  }

  // ---- In-app file picker state machine ----

  // Single authority for what's visible and for stop_compute: true the instant we
  // leave FILE_UI_NORMAL, false only once we're back (Cancel from any sub-state, or
  // a completed load/save) - one place to get right instead of resetting the flag in
  // every possible callback branch (see xLib_version.pde 3.12.1 changelog for the bug
  // this avoids repeating).
  void enterState(int new_state)
  {
    file_ui_state = new_state;
    stop_compute = (new_state != FILE_UI_NORMAL);

    if (new_state == FILE_UI_NORMAL)
      cp5.getTab(pageName).bringToFront();
    else
      cp5.getTab("default").bringToFront();

    for (Button b : file_slot_buttons)
      b.hide();
    up_dir_bt.hide();
    prev_page_bt.hide();
    next_page_bt.hide();
    new_filename_field.hide();
    create_bt.hide();
    confirm_overwrite_bt.hide();
    cancel_bt.hide();
    file_ui_status_label.setText("");

    if (new_state == FILE_UI_LOAD_PICK)
    {
      file_ui_status_label.setText("Select a file to load:");
      refreshFileList();
      cancel_bt.show();
    } else if (new_state == FILE_UI_SAVE_PICK)
    {
      file_ui_status_label.setText("Select a file to overwrite, or type a new name:");
      refreshFileList();
      new_filename_field.show();
      new_filename_field.setText(data.name);
      new_filename_field.setFocus(true);
      create_bt.show();
      cancel_bt.show();
    } else if (new_state == FILE_UI_CONFIRM_OVERWRITE)
    {
      file_ui_status_label.setText("Overwrite \"" + pending_overwrite_name + "\" ?");
      confirm_overwrite_bt.show();
      cancel_bt.show();
    }
  }

  // Lists sub-folders and .json files directly inside Settings/current_relpath (never
  // outside Settings/), folders first, both alphabetical (case-insensitive), and
  // fills the fixed button pool for the current page. Called on entering
  // LOAD_PICK/SAVE_PICK and again after navigating a folder/page, WITHOUT going
  // through enterState() (so status label / textfield visibility stay as they are).
  void refreshFileList()
  {
    ArrayList<String> dirs = new ArrayList<String>();
    ArrayList<String> files = new ArrayList<String>();

    File dir = new File(sketchPath("Settings"), current_relpath);
    File[] entries = dir.exists() ? dir.listFiles() : null;
    if (entries != null)
    {
      for (File f : entries)
      {
        if (f.isDirectory())
          dirs.add(f.getName());
        else if (f.getName().toLowerCase(Locale.US).endsWith(".json"))
          files.add(f.getName());
      }
    }
    Collections.sort(dirs, String.CASE_INSENSITIVE_ORDER);
    Collections.sort(files, String.CASE_INSENSITIVE_ORDER);

    ArrayList<String> combined = new ArrayList<String>();
    ArrayList<Boolean> combined_is_dir = new ArrayList<Boolean>();
    for (String d : dirs) {
      combined.add(d);
      combined_is_dir.add(true);
    }
    for (String f : files) {
      combined.add(f);
      combined_is_dir.add(false);
    }

    int total = combined.size();
    int start = file_list_page * MAX_FILE_SLOTS;

    for (int i = 0; i < MAX_FILE_SLOTS; i++)
    {
      int srcIdx = start + i;
      if (srcIdx < total)
      {
        String name = combined.get(srcIdx);
        boolean is_dir = combined_is_dir.get(srcIdx);
        file_slot_name[i] = name;
        file_slot_is_dir[i] = is_dir;
        file_slot_buttons[i].setLabel(is_dir ? (name + "/") : name);
        file_slot_buttons[i].show();
      } else
      {
        file_slot_name[i] = null;
        file_slot_buttons[i].hide();
      }
    }

    if (current_relpath.length() == 0)
      up_dir_bt.hide();
    else
      up_dir_bt.show();

    if (file_list_page > 0)
      prev_page_bt.show();
    else
      prev_page_bt.hide();

    if (start + MAX_FILE_SLOTS < total)
      next_page_bt.show();
    else
      next_page_bt.hide();
  }

  void onFileSlotClicked(int i)
  {
    String name = file_slot_name[i];
    if (name == null)
      return;

    if (file_slot_is_dir[i])
    {
      if (shouldSkipDuplicateNavAction())
      {
        println("[FileUI] ignoring re-entrant folder click this frame (i=" + i + ")");
        return;
      }
      current_relpath = (current_relpath.length() == 0) ? name : current_relpath + "/" + name;
      file_list_page = 0;
      pending_refresh = true;
      return;
    }

    if (file_ui_state == FILE_UI_LOAD_PICK)
    {
      executeLoad(name);
    } else if (file_ui_state == FILE_UI_SAVE_PICK)
    {
      pending_overwrite_name = name;
      enterState(FILE_UI_CONFIRM_OVERWRITE);
    }
  }

  // Blocks a second navigation action (folder click / up / prev / next) dispatched
  // within the same Processing frame - a real distinct user click can never land in
  // the same frame as another (frames are ~16ms apart), so this only ever catches
  // the ControlP5 ghost re-dispatch, never a legitimate fast click.
  boolean shouldSkipDuplicateNavAction()
  {
    if (frameCount == last_nav_action_frame)
      return true;
    last_nav_action_frame = frameCount;
    return false;
  }

  void onUpDir()
  {
    if (shouldSkipDuplicateNavAction())
    {
      println("[FileUI] ignoring re-entrant up-dir click this frame");
      return;
    }
    int idx = current_relpath.lastIndexOf('/');
    current_relpath = (idx < 0) ? "" : current_relpath.substring(0, idx);
    file_list_page = 0;
    pending_refresh = true;
  }

  void onPrevPage()
  {
    if (shouldSkipDuplicateNavAction())
      return;
    if (file_list_page > 0)
    {
      file_list_page--;
      pending_refresh = true;
    }
  }

  void onNextPage()
  {
    if (shouldSkipDuplicateNavAction())
      return;
    file_list_page++;
    pending_refresh = true;
  }

  // ControlP5 appears to re-evaluate a click within the same dispatch pass if the
  // button under the cursor gets relabeled synchronously inside its own click
  // handler (confirmed empirically: navigating into a folder immediately re-fired
  // a second click on whatever file now occupies that same slot). Deferring the
  // actual relabeling to the next draw() frame - after ControlP5 has fully finished
  // dispatching the current click - avoids that re-entrant ghost click entirely.
  void draw()
  {
    if (pending_refresh)
    {
      pending_refresh = false;
      refreshFileList();
    }
  }

  void onCreateNewFile()
  {
    handleNewFilenameSubmitted(new_filename_field.getText());
  }

  void handleNewFilenameSubmitted(String raw)
  {
    // Guards against a duplicate submit: ControlP5's Textfield appears to re-fire its
    // submit event when it loses focus, which happens right after a successful save
    // hides it (enterState(FILE_UI_NORMAL)) - without this guard, that second,
    // stale event would run again, now find the just-created file, and immediately
    // ask to confirm overwriting it. Only meaningful to process while still in
    // FILE_UI_SAVE_PICK.
    if (file_ui_state != FILE_UI_SAVE_PICK)
      return;

    String trimmed = (raw == null) ? "" : raw.trim();
    if (trimmed.length() == 0)
    {
      file_ui_status_label.setText("Enter a file name.");
      return;
    }
    if (trimmed.matches(".*[\\\\/:*?\"<>|].*"))
    {
      file_ui_status_label.setText("Invalid character in file name.");
      return;
    }

    String base = trimmed.toLowerCase(Locale.US).endsWith(".json")
      ? trimmed.substring(0, trimmed.length() - 5) : trimmed;
    String filename = base + ".json";

    File target = new File(new File(sketchPath("Settings"), current_relpath), filename);
    if (target.exists())
    {
      pending_overwrite_name = filename;
      enterState(FILE_UI_CONFIRM_OVERWRITE);
    } else
    {
      executeSave(filename);
    }
  }

  void onConfirmOverwrite()
  {
    if (pending_overwrite_name != null)
      executeSave(pending_overwrite_name);
  }

  // Cancel out of a confirm step goes back to the file list (keeps current_relpath),
  // not all the way out - so picking the wrong file to overwrite doesn't throw away
  // the folder you were browsing. Cancel out of LOAD_PICK/SAVE_PICK itself goes to
  // NORMAL, the only other reachable state.
  void onCancel()
  {
    if (file_ui_state == FILE_UI_CONFIRM_OVERWRITE)
      enterState(FILE_UI_SAVE_PICK);
    else
      enterState(FILE_UI_NORMAL);
  }

  void executeLoad(String filename)
  {
    String path = new File(new File(sketchPath("Settings"), current_relpath), filename).getAbsolutePath();
    data.LoadSettings(path);
    dataGui.setGUIValues();
    enterState(FILE_UI_NORMAL);
  }

  void executeSave(String filename)
  {
    String path = new File(new File(sketchPath("Settings"), current_relpath), filename).getAbsolutePath();
    data.SaveSettings(path);
    setGUIValues();
    enterState(FILE_UI_NORMAL);
  }

  // Routes clicks from the shared file-slot button pool (and the new-filename
  // Textfield's Enter-to-submit event) by controller identity, since plugTo() only
  // supports one fixed method per controller and these are reused across refreshes.
  // Also enforces the clip aspect-ratio lock (see applyAspectRatioFromWidth/Height):
  // dragging clip_width/clip_height recomputes the other slider when a ratio is
  // active, and picking a new ratio snaps height to the current width. Everything
  // else (Load/Save/Save as/Export/Reset Scale/../Prev/Next/Create/confirm/cancel,
  // paper_format/margin radios) falls through to the inherited tab-filtered
  // onUIChanged() behavior unchanged.
  public void controlEvent(ControlEvent theEvent)
  {
    if (theEvent.isController())
    {
      Controller c = theEvent.getController();
      for (int i = 0; i < MAX_FILE_SLOTS; i++)
      {
        if (c == file_slot_buttons[i])
        {
          onFileSlotClicked(i);
          return;
        }
      }
      if (c == new_filename_field)
      {
        handleNewFilenameSubmitted(new_filename_field.getText());
        return;
      }
      if (show_clipping && c == clip_slider_width && !applying_aspect_ratio)
      {
        applyAspectRatioFromWidth();
      } else if (show_clipping && c == clip_slider_height && !applying_aspect_ratio)
      {
        applyAspectRatioFromHeight();
      } else if (show_clipping && c == clip_landscape_toggle)
      {
        // Simply swap width/height rather than recompute from the ratio: a
        // ratio-locked pair already satisfies width/height = r or 1/r, so swapping
        // them directly always lands on the other orientation exactly - no
        // dependency on exactly when ControlP5 updates the bound clip_landscape
        // field relative to this event firing (recomputing via
        // getClipAspectRatioValue() here intermittently used a stale value and
        // needed an extra slider touch to actually take effect).
        swapClipWidthHeight();
      }
    }

    super.controlEvent(theEvent);

    if (show_clipping && theEvent.isGroup() && theEvent.getGroup() == clip_aspect_radio)
    {
      // super.controlEvent() (above) has already set page_data.clip_aspect_ratio to
      // the newly picked mode - snap height to match the current width under it.
      applyAspectRatioFromWidth();
    }
  }

  // clip_width is authoritative: recomputes clip_height to match the active ratio.
  void applyAspectRatioFromWidth()
  {
    float ratio = getClipAspectRatioValue(page_data.clip_aspect_ratio, page_data.clip_landscape);
    if (ratio <= 0)
      return;
    applying_aspect_ratio = true;
    clip_slider_height.setValue(page_data.clip_width / ratio);
    applying_aspect_ratio = false;
  }

  // clip_height is authoritative: recomputes clip_width to match the active ratio.
  void applyAspectRatioFromHeight()
  {
    float ratio = getClipAspectRatioValue(page_data.clip_aspect_ratio, page_data.clip_landscape);
    if (ratio <= 0)
      return;
    applying_aspect_ratio = true;
    clip_slider_width.setValue(page_data.clip_height * ratio);
    applying_aspect_ratio = false;
  }

  // Swaps clip_width/clip_height directly - used when the Landscape toggle flips.
  void swapClipWidthHeight()
  {
    float w = page_data.clip_width;
    float h = page_data.clip_height;
    applying_aspect_ratio = true;
    clip_slider_width.setValue(h);
    clip_slider_height.setValue(w);
    applying_aspect_ratio = false;
  }

  void ExportSVGProcessing()
  {
    // Force Processing's SVG renderer (legacy fallback)
    _record = true;
    data.changed = true;
    mode = 2;
  }

  void ExportSVG()
  {
    if (export_busy_guard != null && export_busy_guard.isBusy()) {
      println("[SVG direct] Export refused: still computing.");
      return;
    }

    boolean use_shapes = export_shapes != null && export_shapes.totalCount() > 0;
    boolean use_group  = export_group  != null && export_group.size()  > 0;

    if (use_shapes || use_group) {
      println("[SVG direct] Export with custom writer (paper=" +
        (page_data.paper_format == PAPER_NONE ? "none, px mode" : "format " + page_data.paper_format) + ")");
      String name = data.name.equals("") ? "default" : data.name;
      String fmt  = "";
      switch (page_data.paper_format) {
      case PAPER_A4:
        fmt = "_A4";
        break;
      case PAPER_A3:
        fmt = "_A3";
        break;
      case PAPER_A2:
        fmt = "_A2";
        break;
      case PAPER_RAISIN:
        fmt = "_Raisin";
        break;
      }
      String filepath = sketchPath("Export/" + name + fmt + "_"
        + year() + "-" + month() + "-" + day()
        + "_" + hour() + "-" + minute() + "-" + second() + ".svg");
      println("[SVG] " + filepath);
      long t0 = System.currentTimeMillis();
      if (use_shapes) writeSVGDirect(filepath, export_shapes, page_data.paper_format);
      else            writeSVGDirect(filepath, export_group, page_data.paper_format);
      last_save_duration = (int)(System.currentTimeMillis() - t0);
      println("[SVG] Export completed in " + StringUtils.formatDuration(last_save_duration));
    } else {
      println("[SVG Processing] No export data connected - fallback to Processing renderer");
      // Fallback: Processing's SVG renderer (+ post-process)
      _record = true;
      data.changed = true;
      mode = 2;
    }
  }

  void Reset_Scale()
  {
    scale_slider.setValue(0);
  }

  // Update export scale based on bounding box and paper format
  void updateExportScale(BoundingBox bbox)
  {
    last_bbox = bbox;
    export_landscape = (bbox != null && bbox.getWidth() > bbox.getHeight());
    export_scale = calculateExportScale(bbox, data.page.paper_format, data.page.margin);
    // println("[FileUI] updateExportScale -> scale=" + export_scale + " landscape=" + export_landscape + " paper=" + data.page.paper_format);
  }
}

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

boolean _record = false;
boolean stop_compute = false; // interrompt le calcul en cours lors d'un load/save
int mode  = 0;
long _record_start_millis = 0;

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
  data.changed = true;
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

    float newWidth = width;
    float newheight = height;

    // Si un format papier est sélectionné, utiliser ses dimensions pour le canvas SVG/PDF
    // L'orientation de la page suit le ratio du dessin (pas de rotation du contenu)
    if (data.page.paper_format != PAPER_NONE) {
      float[] paper_dims_mm = getPaperDimensions(data.page.paper_format, file_ui.export_landscape);
      newWidth = mmToSvgPx(paper_dims_mm[0]);
      newheight = mmToSvgPx(paper_dims_mm[1]);
    }

    // Add paper format to filename
    String format_suffix = "";
    switch(data.page.paper_format) {
    case PAPER_A4:
      format_suffix = "_A4";
      break;
    case PAPER_A3:
      format_suffix = "_A3";
      break;
    case PAPER_A2:
      format_suffix = "_A2";
      break;
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

    println("Saving file in progress... please wait. " + export_fileName);
    _record_start_millis = System.currentTimeMillis();

    current_graphics.beginDraw();

    // Calculate active scale for export
    float active_scale = (data.page.paper_format != PAPER_NONE) ? file_ui.export_scale : data.page.global_scale;
    printExportDebugInfo(file_ui.last_bbox, active_scale, data.page.paper_format);

    current_graphics.pushMatrix();
    current_graphics.strokeWeight(data.style.lineWidth * active_scale);
    // Centrage sur le canvas papier : le dessin est en coordonnées centrées sur (0,0)
    if (data.page.paper_format != PAPER_NONE) {
      current_graphics.translate(newWidth / 2, newheight / 2);
    }
    current_graphics.scale(active_scale, active_scale);
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
    int duration = (int)(System.currentTimeMillis() - _record_start_millis);
    file_ui.last_save_duration = duration;
    println("Save completed in " + StringUtils.formatDuration(duration));
    if (mode == 2) {
      postProcessSVGForPlotter(export_fileName, data.page.paper_format, file_ui.export_landscape);
    }
    _record = false;
  } else {
    popMatrix();  // Close the pushMatrix from start_draw
  }
}
