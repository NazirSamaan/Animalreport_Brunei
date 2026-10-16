<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Only POST requests are allowed.']);
    exit;
}

require_once __DIR__ . '/Database/connectionDB.php';
$input = json_decode(file_get_contents('php://input'), true) ?? [];
$username = trim((string)($input['username'] ?? ''));
$digits = preg_replace('/\D+/', '', (string)($input['contact'] ?? ''));
$password = (string)($input['password'] ?? '');

if (!preg_match('/^[A-Za-z0-9_]{3,30}$/', $username)) {
    http_response_code(422);
    echo json_encode(['status' => 'error', 'message' => 'Username must be 3–30 characters and use only letters, numbers, or underscores.']);
    exit;
}
if (str_starts_with($digits, '673') && strlen($digits) === 10) {
    $digits = substr($digits, 3);
}
if (!preg_match('/^[78][0-9]{6}$/', $digits)) {
    http_response_code(422);
    echo json_encode(['status' => 'error', 'message' => 'Enter a valid 7-digit Brunei mobile number beginning with 7 or 8.']);
    exit;
}
if (strlen($password) < 8) {
    http_response_code(422);
    echo json_encode(['status' => 'error', 'message' => 'Password must be at least 8 characters.']);
    exit;
}

$contact = '+673' . $digits;
$passwordHash = password_hash($password, PASSWORD_DEFAULT);
$stmt = $connection->prepare('INSERT INTO user_account (username, contact, password_hash) VALUES (?, ?, ?)');
if (!$stmt) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Could not create the account. Make sure the user_account table has been imported.']);
    exit;
}
$stmt->bind_param('sss', $username, $contact, $passwordHash);
if (!$stmt->execute()) {
    if ($stmt->errno === 1062) {
        http_response_code(409);
        echo json_encode(['status' => 'error', 'message' => 'That username or contact number is already registered.']);
    } else {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Account registration failed. Please try again.']);
    }
    $stmt->close();
    exit;
}

echo json_encode([
    'status' => 'success',
    'message' => 'Your account is ready.',
    'user' => ['id' => $stmt->insert_id, 'username' => $username, 'contact' => $contact],
]);
$stmt->close();
$connection->close();
?>
