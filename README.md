# 📂 FoldyDock

**FoldyDock** est une application macOS native offrant un dock flottant alternatif élégant doté d'un système de dossiers d'applications inspiré d'iOS, d'interactions avancées à la souris et d'un masquage automatique fluide.

---

## ✨ Fonctionnalités Clés

1. **Dock Flottant en Verre Liquide (Liquid Glass)**
   - Barre centrée au bas de l'écran principal.
   - Matériau `NSVisualEffectView` (`.hudWindow`) avec bordure lumineuse et flou d'arrière-plan moderne.
   - Fenêtre `NSPanel` de niveau `.floating` non-intrusive (ne vole pas le focus des applications actives).

2. **Masquage Automatique Réactif (Autohide)**
   - Détection de la sortie du curseur via `NSTrackingArea`.
   - Rétraction animée vers le bas après un délai réglable (0,3 seconde par défaut).
   - Panneau déclencheur invisible au ras du bord inférieur (`HotspotPanel`) permettant une réapparition instantanée dès que la souris touche le bas de l'écran.

3. **Dossiers d'Applications style iOS**
   - **Miniatures Dynamiques & Évolutives :** Les dossiers affichent toutes les applications qu'ils renferment sans aucune limite de nombre. La grille s'adapte automatiquement (2x2 jusqu'à 4 apps, 3x3, 4x4, etc.) et réduit la taille des icônes au fur et à mesure que le dossier s'enrichit.
   - **Titres et Noms au-dessus des Éléments :** Les noms des dossiers et des applications sont affichés de manière harmonieuse au-dessus de chaque icône dans la marge supérieure du dock, avec une typographie arrondie lisible et une ombre douce. Pour distinguer instantanément les dossiers des applications, le titre des dossiers est affiché en **gras** tandis que celui des applications reste normal.
   - **Popover Liquide & Réorganisation par Drag & Drop :** Cliquer sur un dossier déploie une vue modale élégante au-dessus du dock avec la grille d'applications agrandie (icônes 52 pt, disposition centrée pour 2 apps, espacement optimisé pour 6 apps). Les noms des applications sont affichés au-dessus de chaque icône pour une cohérence visuelle parfaite. Les applications au sein d'un dossier peuvent être réorganisées directement par glisser-déposer (Drag & Drop).
   - **Renommage direct :** Modification du nom du dossier par double-clic sur le titre ou via le bouton d'édition.
   - **Création instantanée par Drag & Drop :** Glisser une application au centre d'une autre déclenche la création d'un nouveau dossier ou son insertion dans un dossier existant.

4. **Redimensionnement Dynamique & Immédiat par les Bords**
   - **Poignées de redimensionnement gauche & droite :** Survoler les extrémités latérales du dock transforme automatiquement le curseur en icône de défilement / redimensionnement horizontal (`NSCursor.resizeLeftRight`).
   - **Échelle dynamique en temps réel (1:1) :** Faire glisser le bord vers l'extérieur agrandit instantanément le dock, les dossiers et l'ensemble des icônes d'applications ; glisser vers l'intérieur les réduit.
   - **Protection anti-masquage & Persistance :** Le masquage automatique est suspendu pendant le glissement, et la nouvelle taille (`iconSize`) est sauvegardée automatiquement dans `config.json`.

5. **Interactions Souris & Contrôles Avancés**
   - **Clic gauche :** Lance l'application ou l'amène au premier plan via `NSWorkspace`, avec animation de saut/rebond (`BouncingModifier`). Si l'application se trouve dans un dossier fermé, le dossier rebondit pour signaler le lancement.
   - **Clic milieu (`otherMouseDown` avec `buttonNumber == 2`) :** Ferme immédiatement l'application ciblée via `NSRunningApplication.terminate()`. Fonctionne également directement sur une sous-application depuis l'icône du dossier.
   - **Clic droit sur un élément :** Menu contextuel complet (« Ouvrir », « Quitter l'application », « Conserver dans le dock », « Renommer », « Dissocier le dossier », « Supprimer le séparateur »).
   - **Clic droit sur le fond du dock :** Ouvre le menu contextuel permettant d'accéder directement à la fenêtre dédiée des réglages (« Paramètres FoldyDock… »), d'ajouter un séparateur visuel ou de créer un dossier vide.
   - **Glisser-déposer (Drag & Drop) :**
     - Survol central (anneau de fusion bleu) : Fusionne en dossier.
     - Déplacement latéral : Réorganise l'ordre des éléments sur l'axe horizontal.

6. **Surveillance des Processus, Épinglage, Corbeille & Éléments Spéciaux**
   - Suivi en temps réel des applications actives (`NSWorkspace.shared.notificationCenter`).
   - Badge d'épinglage visuel discret en verre liquide (`PinBadgeView`) sur le coin supérieur droit des applications et dossiers épinglés sur le dock principal.
   - Séparateur vertical visuel distinguant les applications épinglées des applications ouvertes temporaires.
   - Possibilité d'insérer des séparateurs manuels (`.separator`) pour organiser son dock en sections.
   - **Corbeille native à l'extrémité droite (`TrashItemView`) :** Affiche l'icône native de la corbeille macOS tout à droite du dock (séparée par un diviseur). Un clic gauche l'ouvre dans le Finder, un clic droit permet de l'ouvrir ou de la vider. Y déposer un élément par glisser-déposer supprime l'élément du dock ou ferme l'application. Son affichage peut être masqué ou réactivé depuis la fenêtre des paramètres.
   - **Indicateur d'activité multi-fenêtres :** Pastilles lumineuses sous l'icône de chaque application active reflétant le nombre de fenêtres ouvertes :
      - 1 fenêtre ou application en arrière-plan : 1 pastille centrale.
      - 2 fenêtres ouvertes : 2 pastilles côte à côte.
      - 3 fenêtres ouvertes : 3 pastilles côte à côte.
      - 4 fenêtres ou plus (au-delà de 3) : 2 pastilles côte à côte accompagnées d'une petite icône `+` géométrique dédiée (`MiniPlusShape`).
      - **Dossiers et sous-applications :** Sur le dock, le dossier affiche une unique pastille simple signalant la présence d'au moins une application active. À l'intérieur du dossier (vue popover et aperçu de grille), chaque sous-application affiche ses propres multi-pastilles en fonction de ses fenêtres ouvertes.

7. **Fenêtre Dédiée de Paramètres, Persistance JSON & Menu Bar**
   - **Identité Visuelle & Logo Officiel (`logoFoldyDock.png`) :** Intégration du logo officiel FoldyDock haute résolution dans la barre des menus macOS (icône Retina 18×18 pt avec infobulle native) et au sommet de la fenêtre de réglages (48×48 pt). L'icône de l'application (`AppIcon.icns`) est également générée et intégrée au bundle `FoldyDock.app`.
   - **Fenêtre Dédiée de Réglages (`FoldyDockSettingsView` & `SettingsWindowController`) :** Accessible depuis le menu de la barre de menus macOS (« Paramètres FoldyDock… ») ou via un clic droit sur un espace vide du dock. Permet d'ajuster en direct la taille des icônes (32 à 96 pt avec raccourcis de presets), l'autohide et son délai de rétraction (0,1 à 1,5 s), d'activer/désactiver la corbeille, d'insérer séparateurs ou dossiers, de réinitialiser la disposition d'origine ou de quitter l'application.
   - Configuration sauvegardée de manière atomique dans `~/Library/Application Support/FoldyDock/config.json` (avec migration automatique depuis `FolderDock` si présent).
   - Icône dans la barre des menus macOS : un clic déploie le menu complet intégrant l'accès aux « Paramètres FoldyDock… » (raccourci ⌘,), l'affichage forcé du Dock, le basculement rapide de l'autohide, la réinitialisation et l'arrêt de l'application.

---

## 🛠 Compilation & Lancement

### Prérequis
- macOS 14.0 Sonoma ou supérieur
- Xcode 15+ ou Swift 5.9+

### Lancer la suite de tests
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

### Compiler et empaqueter le bundle `FoldyDock.app`
```bash
./scripts/build_app.sh
```

### Compiler et lancer directement
```bash
./scripts/build_app.sh run
```

---

## 📁 Architecture du Code

- **`Sources/FoldyDock/`**
  - `Main.swift` : Point d'entrée `@main`, cycle de vie `NSApplicationDelegate`, gestion de la barre des menus.
  - `Models/` :
    - `DockItem.swift` : Structure arborescente unifiée (`.app`, `.folder`, `.separator`).
    - `DockConfig.swift` : Configuration globale, presets d'applications par défaut et options (autohide, taille, affichage de la corbeille).
  - `Services/` :
    - `AppObserverService.swift` : Surveillance des lancements et fermetures de processus, et comptage précis des fenêtres ouvertes via l'API Accessibility (AXUIElement).
    - `DockPersistenceService.swift` : Sérialisation / désérialisation JSON atomique et migration automatique.
    - `IconProvider.swift` : Extraction d'icônes macOS et composition de grille pour les dossiers.
    - `LogoProvider.swift` : Gestion, mise à l'échelle Retina et résolution dynamique de l'icône et du logo officiel FoldyDock.
  - `ViewModels/` :
    - `DockViewModel.swift` : Logique d'état MVVM, drag-and-drop, réorganisation (principale et intra-dossier), fusion, animations de rebond, gestion de la corbeille, filtrage automatique et déclenchement de la fenêtre de paramètres.
  - `Window/` :
    - `DockPanel.swift` : `NSPanel` flottant gérant la position, les animations et l'autohide.
    - `HotspotPanel.swift` : Déclencheur tactile au bord inférieur de l'écran.
    - `SettingsWindowController.swift` : Contrôleur singleton de la fenêtre dédiée de paramètres native macOS.
    - `VisualEffectBackground.swift` : Wrapper AppKit pour le flou de verre liquide.
  - `Views/` :
    - `DockContainerView.swift` : Vue racine du Dock, conteneur horizontal, séparateurs, corbeille et poignées latérales.
    - `DockItemView.swift` : Rendu des éléments (app, dossier, séparateur), titres au-dessus des icônes, animations de survol, drag-and-drop et menus contextuels.
    - `TrashItemView.swift` : Vue de la corbeille native macOS à droite du dock avec interactions de clic, menu contextuel et zone de dépôt (drop-to-trash).
    - `ResizeHandleView.swift` : Poignées natives de redimensionnement gauche/droite avec curseur horizontal interactif.
    - `FolderIconGrid.swift` : Rendu dynamique et évolutif de la grille d'icônes miniatures avec alignement strict des cellules.
    - `FolderPopoverView.swift` : Popover étendu d'un dossier avec grille complète d'applications agrandies, titres au-dessus, réorganisation par drag-and-drop et renommage direct.
    - `MultiWindowIndicatorView.swift` : Composant d'affichage des pastilles d'activité multi-fenêtres avec forme géométrique dédiée MiniPlusShape pour un alignement sans distorsion.
    - `FoldyDockSettingsView.swift` : Vue complète de la fenêtre de paramètres avec logo haute résolution, réglages de comportement, taille, corbeille, séparateurs et réinitialisation.
    - `PinBadgeView.swift` : Badge visuel en verre liquide indiquant le statut épinglé d'un élément.
    - `BouncingModifier.swift` : Animation fluide de rebond/saut d'icône lors du lancement d'application.
    - `MouseInteractionModifier.swift` : Gestion unifiée des clics gauche, milieu et droit.
- **`Tests/FoldyDockTests/`**
  - `DockItemTests.swift` : Tests de sérialisation, détection d'apps et modèles.
  - `DockViewModelTests.swift` : 35 tests couvrant la logique métier (création/fusion/dissolution de dossiers, redimensionnement, réorganisation intra-dossier, rebonds, corbeille, multi-fenêtres, persistance, filtrage des anciens items de réglages).
