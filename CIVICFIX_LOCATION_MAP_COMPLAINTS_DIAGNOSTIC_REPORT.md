# CIVICFIX DIAGNOSTIC REPORT: COMPLAINTS NOT VISIBLE ON LOCATION MAP

**Document ID:** `CIVICFIX_LOCATION_MAP_COMPLAINTS_DIAGNOSTIC_REPORT.md`  
**Investigation Timestamp:** 2026-09-29  
**System:** CivicFix Mobile App (Flutter / MapLibre GL / MapTiler / Cloud Firestore)  
**Investigation Scope:** Non-destructive, read-only diagnostic trace & root-cause analysis  

---

## 1. Exact Affected Screen

- **Screen / Widget File:** `lib/User UI/screens/hazard_map_screen.dart` (`HazardMapScreen`)
- **Route:** `AppRoutes.hazardMap` (`/hazard-map`), and accessible as Tab index 2 (`Map`) in `MainNavigationScreen` (`lib/User UI/screens/main_navigation_screen.dart`).
- **Target Role:** Citizen / Resident Location Map (Public Civic Issue & Hazard Map).
- **Distinction from Government Maps:**
  - Citizen Location Map: `HazardMapScreen` (`lib/User UI/screens/hazard_map_screen.dart`)
  - Government Scoped Map: `GovernmentScopedMap` (`lib/Govt UI/widgets/map/government_scoped_map.dart`)
  - Government City/Ward/Zone Dashboards: `GovtHazardMapScreen` (`lib/Govt UI/screens/map/govt_hazard_map_screen.dart`), `CityComplaintMapSection`, `WardOperationsMapSection`, `ZoneOperationsMapSection`.

---

## 2. Active Map Architecture

- **Core Canvas Component:** `CivicMapCanvas` (`lib/core/map/civic_map_canvas.dart`)
- **Map Provider & Engine:** MapTiler Vector Basemap via `MapLibreMap` (`maplibre_gl: ^0.19.0`).
- **Style Preset:** MapTiler `streets-v2` (`https://api.maptiler.com/maps/streets-v2/style.json?key=...`).
- **Fallback Engine:** Offline/Unconfigured Canvas Painter `_MumbaiBasemapPainter` rendering geographical Mumbai features (Arabian Sea, Thane Creek, Sanjay Gandhi National Park, Western & Eastern Express Highways, Bandra-Worli Sea Link).
- **MapLibre Source ID:** `MapConstants.spatialSourceId` (`civicfix-spatial-points`).
- **MapLibre Layer IDs:**
  1. `civicfix-heatmap-layer` (`MapConstants.heatmapLayerId`): Native density heatmap (maxzoom: 18.0).
  2. `civicfix-clustered-points` (`MapConstants.clusterPointsLayerId`): Clustered circular badges with count color-steps (maxzoom: 14.5).
  3. `civicfix-cluster-count` (`MapConstants.clusterCountLayerId`): Abbreviated cluster count text label (maxzoom: 14.5).
  4. `civicfix-unclustered-points` (`MapConstants.unclusteredPointsLayerId`): Individual severity-coded circle markers (minzoom: 12.0).
- **Overlay Marker System:** High-level interactive Flutter widgets rendered on top of the canvas via `_buildHazardMarker` / `HazardMarker`.
- **Controller Lifecycle:** `MapLibreMapController` initialized in `onMapCreated`, spatial source initialized upon `onStyleLoadedCallback`, and synchronized via `syncSpatialGeoJsonSource()` on state updates.

---

## 3. Active Complaint Data Source

- `HazardMapScreen.initState()` initializes `_hazardRepository = widget.hazardRepository ?? RepositoryLocator.hazardRepository`.
- In production runtime (`RepositoryLocator.isProductionActive == true`), `RepositoryLocator.hazardRepository` resolves to `OfflineFirstHazardRepository` (`lib/core/repositories/offline_first_hazard_repository.dart`).
- `OfflineFirstHazardRepository` reads from `HiveHazardRepository` cache and queries `FirebaseHazardDataSource` (`lib/core/firebase/firestore/firebase_hazard_data_source.dart`).
- `FirebaseHazardDataSource` queries `FirestoreCollections.hazards` (`'hazards'`).
- **Critical Finding:** The `hazards` collection in Firestore is **completely empty** (`0` documents).
- Real complaints submitted through the app are processed by `OfflineFirstComplaintRepository` / `FirebaseComplaintDataSource` and stored exclusively in `FirestoreCollections.complaints` (`'complaints'`).
- `HazardMapScreen` does **not** fetch from `ComplaintRepository`.

---

## 4. Complaint Records Fetched

