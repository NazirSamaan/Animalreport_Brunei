<?php
header('Content-Type: application/json');

$host = "localhost";
$user = "root";
$password = "";
$database = "wildlife";



$connection = mysqli_connect($host, $user, $password, $database);

if (!$connection) {
    echo json_encode(["status" => "error", "message" => "Connection failed"]);
    exit;
}
$connection->set_charset('utf8mb4');

// Create uploads folder if not exists
$target_dir = "uploads/";
if (!file_exists($target_dir)) {
    mkdir($target_dir, 0777, true);
}

// Receive Data
$fullname = $_POST['fullname'] ?? 'Unknown';
$lat = $_POST['latitude'] ?? '0.0';
$lon = $_POST['longitude'] ?? '0.0';
$contact = $_POST['contact'] ?? '';

// Handle Image Upload
if (isset($_FILES['picture'])) {
    $file_extension = pathinfo($_FILES['picture']['name'], PATHINFO_EXTENSION);
    $new_filename = time() . '_' . uniqid() . '.' . $file_extension;
    $target_file = $target_dir . $new_filename;

    if (move_uploaded_file($_FILES['picture']['tmp_name'], $target_file)) {
        // Insert into Database using Prepared Statement
        $stmt = $connection->prepare("INSERT INTO reports (fullname, latitude, longitude, contact, picture_path) VALUES (?, ?, ?, ?, ?)");
        $stmt->bind_param("sssss", $fullname, $lat, $lon, $contact, $target_file);
        
        if ($stmt->execute()) {
            echo json_encode(["status" => "success", "message" => "Report saved successfully"]);
        } else {
            echo json_encode(["status" => "error", "message" => "Database error: " . $stmt->error]);
        }
        $stmt->close();
    } else {
        echo json_encode(["status" => "error", "message" => "Failed to move uploaded file"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "No image data received"]);
}

mysqli_close($connection);
?>
