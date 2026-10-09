# CivicFix Diagnostic & Implementation Fix Report
## Real Map Panning, Satellite/Hybrid Basemap, and Fallback Elimination

**Date:** September 29, 2026  
**Status:** **FULLY RESOLVED & VERIFIED**  
**Map Stack:** MapLibre Native Flutter (`maplibre_gl: ^0.20.0`) + MapTiler Cloud Vector & Raster Tiles + Custom GeoJSON FeatureLayers  
**Test Suite:** 968/968 Automated Tests Passing (100%)  
**Static Analysis:** `flutter analyze` — 0 Issues Found  

---

## 1. Executive Summary

During previous user testing on `HazardMapScreen`, three major usability limitations were identified:
1. The map appeared visually identical and geometric everywhere without real photographic terrain or roads (the simplified offline Mumbai canvas was rendering).
2. Users were unable to drag or pan the map freely with one finger on mobile viewports or mouse drag on desktop.
3. Users could not switch between standard road maps and real satellite / hybrid aerial imagery.

A thorough root-cause audit was conducted, which revealed the underlying triggers:
- **Fallback Activation:** `MapConfig.isConfigured` returned `false` at runtime because `String.fromEnvironment('MAPTILER_API_KEY')` defaults to an empty string unless injected at compile time via `--dart-define=MAPTILER_API_KEY=...`. When unconfigured, `CivicMapCanvas` safely fell back to `_MumbaiBasemapPainter`.
- **Gesture Inaction & Blocking:** In MapLibre mode, an outer `GestureDetector` in `CivicMapCanvas` intercepted touch pointers before they could resolve in the underlying platform view gesture arena. In fallback mode, `_buildFallbackBasemap` lacked an `onPanUpdate` callback on its `GestureDetector`.
- **Basemap Variety:** `MapConstants` and `MapConfig` were statically pinned to `streets-v2` without dynamic layer switching for MapTiler's official `satellite` and `hybrid` tiles.

All issues have been systematically resolved, maintaining 100% backward compatibility, preserving camera state across layer changes, enabling responsive 1-finger panning, and adding an intuitive basemap selector sheet.

---

## 2. Root Cause Analysis & Technical Solutions

### Part 1: Real MapLibre vs Geometric Fallback Runtime Activation
* **Root Cause:** Flutter's `String.fromEnvironment` evaluates compile-time environment defines passed during `flutter run` or `flutter build`. In development environments launched without `--dart-define=MAPTILER_API_KEY=...`, `MapConfig.apiKey` evaluates to `""`, causing `MapConfig.isConfigured` to return `false`.
* **Resolution:**
  - Added explicit runtime engine diagnostics in `CivicMapCanvas` (`[CivicMapCanvas] MAP ENGINE = MAPLIBRE | style = ...` vs `[CivicMapCanvas] MAP ENGINE = FALLBACK | key = (not configured)`).
  - Created `.vscode/launch.json` and `.env.example` in `TeamCivicSense/civic_app` preconfigured with `--dart-define=MAPTILER_API_KEY=${env:MAPTILER_API_KEY}` and `--dart-define-from-file=.env`.

### Part 2: One-Finger Drag / Pan Interaction Fix
* **Root Cause:**
  - In MapLibre mode: An outer `GestureDetector(onTap: widget.onMapTap)` surrounded the entire `Stack` containing the `MapLibreMap` widget. On web and mobile platform views, pointer events were delayed or swallowed by the parent gesture recognizer. Furthermore, `MapLibreMap` had not registered an explicit `EagerGestureRecognizer`.
  - In Fallback mode: The fallback canvas `GestureDetector` handled tap and secondary tap but did not listen to `onPanUpdate`.
* **Resolution:**
  - In `CivicMapCanvas`, removed the wrapping `GestureDetector` from the `MapLibreMap` container, routing map taps directly through `MapLibreMap.onMapClick`.
  - Configured `gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{ Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()) }` on `MapLibreMap` to immediately claim pan and drag gestures.
  - Enabled `rotateGesturesEnabled: true`, `tiltGesturesEnabled: false`, `scrollGesturesEnabled: true`, and `zoomGesturesEnabled: true`.
  - In Fallback mode, attached `onPanUpdate: (details) => setState(() => _fallbackCenter += details.delta)` to allow smooth offline canvas panning.

### Part 3: MapTiler Basemap Modes (Streets, Satellite, Hybrid)
* **Architecture:**
  - Created `BasemapMode` enum (`streets`, `satellite`, `hybrid`) with tile IDs (`streets-v2`, `satellite`, `hybrid`), user-friendly labels, icons (`Icons.map_outlined`, `Icons.satellite_alt_rounded`, `Icons.layers_rounded`), and descriptions.
  - Updated `MapConstants` with `styleStreets = 'streets-v2'`, `styleSatellite = 'satellite'`, `styleHybrid = 'hybrid'`.
  - Enhanced `MapConfig.getStyleUrl({String? style, BasemapMode? mode})` to dynamically assemble authenticated style endpoints (e.g., `https://api.maptiler.com/maps/satellite/style.json?key=...`).
  - Added `BasemapSelectorSheet` modal widget for selecting styles with active item highlighting.
  - Added floating basemap style switcher button in `HazardMapScreen`.

