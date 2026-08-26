// Clipping utilities for line segments
// Used by: spiral, image_processor, perlin_mountains

// Test si un point est à l'intérieur du rectangle de clipping
boolean pointInClipRect(float x, float y, float centerX, float centerY, 
                        float clipWidth, float clipHeight)
{
  float halfW = clipWidth * 0.5;
  float halfH = clipHeight * 0.5;
  float xmin = centerX - halfW;
  float xmax = centerX + halfW;
  float ymin = centerY - halfH;
  float ymax = centerY + halfH;
  return x >= xmin && x <= xmax && y >= ymin && y <= ymax;
}

// Clips a line segment to a centered rectangle using Cohen-Sutherland algorithm
// Returns true and fills out[0..3] = {x1,y1,x2,y2} when a clipped segment exists
boolean clipLineToCenteredRect(float xFrom, float yFrom, float xTo, float yTo, 
                               float centerX, float centerY, 
                               float clipWidth, float clipHeight, float[] out)
{
  float halfW = clipWidth * 0.5;
  float halfH = clipHeight * 0.5;
  float xmin = centerX - halfW;
  float xmax = centerX + halfW;
  float ymin = centerY - halfH;
  float ymax = centerY + halfH;

  float dx = xTo - xFrom;
  float dy = yTo - yFrom;

  float[] p = { -dx, dx, -dy, dy };
  float[] q = { xFrom - xmin, xmax - xFrom, yFrom - ymin, ymax - yFrom };

  float u1 = 0.0;
  float u2 = 1.0;

  for (int i = 0; i < 4; i++)
  {
    if (p[i] == 0)
    {
      if (q[i] < 0) // parallel and outside
        return false;
    }
    else
    {
      float t = q[i] / p[i];
      if (p[i] < 0)
      {
        if (t > u2) return false;
        if (t > u1) u1 = t;
      }
      else
      {
        if (t < u1) return false;
        if (t < u2) u2 = t;
      }
    }
  }

  out[0] = xFrom + u1 * dx;
  out[1] = yFrom + u1 * dy;
  out[2] = xFrom + u2 * dx;
  out[3] = yFrom + u2 * dy;
  return true;
}
