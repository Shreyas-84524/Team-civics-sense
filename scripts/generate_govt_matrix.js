/**
 * CivicFix - Municipal Government Matrix Architecture Generator (Phase 2)
 *
 * Generates canonical BMC-style hierarchical government data:
 * - 7 Zones
 * - 24 Wards
 * - 18 Departments
 * - 432 Ward-Department Units (24 x 18)
 * - 2,642 Government Identities:
 *     1 Super Admin
 *     7 Zonal DMCs
 *    18 Central Department HODs
 *    24 Ward Officers
 *   432 Ward Department Leads
 * 2,160 Department Crew Members (432 x 5)
 */

const fs = require('fs');
const path = require('path');

const GOVT_DATA_DIR = path.resolve(__dirname, '../resources/Govt Data');

// 1. ZONES DEFINITION (7 Zones)
const ZONES = [
  { zoneId: 'ZONE_1', zoneNumber: 1, displayName: 'Zone 1 (City South)', active: true },
  { zoneId: 'ZONE_2', zoneNumber: 2, displayName: 'Zone 2 (City Central)', active: true },
  { zoneId: 'ZONE_3', zoneNumber: 3, displayName: 'Zone 3 (Western Suburbs South & Central)', active: true },
  { zoneId: 'ZONE_4', zoneNumber: 4, displayName: 'Zone 4 (Western Suburbs North)', active: true },
  { zoneId: 'ZONE_5', zoneNumber: 5, displayName: 'Zone 5 (Eastern Suburbs South)', active: true },
  { zoneId: 'ZONE_6', zoneNumber: 6, displayName: 'Zone 6 (Eastern Suburbs North)', active: true },
  { zoneId: 'ZONE_7', zoneNumber: 7, displayName: 'Zone 7 (Northern Suburbs)', active: true }
];

