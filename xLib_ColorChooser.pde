// Click handler for a GUIPanel.addColorChooser() trigger button - a named
// class rather than an anonymous one plugTo()'d inline, since Processing's
// preprocessor did not like an anonymous class with a method body used
// directly as a plugTo() argument. Also holds the trigger's own swatchButton
// so ColorChooserPopup can re-tint it after a pick (nothing else is watching
// the underlying color field for changes).
class ColorChooserTrigger
{
  String tabName;
  ColorSetter target;
  Button swatchButton;

  ColorChooserTrigger(String tabName, ColorSetter target, Button swatchButton)
  {
    this.tabName = tabName;
    this.target = target;
    this.swatchButton = swatchButton;
  }

  void onClic()
  {
    colorPopup.show(this);
  }

  void apply(color c)
  {
    target.setColor(c);
    swatchButton.setColorBackground(c);
  }
}

// A named set of swatch colors offered in the ColorChooserPopup (e.g.
// "Default", "Rainbow", ...). Just a name + the RGB triples - rendering is
// still entirely ColorGroup/ColorButton, one ColorGroup per palette.
class ColorPalette
{
  String name;
  int[][] colors;

  ColorPalette(String name, int[][] colors)
  {
    this.name = name;
    this.colors = colors;
  }
}

// Click handler for a palette-switcher button in the popup.
class PaletteSwitcher
{
  ColorChooserPopup popup;
  int index;

  PaletteSwitcher(ColorChooserPopup popup, int index)
  {
    this.popup = popup;
    this.index = index;
  }

  void onClic()
  {
    popup.showPalette(index);
  }
}

// Click handler for the "Custom" mode button (HSB square + hue bar).
class CustomModeButton
{
  ColorChooserPopup popup;

  CustomModeButton(ColorChooserPopup popup)
  {
    this.popup = popup;
  }

  void onClic()
  {
    popup.showCustom();
  }
}

// Click handler for Custom mode's "OK" button.
class OkButton
{
  ColorChooserPopup popup;

  OkButton(ColorChooserPopup popup)
  {
    this.popup = popup;
  }

  void onClic()
  {
    popup.close();
  }
}

// Value-changed listeners for the custom picker's two sliders. Named classes
// rather than anonymous ones, matching PaletteSwitcher/CustomModeButton -
// ColorButton.onClic() already proves .plugTo(obj, "methodName") works for a
// no-arg method on a Button; Slider/Slider2D aren't proven the same way
// anywhere else in this codebase, so this is the one part of this feature
// that hadn't been empirically confirmed before first use.
class HueSliderListener
{
  ColorChooserPopup popup;

  HueSliderListener(ColorChooserPopup popup)
  {
    this.popup = popup;
  }

  void onChange()
  {
    popup.onHueChanged();
  }
}

class SVSliderListener
{
  ColorChooserPopup popup;

  SVSliderListener(ColorChooserPopup popup)
  {
    this.popup = popup;
  }

  void onChange()
  {
    popup.onSVChanged();
  }
}

