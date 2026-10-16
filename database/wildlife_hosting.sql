-- Hosting schema for Brunei Go Online Apps.
-- Select nazir21_wildlife in phpMyAdmin before importing this file.
-- Starter CRM login: admin / admin123. Change the password in phpMyAdmin.

CREATE TABLE IF NOT EXISTS `admin` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(80) NOT NULL,
  `password` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `admin_username_unique` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_account` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(30) NOT NULL,
  `contact` VARCHAR(20) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_account_username_unique` (`username`),
  UNIQUE KEY `user_account_contact_unique` (`contact`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO `admin` (`username`, `password`) VALUES ('admin', 'admin123');

CREATE TABLE IF NOT EXISTS `animals` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(120) NOT NULL,
  `scientific_name` VARCHAR(160) DEFAULT NULL,
  `category` VARCHAR(80) DEFAULT NULL,
  `description` TEXT NOT NULL,
  `conservation_status` VARCHAR(80) DEFAULT NULL,
  `habitat` VARCHAR(255) DEFAULT NULL,
  `image_path` VARCHAR(255) DEFAULT NULL,
  `image_credit` VARCHAR(255) DEFAULT NULL,
  `poster_path` VARCHAR(255) DEFAULT NULL,
  `is_published` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `animals_name_idx` (`name`),
  KEY `animals_published_idx` (`is_published`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add photo credits to existing installations that predate this column.
SET @has_image_credit = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'animals' AND COLUMN_NAME = 'image_credit'
);
SET @image_credit_ddl = IF(@has_image_credit = 0,
  'ALTER TABLE animals ADD COLUMN image_credit VARCHAR(255) NULL AFTER image_path',
  'SELECT 1');
PREPARE image_credit_stmt FROM @image_credit_ddl;
EXECUTE image_credit_stmt;
DEALLOCATE PREPARE image_credit_stmt;

-- Curated Brunei wildlife starter profiles. This is not an exhaustive species list.
-- Images are representative photos hosted by Wikimedia Commons; see
-- brunei_wildlife_photo_credits.md for authors, licences, and source pages.
UPDATE animals
SET name = 'Estuarine Crocodile',
    scientific_name = 'Crocodylus porosus',
    category = 'Reptile',
    description = 'Brunei’s estuarine crocodile is a large, powerful reptile found in coastal wetlands and river systems. It can move between salt water and fresh water and is an important native predator. Keep a safe distance from waterways where crocodiles may occur.',
    conservation_status = 'Least Concern (LC)',
    habitat = 'Estuaries, mangroves, coastal forests, and rivers',
    image_path = 'uploads/animals/catalog_estuarine_crocodile.jpg',
    image_credit = 'JustinReptile · CC BY-SA 4.0 · Wikimedia Commons',
    is_published = 1
WHERE scientific_name = 'Crocodylus johnstoni';

-- Point any profiles already imported from an earlier version to the bundled
-- local photos so the mobile app does not depend on third-party redirects.
UPDATE animals
SET image_path = CASE scientific_name
  WHEN 'Crocodylus porosus' THEN 'uploads/animals/catalog_estuarine_crocodile.jpg'
  WHEN 'Nasalis larvatus' THEN 'uploads/animals/catalog_proboscis_monkey.jpg'
  WHEN 'Helarctos malayanus' THEN 'uploads/animals/catalog_bornean_sun_bear.jpg'
  WHEN 'Sus barbatus' THEN 'uploads/animals/catalog_bearded_pig.jpg'
  WHEN 'Buceros rhinoceros' THEN 'uploads/animals/catalog_rhinoceros_hornbill.jpg'
  WHEN 'Tomistoma schlegelii' THEN 'uploads/animals/catalog_false_gharial.jpg'
  WHEN 'Chelonia mydas' THEN 'uploads/animals/catalog_green_sea_turtle.jpg'
  ELSE image_path
END
WHERE scientific_name IN (
  'Crocodylus porosus', 'Nasalis larvatus', 'Helarctos malayanus',
  'Sus barbatus', 'Buceros rhinoceros', 'Tomistoma schlegelii', 'Chelonia mydas'
);

INSERT INTO animals
  (name, scientific_name, category, description, conservation_status, habitat, image_path, image_credit, is_published)
SELECT s.name, s.scientific_name, s.category, s.description, s.conservation_status,
       s.habitat, s.image_path, s.image_credit, 1
FROM (
  SELECT
    'Estuarine Crocodile' AS name,
    'Crocodylus porosus' AS scientific_name,
    'Reptile' AS category,
    'Brunei’s estuarine crocodile is a large, powerful reptile found in coastal wetlands and river systems. It can move between salt water and fresh water and is an important native predator. Keep a safe distance from waterways where crocodiles may occur.' AS description,
    'Least Concern (LC)' AS conservation_status,
    'Estuaries, mangroves, coastal forests, and rivers' AS habitat,
    'uploads/animals/catalog_estuarine_crocodile.jpg' AS image_path,
    'JustinReptile · CC BY-SA 4.0 · Wikimedia Commons' AS image_credit
  UNION ALL SELECT
    'Proboscis Monkey', 'Nasalis larvatus', 'Mammal',
    'This Bornean endemic is known for the adult male’s long, prominent nose. It lives in groups and feeds mainly on leaves and fruit in forests close to rivers and tidal wetlands. Brunei’s national biodiversity report records the species in the country and identifies it as endangered.',
    'Endangered (EN)', 'Riverine forest, mangroves, and freshwater or peat-swamp forest',
    'uploads/animals/catalog_proboscis_monkey.jpg',
    'Calistemon · CC BY-SA 4.0 · Wikimedia Commons'
  UNION ALL SELECT
    'Bornean Sun Bear', 'Helarctos malayanus', 'Mammal',
    'The sun bear is the smallest bear species and has a short black coat with a pale chest marking. It uses its long tongue and strong claws to reach insects and honey, and also eats fruit. Brunei’s biodiversity report records sun bears in the country’s forests.',
    'Vulnerable (VU)', 'Lowland and hill forests',
    'uploads/animals/catalog_bornean_sun_bear.jpg',
    'Rennett Stowe · CC BY 2.0 · Wikimedia Commons'
  UNION ALL SELECT
    'Bornean Bearded Pig', 'Sus barbatus', 'Mammal',
    'A native forest pig with a distinctive fringe of coarse bristles around its cheeks and snout. It forages for fruit, roots, and other food on the forest floor and may travel in groups. Bearded pigs are among the large terrestrial mammals recorded in Brunei.',
    'Near Threatened (NT)', 'Tropical forests and forest edges',
    'uploads/animals/catalog_bearded_pig.jpg',
    'Quinet · CC BY-SA 4.0 · Wikimedia Commons'
  UNION ALL SELECT
    'Rhinoceros Hornbill', 'Buceros rhinoceros', 'Bird',
    'A large forest hornbill recognised by its strong bill and prominent upturned casque. It eats fruit and helps disperse seeds through the forest. Brunei’s national biodiversity report notes that hornbills occur in the country, including around the Belait district.',
    'Vulnerable (VU)', 'Lowland and hill dipterocarp forest',
    'uploads/animals/catalog_rhinoceros_hornbill.jpg',
    'shankar s. · CC BY 2.0 · Wikimedia Commons'
  UNION ALL SELECT
    'False Gharial', 'Tomistoma schlegelii', 'Reptile',
    'A long-snouted crocodilian that spends much of its time in freshwater. It is more secretive than the estuarine crocodile and is associated with quiet rivers and swamp forests. Brunei’s national biodiversity report records the false gharial in the country.',
    'Endangered (EN)', 'Freshwater rivers, peat swamps, and swamp forest',
    'uploads/animals/catalog_false_gharial.jpg',
    'Yinan Chen · Public domain · Wikimedia Commons'
  UNION ALL SELECT
    'Green Sea Turtle', 'Chelonia mydas', 'Reptile',
    'A large marine turtle that uses tropical coastal waters and seagrass beds. Adults mostly graze on seagrass and algae. The green turtle is included in the Convention on Migratory Species records for Brunei Darussalam.',
    'Endangered (EN)', 'Coastal waters, seagrass beds, and nesting beaches',
    'uploads/animals/catalog_green_sea_turtle.jpg',
    'U.S. Fish and Wildlife Service · Public domain · Wikimedia Commons'
) AS s
WHERE NOT EXISTS (
  SELECT 1 FROM animals a WHERE a.scientific_name = s.scientific_name
);

CREATE TABLE IF NOT EXISTS `reports` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `fullname` VARCHAR(150) NOT NULL,
  `latitude` DECIMAL(10,7) NOT NULL DEFAULT 0.0000000,
  `longitude` DECIMAL(10,7) NOT NULL DEFAULT 0.0000000,
  `location` VARCHAR(255) NOT NULL DEFAULT 'Unknown Location',
  `status` VARCHAR(20) NOT NULL DEFAULT 'pending',
  `contact` VARCHAR(80) NOT NULL DEFAULT '',
  `aduan` TEXT DEFAULT NULL,
  `picture_path` VARCHAR(255) DEFAULT NULL,
  `tarikh` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `animal_id` INT UNSIGNED DEFAULT NULL,
  `animal_name` VARCHAR(120) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `reports_status_idx` (`status`),
  KEY `reports_tarikh_idx` (`tarikh`),
  KEY `reports_animal_id_idx` (`animal_id`),
  CONSTRAINT `reports_animal_fk` FOREIGN KEY (`animal_id`) REFERENCES `animals` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
