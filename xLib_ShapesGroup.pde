// Dot: a single point for SVG/plotter export.
// Rendered on screen as point(), in SVG as a zero-length line with round linecap
// (same stroke-width as polylines — the stroke controls the visual size).
class Dot
{
  PVector pos;
  Dot(PVector pos) { this.pos = pos; }
}

// ShapesGroup: holds both Polylines and Dots for mixed-content drawing.
// Used by image_dots and any future project that combines shapes.
// Replaces PolylineGroup when dot support is needed (v3.1.0).
class ShapesGroup
{
  ArrayList<Polyline> polylines = new ArrayList<Polyline>();
  ArrayList<Dot>      dots      = new ArrayList<Dot>();

  void addPolyline(Polyline p)  { polylines.add(p); }
  void addDot(PVector pos)      { dots.add(new Dot(pos)); }
  void clear()                  { polylines.clear(); dots.clear(); }

  int polylineCount()           { return polylines.size(); }
  int dotCount()                { return dots.size(); }
  int totalCount()              { return polylines.size() + dots.size(); }

  void draw(boolean clipping, float clip_w, float clip_h)
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
        for (int i = 0; i < l.size() - 1; i++)
        {
          PVector a = l.get(i), b = l.get(i + 1);
          if (clipLineToCenteredRect(a.x, a.y, b.x, b.y, 0, 0, clip_w, clip_h, out))
            current_graphics.line(out[0], out[1], out[2], out[3]);
        }
      }
    }

    for (Dot d : dots)
    {
      if (!clipping || pointInClipRect(d.pos.x, d.pos.y, 0, 0, clip_w, clip_h))
        current_graphics.point(d.pos.x, d.pos.y);
    }
  }

  BoundingBox getBoundingBox(boolean clipping, float clip_w, float clip_h)
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
          PVector a = l.get(i), b = l.get(i + 1);
          if (clipLineToCenteredRect(a.x, a.y, b.x, b.y, 0, 0, clip_w, clip_h, out))
          {
            bbox.addPoint(new PVector(out[0], out[1]));
            bbox.addPoint(new PVector(out[2], out[3]));
          }
        }
      }
    }

    for (Dot d : dots)
    {
      if (!clipping || pointInClipRect(d.pos.x, d.pos.y, 0, 0, clip_w, clip_h))
        bbox.addPoint(d.pos);
    }

    return bbox;
  }
}