// 2. 24 WARDS DEFINITION
// Mapped to existing verified BMC ward data with normalized IDs
const WARD_DEFINITIONS = [
  { wardId: 'A', wardCode: 'A', wardName: 'A Ward (Fort / Colaba)', zoneId: 'ZONE_1', active: true, lat: 18.9220, lng: 72.8347, pincode: '400001' },
  { wardId: 'B', wardCode: 'B', wardName: 'B Ward (Dongri / Mandvi)', zoneId: 'ZONE_1', active: true, lat: 18.9560, lng: 72.8380, pincode: '400002' },
  { wardId: 'C', wardCode: 'C', wardName: 'C Ward (Marine Lines / Bhuleshwar)', zoneId: 'ZONE_1', active: true, lat: 18.9480, lng: 72.8250, pincode: '400003' },
  { wardId: 'D', wardCode: 'D', wardName: 'D Ward (Grant Road / Malabar Hill)', zoneId: 'ZONE_2', active: true, lat: 18.9610, lng: 72.8120, pincode: '400007' },
  { wardId: 'E', wardCode: 'E', wardName: 'E Ward (Byculla)', zoneId: 'ZONE_2', active: true, lat: 18.9730, lng: 72.8310, pincode: '400008' },
  { wardId: 'F_NORTH', wardCode: 'F/North', wardName: 'F North Ward (Matunga / Sion / Wadala)', zoneId: 'ZONE_2', active: true, lat: 19.0320, lng: 72.8590, pincode: '400019' },
  { wardId: 'F_SOUTH', wardCode: 'F/South', wardName: 'F South Ward (Parel / Sewri)', zoneId: 'ZONE_2', active: true, lat: 18.9980, lng: 72.8420, pincode: '400012' },
  { wardId: 'G_NORTH', wardCode: 'G/North', wardName: 'G North Ward (Dadar / Mahim / Dharavi)', zoneId: 'ZONE_2', active: true, lat: 19.0410, lng: 72.8430, pincode: '400028' },
  { wardId: 'G_SOUTH', wardCode: 'G/South', wardName: 'G South Ward (Worli / Lower Parel)', zoneId: 'ZONE_2', active: true, lat: 19.0060, lng: 72.8190, pincode: '400018' },
  { wardId: 'H_EAST', wardCode: 'H/East', wardName: 'H East Ward (Santacruz East / Khar East)', zoneId: 'ZONE_3', active: true, lat: 19.0820, lng: 72.8520, pincode: '400055' },
  { wardId: 'H_WEST', wardCode: 'H/West', wardName: 'H West Ward (Bandra West)', zoneId: 'ZONE_3', active: true, lat: 19.0580, lng: 72.8310, pincode: '400050' },
  { wardId: 'K_EAST', wardCode: 'K/East', wardName: 'K East Ward (Andheri East)', zoneId: 'ZONE_3', active: true, lat: 19.1170, lng: 72.8640, pincode: '400069' },
  { wardId: 'K_WEST', wardCode: 'K/West', wardName: 'K West Ward (Andheri West / Juhu)', zoneId: 'ZONE_3', active: true, lat: 19.1360, lng: 72.8270, pincode: '400058' },
  { wardId: 'P_NORTH', wardCode: 'P/North', wardName: 'P North Ward (Malad)', zoneId: 'ZONE_4', active: true, lat: 19.1860, lng: 72.8480, pincode: '400064' },
  { wardId: 'P_SOUTH', wardCode: 'P/South', wardName: 'P South Ward (Goregaon)', zoneId: 'ZONE_4', active: true, lat: 19.1640, lng: 72.8490, pincode: '400104' },
  { wardId: 'L', wardCode: 'L', wardName: 'L Ward (Kurla / Sakinaka)', zoneId: 'ZONE_5', active: true, lat: 19.0710, lng: 72.8800, pincode: '400070' },
  { wardId: 'M_EAST', wardCode: 'M/East', wardName: 'M East Ward (Govandi / Mankhurd)', zoneId: 'ZONE_5', active: true, lat: 19.0550, lng: 72.9280, pincode: '400043' },
  { wardId: 'M_WEST', wardCode: 'M/West', wardName: 'M West Ward (Chembur West)', zoneId: 'ZONE_5', active: true, lat: 19.0620, lng: 72.8980, pincode: '400071' },
  { wardId: 'N', wardCode: 'N', wardName: 'N Ward (Ghatkopar / Vikhroli West)', zoneId: 'ZONE_6', active: true, lat: 19.0880, lng: 72.9080, pincode: '400077' },
  { wardId: 'S', wardCode: 'S', wardName: 'S Ward (Bhandup / Powai / Kanjurmarg)', zoneId: 'ZONE_6', active: true, lat: 19.1460, lng: 72.9340, pincode: '400078' },
  { wardId: 'T', wardCode: 'T', wardName: 'T Ward (Mulund / Nahur)', zoneId: 'ZONE_6', active: true, lat: 19.1720, lng: 72.9560, pincode: '400080' },
  { wardId: 'R_CENTRAL', wardCode: 'R/Central', wardName: 'R Central Ward (Borivali / Gorai)', zoneId: 'ZONE_7', active: true, lat: 19.2310, lng: 72.8560, pincode: '400092' },
  { wardId: 'R_NORTH', wardCode: 'R/North', wardName: 'R North Ward (Dahisar)', zoneId: 'ZONE_7', active: true, lat: 19.2570, lng: 72.8610, pincode: '400068' },
  { wardId: 'R_SOUTH', wardCode: 'R/South', wardName: 'R South Ward (Kandivali)', zoneId: 'ZONE_7', active: true, lat: 19.2060, lng: 72.8520, pincode: '400067' }
];

