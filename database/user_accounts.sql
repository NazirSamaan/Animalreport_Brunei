-- Run this once in phpMyAdmin against the existing `wildlife` database.
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

-- Preserve accounts created with the earlier `users` table, when it exists.
SET @legacy_users_exist = (
  SELECT COUNT(*) FROM information_schema.tables
  WHERE table_schema = DATABASE() AND table_name = 'users'
);
SET @copy_legacy_users = IF(
  @legacy_users_exist > 0,
  'INSERT IGNORE INTO `user_account` (`id`, `username`, `contact`, `password_hash`, `created_at`) SELECT `id`, `username`, `contact`, `password_hash`, `created_at` FROM `users`',
  'SELECT 1'
);
PREPARE copy_users_stmt FROM @copy_legacy_users;
EXECUTE copy_users_stmt;
DEALLOCATE PREPARE copy_users_stmt;
