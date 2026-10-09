# CivicFix Canonical Multilingual Glossary & Terminology Dictionary

This document serves as the **authoritative single source of truth** for all canonical backend tokens and their standard localized representations across **English**, **Hindi (हिन्दी)**, and **Marathi (मराठी)** in CivicFix.

---

## Hard Architectural Invariants

1. **Strict Canonical Invariance**: All backend fields in Firestore, Hive boxes, Supabase rows, and REST payload schemas MUST store only the **Canonical Backend Token** (ASCII strings/enums).
2. **Zero Storage of Localized Strings**: Never write Hindi or Marathi display labels to database fields.
3. **Immutability of Citizen & Officer Content**: User-generated content (complaint titles, citizen descriptions, officer remarks, field notes, instructions) is authoritative and immutable. No machine translation is applied.
4. **Boundary Presentation**: Translations occur exclusively at the UI boundary via `canonical_display_mappers.dart` backed by the Flutter ARB localization catalog.

---

## 1. Complaint Statuses (`ComplaintStatus`)

| Canonical Backend Token | English (`en`) | Hindi (`hi`) | Marathi (`mr`) |
|---|---|---|---|
| `underVerification` | Under Verification | सत्यापन प्रक्रिया में | पडताळणी अंतर्गत |
| `reported` | Reported | दर्ज की गई | नोंदवली |
| `verified` | Verified | सत्यापित | पडताळणी पूर्ण |
| `assigned` | Assigned | आवंटित | नियुक्त |
| `inProgress` | Work In Progress | कार्य प्रगति पर है | काम प्रगतीपथावर |
| `resolved` | Resolved | समाधान हुआ | निवारण झाले |
| `closed` | Closed | बंद | बंद |
| `rejected` | Rejected | अस्वीकृत | नाकारली |
| `reopened` / `rework` | Rework / In Progress | पुनः कार्य / प्रगति पर | पुन्हा काम / प्रगतीपथावर |

---

## 2. Complaint Priorities (`ComplaintPriority`)

| Canonical Backend Token | English (`en`) | Hindi (`hi`) | Marathi (`mr`) |
|---|---|---|---|
| `low` | Low Priority | कम प्राथमिकता | कमी प्राधान्य |
| `medium` | Medium Priority | मध्यम प्राथमिकता | मध्यम प्राधान्य |
| `high` | High Priority | उच्च प्राथमिकता | उच्च प्राधान्य |
| `emergency` / `critical` | Emergency Hazard / Critical | आपातकालीन खतरा / अतिमहत्त्वपूर्ण | तातडीचा धोका / अतिमहत्त्वाचे |

---

## 3. Civic Categories (`CivicCategory`)

| Canonical Backend Token | English (`en`) | Hindi (`hi`) | Marathi (`mr`) |
|---|---|---|---|
| `roads` | Roads | सड़कें | रस्ते |
| `potholes` | Potholes | गड्ढे | खड्डे |
| `water` | Water | जल आपूर्ति | पाणी पुरवठा |
| `water_leakage` | Water Leakage | पानी का रिसाव | पाण्याची गळती |
| `damaged_water` | Damaged Water Infrastructure | क्षतिग्रस्त जल संरचना | नादुरुस्त पाणी पायाभूत सुविधा |
| `waterlogging` | Waterlogging | जलभराव | पाणी साचणे |
| `sanitation` | Sanitation | स्वच्छता | स्वच्छता |
| `waste` / `garbage` | Waste Management | कचरा प्रबंधन | कचरा व्यवस्थापन |
| `garbage_overflow` | Garbage Overflow | कचरा ओवरफ्लो | कचऱ्याचे ढीग |
| `streetlights` | Street Lights | स्ट्रीट लाइट | पथदिवे |
| `drainage` | Drainage | जल निकासी | सांडपाणी निचरा |
| `sewage_overflow` | Sewage Overflow | सीवेज ओवरफ्लो | सांडपाणी तुंबणे |
| `manholes` | Open Manholes | खुले मैनहोल | उघडी मॅनहोल्स |
| `infrastructure` | Public Infrastructure | सार्वजनिक बुनियादी ढांचा | सार्वजनिक पायाभूत सुविधा |
| `footpaths` | Damaged Footpaths | क्षतिग्रस्त फुटपाथ | नादुरुस्त पदपथ |
| `traffic` | Traffic / Road Safety | यातायात / सड़क सुरक्षा | वाहतूक / रस्ता सुरक्षा |
| `trees` | Fallen / Dangerous Trees | गिरे / खतरनाक पेड़ | पडलेली / धोकादायक झाडे |
| `other` | Other Issues | अन्य समस्याएं | इतर समस्या |

