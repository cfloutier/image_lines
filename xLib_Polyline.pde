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

  // Draws the polyline as dashes of length dashLen separated by gaps of gapLen.
  // gapLen == 0 → solid line (equivalent to draw()).
  // Supports the same centered-rectangle clipping as PolylineGroup.draw().
  void drawDashed(float dashLen, float gapLen, boolean clipping, float clipW, float clipH)
  {
    if (points.size() < 2) return;
    if (gapLen <= 0) { draw(); return; }

    float[] out     = new float[4];
    float   pos     = 0;          // position within current phase
    boolean drawing = true;

    for (int i = 0; i < points.size() - 1; i++)
    {
      PVector a = points.get(i);
      PVector b = points.get(i + 1);
      float segLen = PVector.dist(a, b);
      if (segLen < 1e-6) continue;

      float t = 0;
      while (t < segLen - 1e-6)
      {
        float phaseLen  = drawing ? dashLen : gapLen;
        float spaceLeft = phaseLen - pos;
        float step      = min(spaceLeft, segLen - t);
        float t2        = t + step;

        if (drawing)
        {
          float x1 = lerp(a.x, b.x, t  / segLen);
          float y1 = lerp(a.y, b.y, t  / segLen);
          float x2 = lerp(a.x, b.x, t2 / segLen);
          float y2 = lerp(a.y, b.y, t2 / segLen);
          if (!clipping)
            current_graphics.line(x1, y1, x2, y2);
          else if (clipLineToCenteredRect(x1, y1, x2, y2, 0, 0, clipW, clipH, out))
            current_graphics.line(out[0], out[1], out[2], out[3]);
        }

        pos += step;
        t    = t2;
        if (pos >= phaseLen - 1e-6) { pos = 0; drawing = !drawing; }
      }
    }
  }

  // Pre-computes dashes as actual Polyline segments (AxiDraw-compatible, no SVG stroke-dasharray).
  // Returns a list of Polylines, each representing one drawn dash.
  // gapLen == 0 → returns a list with just this polyline (solid).
  ArrayList<Polyline> splitToDashes(float dashLen, float gapLen)
  {
    ArrayList<Polyline> result = new ArrayList<Polyline>();
    if (points.size() < 2) return result;
    if (gapLen <= 0) { result.add(this); return result; }

    // Random start offset so dash seams don't align across lines or at island join points.
    float   period  = dashLen + gapLen;
    float   startOff = random(period);
    boolean drawing  = (startOff < dashLen);
    float   pos      = drawing ? startOff : (startOff - dashLen);

    Polyline  current = null;

    for (int i = 0; i < points.size() - 1; i++)
    {
      PVector a = points.get(i);
      PVector b = points.get(i + 1);
      float segLen = PVector.dist(a, b);
      if (segLen < 1e-6) continue;

      float t = 0;
      while (t < segLen - 1e-6)
      {
        float phaseLen  = drawing ? dashLen : gapLen;
        float spaceLeft = phaseLen - pos;
        float step      = min(spaceLeft, segLen - t);
        float t2        = t + step;

        if (drawing)
        {
          if (current == null)
          {
            current = new Polyline();
            current.group_id = group_id;
            current.addPoint(new PVector(lerp(a.x, b.x, t / segLen), lerp(a.y, b.y, t / segLen)));
          }
          current.addPoint(new PVector(lerp(a.x, b.x, t2 / segLen), lerp(a.y, b.y, t2 / segLen)));
        }

        pos += step;
        t    = t2;
        if (pos >= phaseLen - 1e-6)
        {
          pos = 0;
          if (drawing && current != null && current.size() >= 2) { result.add(current); current = null; }
          drawing = !drawing;
        }
      }
    }
    if (current != null && current.size() >= 2) result.add(current);
    return result;
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

  // Returns true if this polyline is closed (first ≈ last point, tolerance 0.5 px).
  boolean isClosed()
  {
    if (points.size() < 3) return false;
    PVector a = points.get(0);
    PVector b = points.get(points.size() - 1);
    return PVector.dist(a, b) < 0.5;
  }

  float length()
  {
    float total = 0;
    for (int i = 0; i < points.size() - 1; i++)
      total += PVector.dist(points.get(i), points.get(i + 1));
    return total;
  }

  // Absolute area via the shoelace (Gauss) formula.
  // Returns 0 for open polylines.
  float area()
  {
    if (!isClosed()) return 0;
    int n = points.size();
    float sum = 0;
    for (int i = 0; i < n - 1; i++)
    {
      PVector a = points.get(i);
      PVector b = points.get(i + 1);
      sum += a.x * b.y - b.x * a.y;
    }
    return abs(sum) * 0.5;
  }

  // Merge consecutive points closer than minDist into one (keep the first).
  // Useful to remove near-duplicate vertices produced by bevel joins after offset.
  // The closing vertex of closed polylines is always reconstructed from the new first.
  Polyline dedupe(float minDist)
  {
    if (points.size() < 2) return this;
    boolean closed  = isClosed();
    float   distSq  = minDist * minDist;
    Polyline result = new Polyline();
    result.group_id = group_id;
    result.addPoint(points.get(0).copy());
    int end = closed ? points.size() - 1 : points.size();
    for (int i = 1; i < end; i++)
    {
      PVector prev = result.points.get(result.points.size() - 1);
      PVector curr = points.get(i);
      if (PVector.sub(curr, prev).magSq() >= distSq)
        result.addPoint(curr.copy());
    }
    if (closed && result.points.size() > 0)
      result.addPoint(result.points.get(0).copy());
    return result;
  }

  // Douglas-Peucker polyline simplification.
  // Removes points that are closer than `epsilon` pixels to the simplified line,
  // collapsing grid-aligned staircase patterns into clean diagonal segments.
  // Open polylines: first and last points are always preserved.
  // Closed polylines: closing duplicate vertex is reconstructed.
  Polyline simplify(float epsilon)
  {
    if (epsilon <= 0 || points.size() < 3) return this;
    boolean closed = isClosed();
    int n = closed ? points.size() - 1 : points.size();   // unique vertices

    boolean[] keep = new boolean[n];
    keep[0]     = true;
    keep[n - 1] = true;
    _dpReduce(keep, 0, n - 1, epsilon * epsilon);

    Polyline result = new Polyline();
    result.group_id = group_id;
    for (int i = 0; i < n; i++)
      if (keep[i]) result.addPoint(points.get(i).copy());
    if (closed) result.addPoint(result.points.get(0).copy());
    return result;
  }

  private void _dpReduce(boolean[] keep, int first, int last, float epsSq)
  {
    if (last - first < 2) return;
    PVector a = points.get(first);
    PVector b = points.get(last);
    float maxDistSq = 0;
    int   maxIdx    = first;
    for (int i = first + 1; i < last; i++)
    {
      float d = _ptSegDistSq(points.get(i), a, b);
      if (d > maxDistSq) { maxDistSq = d; maxIdx = i; }
    }
    if (maxDistSq > epsSq)
    {
      keep[maxIdx] = true;
      _dpReduce(keep, first, maxIdx, epsSq);
      _dpReduce(keep, maxIdx, last,  epsSq);
    }
  }

  private float _ptSegDistSq(PVector p, PVector a, PVector b)
  {
    float dx = b.x - a.x, dy = b.y - a.y;
    float lenSq = dx*dx + dy*dy;
    if (lenSq == 0) { float ex = p.x-a.x, ey = p.y-a.y; return ex*ex + ey*ey; }
    float t = max(0, min(1, ((p.x-a.x)*dx + (p.y-a.y)*dy) / lenSq));
    float qx = a.x + t*dx - p.x, qy = a.y + t*dy - p.y;
    return qx*qx + qy*qy;
  }

  // Returns a new Polyline offset by `dist` pixels along vertex normals.
  // Uses the segment-parallel + miter-join approach (O(n), spike-free):
  //   1. Each segment is shifted by dist perpendicular to its direction.
  //   2. Adjacent offset segments are intersected to find each corner point.
  //   3. If the miter distance exceeds miterLimit * |dist|, a bevel is used instead.
  // Closed polylines (islands) are handled correctly.
  // The legacy removeSpikes flag is kept for compatibility but ignored.
  Polyline offset(float dist) { return offset(dist, 4.0); }
  Polyline offset(float dist, float miterLimit)
  {
    int n = points.size();
    if (n < 2) return null;

    boolean closed = isClosed();
    int count = closed ? n - 1 : n;  // number of unique vertices

    // Step 1: build one offset segment per original segment.
    // Each offset segment = (a', b') where a' = a + normal*dist, b' = b + normal*dist.
    int segCount = closed ? count : count - 1;
    PVector[] segA = new PVector[segCount];
    PVector[] segB = new PVector[segCount];

    for (int i = 0; i < segCount; i++)
    {
      PVector p0 = points.get(i);
      PVector p1 = points.get((i + 1) % count);
      PVector d  = PVector.sub(p1, p0);
      // Left-hand perpendicular normal (unit length)
      PVector nm = new PVector(-d.y, d.x);
      float   len = nm.mag();
      if (len < 1e-6) { segA[i] = p0.copy(); segB[i] = p1.copy(); continue; }
      nm.div(len);
      nm.mult(dist);
      segA[i] = PVector.add(p0, nm);
      segB[i] = PVector.add(p1, nm);
    }

    // Step 2: for each vertex, intersect adjacent offset segments.
    Polyline result = new Polyline();
    result.group_id = group_id;

    int vertCount = closed ? count : count;

    for (int i = 0; i < vertCount; i++)
    {
      if (!closed && i == 0)          { result.addPoint(segA[0].copy()); continue; }
      if (!closed && i == count - 1)  { result.addPoint(segB[segCount - 1].copy()); continue; }

      int iPrev = closed ? (i - 1 + segCount) % segCount : i - 1;
      int iNext = closed ? i % segCount                  : i;

      PVector a = segA[iPrev], b = segB[iPrev];
      PVector c = segA[iNext], d = segB[iNext];

      PVector miter = _lineIntersect(a, b, c, d);
      if (miter != null)
      {
        // Miter limit: if the corner point is too far from the offset endpoint, bevel.
        float miterDist = PVector.dist(miter, b);
        if (miterLimit > 0 && miterDist > miterLimit * abs(dist))
        {
          // Bevel: add end of prev segment and start of next segment
          result.addPoint(b.copy());
          result.addPoint(c.copy());
        }
        else
        {
          result.addPoint(miter);
        }
      }
      else
      {
        // Parallel segments (collinear) — just use midpoint between endpoints
        result.addPoint(PVector.lerp(b, c, 0.5));
      }
    }

    if (closed && result.points.size() > 0)
      result.addPoint(result.points.get(0).copy());

    return result;
  }

  // Line-line intersection (infinite lines through a→b and c→d).
  // Returns null if lines are parallel.
  private PVector _lineIntersect(PVector a, PVector b, PVector c, PVector d)
  {
    float dab_x = b.x - a.x, dab_y = b.y - a.y;
    float dcd_x = d.x - c.x, dcd_y = d.y - c.y;
    float denom  = dab_x * dcd_y - dab_y * dcd_x;
    if (abs(denom) < 1e-6) return null;
    float t = ((c.x - a.x) * dcd_y - (c.y - a.y) * dcd_x) / denom;
    return new PVector(a.x + t * dab_x, a.y + t * dab_y);
  }

  // Remove vertices where the polyline reverses direction by more than maxAngleDeg.
  // A hairpin (near-180° turn) is left by removeSpikes when a trimmed loop leaves
  // two near-parallel segments going in opposite directions.
  // Iterates until stable (each pass is O(n)).
  Polyline removeHairpins(float maxAngleDeg)
  {
    float cosThresh = cos(radians(maxAngleDeg));
    boolean closed  = isClosed();
    ArrayList<PVector> pts = new ArrayList<PVector>(points);

    boolean found = true;
    while (found)
    {
      found = false;
      int n   = pts.size();
      int end = closed ? n - 1 : n;
      for (int i = 1; i < end - 1; i++)
      {
        PVector prev = pts.get(i - 1);
        PVector curr = pts.get(i);
        PVector next = pts.get(i + 1);
        PVector d1 = PVector.sub(curr, prev);
        PVector d2 = PVector.sub(next, curr);
        float l1 = d1.mag(), l2 = d2.mag();
        if (l1 < 1e-6 || l2 < 1e-6) { pts.remove(i); found = true; break; }
        float dot = (d1.x*d2.x + d1.y*d2.y) / (l1 * l2);
        if (dot < cosThresh)
        {
          pts.remove(i);
          found = true;
          break;
        }
      }
    }

    Polyline result = new Polyline();
    result.group_id = group_id;
    for (PVector p : pts) result.addPoint(p.copy());
    // Re-close if needed (closing vertex may have been removed)
    if (closed && result.points.size() >= 2)
    {
      PVector first = result.points.get(0);
      PVector last  = result.points.get(result.points.size() - 1);
      if (PVector.dist(first, last) > 0.5) result.addPoint(first.copy());
    }
    return result;
  }

  // Removes self-intersecting loops ("spikes") from the polyline.
  // Iteratively finds the EARLIEST self-intersection and trims the loop,
  // until the polyline is free of crossings or a safety limit is hit.
  Polyline removeSpikes()
  {
    ArrayList<PVector> pts = new ArrayList<PVector>(points);
    boolean closed = isClosed();

    boolean found = true;
    int safety = 0;
    int maxIter = pts.size() * 4;   // proportional to complexity (was hard-coded 500)
    while (found && pts.size() >= 3 && safety++ < maxIter)
    {
      found = false;
      int n        = pts.size();
      int segCount = n - 1;

      outerLoop:
      for (int i = 0; i < segCount - 1; i++)
      {
        PVector a = pts.get(i), b = pts.get(i + 1);
        // For closed polylines don't test the last segment against seg 0
        // (they share an endpoint and would give a false crossing).
        int jEnd = (closed && i == 0) ? segCount - 2 : segCount - 1;

        for (int j = i + 2; j <= jEnd; j++)
        {
          PVector c = pts.get(j), e = pts.get(j + 1);
          PVector ix = _segIntersect(a, b, c, e);
          if (ix != null)
          {
            pts.subList(i + 1, j + 1).clear();
            pts.add(i + 1, ix);
            found = true;
            break outerLoop;
          }
        }
      }
    }

    Polyline r = new Polyline();
    r.group_id = group_id;
    for (PVector p : pts) r.addPoint(p);
    return r;
  }

  // Segment intersection (strictly interior). Returns null if no crossing.
  private PVector _segIntersect(PVector a, PVector b, PVector c, PVector d)
  {
    float dab_x = b.x - a.x, dab_y = b.y - a.y;
    float dcd_x = d.x - c.x, dcd_y = d.y - c.y;
    float denom  = dab_x * dcd_y - dab_y * dcd_x;
    if (abs(denom) < 1e-6) return null;

    float t = ((c.x - a.x) * dcd_y - (c.y - a.y) * dcd_x) / denom;
    float u = ((c.x - a.x) * dab_y - (c.y - a.y) * dab_x) / denom;

    float eps = 1e-6;
    if (t > eps && t < 1 - eps && u > eps && u < 1 - eps)
      return new PVector(a.x + t * dab_x, a.y + t * dab_y);
    return null;
  }

  // REMOVED: _vertexNormal — replaced by segment-parallel approach in offset().
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
