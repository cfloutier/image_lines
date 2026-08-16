// Computes "seam" edges where two Box3D surfaces cross each other (the visible crease
// lines where two overlapping/intersecting boxes meet), for direct reuse by the
// analytic HLR pipeline in LineBuilder. Not solid CSG: only the surface-intersection
// curve segments are produced (no face capping, no solid boolean), which is exactly the
// extra geometry a wireframe/line-art renderer needs.
//
// Method: for every pair of faces (one quad from box A, one quad from box B), the two
// face planes intersect in a line (unless parallel). That line is clipped first to face
// A's rectangle, then to face B's rectangle (both in each face's own 2D basis); whatever
// segment survives both clips lies simultaneously on both box surfaces, i.e. a piece of
// the seam curve. 6x6 = 36 face pairs per box pair, each O(1).

class SeamWorldEdge
{
  PVector worldA;
  PVector worldB;
  int ownerA;
  int ownerB;

  SeamWorldEdge(PVector worldA, PVector worldB, int ownerA, int ownerB)
  {
    this.worldA = worldA;
    this.worldB = worldB;
    this.ownerA = ownerA;
    this.ownerB = ownerB;
  }
}

// Below this world-unit chord length, a face/face crossing is treated as a degenerate
// touch (corner/edge graze) rather than a real seam segment worth drawing.
final float MIN_SEAM_LENGTH = 0.001;

void appendBoxSeamEdges(Box3D boxA, int ownerA, Box3D boxB, int ownerB, ArrayList<SeamWorldEdge> outSeams)
{
  PVector[] va = boxA.getVertices();
  PVector[] vb = boxB.getVertices();

  for (int fa = 0; fa < boxA.FACE_IDX.length; fa++)
  {
    PVector a0 = va[boxA.FACE_IDX[fa][0]];
    PVector a1 = va[boxA.FACE_IDX[fa][1]];
    PVector a3 = va[boxA.FACE_IDX[fa][3]];

    PVector uA = PVector.sub(a1, a0);
    PVector vA = PVector.sub(a3, a0);
    float uLenA = uA.mag();
    float vLenA = vA.mag();
    if (uLenA < 1e-6 || vLenA < 1e-6)
      continue;
    PVector uHatA = PVector.div(uA, uLenA);
    PVector vHatA = PVector.div(vA, vLenA);
    PVector nA = uHatA.cross(vHatA, null);
    nA.normalize();
    float dA = nA.dot(a0);

    for (int fb = 0; fb < boxB.FACE_IDX.length; fb++)
    {
      PVector b0 = vb[boxB.FACE_IDX[fb][0]];
      PVector b1 = vb[boxB.FACE_IDX[fb][1]];
      PVector b3 = vb[boxB.FACE_IDX[fb][3]];

      PVector uB = PVector.sub(b1, b0);
      PVector vB = PVector.sub(b3, b0);
      float uLenB = uB.mag();
      float vLenB = vB.mag();
      if (uLenB < 1e-6 || vLenB < 1e-6)
        continue;
      PVector uHatB = PVector.div(uB, uLenB);
      PVector vHatB = PVector.div(vB, vLenB);
      PVector nB = uHatB.cross(vHatB, null);
      nB.normalize();
      float dB = nB.dot(b0);

      PVector D = nA.cross(nB, null);
      float denom = D.magSq();
      if (denom < 1e-9)
        continue; // parallel faces: no crossing line

      PVector p0 = PVector.add(
        PVector.mult(nB.cross(D, null), dA),
        PVector.mult(D.cross(nA, null), dB));
      p0.div(denom);

      PVector dhat = D.copy();
      dhat.normalize();

      float[] tRange = { -1e9, 1e9 };
      if (!clipLineToFaceRect(p0, dhat, a0, uHatA, uLenA, vHatA, vLenA, tRange))
        continue;
      if (!clipLineToFaceRect(p0, dhat, b0, uHatB, uLenB, vHatB, vLenB, tRange))
        continue;

      if (tRange[1] - tRange[0] < MIN_SEAM_LENGTH)
        continue;

      PVector segStart = PVector.add(p0, PVector.mult(dhat, tRange[0]));
      PVector segEnd = PVector.add(p0, PVector.mult(dhat, tRange[1]));
      outSeams.add(new SeamWorldEdge(segStart, segEnd, ownerA, ownerB));
    }
  }
}

// Narrows tRange (in/out, {tMin,tMax}) to where the line p0 + t*dhat falls inside the
// rectangle [0,uLen] x [0,vLen] of the given face basis. Returns false if empty.
boolean clipLineToFaceRect(PVector p0, PVector dhat, PVector faceCorner, PVector faceUhat, float faceULen, PVector faceVhat, float faceVLen, float[] tRange)
{
  PVector rel = PVector.sub(p0, faceCorner);
  float u0 = rel.dot(faceUhat);
  float v0 = rel.dot(faceVhat);
  float du = dhat.dot(faceUhat);
  float dv = dhat.dot(faceVhat);

  if (!clipAxis(u0, du, 0, faceULen, tRange))
    return false;
  if (!clipAxis(v0, dv, 0, faceVLen, tRange))
    return false;

  return tRange[0] <= tRange[1];
}

boolean clipAxis(float p0, float d, float lo, float hi, float[] tRange)
{
  if (Math.abs(d) < 1e-9)
    return (p0 >= lo && p0 <= hi);

  float t1 = (lo - p0) / d;
  float t2 = (hi - p0) / d;
  float tNear = Math.min(t1, t2);
  float tFar = Math.max(t1, t2);

  tRange[0] = Math.max(tRange[0], tNear);
  tRange[1] = Math.min(tRange[1], tFar);
  return tRange[0] <= tRange[1];
}