---

## 4. BMC Municipal Technical Departments (`CivicDepartment` - 18 Departments)

| Canonical Department Code | English (`en`) | Hindi (`hi`) | Marathi (`mr`) |
|---|---|---|---|
| `roads_maintenance` / `rds` | Roads & Maintenance | सड़क एवं अनुरक्षण विभाग | रस्ते व परिरक्षण विभाग |
| `roads_traffic` | Roads & Traffic Department | सड़क एवं यातायात विभाग | रस्ते व वाहतूक विभाग |
| `water_works` / `ww` | Water Works & Supply | जल कार्य एवं आपूर्ति विभाग | जलकामे व पाणीपुरवठा विभाग |
| `solid_waste_management` / `swm` | Solid Waste Management | ठोस अपशिष्ट प्रबंधन विभाग | घनकचरा व्यवस्थापन विभाग |
| `building_factory` / `bf` | Building & Factory | भवन एवं कारखाना विभाग | इमारत व कारखाना विभाग |
| `gardens_trees` / `gdn` | Gardens & Trees | उद्यान एवं वृक्ष प्राधिकरण | उद्याने व वृक्ष प्राधिकरण |
| `public_health` / `ph` | Public Health Department | जनस्वास्थ्य विभाग | सार्वजनिक आरोग्य विभाग |
| `pest_control_insecticide` / `pci` | Pest Control & Insecticide | कीटनाशक एवं कीट नियंत्रण विभाग | कीटक नियंत्रण व कीटकनाशक विभाग |
| `encroachment_removal` / `enc` | Encroachment Removal | अतिक्रमण निष्कासन विभाग | अतिक्रमण निर्मूलन विभाग |
| `licence_department` / `lic` | Licence Department | अनुज्ञप्ति (लाइसेंस) विभाग | अनुज्ञाप्ती (परवाना) विभाग |
| `shops_establishments` / `se` | Shops & Establishments | दुकाने एवं प्रतिष्ठान विभाग | दुकाने व आस्थापना विभाग |
| `assessment_collection` / `ac` | Assessment & Collection | कर निर्धारण एवं संकलन विभाग | कर निर्धारण व संकलन विभाग |
| `estate_department` / `est` | Estate Department | संपदा विभाग | मालमत्ता विभाग |
| `colony_slum_improvement` / `csi` | Colony & Slum Improvement | बस्ती एवं झोपड़पट्टी सुधार विभाग | वसाहत व झोपडपट्टी सुधार विभाग |
| `education_schools` / `edu` | Education & Municipal Schools | शिक्षा एवं मनपा विद्यालय विभाग | शिक्षण व मनपा शाळा विभाग |
| `security_force` / `sec` | Security Force | सुरक्षा बल विभाग | सुरक्षा दल विभाग |
| `legal_department` / `leg` | Legal Department | विधि (कानूनी) विभाग | विधी (कायदा) विभाग |
| `administration_establishment` / `adm` | Administration & Establishment | प्रशासन एवं स्थापना विभाग | प्रशासन व आस्थापना विभाग |
| `town_planning` / `tp` | Town Planning & Development Plan | नगर नियोजन एवं विकास योजना | नगररचना व विकास नियोजन विभाग |
| `electrical_streetlights` | Electrical & Street Lighting | विद्युत एवं पथ प्रकाश विभाग | विद्युत व पथदिवे विभाग |
| `storm_drainage` | Storm Water Drainage | वर्षा जल निकासी विभाग | पर्जन्य जलवाहिन्या विभाग |
| `building_infrastructure` | Building & Infrastructure | भवन एवं अवसंरचना विभाग | इमारत व पायाभूत सुविधा विभाग |
| `general_municipal_desk` / `general` | General Municipal Desk | सामान्य नगरपालिका सहायता केंद्र | सामान्य पालिका नियंत्रण कक्ष |

---

## 5. Hierarchical Government Roles (`GovernmentRole`)

