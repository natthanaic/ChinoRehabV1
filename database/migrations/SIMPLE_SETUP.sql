-- SIMPLEST SETUP - Just copy and paste this entire block into MySQL/phpMyAdmin

CREATE TABLE IF NOT EXISTS `pthn_sequence` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `year` int(4) NOT NULL,
  `last_sequence` int(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY (`year`)
) ENGINE=InnoDB;

INSERT INTO `pthn_sequence` (`year`, `last_sequence`) VALUES (25, 75);

SELECT * FROM `pthn_sequence`;