// ColorChooserPopup - shared swatch-grid popup, opened from a small trigger
// button on any tab (GUIPanel.addColorChooser()) instead of laying the full
// grid out inline (that's still what ColorGroup/addColorGroup does, unchanged).
//
// Fakes a modal the same way xLib_FileUI.pde's Load/Save browser does: parks
// its controls on ControlP5's built-in "default" tab and calls
// Tab.bringToFront() to show/hide, no backdrop, no click-blocking - clicking
// another tab header also closes it, same as the file picker.
//
// The method that opens the popup is named show(), not open() - naming it
// open() caused Processing's preprocessor to throw a "Syntax Error - Error
// on parameter or method declaration" at the *call site* (not a real Java
// error, and not reproducible with any other method name tried) - some kind
// of reserved/special-cased handling of "open" in Processing's own PDE
// grammar. Confirmed empirically: renaming the method was the only thing
// that fixed it. Avoid a method literally named `open` anywhere in xLib.
//
// One instance for the whole sketch (declared as the global `colorPopup`
// in each project's main .pde, next to `cp5` - can't be a static holder like
// GUIPanel's LabelsHandler since, unlike Textlabel, ColorGroup/GUIPanel are
// sketch-inner classes and need an enclosing instance). Reused by every
// addColorChooser() trigger; only one can be open at a time, which is fine
// since only one color is ever being picked.
//
// Multiple palettes: one ColorGroup per registered ColorPalette, all built
// (hidden) up front in ensureInit(), same hide-all/show-relevant technique
// as the palettes themselves and as xLib_FileUI.pde's picker states. A row
// of small named buttons above the grid switches which one is visible.
//
// Custom mode: a saturation/brightness square (Slider2D) + a hue bar
// (Slider). Drag interaction comes for free from ControlP5 (no custom
// mousePressed() plumbing needed), but the gradient BACKGROUND does not:
// Controller.setImages() is a no-op for these two controller types.
// Confirmed by inspecting controlP5.jar directly - Controller.class embeds
// the string "Image-based or custom displays are not yet implemented for
// this type of controller. (" and Slider/Slider2D's own view classes
// (SliderView/Slider2DView) only ever call fill()/rect(), never image() -
// setImages() silently does nothing on these two. Worked around by drawing
// the gradient ourselves with a plain image() call in spiral.pde's draw()
// (drawCustomBackgrounds(), called after end_draw() so it's in absolute
// screen coordinates, matching where ControlP5 controls sit), *underneath*
// where ControlP5 renders its controls a moment later - with both sliders'
// own background set fully transparent (alpha 0) via setColorBackground()
// so their flat fill() doesn't paint over the image. The crosshair (drawn
// with the foreground/active color, left opaque) still shows on top.
//
// Not one of the indexed palettes/_groups (a Slider/Slider2D pair isn't a
// ColorGroup) - tracked as a separate _customMode boolean instead.
//
// Declared `public`: registerMethod("draw", colorPopup) needs external
// reflection (processing.core.PApplet$RegisteredMethods, no setAccessible())
// to call its public draw() - Java's IllegalAccessException fires on that
// even for a public *method* if the enclosing class isn't public too, and
// this one wasn't. ("cannot access a member ... with modifiers 'public'" is
// Java's confusing way of saying the *class* needs to be public, not that
// the public modifier itself is somehow wrong.)
public class ColorChooserPopup
{
  ArrayList<ColorPalette> palettes = new ArrayList<ColorPalette>();
  ArrayList<ColorGroup> _groups = new ArrayList<ColorGroup>();
  ArrayList<Button> _paletteButtons = new ArrayList<Button>();
  int _activePalette = 0;
  boolean _customMode = false;
  Button customButton;
  Button okButton;
  Slider2D svSlider;
  Slider hueSlider;
  PImage _svImage;
  PImage _hueImage;
  float _svX, _svY, _hueX, _hueY;
  ColorChooserTrigger _trigger;
  boolean _initialized = false;
  boolean _visible = false;

  color PALETTE_ACTIVE_COLOR   = color(70, 130, 220);
  color PALETTE_INACTIVE_COLOR = color(80);

  static final int SV_SIZE = 200;
  static final int HUE_WIDTH = 30;

  // Call before the popup is first shown (e.g. right after `new
  // ColorChooserPopup()`) to add palettes beyond the built-in "Default" one.
  void registerPalette(String name, int[][] colors)
  {
    palettes.add(new ColorPalette(name, colors));
  }

