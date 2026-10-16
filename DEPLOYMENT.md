# Online deployment

The application needs HTTPS hosting with PHP, mysqli, MySQL, and persistent
storage for `wildlife_api/uploads`. GitHub stores source code; GitHub Pages
cannot run the PHP backend or MySQL database.

1. Create a MySQL database and a dedicated database user on the host. Configure
   server environment variables `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, and
   `DB_PASSWORD`. Defaults remain compatible with local XAMPP. These variables
   must be visible to PHP; a `.env` file is not automatically loaded.
2. Import `database/wildlife.sql`. For hosting that assigns a database name,
   omit its `CREATE DATABASE` and `USE` statements and import into the assigned
   database. This imports schema and catalog data, not existing local accounts
   or reports. A separate private database export is needed to migrate those.
3. Replace the seeded admin password before exposing the admin interface.
   The starter password is rejected by admin login. Existing plaintext passwords
   are upgraded to password hashes on the first successful sign-in.
4. Upload `admin/` and `wildlife_api/` to the PHP host. Keep uploads persistent
   and disallow script execution in the uploads directory. Transfer existing
   private uploads separately if migrating live records. Only catalog images
   are included in Git. Deny web access to source SQL and configuration files.
5. Run `flutter pub get`, then build the frontend with the real public API URL:

   ```powershell
   flutter build web --release --dart-define=API_BASE_URL=https://YOUR-DOMAIN/wildlife_api
   ```

6. Upload the contents of `build/web/` to the web root, keeping `admin/` and
   `wildlife_api/` alongside it. Enable HTTPS. Camera and location access in a
   public browser require a secure origin.
7. Verify the public app, `wildlife_api/animals.php`, registration, login,
   reporting, image uploads, and the admin interface from another network.
   `lib/main.dart` currently references `get_reports.php`, which is absent;
   that reporting path needs implementation before full feature verification.
8. Configure database and upload backups and host uptime monitoring. Availability
   depends on the hosting service and cannot be guaranteed by a Git push.

Do not commit database exports containing user records, credentials, or report
evidence. No public deployment has been configured by these instructions.
