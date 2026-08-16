Polyline makeProjectedEdge(PVector a, PVector b, CameraProjector3D camera)
{
  Polyline edge = new Polyline();
  edge.addPoint(camera.projectPoint(a));
  edge.addPoint(camera.projectPoint(b));
  return edge;
}


class Box3D extends Mesh
{
  final int[][] EDGE_IDX = {
    { 0, 1 }, { 1, 2 }, { 2, 3 }, { 3, 0 },
    { 4, 5 }, { 5, 6 }, { 6, 7 }, { 7, 4 },
    { 0, 4 }, { 1, 5 }, { 2, 6 }, { 3, 7 }
  };

  // The 6 faces as planar quads (c0,c1,c2,c3 in order, with c1-c0 and c3-c0 forming a
  // perpendicular in-plane basis) - used by xLib_BoxIntersection to find seam edges
  // where two boxes' surfaces cross.
  final int[][] FACE_IDX = {
    { 0, 1, 2, 3 }, // -Y (bottom)
    { 4, 5, 6, 7 }, // +Y (top)
    { 0, 1, 5, 4 }, // -Z
    { 3, 2, 6, 7 }, // +Z
    { 0, 4, 7, 3 }, // -X
    { 1, 2, 6, 5 }  // +X
  };

  float center_x;
  float center_y;
  float center_z;

  float size_x;
  float size_y;
  float size_z;

  PVector rotation = new PVector(0, 0, 0);

  Box3D(float center_x, float center_y, float center_z, float size_x, float size_y, float size_z)
  {
    this.center_x = center_x;
    this.center_y = center_y;
    this.center_z = center_z;
    this.size_x = size_x;
    this.size_y = size_y;
    this.size_z = size_z;
  }

  Box3D(float center_x, float center_y, float center_z, float size_x, float size_y, float size_z, PVector rotation)
  {
    this(center_x, center_y, center_z, size_x, size_y, size_z);
    setRotation(rotation);
  }

  void setRotation(PVector rotation)
  {
    if (rotation == null)
      this.rotation = new PVector(0, 0, 0);
    else
      this.rotation = rotation.copy();
  }

  PVector[] getVertices()
  {
    PVector[] vertices = new PVector[8];

    float min_x = center_x - size_x;
    float max_x = center_x + size_x;
    float min_z = center_z - size_z;
    float max_z = center_z + size_z;
    float top_y = center_y + size_y;

    vertices[0] = new PVector(min_x, center_y, min_z);
    vertices[1] = new PVector(max_x, center_y, min_z);
    vertices[2] = new PVector(max_x, center_y, max_z);
    vertices[3] = new PVector(min_x, center_y, max_z);

    vertices[4] = new PVector(min_x, top_y, min_z);
    vertices[5] = new PVector(max_x, top_y, min_z);
    vertices[6] = new PVector(max_x, top_y, max_z);
    vertices[7] = new PVector(min_x, top_y, max_z);

    for (int i = 0; i < vertices.length; i++)
      vertices[i] = rotateAroundBaseCenter(vertices[i]);

    return vertices;
  }

  PVector rotateAroundBaseCenter(PVector point)
  {
    PVector rotated = point.copy();
    rotated.sub(center_x, center_y, center_z);

    if (rotation.x != 0) rotated = rotateXPoint(rotated, rotation.x);
    if (rotation.y != 0) rotated = rotateYPoint(rotated, rotation.y);
    if (rotation.z != 0) rotated = rotateZPoint(rotated, rotation.z);

    rotated.add(center_x, center_y, center_z);
    return rotated;
  }

  PVector rotateXPoint(PVector point, float angle)
  {
    float c = cos(angle);
    float s = sin(angle);
    return new PVector(point.x, point.y * c - point.z * s, point.y * s + point.z * c);
  }

  PVector rotateYPoint(PVector point, float angle)
  {
    float c = cos(angle);
    float s = sin(angle);
    return new PVector(point.x * c + point.z * s, point.y, -point.x * s + point.z * c);
  }

  PVector rotateZPoint(PVector point, float angle)
  {
    float c = cos(angle);
    float s = sin(angle);
    return new PVector(point.x * c - point.y * s, point.x * s + point.y * c, point.z);
  }

  @Override
  void addWireframe(PolylineGroup group, CameraProjector3D camera)
  {
    PVector[] vertices = getVertices();

    for (int i = 0; i < EDGE_IDX.length; i++)
    {
      group.add(makeProjectedEdge(vertices[EDGE_IDX[i][0]], vertices[EDGE_IDX[i][1]], camera));
    }
  }

  @Override
  OccluderBox buildOccluder()
  {
    return new OccluderBox(this);
  }

