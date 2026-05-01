String get_xlib_version()
{
  return "2.2.12";
}


/*

 # CHANGELOG
 
 ## [2.2.12] - 2026-05-01
 - Image.pde renommé en xLib_Image.pde pour intégration dans la xLib partagée

 ## [2.2.11] - 2026-04-17
 - l'export de fichiers svg et pdf a une taille adaptée à la page.

 ## [2.2.10] - 2026-04-13
 - implémentation complète du clipping avec cassure de lignes aux bords
 - addLineSegment() détecte transitions dedans↔dehors et casse les lignes
 - pointInClipRect() fonction partagée pour tester points dedans/dehors clip rect
 - uniformisation de tout.any_change() pour relancer generates quand clipping change

 ## [2.2.9] - 2026-04-13
 - hiérarchie Polyline simplifiée: suppression de SegmentedPolyline
 - SpiralLine utilise maintenant Polyline de base (dessin continu)
 - extraction du clipping en fonction commune clipLineToCenteredRect() dans xLib_ClippingUtils
 - uniformisation complète des xLib_Polyline et xLib_ClippingUtils dans les 3 projets
 
 ## [2.2.8] - 2026-04-13
 - renommage des classes génératrices en supprimant "Drawing"
 - SpiralDrawingGenerator -> SpiralGenerator
 - PerlinDrawingGenerator -> PerlinGenerator
 - noms de fichiers simplifiés
 
 ## [2.2.7] - 2026-04-13
 - refactoring complet des 3 projets avec utiliséation uniforme de Polyline
 - introduction de SpiralLine, PerlinLine, ImageLine pour clarifier les types
 - séparation calcul/rendu avec update() dans DrawingGenerator spiral
 - mécanisme de lazy-update basé sur data.any_change()
 
 ## [2.2.6] - 2026-04-13
 - abstraction de Polyline générique pour perlin_mountains et image_processor
 - création de xLib_Polyline avec classe Polyline de base et ValidatedPolylineWithOffset
 
 ## [2.2.5] - 2025-03-01
 - nettoyage et fix du nom de fichier au moment de la sauvegarde
 
 ## [2.2.4.1] - 2025-02-28
 - ajout du ControlGroup qui permet de groupers les controles d'ui par groupes affichables ou cachables d'un coup.
 - .1 = fix du nom de fichier au moment de la sauvegarde
 
 ## [2.2.3] - 2025-02-28
 - micro nettoyage
 
 ## [2.2.2] - 2025-02-12
 - refacto complete de la gestion des Fichier : UI + data avec l'ajout des slider clipping et scale. sauvegardables enfin
 
 ## [2.2.0] - 2024-06-30
 # - added get_xlib_version() function to return the current version of xLib. This
 #   can be used for debugging and to ensure compatibility with different versions of xLib.
 
 ## [2.1.0] - 2024-05-15
 # - added support for global scale in the DataPage class. This allows users to scale the entire page, which can be useful for printing or exporting to PDF/SVG. The global scale can be adjusted using a slider in the UI.
 
 
 */