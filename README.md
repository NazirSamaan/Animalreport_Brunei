# Brunei Go Online Apps

Flutter wildlife education and incident reporting app with a PHP/MySQL backend and a PHP admin CRM.

## Local setup (XAMPP)

1. Place this project under `C:\xampp\htdocs\BruneiGoOnlineApps` and start Apache and MySQL.
2. In phpMyAdmin, use **Import** to import `database/wildlife.sql`. It creates the `wildlife` database and the `admin`, `user_account`, `reports` and `animals` tables, and seeds a curated Brunei wildlife catalog with locally stored photos. The seed corrects the old Australian freshwater-crocodile sample, updates photos for previously imported profiles, and is safe to re-import without duplicating species. Image attributions are listed in `database/brunei_wildlife_photo_credits.md`. If the database already exists, import `database/user_accounts.sql` into `wildlife` as needed to add `user_account` and migrate earlier user entries.
3. The starter CRM login is `admin` / `admin123`. Change the password in phpMyAdmin before using this beyond local development.
4. The PHP connection defaults to MySQL `localhost`, user `root`, no password, database `wildlife`. Update `wildlife_api/Database/connectionDB.php` if your local credentials differ.
5. Sign in at `/BruneiGoOnlineApps/admin/` using the existing admin account. The CRM has Animal library and incident report screens.
6. Set `baseUrl` in `lib/main.dart` to the machine address reachable by the phone. Android emulators can use `10.0.2.2`; a physical phone needs the computer's LAN IP. HTTP access must be enabled for local development.
7. Run `flutter pub get`, then launch the Flutter app. Camera and location permissions are already declared for Android.

## Features

- Admin animal profiles: create, edit, publish or remove animal records; upload profile photos and educational poster images.
- Mobile wildlife field guide: displays published species, descriptions, habitats and conservation status from PHP.
- Incident reports: capture evidence with GPS, provide contact and complaint details, and associate an optional animal profile.
- Mobile accounts: register with a username, Brunei mobile number and password, or continue as a guest. Account passwords are stored as password hashes. Signed-in account details are automatically attached to reports; guests enter their own contact details.

The Flutter app reads animal profiles from `wildlife_api/animals.php`, which uses the same `wildlife.animals` table managed by `admin/animals.php`. The development API address defaults to `http://192.168.100.17/BruneiGoOnlineApps/wildlife_api`; if the XAMPP computer's Wi-Fi address changes, run Flutter with `--dart-define=API_BASE_URL=http://<computer-ip>/BruneiGoOnlineApps/wildlife_api`. A physical phone and the XAMPP computer must be on the same network.
- Admin incident queue: review report details and evidence, see the linked animal, and resolve or reopen reports.

Animal identification currently uses a user-confirmed catalog selection after photo capture. Automatic species recognition requires integrating and configuring an image classification model; this project does not include one yet.