| Canonical Role ID | English (`en`) | Hindi (`hi`) | Marathi (`mr`) |
|---|---|---|---|
| `government_super_admin` | Municipal Commissioner / Super Admin | नगर आयुक्त / मुख्य प्रशासक | महानगरपालिका आयुक्त / मुख्य प्रशासक |
| `zonal_dmc` | Zonal Deputy Municipal Commissioner | क्षेत्रीय उप नगर आयुक्त (डीएमसी) | परिमंडळीय उपायुक्त |
| `central_department_hod` | Central Department Head of Department | केंद्रीय विभागाध्यक्ष (एचओडी) | मध्यवर्ती विभागप्रमुख |
| `ward_officer` | Assistant Municipal Commissioner (Ward Officer) | सहायक नगर आयुक्त (वार्ड अधिकारी) | सहाय्यक आयुक्त (प्रभाग अधिकारी) |
| `ward_department_lead` | Ward Department Lead | वार्ड विभागीय प्रमुख | प्रभाग विभाग प्रमुख |
| `department_crew` | Field Execution Officer / Junior Engineer | फील्ड निष्पादन अधिकारी / कनिष्ठ अभियंता | क्षेत्रीय अंमलबजावणी अधिकारी / कनिष्ठ अभियंता |
| `assistant_engineer` | Assistant Engineer | सहायक अभियंता | सहाय्यक अभियंता |
| `executive_engineer` | Executive Engineer | अधिशासी अभियंता | कार्यकारी अभियंता |
| `sub_engineer` | Sub-Engineer | उप-अभियंता | उप अभियंता |
| `medical_officer` | Medical Officer of Health | स्वास्थ्य चिकित्सा अधिकारी | आरोग्य वैद्यकीय अधिकारी |
| `superintendent` | Assistant Superintendent | सहायक अधीक्षक | सहाय्यक अधीक्षक |

---

## 6. Verification States

| Canonical Verification Token | English (`en`) | Hindi (`hi`) | Marathi (`mr`) |
|---|---|---|---|
| `pending` | Verification Pending | सत्यापन लंबित | पडताळणी प्रलंबित |
| `processing` | Analyzing & Verifying... | विश्लेषण एवं सत्यापन जारी... | विश्लेषण आणि पडताळणी सुरू... |
| `passed` / `evidence_verified` | Verification Passed | सत्यापन सफल | पडताळणी यशस्वी |
| `failed` | Verification Failed | सत्यापन विफल | पडताळणी अयशस्वी |
| `temporarily_unavailable` / `delayed` | Automated Verification Delayed | स्वचालित सत्यापन विलंबित | स्वयंचलित पडताळणीस विलंब |
| `human_department_review` | Department Officer Review | विभागीय अधिकारी समीक्षा | विभागीय अधिकारी पुनरावलोकन |
| `verification_completed` | Verification Completed | सत्यापन पूर्ण | पडताळणी पूर्ण |
| `low_confidence` | Low Verification Confidence | कम सत्यापन विश्वास | कमी पडताळणी विश्वास |
| `manual_override` | Manual Verification Override | मैन्युअल सत्यापन ओवरराइड | मॅन्युअल पडताळणी ओव्हरराइड |

---

## 7. Routing States & Routing Ticket Statuses

| Canonical Routing Token | English (`en`) | Hindi (`hi`) | Marathi (`mr`) |
|---|---|---|---|
| `unassigned` | Unassigned | अनियुक्त | नियुक्त नाही |
| `assigned` | Assigned | आवंटित | नियुक्त |
| `reassignmentRequested` | Reassignment Requested | पुनर्आवंटन अनुरोधित | पुनर्नियुक्तीची विनंती |
| `transferred` | Transferred | स्थानांतरित | वर्ग केले |
| `inProgress` | In Progress | प्रगति पर | प्रगतीपथावर |
| `resolved` | Resolved | समाधानित | निवारण झाले |
| `pending` (RoutingTicket) | Pending Ward Officer Review | वार्ड अधिकारी समीक्षा लंबित | प्रभाग अधिकारी पुनरावलोकन प्रलंबित |
| `approved` (RoutingTicket) | Reassignment Approved | पुनर्आवंटन स्वीकृत | पुनर्नियुक्ती मंजूर |
| `rejected` (RoutingTicket) | Reassignment Rejected | पुनर्आवंटन अस्वीकृत | पुनर्नियुक्ती नाकारली |
| `cancelled` (RoutingTicket) | Ticket Cancelled | टिकट रद्द | तक्रार रद्द |

---

## 8. Assignment States

