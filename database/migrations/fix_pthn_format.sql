-- ====================================================================
-- Fix PTHN Format - Add Missing Leading Zero
-- Current: PT25001, PT25002, etc. (WRONG - 5 digits after PT)
-- Correct: PT250001, PT250002, etc. (RIGHT - 6 digits after PT = PTYYXXXX)
-- ====================================================================

-- STEP 1: Backup your current HN values (just in case)
CREATE TABLE IF NOT EXISTS patients_hn_backup AS
SELECT id, hn, pt_number FROM patients;

-- STEP 2: Update HN format - Add leading zero to sequence part
-- This converts PT25001 -> PT250001, PT25075 -> PT250075, etc.
UPDATE patients
SET hn = CONCAT(
    'PT',                                    -- Prefix: PT
    SUBSTRING(hn, 3, 2),                    -- Year: 25
    LPAD(SUBSTRING(hn, 5), 4, '0')         -- Sequence: pad to 4 digits
)
WHERE hn LIKE 'PT25%'
  AND LENGTH(hn) = 7;  -- Only update wrong format (PT25XXX = 7 chars)

-- STEP 3: Update pthn_sequence table to reflect correct last sequence
UPDATE pthn_sequence
SET last_sequence = (
    SELECT MAX(CAST(SUBSTRING(hn, 5, 4) AS UNSIGNED))
    FROM patients
    WHERE hn LIKE 'PT25%'
)
WHERE year = 25;

-- STEP 4: Verify the changes
SELECT 'Updated HN values:' AS Status;
SELECT id, hn, pt_number
FROM patients
WHERE hn LIKE 'PT25%'
ORDER BY hn
LIMIT 10;

SELECT '' AS '';
SELECT 'PTHN Sequence status:' AS Status;
SELECT
    year,
    last_sequence,
    CONCAT('PT', LPAD(year, 2, '0'), LPAD(last_sequence, 4, '0')) as last_pthn,
    CONCAT('PT', LPAD(year, 2, '0'), LPAD(last_sequence + 1, 4, '0')) as next_pthn
FROM pthn_sequence
WHERE year = 25;

-- STEP 5 (Optional): Drop backup table after verifying
-- DROP TABLE patients_hn_backup;
