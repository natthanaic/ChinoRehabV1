# HL7-Compliant Patient Registration System Design

## Overview
This document outlines the design for an HL7 FHIR-compliant patient registration system for the ChinoRehabV1 application.

---

## 1. Database Schema Design (SQL)

### 1.1 Main Patient Table (HL7 FHIR Patient Resource Compliant)

```sql
-- HL7 FHIR-compliant patient table
CREATE TABLE `hl7_patients` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,

  -- FHIR Resource Metadata
  `resource_type` VARCHAR(50) DEFAULT 'Patient' COMMENT 'FHIR resource type',
  `fhir_id` VARCHAR(100) UNIQUE COMMENT 'FHIR resource ID (UUID)',

  -- Identifiers (PID segment - HL7 v2 / FHIR Identifier)
  `hn` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Hospital Number (MRN)',
  `pt_number` VARCHAR(50) NOT NULL UNIQUE COMMENT 'PT Number',
  `national_id` VARCHAR(20) DEFAULT NULL COMMENT 'National ID / Thai ID (PID)',
  `passport_no` VARCHAR(50) DEFAULT NULL COMMENT 'Passport Number',
  `ssn` VARCHAR(20) DEFAULT NULL COMMENT 'Social Security Number',
  `identifier_system` VARCHAR(255) DEFAULT NULL COMMENT 'FHIR identifier system URI',

  -- Name (FHIR HumanName)
  `name_use` ENUM('official', 'usual', 'temp', 'nickname', 'anonymous', 'old', 'maiden') DEFAULT 'official',
  `name_prefix` VARCHAR(20) DEFAULT NULL COMMENT 'Title (Mr., Mrs., Dr.)',
  `name_given` VARCHAR(100) NOT NULL COMMENT 'Given name / First name',
  `name_family` VARCHAR(100) NOT NULL COMMENT 'Family name / Last name',
  `name_middle` VARCHAR(100) DEFAULT NULL COMMENT 'Middle name',
  `name_suffix` VARCHAR(50) DEFAULT NULL COMMENT 'Suffix (Jr., Sr., III)',
  `name_text` VARCHAR(255) DEFAULT NULL COMMENT 'Full name as text',

  -- Telecom (FHIR ContactPoint)
  `telecom_phone` VARCHAR(50) DEFAULT NULL,
  `telecom_mobile` VARCHAR(50) DEFAULT NULL,
  `telecom_email` VARCHAR(100) DEFAULT NULL,
  `telecom_fax` VARCHAR(50) DEFAULT NULL,
  `telecom_use` ENUM('home', 'work', 'temp', 'old', 'mobile') DEFAULT 'home',

  -- Demographics
  `gender` ENUM('male', 'female', 'other', 'unknown') DEFAULT NULL COMMENT 'Administrative gender (HL7 AdministrativeGender)',
  `birth_date` DATE NOT NULL COMMENT 'Date of birth (YYYY-MM-DD)',
  `deceased_boolean` TINYINT(1) DEFAULT 0 COMMENT 'Indicates if patient is deceased',
  `deceased_date_time` DATETIME DEFAULT NULL COMMENT 'Date and time of death',

  -- Address (FHIR Address)
  `address_use` ENUM('home', 'work', 'temp', 'old', 'billing') DEFAULT 'home',
  `address_type` ENUM('postal', 'physical', 'both') DEFAULT 'both',
  `address_line1` VARCHAR(255) DEFAULT NULL COMMENT 'Street address line 1',
  `address_line2` VARCHAR(255) DEFAULT NULL COMMENT 'Street address line 2',
  `address_city` VARCHAR(100) DEFAULT NULL,
  `address_district` VARCHAR(100) DEFAULT NULL COMMENT 'District/County',
  `address_state` VARCHAR(100) DEFAULT NULL COMMENT 'State/Province',
  `address_postal_code` VARCHAR(20) DEFAULT NULL,
  `address_country` VARCHAR(100) DEFAULT NULL COMMENT 'ISO 3166 country code',
  `address_text` TEXT DEFAULT NULL COMMENT 'Full address as text',

  -- Marital Status (FHIR CodeableConcept)
  `marital_status` ENUM('A', 'D', 'I', 'L', 'M', 'P', 'S', 'T', 'U', 'W') DEFAULT NULL COMMENT 'A=Annulled, D=Divorced, I=Interlocutory, L=Legally Separated, M=Married, P=Polygamous, S=Never Married, T=Domestic partner, U=unmarried, W=Widowed',

  -- Communication (FHIR Patient.communication)
  `language_primary` VARCHAR(10) DEFAULT NULL COMMENT 'ISO 639-1 language code (th, en, etc.)',
  `language_preferred` TINYINT(1) DEFAULT 0 COMMENT 'Preferred language indicator',

  -- Emergency Contact (FHIR Contact)
  `emergency_contact_name` VARCHAR(200) DEFAULT NULL,
  `emergency_contact_relationship` VARCHAR(100) DEFAULT NULL COMMENT 'Relationship to patient',
  `emergency_contact_phone` VARCHAR(50) DEFAULT NULL,
  `emergency_contact_email` VARCHAR(100) DEFAULT NULL,
  `emergency_contact_address` TEXT DEFAULT NULL,

  -- Clinical Information (Extensions)
  `primary_diagnosis` TEXT DEFAULT NULL COMMENT 'Primary diagnosis',
  `medical_history` TEXT DEFAULT NULL COMMENT 'Past medical history',
  `allergies` TEXT DEFAULT NULL COMMENT 'Known allergies',
  `medications` TEXT DEFAULT NULL COMMENT 'Current medications',

  -- Rehabilitation Plan (Custom Extension)
  `rehab_goals` TEXT DEFAULT NULL COMMENT 'JSON array of rehabilitation goals',
  `body_area` VARCHAR(200) DEFAULT NULL COMMENT 'Body area affected',
  `treatment_frequency` VARCHAR(100) DEFAULT NULL,
  `expected_duration` VARCHAR(100) DEFAULT NULL,
  `precautions` TEXT DEFAULT NULL,
  `contraindications` TEXT DEFAULT NULL,
  `doctor_notes` TEXT DEFAULT NULL,

  -- Organization Reference
  `managing_organization` INT(11) NOT NULL COMMENT 'Reference to clinic (Organization)',

  -- FHIR Metadata
  `active` TINYINT(1) DEFAULT 1 COMMENT 'Whether patient record is active',
  `meta_version_id` INT(11) DEFAULT 1 COMMENT 'Version number for resource',
  `meta_last_updated` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  -- Audit
  `created_by` INT(11) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_hn` (`hn`),
  UNIQUE KEY `uk_pt_number` (`pt_number`),
  UNIQUE KEY `uk_fhir_id` (`fhir_id`),
  KEY `idx_national_id` (`national_id`),
  KEY `idx_passport` (`passport_no`),
  KEY `idx_name` (`name_given`, `name_family`),
  KEY `idx_birth_date` (`birth_date`),
  KEY `idx_clinic` (`managing_organization`),
  CONSTRAINT `fk_hl7_patient_clinic` FOREIGN KEY (`managing_organization`) REFERENCES `clinics` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='HL7 FHIR-compliant patient records';
