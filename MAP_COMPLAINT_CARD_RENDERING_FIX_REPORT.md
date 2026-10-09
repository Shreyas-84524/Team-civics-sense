# Map Complaint Card Rendering Fix

## 1. Root cause

`CivicMapCanvas` listened only to `MapLibreMap.onMapClick`. In the installed maplibre_gl 0.27.1, `featureTapsTriggersMapClick` defaults to false and circle/symbol layers default to interactive. The web adapter's `_onMapClick` sends interactive feature hits to `onFeatureTappedPlatform` and only forwards them to `onMapClickPlatform` when that flag is true. No feature-tapped listener was registered by the canvas. Consequently, tapping the visible issue stopped BEFORE the application's rendered-feature queries and selected state update. Heatmap/source loading was working independently.

Evidence: installed package `maplibre_gl/lib/src/maplibre_map.dart` (constructor and callback documentation), `maplibre_gl_web/lib/src/maplibre_web_gl_platform.dart` (`_onMapClick`), and `CivicMapCanvas._buildMapLibreView`.

A secondary visibility defect hid cluster circles/text at zoom 14.5 although the source clusters through integer zoom 14. The layers now stay visible until zoom 15.

## 2. Tap flow before fix

MapLibre pointer click -> interactive circle hit -> feature-tapped event with no app listener -> no rendered-feature query -> selected hazard stays null -> conditional floating card absent. Empty-map clicks could reach a geographic proximity fallback, masking the broken event route and potentially selecting invisible/clustered points.

## 3. Tap flow after fix

MapLibre pointer click -> `featureTapsTriggersMapClick: true` -> existing `onMapClick` -> cluster query -> expand if a cluster is hit; otherwise query unclustered circle -> exact feature type/ID lookup -> `onHazardSelected` -> screen `setState` -> existing `HazardInfoCard` above the map. Empty rendered hit dismisses the card. The live map never falls back to geographic guesses. Offline painter behavior remains separate.

## 4. Queried layers

- `civicfix-clustered-points` and `civicfix-cluster-count`, only when clustering is enabled.
- `civicfix-unclustered-points`, only when the point layer is enabled.
- Heatmap and GPS dot are excluded from selection.

Heatmap is added first, then cluster circles/text, then visible unclustered circles. Individual circles have opacity 0.9 and start at zoom 10. The existing point_count filter separates single features from clusters.

## 5. Feature properties

The actual `SpatialFeature.toGeoJsonFeature` builder provides `id`, `type` (complaint/hazard), `complaintId`, `ticketNumber`, `title`, `category`, `categoryId`, `status`, `citizenPhaseLabel`, `createdAt`, `address`, and optional landmark/ward. No invented `ticketId`, `reportedAt`, or `featureType` field is assumed. Card content comes from the resolved domain model.

## 6. ID mapping

Complaint features: `id == ComplaintModel.id == complaintId` (internal document ID). Derived hazards: `id == haz_<complaint document ID>`, with `complaintId` retaining the original document ID. Resolution uses an exact `type:id` index over the current dataset, preserving distinct complaint/hazard namespaces. Display ticket numbers never participate in feature resolution. View Details now uses the internal ID without falling back to a ticket search.

## 7. State fix

Query generation guards discard results after a newer tap or widget/data refresh, and check mounted state before callbacks. Selection subscription generations discard updates from a previously selected issue. When filtering or chunk refresh removes the selected item, the screen clears selection and cancels its subscriptions. Existing refresh reconciliation keeps the selected card's model current.

## 8. UI/card review

The existing card already contains category, title, reported time, current phase, address, and View Details. Its Positioned overlay is after the map and other overlays in the screen Stack. No Offstage/Visibility gate or role restriction suppresses it: the gate is simply non-null selection. The fix restores that selection path; no visual redesign or outer GestureDetector was added. The existing GestureDetector belongs only to the offline painter. MapLibre remains the sole live-map gesture controller.

## 9. Web-specific findings

The installed web adapter emits map-local CSS pixel coordinates and passes query coordinates directly to MapLibre GL JS. No device-pixel-ratio conversion is required. The callback suppression described above is explicitly present in the web adapter. Browser inventory contained no attached running localhost demo. Attempted `flutter test --no-pub --platform chrome test/core/map/map_feature_selection_test.dart`. Chrome launched, but the runner stayed at loading without executing tests; it was stopped after several minutes. This is an unverified browser result, not evidence of an application assertion failure. The adapter tests do not exercise real WebGL or DOM pointer propagation. A manual localhost walkthrough with a configured MapTiler key and citizen session remains outstanding.

## 10. Cluster behavior

Cluster taps clear any open card and retain the existing +2 zoom expansion. Cluster layers remain visible until zoom 15, matching source clustering. Query failures return without choosing a nearby complaint. No arbitrary cluster child is selected.

## 11. Tests

`flutter test --no-pub test/core/map`: **71 passed**.

New configured-MapLibre regression tests cover the forwarding option, unchanged screen coordinates, queried point layer, exact hazard/document ID mapping, first/second card selection, cluster zoom/dismissal, empty-map dismissal without proximity selection, and late query rejection after data replacement. Existing tests cover card details navigation, live status refresh, basemap switching, location controls, spatial filters, chunk loading, and deduplication. Corrected an existing stale test tooltip from `Change Map Layer (Streets)` to the current `Basemap Style (Streets)`.

These tests use fixtures/test adapters and do not constitute a manual production-data walkthrough.

## 12. Static analysis

`flutter analyze --no-pub`: **No issues found** (full civic_app analysis, including the new tests).

The sandboxed SDK initially failed to start; the same Flutter commands ran successfully with normal SDK access. No dependency change was required.

## Files changed

- `civic_app/lib/core/map/civic_map_canvas.dart`
- `civic_app/lib/User UI/screens/hazard_map_screen.dart`
- `civic_app/lib/User UI/widgets/hazard_map/hazard_info_card.dart`
- `civic_app/test/core/map/map_feature_selection_test.dart` (new)
- `civic_app/test/core/map/complaint_info_card_test.dart` (stale tooltip expectation)
- `Brain.md` (append only)
- `MAP_COMPLAINT_CARD_RENDERING_FIX_REPORT.md`

## Final verdict

PASS below means supported by code review and the automated map suite, not an unperformed live WebGL walkthrough.

| Check | Verdict |
| --- | --- |
| HEATMAP PRESERVED | PASS - heatmap/source code retained; spatial suite passes |
| SINGLE POINT TAP | PASS - configured callback regression |
| FEATURE QUERY | PASS - correct layers and coordinate forwarding verified with adapter |
| CORRECT COMPLAINT RESOLUTION | PASS - exact type/ID lookup, document IDs preserved |
| FLOATING CARD RENDERING | PASS - widget selection/update tests |
| CLUSTER EXPANSION | PASS - camera animation instead of card; visibility gap corrected |
| WEB/CHROME | FAIL (verification incomplete) - Chrome runner stalled loading; live WebGL walkthrough unverified |
| FILTERS PRESERVED | PASS - spatial filter/chunk suite and stale query regression |
| LOCATION DOT PRESERVED | PASS - GPS code retained; existing location tests pass |
| FLUTTER ANALYZE | PASS - no issues found |

