class CameraData extends GenericData implements CameraProjector3D
{
  static final int PROJECTION_ORTHO = 0;
  static final int PROJECTION_PERSPECTIVE = 1;
  static final float TARGET_DISTANCE_MIN = 50;
  static final float TARGET_DISTANCE_MAX = 10000;
  static final float ORTHO_ZOOM_MIN = 0.05;
  static final float ORTHO_ZOOM_MAX = 20;

  CameraData()
  {
    super("Camera");
  }

  int projection_mode = PROJECTION_PERSPECTIVE;

  float fov = 60;
  // Distance between camera and target (orbit radius).
  float target_distance = 900;
  // Zoom factor used only in orthographic mode.
  float ortho_zoom = 1;
  float yaw = 0;
  float pitch = -0.55;

  float target_x = 0;
  float target_y = 0;
  float target_z = 0;

  @Override
  CameraFrame buildFrame()
  {
    PVector camera_pos = getCameraPosition();
    PVector forward = PVector.sub(getTarget(), camera_pos);
    forward.normalize();

    PVector world_up = new PVector(0, 1, 0);
    PVector right = forward.cross(world_up, null);
    if (right.magSq() < 1e-6)
      right = new PVector(1, 0, 0);
    else
      right.normalize();

    PVector up = right.cross(forward, null);
    up.normalize();

    // Ties focal length (in pixels) to fov and the actual canvas height, same relation
    // Processing's own perspective() uses internally - keeps the manual 2D projection and
    // any native 3D camera (perspective(radians(fov), aspect, near, far)) in lockstep,
    // with no separate "lens strength" knob to reconcile between the two.
    float focal = (height * 0.5) / tan(radians(fov) * 0.5);
    return new CameraFrame(camera_pos, right, up, forward, focal);
  }

  @Override
  ProjectedPoint projectPointWithDepth(PVector world, CameraFrame frame)
  {
    PVector relative = PVector.sub(world, frame.camera_pos);
    float x = relative.dot(frame.right);
    float y = relative.dot(frame.up);
    float z = relative.dot(frame.forward);

    if (projection_mode == PROJECTION_ORTHO)
      return new ProjectedPoint(x * ortho_zoom, y * ortho_zoom, z);

    float safe_z = max(0.001, z);
    return new ProjectedPoint(x * frame.focal / safe_z, y * frame.focal / safe_z, z);
  }

  @Override
  PVector projectPoint(PVector world)
  {
    ProjectedPoint p = projectPointWithDepth(world, buildFrame());
    return new PVector(p.x, p.y);
  }

  // Exact inverse of projectPointWithDepth: reconstructs the world-space point from a
  // screen-space projected (x,y) and its camera-space depth z, using the same frame.
  PVector unprojectPoint(float screenX, float screenY, float depthZ, CameraFrame frame)
  {
    float camX, camY;
    if (projection_mode == PROJECTION_ORTHO)
    {
      float safeZoom = max(1e-6, ortho_zoom);
      camX = screenX / safeZoom;
      camY = screenY / safeZoom;
    }
    else
    {
      camX = screenX * depthZ / frame.focal;
      camY = screenY * depthZ / frame.focal;
    }

    PVector world = frame.camera_pos.copy();
    world.add(PVector.mult(frame.right, camX));
    world.add(PVector.mult(frame.up, camY));
    world.add(PVector.mult(frame.forward, depthZ));
    return world;
  }

  PVector getTarget()
  {
    return new PVector(target_x, target_y, target_z);
  }

  PVector getCameraPosition()
  {
    float cosPitch = cos(pitch);
    return new PVector(
      target_x + target_distance * cosPitch * sin(yaw),
      target_y + target_distance * sin(pitch),
      target_z + target_distance * cosPitch * cos(yaw)
    );
  }

  void markChanged()
  {
    changed = true;
  }

  void setTargetDistance(float newDistance)
  {
    target_distance = constrain(newDistance, TARGET_DISTANCE_MIN, TARGET_DISTANCE_MAX);
    markChanged();
  }

  void zoomByWheel(float wheelCount)
  {
    // Mouse wheel > 0 means zoom out, < 0 means zoom in.
    float factor = pow(1.08, wheelCount);
    if (projection_mode == PROJECTION_ORTHO)
      setOrthoZoom(ortho_zoom / factor);
    else
      setTargetDistance(target_distance * factor);
  }

  void panTargetByScreenDelta(float dxPixels, float dyPixels, float viewScale)
  {
    CameraFrame frame = buildFrame();
    float safeViewScale = max(1e-6, viewScale);

    // Convert screen-space drag (pixels) into world-space translation
    // in the camera right/up plane.
    float worldPerPixel;
    if (projection_mode == PROJECTION_ORTHO)
      worldPerPixel = 1.0 / max(1e-6, ortho_zoom * safeViewScale);
    else
      worldPerPixel = target_distance / max(1e-6, frame.focal * safeViewScale);

    PVector deltaRight = PVector.mult(frame.right, -dxPixels * worldPerPixel);
    PVector deltaUp = PVector.mult(frame.up, -dyPixels * worldPerPixel);
    PVector delta = PVector.add(deltaRight, deltaUp);

    target_x += delta.x;
    target_y += delta.y;
    target_z += delta.z;
    markChanged();
  }

  void setOrthoZoom(float newZoom)
  {
    ortho_zoom = constrain(newZoom, ORTHO_ZOOM_MIN, ORTHO_ZOOM_MAX);
    markChanged();
  }

  void resetToView(float newYaw, float newPitch)
  {
    yaw = wrapAngle(newYaw);
    pitch = newPitch;
    markChanged();
  }

  float wrapAngle(float angle)
  {
    while (angle <= -PI) angle += TWO_PI;
    while (angle > PI) angle -= TWO_PI;
    return angle;
  }

  void lookFront()  { resetToView(0, -0.01); }
  void lookBack()   { resetToView(PI, -0.01); }
  void lookLeft()   { resetToView(-HALF_PI, -0.01); }
  void lookRight()  { resetToView(HALF_PI, -0.01); }
  void lookIso()    { resetToView(QUARTER_PI, -0.6); }
  void lookTop()    { resetToView(0, HALF_PI - 0.001); }

  void LoadJson(JSONObject src)
  {
    if (src == null) return;

    projection_mode = src.getInt("projection_mode", projection_mode);
    fov = src.getFloat("fov", fov);
    target_distance = src.getFloat("target_distance", target_distance);
    ortho_zoom = src.getFloat("ortho_zoom", ortho_zoom);
    yaw = src.getFloat("yaw", yaw);
    pitch = src.getFloat("pitch", pitch);
    target_x = src.getFloat("target_x", target_x);
    target_y = src.getFloat("target_y", target_y);
    target_z = src.getFloat("target_z", target_z);
  }

  JSONObject SaveJson()
  {
    JSONObject dest = new JSONObject();
    dest.setInt("projection_mode", projection_mode);
    dest.setFloat("fov", fov);
    dest.setFloat("target_distance", target_distance);
    dest.setFloat("ortho_zoom", ortho_zoom);
    dest.setFloat("yaw", yaw);
    dest.setFloat("pitch", pitch);
    dest.setFloat("target_x", target_x);
    dest.setFloat("target_y", target_y);
    dest.setFloat("target_z", target_z);
    return dest;
  }
}