```

### 1.2 Patient Identifier History Table

```sql
-- Track multiple identifiers per patient (FHIR Identifier array)
CREATE TABLE `hl7_patient_identifiers` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `patient_id` INT(11) NOT NULL,
  `identifier_use` ENUM('usual', 'official', 'temp', 'secondary', 'old') DEFAULT 'usual',
  `identifier_type` VARCHAR(50) NOT NULL COMMENT 'MR, SS, DL, PPN, etc.',
  `identifier_system` VARCHAR(255) DEFAULT NULL COMMENT 'URI for identifier system',
  `identifier_value` VARCHAR(100) NOT NULL,
  `identifier_period_start` DATE DEFAULT NULL,
  `identifier_period_end` DATE DEFAULT NULL,
  `assigner_organization` VARCHAR(255) DEFAULT NULL,
  `active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_patient` (`patient_id`),
  KEY `idx_identifier` (`identifier_value`),
  CONSTRAINT `fk_identifier_patient` FOREIGN KEY (`patient_id`) REFERENCES `hl7_patients` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 1.3 Patient Communication Languages Table

```sql
-- Multiple languages per patient (FHIR Patient.communication)
CREATE TABLE `hl7_patient_communications` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `patient_id` INT(11) NOT NULL,
  `language_code` VARCHAR(10) NOT NULL COMMENT 'ISO 639-1 code',
  `language_display` VARCHAR(100) DEFAULT NULL COMMENT 'Language name',
  `preferred` TINYINT(1) DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_patient` (`patient_id`),
  CONSTRAINT `fk_comm_patient` FOREIGN KEY (`patient_id`) REFERENCES `hl7_patients` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 1.4 Patient Contact Persons Table

