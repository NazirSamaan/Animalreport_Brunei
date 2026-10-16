<?php
session_start();
include "../wildlife_api/Database/connectionDB.php"; 


function validate($data) {
    $data = trim($data);
    $data = stripslashes($data);
    $data = htmlspecialchars($data);
    return $data;
}

if (isset($_POST['Username']) && isset($_POST['Password'])) {
    $username = validate($_POST['Username']);
    $password = validate($_POST['Password']);

    if (empty($username) || empty($password)) {
        header("Location: indexadmin.php?error=Username and Password are required");
        exit();
    }

    
    $stmt = $connection->prepare("SELECT * FROM admin WHERE username = ? AND password = ?");
    $stmt->bind_param("ss", $username, $password);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $_SESSION['id'] = $row['id'];
        $_SESSION['username'] = $row['username'];
        header("Location: dashboard.php");
        exit();
    } else {
        header("Location: indexadmin.php?error=Incorrect Username or Password");
        exit();
    }
}
?>