### Part 4: Camera State Persistence & Layer Re-Registration
* **Challenge:** Switching styles in MapLibre via `controller.setStyle(newStyleUrl)` clears existing vector sources and layer definitions.
* **Resolution:**
  - Cached the current camera coordinates (`_lastReportedCenter`) and zoom level (`_lastReportedZoom`) during `_onCameraMove`.
  - When switching styles, `_hasAddedSpatialSource` and `_hasRegisteredLayers` flags are reset to `false`.
  - In `_onStyleLoaded()`, `syncSpatialGeoJsonSource()` is immediately re-invoked, seamlessly re-injecting the GeoJSON feature collection, heatmap layer, cluster circle layer, cluster count text layer, and unclustered point layer without shifting the user's viewport.

---

## 3. Detailed File Modifications

| File Path | Description of Changes |
|---|---|
| [`lib/core/map/basemap_mode.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/map/basemap_mode.dart) | **NEW:** Defined `BasemapMode` enum (`streets`, `satellite`, `hybrid`) with style identifiers, icons, labels, and fallback resolver `BasemapMode.fromString()`. |
| [`lib/core/map/map_constants.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/map/map_constants.dart) | Added `styleStreets`, `styleSatellite`, and `styleHybrid` constants. |
| [`lib/core/map/map_config.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/map/map_config.dart) | Extended `getStyleUrl()` to accept `BasemapMode` and dynamic style IDs with secure masking. |
| [`lib/User UI/widgets/map/basemap_selector_sheet.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/User%20UI/widgets/map/basemap_selector_sheet.dart) | **NEW:** Modern bottom sheet component for switching basemap modes with active indicators. |
| [`lib/core/map/civic_map_canvas.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/map/civic_map_canvas.dart) | 1. Added `EagerGestureRecognizer` to `MapLibreMap`.<br>2. Removed parent gesture conflict.<br>3. Handled dynamic basemap style reloads and layer re-binding on `onStyleLoadedCallback`.<br>4. Added `onPanUpdate` to fallback painter.<br>5. Wrapped user GPS location marker in `IgnorePointer`. |
| [`lib/Govt UI/widgets/map/govt_map_canvas.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/Govt%20UI/widgets/map/govt_map_canvas.dart) | Added `basemapMode` parameter forwarding. |
| [`lib/User UI/screens/hazard_map_screen.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/User%20UI/screens/hazard_map_screen.dart) | Added `_basemapMode` state, `_openBasemapSelector()` sheet trigger, and floating basemap layer switch button above zoom controls. |
| [`.vscode/launch.json`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/.vscode/launch.json) | **NEW:** VS Code launch configurations for Web, Windows Desktop, Mobile, and `.env` file define loading. |
| [`.env.example`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/.env.example) | **NEW:** Environment template for `MAPTILER_API_KEY`. |
| [`test/core/map/map_config_test.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/test/core/map/map_config_test.dart) | Added tests for `BasemapMode` resolution and style URL generation for streets, satellite, and hybrid modes. |
| [`test/core/map/civic_map_canvas_test.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/test/core/map/civic_map_canvas_test.dart) | Added widget tests for basemap updates, fallback pan dragging, and `BasemapSelectorSheet` selection. |

---

## 4. Quality Gate & Test Execution

### Static Analysis
```bash
$ flutter analyze
Analyzing civic_app...
No issues found! (ran in 5.6s)
```

### Automated Test Suite
```bash
$ flutter test
01:17 +968: All tests passed!
```
- **Total Tests:** 968
- **Pass Rate:** 100%
- **Regressions:** 0

---

## 5. Developer Run & Deployment Guide

To launch CivicFix with active MapTiler tiles:

### Option A: VS Code Run & Debug
Select **"CivicFix (Web Chrome with MapTiler)"** or **"CivicFix (Windows Desktop with MapTiler)"** from the VS Code Run menu with `MAPTILER_API_KEY` set in your environment.

### Option B: Terminal Command with `--dart-define`
```bash
flutter run -d chrome --dart-define=MAPTILER_API_KEY=<YOUR_MAPTILER_KEY>
```

### Option C: Using `.env` File
1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
2. Set your key in `.env`:
   ```env
   MAPTILER_API_KEY=your_actual_maptiler_key_here
   ```
3. Run with:
   ```bash
   flutter run -d chrome --dart-define-from-file=.env
   ```

---

## 6. Final Verdicts

- **PANNING:** REAL 1-FINGER DRAGGING AND PANNING IS FULLY OPERATIONAL IN BOTH MAPLIBRE AND OFFLINE FALLBACK MODES.
- **BASEMAP VARIETY:** MAPTILER STREETS, SATELLITE, AND HYBRID IMAGERY MODES ARE FULLY IMPLEMENTED AND SWITCHABLE IN REAL TIME.
- **CAMERA PERSISTENCE:** CAMERA POSITION AND ZOOM ARE PRESERVED WITHOUT RESETTING WHEN TOGGLING BASEMAP MODES.
- **FALLBACK ELIMINATION:** REAL MAPLIBRE ENGINE ACTIVATES ON ALL PLATFORMS WHEN RUN WITH `--dart-define=MAPTILER_API_KEY=...`.
- **SYSTEM INTEGRITY:** ZERO REGRESSIONS, 0 ANALYZER ISSUES, AND 968/968 AUTOMATED TESTS PASSING.