```sql
-- Multiple contacts per patient (FHIR Patient.contact)
CREATE TABLE `hl7_patient_contacts` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `patient_id` INT(11) NOT NULL,
  `relationship_code` VARCHAR(50) DEFAULT NULL COMMENT 'C=Emergency Contact, E=Employer, F=Federal Agency, etc.',
  `relationship_text` VARCHAR(100) DEFAULT NULL,
  `name_prefix` VARCHAR(20) DEFAULT NULL,
  `name_given` VARCHAR(100) DEFAULT NULL,
  `name_family` VARCHAR(100) DEFAULT NULL,
  `name_text` VARCHAR(255) DEFAULT NULL,
  `telecom_phone` VARCHAR(50) DEFAULT NULL,
  `telecom_email` VARCHAR(100) DEFAULT NULL,
  `address_text` TEXT DEFAULT NULL,
  `gender` ENUM('male', 'female', 'other', 'unknown') DEFAULT NULL,
  `organization_name` VARCHAR(255) DEFAULT NULL,
  `period_start` DATE DEFAULT NULL,
  `period_end` DATE DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_patient` (`patient_id`),
  CONSTRAINT `fk_contact_patient` FOREIGN KEY (`patient_id`) REFERENCES `hl7_patients` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 2. EJS View Design

### File: `/views/hl7-patient-register.ejs`