  void ensureInit()
  {
    if (_initialized) return;
    _initialized = true;

    if (palettes.size() == 0)
      registerPalette("Default", DEFAULT_COLOR_PALETTE);

    float switcherX = StartX;
    float switcherY = StartY;

    for (int i = 0; i < palettes.size(); i++)
    {
      Button pb = cp5.addButton("colorpalette" + i)
        .setLabel(palettes.get(i).name)
        .setPosition(switcherX, switcherY)
        .setSize(90, 20)
        .moveTo("default");
      switcherX += 95;
      _paletteButtons.add(pb);
      pb.plugTo(new PaletteSwitcher(this, i), "onClic");
    }

    customButton = cp5.addButton("colorcustom")
      .setLabel("Custom")
      .setPosition(switcherX, switcherY)
      .setSize(90, 20)
      .moveTo("default");
    customButton.plugTo(new CustomModeButton(this), "onClic");

    float gridY = switcherY + 30;

    ColorSetter sink = new ColorSetter()
    {
      public color getColor() { return 0; } // unused - this ColorSetter is a write-only sink
      public void setColor(color c) { pick(c); }
    };

    for (ColorPalette p : palettes)
    {
      ColorGroup g = new ColorGroup(sink, "");
      g.colors = p.colors;

      GUIPanel gridPanel = new GUIPanel("default", null);
      gridPanel.xPos = StartX;
      gridPanel.yPos = gridY;
      g.Init(gridPanel);

      for (ColorButton b : g.buttons)
        b.bt.hide();
      _groups.add(g);
    }

    for (Button pb : _paletteButtons)
      pb.hide();
    customButton.hide();

    _svX = StartX;
    _svY = gridY;
    _hueX = StartX + SV_SIZE + 10;
    _hueY = gridY;

    svSlider = cp5.addSlider2D("colorsv")
      .setLabel("Color")
      .setPosition(_svX, _svY)
      .setSize(SV_SIZE, SV_SIZE)
      .setMinMax(0, 0, 1, 1)
      .setColorBackground(color(0, 0, 0, 0))
      .moveTo("default");
    svSlider.enableCrosshair();
    _svImage = buildSVImage(0, SV_SIZE, SV_SIZE);
    svSlider.plugTo(new SVSliderListener(this), "onChange");
    svSlider.hide();

    // Range given as (360, 0) rather than (0, 360) - ControlP5 maps a
    // vertical slider as "drag up = value increases" regardless of range
    // direction, opposite of our hue image/tick (hue 0 at the top, 360 at
    // the bottom) - swapping min/max here inverts that mapping so dragging
    // down moves toward higher hue, matching the gradient and the tick.
    hueSlider = cp5.addSlider("colorhue")
      .setLabel("Hue")
      .setPosition(_hueX, _hueY)
      .setSize(HUE_WIDTH, SV_SIZE)
      .setRange(360, 0)
      .setColorBackground(color(0, 0, 0, 0))
      .moveTo("default");
    _hueImage = buildHueImage(HUE_WIDTH, SV_SIZE);
    hueSlider.plugTo(new HueSliderListener(this), "onChange");
    hueSlider.hide();

    // Custom mode has no discrete "pick" moment like a swatch click (you
    // drag hue and saturation/brightness separately, often several times) -
    // an explicit OK is how you say "done" and close the popup, rather than
    // relying on switching tabs.
    okButton = cp5.addButton("colorok")
      .setLabel("OK")
      .setPosition(_svX, _svY + SV_SIZE + 30)
      .setSize(90, 20)
      .moveTo("default");
    okButton.plugTo(new OkButton(this), "onClic");
    okButton.hide();
  }

  // Called from spiral.pde's draw(), after end_draw() (absolute screen
  // coords, matching where the ControlP5 controls themselves sit) - draws
  // the gradient images setImages() can't apply to Slider/Slider2D (see
  // class comment above). Must run before ControlP5's own post-draw pass
  // paints the (transparent-background) sliders/crosshair on top, which it
  // does automatically every frame regardless of this call. Gated on our
  // own _visible flag (set in show()/close()), not cp5.getTab("default")
  // .isActive() - that returned false here even while the popup was
  // visibly showing, so nothing ever got drawn.
  // Called via registerMethod("draw", colorPopup) in spiral.pde's
  // setupControls() - Processing invokes registered "draw" methods in
  // registration order, and ControlP5 registers its own during `new
  // ControlP5(this)`, so as long as we register after that (we do), this
  // fires *after* ControlP5's own controls have rendered, drawing our
  // gradient on top instead of underneath it. Must be `public` - unlike
  // ControlP5's plugTo() (which setAccessible(true)s before invoking),
  // Processing's own registerMethod reflection does not, and throws
  // IllegalAccessException on a package-private method.
  public void draw()
  {
    drawCustomBackgrounds();
  }

