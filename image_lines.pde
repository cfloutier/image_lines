import java.awt.Image;
// trace parallels line on pictures

/*
 *
 * This is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * http://creativecommons.org/licenses/LGPL/2.1/
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

import controlP5.*;
import processing.pdf.*;
import processing.dxf.*;
import processing.svg.*;

ImgProcData data;
DataGUI dataGui;

MultiLinesGenerator generator;
ThresholdFilter threshold_filter;

//SourceFiles sourceFilesGui;
PGraphics current_graphics;

ControlP5 cp5;

void setup()
{
  size(1200, 800);
  pixelDensity(1);

  data = new ImgProcData();
  dataGui = new DataGUI(data);

  generator = new MultiLinesGenerator(data.lines);

  generator.straight = dataGui.lines_ui.straightGroup;
  generator.circle = dataGui.lines_ui.circleGroup;
  generator.sinus = dataGui.lines_ui.sinusGroup;


  threshold_filter = new ThresholdFilter(data.lines, data.threshold);

  setupControls();

  data.LoadSettings("./Settings/test_lines.json");

  dataGui.setGUIValues();

  surface.setResizable(true);
}

void setupControls()
{
  cp5 = new ControlP5(this);
  cp5.getTab("default").setLabel("Hide GUI");

  // addFileTab();
  dataGui.Init();
}

void draw()
{
  start_draw();

  data.image.buildTransformedImage();
  if (data.image.draw)
    data.image.draw(data.image.imageAlpha);

  if (data.any_change())
  {
    generator.buildLines();
    threshold_filter.buildLines(generator, data.image);
    data.reset_all_changes();
  }

  strokeWeight(data.style.lineWidth);
  stroke(data.style.lineColor.col);

  smooth();
  if (data.lines.draw)
    generator.draw();

  if (data.threshold.draw)
    threshold_filter.draw();

  end_draw();
}