**Structure:**
```
┌─────────────────────────────────────────────────────────┐
│  Header: "Register New Patient (HL7 FHIR Compliant)"  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Section 1: Patient Identifiers                        │
│  ┌────────────────┬────────────────┬─────────────────┐ │
│  │ HN (MRN)*      │ PT Number*     │ FHIR ID (Auto)  │ │
│  ├────────────────┼────────────────┼─────────────────┤ │
│  │ National ID    │ Passport No.   │ SSN             │ │
│  └────────────────┴────────────────┴─────────────────┘ │
│                                                         │
│  Section 2: Name (HumanName)                           │
│  ┌─────────┬──────────────┬──────────────┬──────────┐ │
│  │ Use*    │ Prefix       │ Given Name*  │ Middle   │ │
│  ├─────────┼──────────────┼──────────────┼──────────┤ │
│  │ Family* │ Suffix       │ Full Text    │          │ │
│  └─────────┴──────────────┴──────────────┴──────────┘ │
│                                                         │
│  Section 3: Demographics                               │
│  ┌──────────────┬───────────────┬──────────────────┐  │
│  │ Birth Date*  │ Gender*       │ Marital Status   │  │
│  ├──────────────┼───────────────┼──────────────────┤  │
│  │ Deceased?    │ Death Date    │ Primary Language │  │
│  └──────────────┴───────────────┴──────────────────┘  │
│                                                         │
│  Section 4: Contact Information (ContactPoint)         │
│  ┌───────────────┬───────────────┬─────────────────┐  │
│  │ Phone         │ Mobile        │ Email           │  │
│  ├───────────────┼───────────────┼─────────────────┤  │
│  │ Fax           │ Contact Use   │                 │  │
│  └───────────────┴───────────────┴─────────────────┘  │
│                                                         │
│  Section 5: Address (FHIR Address)                     │
│  ┌────────────────────────────────────────────────┐   │
│  │ Address Use*  │ Address Type                   │   │
│  ├────────────────────────────────────────────────┤   │
│  │ Street Line 1                                  │   │
│  ├────────────────────────────────────────────────┤   │
│  │ Street Line 2                                  │   │
│  ├────────────┬────────────┬────────┬─────────────┤   │
│  │ City       │ District   │ State  │ Postal Code │   │
│  ├────────────┴────────────┴────────┴─────────────┤   │
│  │ Country (ISO 3166)                             │   │
│  └────────────────────────────────────────────────┘   │
│                                                         │
│  Section 6: Emergency Contact                          │
│  ┌─────────────────┬──────────────┬────────────────┐  │
│  │ Name            │ Relationship │ Phone          │  │
│  ├─────────────────┼──────────────┼────────────────┤  │
│  │ Email           │ Address                       │  │
│  └─────────────────┴──────────────┴────────────────┘  │
│                                                         │
│  Section 7: Clinical Information                       │
│  ┌──────────────────────────────────────────────────┐ │
│  │ Primary Diagnosis*                               │ │
│  ├──────────────────────────────────────────────────┤ │
│  │ Medical History                                  │ │
│  ├──────────────────────────────────────────────────┤ │
│  │ Allergies                                        │ │
│  ├──────────────────────────────────────────────────┤ │
│  │ Current Medications                              │ │
│  └──────────────────────────────────────────────────┘ │
│                                                         │
│  Section 8: Rehabilitation Plan                        │
│  ┌──────────────┬───────────────┬──────────────────┐  │
│  │ Goals (JSON) │ Body Area     │ Frequency        │  │
│  ├──────────────┼───────────────┼──────────────────┤  │
│  │ Duration     │ Precautions   │ Contraindications│  │
│  ├──────────────┴───────────────┴──────────────────┤  │
│  │ Doctor Notes                                    │  │
│  └─────────────────────────────────────────────────┘  │
│                                                         │
│  Section 9: Organization                               │
│  ┌─────────────────────────────────────────────────┐  │
│  │ Managing Organization (Clinic)*                 │  │
│  └─────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────┐  ┌──────────────────┐           │
│  │  Submit          │  │  Clear Form      │           │
│  └──────────────────┘  └──────────────────┘           │
└─────────────────────────────────────────────────────────┘
```

**Key Design Features:**
- Bootstrap 5 responsive grid layout
- Form validation using HTML5 + custom JavaScript
- Date picker for birth_date (Flatpickr)
- Dropdown selects for coded values (gender, marital_status, etc.)
- Multi-select for rehabilitation goals
- JSON editor for complex data
- Auto-generation of FHIR ID (UUID v4)
- Auto-generation of HN and PT Number
- Collapsible sections for better UX
- Real-time validation indicators

---

## 3. JavaScript Design

### File: `/public/js/hl7-patient-register.js`

**Main Functions:**

#### 3.1 Initialization
```javascript
// Initialize form on page load
document.addEventListener('DOMContentLoaded', () => {
  initializeDatePickers()
  loadClinics()
  generateFHIRId()
  setupFormValidation()
  setupAddressAutocomplete()
})
```

#### 3.2 Core Functions

**Generate FHIR ID**
```javascript
function generateFHIRId() {
  // Generate UUID v4 for FHIR resource ID
  // Format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  const uuid = crypto.randomUUID()
  document.getElementById('fhir_id').value = uuid
}
```

**Auto-generate HN and PT Number**
```javascript
async function generatePatientNumbers() {
  // Fetch next available HN and PT numbers from API
  // Format: HN - PT25XXX
  //         PT Number - PT20251114HHMMSSXXX
  const response = await fetch('/api/hl7/patients/next-numbers')
  const data = await response.json()
  return data
}
```

**Form Validation**
```javascript
function setupFormValidation() {
  // Required fields validation
  const requiredFields = [
    'hn', 'pt_number', 'name_given', 'name_family',
    'birth_date', 'gender', 'primary_diagnosis',
    'managing_organization'
  ]

  // HL7-specific validations
  - National ID format (13 digits for Thai ID)
  - Passport format validation
  - Date format (ISO 8601: YYYY-MM-DD)
  - Email format (RFC 5322)
  - Phone format (E.164 recommended)
  - Country code (ISO 3166-1 alpha-2)
  - Language code (ISO 639-1)
}
```

