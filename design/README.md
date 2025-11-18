# HL7 FHIR Patient Registration System - Design Documentation

## Overview

This directory contains the complete design for an **HL7 FHIR R4-compliant patient registration system** for ChinoRehabV1 rehabilitation clinic management application.

**Design Date:** November 18, 2025
**Version:** 1.0
**Status:** Design Only (Not Implemented)

---

## 📁 Design Files

### 1. **DESIGN_HL7_PATIENT_REGISTRATION.md**
**Location:** `/DESIGN_HL7_PATIENT_REGISTRATION.md`

Complete design specification document covering:
- Database schema design (HL7 FHIR-compliant)
- EJS view structure and wireframes
- JavaScript functionality design
- API endpoint specifications
- Data flow diagrams
- HL7 FHIR compliance checklist
- Security considerations
- Migration strategy
- Future enhancements

**Key Highlights:**
- ✅ HL7 FHIR R4 compliant
- ✅ ISO standards (8601, 639-1, 3166-1)
- ✅ Interoperability-ready
- ✅ Comprehensive patient data model

### 2. **hl7_patient_registration_schema.sql**
**Location:** `/design/hl7_patient_registration_schema.sql`

Complete SQL database schema including:

#### Main Tables:
- `hl7_patients` - Main patient table (FHIR Patient Resource)
- `hl7_patient_identifiers` - Multiple identifiers per patient
- `hl7_patient_communications` - Language preferences
- `hl7_patient_contacts` - Emergency contacts and next-of-kin

#### Features:
- **FHIR Metadata:** Resource versioning, timestamps
- **Identifiers:** HN, PT Number, National ID, Passport, SSN
- **Demographics:** Gender, birth date, deceased status, marital status
- **Contact Points:** Phone, mobile, email, fax
- **Address:** Structured address following FHIR Address format
- **Clinical Data:** Diagnosis, medical history, allergies, medications
- **Rehabilitation:** Goals, body area, frequency, duration, precautions
- **Audit Triggers:** Auto-logging of all changes
- **Indexes:** Optimized for performance

#### Standards Compliance:
- HL7 FHIR R4 Patient Resource
- ISO 8601 (dates and timestamps)
- ISO 639-1 (language codes)
- ISO 3166-1 (country codes)
- E.164 (phone numbers)
- RFC 5322 (email addresses)

### 3. **hl7-patient-register.ejs.design**
**Location:** `/design/hl7-patient-register.ejs.design`

Complete EJS template design for patient registration form.

#### Form Sections:

**Section 1: Patient Identifiers**
- FHIR Resource ID (UUID v4, auto-generated)
- Hospital Number (HN)
- PT Number
- National ID / Thai ID
- Passport Number
- SSN / Other ID

**Section 2: Name (FHIR HumanName)**
- Name Use (official, usual, temp, nickname)
- Prefix/Title
- Given Name (First Name)
- Middle Name
- Family Name (Last Name)
- Suffix
- Full Name Display (auto-generated)

**Section 3: Demographics**
- Date of Birth (ISO 8601)
- Gender (male, female, other, unknown)
- Marital Status (HL7 v3 codes)
- Primary Language (ISO 639-1)
- Deceased Status
- Date/Time of Death

**Section 4: Contact Information (FHIR ContactPoint)**
- Phone (Home/Work)
- Mobile Phone
- Email
- Fax
- Contact Use

**Section 5: Address (FHIR Address)**
- Address Use & Type
- Street Address Lines 1-2
- City, District, State
- Postal Code
- Country (ISO 3166-1)
- Full Address Display (auto-generated)

**Section 6: Emergency Contact**
- Contact Name
- Relationship to Patient
- Contact Phone & Email
- Contact Address

**Section 7: Clinical Information**
- Primary Diagnosis
- Medical History
- Known Allergies
- Current Medications

**Section 8: Rehabilitation Plan**
- Rehabilitation Goals (checkboxes + custom)
- Body Area Affected
- Treatment Frequency
- Expected Duration
- Precautions
- Contraindications
- Doctor's Notes

**Section 9: Managing Organization**
- Clinic Selection (FHIR Organization reference)

#### UI/UX Features:
- Bootstrap 5 responsive design
- Collapsible sections
- Real-time validation
- Auto-fill computed fields
- Date pickers (Flatpickr)
- Accessibility (WCAG 2.1)
- Mobile-friendly

### 4. **hl7-patient-register.js.design**
**Location:** `/design/hl7-patient-register.js.design`

Complete JavaScript implementation design.

#### Main Functions:

**Initialization:**
- `initializeDatePickers()` - Setup Flatpickr date pickers
- `generateFHIRId()` - Generate UUID v4 for FHIR ID
- `generatePatientNumbers()` - Get next HN and PT numbers from API
- `loadClinics()` - Load clinic dropdown
- `setupFormValidation()` - Setup validation rules
- `setupEventListeners()` - Bind event handlers
- `setupAutoFillFields()` - Auto-compute display fields

