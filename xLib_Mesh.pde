class EdgeProjected
{
  ProjectedPoint a;
  ProjectedPoint b;
  PVector worldA;
  PVector worldB;
  int ownerOccluderIndex;
  // -1 for a normal box edge (single owner). Set to a second occluder index for a seam
  // edge shared by two intersecting boxes (see xLib_BoxIntersection) - such an edge sits
  // exactly on both boxes' surfaces, so both must get the lenient self-occlusion check.
  int ownerOccluderIndexB;

  EdgeProjected(ProjectedPoint a, ProjectedPoint b, PVector worldA, PVector worldB, int ownerOccluderIndex)
  {
    this(a, b, worldA, worldB, ownerOccluderIndex, -1);
  }

  EdgeProjected(ProjectedPoint a, ProjectedPoint b, PVector worldA, PVector worldB, int ownerOccluderIndex, int ownerOccluderIndexB)
  {
    this.a = a;
    this.b = b;
    this.worldA = worldA;
    this.worldB = worldB;
    this.ownerOccluderIndex = ownerOccluderIndex;
    this.ownerOccluderIndexB = ownerOccluderIndexB;
  }
}

// A single occluder for analytic line-of-sight visibility tests: a Box3D plus its
// precomputed world AABB, world geometric center, and diagonal (world-space, camera-
// independent - built once per mesh-list version and reused across camera-only rebuilds).
// epsilon defaults to a generic value but LineBuilder rescales it every emit pass from
// the user-tunable DataOcclusion.self_occlusion_eps_scale.
class OccluderBox
{
  Box3D box;
  float minX, minY, minZ;
  float maxX, maxY, maxZ;
  PVector worldCenter;
  float diagonal;
  float epsilon;

  OccluderBox(Box3D box)
  {
    this.box = box;

    float[] mn = new float[3];
    float[] mx = new float[3];
    box.computeWorldAABB(mn, mx);
    minX = mn[0]; minY = mn[1]; minZ = mn[2];
    maxX = mx[0]; maxY = mx[1]; maxZ = mx[2];

    worldCenter = box.getWorldGeometricCenter();
    diagonal = box.getDiagonal();
    epsilon = max(1e-3, 1e-4 * diagonal);
  }
}

abstract class Mesh
{
  abstract void addWireframe(PolylineGroup group, CameraProjector3D camera);

  // World-space-only occluder representation of this mesh (camera-independent), rebuilt
  // only when the mesh list itself changes.
  abstract OccluderBox buildOccluder();

  // Projects this mesh's edges for the current camera frame, tagging each with
  // ownerOccluderIndex (the index of this mesh's OccluderBox in the occluders list).
  // Rebuilt on every camera/occlusion-parameter change.
  abstract void appendProjectedEdges(
    ArrayList<EdgeProjected> edges,
    CameraProjector3D camera,
    CameraFrame frame,
    int ownerOccluderIndex
  );
}
