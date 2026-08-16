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
  surface.setResizable(true);

  data = new ImgProcData();
  dataGui = new DataGUI(data);

  generator = new MultiLinesGenerator(data.lines);

  generator.straight = dataGui.lines_ui.straightGroup;
  generator.circle = dataGui.lines_ui.circleGroup;
  generator.sinus = dataGui.lines_ui.sinusGroup;


  threshold_filter = new ThresholdFilter(data.lines, data.threshold);

  setupControls();
  file_ui.export_group = threshold_filter.group;

  data.LoadSettings("./Settings/test_lines.json");

  dataGui.setGUIValues();
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
  // buildTransformedImage() must run before data.reset_all_changes() below: it gates its
  // own rebuild on data.image.changed, which reset_all_changes() clears. It must also run
  // before threshold_filter.buildLines(), which samples the freshly rebuilt image.
  data.image.buildTransformedImage();

  // Rebuild lines and refresh export scale/orientation BEFORE start_draw(), so that
  // an export triggered right after a data change sizes its canvas from up-to-date values
  // (start_draw() reads file_ui.export_landscape / export_scale to size the export canvas).
  if (data.any_change())
  {
    generator.buildLines();
    threshold_filter.buildLines(generator, data.image);
    file_ui.updateExportScale(threshold_filter.group.getBoundingBox(data.page.clipping, data.page.clip_width, data.page.clip_height));
    data.reset_all_changes();
  }

  start_draw();

  if (data.image.draw)
    data.image.draw(data.image.imageAlpha);

  strokeWeight(data.style.lineWidth);
  stroke(data.style.lineColor.col);

  smooth();
  if (data.lines.draw)
    generator.draw();

  if (data.threshold.enabled)
    threshold_filter.draw();

  end_draw();
}