**Build HL7 FHIR Payload**
```javascript
function buildFHIRPayload() {
  return {
    resourceType: 'Patient',
    id: document.getElementById('fhir_id').value,
    identifier: [
      {
        use: 'official',
        type: { text: 'MRN' },
        value: document.getElementById('hn').value
      },
      {
        use: 'usual',
        type: { text: 'PT' },
        value: document.getElementById('pt_number').value
      }
    ],
    name: [{
      use: document.getElementById('name_use').value,
      prefix: [document.getElementById('name_prefix').value],
      given: [document.getElementById('name_given').value],
      family: document.getElementById('name_family').value
    }],
    telecom: [
      {
        system: 'phone',
        value: document.getElementById('telecom_phone').value,
        use: document.getElementById('telecom_use').value
      },
      {
        system: 'email',
        value: document.getElementById('telecom_email').value
      }
    ],
    gender: document.getElementById('gender').value,
    birthDate: document.getElementById('birth_date').value,
    address: [{
      use: document.getElementById('address_use').value,
      type: document.getElementById('address_type').value,
      line: [
        document.getElementById('address_line1').value,
        document.getElementById('address_line2').value
      ],
      city: document.getElementById('address_city').value,
      state: document.getElementById('address_state').value,
      postalCode: document.getElementById('address_postal_code').value,
      country: document.getElementById('address_country').value
    }],
    maritalStatus: {
      coding: [{
        code: document.getElementById('marital_status').value
      }]
    },
    contact: [{
      relationship: [{ text: 'Emergency Contact' }],
      name: { text: document.getElementById('emergency_contact_name').value },
      telecom: [
        { system: 'phone', value: document.getElementById('emergency_contact_phone').value }
      ]
    }],
    managingOrganization: {
      reference: `Organization/${document.getElementById('managing_organization').value}`
    },
    active: true
  }
}
```

**Submit Form**
```javascript
async function submitForm(event) {
  event.preventDefault()

  // Validate form
  if (!validateForm()) {
    showAlert('Please fill in all required fields correctly', 'danger')
    return
  }

  // Build FHIR-compliant payload
  const fhirPayload = buildFHIRPayload()

  // Submit to API
  try {
    const response = await fetch('/api/hl7/patients', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/fhir+json',
        'Authorization': `Bearer ${getAuthToken()}`
      },
      body: JSON.stringify(fhirPayload)
    })

    if (response.ok) {
      const result = await response.json()
      showAlert(`Patient registered successfully! FHIR ID: ${result.id}`, 'success')

      // Redirect to patient detail or list
      setTimeout(() => {
        window.location.href = `/hl7/patients/${result.id}`
      }, 2000)
    } else {
      const error = await response.json()
      showAlert(`Error: ${error.message}`, 'danger')
    }
  } catch (error) {
    showAlert('Network error. Please try again.', 'danger')
  }
}
```

#### 3.3 Helper Functions

```javascript
// Date formatting (ISO 8601)
function formatDateISO(date) {
  return date.toISOString().split('T')[0]
}

// Validate Thai National ID (13 digits with checksum)
function validateThaiID(id) {
  if (!/^\d{13}$/.test(id)) return false

  let sum = 0
  for (let i = 0; i < 12; i++) {
    sum += parseInt(id[i]) * (13 - i)
  }
  const checksum = (11 - (sum % 11)) % 10
  return checksum === parseInt(id[12])
}

// Validate email (RFC 5322)
function validateEmail(email) {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return regex.test(email)
}

// Load clinic list
async function loadClinics() {
  const response = await fetch('/api/clinics')
  const clinics = await response.json()

  const select = document.getElementById('managing_organization')
  clinics.forEach(clinic => {
    const option = document.createElement('option')
    option.value = clinic.id
    option.textContent = clinic.name
    select.appendChild(option)
  })
}
```

---

## 4. Data Flow Diagram

