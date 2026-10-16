<?php
$host = getenv('DB_HOST') ?: 'localhost';
$user = getenv('DB_USER') ?: 'root';
$password = getenv('DB_PASSWORD') !== false ? getenv('DB_PASSWORD') : '';
$database = getenv('DB_NAME') ?: 'wildlife';
$port = (int)(getenv('DB_PORT') ?: 3306);

mysqli_report(MYSQLI_REPORT_OFF);
$connection = mysqli_connect($host, $user, $password, $database, $port);

if (!$connection) {
    http_response_code(500);
    die(json_encode(["status" => "error", "message" => "Connection failed"]));
}
$connection->set_charset('utf8mb4');
?>
