/**
 * CANONICAL 18 BMC DEPARTMENTS & 24 BMC WARDS DEFINITIONS
 * Authoritative source of truth for AI Department Verification and Automated JE Routing.
 */

export interface CanonicalDepartment {
  departmentId: string;
  departmentCode: string;
  displayName: string;
  description: string;
  citizenComplaintEnabled: boolean;
}

export interface CanonicalWard {
  wardId: string;
  wardCode: string;
  wardName: string;
  zoneId: string;
  lat: number;
  lng: number;
  pincode: string;
}

export const CANONICAL_DEPARTMENTS: readonly CanonicalDepartment[] = [
  {
    departmentId: 'maintenance_roads',
    departmentCode: 'RDS',
    displayName: 'Roads & Maintenance',
    description: 'Pothole repairs, asphalt resurfacing, road trenches, footpaths, mastic asphalt treatments, pedestrian walkways.',
    citizenComplaintEnabled: true,
  },
  {
    departmentId: 'water_works',
    departmentCode: 'WW',
    displayName: 'Water Works & Supply',
    description: 'Potable water pipelines, valve leakages, low pressure grievances, contaminated water, municipal water tankers.',
    citizenComplaintEnabled: true,
  },
  {
    departmentId: 'solid_waste_management',
    departmentCode: 'SWM',
    displayName: 'Solid Waste Management',
    description: 'Garbage accumulation, community waste bins, street sweeping, compactor truck routes, debris removal.',
    citizenComplaintEnabled: true,
  },
  {
    departmentId: 'building_factory',
    departmentCode: 'BF',
    displayName: 'Building & Factory',
    description: 'Structural safety inspections, dangerous dilapidated buildings, unauthorized structural alterations, factory permits.',
    citizenComplaintEnabled: true,
  },
  {
    departmentId: 'garden_trees',
    departmentCode: 'GDN',
    displayName: 'Gardens & Trees',
    description: 'Dangerous tree branch trimming, fallen trees, municipal parks, garden cleanliness, tree census.',
    citizenComplaintEnabled: true,
  },
  {
    departmentId: 'public_health',
    departmentCode: 'PH',
    displayName: 'Public Health',
    description: 'Epidemic surveillance, public dispensaries, maternal health centers, birth & death registration, food hygiene.',
    citizenComplaintEnabled: true,
  },
  {
    departmentId: 'pest_control_insecticide',
    departmentCode: 'PCI',
    displayName: 'Pest Control & Insecticide',
    description: 'Mosquito fogging, vector-borne disease prevention, rodent control, stagnant water inspection, insecticide spray.',
    citizenComplaintEnabled: true,
  },
  {
    departmentId: 'encroachment',
    departmentCode: 'ENC',
    displayName: 'Encroachment Removal',
    description: 'Clearing unauthorized hawkers, illegal pavement structures, demolition of illegal extensions, public right-of-way.',
    citizenComplaintEnabled: true,
  },
  {
    departmentId: 'licence',
    departmentCode: 'LIC',
    displayName: 'Licence Department',
    description: 'Trade licences, commercial signage permits, billboard advertising regulations, storage licences.',
    citizenComplaintEnabled: true,
  },
  {
    departmentId: 'shops_establishments',
    departmentCode: 'SE',
    displayName: 'Shops & Establishments',
    description: 'Gumasta registration, commercial working hour inspections, retail compliance, establishment safety.',
    citizenComplaintEnabled: true,
  },
  {
    departmentId: 'assessment_collection',
    departmentCode: 'AC',
    displayName: 'Assessment & Collection',
    description: 'Property tax assessments, municipal dues, municipal billing grievances, civic property valuation.',
    citizenComplaintEnabled: true,
  },
  {
    departmentId: 'estate',
    departmentCode: 'EST',
    displayName: 'Estate Department',
    description: 'Municipal property management, civic leases, municipal tenancies, municipal land protection.',
    citizenComplaintEnabled: true,
  },
  {
    departmentId: 'colony_slum',
    departmentCode: 'CSI',
    displayName: 'Colony & Slum Improvement',
    description: 'Basic civic amenities in notified slums, public community toilets, pathway paving, community lighting.',
    citizenComplaintEnabled: true,
  },
  {
    departmentId: 'education_schools',
    departmentCode: 'EDU',
    displayName: 'Education & Municipal Schools',
    description: 'BMC school infrastructure, classroom maintenance, municipal drinking water in schools, civic education programs.',
    citizenComplaintEnabled: true,
  },
  {
    departmentId: 'security',
    departmentCode: 'SEC',
    displayName: 'Security Force',
    description: 'BMC security force, ward office security, municipal installation guarding, civic vigil.',
    citizenComplaintEnabled: false,
  },
  {
    departmentId: 'legal',
    departmentCode: 'LEG',
    displayName: 'Legal Department',
    description: 'Municipal litigation, court notices, legal advisory to ward officers, dispute resolution.',
    citizenComplaintEnabled: false,
  },
  {
    departmentId: 'administration_establishment',
    departmentCode: 'ADM',
    displayName: 'Administration & Establishment',
    description: 'Ward human resources, personnel grievance cell, public relations, general administrative services.',
    citizenComplaintEnabled: false,
  },
  {
    departmentId: 'town_planning_development_plan',
    departmentCode: 'TP',
    displayName: 'Town Planning & Development Plan',
    description: 'Development plan DP-2034 implementation, civic zoning verification, reservation tracking, urban planning compliance.',
    citizenComplaintEnabled: true,
  },
] as const;

