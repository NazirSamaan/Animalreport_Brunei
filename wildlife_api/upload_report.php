<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
include "Database/connectionDB.php";

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Only POST requests allowed"]);
    exit;
}

$required = ['fullname', 'contact', 'aduan', 'latitude', 'longitude'];
foreach ($required as $field) {
    if (empty($_POST[$field])) {
        echo json_encode(["status" => "error", "message" => "Missing field: $field"]);
        exit;
    }
}

$fullname = trim($_POST['fullname']);
$contact  = trim($_POST['contact']);
$aduan    = trim($_POST['aduan']);
$lat      = trim($_POST['latitude']);
$lon      = trim($_POST['longitude']);
$location = trim($_POST['location'] ?? 'Unknown Location');
$tarikh   = trim($_POST['tarikh'] ?? date('Y-m-d H:i:s'));
$animalId = isset($_POST['animal_id']) && ctype_digit((string)$_POST['animal_id']) ? (int)$_POST['animal_id'] : null;
$animalName = trim($_POST['animal_name'] ?? '');


if (!preg_match('/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/', $tarikh)) {
    $tarikh = date('Y-m-d H:i:s');
}

if (!is_numeric($lat) || !is_numeric($lon)) {
    echo json_encode(["status" => "error", "message" => "Invalid GPS coordinates"]);
    exit;
}

if (!isset($_FILES['picture']) || $_FILES['picture']['error'] !== UPLOAD_ERR_OK) {
    echo json_encode(["status" => "error", "message" => "File upload error"]);
    exit;
}

$allowedMimes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mimeType = finfo_file($finfo, $_FILES['picture']['tmp_name']);
finfo_close($finfo);
$ext = strtolower(pathinfo($_FILES['picture']['name'], PATHINFO_EXTENSION));

if (!in_array($mimeType, $allowedMimes)) {
    echo json_encode(["status" => "error", "message" => "Invalid file type"]);
    exit;
}

$target_dir = "uploads/";
if (!file_exists($target_dir)) {
    mkdir($target_dir, 0755, true);
}

$safeFilename = time() . "_" . bin2hex(random_bytes(8)) . "." . $ext;
$target_file = $target_dir . $safeFilename;

if (!move_uploaded_file($_FILES['picture']['tmp_name'], $target_file)) {
    echo json_encode(["status" => "error", "message" => "Failed to save file"]);
    exit;
}

$stmt = $connection->prepare(
    "INSERT INTO reports (fullname, latitude, longitude, location, contact, aduan, picture_path, tarikh, animal_id, animal_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
);

if (!$stmt) {
    unlink($target_file);
    echo json_encode(["status" => "error", "message" => "DB prepare failed"]);
    exit;
}

$stmt->bind_param("ssssssssis", $fullname, $lat, $lon, $location, $contact, $aduan, $target_file, $tarikh, $animalId, $animalName);

if ($stmt->execute()) {
    echo json_encode([
        "status"  => "success",
        "message" => "Report submitted successfully",
        "id"      => $stmt->insert_id
    ]);
} else {
    unlink($target_file);
    echo json_encode(["status" => "error", "message" => "DB insert failed: " . $stmt->error]);
}

$stmt->close();
$connection->close();
?>