Live inspection of the Firestore backend (`civicfix-38d53`) confirmed active complaints in the `complaints` collection:

| Document ID | Ticket Number | Title | Coordinates (Lat, Lng) | Status | `isHazard` | Citizen ID |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `cPwES4DLJ2pnQB6EirG9` | `CF-2026-1790633246862000-c19277e9293b` | Broken Road | `19.244548, 72.863509` | `inProgress` | `false` | `pfZMsRAk...` |
| `cmp_diag_1790621344083` | `CF-2026-999999` | Diagnostic Test Issue | `19.244500, 72.863400` | `reported` | `false` | `93xCCiIP...` |
| `cmp_live_1790620651204_000026` | `CF-2026-000026` | Large Pothole near SV Road | `19.244500, 72.863400` | `verified` | `false` | `93xCCiIP...` |
| `cmp_r_north_road_01` | `CF-2026-000101` | Severe Potholes Dahisar Check Naka | `19.257800, 72.863100` | `reported` | `true` | `pfZMsRAk...` |
| `cmp_r_north_road_02` | `CF-2026-000102` | Broken Footpath outside Station | `19.251200, 72.859400` | `reported` | `false` | `pfZMsRAk...` |
| `cmp_r_north_road_03` | `CF-2026-000103` | Crater on Anand Nagar Road | `19.255500, 72.864500` | `reported` | `true` | `pfZMsRAk...` |
| `cmp_r_north_road_04` | `CF-2026-000104` | Collapsed walkway slabs | `19.253000, 72.853800` | `verified` | `true` | `pfZMsRAk...` |
| `cmp_r_north_road_05` | `CF-2026-000105` | Paver block depressions | `19.248900, 72.861200` | `reported` | `false` | `pfZMsRAk...` |

- **Total Complaints in Firestore `/complaints`:** 8
- **Total Documents in Firestore `/hazards`:** 0
- **Total Complaints Fetched by `HazardMapScreen`:** 0 (because it queries `/hazards`)

---

## 5. Valid Coordinate Count

- **Total records inspected:** 8
- **Records with valid WGS84 coordinates:** 8 (100%)
- **Records rejected due to out-of-bounds / NaN coordinates:** 0
- **Coordinate Schema in Firestore:** Nested map field `location` containing `latitude: <number>` and `longitude: <number>`.

---

## 6. Model Parsing Findings

- `ComplaintFirestoreMapper` (`lib/core/firebase/mappers/complaint_firestore_mapper.dart`) and `FirestoreMapperHelpers.locationFromMap` (`lib/core/firebase/mappers/firestore_mapper_helpers.dart`):
  - Properly extracts `(map['latitude'] as num?)?.toDouble() ?? 0.0` and `(map['longitude'] as num?)?.toDouble() ?? 0.0`.
  - No type casting exceptions occur (supports double, int, num).
  - Latitude and longitude are correctly mapped without swapping.
- `HazardFirestoreMapper` (`lib/core/firebase/mappers/hazard_firestore_mapper.dart`):
  - Expects root-level `data['latitude']` and `data['longitude']`.
- `HazardModel.fromComplaint(complaint)` (`lib/core/models/hazard_model.dart`):
  - Correctly maps `latitude: complaint.location.latitude` and `longitude: complaint.location.longitude`.

---

## 7. GeoJSON Findings

- `SpatialDataService.buildFeatureCollection` (`lib/core/map/spatial_data_service.dart`):
  - Accurately creates `SpatialFeature` instances from `ComplaintModel` or `HazardModel`.
  - Converts items into valid RFC 7946 GeoJSON Feature objects.
- Current Runtime State: Because `HazardMapScreen` passes `hazards: []` and `complaints: null`, the generated GeoJSON payload sent to MapLibre is:
  ```json
  {
    "type": "FeatureCollection",
    "features": []
  }
  ```

---

## 8. Coordinate Ordering

- **GeoJSON RFC 7946 Standard Requirement:** `[longitude, latitude]` (`[lng, lat]`).
- **CivicFix Implementation in `SpatialFeature.toGeoJsonFeature()` (line 141):**
  ```dart
  'geometry': {
    'type': 'Point',
    'coordinates': [longitude, latitude], // [lng, lat]
  }
  ```
- **Finding:** Coordinate ordering is **100% correct** and RFC 7946 compliant. Coordinates are not swapped.

---

## 9. Map Source Findings

- **Source ID:** `civicfix-spatial-points`
- **Creation:** `_mapController.addSource('civicfix-spatial-points', GeojsonSourceProperties(data: geoJson, cluster: true, clusterMaxZoom: 14, clusterRadius: 50))`
- **Update:** `_mapController.setGeoJsonSource('civicfix-spatial-points', geoJson)`
- **Finding:** Source handling and recreation on style reloads are intact. The source is populated, but with an empty `features` list.

