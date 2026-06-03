
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
    group.colorRef.col = this.col;
  }
}

class ColorGroup
{
  ColorRef colorRef;
  String name;

  int[][] colors = {
    { 255, 255, 255  },

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
    { 10, 14, 19 },
    { 0, 0, 0  }
  };

  ColorGroup(ColorRef colorRef, String name)
  {
    this.colorRef = colorRef;
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
      new ColorButton(color(colorValues[0], colorValues[1], colorValues[2])).init(panel, this);
    }

    panel.yPos += 25;
    panel.xPos = StartX;
  }
}

class ColorRef
{
  ColorRef(color col, String name)
  {
    this.col = col;
    this.name = name;
  }

  color col;
  String name;

  void LoadJson(JSONObject src)
  {
    col = src.getInt(name, col);
  }

  void SaveJson(JSONObject dest)
  {
    dest.setInt(name, col);
  }
}
