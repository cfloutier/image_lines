// Default swatch palette - a plain sketch-global (not a ColorGroup field)
// so ColorChooserPopup's palette registry can reference the exact same
// array under the name "Default" instead of duplicating it. Can't be a
// `static final` inside ColorGroup - Java disallows static members in a
// non-static inner class, and ColorGroup can't be static (it instantiates
// ColorButton, which needs an enclosing sketch instance for cp5).
int[][] DEFAULT_COLOR_PALETTE = {
  { 255, 255, 255  }, // white
  { 0, 0, 0  }, // black

  { 255, 205, 210 }, // rose

  { 81, 46, 95   },
  { 155, 89, 182  },
  { 235, 222, 240 },
  { 21, 67, 96 },
  { 127, 179, 213 },
  { 33, 97, 140 },
  { 93, 173, 226 },
  { 14, 98, 81 },
  { 39, 174, 96 },
  { 88, 214, 141 },

  { 255, 245, 157 }, // jaunes
  { 253, 216, 53  },

  { 251, 140, 0}, // orange
  { 255, 87, 34 }, //
  {  191, 54, 12   }, // rouges
  { 100, 30, 22 },
  { 192, 57, 43 },
  { 148, 49, 38  },

  { 93, 64, 55  }, //marrons
  { 62, 39, 35  },


  { 174, 182, 191 }, // gris
  { 44, 62, 80 },
  { 23, 32, 42 },
  { 10, 14, 19 }
};

// 20-step rainbow, evenly spaced hues (18 degree steps) at S=85%, B=95% -
// vivid but not harsh. Registered explicitly per-project (unlike
// DEFAULT_COLOR_PALETTE, which ColorChooserPopup falls back to automatically
// if nothing was registered) via colorPopup.registerPalette("Rainbow",
// RAINBOW_COLOR_PALETTE) in setupControls().
int[][] RAINBOW_COLOR_PALETTE = {
  { 255, 255, 255 }, // white
  { 0, 0, 0       }, // black

  { 242, 36, 36  }, // red
  { 242, 98, 36  },
  { 242, 160, 36 },
  { 242, 222, 36 }, // yellow
  { 201, 242, 36 },
  { 139, 242, 36 },
  { 78, 242, 36  },
  { 36, 242, 57  }, // green
  { 36, 242, 119 },
  { 36, 242, 180 },
  { 36, 242, 242 }, // cyan
  { 36, 180, 242 },
  { 36, 119, 242 },
  { 36, 57, 242  }, // blue
  { 78, 36, 242  },
  { 139, 36, 242 },
  { 201, 36, 242 }, // purple
  { 242, 36, 222 },
  { 242, 36, 160 },
  { 242, 36, 98  }
};

// POSCA PC-1M (0.7mm) marker ink colors, read off the manufacturer's color
// chart - RGB values are a visual approximation of the printed chart, not a
// sampled/calibrated source, so nudge them if a swatch looks off once seen
// next to the real pens. Number in each comment is POSCA's own color index.
int[][] POSCA_COLOR_PALETTE = {
  { 255, 255, 255 }, // White, 1
  { 25, 25, 25    }, // Black, 24

  { 225, 195, 224 }, // Light Pink, 51
  { 240, 222, 200 }, // Beige, 45
  { 240, 235, 200 }, // Ivory, 46
  { 10, 95, 150   }, // Blue, 33
  { 135, 60, 150  }, // Violet, 12
  { 175, 105, 60  }, // Brown, 21

  { 230, 90, 150  }, // Pink, 13
  { 245, 175, 115 }, // Light Orange, 54
  { 245, 195, 70  }, // Straw Yellow, 73
  { 95, 190, 230  }, // Light Blue, 8
  { 180, 180, 180 }, // Silver, 26

  { 205, 30, 55   }, // Red, 15
  { 240, 150, 25  }, // Bright Yellow, 3
  { 250, 200, 15  }, // Yellow, 2
  { 10, 130, 60   }, // Green, 6
  { 90, 100, 110  }, // Slate Grey, 61

  { 140, 40, 60   }, // Red Wine, 60
  { 240, 130, 20  }, // Orange, 4
  { 180, 145, 30  }, // Gold, 25
  { 130, 220, 170 }  // Light Green, 5
};

