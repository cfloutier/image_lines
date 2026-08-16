import controlP5.*;


class CameraGUI extends GUIPanel
{
  CameraData camera;

  myRadioButton projection_mode;
  Slider fov;
  Slider target_distance;
  Slider ortho_zoom;
  Slider yaw;
  Slider pitch;

  CameraGUI(CameraData camera)
  {
    super("Camera", camera);
    this.camera = camera;
  }

  void setupControls()
  {
    super.Init();

    addButton("Front").plugTo(this, "lookFront");
    addButton("Back").plugTo(this, "lookBack");
    addButton("Left").plugTo(this, "lookLeft");
    addButton("Right").plugTo(this, "lookRight");
    addButton("Iso").plugTo(this, "lookIso");
    addButton("Top").plugTo(this, "lookTop");
    nextLine();

    yaw = addSlider("yaw", "Yaw", -PI, PI);
    pitch = addSlider("pitch", "Pitch", -HALF_PI + 0.005, HALF_PI - 0.005);
    target_distance = addSlider("target_distance", "Distance", CameraData.TARGET_DISTANCE_MIN, CameraData.TARGET_DISTANCE_MAX);
    nextLine();
    
    ArrayList<String> projection_modes = new ArrayList<String>();
    projection_modes.add("Ortho");
    projection_modes.add("Perspective");
    projection_mode = addRadio("projection_mode", projection_modes);
    float start_pos = xPos;
    fov = addSlider("fov", "FOV", 10, 180);
    xPos = start_pos;
    ortho_zoom = addSlider("ortho_zoom", "Ortho Zoom", CameraData.ORTHO_ZOOM_MIN, CameraData.ORTHO_ZOOM_MAX);
}

  void setGUIValues()
  {
    fov.setValue(camera.fov);
    target_distance.setValue(camera.target_distance);
    ortho_zoom.setValue(camera.ortho_zoom);
    yaw.setValue(camera.yaw);
    pitch.setValue(camera.pitch);
    projection_mode.activate(camera.projection_mode);
    updateProjectionControlsVisibility();
  }

  void updateProjectionControlsVisibility()
  {
    boolean is_ortho = camera.projection_mode == CameraData.PROJECTION_ORTHO;

    if (is_ortho)
    {
      fov.hide();
      ortho_zoom.show();
    }
    else
    {
      fov.show();
      ortho_zoom.hide();
    }
  }

  void lookFront()  { camera.lookFront(); setGUIValues(); }
  void lookBack()   { camera.lookBack(); setGUIValues(); }
  void lookLeft()   { camera.lookLeft(); setGUIValues(); }
  void lookRight()  { camera.lookRight(); setGUIValues(); }
  void lookIso()    { camera.lookIso(); setGUIValues(); }
  void lookTop()    { camera.lookTop(); setGUIValues(); }

  void update_ui()
  {
    fov.setValue(camera.fov);
    target_distance.setValue(camera.target_distance);
    ortho_zoom.setValue(camera.ortho_zoom);
    yaw.setValue(camera.yaw);
    pitch.setValue(camera.pitch);
    updateProjectionControlsVisibility();
  }
}


class CameraFrame
{
  PVector camera_pos;
  PVector right;
  PVector up;
  PVector forward;
  float focal;

  CameraFrame(PVector camera_pos, PVector right, PVector up, PVector forward, float focal)
  {
    this.camera_pos = camera_pos;
    this.right = right;
    this.up = up;
    this.forward = forward;
    this.focal = focal;
  }
}

class ProjectedPoint
{
  float x;
  float y;
  float z;
  float invz;

  ProjectedPoint(float x, float y, float z)
  {
    this.x = x;
    this.y = y;
    this.z = z;
    this.invz = (z > 1e-6) ? (1.0 / z) : 0;
  }
}

interface CameraProjector3D
{
  CameraFrame buildFrame();
  ProjectedPoint projectPointWithDepth(PVector world, CameraFrame frame);
  PVector projectPoint(PVector world);
}

// Minimum camera-space depth a projected point is allowed to have. Points/segments closer
// than this to the camera plane produce numerically unstable (huge) screen coordinates -
// e.g. screen = camX*focal/z blows up as z->0 - which corrupts unclipped bounding-box
// fitting (global_scale collapsing toward zero, rendering everything invisible when page
// clipping is off and no longer discards those outlier points) and can blow up per-edge
// sample counts (segLenPx huge -> huge step count -> slow builds), independent of clipping.
final float PROJECTION_NEAR_Z = 1.0;

// Clips a world-space segment (with already-projected endpoints pA/pB) against the near
// plane at camera-space depth PROJECTION_NEAR_Z, re-projecting the clipped endpoint (if
// any) from its exact world-space position rather than trusting the original, potentially
// near-zero-z projection. Returns false if the whole segment is at/behind the near plane
// (nothing usable to draw). outWorld/outProjected (each a length-2 array) receive the
// resulting endpoints on success.
boolean clipSegmentToNearPlane(
  PVector worldA, ProjectedPoint pA,
  PVector worldB, ProjectedPoint pB,
  CameraProjector3D camera, CameraFrame frame,
  PVector[] outWorld, ProjectedPoint[] outProjected)
{
  boolean nearA = pA.z < PROJECTION_NEAR_Z;
  boolean nearB = pB.z < PROJECTION_NEAR_Z;

  if (nearA && nearB)
    return false;

  PVector finalWA = worldA, finalWB = worldB;
  ProjectedPoint finalPA = pA, finalPB = pB;

  if (nearA != nearB)
  {
    float t = (PROJECTION_NEAR_Z - pA.z) / (pB.z - pA.z);
    PVector clippedWorld = PVector.lerp(worldA, worldB, t);
    ProjectedPoint clippedProjected = camera.projectPointWithDepth(clippedWorld, frame);

    if (nearA) { finalWA = clippedWorld; finalPA = clippedProjected; }
    else       { finalWB = clippedWorld; finalPB = clippedProjected; }
  }

  outWorld[0] = finalWA; outWorld[1] = finalWB;
  outProjected[0] = finalPA; outProjected[1] = finalPB;
  return true;
}