| Canonical Assignment Token | English (`en`) | Hindi (`hi`) | Marathi (`mr`) |
|---|---|---|---|
| `unassigned` | Unassigned | अनियुक्त | नियुक्त नाही |
| `leadAssigned` | Assigned to Ward Lead | वार्ड प्रमुख को आवंटित | प्रभाग प्रमुखांना नियुक्त |
| `crewAssigned` | Assigned to Ground Crew | फील्ड टीम को आवंटित | क्षेत्रीय पथकाला नियुक्त |
| `fieldOfficerAssigned` | Assigned to Field Officer | फील्ड अधिकारी को आवंटित | क्षेत्रीय अधिकाऱ्यांना नियुक्त |

---

## 9. Field Execution States

| Canonical Execution Token | English (`en`) | Hindi (`hi`) | Marathi (`mr`) |
|---|---|---|---|
| `not_started` / `readyToStart` | Ready to Start | प्रारंभ के लिए तैयार | सुरू करण्यास तयार |
| `in_progress` / `commenced` | Execution In Progress | कार्य प्रगति पर है | काम प्रगतीपथावर आहे |
| `blocked` / `on_hold` | Execution Blocked | कार्य रुका हुआ है | काम थांबलेले आहे |
| `awaiting_evidence` | Awaiting Ground Evidence | जमीनी साक्ष्य की प्रतीक्षा | घटनास्थळावरील पुराव्याची प्रतीक्षा |
| `completed` / `work_completed` | Work Completed | कार्य पूर्ण हुआ | काम पूर्ण झाले |

---

## 10. Resolution States

| Canonical Resolution Token | English (`en`) | Hindi (`hi`) | Marathi (`mr`) |
|---|---|---|---|
| `resolution_pending` / `pending` | Resolution Pending | समाधान लंबित | निवारण प्रलंबित |
| `resolution_submitted` / `submitted` | Resolution Submitted | समाधान प्रस्तुत | निवारण सादर केले |
| `resolution_approved` / `approved` | Resolution Approved | समाधान स्वीकृत | निवारण मंजूर |
| `resolution_rejected` / `rejected` | Resolution Rejected | समाधान अस्वीकृत | निवारण नाकारले |
| `resolution_closed` / `closed` | Resolution Closed | समाधान बंद | निवारण बंद |

---

## 11. Supervisory Quality Rework States

| Canonical Rework Token | English (`en`) | Hindi (`hi`) | Marathi (`mr`) |
|---|---|---|---|
| `rework_not_required` / `none` | No Rework Required | पुनः कार्य की आवश्यकता नहीं | पुन्हा कामाची गरज नाही |
| `rework_required` / `required` | Rework Required | पुनः कार्य आवश्यक | पुन्हा काम आवश्यक |
| `rework_in_progress` | Rework In Progress | पुनः कार्य प्रगति पर है | पुन्हा काम प्रगतीपथावर |
| `rework_submitted` | Rework Submitted | पुनः कार्य प्रस्तुत | पुन्हा काम सादर केले |
| `rework_approved` | Rework Approved | पुनः कार्य स्वीकृत | पुन्हा काम मंजूर |

---

## 12. Synchronization States (`SyncStatus`)

| Canonical Sync Token | English (`en`) | Hindi (`hi`) | Marathi (`mr`) |
|---|---|---|---|
| `synced` | Synced | सिंक हुआ | सिंक झाले |
| `pending` | Pending Sync | सिंक लंबित | सिंक प्रलंबित |
| `syncing` | Syncing... | सिंक हो रहा है... | सिंक होत आहे... |
| `failed` | Sync Failed | सिंक विफल | सिंक अयशस्वी |
| `offline` | Offline Queue | ऑफ़लाइन कतार | ऑफलाइन रांग |
| `retrying` | Retrying Sync... | सिंक का पुनः प्रयास... | सिंकचा पुन्हा प्रयत्न... |

---

## 13. Notification Types (`NotificationType`)