  @Override
  void appendProjectedEdges(
    ArrayList<EdgeProjected> edges,
    CameraProjector3D camera,
    CameraFrame frame,
    int ownerOccluderIndex)
  {
    PVector[] worldVertices = getVertices();
    ProjectedPoint[] p = new ProjectedPoint[worldVertices.length];
    for (int i = 0; i < worldVertices.length; i++)
      p[i] = camera.projectPointWithDepth(worldVertices[i], frame);

    PVector[] outWorld = new PVector[2];
    ProjectedPoint[] outProjected = new ProjectedPoint[2];

    for (int i = 0; i < EDGE_IDX.length; i++)
    {
      int ia = EDGE_IDX[i][0];
      int ib = EDGE_IDX[i][1];

      if (!clipSegmentToNearPlane(worldVertices[ia], p[ia], worldVertices[ib], p[ib], camera, frame, outWorld, outProjected))
        continue;

      edges.add(new EdgeProjected(
        outProjected[0], outProjected[1],
        outWorld[0], outWorld[1],
        ownerOccluderIndex));
    }
  }

  // World-space geometric center of the box volume (base pivot + half-height on Y, rotated).
  // Note: center_x/y/z is a BASE pivot (Y in [0, size_y]), not the volume's geometric center.
  PVector getWorldGeometricCenter()
  {
    PVector offset = new PVector(0, size_y * 0.5, 0);
    if (rotation.x != 0) offset = rotateXPoint(offset, rotation.x);
    if (rotation.y != 0) offset = rotateYPoint(offset, rotation.y);
    if (rotation.z != 0) offset = rotateZPoint(offset, rotation.z);
    return new PVector(center_x + offset.x, center_y + offset.y, center_z + offset.z);
  }

  // Axis-aligned world-space bounding box of the (possibly rotated) box, from its 8 vertices.
  void computeWorldAABB(float[] outMin, float[] outMax)
  {
    PVector[] vertices = getVertices();

    float minX = Float.MAX_VALUE, minY = Float.MAX_VALUE, minZ = Float.MAX_VALUE;
    float maxX = -Float.MAX_VALUE, maxY = -Float.MAX_VALUE, maxZ = -Float.MAX_VALUE;

    for (int i = 0; i < vertices.length; i++)
    {
      PVector v = vertices[i];
      if (v.x < minX) minX = v.x;
      if (v.x > maxX) maxX = v.x;
      if (v.y < minY) minY = v.y;
      if (v.y > maxY) maxY = v.y;
      if (v.z < minZ) minZ = v.z;
      if (v.z > maxZ) maxZ = v.z;
    }

    outMin[0] = minX; outMin[1] = minY; outMin[2] = minZ;
    outMax[0] = maxX; outMax[1] = maxY; outMax[2] = maxZ;
  }

  // Transforms a world-space point (isDirection=false) or vector (isDirection=true, no translation)
  // into the box's unrotated local frame, where the box occupies x in [-size_x,size_x],
  // y in [0,size_y], z in [-size_z,size_z]. This is the exact inverse of rotateAroundBaseCenter,
  // which applies Rx then Ry then Rz: the inverse applies Rz(-z) then Ry(-y) then Rx(-x).
  PVector worldToLocal(PVector world, boolean isDirection)
  {
    PVector p = world.copy();
    if (!isDirection)
      p.sub(center_x, center_y, center_z);

    if (rotation.z != 0) p = rotateZPoint(p, -rotation.z);
    if (rotation.y != 0) p = rotateYPoint(p, -rotation.y);
    if (rotation.x != 0) p = rotateXPoint(p, -rotation.x);

    return p;
  }

  // Closed-form ray/box (OBB) intersection via the slab method, done in the box's local frame
  // so rotation is handled exactly. origin/dir are world-space; dir need not be normalized, but
  // outT is then expressed in units of |dir| (pass a normalized dir to get true distances).
  // Returns true and fills outT = {tEntry, tExit} (clamped to [tMin,tMax]) on intersection.
  boolean intersectRaySlab(PVector origin, PVector dir, float tMin, float tMax, float[] outT)
  {
    PVector lo = worldToLocal(origin, false);
    PVector ld = worldToLocal(dir, true);

    float t0 = tMin;
    float t1 = tMax;

    float[] o = { lo.x, lo.y, lo.z };
    float[] d = { ld.x, ld.y, ld.z };
    float[] mn = { -size_x, 0, -size_z };
    float[] mx = { size_x, size_y, size_z };

    for (int axis = 0; axis < 3; axis++)
    {
      if (Math.abs(d[axis]) < 1e-12f)
      {
        if (o[axis] < mn[axis] || o[axis] > mx[axis])
          return false;
        continue;
      }

      float invD = 1.0f / d[axis];
      float tNear = (mn[axis] - o[axis]) * invD;
      float tFar = (mx[axis] - o[axis]) * invD;
      if (tNear > tFar)
      {
        float tmp = tNear;
        tNear = tFar;
        tFar = tmp;
      }

      t0 = Math.max(t0, tNear);
      t1 = Math.min(t1, tFar);

      if (t0 > t1)
        return false;
    }

    outT[0] = t0;
    outT[1] = t1;
    return true;
  }

  // Diagonal length of the box volume, used to scale a per-box self-occlusion epsilon.
  float getDiagonal()
  {
    return sqrt(sq(2 * size_x) + sq(size_y) + sq(2 * size_z));
  }
}


void addBoxWireframe(PolylineGroup group, CameraProjector3D camera, float center_x, float center_y, float center_z, float size_x, float size_y, float size_z)
{
  Box3D box = new Box3D(center_x, center_y, center_z, size_x, size_y, size_z);
  box.addWireframe(group, camera);
}
