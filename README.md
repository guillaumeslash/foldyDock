# 📂 FolderDock

**FolderDock** est une application macOS native offrant un dock flottant alternatif élégant doté d'un système de dossiers d'applications inspiré d'iOS, d'interactions avancées à la souris et d'un masquage automatique fluide.

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
   - **Noms des Dossiers dans le Dock :** Le nom de chaque dossier est affiché sous son icône avec troncature intelligente par ellipses (`…`) s'il dépasse la largeur disponible, s'ajustant en temps réel lors du redimensionnement du dock.
   - **Popover Liquide :** Cliquer sur un dossier déploie une vue modale élégante au-dessus du dock avec la grille complète de toutes les applications du dossier.
   - **Renommage direct :** Modification du nom du dossier par double-clic sur le titre ou via le bouton d'édition.
   - **Création instantanée par Drag & Drop :** Glisser une application au centre d'une autre déclenche la création d'un nouveau dossier ou son insertion dans un dossier existant.

4. **Redimensionnement Dynamique & Immédiat par les Bords**
   - **Poignées de redimensionnement gauche & droite :** Survoler les extrémités latérales du dock transforme automatiquement le curseur en icône de défilement / redimensionnement horizontal (`NSCursor.resizeLeftRight`).
   - **Échelle dynamique en temps réel (1:1) :** Faire glisser le bord vers l'extérieur agrandit instantanément le dock, les dossiers et l'ensemble des icônes d'applications ; glisser vers l'intérieur les réduit.
   - **Protection anti-masquage & Persistance :** Le masquage automatique est suspendu pendant le glissement, et la nouvelle taille (`iconSize`) est sauvegardée automatiquement dans `config.json`.

5. **Interactions Souris & Contrôles Avancés**
   - **Clic gauche :** Lance l'application ou l'amène au premier plan via `NSWorkspace`.
   - **Clic milieu (`otherMouseDown` avec `buttonNumber == 2`) :** Ferme immédiatement l'application ciblée via `NSRunningApplication.terminate()`.
   - **Clic droit :** Menu contextuel complet (« Ouvrir », « Quitter l'application », « Conserver dans le dock », « Renommer », « Dissocier le dossier »).
   - **Glisser-déposer (Drag & Drop) :**
     - Survol central (anneau de fusion bleu) : Fusionne en dossier.
     - Déplacement latéral : Réorganise l'ordre des éléments sur l'axe horizontal.

6. **Surveillance des Processus & Épinglage**
   - Suivi en temps réel des applications actives (`NSWorkspace.shared.notificationCenter`).
   - Séparateur vertical visuel distinguant les applications épinglées des applications ouvertes temporaires.
   - Indicateur d'activité (pastille lumineuse) sous l'icône de chaque application ou dossier contenant une application active.

7. **Persistance JSON & Menu Bar**
   - Configuration sauvegardée de manière atomique dans `~/Library/Application Support/FolderDock/config.json`.
   - Icône discrète dans la barre des menus macOS permettant d'afficher le dock, d'activer/désactiver l'autohide, de réinitialiser la disposition d'origine ou de quitter l'application.

---

## 🛠 Compilation & Lancement

### Prérequis
- macOS 14.0 Sonoma ou supérieur
- Xcode 15+ ou Swift 5.9+

### Lancer la suite de tests
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

### Compiler et empaqueter le bundle `FolderDock.app`
```bash
./scripts/build_app.sh
```

### Compiler et lancer directement
```bash
./scripts/build_app.sh run
```

---

## 📁 Architecture du Code

- **`Sources/FolderDock/`**
  - `Main.swift` : Point d'entrée `@main`, cycle de vie `NSApplicationDelegate`, barre des menus.
  - `Models/` :
    - `DockItem.swift` : Structure arborescente unifiée (`.app` et `.folder`).
    - `DockConfig.swift` : Configuration globale et presets d'applications par défaut.
  - `Services/` :
    - `AppObserverService.swift` : Surveillance des lancements et fermetures de processus.
    - `DockPersistenceService.swift` : Sérialisation / désérialisation JSON.
    - `IconProvider.swift` : Extraction d'icônes macOS et composition 2x2 des dossiers.
  - `ViewModels/` :
    - `DockViewModel.swift` : Logique d'état MVVM, drag-and-drop, réorganisation, fusion et redimensionnement dynamique.
  - `Window/` :
    - `DockPanel.swift` : `NSPanel` flottant gérant la position et l'autohide.
    - `HotspotPanel.swift` : Déclencheur tactile au bord inférieur de l'écran.
    - `VisualEffectBackground.swift` : Wrapper AppKit pour le flou de verre liquide.
  - `Views/` :
    - `DockContainerView.swift` : Vue racine du Dock, séparateur, popover et poignées latérales.
    - `ResizeHandleView.swift` : Vue AppKit native de redimensionnement avec curseur horizontal et suivi d'écran sans à-coups.
    - `DockItemView.swift` : Icône, animations au survol, drag-and-drop.
    - `FolderIconGrid.swift` : Rendu dynamique et évolutif de la grille d'icônes miniature.
    - `FolderPopoverView.swift` : Popover étendu d'un dossier.
    - `MouseInteractionModifier.swift` : Gestion des clics gauche, milieu et droit.