// 3. 18 DEPARTMENTS DEFINITION
const DEPARTMENTS = [
  {
    departmentId: 'maintenance_roads',
    departmentCode: 'RDS',
    displayName: 'Roads & Maintenance',
    description: 'Pothole repairs, asphalt resurfacing, road trenches, footpaths, mastic asphalt treatments, and pedestrian walkways.',
    active: true,
    citizenComplaintEnabled: true,
    defaultLeadDesignation: 'Assistant Engineer (Roads)'
  },
  {
    departmentId: 'water_works',
    departmentCode: 'WW',
    displayName: 'Water Works & Supply',
    description: 'Potable water pipelines, valve leakages, low pressure grievances, contaminated water, and municipal water tankers.',
    active: true,
    citizenComplaintEnabled: true,
    defaultLeadDesignation: 'Assistant Engineer (Water Works)'
  },
  {
    departmentId: 'solid_waste_management',
    departmentCode: 'SWM',
    displayName: 'Solid Waste Management',
    description: 'Garbage accumulation, community waste bins, street sweeping, compactor truck routes, and debris removal.',
    active: true,
    citizenComplaintEnabled: true,
    defaultLeadDesignation: 'Assistant Engineer (SWM)'
  },
  {
    departmentId: 'building_factory',
    departmentCode: 'BF',
    displayName: 'Building & Factory',
    description: 'Structural safety inspections, dangerous dilapidated buildings, unauthorized structural alterations, and factory permits.',
    active: true,
    citizenComplaintEnabled: true,
    defaultLeadDesignation: 'Assistant Engineer (Building & Factory)'
  },
  {
    departmentId: 'garden_trees',
    departmentCode: 'GDN',
    displayName: 'Gardens & Trees',
    description: 'Dangerous tree branch trimming, fallen trees, municipal parks, garden cleanliness, and tree census.',
    active: true,
    citizenComplaintEnabled: true,
    defaultLeadDesignation: 'Assistant Superintendent of Gardens'
  },
  {
    departmentId: 'public_health',
    departmentCode: 'PH',
    displayName: 'Public Health',
    description: 'Epidemic surveillance, public dispensaries, maternal health centers, birth & death registration, and food hygiene.',
    active: true,
    citizenComplaintEnabled: true,
    defaultLeadDesignation: 'Medical Officer of Health (MOH)'
  },
  {
    departmentId: 'pest_control_insecticide',
    departmentCode: 'PCI',
    displayName: 'Pest Control & Insecticide',
    description: 'Mosquito fogging, vector-borne disease prevention, rodent control, stagnant water inspection, and insecticide spray.',
    active: true,
    citizenComplaintEnabled: true,
    defaultLeadDesignation: 'Pest Control Officer (PCO)'
  },
  {
    departmentId: 'encroachment',
    departmentCode: 'ENC',
    displayName: 'Encroachment Removal',
    description: 'Clearing unauthorized hawkers, illegal pavement structures, demolition of illegal extensions, and public right-of-way.',
    active: true,
    citizenComplaintEnabled: true,
    defaultLeadDesignation: 'Encroachment Removal Officer'
  },
  {
    departmentId: 'licence',
    departmentCode: 'LIC',
    displayName: 'Licence Department',
    description: 'Trade licences, commercial signage permits, billboard advertising regulations, and storage licences.',
    active: true,
    citizenComplaintEnabled: true,
    defaultLeadDesignation: 'Senior Inspector (Licence)'
  },
  {
    departmentId: 'shops_establishments',
    departmentCode: 'SE',
    displayName: 'Shops & Establishments',
    description: 'Gumasta registration, commercial working hour inspections, retail compliance, and establishment safety.',
    active: true,
    citizenComplaintEnabled: true,
    defaultLeadDesignation: 'Senior Inspector (Shops & Est.)'
  },
  {
    departmentId: 'assessment_collection',
    departmentCode: 'AC',
    displayName: 'Assessment & Collection',
    description: 'Property tax assessments, municipal dues, municipal billing grievances, and civic property valuation.',
    active: true,
    citizenComplaintEnabled: true,
    defaultLeadDesignation: 'Assistant Assessor & Collector'
  },
  {
    departmentId: 'estate',
    departmentCode: 'EST',
    displayName: 'Estate Department',
    description: 'Municipal property management, civic leases, municipal tenancies, and municipal land protection.',
    active: true,
    citizenComplaintEnabled: true,
    defaultLeadDesignation: 'Administrative Officer (Estates)'
  },
  {
    departmentId: 'colony_slum',
    departmentCode: 'CSI',
    displayName: 'Colony & Slum Improvement',
    description: 'Basic civic amenities in notified slums, public community toilets, pathway paving, and community lighting.',
    active: true,
    citizenComplaintEnabled: true,
    defaultLeadDesignation: 'Assistant Engineer (Slum Improvement)'
  },
  {
    departmentId: 'education_schools',
    departmentCode: 'EDU',
    displayName: 'Education & Municipal Schools',
    description: 'BMC school infrastructure, classroom maintenance, municipal drinking water in schools, and civic education programs.',
    active: true,
    citizenComplaintEnabled: true,
    defaultLeadDesignation: 'Administrative Officer (Schools)'
  },
  {
    departmentId: 'security',
    departmentCode: 'SEC',
    displayName: 'Security Force',
    description: 'BMC security force, ward office security, municipal installation guarding, and civic vigil.',
    active: true,
    citizenComplaintEnabled: false,
    defaultLeadDesignation: 'Divisional Security Officer'
  },
  {
    departmentId: 'legal',
    departmentCode: 'LEG',
    displayName: 'Legal Department',
    description: 'Municipal litigation, court notices, legal advisory to ward officers, and dispute resolution.',
    active: true,
    citizenComplaintEnabled: false,
    defaultLeadDesignation: 'Assistant Law Officer'
  },
  {
    departmentId: 'administration_establishment',
    departmentCode: 'ADM',
    displayName: 'Administration & Establishment',
    description: 'Ward human resources, personnel grievance cell, public relations, and general administrative services.',
    active: true,
    citizenComplaintEnabled: false,
    defaultLeadDesignation: 'Administrative Officer (Establishment)'
  },
  {
    departmentId: 'town_planning_development_plan',
    departmentCode: 'TP',
    displayName: 'Town Planning & Development Plan',
    description: 'Development plan DP-2034 implementation, civic zoning verification, reservation tracking, and urban planning compliance.',
    active: true,
    citizenComplaintEnabled: true,
    defaultLeadDesignation: 'Assistant Engineer (Town Planning)'
  }
];

