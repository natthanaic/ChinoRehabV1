-- Quick setup for pthn_sequence table
-- Run this in your MySQL database

-- Create the table if it doesn't exist
CREATE TABLE IF NOT EXISTS `pthn_sequence` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `year` int(4) NOT NULL COMMENT 'Year in YY format (e.g., 25 for 2025)',
  `last_sequence` int(4) NOT NULL DEFAULT 0 COMMENT 'Last used sequence (0001-9999)',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_year` (`year`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Initialize current year
INSERT INTO `pthn_sequence` (`year`, `last_sequence`)
VALUES (25, 0)
ON DUPLICATE KEY UPDATE `last_sequence` = `last_sequence`;

-- Check if it worked
SELECT * FROM `pthn_sequence`;