export const ALLOWED_DEPARTMENT_IDS: ReadonlySet<string> = new Set(
  CANONICAL_DEPARTMENTS.map((d) => d.departmentId)
);

export function isValidDepartmentId(deptId: string): boolean {
  if (!deptId) return false;
  return ALLOWED_DEPARTMENT_IDS.has(deptId.trim().toLowerCase());
}

export function getDepartmentById(deptId: string): CanonicalDepartment | undefined {
  if (!deptId) return undefined;
  const clean = deptId.trim().toLowerCase();
  return CANONICAL_DEPARTMENTS.find((d) => d.departmentId === clean);
}

export function generateDepartmentPromptList(): string {
  return CANONICAL_DEPARTMENTS.map(
    (d) => `- ID: "${d.departmentId}" | Name: "${d.displayName}" | Scope: ${d.description}`
  ).join('\n');
}

export const CANONICAL_WARDS: readonly CanonicalWard[] = [
  { wardId: 'A', wardCode: 'A', wardName: 'A Ward (Fort / Colaba)', zoneId: 'ZONE_1', lat: 18.922, lng: 72.8347, pincode: '400001' },
  { wardId: 'B', wardCode: 'B', wardName: 'B Ward (Dongri / Mandvi)', zoneId: 'ZONE_1', lat: 18.956, lng: 72.838, pincode: '400002' },
  { wardId: 'C', wardCode: 'C', wardName: 'C Ward (Marine Lines / Bhuleshwar)', zoneId: 'ZONE_1', lat: 18.948, lng: 72.825, pincode: '400003' },
  { wardId: 'D', wardCode: 'D', wardName: 'D Ward (Grant Road / Malabar Hill)', zoneId: 'ZONE_2', lat: 18.961, lng: 72.812, pincode: '400007' },
  { wardId: 'E', wardCode: 'E', wardName: 'E Ward (Byculla)', zoneId: 'ZONE_2', lat: 18.973, lng: 72.831, pincode: '400008' },
  { wardId: 'F_NORTH', wardCode: 'F/North', wardName: 'F North Ward (Matunga / Sion / Wadala)', zoneId: 'ZONE_2', lat: 19.032, lng: 72.859, pincode: '400019' },
  { wardId: 'F_SOUTH', wardCode: 'F/South', wardName: 'F South Ward (Parel / Sewri)', zoneId: 'ZONE_2', lat: 18.998, lng: 72.842, pincode: '400012' },
  { wardId: 'G_NORTH', wardCode: 'G/North', wardName: 'G North Ward (Dadar / Mahim / Dharavi)', zoneId: 'ZONE_2', lat: 19.041, lng: 72.843, pincode: '400028' },
  { wardId: 'G_SOUTH', wardCode: 'G/South', wardName: 'G South Ward (Worli / Lower Parel)', zoneId: 'ZONE_2', lat: 19.006, lng: 72.819, pincode: '400018' },
  { wardId: 'H_EAST', wardCode: 'H/East', wardName: 'H East Ward (Santacruz East / Khar East)', zoneId: 'ZONE_3', lat: 19.082, lng: 72.852, pincode: '400055' },
  { wardId: 'H_WEST', wardCode: 'H/West', wardName: 'H West Ward (Bandra / Khar / Santacruz West)', zoneId: 'ZONE_3', lat: 19.058, lng: 72.833, pincode: '400050' },
  { wardId: 'K_EAST', wardCode: 'K/East', wardName: 'K East Ward (Andheri East / Vile Parle East)', zoneId: 'ZONE_3', lat: 19.117, lng: 72.863, pincode: '400069' },
  { wardId: 'K_WEST', wardCode: 'K/West', wardName: 'K West Ward (Andheri West / Juhu / Versova)', zoneId: 'ZONE_3', lat: 19.124, lng: 72.836, pincode: '400058' },
  { wardId: 'L', wardCode: 'L', wardName: 'L Ward (Kurla / Chunabhatti)', zoneId: 'ZONE_5', lat: 19.072, lng: 72.883, pincode: '400070' },
  { wardId: 'M_EAST', wardCode: 'M/East', wardName: 'M East Ward (Govandi / Mankhurd)', zoneId: 'ZONE_5', lat: 19.055, lng: 72.915, pincode: '400088' },
  { wardId: 'M_WEST', wardCode: 'M/West', wardName: 'M West Ward (Chembur / Tilak Nagar)', zoneId: 'ZONE_5', lat: 19.062, lng: 72.898, pincode: '400071' },
  { wardId: 'N', wardCode: 'N', wardName: 'N Ward (Ghatkopar / Vikhroli)', zoneId: 'ZONE_6', lat: 19.086, lng: 72.909, pincode: '400077' },
  { wardId: 'P_NORTH', wardCode: 'P/North', wardName: 'P North Ward (Malad / Marve)', zoneId: 'ZONE_4', lat: 19.186, lng: 72.848, pincode: '400064' },
  { wardId: 'P_SOUTH', wardCode: 'P/South', wardName: 'P South Ward (Goregaon)', zoneId: 'ZONE_4', lat: 19.163, lng: 72.846, pincode: '400104' },
  { wardId: 'R_CENTRAL', wardCode: 'R/Central', wardName: 'R Central Ward (Borivali)', zoneId: 'ZONE_7', lat: 19.231, lng: 72.856, pincode: '400092' },
  { wardId: 'R_NORTH', wardCode: 'R/North', wardName: 'R North Ward (Dahisar)', zoneId: 'ZONE_7', lat: 19.257, lng: 72.862, pincode: '400068' },
  { wardId: 'R_SOUTH', wardCode: 'R/South', wardName: 'R South Ward (Kandivali / Charkop)', zoneId: 'ZONE_7', lat: 19.206, lng: 72.848, pincode: '400067' },
  { wardId: 'S', wardCode: 'S', wardName: 'S Ward (Bhandup / Powai / Kanjurmarg)', zoneId: 'ZONE_6', lat: 19.144, lng: 72.935, pincode: '400078' },
  { wardId: 'T', wardCode: 'T', wardName: 'T Ward (Mulund / Nahur)', zoneId: 'ZONE_6', lat: 19.176, lng: 72.955, pincode: '400080' },
] as const;

