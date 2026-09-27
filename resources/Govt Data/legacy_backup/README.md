# Brihanmumbai Municipal Corporation (BMC / MCGM) — Government Officers Dataset (1,057 Personnel)

This directory contains the canonical municipal operational dataset of 1,057 authorized municipal officers, ward administrators, elected corporators, departmental leads, and on-field engineers for the **Brihanmumbai Municipal Corporation (MCGM / BMC)** in **CivicFix**.

The dataset features a streamlined 7-column schema, a strictly validated **10-character deterministic UID**, authentic municipal designations, departmental affiliations, and role-based test authentication passwords.

---

## 1. Directory Structure & File Manifest

```text
resources/Govt Data/
├── government_officers.xlsx  # Styled Excel Workbook with 1,057 officers, dark header & alternating fills
├── government_officers.xls   # Excel 97-2003 compatible workbook copy
├── government_officers.csv   # Tabular CSV (1,058 lines: 1 header + 1,057 records)
├── government_officers.json  # Complete JSON catalog with summary breakdown for Firestore & APIs
├── departments.json          # 7 Core BMC Departments (M&E, Roads, SWM, SWD, Hydraulic, Gardens, Sewerage)
├── wards.json                # 24 BMC Administrative Wards (A through T, boundaries, AMC offices)
└── README.md                 # System documentation, UID specifications, and role hierarchy
```

---

## 2. Municipal Personnel Hierarchy Breakdown (1,057 Officers)

The dataset precisely implements the requested 5-tier municipal governance architecture:

$$\text{Total Officers} = 1 + 24 + 24 + (24 \times 7) + (24 \times 7 \times 5) = 1 + 24 + 24 + 168 + 840 = \mathbf{1,057}$$

```text
┌────────────────────────────────────────────────────────────────────────┐
│               MUNICIPAL COMMISSIONER & ADMINISTRATOR                   │
│                    Dr. Bhushan Gagrani, IAS (1)                        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
         ┌──────────────────────────┴──────────────────────────┐
         ▼                                                     ▼
┌──────────────────────────────┐        ┌──────────────────────────────┐
│     24 WARD OFFICERS         │        │    24 WARD NAGARSEVAKS       │
│ Assistant Municipal Comm.    │        │ Municipal Corporators        │
│ (Ward A through Ward T)      │        │ (Govt. of Maharashtra / BMC) │
└──────────────┬───────────────┘        └──────────────────────────────┘
               │
               ▼
┌────────────────────────────────────────────────────────────────────────┐
│             168 DEPARTMENTAL OFFICERS (24 Wards x 7 Depts)             │
│                                                                        │
│ • 1 Nodal Departmental Officer per MCGM department in every ward       │
└──────────────────────────────┬─────────────────────────────────────────┘
                               │
                               ▼
┌────────────────────────────────────────────────────────────────────────┐
│         840 ON-FIELD ENGINEERS (24 Wards x 7 Depts x 5 Engineers)      │
│                                                                        │
│ • 5 dedicated field inspection & repair engineers under each           │
│   department in every ward (35 engineers per ward)                     │
└────────────────────────────────────────────────────────────────────────┘
```

### Numerical Breakdown by Role:

| # | Role Tier | Calculation | Count | Password | Description |
| :-: | :--- | :---: | :---: | :---: | :--- |
| **1** | **Admin** | 1 | **1** | `mum_admin` | Dr. Bhushan Gagrani, IAS (Municipal Commissioner) |
| **2** | **Ward Officers** | 24 wards $\times 1$ | **24** | `mum_wardoff` | Assistant Municipal Commissioners (AMCs) |
| **3** | **Ward Nagarsevaks** | 24 wards $\times 1$ | **24** | `mum_nagarsevak` | Elected Corporators (Govt of Maharashtra) |
| **4** | **Departmental Officers** | 24 wards $\times 7$ depts | **168** | `mum_dept` | 1 Departmental Officer per department per ward |
| **5** | **Field Engineers** | 24 wards $\times 7$ depts $\times 5$ | **840** | `mum_engg` | 5 Field Engineers per department per ward |
| | **Total Active Roster** | | **1,057** | | **100% Unique UIDs, Zero duplicates** |

---

## 3. Table Schema & Column Specifications

Only the 7 essential columns are retained across all formats:

| Column Name | Data Type | Required? | Description | Example Values |
| :--- | :---: | :---: | :--- | :--- |
| `No.` | Integer | Yes | Row index (1 to 1057) | `1`, `2`, `50`, `218` |
| `UID` | String (10) | Yes | Strictly 10-character unique municipal officer ID | `MUMHQ00001`, `MUMA001001`, `MUMFN06010` |
| `Ward` | String | Yes | Administrative ward code | `All Wards (HQ)`, `A`, `B`, `F/North`, `G/South`, `T` |
| `Name` | String | Yes | Full name of the officer/engineer/corporator | `Dr. Bhushan Gagrani, IAS`, `Er. Hemant Suryavanshi` |
| `Designation` | String | Yes | Official civic post or technical rank | `Assistant Municipal Commissioner (Ward Officer)`, `Field Engineer (Roads & Pavements)` |
| `Department` | String | Conditional | MCGM technical department (blank for Nagarsevaks, Ward Officers, Admin) | `BMC Roads Department`, `BMC Hydraulic Engineer's Department`, `""` |
| `Password` | String | Yes | Role-based password for testing and authentication | `mum_admin`, `mum_wardoff`, `mum_nagarsevak`, `mum_dept`, `mum_engg` |

