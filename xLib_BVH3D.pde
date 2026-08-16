// Generic bounding-volume hierarchy over world-space AABBs, used as a broad-phase
// spatial index for "any-hit" ray queries (e.g. line-of-sight occlusion tests).
// Rebuild only when the underlying object set changes; queries are allocation-free
// on the hot path (traversalStack is a reusable instance field).

interface BVH3DRayTest
{
  // Return true if object at objectIndex counts as a hit for this ray within (tMin,tMax).
  boolean testObject(int objectIndex, PVector origin, PVector dir, float tMin, float tMax);
}

class BVH3DNode
{
  float minX, minY, minZ;
  float maxX, maxY, maxZ;
  int left = -1;
  int right = -1;
  int start = -1;
  int count = 0;

  boolean isLeaf()
  {
    return count > 0;
  }
}

class BVH3D
{
  static final int LEAF_SIZE = 4;
  static final int MAX_STACK = 64;

  ArrayList<BVH3DNode> nodes = new ArrayList<BVH3DNode>();
  int[] objectIndices;
  int rootIndex = -1;
  int[] traversalStack = new int[MAX_STACK];

  void build(float[] minX, float[] minY, float[] minZ, float[] maxX, float[] maxY, float[] maxZ)
  {
    nodes.clear();
    int n = minX.length;

    objectIndices = new int[n];
    for (int i = 0; i < n; i++)
      objectIndices[i] = i;

    if (n == 0)
    {
      rootIndex = -1;
      return;
    }

    rootIndex = buildRecursive(minX, minY, minZ, maxX, maxY, maxZ, 0, n);
  }

  int buildRecursive(float[] minX, float[] minY, float[] minZ, float[] maxX, float[] maxY, float[] maxZ, int start, int count)
  {
    BVH3DNode node = new BVH3DNode();
    int nodeIndex = nodes.size();
    nodes.add(node);

    float bMinX = Float.MAX_VALUE, bMinY = Float.MAX_VALUE, bMinZ = Float.MAX_VALUE;
    float bMaxX = -Float.MAX_VALUE, bMaxY = -Float.MAX_VALUE, bMaxZ = -Float.MAX_VALUE;

    for (int i = start; i < start + count; i++)
    {
      int idx = objectIndices[i];
      if (minX[idx] < bMinX) bMinX = minX[idx];
      if (maxX[idx] > bMaxX) bMaxX = maxX[idx];
      if (minY[idx] < bMinY) bMinY = minY[idx];
      if (maxY[idx] > bMaxY) bMaxY = maxY[idx];
      if (minZ[idx] < bMinZ) bMinZ = minZ[idx];
      if (maxZ[idx] > bMaxZ) bMaxZ = maxZ[idx];
    }

    node.minX = bMinX; node.minY = bMinY; node.minZ = bMinZ;
    node.maxX = bMaxX; node.maxY = bMaxY; node.maxZ = bMaxZ;

    if (count <= LEAF_SIZE)
    {
      node.start = start;
      node.count = count;
      return nodeIndex;
    }

    float extentX = bMaxX - bMinX;
    float extentY = bMaxY - bMinY;
    float extentZ = bMaxZ - bMinZ;

    int axis = 0;
    if (extentY > extentX && extentY >= extentZ) axis = 1;
    else if (extentZ > extentX && extentZ >= extentY) axis = 2;

    int mid = start + count / 2;
    quickSelectMedian(minX, minY, minZ, maxX, maxY, maxZ, start, start + count - 1, mid, axis);

    int leftChild = buildRecursive(minX, minY, minZ, maxX, maxY, maxZ, start, mid - start);
    int rightChild = buildRecursive(minX, minY, minZ, maxX, maxY, maxZ, mid, start + count - mid);

    node.left = leftChild;
    node.right = rightChild;
    node.count = 0;
    return nodeIndex;
  }

  // Partial (nth_element-style) partition of objectIndices[lo..hi] around the median
  // index k, ordered by object center on the given axis. Average O(n) per call.
  void quickSelectMedian(float[] minX, float[] minY, float[] minZ, float[] maxX, float[] maxY, float[] maxZ, int lo, int hi, int k, int axis)
  {
    while (lo < hi)
    {
      float pivot = centerOf(minX, minY, minZ, maxX, maxY, maxZ, objectIndices[(lo + hi) / 2], axis);
      int i = lo;
      int j = hi;

      while (i <= j)
      {
        while (centerOf(minX, minY, minZ, maxX, maxY, maxZ, objectIndices[i], axis) < pivot) i++;
        while (centerOf(minX, minY, minZ, maxX, maxY, maxZ, objectIndices[j], axis) > pivot) j--;
        if (i <= j)
        {
          int tmp = objectIndices[i];
          objectIndices[i] = objectIndices[j];
          objectIndices[j] = tmp;
          i++;
          j--;
        }
      }

      if (k <= j) hi = j;
      else if (k >= i) lo = i;
      else break;
    }
  }