// Names list for synthetic personnel generation
const FIRST_NAMES = [
  'Arun', 'Ramesh', 'Suresh', 'Pooja', 'Vijay', 'Anil', 'Meera', 'Karan', 'Sunil', 'Nitin',
  'Deepak', 'Sanjay', 'Pravin', 'Sachin', 'Amol', 'Ganesh', 'Kishor', 'Rajesh', 'Vilas', 'Ashok',
  'Mahesh', 'Santosh', 'Milind', 'Vinod', 'Hemant', 'Ajay', 'Ravindra', 'Prashant', 'Umesh', 'Vikas',
  'Smita', 'Sunita', 'Swati', 'Manish', 'Rahul', 'Chetan', 'Sandip', 'Suhas', 'Kailash', 'Dattatray'
];

const LAST_NAMES = [
  'Deshmukh', 'Patel', 'More', 'Kulkarni', 'Rane', 'Jadhav', 'Joshi', 'Verma', 'Shinde', 'Bhalerao',
  'Sawant', 'Chavan', 'Kadam', 'Pawar', 'Kamble', 'Salvi', 'Gaikwad', 'Mhatre', 'Koli', 'Thakur',
  'Suryavanshi', 'Gharat', 'Bhoir', 'Tendulkar', 'Wagh', 'Dumbre', 'Gawde', 'Gite', 'Tambe', 'Zore'
];

function generateSyntheticName(seedIndex) {
  const first = FIRST_NAMES[seedIndex % FIRST_NAMES.length];
  const last = LAST_NAMES[Math.floor(seedIndex / FIRST_NAMES.length) % LAST_NAMES.length];
  return `${first} ${last}`;
}

