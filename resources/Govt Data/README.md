# CivicFix — Municipal Government Data Registry

This directory contains municipal structural reference data for the **Brihanmumbai Municipal Corporation (BMC / MCGM)** in **CivicFix**.

---

## 1. Directory Structure

```text
resources/Govt Data/
├── legacy_backup/                        # Archive of legacy 1,057 officer datasets (CSV, JSON, XLS, XLSX, README)
│   ├── government_officers.csv
│   ├── government_officers.json
│   ├── government_officers.xls
│   ├── government_officers.xlsx
│   └── README.md
├── legacy_government_schema_report.md    # Comprehensive Phase 1 audit and schema report of legacy model
├── departments.json                      # 7 Core BMC Technical Departments metadata
├── wards.json                            # 24 BMC Administrative Wards registry & GIS boundaries
└── PHASE_1_GOVERNMENT_CLEANUP_REPORT.md  # Phase 1 completion and audit verification report
```

---

## 2. Active Canonical Metadata

- **`departments.json`**: Authoritative registry of the 7 BMC technical departments (Mechanical & Electrical, Roads, Solid Waste Management, Storm Water Drains, Hydraulic Engineer, Gardens, Sewerage Operations) with service level agreements (SLAs), operating zones, and department codes.
- **`wards.json`**: Authoritative registry of Mumbai's 24 administrative municipal wards (Wards A through T) with boundaries, center coordinates, ward offices, and administrative codes.

---

## 3. Upcoming Phase 2 BMC Governance Architecture

In Phase 2, the following 6-tier BMC hierarchical roles will replace the legacy structure:

1. `government_super_admin`: Apex Municipal Leadership (MC & AMC)
2. `zonal_dmc`: Deputy Municipal Commissioners for City, Eastern & Western Suburbs
3. `central_department_hod`: Chief Engineers & Department Heads
4. `ward_officer`: Assistant Municipal Commissioners (AMCs) per Ward
5. `ward_department_lead`: Executive Engineers & Ward Departmental Leads
6. `department_crew`: Sub-Engineers, Junior Engineers & Ground Crews