  // Draws the gradients, plus our own cursor markers - ControlP5's own
  // crosshair/value-fill (drawn earlier in the same frame, see draw() above)
  // end up completely covered by these images, same problem setImages() had,
  // just moved from "background invisible" to "cursor invisible". Cheaper to
  // draw a marker ourselves from the sliders' own current value than to try
  // to sandwich our image between ControlP5's background and foreground
  // passes (they're one atomic draw call, not interruptible from outside).
  void drawCustomBackgrounds()
  {
    if (!_customMode || !_visible) return;

    image(_svImage, _svX, _svY);
    image(_hueImage, _hueX, _hueY);

    float[] sv = svSlider.getArrayValue();
    float cx = _svX + sv[0] * SV_SIZE;
    float cy = _svY + sv[1] * SV_SIZE;
    noFill();
    rectMode(CENTER);
    stroke(0);
    strokeWeight(3);
    rect(cx, cy, 10, 10);
    stroke(255);
    strokeWeight(1);
    rect(cx, cy, 10, 10);
    rectMode(CORNER);

    float tickY = _hueY + (hueSlider.getValue() / 360.0) * SV_SIZE;
    stroke(0);
    strokeWeight(3);
    line(_hueX - 2, tickY, _hueX + HUE_WIDTH + 2, tickY);
    stroke(255);
    strokeWeight(1);
    line(_hueX - 2, tickY, _hueX + HUE_WIDTH + 2, tickY);
  }

  // colorMode() is global sketch state - every image builder here switches
  // to HSB just long enough to compute pixels, then restores RGB 0-255
  // immediately, since the rest of the app (palette arrays, style colors)
  // assumes RGB.
  PImage buildSVImage(float hue, int w, int h)
  {
    PImage img = createImage(w, h, RGB);
    colorMode(HSB, 360, 1, 1);
    img.loadPixels();
    for (int y = 0; y < h; y++)
      for (int x = 0; x < w; x++)
      {
        float sat = x / (float)(w - 1);
        float bri = 1 - y / (float)(h - 1);
        img.pixels[y * w + x] = color(hue, sat, bri);
      }
    img.updatePixels();
    colorMode(RGB, 255);
    return img;
  }

  PImage buildHueImage(int w, int h)
  {
    PImage img = createImage(w, h, RGB);
    colorMode(HSB, 360, 1, 1);
    img.loadPixels();
    for (int y = 0; y < h; y++)
    {
      float hue = 360 * y / (float)(h - 1);
      color c = color(hue, 1, 1);
      for (int x = 0; x < w; x++)
        img.pixels[y * w + x] = c;
    }
    img.updatePixels();
    colorMode(RGB, 255);
    return img;
  }

  void onHueChanged()
  {
    float hue = hueSlider.getValue();
    _svImage = buildSVImage(hue, SV_SIZE, SV_SIZE);
    applyCustomColor();
  }

  void onSVChanged()
  {
    applyCustomColor();
  }

  void applyCustomColor()
  {
    float hue = hueSlider.getValue();
    float[] sv = svSlider.getArrayValue();
    float sat = sv[0];
    float bri = 1 - sv[1];

    colorMode(HSB, 360, 1, 1);
    color c = color(hue, sat, bri);
    colorMode(RGB, 255);

    if (_trigger != null)
      _trigger.apply(c);
  }