  float centerOf(float[] minX, float[] minY, float[] minZ, float[] maxX, float[] maxY, float[] maxZ, int idx, int axis)
  {
    if (axis == 0) return (minX[idx] + maxX[idx]) * 0.5f;
    if (axis == 1) return (minY[idx] + maxY[idx]) * 0.5f;
    return (minZ[idx] + maxZ[idx]) * 0.5f;
  }

  // Iterative any-hit traversal: returns true as soon as test.testObject() reports a hit.
  // Allocation-free (traversalStack is a reusable field) — safe for single-threaded reuse only.
  boolean anyHit(PVector origin, PVector dir, float tMin, float tMax, BVH3DRayTest test)
  {
    if (rootIndex < 0)
      return false;

    int sp = 0;
    traversalStack[sp++] = rootIndex;

    while (sp > 0)
    {
      int nodeIndex = traversalStack[--sp];
      BVH3DNode node = nodes.get(nodeIndex);

      if (!rayIntersectsAABB(origin, dir, node.minX, node.minY, node.minZ, node.maxX, node.maxY, node.maxZ, tMin, tMax))
        continue;

      if (node.isLeaf())
      {
        for (int i = node.start; i < node.start + node.count; i++)
        {
          int objectIndex = objectIndices[i];
          if (test.testObject(objectIndex, origin, dir, tMin, tMax))
            return true;
        }
      }
      else if (sp < MAX_STACK - 2)
      {
        traversalStack[sp++] = node.left;
        traversalStack[sp++] = node.right;
      }
    }

    return false;
  }

  // Collects the indices of every leaf object whose AABB overlaps the given query AABB
  // (broad-phase for e.g. finding candidate box-box intersection pairs). Includes the
  // query's own object if its bounds are passed in - callers dedupe/self-filter as needed.
  void queryOverlaps(float qMinX, float qMinY, float qMinZ, float qMaxX, float qMaxY, float qMaxZ, ArrayList<Integer> outIndices)
  {
    if (rootIndex < 0)
      return;

    int sp = 0;
    traversalStack[sp++] = rootIndex;

    while (sp > 0)
    {
      int nodeIndex = traversalStack[--sp];
      BVH3DNode node = nodes.get(nodeIndex);

      if (!aabbOverlap(node.minX, node.minY, node.minZ, node.maxX, node.maxY, node.maxZ, qMinX, qMinY, qMinZ, qMaxX, qMaxY, qMaxZ))
        continue;

      if (node.isLeaf())
      {
        for (int i = node.start; i < node.start + node.count; i++)
          outIndices.add(objectIndices[i]);
      }
      else if (sp < MAX_STACK - 2)
      {
        traversalStack[sp++] = node.left;
        traversalStack[sp++] = node.right;
      }
    }
  }

  boolean aabbOverlap(float aMinX, float aMinY, float aMinZ, float aMaxX, float aMaxY, float aMaxZ, float bMinX, float bMinY, float bMinZ, float bMaxX, float bMaxY, float bMaxZ)
  {
    return aMinX <= bMaxX && aMaxX >= bMinX
        && aMinY <= bMaxY && aMaxY >= bMinY
        && aMinZ <= bMaxZ && aMaxZ >= bMinZ;
  }

  boolean rayIntersectsAABB(PVector origin, PVector dir, float minX, float minY, float minZ, float maxX, float maxY, float maxZ, float tMin, float tMax)
  {
    float t0 = tMin;
    float t1 = tMax;

    if (Math.abs(dir.x) < 1e-12f)
    {
      if (origin.x < minX || origin.x > maxX)
        return false;
    }
    else
    {
      float invD = 1.0f / dir.x;
      float tNear = (minX - origin.x) * invD;
      float tFar = (maxX - origin.x) * invD;
      if (tNear > tFar) { float tmp = tNear; tNear = tFar; tFar = tmp; }
      t0 = Math.max(t0, tNear);
      t1 = Math.min(t1, tFar);
      if (t0 > t1) return false;
    }

    if (Math.abs(dir.y) < 1e-12f)
    {
      if (origin.y < minY || origin.y > maxY)
        return false;
    }
    else
    {
      float invD = 1.0f / dir.y;
      float tNear = (minY - origin.y) * invD;
      float tFar = (maxY - origin.y) * invD;
      if (tNear > tFar) { float tmp = tNear; tNear = tFar; tFar = tmp; }
      t0 = Math.max(t0, tNear);
      t1 = Math.min(t1, tFar);
      if (t0 > t1) return false;
    }

    if (Math.abs(dir.z) < 1e-12f)
    {
      if (origin.z < minZ || origin.z > maxZ)
        return false;
    }
    else
    {
      float invD = 1.0f / dir.z;
      float tNear = (minZ - origin.z) * invD;
      float tFar = (maxZ - origin.z) * invD;
      if (tNear > tFar) { float tmp = tNear; tNear = tFar; tFar = tmp; }
      t0 = Math.max(t0, tNear);
      t1 = Math.min(t1, tFar);
      if (t0 > t1) return false;
    }

    return true;
  }
}