// Stabilo point 88 fineliner ink colors, read off a manufacturer color chart
// (Huanyo Art Supplies reference sheet) - same caveat as POSCA_COLOR_PALETTE:
// a visual approximation of the printed/screen chart, not calibrated/sampled,
// nudge values if a swatch looks off next to the real pens. Number in each
// comment is Stabilo's own color index.
int[][] STABILO88_COLOR_PALETTE = {
  { 255, 255, 255 }, // white (not part of the point 88 range, added for consistency)
  { 20, 20, 25    }, // black, 46

  { 255, 235, 0   }, // neon yellow, 024
  { 0, 174, 239   }, // neon blue, 031
  { 85, 184, 56   }, // neon green, 033
  { 240, 130, 130 }, // neon red, 040
  { 247, 148, 30  }, // neon orange, 054
  { 236, 0, 140   }, // neon pink, 056
  { 159, 208, 224 }, // ice blue, 11
  { 0, 166, 147   }, // ice-green, 13
  { 126, 188, 137 }, // light emerald, 16
  { 222, 178, 202 }, // heliotrope, 17
  { 155, 27, 90   }, // purple, 19
  { 29, 34, 92    }, // nightblue, 22

  { 240, 230, 140 }, // lemon yellow, 24
  { 240, 170, 145 }, // apricot, 26
  { 240, 165, 185 }, // light pink, 29
  { 235, 110, 60  }, // pale vermillion, 30
  { 30, 110, 190  }, // light blue, 31
  { 25, 70, 160   }, // ultramarine, 32
  { 135, 190, 65  }, // apple green, 33
  { 30, 120, 60   }, // green, 36
  { 170, 75, 55   }, // sanguine, 38
  { 225, 30, 40   }, // red, 40
  { 25, 65, 145   }, // blue, 41
  { 95, 180, 75   }, // light green, 43

  { 250, 190, 30  }, // yellow, 44
  { 95, 60, 45    }, // brown, 45
  { 235, 90, 65   }, // light red, 48
  { 200, 20, 75   }, // crimson, 50
  { 0, 155, 160   }, // turquoise, 51
  { 0, 95, 75     }, // pine green, 53
  { 240, 130, 30  }, // orange, 54
  { 110, 40, 140  }, // violet, 55
  { 230, 30, 130  }, // pink, 56
  { 55, 175, 220  }, // azure, 57
  { 160, 45, 150  }, // lilac, 58

  { 180, 155, 200 }, // light lilac, 59
  { 75, 90, 45    }, // olive green, 63
  { 90, 65, 50    }, // umber, 65
  { 140, 80, 55   }, // sienna, 75
  { 200, 155, 105 }, // light ochre, 88
  { 175, 100, 35  }, // dark ochre, 89
  { 190, 195, 200 }, // light grey, 94
  { 130, 140, 145 }, // medium cold grey, 95
  { 80, 90, 100   }, // dark grey, 96
  { 55, 60, 70    }, // deep cold grey, 97
  { 35, 60, 85    }  // payne's grey, 98
};

// Accessor for a color-holding field - lets ColorGroup/ColorChooserPopup
// read the current value (e.g. to tint a trigger button) and write a picked
// swatch color straight back into whichever plain `color` field owns it,
// without a wrapper object or reflection. Implemented anonymously at each
// addColorGroup()/addColorChooser() call site.
interface ColorSetter
{
  color getColor();
  void setColor(color c);
}

class ColorButton
{
  color col;

  Button bt = null;
  ColorGroup group;

  ColorButton(color col)
  {
    this.col = col;
  }

  void init(GUIPanel panel, ColorGroup group)
  {
    bt = cp5.addButton("colorbt"+ indexControler)
      .setPosition(panel.xPos, panel.yPos)
      .setSize(20, 20)
      .setLabel("")
      .moveTo(panel.pageName)
      .setColorBackground(col);

    indexControler++;
    panel.xPos += 22;

    bt.plugTo(this, "onClic");
    this.group = group;
  }

  void onClic()
  {
    group.target.setColor(this.col);
  }
}

class ColorGroup
{
  ColorSetter target;
  String name;
  ArrayList<ColorButton> buttons = new ArrayList<ColorButton>();

  int[][] colors = DEFAULT_COLOR_PALETTE;

  ColorGroup(ColorSetter target, String name)
  {
    this.target = target;
    this.name = name;
  }

  void Init(GUIPanel panel)
  {
    panel.addLabel(name);

    for (int i = 0; i< colors.length; i++) {
      if (i != 0 && (i%8) == 0)
      {
        panel.yPos += 25;
        panel.xPos = StartX;
      }

      int[] colorValues = colors[i];
      ColorButton b = new ColorButton(color(colorValues[0], colorValues[1], colorValues[2]));
      b.init(panel, this);
      buttons.add(b);
    }

    panel.yPos += 25;
    panel.xPos = StartX;
  }
}
