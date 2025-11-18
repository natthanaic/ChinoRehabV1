-- ============================================================================
-- HL7 FHIR-Compliant Patient Registration System - Database Schema
-- ============================================================================
-- Version: 1.0
-- Date: 2025-11-18
-- Description: Database schema for HL7 FHIR-compliant patient records
-- Standards: HL7 FHIR R4, ISO 8601, ISO 639-1, ISO 3166-1
-- ============================================================================

-- Drop existing tables if they exist (for clean installation)
DROP TABLE IF EXISTS `hl7_patient_contacts`;
DROP TABLE IF EXISTS `hl7_patient_communications`;
DROP TABLE IF EXISTS `hl7_patient_identifiers`;
DROP TABLE IF EXISTS `hl7_patients`;

-- ============================================================================
-- Main Patient Table (FHIR Patient Resource)
-- ============================================================================

CREATE TABLE `hl7_patients` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,

  -- ========== FHIR Resource Metadata ==========
  `resource_type` VARCHAR(50) DEFAULT 'Patient' COMMENT 'FHIR resource type',
  `fhir_id` VARCHAR(100) UNIQUE NOT NULL COMMENT 'FHIR resource ID (UUID v4)',

  -- ========== Identifiers (PID Segment - HL7 v2 / FHIR Identifier) ==========
  `hn` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Hospital Number (Medical Record Number)',
  `pt_number` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Physical Therapy Number',
  `national_id` VARCHAR(20) DEFAULT NULL COMMENT 'National ID / Thai ID (PID)',
  `passport_no` VARCHAR(50) DEFAULT NULL COMMENT 'Passport Number',
  `ssn` VARCHAR(20) DEFAULT NULL COMMENT 'Social Security Number',
  `identifier_system` VARCHAR(255) DEFAULT NULL COMMENT 'FHIR identifier system URI',

  -- ========== Name (FHIR HumanName) ==========
  `name_use` ENUM('official', 'usual', 'temp', 'nickname', 'anonymous', 'old', 'maiden') DEFAULT 'official' COMMENT 'How this name is used',
  `name_prefix` VARCHAR(20) DEFAULT NULL COMMENT 'Title: Mr., Mrs., Ms., Dr., etc.',
  `name_given` VARCHAR(100) NOT NULL COMMENT 'Given name / First name',
  `name_family` VARCHAR(100) NOT NULL COMMENT 'Family name / Last name',
  `name_middle` VARCHAR(100) DEFAULT NULL COMMENT 'Middle name',
  `name_suffix` VARCHAR(50) DEFAULT NULL COMMENT 'Suffix: Jr., Sr., III, etc.',
  `name_text` VARCHAR(255) DEFAULT NULL COMMENT 'Full name as displayed text',

  -- ========== Telecom (FHIR ContactPoint) ==========
  `telecom_phone` VARCHAR(50) DEFAULT NULL COMMENT 'Primary phone number',
  `telecom_mobile` VARCHAR(50) DEFAULT NULL COMMENT 'Mobile phone number',
  `telecom_email` VARCHAR(100) DEFAULT NULL COMMENT 'Email address',
  `telecom_fax` VARCHAR(50) DEFAULT NULL COMMENT 'Fax number',
  `telecom_use` ENUM('home', 'work', 'temp', 'old', 'mobile') DEFAULT 'home' COMMENT 'Purpose of contact point',

  -- ========== Demographics ==========
  `gender` ENUM('male', 'female', 'other', 'unknown') DEFAULT NULL COMMENT 'Administrative gender (HL7 AdministrativeGender)',
  `birth_date` DATE NOT NULL COMMENT 'Date of birth in YYYY-MM-DD format (ISO 8601)',
  `deceased_boolean` TINYINT(1) DEFAULT 0 COMMENT 'Indicates if patient is deceased',
  `deceased_date_time` DATETIME DEFAULT NULL COMMENT 'Date and time of death (ISO 8601)',

  -- ========== Address (FHIR Address) ==========
  `address_use` ENUM('home', 'work', 'temp', 'old', 'billing') DEFAULT 'home' COMMENT 'Purpose of this address',
  `address_type` ENUM('postal', 'physical', 'both') DEFAULT 'both' COMMENT 'Type of address',
  `address_line1` VARCHAR(255) DEFAULT NULL COMMENT 'Street address line 1',
  `address_line2` VARCHAR(255) DEFAULT NULL COMMENT 'Street address line 2 (apartment, unit, etc.)',
  `address_city` VARCHAR(100) DEFAULT NULL COMMENT 'City / Municipality',
  `address_district` VARCHAR(100) DEFAULT NULL COMMENT 'District / County / Amphoe',
  `address_state` VARCHAR(100) DEFAULT NULL COMMENT 'State / Province / Changwat',
  `address_postal_code` VARCHAR(20) DEFAULT NULL COMMENT 'Postal code / ZIP code',
  `address_country` VARCHAR(100) DEFAULT NULL COMMENT 'Country (ISO 3166-1 alpha-2 code: TH, US, etc.)',
  `address_text` TEXT DEFAULT NULL COMMENT 'Full address as text',

  -- ========== Marital Status (FHIR CodeableConcept) ==========
  `marital_status` ENUM('A', 'D', 'I', 'L', 'M', 'P', 'S', 'T', 'U', 'W') DEFAULT NULL
    COMMENT 'A=Annulled, D=Divorced, I=Interlocutory, L=Legally Separated, M=Married, P=Polygamous, S=Never Married, T=Domestic partner, U=Unmarried, W=Widowed (HL7 v3 Code System)',

  -- ========== Communication (FHIR Patient.communication) ==========
  `language_primary` VARCHAR(10) DEFAULT NULL COMMENT 'Primary language (ISO 639-1 code: th, en, fr, etc.)',
  `language_preferred` TINYINT(1) DEFAULT 0 COMMENT 'Whether this is the preferred language',

  -- ========== Emergency Contact (FHIR Contact) ==========
  `emergency_contact_name` VARCHAR(200) DEFAULT NULL COMMENT 'Full name of emergency contact',
  `emergency_contact_relationship` VARCHAR(100) DEFAULT NULL COMMENT 'Relationship to patient (spouse, parent, child, friend, etc.)',
  `emergency_contact_phone` VARCHAR(50) DEFAULT NULL COMMENT 'Emergency contact phone number',
  `emergency_contact_email` VARCHAR(100) DEFAULT NULL COMMENT 'Emergency contact email',
  `emergency_contact_address` TEXT DEFAULT NULL COMMENT 'Emergency contact address',

  -- ========== Clinical Information (FHIR Extensions) ==========
  `primary_diagnosis` TEXT DEFAULT NULL COMMENT 'Primary diagnosis or chief complaint',
  `medical_history` TEXT DEFAULT NULL COMMENT 'Past medical history, chronic conditions',
  `allergies` TEXT DEFAULT NULL COMMENT 'Known allergies (medications, food, environmental)',
  `medications` TEXT DEFAULT NULL COMMENT 'Current medications list',

  -- ========== Rehabilitation Plan (Custom Extension for PT) ==========
  `rehab_goals` TEXT DEFAULT NULL COMMENT 'JSON array of rehabilitation goals',
  `body_area` VARCHAR(200) DEFAULT NULL COMMENT 'Body area affected (Neck, Shoulder, Back, Knee, etc.)',
  `treatment_frequency` VARCHAR(100) DEFAULT NULL COMMENT 'Frequency of treatment (Daily, 2x/week, etc.)',
  `expected_duration` VARCHAR(100) DEFAULT NULL COMMENT 'Expected duration of treatment',
  `precautions` TEXT DEFAULT NULL COMMENT 'Clinical precautions for treatment',
  `contraindications` TEXT DEFAULT NULL COMMENT 'Treatment contraindications',
  `doctor_notes` TEXT DEFAULT NULL COMMENT 'Doctor or referring physician notes',

  -- ========== Organization Reference (FHIR Reference) ==========
  `managing_organization` INT(11) NOT NULL COMMENT 'Reference to managing clinic (Organization resource)',

  -- ========== FHIR Metadata ==========
  `active` TINYINT(1) DEFAULT 1 COMMENT 'Whether this patient record is active',
  `meta_version_id` INT(11) DEFAULT 1 COMMENT 'Version number for FHIR resource versioning',
  `meta_last_updated` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update timestamp',

  -- ========== Audit Fields ==========
  `created_by` INT(11) NOT NULL COMMENT 'User ID who created this record',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation timestamp',
  `updated_at` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last modification timestamp',

  -- ========== Primary and Unique Keys ==========
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_hn` (`hn`),
  UNIQUE KEY `uk_pt_number` (`pt_number`),
  UNIQUE KEY `uk_fhir_id` (`fhir_id`),

  -- ========== Indexes for Performance ==========
  KEY `idx_national_id` (`national_id`),
  KEY `idx_passport` (`passport_no`),
  KEY `idx_name` (`name_given`, `name_family`),
  KEY `idx_birth_date` (`birth_date`),
  KEY `idx_gender` (`gender`),
  KEY `idx_clinic` (`managing_organization`),
  KEY `idx_active` (`active`),
  KEY `idx_created_at` (`created_at`),

  -- ========== Foreign Key Constraints ==========
  CONSTRAINT `fk_hl7_patient_clinic`
    FOREIGN KEY (`managing_organization`)
    REFERENCES `clinics` (`id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,

  CONSTRAINT `fk_hl7_patient_creator`
    FOREIGN KEY (`created_by`)
    REFERENCES `users` (`id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='HL7 FHIR R4-compliant patient records for rehabilitation clinic';

-- ============================================================================
-- Patient Identifiers Table (FHIR Identifier Array)
-- ============================================================================

CREATE TABLE `hl7_patient_identifiers` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `patient_id` INT(11) NOT NULL COMMENT 'Reference to hl7_patients.id',

  -- FHIR Identifier Fields
  `identifier_use` ENUM('usual', 'official', 'temp', 'secondary', 'old') DEFAULT 'usual'
    COMMENT 'Purpose of this identifier',
  `identifier_type` VARCHAR(50) NOT NULL
    COMMENT 'Type of identifier: MR=Medical record, SS=Social Security, DL=Drivers License, PPN=Passport, etc.',
  `identifier_system` VARCHAR(255) DEFAULT NULL
    COMMENT 'URI that defines the identifier system (e.g., http://hospital.org/identifiers/mrn)',
  `identifier_value` VARCHAR(100) NOT NULL
    COMMENT 'The actual identifier value',
  `identifier_period_start` DATE DEFAULT NULL
    COMMENT 'Time period when identifier is/was valid - start date',
  `identifier_period_end` DATE DEFAULT NULL
    COMMENT 'Time period when identifier is/was valid - end date',
  `assigner_organization` VARCHAR(255) DEFAULT NULL
    COMMENT 'Organization that issued this identifier',

  -- Metadata
  `active` TINYINT(1) DEFAULT 1 COMMENT 'Whether this identifier is currently active',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  KEY `idx_patient` (`patient_id`),
  KEY `idx_identifier_value` (`identifier_value`),
  KEY `idx_identifier_type` (`identifier_type`),

  CONSTRAINT `fk_identifier_patient`
    FOREIGN KEY (`patient_id`)
    REFERENCES `hl7_patients` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Multiple identifiers per patient (FHIR Identifier)';

-- ============================================================================
-- Patient Communication Languages Table (FHIR Patient.communication)
-- ============================================================================

CREATE TABLE `hl7_patient_communications` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `patient_id` INT(11) NOT NULL COMMENT 'Reference to hl7_patients.id',

  -- Language Information
  `language_code` VARCHAR(10) NOT NULL
    COMMENT 'ISO 639-1 language code (th=Thai, en=English, zh=Chinese, etc.)',
  `language_display` VARCHAR(100) DEFAULT NULL
    COMMENT 'Human-readable language name',
  `preferred` TINYINT(1) DEFAULT 0
    COMMENT 'Whether this is the preferred language for communication',

  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  KEY `idx_patient` (`patient_id`),
  KEY `idx_language` (`language_code`),

  CONSTRAINT `fk_comm_patient`
    FOREIGN KEY (`patient_id`)
    REFERENCES `hl7_patients` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Languages spoken by patient (FHIR Patient.communication)';

-- ============================================================================
-- Patient Contact Persons Table (FHIR Patient.contact)
-- ============================================================================

CREATE TABLE `hl7_patient_contacts` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `patient_id` INT(11) NOT NULL COMMENT 'Reference to hl7_patients.id',

  -- Relationship
  `relationship_code` VARCHAR(50) DEFAULT NULL
    COMMENT 'Coded relationship: C=Emergency Contact, E=Employer, F=Federal Agency, N=Next-of-Kin, S=State Agency, U=Unknown, etc.',
  `relationship_text` VARCHAR(100) DEFAULT NULL
    COMMENT 'Human-readable relationship description',

  -- Name
  `name_prefix` VARCHAR(20) DEFAULT NULL COMMENT 'Title (Mr., Mrs., Dr., etc.)',
  `name_given` VARCHAR(100) DEFAULT NULL COMMENT 'Given / First name',
  `name_family` VARCHAR(100) DEFAULT NULL COMMENT 'Family / Last name',
  `name_text` VARCHAR(255) DEFAULT NULL COMMENT 'Full name as text',

  -- Contact Information
  `telecom_phone` VARCHAR(50) DEFAULT NULL COMMENT 'Phone number',
  `telecom_email` VARCHAR(100) DEFAULT NULL COMMENT 'Email address',
  `address_text` TEXT DEFAULT NULL COMMENT 'Full address',

  -- Additional Information
  `gender` ENUM('male', 'female', 'other', 'unknown') DEFAULT NULL,
  `organization_name` VARCHAR(255) DEFAULT NULL
    COMMENT 'Organization this contact represents (if applicable)',

  -- Period
  `period_start` DATE DEFAULT NULL COMMENT 'Start date of relationship',
  `period_end` DATE DEFAULT NULL COMMENT 'End date of relationship',

  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  KEY `idx_patient` (`patient_id`),
  KEY `idx_relationship` (`relationship_code`),

  CONSTRAINT `fk_contact_patient`
    FOREIGN KEY (`patient_id`)
    REFERENCES `hl7_patients` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Contact persons for patient (emergency, next-of-kin, etc.)';

-- ============================================================================
-- Indexes for Audit Logs (if using existing audit_logs table)
-- ============================================================================

-- Add index for HL7 patient audit logs
ALTER TABLE `audit_logs`
ADD KEY `idx_entity_hl7_patient` (`entity_type`, `entity_id`)
WHERE `entity_type` = 'hl7_patient';

-- ============================================================================
-- Triggers for Audit Trail
-- ============================================================================

DELIMITER $$

-- Trigger: Before Insert - Generate FHIR ID if not provided
CREATE TRIGGER `before_hl7_patient_insert`
BEFORE INSERT ON `hl7_patients`
FOR EACH ROW
BEGIN
  -- Generate FHIR ID if not provided (UUID v4 format)
  IF NEW.fhir_id IS NULL OR NEW.fhir_id = '' THEN
    SET NEW.fhir_id = UUID();
  END IF;

  -- Set initial version
  SET NEW.meta_version_id = 1;
END$$

-- Trigger: After Insert - Log creation
CREATE TRIGGER `after_hl7_patient_insert`
AFTER INSERT ON `hl7_patients`
FOR EACH ROW
BEGIN
  INSERT INTO audit_logs (
    user_id,
    action,
    entity_type,
    entity_id,
    new_values,
    created_at
  ) VALUES (
    NEW.created_by,
    'CREATE',
    'hl7_patient',
    NEW.id,
    JSON_OBJECT(
      'fhir_id', NEW.fhir_id,
      'hn', NEW.hn,
      'pt_number', NEW.pt_number,
      'name', CONCAT(NEW.name_given, ' ', NEW.name_family)
    ),
    CURRENT_TIMESTAMP
  );
END$$

-- Trigger: Before Update - Increment version
CREATE TRIGGER `before_hl7_patient_update`
BEFORE UPDATE ON `hl7_patients`
FOR EACH ROW
BEGIN
  -- Increment version on update
  SET NEW.meta_version_id = OLD.meta_version_id + 1;
END$$

-- Trigger: After Update - Log changes
CREATE TRIGGER `after_hl7_patient_update`
AFTER UPDATE ON `hl7_patients`
FOR EACH ROW
BEGIN
  INSERT INTO audit_logs (
    user_id,
    action,
    entity_type,
    entity_id,
    old_values,
    new_values,
    created_at
  ) VALUES (
    NEW.created_by,
    'UPDATE',
    'hl7_patient',
    NEW.id,
    JSON_OBJECT(
      'name', CONCAT(OLD.name_given, ' ', OLD.name_family),
      'version', OLD.meta_version_id
    ),
    JSON_OBJECT(
      'name', CONCAT(NEW.name_given, ' ', NEW.name_family),
      'version', NEW.meta_version_id
    ),
    CURRENT_TIMESTAMP
  );
END$$

DELIMITER ;

-- ============================================================================
-- Initial Data / Sample Records (Optional)
-- ============================================================================

-- None - Production tables should start empty

-- ============================================================================
-- Grants and Permissions (Adjust as needed)
-- ============================================================================

-- GRANT SELECT, INSERT, UPDATE ON hl7_patients TO 'app_user'@'localhost';
-- GRANT SELECT, INSERT, UPDATE ON hl7_patient_identifiers TO 'app_user'@'localhost';
-- GRANT SELECT, INSERT, UPDATE ON hl7_patient_communications TO 'app_user'@'localhost';
-- GRANT SELECT, INSERT, UPDATE ON hl7_patient_contacts TO 'app_user'@'localhost';

-- ============================================================================
-- End of Schema
-- ============================================================================
