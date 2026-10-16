<?php
session_start();
if (!isset($_SESSION['id'])) { header('Location: indexadmin.php'); exit; }
include '../wildlife_api/Database/connectionDB.php';


if (isset($_POST['resolvebutton'])) {
    $resolve_id = (int)$_POST['resolve_id'];
    

    $checkColumn = mysqli_query($connection, "SHOW COLUMNS FROM reports LIKE 'status'");
    if (mysqli_num_rows($checkColumn) == 0) {
        mysqli_query($connection, "ALTER TABLE reports ADD COLUMN status VARCHAR(20) DEFAULT 'pending' AFTER location");
    }
    
    $update_query = "UPDATE reports SET status = 'resolved' WHERE id = ?";
    $stmt = mysqli_prepare($connection, $update_query);
    mysqli_stmt_bind_param($stmt, "i", $resolve_id);
    
    if (mysqli_stmt_execute($stmt)) {
        header("Location: manageuser.php?msg=resolved");
        exit;
    } else {
        echo "Error: " . mysqli_error($connection);
    }
    mysqli_stmt_close($stmt);
}

if (isset($_POST['unresolvebutton'])) {
    $unresolve_id = (int)$_POST['unresolve_id'];
    
    $update_query = "UPDATE reports SET status = 'pending' WHERE id = ?";
    $stmt = mysqli_prepare($connection, $update_query);
    mysqli_stmt_bind_param($stmt, "i", $unresolve_id);
    
    if (mysqli_stmt_execute($stmt)) {
        header("Location: manageuser.php?msg=unresolved");
        exit;
    } else {
        echo "Error: " . mysqli_error($connection);
    }
    mysqli_stmt_close($stmt);
}


if (isset($_POST['deletebutton'])) {
    $delete_id = (int)$_POST['delete_id'];
    
    
    $query = "SELECT picture_path FROM reports WHERE id = ?";
    $stmt = mysqli_prepare($connection, $query);
    mysqli_stmt_bind_param($stmt, "i", $delete_id);
    mysqli_stmt_execute($stmt);
    $result = mysqli_stmt_get_result($stmt);
    $row = mysqli_fetch_assoc($result);
    mysqli_stmt_close($stmt);
    

    if (!empty($row['picture_path']) && file_exists("../" . $row['picture_path'])) {
        unlink("../" . $row['picture_path']);
    }
    
    
    $delete_query = "DELETE FROM reports WHERE id = ?";
    $stmt = mysqli_prepare($connection, $delete_query);
    mysqli_stmt_bind_param($stmt, "i", $delete_id);
    
    if (mysqli_stmt_execute($stmt)) {
        header("Location: manageuser.php?msg=deleted");
        exit;
    } else {
        echo "Error: " . mysqli_error($connection);
    }
    mysqli_stmt_close($stmt);
}

mysqli_close($connection);
?>