export function calculateDistanceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const earthRadiusKm = 6371.0;
  const dLat = (lat2 - lat1) * (Math.PI / 180.0);
  const dLon = (lon2 - lon1) * (Math.PI / 180.0);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180.0)) *
      Math.cos(lat2 * (Math.PI / 180.0)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadiusKm * c;
}

export function resolveWardForLocation(
  lat?: number,
  lng?: number,
  rawWard?: string
): CanonicalWard | null {
  // 1. Check raw ward if present
  if (rawWard && rawWard.trim().length > 0) {
    const clean = rawWard.trim().toLowerCase();
    for (const ward of CANONICAL_WARDS) {
      if (
        ward.wardId.toLowerCase() === clean ||
        ward.wardCode.toLowerCase() === clean ||
        ward.wardName.toLowerCase().includes(clean)
      ) {
        return ward;
      }
    }
  }

  // 2. Check coordinates proximity
  if (lat !== undefined && lng !== undefined && (lat !== 0 || lng !== 0)) {
    let closestWard: CanonicalWard | null = null;
    let minDistance = Infinity;

    for (const ward of CANONICAL_WARDS) {
      const dist = calculateDistanceKm(lat, lng, ward.lat, ward.lng);
      if (dist < minDistance) {
        minDistance = dist;
        closestWard = ward;
      }
    }

    // Must be within Mumbai administrative perimeter (~35km of any ward centroid)
    if (closestWard && minDistance <= 35.0) {
      return closestWard;
    }
  }

  // Strictly return null if coordinates or ward cannot be validated (No silent G/North fallback)
  return null;
}