---

## 4. 10-Character UID Specification

Every officer has a unique, deterministic, strictly 10-character UID:

$$\text{UID} = \mathbf{MUM} + \{\text{Ward Code: 2 chars}\} + \{\text{Serial: 5 digits}\}$$

### A. Ward Code (2 Characters)
* **Directional Wards** (Ward initial + Direction):
  * `F/North` $\rightarrow$ `FN` | `F/South` $\rightarrow$ `FS`
  * `G/North` $\rightarrow$ `GN` | `G/South` $\rightarrow$ `GS`
  * `H/East` $\rightarrow$ `HE` | `H/West` $\rightarrow$ `HW`
  * `K/East` $\rightarrow$ `KE` | `K/West` $\rightarrow$ `KW`
  * `M/East` $\rightarrow$ `ME` | `M/West` $\rightarrow$ `MW`
  * `P/North` $\rightarrow$ `PN` | `P/South` $\rightarrow$ `PS`
  * `R/Central` $\rightarrow$ `RC` | `R/North` $\rightarrow$ `RN` | `R/South` $\rightarrow$ `RS`
* **Non-Directional Wards** (Ward letter + `0`):
  * `A` $\rightarrow$ `A0` | `B` $\rightarrow$ `B0` | `C` $\rightarrow$ `C0` | `D` $\rightarrow$ `D0` | `E` $\rightarrow$ `E0`
  * `L` $\rightarrow$ `L0` | `N` $\rightarrow$ `N0` | `S` $\rightarrow$ `S0` | `T` $\rightarrow$ `T0`
* **Headquarters (Admin)**: `HQ`

### B. 5-Digit Serial Mapping per Ward
* `001`: Ward Officer (AMC)
* `002`: Ward Nagarsevak (Corporator)
* `003` to `009`: 7 Departmental Officers (1 per department)
* `010` to `044`: 35 Field Engineers (5 per department $\times 7$ departments)

*Examples:*
* `MUMHQ00001`: Municipal Commissioner (Admin)
* `MUMA001001`: Ward A Ward Officer
* `MUMA001002`: Ward A Nagarsevak
* `MUMA001003`: Ward A Dept Officer (Mechanical & Electrical)
* `MUMA001010`: Ward A Field Engineer 1 (Mechanical & Electrical)
* `MUMT024044`: Ward T Field Engineer 5 (Sewerage Networks)

---

## 5. The 7 MCGM Technical Departments

1. **BMC Mechanical & Electrical Department**
2. **BMC Roads Department**
3. **BMC Solid Waste Management Department**
4. **BMC Storm Water Drains Department (SWD)**
5. **BMC Hydraulic Engineer's Department**
6. **BMC Gardens Department**
7. **BMC Sewerage Operations Department**

---

## 6. The 24 Administrative Wards (Mumbai)

* `A`: Fort / Colaba
* `B`: Dongri / Mandvi
* `C`: Marine Lines
* `D`: Grant Road
* `E`: Byculla
* `F/North`: Parel
* `F/South`: Matunga East / Kings Circle
* `G/North`: Lower Parel / Prabhadevi
* `G/South`: Dadar West
* `H/East`: Santacruz East
* `H/West`: Bandra West
* `K/East`: Andheri East
* `K/West`: Andheri West
* `L`: Kurla
* `M/East`: Govandi
* `M/West`: Chembur West
* `N`: Ghatkopar
* `P/North`: Goregaon
* `P/South`: Malad
* `R/Central`: Kandivali
* `R/North`: Borivali
* `R/South`: Borivali / Dahisar
* `S`: Bhandup / Vikhroli
* `T`: Mulund

---

## 7. Sample Excerpt from the 1,057-Row Dataset

| No. | UID | Ward | Name | Designation | Department | Password |
| :-: | :---: | :---: | :--- | :--- | :--- | :---: |
| 1 | `MUMHQ00001` | All Wards (HQ) | Dr. Bhushan Gagrani, IAS | Municipal Commissioner & Administrator | | `mum_admin` |
| 2 | `MUMA001001` | A | Santoshkumar Dhonde | Assistant Municipal Commissioner (Ward Officer) | | `mum_wardoff` |
| 26 | `MUMA001002` | A | Makarand Narwekar | Municipal Corporator (Nagarsevak) | | `mum_nagarsevak` |
| 50 | `MUMA001003` | A | Eknath Mhatre | Departmental Officer (Mechanical & Electrical) | BMC Mechanical & Electrical Department | `mum_dept` |
| 51 | `MUMA001004` | A | Satish Koli | Departmental Officer (Roads & Infrastructure) | BMC Roads Department | `mum_dept` |
| 218 | `MUMA001010` | A | Er. Hemant Suryavanshi | Field Engineer (Mechanical & Electrical) | BMC Mechanical & Electrical Department | `mum_engg` |
| 219 | `MUMA001011` | A | Er. Nitin Bhalerao | Field Engineer (Mechanical & Electrical) | BMC Mechanical & Electrical Department | `mum_engg` |
| 1057 | `MUMT024044` | T | Er. Kishor Salvi | Field Engineer (Sewerage Networks) | BMC Sewerage Operations Department | `mum_engg` |