| Canonical Notification Token | English (`en`) | Hindi (`hi`) | Marathi (`mr`) |
|---|---|---|---|
| `complaintSubmitted` | Complaint Submitted | शिकायत दर्ज की गई | तक्रार नोंदवली |
| `complaintVerified` | Complaint Verified | शिकायत सत्यापित हुई | तक्रार पडताळली गेली |
| `complaintAssigned` | Complaint Assigned | शिकायत आवंटित हुई | तक्रार नियुक्त केली |
| `complaintStatusChanged` | Status Updated | स्थिति अद्यतन | स्थिती अद्यतन |
| `complaintResolved` | Complaint Resolved | शिकायत का समाधान हुआ | तक्रारीचे निवारण झाले |
| `generalCivic` | Civic Announcement | नागरिक सूचना | नागरी सूचना |
| `hazardAlert` | Hazard Warning | खतरा चेतावनी | धोक्याचा इशारा |
| `rewardEarned` | Reward Earned | पुरस्कार प्राप्त हुआ | बक्षीस मिळाले |
| `slaWarning` | SLA Deadline Warning | एसएलए समयसीमा चेतावनी | एसएलए मुदत इशारा |
| `reworkRequested` | Rework Requested | पुनः कार्य अनुरोधित | पुन्हा काम करण्याची विनंती |

---

## 14. Gamification, Achievements & Civic Levels

| Canonical Badge / Level Token | English (`en`) | Hindi (`hi`) | Marathi (`mr`) |
|---|---|---|---|
| `first_report` / `ach_1` | First Report | पहली रिपोर्ट | पहिली नोंदणी |
| `active_citizen` / `ach_4` | Active Citizen | सक्रिय नागरिक | सक्रिय नागरिक |
| `neighborhood_hero` / `ach_2` | Neighborhood Hero | मोहल्ला नायक | वस्ती रक्षक |
| `sharp_eye` | Sharp Eye | पैनी नजर | सजग नागरिक |
| `community_pillar` / `ach_3` | Community Pillar | समाज का स्तंभ | समाजाचा आधारस्तंभ |
| `ground_reporter` | Ground Reporter | ग्राउंड रिपोर्टर | ग्राउंड रिपोर्टर |
| `community_voice` | Community Voice | सामुदायिक आवाज़ | सामुदायिक आवाज |
| `resolution_champion` | Resolution Champion | समाधान चैंपियन | निवारण चॅम्पियन |
| `level_1` / `starter` | Civic Starter | नागरिक शुरुआत | नागरी नवशिक्या |
| `level_2` / `contributor` | Civic Contributor | नागरिक योगदानकर्ता | नागरी योगदानकर्ता |
| `level_3` / `champion` | Civic Champion | नागरिक चैंपियन | नागरी चॅम्पियन |
| `level_4` / `leader` | Civic Leader | नागरिक अगुआ | नागरी मार्गदर्शक |
| `level_5` / `hero` | Civic Hero | नागरिक नायक | नागरी नायक |

---

## 15. Basemap Modes (`BasemapMode`)

| Canonical Mode Token | English (`en`) | Hindi (`hi`) | Marathi (`mr`) |
|---|---|---|---|
| `streets` | Streets | सड़कें | रस्ते नकाशा |
| `satellite` | Satellite | उपग्रह | उपग्रह दृश्य |
| `hybrid` | Hybrid | हाइब्रिड | संमिश्र दृश्य |

---

## 16. Jurisdiction Types & Administrative Scopes

| Canonical Scope Token | English (`en`) | Hindi (`hi`) | Marathi (`mr`) |
|---|---|---|---|
| `citywide` | Citywide (All Zones & Wards) | संपूर्ण शहर (सभी जोन और वार्ड) | शहरव्यापी (सर्व परिमंडळे व प्रभाग) |
| `zone` | Zone Jurisdiction | ज़ोन क्षेत्राधिकार | परिमंडळ कार्यक्षेत्र |
| `ward` | Ward Jurisdiction | वार्ड क्षेत्राधिकार | प्रभाग कार्यक्षेत्र |
| `department` | Department Jurisdiction | विभाग क्षेत्राधिकार | विभाग कार्यक्षेत्र |
| `role` | Role Scope | पद कार्यक्षेत्र | पद कार्यक्षेत्र |

---

## 17. SLA Compliance States (`GovtSlaStatus`)

| Canonical SLA Token | English (`en`) | Hindi (`hi`) | Marathi (`mr`) |
|---|---|---|---|
| `healthy` / `within_sla` | Within SLA | एसएलए के अंतर्गत | एसएलए अंतर्गत |
| `warning` / `approaching` | Approaching SLA Deadline | एसएलए समयसीमा निकट | एसएलए मुदत जवळ येत आहे |
| `breached` / `overdue` | SLA Breached | एसएलए उल्लंघन | एसएलए मुदत संपली |
| `status_label` | SLA Compliance | एसएलए अनुपालन | एसएलए पूर्तता |
