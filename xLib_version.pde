String get_xlib_version()
{
  return "4.4.0";
}


/*

 # CHANGELOG

 ## [4.4.0] - 2026-08-27
 - xLib_ThresholdData.pde (image_lines, image_contours): clicking the "Black Lines"
 toggle now also swaps Style's Line/Background colors, same as the Style tab's own
 "Invert" button - "Black Lines" is this project's equivalent of image_dots' Dots-tab
 Invert toggle (flips which tonal range is treated as filled), wired the same way
 (image_dots gets the same wiring, but its Invert toggle is project-specific code, not
 a shared xLib file, so no version bump needed there).

 ## [4.3.0] - 2026-08-27
 - Style tab: new "Invert" button swaps Line Color / Background Color (and re-tints both
 trigger buttons to match).

 ## [4.2.1] - 2026-08-27
 - Custom mode's OK button given more clearance below the SV square (was crowding the
 Slider2D's own "0,0" value label right beneath it).

 ## [4.2.0] - 2026-08-27
 - Custom mode now has an "OK" button (below the SV square) to close the popup - unlike a
 swatch click, dragging the hue/SV controls has no discrete "done" moment, so it used to
 only close by switching tabs, which wasn't obvious.

 ## [4.1.0] - 2026-08-27
 - init_xlib()/setupColorPopup() gained an optional `boolean autoDraw` parameter
 (defaults to true, matching prior behavior exactly). Pass false to skip the color
 popup's automatic registerMethod("draw", colorPopup) and call colorPopup.draw()
 manually instead, wherever your own draw loop has the right state for it - needed for
 trace_3d (P3D, manual ControlP5 drawing via drawControlP5() for the same reason).

 ## [4.0.0] - 2026-08-27
 - New ColorChooser popup: replaces the big inline swatch grid with a small square
 trigger button (any tab can offer one via GUIPanel.addColorChooser()) that opens a
 shared color-picker overlay.
 - Several built-in swatch palettes to pick from (Default, Rainbow, POSCA, Stabilo 88),
 switchable via buttons at the top of the popup - projects can register their own too.
 - A "Custom" mode for exact color selection: a saturation/brightness square plus a hue
 bar, both draggable, updating the color live as you drag.
 - The Style tab's Line Color / Background Color now use this new picker.
 - Breaking: every project's own setup() must call the new init_xlib() (creates cp5,
 labels its "default" tab, sets up the color popup) instead of doing that itself -
 replace `cp5 = new ControlP5(this); cp5.getTab("default").setLabel("Hide GUI");` with
 `init_xlib();`. Also needs a `ColorChooserPopup colorPopup;` global declared next to
 `cp5` (Java requires the field itself to live in the sketch's own class - can't be
 hidden inside init_xlib()).

 ## [3.14.0] - 2026-08-26
 - Removed ColorRef from xLib_Style/xLib_ColorRef. Style.lineColor/backgroundColor are now
 plain color fields instead of a ColorRef wrapper - GenericData's generic reflection already
 round-trips color fields through JSON (color is int at the JVM level), under the same keys
 ColorRef used, so no custom LoadJson/SaveJson is needed anymore. The Style tab's swatch grid
 (ColorGroup/ColorButton) now writes a picked color through a small ColorSetter callback
 interface instead of mutating a shared ColorRef object - breaking API change:
 GUIPanel.addColorGroup(label, ColorRef) is now addColorGroup(label, ColorSetter). No backward
 compatibility kept; other xLib-based projects need their own Style/ColorRef consumers (e.g.
 any per-project ColorRef-typed field) adapted on sync.
 
 ## [3.13.4] - 2026-08-18
 - xLib_FileUI: added a "1:1" (square) option to the clip aspect-ratio radio
 (DataPage.ASPECT_1_1). Appended after ASPECT_RAISIN rather than inserted earlier
 in the enum, since addRadio() assigns each item's value by its position in the
 labels list - inserting it would have renumbered A4/16:9/4:3/Raisin and silently
 reinterpreted any settings file already saved with a clip_aspect_ratio value.
 
 ## [3.13.3] - 2026-08-18
 - xLib_FileUI: flipping the clip aspect-ratio "Landscape" toggle now directly swaps
 clip_width/clip_height instead of recomputing height from width via
 getClipAspectRatioValue(mode, clip_landscape) - the recompute intermittently used
 a stale clip_landscape value (dependent on exactly when ControlP5 updates the
 bound field relative to the toggle's own ControlEvent firing), requiring an
 extra touch of a clip slider before the new orientation actually took effect. A
 ratio-locked pair already satisfies width/height = r or 1/r, so swapping them is
 simpler and has no such ordering dependency.
 
 ## [3.13.2] - 2026-08-17
 - xLib_FileUI: clip aspect-ratio lock (added in 3.13.1's clip_aspect_ratio radio)
 gains a "Landscape" toggle (DataPage.clip_landscape) to pick which side (width or
 height) gets the preset's long dimension - e.g. upright vs. sideways A4. Ratio
 lookup split into getClipAspectRatioMagnitude() (long/short, always >= 1) and
 getClipAspectRatioValue(mode, landscape) (actual width/height ratio for the
 chosen orientation); flipping the toggle re-snaps height to the current width
 under the new orientation, same as picking a different ratio preset does.
 
 ## [3.13.1] - 2026-08-17
 - xLib_GUIPanel: addRadio() now names each item "<radio_name>_<label>" instead of
 just "<label>" when registering it with ControlP5, restoring the plain label as
 the item's displayed caption text afterward. addItem()'s name argument is a
 ControlP5 controller name in a flat, sketch-wide namespace (not scoped to the
 radio group it belongs to) - two different radios offering an option with the
 same label (e.g. "A4", used by both an export-paper radio and a new clip
 aspect-ratio radio in xLib_FileUI) collided: ControlP5 logged a "Controller ...
 already exists, overwriting reference" warning and the second radio's item
 silently reused the first one's controller instead of being created, so it never
 rendered or responded to clicks.
 
 ## [3.13.0] - 2026-08-17
 - xLib_FileUI: Load and "Save as..." no longer open the native selectInput() file
 dialog (the one that could open behind the main window on P3D/JOGL sketches like
 trace_3d) - replaced by an in-app ControlP5 file picker built entirely on top of
 the existing "Files" tab and the built-in "default"/"Hide GUI" tab:
 - Load: browses Settings/ (including sub-folders, e.g. perlin_mountains' presets
 organized under Settings/mountains/, Settings/hairs/, etc.), one button per
 file/folder, with ".." to go up and Prev/Next pagination beyond a fixed slot pool.
 - Save as...: same browser, either click an existing file (asks for confirmation
 before overwriting) or type a new name in a text field (pre-filled with the
 current file's name, auto-focused, ".json" appended automatically, redirects to
 the same overwrite confirmation on a name collision).
 - The picker's controls live on the "default" tab (enterState() brings it to
 front while active, and back to "Files" on Cancel/completion) instead of the
 Files tab itself, so Files stays uncluttered when not picking.
 - stop_compute is driven from a single state-transition function, avoiding the
 kind of stuck-true regression fixed in 3.12.1.
 - bringNativeFileDialogToFront() itself is unchanged and still used by
 xLib_Image.pde's image-source picker (out of scope for this change).
 - Fixed along the way: ControlP5 re-fires a click within the same frame when the
 button under the cursor is relabeled synchronously inside its own click handler
 (observed navigating into a folder: the same slot, now showing a different
 entry, was clicked a second time in the same frame) - folder/up/prev/next
 navigation now defers the actual relabeling to the next draw() frame and
 ignores a second nav action inside one frame.
 
 ## [3.12.3] - 2026-08-17
 - xLib_Style: LoadJson() now sets changed = true at the end, like the base
 GenericData.LoadJson() does - this custom override never did, so a project's own
 draw()-gate checks on style.changed (or any per-chapter "did this change" check)
 never saw a Load as a change. Same latent bug found and fixed in several
 trace_3d-local (non-synced) files with their own custom LoadJson() overrides -
 DataBoxes, DataOcclusion, CameraData, DataFacePattern - none of them propagated
 "changed" either. Previously masked by MainPanel.setGUIValues() calling
 Controller.setValue() with broadcast still enabled (setValue() firing a
 ControlEvent like a real edit, incidentally marking every chapter "changed" as a
 side effect) - now that 3.12.2 correctly suppresses that broadcast, this
 pre-existing gap became visible: trace_3d stopped rebuilding its box mesh after a
 Load, since DataBoxes.changed was never set.
 
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