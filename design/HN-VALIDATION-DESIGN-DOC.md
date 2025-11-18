# HN Creation & Validation System - Design Documentation

## 📋 Table of Contents
1. [Overview](#overview)
2. [Requirements](#requirements)
3. [PTHN Format Specification](#pthn-format-specification)
4. [System Architecture](#system-architecture)
5. [User Workflows](#user-workflows)
6. [Database Changes](#database-changes)
7. [API Endpoints](#api-endpoints)
8. [Frontend Components](#frontend-components)
9. [Implementation Files](#implementation-files)
10. [Testing Scenarios](#testing-scenarios)
11. [Security Considerations](#security-considerations)
12. [Future Enhancements](#future-enhancements)

---

## Overview

### Purpose
Implement a robust HN (Hospital Number) creation and validation system that:
- **Prevents duplicate patient registrations** based on Thai ID or Passport
- **Auto-generates PTHN** (Patient Hospital Number) with consistent format
- **Guides users** to create PN (Patient Number) cases for existing patients
- **Ensures data integrity** with server-side validation

### Current vs. New System

| Feature | Current System | New System |
|---------|---------------|------------|
| HN Generation | Manual entry | Auto-generated (PTYYXXXX) |
| HN Uniqueness | Not enforced | Database UNIQUE constraint |
| Thai ID Validation | Client-side only | Client + Server validation |
| Duplicate Check | None | Pre-registration verification |
| Passport Validation | None | Format validation + duplication check |
| Year Rollover | N/A | Auto-reset sequence to 0001 |

---

## Requirements

### Functional Requirements

1. **ID Verification**
   - User selects ID type (Thai National ID or Passport)
   - User enters ID number
   - System validates format
   - System checks database for duplicates

2. **PTHN Generation**
   - Format: **PTYYXXXX**
     - PT = Prefix (fixed)
     - YY = Current year (2 digits)
     - XXXX = Sequential number (0001-9999)
   - Auto-increment sequence per year
   - Reset to 0001 every new year

3. **Verification Outcomes**
   - **ID Available**: Show PTHN preview, allow form completion
   - **ID Exists**: Show patient info, offer PN creation option

4. **Validation Rules**
   - Thai ID: 13 digits with valid checksum
   - Passport: 6-20 alphanumeric characters
   - HN: Must match current year format
   - All validation: Client-side + Server-side

### Non-Functional Requirements

1. **Performance**
   - ID verification response < 500ms
   - Support up to 9999 patients per year

2. **Security**
   - JWT authentication required
   - Server-side re-validation to prevent race conditions
   - SQL injection prevention

3. **Usability**
   - Clear visual feedback for each step
   - Mobile-responsive design
   - Accessible (WCAG 2.1 AA)

---

## PTHN Format Specification

### Format Structure

```
PT YY XXXX
│  │  └─── Sequential Number (0001-9999)
│  └────── Year (2 digits)
└───────── Prefix (fixed)
```

### Examples

| Year | Sequence | PTHN | Description |
|------|----------|------|-------------|
| 2025 | 1 | **PT250001** | First patient of 2025 |
| 2025 | 2 | **PT250002** | Second patient of 2025 |
| 2025 | 9999 | **PT259999** | Last patient of 2025 |
| 2026 | 1 | **PT260001** | First patient of 2026 (sequence reset) |

### Year Transition

```
December 31, 2025:
  Last PTHN: PT259999

January 1, 2026:
  Next PTHN: PT260001 (sequence reset to 0001)
```

---

## System Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Patient Registration Form                 │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  1. ID Selection & Verification                       │  │
│  │     - Select ID Type (Thai ID / Passport)            │  │
│  │     - Enter ID Number                                │  │
│  │     - Click "Check ID" Button                        │  │
│  └──────────────┬───────────────────────────────────────┘  │
│                 │                                            │
│                 ▼                                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  2. Verification Result Display                       │  │
│  │     - ID Available → Show PTHN Preview               │  │
│  │     - ID Exists → Show Patient Info + PN Option      │  │
│  └──────────────┬───────────────────────────────────────┘  │
│                 │                                            │
│                 ▼                                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  3. Form Completion & Submission                      │  │
│  │     - Fill Patient Details                           │  │
│  │     - Submit Form                                    │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ AJAX POST /api/patients/check-id
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Backend API (Node.js)                     │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  POST /api/patients/check-id                         │  │
│  │                                                       │  │
│  │  1. Validate ID format                               │  │
│  │  2. Query database for existing patient              │  │
│  │  3a. If found → Return patient info                  │  │
│  │  3b. If not found → Generate next PTHN               │  │
│  └──────────────┬───────────────────────────────────────┘  │
│                 │                                            │
│                 ▼                                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  PTHN Generation Function                            │  │
│  │                                                       │  │
│  │  1. Get current year (YY)                            │  │
│  │  2. Query pthn_sequence table                        │  │
│  │  3. Increment sequence (with transaction lock)       │  │
│  │  4. Return PTYYXXXX                                  │  │
│  └──────────────┬───────────────────────────────────────┘  │
│                 │                                            │
│                 ▼                                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  POST /api/patients                                  │  │
│  │                                                       │  │
│  │  1. Re-validate ID (prevent race conditions)         │  │
│  │  2. Verify HN format and year                        │  │
│  │  3. Insert patient record                            │  │
│  │  4. Return success                                   │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    MySQL Database                            │
│                                                              │
│  ┌────────────────────────┐  ┌──────────────────────────┐  │
│  │  patients              │  │  pthn_sequence           │  │
│  │                        │  │                          │  │
│  │  - id (PK)             │  │  - id (PK)               │  │
│  │  - hn (UNIQUE)         │  │  - year (UNIQUE)         │  │
│  │  - pid (UNIQUE)        │  │  - last_sequence         │  │
│  │  - passport_no (INDEX) │  │  - created_at            │  │
│  │  - ...                 │  │  - updated_at            │  │
│  └────────────────────────┘  └──────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## User Workflows

### Workflow 1: New Patient Registration (ID Available)

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: User arrives at Patient Registration Form           │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 2: User selects ID Type                                │
│                                                              │
│   ○ Thai National ID                                        │
│   ○ Passport                                                │
│                                                              │
│   User selects: ● Thai National ID                          │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 3: User enters Thai ID                                 │
│                                                              │
│   Thai National ID: [1234567890123]                         │
│   Helper text: "13-digit Thai National ID"                  │
│                                                              │
│   [✓] Client-side validation passes (checksum valid)        │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 4: User clicks "Check ID" button                       │
│                                                              │
│   [🔍 Checking...] (Button shows loading spinner)           │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 5: System queries database                             │
│                                                              │
│   Query: SELECT * FROM patients WHERE pid = '1234567890123' │
│   Result: No records found                                  │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 6: System generates next PTHN                          │
│                                                              │
│   Current year: 2025 → YY = 25                              │
│   Last sequence: 42 → Next = 43                             │
│   Generated PTHN: PT250043                                  │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 7: System displays success alert                       │
│                                                              │
│   ┌──────────────────────────────────────────────────────┐ │
│   │ ✅ ID Verified - Ready to Create Patient             │ │
│   │                                                       │ │
│   │ This ID is not registered in the system.             │ │
│   │                                                       │ │
│   │ New PTHN will be: [PT250043]                         │ │
│   │                                                       │ │
│   │ You can now fill in patient details and submit.      │ │
│   └──────────────────────────────────────────────────────┘ │
│                                                              │
│   HN (Hospital Number): [PT250043] (read-only)              │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 8: User fills remaining form fields                    │
│                                                              │
│   - Name: John Doe                                          │
│   - Date of Birth: 01/01/1990                               │
│   - Gender: Male                                            │
│   - Diagnosis: Lower back pain                              │
│   - Clinic: Main Clinic                                     │
│   - ...                                                     │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 9: User clicks "Submit" button                         │
│                                                              │
│   Form validation passes ✓                                  │
│   ID verification check passes ✓                            │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 10: Backend re-validates and creates patient           │
│                                                              │
│   1. Re-check ID not duplicated ✓                           │
│   2. Verify HN year matches current year ✓                  │
│   3. Insert patient record ✓                                │
│   4. Return success                                         │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 11: Success message displayed                          │
│                                                              │
│   ✅ Patient created successfully!                          │
│   HN: PT250043                                              │
│   PT#: PT20251118145530123                                  │
│                                                              │
│   [View Patient Details]                                    │
└─────────────────────────────────────────────────────────────┘
```

---

### Workflow 2: Duplicate Patient (ID Already Exists)

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1-4: Same as Workflow 1                                │
│           (User enters ID and clicks "Check ID")            │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 5: System queries database                             │
│                                                              │
│   Query: SELECT * FROM patients WHERE pid = '1234567890123' │
│   Result: ✓ Found existing patient                          │
│                                                              │
│   Patient Info:                                             │
│   - HN: PT250015                                            │
│   - Name: Jane Smith                                        │
│   - DOB: 05/03/1985                                         │
│   - Clinic: Main Clinic                                     │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 6: System displays duplicate alert                     │
│                                                              │
│   ┌──────────────────────────────────────────────────────┐ │
│   │ ⚠️ Duplicate ID Detected                              │ │
│   │                                                       │ │
│   │ This ID is already registered:                       │ │
│   │                                                       │ │
│   │ ┌─────────────────────────────────────────────────┐ │ │
│   │ │ HN: PT250015      PT#: PT20251101...            │ │ │
│   │ │ Name: Jane Smith  DOB: 05/03/1985              │ │ │
│   │ │ Clinic: Main Clinic                             │ │ │
│   │ │ Registered: 01/11/2025                          │ │ │
│   │ └─────────────────────────────────────────────────┘ │ │
│   │                                                       │ │
│   │ [👁 View Patient Details] [➕ Create New PN Case]    │ │
│   │                                                       │ │
│   │ Note: If you need to create a new treatment case    │ │
│   │ (PN) for this patient, click "Create New PN Case".  │ │
│   └──────────────────────────────────────────────────────┘ │
│                                                              │
│   HN (Hospital Number): [        ] (empty, disabled)        │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 7: User has two options                                │
│                                                              │
│   Option A: Click "View Patient Details"                    │
│             → Opens patient detail page in new tab          │
│             → User can review patient history               │
│                                                              │
│   Option B: Click "Create New PN Case"                      │
│             → Shows confirmation dialog                     │
│             → Redirects to PN creation page                 │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Option B Selected: Create PN Case                           │
│                                                              │
│   Confirmation Dialog:                                      │
│   ┌──────────────────────────────────────────────────────┐ │
│   │ Create a new PN (Patient Number) case for            │ │
│   │ patient PT250015?                                     │ │
│   │                                                       │ │
│   │ This will redirect you to the PN creation page.      │ │
│   │                                                       │ │
│   │                [Cancel]  [Confirm]                    │ │
│   └──────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 8: Redirect to PN Creation                             │
│                                                              │
│   URL: /pn/create?patient_id=123&hn=PT250015                │
│                                                              │
│   PN Creation Form opens with:                              │
│   - Patient info pre-filled                                 │
│   - New PN number generated                                 │
│   - User can add new treatment details                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Database Changes

### New Table: `pthn_sequence`

```sql
CREATE TABLE IF NOT EXISTS `pthn_sequence` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `year` int(4) NOT NULL COMMENT 'Year in YY format (e.g., 25 for 2025)',
  `last_sequence` int(4) NOT NULL DEFAULT 0 COMMENT 'Last used sequence number (0001-9999)',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_year` (`year`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Initial data for 2025
INSERT INTO `pthn_sequence` (`year`, `last_sequence`) VALUES (25, 0);
```

### Modify Table: `patients`

```sql
-- Add unique constraint on HN
ALTER TABLE `patients`
ADD UNIQUE KEY `unique_hn` (`hn`);

-- Add unique constraint on Thai ID (pid)
ALTER TABLE `patients`
DROP INDEX IF EXISTS `idx_patient_pid`,
ADD UNIQUE KEY `unique_pid` (`pid`);

-- Keep index on passport (can't be UNIQUE because of NULLs)
ALTER TABLE `patients`
ADD INDEX `idx_patient_passport` (`passport_no`);
```

### Table Relationships

```
┌─────────────────────┐
│  pthn_sequence      │
│                     │
│  PK: id             │
│  UK: year           │
│  last_sequence      │
└─────────────────────┘
         │
         │ Used by PTHN generation
         │ (no foreign key)
         ▼
┌─────────────────────┐
│  patients           │
│                     │
│  PK: id             │
│  UK: hn             │◄────── Generated using pthn_sequence
│  UK: pid            │
│  IDX: passport_no   │
│  FK: clinic_id      │
│  FK: created_by     │
└─────────────────────┘
```

---

## API Endpoints

### 1. POST /api/patients/check-id

**Purpose**: Check if Thai ID or Passport exists in database and get next PTHN

**Authentication**: Required (JWT)

**Request Body**:
```json
{
  "idType": "thai_id",
  "idValue": "1234567890123"
}
```

**Response (ID Available)**:
```json
{
  "success": true,
  "isDuplicate": false,
  "nextPTHN": "PT250043",
  "message": "ID is available. You can create a new patient."
}
```

**Response (ID Exists)**:
```json
{
  "success": true,
  "isDuplicate": true,
  "patient": {
    "id": 123,
    "hn": "PT250015",
    "pt_number": "PT20251101145530123",
    "title": "Mrs.",
    "first_name": "Jane",
    "last_name": "Smith",
    "dob": "1985-03-05",
    "clinic_name": "Main Clinic",
    "created_at": "2025-11-01T10:30:00.000Z"
  },
  "message": "This ID is already registered."
}
```

**Response (Validation Error)**:
```json
{
  "success": false,
  "message": "Invalid Thai National ID format or checksum."
}
```

---

### 2. POST /api/patients (Modified)

**Purpose**: Create new patient (with enhanced validation)

**Authentication**: Required (JWT)

**Request Body**:
```json
{
  "hn": "PT250043",
  "idType": "thai_id",
  "idValue": "1234567890123",
  "first_name": "John",
  "last_name": "Doe",
  "dob": "1990-01-01",
  "gender": "M",
  "diagnosis": "Lower back pain",
  "clinic_id": 1,
  ...
}
```

**New Validation Rules**:
- HN must match format: `PT\d{6}` (e.g., PT250043)
- HN year must match current year
- ID must be re-validated (not duplicate)
- ID checksum must be valid (Thai ID only)

**Response (Success)**:
```json
{
  "success": true,
  "message": "Patient created successfully.",
  "patient": {
    "id": 456,
    "hn": "PT250043",
    "pt_number": "PT20251118145530123"
  }
}
```

**Response (Duplicate - Race Condition)**:
```json
{
  "success": false,
  "message": "HN already exists. Please verify ID again to get a new HN."
}
```

---

### 3. GET /api/admin/pthn-stats (New, Optional)

**Purpose**: Get PTHN generation statistics for monitoring

**Authentication**: Required (JWT + ADMIN role)

**Response**:
```json
{
  "success": true,
  "stats": [
    {
      "year": 25,
      "last_sequence": 42,
      "last_pthn": "PT250042",
      "next_pthn": "PT250043",
      "remaining": 9957,
      "created_at": "2025-01-01T00:00:00.000Z",
      "updated_at": "2025-11-18T10:30:00.000Z"
    },
    {
      "year": 24,
      "last_sequence": 9999,
      "last_pthn": "PT249999",
      "next_pthn": "PT250001",
      "remaining": 0,
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-12-31T23:59:59.000Z"
    }
  ]
}
```

---

## Frontend Components

### 1. ID Type Selector

```html
<select class="form-select" id="idType" name="idType" required>
    <option value="">-- Select ID Type --</option>
    <option value="thai_id">Thai National ID</option>
    <option value="passport">Passport</option>
</select>
```

**Behavior**:
- On change: Update ID input placeholder and validation rules
- On change: Clear previous verification results
- On change: Enable/disable "Check ID" button

---

### 2. ID Value Input with Check Button

```html
<div class="input-group">
    <input type="text"
           class="form-control"
           id="idValue"
           name="idValue"
           placeholder="Enter ID number"
           required>
    <button class="btn btn-primary"
            type="button"
            id="btnCheckID"
            disabled>
        <i class="bi bi-search"></i> Check ID
    </button>
</div>
```

**Behavior**:
- Thai ID: 13-digit input, checksum validation on blur
- Passport: 6-20 alphanumeric, uppercase conversion
- Button disabled until valid input entered
- Shows loading spinner during API call

---

### 3. Verification Alert (Success)

```html
<div class="alert alert-success" role="alert">
    <div class="d-flex align-items-start">
        <i class="bi bi-check-circle-fill me-2 fs-4"></i>
        <div class="flex-grow-1">
            <h6 class="alert-heading mb-1">ID Verified - Ready to Create Patient</h6>
            <p class="mb-2">This ID is not registered in the system.</p>
            <div class="bg-white p-2 rounded border">
                <strong>New PTHN will be:</strong>
                <span class="badge bg-primary fs-6" id="previewPTHN">PT250001</span>
            </div>
        </div>
    </div>
</div>
```

---

### 4. Verification Alert (Duplicate)

```html
<div class="alert alert-warning" role="alert">
    <div class="d-flex align-items-start">
        <i class="bi bi-exclamation-triangle-fill me-2 fs-4"></i>
        <div class="flex-grow-1">
            <h6 class="alert-heading mb-1">Duplicate ID Detected</h6>
            <p class="mb-2">This ID is already registered in the system:</p>

            <!-- Patient Info Card -->
            <div class="card bg-white mb-3">
                <div class="card-body p-2">
                    <div class="row g-2 small">
                        <div class="col-md-6"><strong>HN:</strong> PT250015</div>
                        <div class="col-md-6"><strong>Name:</strong> Jane Smith</div>
                        ...
                    </div>
                </div>
            </div>

            <!-- Action Buttons -->
            <div class="d-flex gap-2">
                <button type="button" class="btn btn-sm btn-outline-primary" id="btnViewPatient">
                    <i class="bi bi-eye"></i> View Patient Details
                </button>
                <button type="button" class="btn btn-sm btn-warning" id="btnCreatePN">
                    <i class="bi bi-plus-circle"></i> Create New PN Case Instead
                </button>
            </div>
        </div>
    </div>
</div>
```

---

### 5. HN Field (Read-Only)

```html
<input type="text"
       class="form-control"
       id="hn"
       name="hn"
       placeholder="PT25XXXX"
       readonly
       required>
<div class="form-text">Auto-generated after ID verification</div>
```

**Behavior**:
- Initially empty
- Populated after successful ID verification
- Read-only (user cannot edit)
- Value submitted with form

---

### 6. Workflow Progress Indicator (Optional)

```html
<div class="card mb-3 bg-light">
    <div class="card-body py-2">
        <div class="d-flex justify-content-between align-items-center">
            <div class="d-flex align-items-center" id="step1">
                <span class="badge rounded-pill bg-primary me-2">1</span>
                <small>Verify ID</small>
            </div>
            <div class="border-top flex-grow-1 mx-2"></div>
            <div class="d-flex align-items-center" id="step2">
                <span class="badge rounded-pill bg-secondary me-2">2</span>
                <small class="text-muted">Fill Patient Details</small>
            </div>
            <div class="border-top flex-grow-1 mx-2"></div>
            <div class="d-flex align-items-center" id="step3">
                <span class="badge rounded-pill bg-secondary me-2">3</span>
                <small class="text-muted">Submit & Create</small>
            </div>
        </div>
    </div>
</div>
```

**States**:
- Step 1 active: Verify ID (primary)
- Step 2 active: Fill form (primary after verification)
- Step 3 active: Submit (primary during submission)

---

## Implementation Files

### Files to Create

| File Path | Purpose | Status |
|-----------|---------|--------|
| `/design/hn-validation-ui.ejs.design` | Frontend UI components | ✅ Created |
| `/design/hn-validation.js.design` | Frontend JavaScript logic | ✅ Created |
| `/design/hn-validation-api.js.design` | Backend API endpoints | ✅ Created |
| `/design/HN-VALIDATION-DESIGN-DOC.md` | This document | ✅ Created |

### Files to Modify

| File Path | Changes Required |
|-----------|------------------|
| `/views/patient-register.ejs` | Replace "Patient Identifiers" section with new UI |
| `/views/patient-register.ejs` | Add `<script>` section for HN validation logic |
| `/app.js` | Add `generateNextPTHN()` function |
| `/app.js` | Add `POST /api/patients/check-id` endpoint |
| `/app.js` | Modify `POST /api/patients` with enhanced validation |
| `/lantava_soapview.sql` | Add `pthn_sequence` table |
| `/lantava_soapview.sql` | Modify `patients` table constraints |

---

## Testing Scenarios

### Test Case 1: New Patient with Thai ID

**Steps**:
1. Select ID Type: "Thai National ID"
2. Enter valid Thai ID: `1234567890123`
3. Click "Check ID"
4. Verify: Success alert shown with PTHN preview
5. Fill remaining form fields
6. Submit form
7. Verify: Patient created with correct PTHN

**Expected Results**:
- ✅ Thai ID validation passes (checksum)
- ✅ No duplicate found
- ✅ PTHN generated: `PT25XXXX`
- ✅ HN field populated and read-only
- ✅ Form submission succeeds
- ✅ Patient created in database

---

### Test Case 2: New Patient with Passport

**Steps**:
1. Select ID Type: "Passport"
2. Enter valid passport: `AB1234567`
3. Click "Check ID"
4. Verify: Success alert shown with PTHN preview
5. Fill remaining form fields
6. Submit form
7. Verify: Patient created with correct PTHN

**Expected Results**:
- ✅ Passport validation passes
- ✅ No duplicate found
- ✅ PTHN generated: `PT25XXXX`
- ✅ HN field populated
- ✅ Patient created in database

---

### Test Case 3: Duplicate Thai ID

**Steps**:
1. Create patient with Thai ID: `1234567890123` (HN: PT250001)
2. Try to create another patient with same Thai ID
3. Select ID Type: "Thai National ID"
4. Enter Thai ID: `1234567890123`
5. Click "Check ID"
6. Verify: Duplicate alert shown with patient info

**Expected Results**:
- ✅ Duplicate detected
- ✅ Warning alert shown
- ✅ Existing patient info displayed (HN, Name, DOB, etc.)
- ✅ "View Patient" button opens patient detail page
- ✅ "Create PN Case" button shows confirmation dialog
- ✅ HN field remains empty
- ✅ Form submission blocked

---

### Test Case 4: Invalid Thai ID (Checksum)

**Steps**:
1. Select ID Type: "Thai National ID"
2. Enter invalid Thai ID: `1234567890120` (wrong checksum)
3. Tab out of input field (blur event)

**Expected Results**:
- ✅ Client-side validation fails
- ✅ Red border shown on input
- ✅ Error message: "Invalid Thai National ID. Please check the checksum."
- ✅ "Check ID" button disabled

---

### Test Case 5: PTHN Sequence Increment

**Steps**:
1. Check current sequence for year 25: last_sequence = 42
2. Create new patient
3. Verify PTHN: `PT250043`
4. Create another patient
5. Verify PTHN: `PT250044`

**Expected Results**:
- ✅ PTHN increments correctly
- ✅ No gaps in sequence
- ✅ Database transaction ensures no duplicates

---

### Test Case 6: Year Transition

**Steps**:
1. Set system date to December 31, 2025
2. Create patient → PTHN: `PT259999`
3. Set system date to January 1, 2026
4. Create patient → PTHN: `PT260001`

**Expected Results**:
- ✅ New year creates new sequence row
- ✅ Sequence resets to 0001
- ✅ PTHN format uses new year: `PT26XXXX`

---

### Test Case 7: Race Condition (Simultaneous Check)

**Steps**:
1. User A: Check Thai ID `1234567890123` → Gets PTHN `PT250043`
2. User B: Check same Thai ID → Gets PTHN `PT250044` (before A submits)
3. User A: Submits form
4. User B: Submits form

**Expected Results**:
- ✅ User A: Patient created successfully with HN `PT250043`
- ✅ User B: Form submission fails with error "This ID is already registered"
- ✅ Server-side validation prevents duplicate

---

### Test Case 8: Form Submission Without Verification

**Steps**:
1. Navigate to patient registration form
2. Leave ID fields empty
3. Fill only name and other required fields
4. Click "Submit"

**Expected Results**:
- ✅ Form validation fails
- ✅ Alert: "Please verify the patient ID first by clicking 'Check ID' button."
- ✅ Focus returns to "Check ID" button
- ✅ Form not submitted

---

### Test Case 9: Create PN Case for Existing Patient

**Steps**:
1. Enter duplicate Thai ID
2. Duplicate alert shown
3. Click "Create New PN Case Instead"
4. Confirm dialog

**Expected Results**:
- ✅ Confirmation dialog shown
- ✅ Redirect to: `/pn/create?patient_id=123&hn=PT250015`
- ✅ PN creation form opens with patient context

---

### Test Case 10: Sequence Limit Reached

**Steps**:
1. Manually set `pthn_sequence` for year 25: last_sequence = 9999
2. Try to create new patient

**Expected Results**:
- ✅ Error returned: "PTHN sequence limit reached for this year (max 9999)"
- ✅ User notified to contact administrator
- ✅ No patient created

---

## Security Considerations

### 1. Input Validation

**Client-Side**:
- Thai ID: 13 digits + checksum algorithm
- Passport: 6-20 alphanumeric characters
- HN: Read-only field (cannot be edited by user)

**Server-Side**:
- Re-validate all inputs (never trust client)
- Sanitize ID values (remove spaces, dashes)
- Validate HN format: `^PT\d{6}$`
- Verify HN year matches current year

### 2. SQL Injection Prevention

```javascript
// ✅ GOOD: Use parameterized queries
db.query('SELECT * FROM patients WHERE pid = ?', [idValue]);

// ❌ BAD: String concatenation
db.query(`SELECT * FROM patients WHERE pid = '${idValue}'`);
```

### 3. Race Condition Handling

**Problem**: Two users check same ID simultaneously and get different PTHNs

**Solution**:
1. Use database transactions with row-level locks (`FOR UPDATE`)
2. Re-validate ID on form submission (server-side)
3. Return error if ID is now duplicate
4. Prompt user to verify again

### 4. Authentication & Authorization

- All API endpoints require JWT authentication
- Role-based access control (RBAC) for admin endpoints
- Clinic-based data isolation (users only see their clinic's data)

### 5. Data Privacy

- Sensitive fields (Thai ID, Passport) should be logged minimally
- Consider encryption at rest for PII (Personal Identifiable Information)
- HTTPS required for all API calls

---

## Future Enhancements

### Phase 2: Advanced Features

1. **Bulk Import with Validation**
   - CSV import with ID duplication check
   - Show report of duplicates before import
   - Auto-generate PTHNs for valid records

2. **ID Merge Functionality**
   - Detect potential duplicates (fuzzy matching on name + DOB)
   - Allow admin to merge duplicate patient records
   - Update all related records (PN, SOAP notes, etc.)

3. **Multi-Clinic PTHN Prefixes**
   - Different prefixes per clinic (e.g., MC25XXXX, BC25XXXX)
   - Separate sequence counters per clinic

4. **QR Code Generation**
   - Generate QR code with PTHN + Thai ID
   - Print on patient card
   - Scan for quick patient lookup

5. **Audit Trail**
   - Log all ID verification attempts
   - Track who created each patient
   - Monitor suspicious patterns (multiple failed verifications)

6. **Integration with National ID Database**
   - Real-time verification with government API
   - Auto-populate name, DOB from official records
   - Ensure data accuracy

---

## Summary

This design document provides a complete specification for implementing HN creation and validation with the following key features:

✅ **PTHN Auto-Generation**: Format `PTYYXXXX` with year-based sequence
✅ **ID Verification**: Check Thai ID and Passport duplication
✅ **User-Friendly UI**: Clear visual feedback and workflow
✅ **Data Integrity**: Unique constraints + server-side validation
✅ **Race Condition Handling**: Transaction locks + re-validation
✅ **PN Case Creation**: Redirect option for existing patients

### Implementation Priority

**Phase 1** (High Priority - Core Functionality):
1. Database schema changes
2. PTHN generation function
3. ID verification API endpoint
4. Frontend UI components
5. Client-side validation

**Phase 2** (Medium Priority - Enhanced UX):
1. Workflow progress indicator
2. View patient details integration
3. PN case creation redirect
4. Admin statistics dashboard

**Phase 3** (Low Priority - Advanced Features):
1. Bulk import with validation
2. Duplicate merge functionality
3. QR code generation

---

## Design Files Reference

| File | Description |
|------|-------------|
| `hn-validation-ui.ejs.design` | Complete UI components with Bootstrap 5 styling |
| `hn-validation.js.design` | Client-side JavaScript with state management |
| `hn-validation-api.js.design` | Backend API endpoints and PTHN generation logic |
| `HN-VALIDATION-DESIGN-DOC.md` | This comprehensive design documentation |

---

**Document Version**: 1.0
**Last Updated**: November 18, 2025
**Status**: Design Complete - Ready for Implementation

---
