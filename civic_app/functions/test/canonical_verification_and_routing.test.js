const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const {
  CANONICAL_DEPARTMENTS,
  ALLOWED_DEPARTMENT_IDS,
  isValidDepartmentId,
  getDepartmentById,
  resolveWardForLocation,
  verifyComplaintEvidence,
  verifyComplaintDepartment,
} = require('../lib/index');

describe('Canonical 18 BMC Departments Allowlist & Validation', () => {
  test('Exact 18 canonical departments are registered', () => {
    assert.equal(CANONICAL_DEPARTMENTS.length, 18);
    assert.equal(ALLOWED_DEPARTMENT_IDS.size, 18);
  });

  test('All canonical 18 BMC department IDs are recognized', () => {
    const expectedIds = [
      'maintenance_roads',
      'water_works',
      'solid_waste_management',
      'building_factory',
      'garden_trees',
      'public_health',
      'pest_control_insecticide',
      'encroachment',
      'licence',
      'shops_establishments',
      'assessment_collection',
      'estate',
      'colony_slum',
      'education_schools',
      'security',
      'legal',
      'administration_establishment',
      'town_planning_development_plan',
    ];

    for (const deptId of expectedIds) {
      assert.equal(
        isValidDepartmentId(deptId),
        true,
        `Expected ${deptId} to be valid in canonical allowlist`
      );
      const meta = getDepartmentById(deptId);
      assert.ok(meta, `Expected metadata for ${deptId}`);
      assert.equal(meta.departmentId, deptId);
    }
  });

  test('Strictly rejects hallucinated / unapproved department IDs', () => {
    const invalidIds = [
      'traffic_police',
      'electricity_grid',
      'parks_and_recreation_department',
      'road_and_bridges_custom',
      'invalid_hallucination',
      'metro_rail_corporation',
      'general_municipal_desk',
      '',
    ];

    for (const invalidId of invalidIds) {
      assert.equal(
        isValidDepartmentId(invalidId),
        false,
        `Expected ${invalidId} to be REJECTED by allowlist`
      );
    }
  });
});

describe('BMC 24 Ward Proximity Resolution & Anti-Silent Fallback', () => {
  test('Correctly resolves centroid coordinates for known BMC wards', () => {
    // Dadar / Mahim -> G/North (19.041, 72.843)
    const gNorth = resolveWardForLocation(19.041, 72.843);
    assert.ok(gNorth);
    assert.equal(gNorth.wardId, 'G_NORTH');

    // Fort / Colaba -> A Ward (18.922, 72.8347)
    const aWard = resolveWardForLocation(18.922, 72.8347);
    assert.ok(aWard);
    assert.equal(aWard.wardId, 'A');

    // Borivali -> R Central Ward (19.231, 72.856)
    const rCentral = resolveWardForLocation(19.231, 72.856);
    assert.ok(rCentral);
    assert.equal(rCentral.wardId, 'R_CENTRAL');
  });

  test('Rejects coordinates far outside Mumbai administrative perimeter without silent fallback', () => {
    // Delhi coordinates: 28.6139, 77.2090 (~1150 km from Mumbai)
    const delhiWard = resolveWardForLocation(28.6139, 77.2090);
    assert.equal(delhiWard, null, 'Coordinates in Delhi must NOT resolve or fallback to G/North');

    // Null Island: (0.0, 0.0)
    const nullIsland = resolveWardForLocation(0.0, 0.0);
    assert.equal(nullIsland, null, '(0,0) coordinates must NOT resolve or fallback to G/North');

    // Pune coordinates: 18.5204, 73.8567 (~120 km from Mumbai)
    const puneWard = resolveWardForLocation(18.5204, 73.8567);
    assert.equal(puneWard, null, 'Coordinates in Pune must NOT resolve or fallback to G/North');
  });
});

describe('Two-Stage Gemini AI Verification (Offline Gating Simulation)', () => {
  test('Step 1: Evidence verification passes for valid complaint and rejects spam', async () => {
    const validComplaint = {
      title: 'Large Pothole near Dadar TT circle',
      description: 'Severe pothole causing heavy traffic delay and risk to two-wheelers.',
      category: 'maintenance_roads',
      imageUrls: ['https://example.com/pothole.jpg'],
    };

    const step1Result = await verifyComplaintEvidence(validComplaint);
    assert.equal(step1Result.passed, true);
    assert.ok(step1Result.confidence > 0.5);

    const spamComplaint = {
      title: 'test-invalid-spam advertisement',
      description: 'fake complaint for marketing product',
    };
    const spamResult = await verifyComplaintEvidence(spamComplaint);
    assert.equal(spamResult.passed, false);
  });

  test('Step 2: Department verification yields canonical BMC department and validates allowlist', async () => {
    const complaint = {
      title: 'Overflowing garbage bin on 14th road Bandra',
      description: 'Solid waste is piling up on footpath causing foul odor.',
      category: 'solid_waste_management',
    };

    const evidenceResult = { passed: true, confidence: 0.9, reason: 'Valid waste issue' };
    const step2Result = await verifyComplaintDepartment(complaint, evidenceResult);

    assert.equal(step2Result.passed, true);
    assert.ok(step2Result.verifiedDepartmentId);
    assert.equal(isValidDepartmentId(step2Result.verifiedDepartmentId), true);
  });
});

describe('AI Failure Classification & Category Mapping (Resilience Gating)', () => {
  const { isTransientAiFailure } = require('../lib/gemini_verification');
  const { resolveDepartmentForCategory } = require('../lib/departments');

  test('Classifies transient infrastructure errors correctly (429, 500, 503, 504, 408)', () => {
    assert.equal(isTransientAiFailure(429), true, 'HTTP 429 must be classified as transient');
    assert.equal(isTransientAiFailure(503), true, 'HTTP 503 must be classified as transient');
    assert.equal(isTransientAiFailure(500), true, 'HTTP 500 must be classified as transient');
    assert.equal(isTransientAiFailure(502), true, 'HTTP 502 must be classified as transient');
    assert.equal(isTransientAiFailure(504), true, 'HTTP 504 must be classified as transient');
    assert.equal(isTransientAiFailure(408), true, 'HTTP 408 must be classified as transient');
    assert.equal(isTransientAiFailure(0, 'fetch failed due to network error'), true);
    assert.equal(isTransientAiFailure(0, 'Resource has been exhausted (quota)'), true);
  });

  test('Rejects permanent non-transient status codes without error keywords', () => {
    assert.equal(isTransientAiFailure(200), false);
    assert.equal(isTransientAiFailure(400), false);
  });

  test('Resolves initial human review department from citizen categories without hardcoded default', () => {
    // Road category -> maintenance_roads
    const roadDept = resolveDepartmentForCategory('potholes_damaged_road');
    assert.equal(roadDept.departmentId, 'maintenance_roads');

    // Water category -> water_works
    const waterDept = resolveDepartmentForCategory('water_supply_leak');
    assert.equal(waterDept.departmentId, 'water_works');

    // Waste category -> solid_waste_management
    const wasteDept = resolveDepartmentForCategory('garbage_accumulation');
    assert.equal(wasteDept.departmentId, 'solid_waste_management');

    // Pest category -> pest_control_insecticide
    const pestDept = resolveDepartmentForCategory('mosquito_fogging');
    assert.equal(pestDept.departmentId, 'pest_control_insecticide');

    // Trees category -> garden_trees
    const treeDept = resolveDepartmentForCategory('fallen_tree_branch');
    assert.equal(treeDept.departmentId, 'garden_trees');
  });
});