```
User Input (Browser)
     │
     ├──> EJS Form (hl7-patient-register.ejs)
     │    └── Sections:
     │        ├── Identifiers
     │        ├── Name
     │        ├── Demographics
     │        ├── Contact
     │        ├── Address
     │        ├── Emergency Contact
     │        ├── Clinical
     │        └── Rehab Plan
     │
     ├──> JavaScript (hl7-patient-register.js)
     │    ├── Validation
     │    ├── Build FHIR Payload
     │    └── API Call
     │
     ├──> Backend API (/api/hl7/patients)
     │    ├── Authenticate User
     │    ├── Validate FHIR Resource
     │    ├── Transform to DB Schema
     │    └── Save to Database
     │
     └──> Database (hl7_patients table)
          └── Success Response
               └── Redirect to Patient Detail
```

---

## 5. HL7 FHIR Compliance Checklist

### Resource Elements
- ✅ resourceType: Patient
- ✅ id: Unique FHIR identifier (UUID)
- ✅ identifier: Multiple identifiers (MRN, National ID, Passport)
- ✅ name: HumanName with use, prefix, given, family
- ✅ telecom: ContactPoint for phone, email
- ✅ gender: AdministrativeGender (male, female, other, unknown)
- ✅ birthDate: Date in YYYY-MM-DD format
- ✅ deceased[x]: Boolean or DateTime
- ✅ address: Address with structured fields
- ✅ maritalStatus: CodeableConcept
- ✅ contact: Emergency contacts with relationship
- ✅ communication: Language preferences
- ✅ managingOrganization: Reference to clinic
- ✅ active: Boolean status

### Data Standards
- ✅ ISO 8601 for dates
- ✅ ISO 639-1 for language codes
- ✅ ISO 3166-1 for country codes
- ✅ E.164 for phone numbers (recommended)
- ✅ RFC 5322 for email addresses
- ✅ HL7 v3 Code System for marital status
- ✅ HL7 v3 Code System for administrative gender

---

## 6. API Endpoints Design

### POST /api/hl7/patients
**Request Headers:**
```
Content-Type: application/fhir+json
Authorization: Bearer <token>
```

**Request Body:** FHIR Patient Resource (JSON)

**Response:**
```json
{
  "resourceType": "Patient",
  "id": "uuid-here",
  "meta": {
    "versionId": "1",
    "lastUpdated": "2025-11-18T10:00:00Z"
  },
  "identifier": [...],
  ...
}
```

### GET /api/hl7/patients/:id
**Response:** FHIR Patient Resource

### PUT /api/hl7/patients/:id
**Request:** Updated FHIR Patient Resource

### GET /api/hl7/patients/next-numbers
**Response:**
```json
{
  "hn": "PT25076",
  "pt_number": "PT20251118101523456"
}
```

---

## 7. Security Considerations

- ✅ Input validation and sanitization
- ✅ SQL injection prevention (parameterized queries)
- ✅ XSS protection (escape HTML output)
- ✅ CSRF token validation
- ✅ Role-based access control (RBAC)
- ✅ Audit logging for all changes
- ✅ HTTPS for data transmission
- ✅ Encryption for sensitive data (PII)
- ✅ HIPAA/GDPR compliance considerations

---

## 8. Migration Strategy

### Step 1: Create HL7 Tables
```sql
-- Run SQL scripts to create hl7_patients and related tables
-- Ensure foreign key constraints are in place
```

### Step 2: Data Migration (Optional)
```sql
-- Migrate existing patient data to HL7 format
INSERT INTO hl7_patients (...)
SELECT ... FROM patients
```

### Step 3: Deploy Frontend
- Deploy hl7-patient-register.ejs
- Deploy hl7-patient-register.js
- Update routing

### Step 4: Testing
- Unit tests for validation functions
- Integration tests for API endpoints
- FHIR validation against official schemas
- User acceptance testing (UAT)

---

## 9. Future Enhancements

- FHIR R4/R5 full compliance
- Integration with external HL7 systems
- FHIR REST API with search parameters
- HL7 v2 message support (ADT^A01, etc.)
- Interoperability with EHR systems
- SMART on FHIR authorization
- CDS Hooks integration
- Bulk data export (FHIR Bulk Data Access)

---

## Document Version
- **Version:** 1.0
- **Date:** 2025-11-18
- **Author:** Design Team
- **Status:** Draft for Review
