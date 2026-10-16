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
$password = (string)($input['password'] ?? '');

if ($username === '' || $password === '') {
    http_response_code(422);
    echo json_encode(['status' => 'error', 'message' => 'Enter your username and password.']);
    exit;
}

$stmt = $connection->prepare('SELECT id, username, contact, password_hash FROM user_account WHERE username = ? LIMIT 1');
if (!$stmt) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Could not sign in. Make sure the user_account table has been imported.']);
    exit;
}
$stmt->bind_param('s', $username);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();
$stmt->close();

if (!$user || !password_verify($password, $user['password_hash'])) {
    http_response_code(401);
    echo json_encode(['status' => 'error', 'message' => 'Incorrect username or password.']);
    exit;
}

echo json_encode([
    'status' => 'success',
    'user' => ['id' => (int)$user['id'], 'username' => $user['username'], 'contact' => $user['contact']],
]);
$connection->close();
?>