function generateMatrix() {
  const governmentUsers = [];
  const wardDepartments = [];
  const employeeIdSet = new Set();
  const userIdSet = new Set();
  let nameCounter = 0;

  function registerUser(user) {
    if (employeeIdSet.has(user.employeeId)) {
      throw new Error(`Duplicate employeeId detected: ${user.employeeId}`);
    }
    if (userIdSet.has(user.id)) {
      throw new Error(`Duplicate userId detected: ${user.id}`);
    }
    employeeIdSet.add(user.employeeId);
    userIdSet.add(user.id);
    governmentUsers.push(user);
    return user;
  }

  // 1. SUPER ADMIN (1)
  const superAdminId = 'usr_gov_sa_001';
  const superAdminEmpId = 'GOV-SA-001';
  registerUser({
    id: superAdminId,
    employeeId: superAdminEmpId,
    fullName: 'Dr. Bhushan Gagrani, IAS',
    email: 'commissioner@mcgm.gov.in',
    phone: '+91 22 2262 0251',
    role: 'government_super_admin',
    displayDesignation: 'Municipal Commissioner & Administrator',
    wardId: null,
    zoneId: null,
    departmentId: null,
    administrativeSupervisorId: null,
    technicalSupervisorId: null,
    active: true,
    isSynthetic: false,
    permissions: ['all', 'admin_override', 'view_all_complaints', 'system_config', 'reassign_override'],
    createdAt: '2026-09-27T00:00:00Z',
    updatedAt: '2026-09-27T00:00:00Z'
  });

  // 2. ZONAL DMCs (7)
  const zoneDmcMap = {}; // zoneId -> user
  ZONES.forEach((z) => {
    const paddedNum = String(z.zoneNumber).padStart(2, '0');
    const empId = `GOV-DMC-Z${paddedNum}`;
    const userId = `usr_gov_dmc_z${paddedNum}`;
    const name = `DMC ${generateSyntheticName(nameCounter++)}`;
    const email = `dmc.zone${z.zoneNumber}@mcgm.gov.in`;

    const user = registerUser({
      id: userId,
      employeeId: empId,
      fullName: name,
      email: email,
      phone: `+91 22 2495 ${1000 + z.zoneNumber}`,
      role: 'zonal_dmc',
      displayDesignation: `Deputy Municipal Commissioner (${z.displayName})`,
      wardId: null,
      zoneId: z.zoneId,
      departmentId: null,
      administrativeSupervisorId: superAdminEmpId,
      technicalSupervisorId: null,
      active: true,
      isSynthetic: true,
      permissions: ['view_zonal_complaints', 'zonal_analytics', 'ward_oversight', 'escalation_monitoring'],
      createdAt: '2026-09-27T00:00:00Z',
      updatedAt: '2026-09-27T00:00:00Z'
    });
    zoneDmcMap[z.zoneId] = user;
  });

  // 3. CENTRAL DEPARTMENT HODs (18)
  const centralHodMap = {}; // departmentId -> user
  DEPARTMENTS.forEach((dept) => {
    const deptUpper = dept.departmentId.toUpperCase();
    const empId = `GOV-HOD-${deptUpper}`;
    const userId = `usr_gov_hod_${dept.departmentId}`;
    const name = `Chief Eng. ${generateSyntheticName(nameCounter++)}`;
    const email = `hod.${dept.departmentCode.toLowerCase()}@mcgm.gov.in`;

    const user = registerUser({
      id: userId,
      employeeId: empId,
      fullName: name,
      email: email,
      phone: `+91 22 2495 ${2000 + (nameCounter % 900)}`,
      role: 'central_department_hod',
      displayDesignation: `Chief Engineer / Head of Department (${dept.displayName})`,
      wardId: null,
      zoneId: null,
      departmentId: dept.departmentId,
      administrativeSupervisorId: superAdminEmpId,
      technicalSupervisorId: null,
      active: true,
      isSynthetic: true,
      permissions: ['technical_oversight', 'view_department_complaints_all_wards', 'sla_standards_management'],
      createdAt: '2026-09-27T00:00:00Z',
      updatedAt: '2026-09-27T00:00:00Z'
    });
    centralHodMap[dept.departmentId] = user;
  });

  // 4. WARD OFFICERS (24)
  const wardOfficerMap = {}; // wardId -> user
  WARD_DEFINITIONS.forEach((w) => {
    const empId = `GOV-WO-${w.wardId}`;
    const userId = `usr_gov_wo_${w.wardId.toLowerCase()}`;
    const name = `AMC ${generateSyntheticName(nameCounter++)}`;
    const email = `ward.${w.wardCode.toLowerCase().replace('/', '_')}@mcgm.gov.in`;
    const dmc = zoneDmcMap[w.zoneId];

    const user = registerUser({
      id: userId,
      employeeId: empId,
      fullName: name,
      email: email,
      phone: `+91 22 2495 ${3000 + (nameCounter % 900)}`,
      role: 'ward_officer',
      displayDesignation: `Assistant Municipal Commissioner (Ward ${w.wardCode})`,
      wardId: w.wardId,
      zoneId: w.zoneId,
      departmentId: null,
      administrativeSupervisorId: dmc.employeeId,
      technicalSupervisorId: null,
      active: true,
      isSynthetic: true,
      permissions: [
        'ward_administrative_control',
        'view_ward_complaints',
        'approve_routing_ticket',
        'reject_routing_ticket',
        'ward_analytics',
        'sla_monitoring'
      ],
      createdAt: '2026-09-27T00:00:00Z',
      updatedAt: '2026-09-27T00:00:00Z'
    });
    wardOfficerMap[w.wardId] = user;
  });

  // 5. WARD DEPARTMENT LEADS (24 x 18 = 432)
  // and 6. AUTHORISED DEPARTMENT CREW (24 x 18 x 5 = 2,160)
  WARD_DEFINITIONS.forEach((w) => {
    const wardOfficer = wardOfficerMap[w.wardId];

    DEPARTMENTS.forEach((dept) => {
      const deptUpper = dept.departmentId.toUpperCase();
      const centralHod = centralHodMap[dept.departmentId];

      // A. Ward Department Lead
      const leadEmpId = `GOV-WDL-${w.wardId}-${deptUpper}`;
      const leadUserId = `usr_gov_wdl_${w.wardId.toLowerCase()}_${dept.departmentId}`;
      const leadName = generateSyntheticName(nameCounter++);
      const leadEmail = `lead.${w.wardId.toLowerCase()}.${dept.departmentCode.toLowerCase()}@mcgm.gov.in`;

      const leadUser = registerUser({
        id: leadUserId,
        employeeId: leadEmpId,
        fullName: leadName,
        email: leadEmail,
        phone: `+91 98200 ${String(nameCounter).padStart(5, '0')}`,
        role: 'ward_department_lead',
        displayDesignation: `${dept.defaultLeadDesignation} - Ward ${w.wardCode}`,
        wardId: w.wardId,
        zoneId: w.zoneId,
        departmentId: dept.departmentId,
        administrativeSupervisorId: wardOfficer.employeeId,
        technicalSupervisorId: centralHod.employeeId,
        active: true,
        isSynthetic: true,
        permissions: [
          'assign_crew',
          'raise_wrong_department_ticket',
          'verify_resolution',
          'update_complaint_status',
          'view_department_ward_complaints'
        ],
        createdAt: '2026-09-27T00:00:00Z',
        updatedAt: '2026-09-27T00:00:00Z'
      });

      // B. 5 Department Crew Members
      const crewEmpIds = [];
      for (let c = 1; c <= 5; c++) {
        const crewIndexStr = String(c).padStart(2, '0');
        const crewEmpId = `GOV-CREW-${w.wardId}-${deptUpper}-${crewIndexStr}`;
        const crewUserId = `usr_gov_crew_${w.wardId.toLowerCase()}_${dept.departmentId}_${crewIndexStr}`;
        const crewName = generateSyntheticName(nameCounter++);
        const crewEmail = `crew.${w.wardId.toLowerCase()}.${dept.departmentCode.toLowerCase()}.${crewIndexStr}@mcgm.gov.in`;

        registerUser({
          id: crewUserId,
          employeeId: crewEmpId,
          fullName: crewName,
          email: crewEmail,
          phone: `+91 98300 ${String(nameCounter).padStart(5, '0')}`,
          role: 'department_crew',
          displayDesignation: `Field Crew Technician ${c} (${dept.displayName}) - Ward ${w.wardCode}`,
          wardId: w.wardId,
          zoneId: w.zoneId,
          departmentId: dept.departmentId,
          supervisorId: leadUser.employeeId,
          administrativeSupervisorId: leadUser.employeeId,
          technicalSupervisorId: null,
          active: true,
          isSynthetic: true,
          permissions: [
            'view_assigned_work',
            'update_work_status',
            'submit_resolution_evidence'
          ],
          createdAt: '2026-09-27T00:00:00Z',
          updatedAt: '2026-09-27T00:00:00Z'
        });

        crewEmpIds.push(crewEmpId);
      }

      // C. Ward Department Record (432 total)
      const wardDeptId = `WD-${w.wardId}-${deptUpper}`;
      wardDepartments.push({
        wardDepartmentId: wardDeptId,
        wardId: w.wardId,
        departmentId: dept.departmentId,
        departmentLeadId: leadUser.employeeId,
        crewMemberIds: crewEmpIds, // exactly 5
        administrativeSupervisorId: wardOfficer.employeeId,
        technicalSupervisorId: centralHod.employeeId,
        active: true
      });
    });
  });

  // Programmatic verification of counts
  const superAdminCount = governmentUsers.filter(u => u.role === 'government_super_admin').length;
  const zonalDmcCount = governmentUsers.filter(u => u.role === 'zonal_dmc').length;
  const centralHodCount = governmentUsers.filter(u => u.role === 'central_department_hod').length;
  const wardOfficerCount = governmentUsers.filter(u => u.role === 'ward_officer').length;
  const wardDeptLeadCount = governmentUsers.filter(u => u.role === 'ward_department_lead').length;
  const crewCount = governmentUsers.filter(u => u.role === 'department_crew').length;
  const totalCount = governmentUsers.length;

  console.log('=== GOVERNMENT MATRIX STATS ===');
  console.log(`Zones: ${ZONES.length}`);
  console.log(`Wards: ${WARD_DEFINITIONS.length}`);
  console.log(`Departments: ${DEPARTMENTS.length}`);
  console.log(`Ward Departments: ${wardDepartments.length}`);
  console.log(`Super Admins: ${superAdminCount}`);
  console.log(`Zonal DMCs: ${zonalDmcCount}`);
  console.log(`Central HODs: ${centralHodCount}`);
  console.log(`Ward Officers: ${wardOfficerCount}`);
  console.log(`Ward Department Leads: ${wardDeptLeadCount}`);
  console.log(`Department Crew: ${crewCount}`);
  console.log(`Total Government Users: ${totalCount}`);

  // Assertions
  if (ZONES.length !== 7) throw new Error(`Expected 7 zones, got ${ZONES.length}`);
  if (WARD_DEFINITIONS.length !== 24) throw new Error(`Expected 24 wards, got ${WARD_DEFINITIONS.length}`);
  if (DEPARTMENTS.length !== 18) throw new Error(`Expected 18 departments, got ${DEPARTMENTS.length}`);
  if (wardDepartments.length !== 432) throw new Error(`Expected 432 ward departments, got ${wardDepartments.length}`);
  if (superAdminCount !== 1) throw new Error(`Expected 1 Super Admin, got ${superAdminCount}`);
  if (zonalDmcCount !== 7) throw new Error(`Expected 7 Zonal DMCs, got ${zonalDmcCount}`);
  if (centralHodCount !== 18) throw new Error(`Expected 18 Central HODs, got ${centralHodCount}`);
  if (wardOfficerCount !== 24) throw new Error(`Expected 24 Ward Officers, got ${wardOfficerCount}`);
  if (wardDeptLeadCount !== 432) throw new Error(`Expected 432 Ward Department Leads, got ${wardDeptLeadCount}`);
  if (crewCount !== 2160) throw new Error(`Expected 2,160 Crew, got ${crewCount}`);
  if (totalCount !== 2642) throw new Error(`Expected 2,642 Total Users, got ${totalCount}`);

  // Check every ward department has exactly 5 crew
  for (const wd of wardDepartments) {
    if (wd.crewMemberIds.length !== 5) {
      throw new Error(`WardDepartment ${wd.wardDepartmentId} does not have exactly 5 crew members!`);
    }
  }

  // Check supervisor relationships (no orphan IDs)
  for (const user of governmentUsers) {
    if (user.administrativeSupervisorId && !employeeIdSet.has(user.administrativeSupervisorId)) {
      throw new Error(`User ${user.employeeId} has orphan administrativeSupervisorId: ${user.administrativeSupervisorId}`);
    }
    if (user.technicalSupervisorId && !employeeIdSet.has(user.technicalSupervisorId)) {
      throw new Error(`User ${user.employeeId} has orphan technicalSupervisorId: ${user.technicalSupervisorId}`);
    }
  }

  console.log('All assertions PASSED! No orphan supervisor IDs, no duplicate employee IDs.');

  // Create Manifest
  const manifest = {
    generatedAt: new Date().toISOString(),
    version: '2.0.0',
    city: 'Mumbai',
    organization: 'Brihanmumbai Municipal Corporation (BMC)',
    governmentSuperAdmins: superAdminCount,
    zonalDMCs: zonalDmcCount,
    centralDepartmentHODs: centralHodCount,
    wardOfficers: wardOfficerCount,
    wardDepartmentLeads: wardDeptLeadCount,
    departmentCrew: crewCount,
    totalGovernmentUsers: totalCount,
    wards: WARD_DEFINITIONS.length,
    zones: ZONES.length,
    departments: DEPARTMENTS.length,
    wardDepartments: wardDepartments.length
  };

  // Create Hierarchy Graph Structure
  const hierarchyGraph = {
    title: 'BMC CivicFix Dual-Chain Municipal Matrix Hierarchy',
    superAdmin: superAdminEmpId,
    zones: ZONES.map(z => ({
      zoneId: z.zoneId,
      displayName: z.displayName,
      dmcEmployeeId: `GOV-DMC-Z${String(z.zoneNumber).padStart(2, '0')}`,
      wards: WARD_DEFINITIONS.filter(w => w.zoneId === z.zoneId).map(w => ({
        wardId: w.wardId,
        wardName: w.wardName,
        wardOfficerEmployeeId: `GOV-WO-${w.wardId}`,
        departments: DEPARTMENTS.map(d => ({
          departmentId: d.departmentId,
          leadEmployeeId: `GOV-WDL-${w.wardId}-${d.departmentId.toUpperCase()}`,
          technicalSupervisorId: `GOV-HOD-${d.departmentId.toUpperCase()}`,
          crewEmployeeIds: [1, 2, 3, 4, 5].map(c => `GOV-CREW-${w.wardId}-${d.departmentId.toUpperCase()}-${String(c).padStart(2, '0')}`)
        }))
      }))
    })),
    technicalDepartments: DEPARTMENTS.map(d => ({
      departmentId: d.departmentId,
      displayName: d.displayName,
      hodEmployeeId: `GOV-HOD-${d.departmentId.toUpperCase()}`,
      wardLeads: WARD_DEFINITIONS.map(w => `GOV-WDL-${w.wardId}-${d.departmentId.toUpperCase()}`)
    }))
  };

  // Write all canonical files
  fs.writeFileSync(path.join(GOVT_DATA_DIR, 'zones.json'), JSON.stringify({ zones: ZONES }, null, 2));
  fs.writeFileSync(path.join(GOVT_DATA_DIR, 'wards.json'), JSON.stringify({ wards: WARD_DEFINITIONS }, null, 2));
  fs.writeFileSync(path.join(GOVT_DATA_DIR, 'departments.json'), JSON.stringify({ departments: DEPARTMENTS }, null, 2));
  fs.writeFileSync(path.join(GOVT_DATA_DIR, 'ward_departments.json'), JSON.stringify({ wardDepartments }, null, 2));
  fs.writeFileSync(path.join(GOVT_DATA_DIR, 'government_users.json'), JSON.stringify({ governmentUsers }, null, 2));
  fs.writeFileSync(path.join(GOVT_DATA_DIR, 'government_hierarchy.json'), JSON.stringify(hierarchyGraph, null, 2));
  fs.writeFileSync(path.join(GOVT_DATA_DIR, 'seed_manifest.json'), JSON.stringify(manifest, null, 2));

  console.log('Successfully wrote all 7 dataset files to resources/Govt Data/');
}

generateMatrix();
