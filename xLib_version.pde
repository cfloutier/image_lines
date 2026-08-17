String get_xlib_version()
{
  return "3.12.2";
}


/*

 # CHANGELOG

 ## [3.12.2] - 2026-08-17
 - xLib_MainPanel: setGUIValues()/update_ui() now wrap their panel loop in
   cp5.setBroadcast(false)/true. Several panels' update_ui() unconditionally call
   Controller.setValue() to keep sliders in sync with data (e.g. OcclusionGUI,
   CameraGUI) even when that specific panel's own chapter isn't what changed - and
   since update_ui() runs for every panel whenever any chapter changes, and
   setValue() broadcasts a ControlEvent just like a real user edit, this looped back
   through GUIPanel.controlEvent() -> onUIChanged() and re-marked that other
   chapter "changed" right after it was synced. Harmless everywhere every change
   triggered a full rebuild anyway, but it broke targeted partial rebuilds (trace_3d's
   face-pattern-only recompute): changing an unrelated tab's own parameter could
   spuriously flag Occlusion/Camera as changed too and force a full HLR rebuild.

 ## [3.12.1] - 2026-08-16
 - xLib_FileUI: fixed stop_compute never being reset to false — LoadJson()/SaveJson()/Save()
   set it to true but nothing ever cleared it (not even on dialog cancel), so after the first
   Load/Save of a run it stayed stuck true forever. Harmless everywhere stop_compute was never
   actually read (every other project) but trace_3d's own draw() gates its mesh/line rebuild
   on !stop_compute, so this permanently froze the 3D render after any Load/Save while GUI/style
   changes kept working (style isn't gated by stop_compute). Now reset in loadSelected()/
   saveSelected() (both the picked-a-file and cancelled paths) and at the end of Save().

 ## [3.12.0] - 2026-08-16
 - Removed xLib_Box3D, xLib_BoxIntersection, xLib_BVH3D, xLib_Camera3D, xLib_CameraData, xLib_Mesh
   from the shared library. Only trace_3d ever used these — every other project got them pushed
   anyway (push-to-projects.ps1 syncs every xLib_*.pde to every project indiscriminately) and just
   carried them as dead code, which was tripping up VS Code's Processing linter with spurious
   "duplicate type/method" diagnostics (real compilation was unaffected, but noisy).
   Renamed in trace_3d to xlib3d_Box3D.pde / xlib3d_BoxIntersection.pde / xlib3d_BVH3D.pde /
   xlib3d_Camera3D.pde / xlib3d_CameraData.pde / xlib3d_Mesh.pde (class names unchanged - .pde
   tab names don't need to match their class in Processing) so they fall outside the xLib_*.pde
   glob the sync scripts match on and stop being synced anywhere; deleted from every other project
   and from processing_xlib. No sync-tools script changes needed - filtering is purely by filename.

 ## [3.11.2] - 2026-08-16
 - xLib_FileUI: added bringNativeFileDialogToFront(), called after selectInput()/selectOutput()
   in LoadJson()/SaveJson() (and xLib_Image.SelectSourceImage()) — works around a Processing/JOGL
   quirk seen on trace_3d (P3D renderer) where the native file dialog opens behind the main
   window (which can auto-minimize) instead of getting focus; not observed with the default
   (non-OpenGL) renderer used by 2D projects like image_lines. Polls briefly (up to ~6s) for the
   dialog window via java.awt.Window.getWindows() and forces it to front/focus once AWT creates it.
   Fixes every LoadJson()/SaveJson() call except the very first one of a run (tried a
   warmupNativeFileDialog() companion to pre-create AWT's native FileDialog peer at setup()
   time on the theory that peer creation itself was racing with JOGL - didn't help, reverted;
   first-call cause still unknown, left as a known minor quirk).

 ## [3.11.1] - 2026-08-16
 - xLib_ExportUtils: writeSVGDirect() (both overloads) reads file_ui.export_landscape instead of recomputing its
   own local bbox-derived orientation — keeps orientation and export_scale tied to the same source, avoiding a
   mismatch between the exported page's orientation and the scale used to fit the drawing on it
 - image_lines: draw() now refreshes lines + updateExportScale() BEFORE start_draw() instead of after — previously
   an export triggered right after a data change sized its canvas from the previous frame's stale orientation/scale
   (fix should be mirrored in other xLib-consuming projects with the same any_change()-after-start_draw() ordering)
 - Merged with main (3.10.0, trace_3d/3D camera line of work): combined with main's independent clip/centering fix
   below — clipLineToCenteredRect() must run in raw drawing space (matching clip_width/clip_height, which are not
   relative to the bbox center) before subtracting bcx/bcy, not after; bbox itself is now clip-aware too
   (getBoundingBox(clipping, clip_w, clip_h)) so a clipped export centers on what's actually visible

 ## [3.11.0] - 2026-08-15
 - xLib_ExportUtils: removed the -90° auto-rotation of the drawing at export time (shouldRotateForExport() / export_should_rotate deleted)
   The plotter now handles orientation itself, so it no longer needs to be baked into the SVG.
 - xLib_ExportUtils: getPaperDimensions() gained a landscape parameter — the exported page orientation (portrait/landscape)
   now follows the drawing's aspect ratio instead of always exporting a rotated portrait page
 - xLib_ExportUtils: calculateExportScale() simplified — no longer takes a shouldRotate parameter
 - xLib_ExportUtils: centeredToMM() simplified — no longer takes a rot parameter
 - xLib_ExportUtils: postProcessSVGForPlotter() takes a landscape parameter instead of re-deriving portrait dimensions
   (Processing fallback renderer path); rotate() transform regex removed (no longer emitted)
 - xLib_FileUI: FileGUI.export_should_rotate renamed to export_landscape; start_draw() sizes the export canvas
   using the landscape-aware paper dimensions instead of rotating the content with rotate(-PI/2)
 (originally versioned 3.6.0/3.6.1 before merge — renumbered to 3.11.0/3.11.1 to follow main's 3.10.0,
 since main independently used 3.6.0 onward for the trace_3d 3D-camera line of work below)

 ## [3.10.0] - 2026-08-14
 - xLib_Camera3D: ajout de PROJECTION_NEAR_Z + clipSegmentToNearPlane() — clippe les segments
   projetes contre un plan proche (1 unite monde), evite les coordonnees ecran instables
   (division par z quasi-nul) qui faisaient exploser le bounding-box auto-fit et le nombre
   d'echantillons par arete
 - xLib_Box3D: appendProjectedEdges() utilise desormais clipSegmentToNearPlane() par arete
 - trace_3d: LineBuilder.projectSeamEdges() applique le meme clip proche ; nouveau message
   d'avertissement plein ecran quand Page.clipping est desactive (le fit d'echelle export
   n'est pas garanti sans lui - non corrige plus avant, cf. commentaire dans trace_3d.pde)
 - xLib_FileUI: FileGUI.ExportSVG() ne reference plus directement lineBuilder (fuite
   specifique a trace_3d qui cassait la compilation des autres projets) - remplace par un
   hook generique optionnel ExportBusyGuard (export_busy_guard), laisse a null par defaut

 ## [3.9.0] - 2026-08-13
 - xLib_CameraData: suppression de focal_distance (et FOCAL_DISTANCE_MIN/MAX) — la focale perspective
   repose desormais uniquement sur fov, via focal = (height * 0.5) / tan(radians(fov) * 0.5), la meme
   relation qu'utilise perspective() de Processing en interne (aligne le modele de camera manuel 2D
   sur un modele de vraie camera 3D, en vue d'un futur rendu 3D natif)
 - xLib_Camera3D: CameraGUI perd le slider Focal Distance (fov reprend sa place en mode Perspective)

 ## [3.8.0] - 2026-08-13
 - xLib_BVH3D: ajout de queryOverlaps() — requête de recouvrement AABB (broad-phase), en plus du any-hit rayon existant
 - xLib_Box3D: ajout de FACE_IDX (les 6 faces en quads) pour la détection d'intersections
 - xLib_BoxIntersection: nouveau fichier — calcule les segments de "couture" où deux Box3D se croisent
   (intersection de plans face/face + double découpage rectangulaire), sans CSG solide ni face capping
 - xLib_Mesh: EdgeProjected porte désormais un second index de propriétaire optionnel (ownerOccluderIndexB,
   -1 par défaut) — une arête de couture appartient à deux boîtes à la fois, les deux profitent du seuil
   tolérant d'auto-occlusion
 - trace_3d: LineBuilder construit et met en cache les seam edges (recalculées seulement quand les occludeurs
   changent, jamais au simple drag caméra) ; nouveau toggle Occlusion.seam_edges_enabled (off par défaut, coût
   O(paires qui se recouvrent x 36 tests de faces))

 ## [3.7.0] - 2026-08-13
 - xLib_BVH3D: nouveau fichier — BVH générique (broad-phase spatial), traversée "any-hit" itérative sans allocation
 - xLib_Box3D: ajout de intersectRaySlab() (intersection rayon/OBB exacte, méthode des slabs en repère local, gère la rotation),
   computeWorldAABB(), getWorldGeometricCenter(), getDiagonal() — suppression de TRI_IDX et getProjectedVertices() (plus utilisés)
 - xLib_Mesh: TriangleProjected supprimé ; EdgeProjected porte désormais les coordonnées monde + un index d'occludeur propriétaire ;
   nouvelle classe OccluderBox (bbox monde + centre + diagonale + epsilon) ; Mesh.appendProjectedOcclusionGeometry()
   remplacé par buildOccluder() + appendProjectedEdges() (sépare la géométrie monde, camera-indépendante, de la projection écran)
 - xLib_CameraData: ajout de unprojectPoint() — inverse exact de projectPointWithDepth() (écran+profondeur -> monde),
   perspective et ortho
 - trace_3d: LineBuilder remplace le HLR par rastérisation z-buffer par un HLR analytique (ray-casting objet-space vers la
   caméra + BVH, intersection rayon-boîte exacte, bissection pour les points de coupure), corrige les artefacts de visibilité
   près des silhouettes et l'auto-occlusion (chord length au lieu du tEntry seul) ; DataOcclusion perd zbuffer_scale/depth_bias
   au profit de bisection_iterations/self_occlusion_eps_scale

 ## [3.6.0] - 2026-07-17
 - xLib_Mesh: nouveau fichier avec Mesh (classe abstraite) + EdgeProjected + TriangleProjected
 - xLib_Box3D: nouveau fichier, Box3D herite de Mesh et encapsule sa decomposition edges/triangles
 - xLib_Camera3D: nouveau fichier avec CameraFrame, ProjectedPoint et interface CameraProjector3D
 - xLib_CameraData: nouveau fichier, CameraData implemente CameraProjector3D
 - xLib_MainPanel: ajout de mouseWheel(event) en override optionnel + forwarding global mouseWheel vers dataGui
 - sync-tools/projects.ps1: ajout de trace_3d dans la liste des projets synchronises

 ## [3.5.0] - 2026-06-04
 - xLib_GenericData: getDeclaredFields() / getDeclaredField() remplacés par getAllInstanceFields() / findFieldInHierarchy()
   parcourent toute la hiérarchie de classes (super inclus) — fix sérialisation, désérialisation et CopyFrom pour les classes dérivées de GenericData
 - xLib_GenericData: champs "chapter_name" et "chapters" exclus de la sérialisation / CopyFrom (évite la corruption JSON)
 - xLib_GenericData: setInt() utilise désormais findFieldInHierarchy() — fix affectation de champs hérités

 ## [3.4.0] - 2026-06-03
 - curved_lines: nouveau projet — courbes offset basées sur Catmull-Rom splines
 - xLib_Polyline: ajout dans projects.ps1 de curved_lines

 ## [3.3.0] - 2026-05-28
 - xLib_ThresholdData: new file — DataThreshold + ThresholdGUI shared between image_lines and image_contours
   Supports 6 distribution modes: PROGRESSIVE, MIRROR, HACHURES, INTERLEAVED, BISECT, BISECT_BFS
 - xLib_Polyline: added group_id field (default -1) — used by threshold filters to cycle thresholds per line group / contour level

 ## [3.2.0] - 2026-05-26
 - xLib_ExportUtils: PAPER_NONE no longer aborts writeSVGDirect — fallback to canvas pixel dimensions (K=1, units=px)
 - xLib_ExportUtils: added PAPER_RAISIN (4) — Grand Raisin 500x650 mm
 - xLib_ExportUtils: all console prints renamed [SVG] → [SVG direct] for clarity
 - xLib_FileUI: ExportSVG() — removed paper_format != PAPER_NONE condition, direct writer always used when data connected
 - xLib_FileUI: added [SVG direct] / [SVG Processing] console prints to distinguish export paths
 - xLib_FileUI: button renamed "Export SVG" → "SVG direct"
 - xLib_FileUI: added Raisin to paper format radio button and _Raisin filename suffix

 ## [3.1.0] - 2026-05-25
 - xLib_ExportUtils: added writeSVGDirect(ShapesGroup) overload — exports dots as zero-length SVG lines with round linecap (AxiDraw convention)
 - xLib_ShapesGroup: new file — Dot class (PVector pos) and ShapesGroup class (ArrayList<Polyline> + ArrayList<Dot>)
   Includes draw(), getBoundingBox(), addDot(), addPolyline(), clear(), totalCount(), dotCount(), polylineCount()
 - xLib_FileUI: added export_shapes (ShapesGroup) field — checked before export_group in ExportSVG()
 - xLib_ExportUtils: centeredToMM() rotation fixed from -90deg to +90deg (swapped direction)

 ## [3.0.0] - 2026-05-25
 - xLib_ExportUtils: added writeSVGDirect() — direct SVG writer bypassing Processing's SVG renderer
   Writes coordinates in mm using the same transform as start_draw() (auto-centering via bbox, optional -90deg rotation)
   Handles clipping (clipLineToCenteredRect per segment) and non-clipping (continuous path per polyline)
   Prints console progress every 10% of polylines
 - xLib_ExportUtils: added centeredToMM() helper for drawing-space to mm page coordinate conversion
 - xLib_FileUI: FileGUI.export_group (PolylineGroup) — set in sketch setup() to enable direct SVG export
 - xLib_FileUI: ExportSVG() uses direct writer when export_group is set + paper format selected; falls back to Processing renderer otherwise
 - xLib_FileUI: added ExportSVGProcessing() — forces Processing's SVG renderer (legacy fallback button)
 - xLib_FileUI: removed Export PDF button from GUI

 ## [2.4.0] - 2026-05-22
 - xLib_ExportUtils: removed EXPORT_DPI — getPaperDimensions() now returns mm (physical units)
 - xLib_ExportUtils: added mmToSvgPx() — mm to SVG px conversion using fixed standard (96px/inch, not a calibration value)
 - xLib_FileUI: SVG/PDF canvas sized via mmToSvgPx() instead of a configurable DPI
 - xLib_ExportUtils: replaced 10cm margin option with 2cm — margins are now 0cm, 1cm, 2cm, 3cm
 - Fix: A3 export was producing A2 output in Inkscape (EXPORT_DPI=135 ≈ 96×√2 caused one paper size offset)

 ## [2.3.0] - 2026-05-22
 - xLib_FileUI: ScaleSlider caption label aligned consistently with other sliders (marginTop/marginLeft)
 - image_lines: Image tab opened by default

 ## [2.2.20] - 2026-05-22
 - xLib_Image: draw toggle and imageAlpha moved to DataImage (saved/loaded via JSON)
 - xLib_Image: blackAndWhite toggle — applies GRAY filter during buildTransformedImage
 - xLib_Image: levels adjustment (levelsMin, levelsMax, levelsGamma) applied pixel-by-pixel; gamma uses -1..1 slider mapped via pow(5,x)
 - xLib_Image: Reset Levels button restores default level values
 - xLib_Image: buildBlurredImage renamed to buildTransformedImage

 ## [2.2.19] - 2026-05-22
 - processing_xlib: création du fichier .github/copilot-instructions.md avec le contexte xLib (workflow, projets synchronisés, scripts)
 
 ## [2.2.18] - 2026-05-18
 - xLib_Polyline: added getBoundingBox() method to calculate the bounding box of a polyline, used for clipping and export.
 - xLib_Polyline: added PolylineGroup class to manage groups of polylines with integrated clipping and bounding box support.


 ## [2.2.17] - 2026-05-10
 - processing_xlib: switched to PolylineGroup for drawing and bbox — clipping logic no longer duplicated in sketch
 - processing_xlib: buildLines() generates N polylines with random point count (nb_points_min to nb_points_max) on the ellipse
 - processing_xlib: replaced nb_lines with nb_polylines, nb_points_min, nb_points_max parameters


 ## [2.2.16] - 2026-05-18
 - xLib_Image: renamed blurred_image to transformed_image to reflect that it may also include contrast changes (TODO), not just blur 

 ## [2.2.15] - 2026-05-10
 - xLib_FileUI: FileGUI constructor takes optional boolean show_clipping (default false) — hides clipping controls in projects that don't use it

 ## [2.2.14] - 2026-05-10
 - xLib_Image: ImageAlpha removed from DataImage — now GUI-only in ImageGUI (no longer triggers data.changed or regeneration)
 - xLib_Image: draw() now takes imageAlpha as a parameter instead of reading data.ImageAlpha
 - xLib_Image: ImageGUI.controlEvent() overridden to handle the alpha slider without propagating a change
 - xLib_StringUtils: added formatDuration(int ms) — formats a duration in ms/s/min/h/d
 - xLib_StringUtils: fix isEmpty() (spurious blank line removed)

 ## [2.2.13] - 2026-05-02
 - xLib_Image.draw(): coordinates corrected for centring via translate (origin already at centre via start_draw)
 - image drawn at (-image_w/2, -image_h/2) instead of (width/2 - image_w/2, height/2 - image_h/2)

 ## [2.2.12] - 2026-05-01
 - Image.pde renamed to xLib_Image.pde for integration into the shared xLib
 - xLib_Image: _image_gui global variable to avoid errors in projects without an image
 - imgFileSelected() checks _image_gui != null before calling setImage()

 ## [2.2.11] - 2026-04-17
 - SVG and PDF export now use page-adapted dimensions.

 ## [2.2.10] - 2026-04-13
 - Full clipping implementation with line breaking at edges
 - addLineSegment() detects inside↔outside transitions and breaks lines
 - pointInClipRect() shared function to test whether points are inside/outside the clip rect
 - Unified any_change() to re-trigger generation when clipping changes

 ## [2.2.9] - 2026-04-13
 - Simplified Polyline hierarchy: removed SegmentedPolyline
 - SpiralLine now uses base Polyline (continuous drawing)
 - Clipping extracted into shared clipLineToCenteredRect() in xLib_ClippingUtils
 - Full unification of xLib_Polyline and xLib_ClippingUtils across all 3 projects

 ## [2.2.8] - 2026-04-13
 - Renamed generator classes by removing "Drawing"
 - SpiralDrawingGenerator -> SpiralGenerator
 - PerlinDrawingGenerator -> PerlinGenerator
 - Simplified file names

 ## [2.2.7] - 2026-04-13
 - Full refactoring of all 3 projects with uniform Polyline usage
 - Introduced SpiralLine, PerlinLine, ImageLine to clarify types
 - Separated computation/rendering with update() in DrawingGenerator spiral
 - Lazy-update mechanism based on data.any_change()

 ## [2.2.6] - 2026-04-13
 - Generic Polyline abstraction for perlin_mountains and image_processor
 - Created xLib_Polyline with base Polyline class and ValidatedPolylineWithOffset

 ## [2.2.5] - 2025-03-01
 - Cleanup and fix of filename at save time

 ## [2.2.4.1] - 2025-02-28
 - Added ControlGroup to allow grouping UI controls that can be shown/hidden together
 - .1 = fix of filename at save time

 ## [2.2.3] - 2025-02-28
 - Minor cleanup

 ## [2.2.2] - 2025-02-12
 - Complete refactoring of file management: UI + data with added clipping and scale sliders, now properly saved

 ## [2.2.0] - 2024-06-30
 # - added get_xlib_version() function to return the current version of xLib. This
 #   can be used for debugging and to ensure compatibility with different versions of xLib.

 ## [2.1.0] - 2024-05-15
 # - added support for global scale in the DataPage class. This allows users to scale the entire page, which can be useful for printing or exporting to PDF/SVG. The global scale can be adjusted using a slider in the UI.
 
 
 */