---

## 10. Layer Findings

- `civicfix-heatmap-layer`: Configured for zoom 0–18, weight 1.0, color interpolation from blue (0.2) to red (1.0).
- `civicfix-clustered-points`: Filter `['has', 'point_count']`, maxzoom 14.5.
- `civicfix-cluster-count`: Filter `['has', 'point_count']`, symbol text `{point_count_abbreviated}`, maxzoom 14.5.
- `civicfix-unclustered-points`: Filter `['!', ['has', 'point_count']]`, minzoom 12.0, circleRadius 6.0, opacity 0.9.
- **Finding:** Layer configurations, paint properties, and source associations are valid.

---

## 11. Zoom-Level Findings

- **Initial Camera Position:** Latitude `19.0760`, Longitude `72.8777`, Zoom `11.5`.
- **Zoom Threshold Observation:**
  - `unclusteredPointsLayerId` has `minzoom: 12.0`.
  - `clusterPointsLayerId` has `filter: ['has', 'point_count']` (only matches when 2 or more points cluster together).
  - **Threshold Gap:** At initial zoom `11.5`, an isolated unclustered point is filtered out by `minzoom: 12.0` and will only render if the user zooms in to zoom 12.0+, or if the heatmap layer is active.

---

## 12. Filter Findings

- Default state of `HazardMapScreen`:
  - `_selectedCategoryId`: `null` (all categories)
  - `_selectedStatus`: `null` (all statuses)
  - `_selectedTimeFilter`: `null` (all time)
  - `_searchController`: `""` (empty)
- **Finding:** Default UI filters do **not** filter out complaints.

---

## 13. Firestore / Security Rule Findings

- **Rule Definition (`firestore.rules` lines 273–277):**
  ```
  match /complaints/{complaintId} {
    allow read: if isSignedIn() && (
      resource.data.citizenId == request.auth.uid ||
      isGovernment() ||
      resource.data.isHazard == true
    );
  }
  ```
- **Rule Definition for Hazards (`firestore.rules` lines 553–556):**
  ```
  match /hazards/{hazardId} {
    allow read: if isSignedIn();
  }
  ```
- **Firestore Rule Semantics:**
  - In Firestore, rules are authorization constraints, not server-side filters.
  - An unfiltered query on `/complaints` (`_complaintsRef.orderBy('createdAt').get()`) executed by a non-government citizen is rejected with `PERMISSION_DENIED` because the collection contains documents where `citizenId != request.auth.uid` and `isHazard == false`.
  - A citizen query on `/complaints` must specify `.where('isHazard', isEqualTo: true)` or `.where('citizenId', isEqualTo: request.auth.uid)` to satisfy the security rule.
  - Of the 8 existing complaints, only 3 have `isHazard == true`.

---

## 14. Repository / State Findings

- In `HazardMapScreen`, data loading is invoked via `_hazardRepository.getHazards()`.
- In `OfflineFirstHazardRepository`, `_remoteDataSource.getHazards()` queries `/hazards`, which yields 0 records.
- In `OfflineFirstComplaintRepository.getComplaints()`, `_remoteDataSource.getGovernmentComplaints()` is called; when executed by a citizen, Firestore throws `PERMISSION_DENIED`, which is caught in `catch (e)` and returns an empty local list.
- Contrast with `GovernmentScopedMap`: `GovernmentScopedMap` includes fallback logic (`if (raw.isEmpty) { raw = complaints.map((c) => HazardModel.fromComplaint(c)).toList(); }`), which succeeds for government users who have collection-wide read access.

---

## 15. Map Lifecycle Findings

- Sequence:
  1. `initState()` -> `_loadHazards()` begins async fetch.
  2. `build()` renders `CivicMapCanvas` with empty list.
  3. `MapLibreMap` created -> `onStyleLoadedCallback` -> `syncSpatialGeoJsonSource()` sets empty GeoJSON source.
  4. `_loadHazards()` resolves with `[]` -> `setState()` calls `_applyCurrentFilters()`.
  5. `CivicMapCanvas.didUpdateWidget()` triggers `syncSpatialGeoJsonSource()` with empty dataset.
- **Finding:** Lifecycle execution order is clean; failure is entirely due to data source divergence.

---

## 16. Collection / Field Name Mismatch Findings

- **Architecture Disconnect:**
  - Submission Pipeline: `ReportIssueScreen` -> `OfflineFirstComplaintRepository` -> writes to collection **`complaints`**.
  - Citizen Map Query: `HazardMapScreen` -> `OfflineFirstHazardRepository` -> reads from collection **`hazards`**.
  - No background worker, Cloud Function, or client trigger copies or synchronizes reported issues from `complaints` to `hazards`.

