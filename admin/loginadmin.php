<?php
session_start();
require_once __DIR__ . '/../wildlife_api/Database/connectionDB.php';

function rejectAdminLogin() {
    header('Location: indexadmin.php?error=Incorrect%20Username%20or%20Password');
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: indexadmin.php');
    exit;
}
$username = trim((string)($_POST['Username'] ?? ''));
$password = (string)($_POST['Password'] ?? '');
if ($username === '' || $password === '' || $password === 'admin123') {
    rejectAdminLogin();
}
$stmt = $connection->prepare('SELECT id, username, password FROM admin WHERE username = ? LIMIT 1');
$stmt->bind_param('s', $username);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();
if (!$row) rejectAdminLogin();

$stored = (string)$row['password'];
$isHash = password_get_info($stored)['algoName'] !== 'unknown';
$valid = $isHash ? password_verify($password, $stored) : hash_equals($stored, $password);
if (!$valid) rejectAdminLogin();

// Migrate existing plaintext passwords after a successful login.
if (!$isHash || password_needs_rehash($stored, PASSWORD_DEFAULT)) {
    $hash = password_hash($password, PASSWORD_DEFAULT);
    $update = $connection->prepare('UPDATE admin SET password = ? WHERE id = ? AND password = ?');
    $update->bind_param('sis', $hash, $row['id'], $stored);
    if (!$update->execute() || $update->affected_rows !== 1) rejectAdminLogin();
    $update->close();
}
session_regenerate_id(true);
$_SESSION['id'] = $row['id'];
$_SESSION['username'] = $row['username'];
header('Location: dashboard.php');
exit;