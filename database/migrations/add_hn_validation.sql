-- ====================================================================
-- HN Creation & Validation System - Database Migration
-- Purpose: Add PTHN sequence tracking and enforce uniqueness constraints
-- ====================================================================

-- 1. Create PTHN sequence table
CREATE TABLE IF NOT EXISTS `pthn_sequence` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `year` int(4) NOT NULL COMMENT 'Year in YY format (e.g., 25 for 2025)',
  `last_sequence` int(4) NOT NULL DEFAULT 0 COMMENT 'Last used sequence number (0001-9999)',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_year` (`year`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Tracks PTHN sequence numbers per year for auto-generation';

-- 2. Initialize current year sequence
INSERT INTO `pthn_sequence` (`year`, `last_sequence`)
VALUES (CAST(DATE_FORMAT(NOW(), '%y') AS UNSIGNED), 0)
ON DUPLICATE KEY UPDATE `year` = `year`;

-- 3. Add unique constraint on HN (if not exists)
SET @exist := (SELECT COUNT(*) FROM information_schema.statistics
               WHERE table_schema = DATABASE()
               AND table_name = 'patients'
               AND index_name = 'unique_hn');
SET @sqlstmt := IF(@exist = 0, 'ALTER TABLE `patients` ADD UNIQUE KEY `unique_hn` (`hn`)', 'SELECT "unique_hn already exists" AS Info');
PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 4. Add unique constraint on Thai ID (pid)
-- First, convert empty strings to NULL (so we can have multiple NULLs but unique non-NULL values)
UPDATE `patients` SET `pid` = NULL WHERE `pid` = '' OR `pid` IS NULL;

-- Check if old index exists and drop it
SET @exist := (SELECT COUNT(*) FROM information_schema.statistics
               WHERE table_schema = DATABASE()
               AND table_name = 'patients'
               AND index_name = 'idx_patient_pid');
SET @sqlstmt := IF(@exist > 0, 'ALTER TABLE `patients` DROP INDEX `idx_patient_pid`', 'SELECT "idx_patient_pid does not exist" AS Info');
PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add unique constraint on pid (if not exists)
-- Note: MySQL allows multiple NULL values in UNIQUE columns
SET @exist := (SELECT COUNT(*) FROM information_schema.statistics
               WHERE table_schema = DATABASE()
               AND table_name = 'patients'
               AND index_name = 'unique_pid');
SET @sqlstmt := IF(@exist = 0, 'ALTER TABLE `patients` ADD UNIQUE KEY `unique_pid` (`pid`)', 'SELECT "unique_pid already exists" AS Info');
PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 5. Handle passport_no - convert empty strings to NULL
UPDATE `patients` SET `passport_no` = NULL WHERE `passport_no` = '' OR `passport_no` IS NULL;

-- Add index on passport_no (if not exists)
SET @exist := (SELECT COUNT(*) FROM information_schema.statistics
               WHERE table_schema = DATABASE()
               AND table_name = 'patients'
               AND index_name = 'idx_patient_passport');
SET @sqlstmt := IF(@exist = 0, 'ALTER TABLE `patients` ADD INDEX `idx_patient_passport` (`passport_no`)', 'SELECT "idx_patient_passport already exists" AS Info');
PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 6. Verify changes
SELECT 'PTHN Sequence Table Created' AS Status;
SELECT * FROM `pthn_sequence`;

SELECT 'Patient Table Constraints' AS Status;
SHOW INDEX FROM `patients` WHERE Key_name IN ('unique_hn', 'unique_pid', 'idx_patient_passport');