**Validation:**
- `validateForm()` - Complete form validation
- `validateThaiNationalID(id)` - Thai ID checksum validation
- `validateEmail(email)` - Email format validation (RFC 5322)
- HTML5 constraint validation

**FHIR Payload Builder:**
- `buildFHIRPayload()` - Construct HL7 FHIR Patient Resource
  - Identifiers (MR, PT, NI, PPN, SS)
  - HumanName structure
  - ContactPoint array
  - Address structure
  - MaritalStatus CodeableConcept
  - Communication preferences
  - Contact persons
  - Managing Organization reference
  - Custom extensions for rehab data

**Form Submission:**
- `handleFormSubmit(event)` - Submit FHIR payload to API
  - Validation
  - Payload construction
  - API call with FHIR content type
  - Success/error handling
  - Redirect to patient detail

**Utility Functions:**
- `clearForm()` - Reset form
- `showAlert(message, type)` - Display alerts
- `getCookie(name)` - Get auth token
- `formatDateISO(date)` - ISO 8601 date formatting
- `escapeHtml(text)` - XSS prevention

---

## 🔄 Implementation Workflow

When you're ready to implement this design, follow these steps:

### Step 1: Database Setup
```bash
# Run the SQL schema
mysql -u username -p database_name < design/hl7_patient_registration_schema.sql
```

### Step 2: Backend API
Create API endpoints:
- `POST /api/hl7/patients` - Create patient
- `GET /api/hl7/patients/:id` - Get patient by FHIR ID
- `PUT /api/hl7/patients/:id` - Update patient
- `GET /api/hl7/patients/next-numbers` - Generate HN/PT numbers

### Step 3: Frontend Files
Copy design files to production locations:
```bash
# EJS template
cp design/hl7-patient-register.ejs.design views/hl7-patient-register.ejs

# JavaScript
cp design/hl7-patient-register.js.design public/js/hl7-patient-register.js
```

### Step 4: Routing
Add route in your Express app:
```javascript
app.get('/hl7/patient/register', (req, res) => {
  res.render('hl7-patient-register', { user: req.user });
});
```

### Step 5: Testing
- Unit tests for validation functions
- Integration tests for API endpoints
- FHIR validation against official schemas
- User acceptance testing (UAT)

---

## 📊 HL7 FHIR Compliance

This design follows **HL7 FHIR R4** specification for Patient Resource:
- [FHIR Patient Resource](https://www.hl7.org/fhir/patient.html)

### Resource Elements Implemented:
✅ resourceType, id, identifier, name, telecom, gender, birthDate
✅ deceased[x], address, maritalStatus, contact, communication
✅ managingOrganization, active, meta (versioning)

### Code Systems Used:
- **Gender:** http://hl7.org/fhir/administrative-gender
- **Marital Status:** http://terminology.hl7.org/CodeSystem/v3-MaritalStatus
- **Contact Relationship:** http://terminology.hl7.org/CodeSystem/v2-0131

### Extensions:
Custom extensions for rehabilitation-specific data:
- Primary diagnosis
- Medical history
- Allergies & medications
- Rehab goals, body area, frequency, duration
- Precautions & contraindications
- Doctor notes

---

## 🔒 Security Features

- **Input Validation:** Client-side and server-side
- **SQL Injection Prevention:** Parameterized queries
- **XSS Protection:** HTML escaping
- **CSRF Protection:** Token validation
- **Authentication:** Bearer token (JWT)
- **Authorization:** Role-based access control
- **Audit Logging:** All CREATE/UPDATE operations
- **Data Encryption:** For PII/PHI fields (recommended)
- **HTTPS Only:** Secure data transmission

---

## 🌐 Interoperability

This design enables:
- ✅ Export patient data as FHIR JSON
- ✅ Import from other FHIR-compliant systems
- ✅ Integration with EHR/EMR systems
- ✅ HL7 v2 message conversion (ADT^A01, etc.)
- ✅ SMART on FHIR apps integration
- ✅ Bulk data export (FHIR Bulk Data Access)

---

## 📈 Benefits

### For Healthcare Providers:
- Standard-compliant patient records
- Easy data exchange with other systems
- Future-proof interoperability
- Reduced data migration costs

### For Developers:
- Well-documented FHIR resources
- Standard validation rules
- Extensive code examples
- Clear API contracts

### For Patients:
- Portable health records
- Better care coordination
- Access to patient portals
- SMART apps compatibility

---

## 🚀 Next Steps

1. **Review** all design documents
2. **Approve** the design with stakeholders
3. **Implement** backend API endpoints
4. **Deploy** database schema
5. **Integrate** frontend templates
6. **Test** thoroughly
7. **Launch** to production

---

## 📞 Support

For questions about this design:
- Review the main design document: `DESIGN_HL7_PATIENT_REGISTRATION.md`
- Check HL7 FHIR documentation: https://www.hl7.org/fhir/
- Consult implementation guides

---

## 📝 Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | 2025-11-18 | Initial design release |

---

## 📄 License

This design is part of the ChinoRehabV1 project.

---

**End of Design Documentation**
