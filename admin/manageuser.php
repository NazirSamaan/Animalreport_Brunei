<?php
session_start();
if (!isset($_SESSION['id'])) { header('Location: indexadmin.php'); exit; }
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Incident reports &middot; WildlifeCare CRM</title>
    <link rel="stylesheet" href="crm.css?v=typography-unified-29">
</head>
   
<body>
    <div class="container">
        <?php include 'sidebar.php'; ?>

        <main class="main-content">
            <div class="page-heading"><div><div class="eyebrow">Community response</div><h1>Incident reports</h1><p>Review wildlife encounters, field evidence and follow-up status.</p></div><a class="button-primary" href="animals.php">Open animal library <svg aria-hidden="true" viewBox="0 0 24 24"><path d="M4 12h15M13 5l7 7-7 7"/></svg></a></div>
            <div class="Userboxs">
                    <?php 
                    include '../wildlife_api/Database/connectionDB.php';

                    $search = trim($_GET['q'] ?? '');
                    if ($search !== '') {
                        $query_run = $connection->prepare("SELECT * FROM reports WHERE fullname LIKE ? OR location LIKE ? OR aduan LIKE ? OR animal_name LIKE ? OR contact LIKE ? ORDER BY id DESC");
                        $term = '%' . $search . '%';
                        $query_run->bind_param('sssss', $term, $term, $term, $term, $term);
                        $query_run->execute();
                        $query_run = $query_run->get_result();
                    } else {
                        $query_run = mysqli_query($connection, "SELECT * FROM reports ORDER BY id DESC");
                    }
                    ?>
                    
                    <div class="table-toolbar"><input id="reportSearch" class="toolbar-search" type="search" placeholder="Filter this list..."><span class="result-count"><?=mysqli_num_rows($query_run)?> matching reports</span></div>
                    <div class="table-container">
                        <table class="professional-table">
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Full Name</th>
                                    <th>Contact</th>
                                    <th>Tarikh</th> 
                                    <th>GPS</th>
                                    <th>Location</th>
                                    <th>Aduan</th>
                                    <th>Animal</th>
                                    <th>Picture</th>
                                    <th>Status</th>
                                    <th>Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php
                                if (mysqli_num_rows($query_run) > 0) {
                                    while ($row = mysqli_fetch_array($query_run)) {
                                        $status = isset($row['status']) && !empty($row['status']) ? $row['status'] : 'pending';
                                        $isResolved = ($status == 'resolved');
                                        $rowClass = $isResolved ? 'resolved-row' : 'pending-row';
                                        
                                        $latitude = htmlspecialchars($row['latitude']);
                                        $longitude = htmlspecialchars($row['longitude']);
                                        $gps = $latitude . ', ' . $longitude;
                                        
                                    
                                        $aduan = isset($row['aduan']) && !empty($row['aduan']) && $row['aduan'] != '0'
                                            ? htmlspecialchars($row['aduan']) 
                                            : '-';
                                        
                                        
                                        $tarikh = isset($row['tarikh']) && !empty($row['tarikh']) && $row['tarikh'] != '0000-00-00 00:00:00'
                                            ? htmlspecialchars($row['tarikh'])
                                            : '-';
                                        ?>
                                        <tr class="<?php echo $rowClass; ?> report-row">
                                            <td>
                                                <span class="id-badge"><?php echo htmlspecialchars($row['id']); ?></span>
                                            </td>
                                            <td><?php echo htmlspecialchars($row['fullname']); ?></td>
                                            <td><?php echo htmlspecialchars($row['contact']); ?></td>
                                            
                                        
                                            <td class="tarikh-cell">
                                                <?php if ($tarikh != '-'): ?>
                                                    <i class="fa fa-calendar" style="color: #07492b; margin-right: 5px;"></i>
                                                    <?php echo $tarikh; ?>
                                                <?php else: ?>
                                                    <span style="color: #999;"><?php echo $tarikh; ?></span>
                                                <?php endif; ?>
                                            </td>

                                            <td class="gps-cell" title="Lat: <?php echo $latitude; ?>, Lon: <?php echo $longitude; ?>">
                                                <i class="fa fa-map-marker" style="color: #07492b; margin-right: 5px;"></i>
                                                <?php echo $gps; ?>
                                            </td>
                                            <td class="location-cell" title="<?php echo htmlspecialchars($row['location']); ?>">
                                                <?php echo htmlspecialchars($row['location']); ?>
                                            </td>
                                            <td class="aduan-cell" title="<?php echo $aduan; ?>">
                                                <?php echo $aduan; ?>
                                            </td>
                                            <td><?php echo !empty($row['animal_name']) ? htmlspecialchars($row['animal_name']) : '-'; ?></td>
                                            
                                            <td class="image-cell">
                                                <?php if (!empty($row['picture_path'])): ?>
                                                    <a href="../wildlife_api/<?php echo htmlspecialchars($row['picture_path']); ?>" target="_blank">
                                                        <img src="../wildlife_api/<?php echo htmlspecialchars($row['picture_path']); ?>" 
                                                            alt="Report Image" 
                                                            class="report-image">
                                                    </a>
                                                <?php else: ?>
                                                    <span style="color: #999; font-size: 13px;">No Image</span>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <?php if ($isResolved): ?>
                                                    <span class="status-badge status-resolved">
                                                        <i class="fa fa-check-circle"></i> Resolved
                                                    </span>
                                                <?php else: ?>
                                                    <span class="status-badge status-pending">
                                                        <i class="fa fa-clock-o"></i> Pending
                                                    </span>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <div class="action-buttons">
                                                    <?php if ($isResolved): ?>
                                                        <form action="reportmanagement.php" method="post" style="display: inline;">
                                                            <input type="hidden" name="unresolve_id" value="<?php echo $row['id']; ?>">
                                                            <button type="submit" name="unresolvebutton" class="unresolve-btn" 
                                                                    onClick="return confirm('Mark this report as pending/unresolved?')">
                                                                <i class="fa fa-undo"></i> Unresolve
                                                            </button>
                                                        </form>
                                                        <form action="reportmanagement.php" method="post" style="display: inline;">
                                                            <input type="hidden" name="delete_id" value="<?php echo $row['id']; ?>">
                                                            <button type="submit" name="deletebutton" class="delete-btn" 
                                                                    onClick="return confirm('Are you sure you want to delete this report?')">
                                                                <i class="fa fa-trash"></i> Delete
                                                            </button>
                                                        </form>
                                                    <?php else: ?>
                                                        <form action="reportmanagement.php" method="post" style="display: inline;">
                                                            <input type="hidden" name="resolve_id" value="<?php echo $row['id']; ?>">
                                                            <button type="submit" name="resolvebutton" class="resolve-btn" 
                                                                    onClick="return confirm('Mark this report as resolved?')">
                                                                <i class="fa fa-check-circle"></i> Resolve
                                                            </button>
                                                        </form>
                                                    <?php endif; ?>
                                                </div>
                                            </td>
                                        </tr>
                                        <?php
                                    }
                                } else {
                                    echo '<tr><td colspan="11">
                                            <div class="empty-state">
                                                <i class="fa fa-inbox"></i>
                                                <p>No reports found</p>
                                            </div>
                                            </td></tr>';
                                }
                                ?>
                            </tbody>
                        </table>
                    </div>
            </div>
        </main>
    </div>
    <script>
    document.getElementById('reportSearch').addEventListener('input', function () {
        const term = this.value.trim().toLowerCase();
        document.querySelectorAll('.report-row').forEach(row => { row.hidden = !row.innerText.toLowerCase().includes(term); });
    });
    </script>
</body>
</html>