---

## 17. Index / Query Findings

- `firestore.indexes.json` contains required composite indexes:
  - `complaints`: `(isHazard ASC, createdAt DESC)`
  - `complaints`: `(citizenId ASC, createdAt DESC)`
  - `hazards`: `(status ASC, createdAt DESC)`
  - `hazards`: `(severity ASC, createdAt DESC)`
- No query failed due to missing composite indexes.

---

## 18. Error Handling Findings

- `OfflineFirstHazardRepository.getHazards()` catches remote errors and silently returns local cache without surfacing errors to UI.
- `OfflineFirstComplaintRepository.getComplaints()` catches `PERMISSION_DENIED` errors on `getGovernmentComplaints` and silently returns local cache.

---

## 19. Exact Point Where Complaints Disappear

Complaints disappear at the **Data Source Acquisition Layer**:
`HazardMapScreen` invokes `_hazardRepository.getHazards()`, which queries the empty `/hazards` Firestore collection. `_allHazards` evaluates to `[]`, passing an empty dataset to `CivicMapCanvas`. GeoJSON generation results in 0 features, and 0 markers are rendered.

---

## 20. Root Cause

The citizen Location Map (`HazardMapScreen`) exclusively queries `HazardRepository` (which queries the empty Firestore `/hazards` collection). Real complaints filed by users are written to the `/complaints` collection, but `HazardMapScreen` does not query `ComplaintRepository` or pass complaints to `CivicMapCanvas`.

---

## 21. Secondary Contributing Causes

1. **Security Rule Query Mismatch:** `OfflineFirstComplaintRepository.getComplaints()` delegates to `getGovernmentComplaints()`, which fails with `PERMISSION_DENIED` when queried by standard citizen accounts because it lacks required query constraints (`isHazard == true` or `citizenId == uid`).
2. **Overlay Marker Iteration in Canvas:** `CivicMapCanvas` iterates only over `widget.hazards` (`...widget.hazards.map(...)`) for high-level Flutter overlay widget markers; it does not generate Flutter overlay markers for `widget.complaints`.
3. **Zoom Threshold Filter:** `unclusteredPointsLayerId` has `minzoom: 12.0`, suppressing isolated point rendering at the initial zoom level of `11.5`.
4. **No Real-Time Subscription:** `HazardMapScreen` uses a one-shot `Future` in `initState()` instead of subscribing to real-time streams (`watchHazards()` / `watchNearbyHazards()`).

---

## 22. Files Likely Requiring Changes (For Future Fix Phase)

1. `lib/User UI/screens/hazard_map_screen.dart`
2. `lib/core/repositories/offline_first_hazard_repository.dart`
3. `lib/core/firebase/firestore/firebase_hazard_data_source.dart`
4. `lib/core/repositories/offline_first_complaint_repository.dart`
5. `lib/core/firebase/firestore/firebase_complaint_data_source.dart`
6. `lib/core/map/civic_map_canvas.dart`
7. `firestore.rules` (if all public complaints, not just hazards, are intended to be readable by all citizens on the map)

---

## 23. Recommended Fix Strategy

### Step 1: Unify Repository / Query for Citizen Map
- In `OfflineFirstHazardRepository` (or `OfflineFirstComplaintRepository`), ensure the citizen map query fetches from `/complaints` using `.where('isHazard', isEqualTo: true)` (or the designated public complaint query), and synthesizes `HazardModel` from `ComplaintModel` (via `HazardModel.fromComplaint(complaint)`), matching the architecture used in `GovernmentScopedMap`.
- Or, if all public complaints should appear on the citizen map, update `firestore.rules` to allow public read of complaints and implement a dedicated `getPublicComplaints()` method.

### Step 2: Update `HazardMapScreen` Data Loading
- In `HazardMapScreen`, fetch community complaints/hazards using the unified query and pass the resulting data to `CivicMapCanvas`.
- Switch from a one-shot `Future` to a reactive stream subscription (`watchNearbyHazards()` / `watchHazards()`) so new reports appear in real-time.

### Step 3: Update `CivicMapCanvas` Marker Builders
- In `CivicMapCanvas`, ensure both `widget.hazards` and `widget.complaints` generate interactive markers (or normalize complaints into hazards before passing to canvas).

### Step 4: Adjust Layer Zoom Thresholds
- In `CivicMapCanvas._registerSpatialLayers()`, adjust `unclusteredPointsLayerId` `minzoom` to `10.0` or `11.0` so individual markers remain visible at the default initial zoom of `11.5`.

---

# ROOT CAUSE IDENTIFIED