  // Reads the trigger's current color and moves both sliders to match, so
  // switching into Custom mode starts from whatever color is already there
  // instead of wherever the sliders were last left.
  void syncFromCurrentColor()
  {
    if (_trigger == null) return;

    color c = _trigger.target.getColor();
    colorMode(HSB, 360, 1, 1);
    float h = hue(c);
    float s = saturation(c);
    float b = brightness(c);
    colorMode(RGB, 255);

    hueSlider.setValue(h);
    svSlider.setValue(s, 1 - b);
    _svImage = buildSVImage(h, SV_SIZE, SV_SIZE);
  }

  void showPalette(int idx)
  {
    hideCurrent();
    _customMode = false;
    _activePalette = idx;

    for (ColorButton b : _groups.get(_activePalette).buttons)
      b.bt.show();

    refreshHighlight();
  }

  void showCustom()
  {
    hideCurrent();
    _customMode = true;

    syncFromCurrentColor();

    svSlider.show();
    hueSlider.show();
    okButton.show();

    refreshHighlight();
  }

  void hideCurrent()
  {
    if (_customMode)
    {
      svSlider.hide();
      hueSlider.hide();
      okButton.hide();
    } else
    {
      for (ColorButton b : _groups.get(_activePalette).buttons)
        b.bt.hide();
    }
  }

  void refreshHighlight()
  {
    for (int i = 0; i < _paletteButtons.size(); i++)
      _paletteButtons.get(i).setColorBackground(!_customMode && i == _activePalette ? PALETTE_ACTIVE_COLOR : PALETTE_INACTIVE_COLOR);
    customButton.setColorBackground(_customMode ? PALETTE_ACTIVE_COLOR : PALETTE_INACTIVE_COLOR);
  }

  void show(ColorChooserTrigger trigger)
  {
    ensureInit();
    _trigger = trigger;
    _visible = true;

    for (Button pb : _paletteButtons)
      pb.show();
    customButton.show();

    if (_customMode)
      showCustom();
    else
      showPalette(_activePalette);

    cp5.getTab("default").bringToFront();
  }

  void pick(color c)
  {
    if (_trigger != null)
      _trigger.apply(c);
    close();
  }

  void close()
  {
    _visible = false;

    for (Button pb : _paletteButtons)
      pb.hide();
    customButton.hide();
    hideCurrent();

    if (_trigger != null)
      cp5.getTab(_trigger.tabName).bringToFront();
  }
}

// Creates the global `colorPopup` (still has to be declared per-project -
// `ColorChooserPopup colorPopup;` next to `cp5` - Java requires the field
// itself to exist in the sketch's own class) and registers the built-in
// palettes. Call once from setupControls(), right after
// `cp5 = new ControlP5(this);`.
void setupColorPopup()
{
  setupColorPopup(true);
}

// autoDraw=false skips registerMethod("draw", colorPopup) - use this in a
// P3D sketch (or anywhere else auto-registered draw callbacks run with GL
// state you don't control, see trace_3d.pde's drawControlP5()/cp5.setAutoDraw
// (false) for the exact same problem already solved for ControlP5's own
// rendering) and call `colorPopup.draw()` manually instead, at whatever
// point in your own draw loop has the right state (for trace_3d: right after
// cp5.draw() inside drawControlP5(), still inside the
// hint(DISABLE_DEPTH_TEST) bracket).
void setupColorPopup(boolean autoDraw)
{
  colorPopup = new ColorChooserPopup();
  colorPopup.registerPalette("Default", DEFAULT_COLOR_PALETTE);
  colorPopup.registerPalette("Rainbow", RAINBOW_COLOR_PALETTE);
  colorPopup.registerPalette("POSCA", POSCA_COLOR_PALETTE);
  colorPopup.registerPalette("Stabilo 88", STABILO88_COLOR_PALETTE);
  if (autoDraw)
    registerMethod("draw", colorPopup);
}
