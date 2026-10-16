<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
require __DIR__ . '/Database/connectionDB.php';
$result = $connection->query("SELECT id, name, scientific_name, category, description, conservation_status, habitat, image_path, image_credit, poster_path FROM animals WHERE is_published = 1 ORDER BY name");
if (!$result) { http_response_code(500); echo json_encode(['status'=>'error','message'=>'Animal catalog unavailable']); exit; }
$animals = [];
while ($row = $result->fetch_assoc()) $animals[] = $row;
echo json_encode(['status'=>'success','animals'=>$animals]);
$connection->close();
