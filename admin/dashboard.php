<?php
session_start();
if (!isset($_SESSION['id'])) { header('Location: indexadmin.php'); exit; }
require '../wildlife_api/Database/connectionDB.php';
function countRows($connection, $sql) {
    $result = $connection->query($sql);
    return $result ? (int)$result->fetch_row()[0] : 0;
}
$reports = countRows($connection, 'SELECT COUNT(*) FROM reports');
$pending = countRows($connection, "SELECT COUNT(*) FROM reports WHERE status IS NULL OR status <> 'resolved'");
$animals = countRows($connection, 'SELECT COUNT(*) FROM animals');
$published = countRows($connection, 'SELECT COUNT(*) FROM animals WHERE is_published=1');
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Overview &middot; WildlifeCare CRM</title>
    <link rel="stylesheet" href="crm.css?v=typography-unified-29">
</head>
<body>
<div class="container">
    <?php include 'sidebar.php'; ?>
    <main class="main-content">
        <header class="page-heading overview-heading">
            <div>
                <div class="eyebrow">Operations workspace</div>
                <h1>Wildlife overview</h1>
                <p>Monitor community reports and keep the animal guide up to date.</p>
            </div>
            <a class="button-primary overview-review-button" href="manageuser.php">Review reports
                <svg aria-hidden="true" viewBox="0 0 24 24"><path d="M4 12h15M13 5l7 7-7 7"/></svg>
            </a>
        </header>

        <section class="dashboard-grid" aria-label="Wildlife operations summary">
            <article class="metric">
                <div class="metric-heading"><span>Total incident reports</span><span class="metric-icon metric-icon-purple" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M7 3.8h7l4 4V20H7a2 2 0 0 1-2-2V5.8a2 2 0 0 1 2-2Z"/><path d="M14 4v5h5M8.5 13h7M8.5 16.5h7"/></svg></span></div>
                <strong><?=$reports?></strong><small>All submissions received</small>
            </article>
            <article class="metric">
                <div class="metric-heading"><span>Awaiting review</span><span class="metric-icon metric-icon-amber" aria-hidden="true"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8.5"/><path d="M12 7v5l3.5 2"/></svg></span></div>
                <strong><?=$pending?></strong><small>Open cases needing attention</small>
            </article>
            <article class="metric">
                <div class="metric-heading"><span>Animal profiles</span><span class="metric-icon metric-icon-teal" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M12 20s-7-4.2-7-9.3a4.2 4.2 0 0 1 7-3.1 4.2 4.2 0 0 1 7 3.1C19 15.8 12 20 12 20Z"/><path d="M9 12.5h6M12 9.5v6"/></svg></span></div>
                <strong><?=$animals?></strong><small>Species in your library</small>
            </article>
            <article class="metric">
                <div class="metric-heading"><span>Published to app</span><span class="metric-icon metric-icon-green" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M5 19V9l7-5 7 5v10M9 19v-6h6v6M3 19h18"/></svg></span></div>
                <strong><?=$published?></strong><small>Visible to mobile users</small>
            </article>
        </section>

        <section class="dashboard-lower">
            <article class="panel">
                <div class="panel-heading"><h2>Operations workspace</h2><span class="result-count">QUICK ACCESS</span></div>
                <a class="quick-link" href="manageuser.php">
                    <span class="quick-icon" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M7 3.8h7l4 4V20H7a2 2 0 0 1-2-2V5.8a2 2 0 0 1 2-2Z"/><path d="M14 4v5h5M8.5 13h7M8.5 16.5h7"/></svg></span>
                    <span><strong>Incident reports</strong><small>Review evidence, location, species and resolution status</small></span>
                    <svg class="quick-arrow" aria-hidden="true" viewBox="0 0 24 24"><path d="M4 12h15M13 5l7 7-7 7"/></svg>
                </a>
                <a class="quick-link" href="animals.php">
                    <span class="quick-icon quick-icon-green" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M12 20s-7-4.2-7-9.3a4.2 4.2 0 0 1 7-3.1 4.2 4.2 0 0 1 7 3.1C19 15.8 12 20 12 20Z"/><path d="M9 12.5h6M12 9.5v6"/></svg></span>
                    <span><strong>Animal library</strong><small>Manage species profiles, conservation details and posters</small></span>
                    <svg class="quick-arrow" aria-hidden="true" viewBox="0 0 24 24"><path d="M4 12h15M13 5l7 7-7 7"/></svg>
                </a>
            </article>
            <article class="panel field-reporting-panel">
                <div class="panel-heading"><h2>Field reporting</h2><span class="quick-icon quick-icon-green" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M19 10c0 5-7 11-7 11S5 15 5 10a7 7 0 1 1 14 0Z"/><circle cx="12" cy="10" r="2.2"/></svg></span></div>
                <p>Mobile reports include captured evidence and GPS coordinates, so teams can assess wildlife encounters with useful context.</p>
                <div class="gps-active"><i aria-hidden="true"></i> GPS-enabled reporting is active</div>
            </article>
        </section>
    </main>
</div>
</body>
</html>
