-- Run this once in phpMyAdmin against the existing `wildlife` database.
CREATE TABLE IF NOT EXISTS animals (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  scientific_name VARCHAR(160) DEFAULT NULL,
  category VARCHAR(80) DEFAULT NULL,
  description TEXT NOT NULL,
  conservation_status VARCHAR(80) DEFAULT NULL,
  habitat VARCHAR(255) DEFAULT NULL,
  image_path VARCHAR(255) DEFAULT NULL,
  image_credit VARCHAR(255) DEFAULT NULL,
  poster_path VARCHAR(255) DEFAULT NULL,
  is_published TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

ALTER TABLE reports ADD COLUMN animal_id INT UNSIGNED NULL;
ALTER TABLE reports ADD COLUMN animal_name VARCHAR(120) NULL;
CREATE INDEX reports_animal_id_idx ON reports (animal_id);
