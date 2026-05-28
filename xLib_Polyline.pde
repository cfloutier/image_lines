// Generic Polyline class for shared use across projects
// Used by: spiral, image_processor, perlin_mountains

class Polyline
{
  ArrayList<PVector> points = new ArrayList<PVector>();
  int group_id = -1;  // index used by threshold filters to cycle thresholds per group/level

  void draw()
  {
    if (points.size() < 2)
      return;

    current_graphics.noFill();
    current_graphics.beginShape();

    for (int i = 0; i < points.size(); i++)
    {
      PVector p = points.get(i);
      current_graphics.vertex(p.x, p.y);
    }

    current_graphics.endShape();
  }

  void addPoint(PVector p)
  {
    points.add(p);
  }

  void clear()
  {
    points.clear();
  }

  int size()
  {
    return points.size();
  }

  PVector get(int index)
  {
    return points.get(index);
  }

  BoundingBox getBoundingBox()
  {
    BoundingBox bbox = new BoundingBox();
    for (PVector p : points)
      bbox.addPoint(p);
    return bbox;
  }

  void print()
  {
    String s = "Polyline: ";
    for (int i = 0; i < points.size(); i++)
    {
      PVector p = points.get(i);
      s += "[" + p.x + "," + p.y + "]";
    }

    println(s);
  }
}

// Extended Polyline with per-point validity and Y offset for line-based rendering
// Used by: perlin_mountains
class ValidatedPolylineWithOffset extends Polyline
{
  boolean[] validity = null;
  float y_offset = 0;

  void setValidity(boolean[] valid)
  {
    this.validity = valid;
  }

  void setYOffset(float offset)
  {
    this.y_offset = offset;
  }

  void draw()
  {
    if (points.size() < 1)
      return;

    if (validity == null)
    {
      // No validity check, draw as simple polyline
      super.draw();
      return;
    }

    // Draw with validity checks - may create multiple line segments
    current_graphics.noFill();
    boolean drawing = false;

    for (int i = 0; i < points.size(); i++)
    {
      boolean valid = validity[i];
      if (valid)
      {
        PVector p = points.get(i);
        if (!drawing)
        {
          drawing = true;
          current_graphics.beginShape();
        }

        current_graphics.vertex(p.x, p.y + y_offset);
      } else
      {
        if (drawing)
        {
          drawing = false;
          current_graphics.endShape();
        }
      }
    }

    if (drawing)
    {
      current_graphics.endShape();
    }
  }
}

// Group of Polylines with integrated clipping and bounding box support
class PolylineGroup
{
  ArrayList<Polyline> polylines = new ArrayList<Polyline>();

  void add(Polyline p)  { polylines.add(p); }
  void clear()          { polylines.clear(); }
  int  size()           { return polylines.size(); }

  void draw(boolean clipping, float clip_width, float clip_height)
  {
    float[] out = new float[4];
    for (Polyline l : polylines)
    {
      if (!clipping)
      {
        l.draw();
      }
      else
      {
        // Clip each segment in the polyline
        for (int i = 0; i < l.size() - 1; i++)
        {
          PVector a = l.get(i);
          PVector b = l.get(i + 1);
          if (clipLineToCenteredRect(a.x, a.y, b.x, b.y, 0, 0, clip_width, clip_height, out))
            current_graphics.line(out[0], out[1], out[2], out[3]);
        }
      }
    }
  }

  BoundingBox getBoundingBox(boolean clipping, float clip_width, float clip_height)
  {
    BoundingBox bbox = new BoundingBox();
    float[] out = new float[4];
    for (Polyline l : polylines)
    {
      if (!clipping)
      {
        BoundingBox lb = l.getBoundingBox();
        bbox.minX = min(bbox.minX, lb.minX);
        bbox.maxX = max(bbox.maxX, lb.maxX);
        bbox.minY = min(bbox.minY, lb.minY);
        bbox.maxY = max(bbox.maxY, lb.maxY);
      }
      else
      {
        for (int i = 0; i < l.size() - 1; i++)
        {
          PVector a = l.get(i);
          PVector b = l.get(i + 1);
          if (clipLineToCenteredRect(a.x, a.y, b.x, b.y, 0, 0, clip_width, clip_height, out))
          {
            bbox.addPoint(new PVector(out[0], out[1]));
            bbox.addPoint(new PVector(out[2], out[3]));
          }
        }
      }
    }
    return bbox;
  }
}
