<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

function respond($statusCode, array $body) {
    http_response_code($statusCode);
    echo json_encode($body, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(405, ['status' => 'error', 'message' => 'Only POST requests are allowed.']);
}

$apiKey = getenv('GEMINI_API_KEY');
if (!$apiKey && isset($_SERVER['GEMINI_API_KEY'])) {
    $apiKey = $_SERVER['GEMINI_API_KEY'];
}
if (!$apiKey) {
    respond(503, [
        'status' => 'error',
        'message' => 'Online animal identification is not configured on the server.',
    ]);
}

// Limit unauthenticated image scans from a single client address.
$rateFile = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'wildlife-ai-' .
    hash('sha256', $_SERVER['REMOTE_ADDR'] ?? 'unknown') . '.json';
$rateHandle = fopen($rateFile, 'c+');
if ($rateHandle === false || !flock($rateHandle, LOCK_EX)) {
    if ($rateHandle) fclose($rateHandle);
    respond(503, ['status' => 'error', 'message' => 'Online identification is temporarily unavailable.']);
}
$rateContents = stream_get_contents($rateHandle);
$recentRequests = json_decode($rateContents ?: '[]', true);
if (!is_array($recentRequests)) $recentRequests = [];
$cutoff = time() - 3600;
$recentRequests = array_values(array_filter($recentRequests, function ($timestamp) use ($cutoff) {
    return is_int($timestamp) && $timestamp > $cutoff;
}));
if (count($recentRequests) >= 20) {
    flock($rateHandle, LOCK_UN);
    fclose($rateHandle);
    respond(429, ['status' => 'error', 'message' => 'Too many identification scans. Please try again later.']);
}
$recentRequests[] = time();
rewind($rateHandle);
ftruncate($rateHandle, 0);
fwrite($rateHandle, json_encode($recentRequests));
flock($rateHandle, LOCK_UN);
fclose($rateHandle);

if (!extension_loaded('curl')) {
    respond(503, ['status' => 'error', 'message' => 'The server HTTP client is unavailable.']);
}
if (!isset($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
    respond(400, ['status' => 'error', 'message' => 'A camera image is required.']);
}

$image = $_FILES['image'];
if ($image['size'] < 1 || $image['size'] > 12 * 1024 * 1024) {
    respond(413, ['status' => 'error', 'message' => 'The image must be smaller than 12 MB.']);
}
$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mimeType = finfo_file($finfo, $image['tmp_name']);
finfo_close($finfo);
$allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
if (!in_array($mimeType, $allowedTypes, true)) {
    respond(415, ['status' => 'error', 'message' => 'Please send a JPEG, PNG, or WebP photo.']);
}

$prompt = <<<'PROMPT'
Identify the wild animal that is clearly visible in this photograph. The photo was taken in Brunei Darussalam or nearby Borneo. Identify a species even if it is not in a local app catalog, but do not guess when the image is unclear, shows no animal, or only supports a broad group. Return only a JSON object with these fields:
{"is_animal":true,"common_name":"English common name","scientific_name":"Latin binomial or empty string","category":"Bird, Mammal, Reptile, Amphibian, Fish, or Other","confidence":0.0,"malay_name":"Malay common name if known, otherwise a careful descriptive name","introduction_ms":"One or two short Malay sentences introducing the animal, or empty string","habitat_ms":"Short Malay habitat description or empty string"}
Confidence must be a number from 0 to 1 and reflect visual certainty. If uncertain, set is_animal to false, common_name to an empty string, and confidence below 0.6. Do not infer a precise species from a generic appearance alone.
PROMPT;

$requestBody = [
    'contents' => [[
        'parts' => [
            ['text' => $prompt],
            ['inline_data' => [
                'mime_type' => $mimeType,
                'data' => base64_encode(file_get_contents($image['tmp_name'])),
            ]],
        ],
    ]],
    'generationConfig' => [
        'responseMimeType' => 'application/json',
        'temperature' => 0.1,
        'maxOutputTokens' => 500,
    ],
];

$responseBody = false;
$httpCode = 0;
$curlError = '';
$providerStatus = '';
$providerMessage = '';
$models = ['gemini-3.5-flash-lite', 'gemini-3.6-flash'];

foreach ($models as $model) {
    $url = 'https://generativelanguage.googleapis.com/v1beta/models/' .
        $model . ':generateContent';
    $curl = curl_init($url);
    curl_setopt_array($curl, [
        CURLOPT_POST => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CONNECTTIMEOUT => 10,
        CURLOPT_TIMEOUT => 35,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'x-goog-api-key: ' . $apiKey,
        ],
        CURLOPT_POSTFIELDS => json_encode($requestBody, JSON_UNESCAPED_UNICODE),
    ]);
    $responseBody = curl_exec($curl);
    $httpCode = (int) curl_getinfo($curl, CURLINFO_HTTP_CODE);
    $curlError = curl_error($curl);
    curl_close($curl);

    if ($responseBody !== false && $httpCode >= 200 && $httpCode < 300) {
        break;
    }

    $providerError = json_decode((string) $responseBody, true);
    $providerStatus = $providerError['error']['status'] ?? '';
    $providerMessage = $providerError['error']['message'] ?? '';
    error_log(
        'Gemini animal identification failed on ' . $model . ': ' .
        ($curlError ?: 'HTTP ' . $httpCode) .
        ($providerStatus ? ' ' . $providerStatus : '') .
        ($providerMessage ? ' - ' . substr(strip_tags($providerMessage), 0, 240) : '')
    );

    if (!in_array($httpCode, [404, 429, 500, 503], true)) {
        break;
    }
}

if ($responseBody === false || $httpCode < 200 || $httpCode >= 300) {
    if (in_array($httpCode, [429, 500, 503], true)) {
        respond(503, [
            'status' => 'error',
            'message' => 'The online identification service is busy. Please try the scan again shortly.',
        ]);
    }
    respond(502, [
        'status' => 'error',
        'message' => 'The online identification service could not process this photo.',
    ]);
}

$providerResponse = json_decode($responseBody, true);
$modelText = $providerResponse['candidates'][0]['content']['parts'][0]['text'] ?? '';
$identified = json_decode($modelText, true);
if (!is_array($identified)) {
    error_log('Gemini animal identification returned an invalid response.');
    respond(502, ['status' => 'error', 'message' => 'The online identification service returned an invalid result.']);
}

$confidence = isset($identified['confidence']) && is_numeric($identified['confidence'])
    ? max(0, min(1, (float) $identified['confidence']))
    : 0;
$commonName = trim((string) ($identified['common_name'] ?? ''));
if (empty($identified['is_animal']) || $confidence < 0.6 || $commonName === '') {
    respond(200, [
        'status' => 'unidentified',
        'message' => 'The online scan could not confidently identify an animal. The report can still be sent for wildlife team review.',
    ]);
}

respond(200, [
    'status' => 'identified',
    'animal' => [
        'name' => $commonName,
        'scientific_name' => trim((string) ($identified['scientific_name'] ?? '')),
        'category' => trim((string) ($identified['category'] ?? 'Wildlife')),
        'confidence' => $confidence,
        'malay_name' => trim((string) ($identified['malay_name'] ?? '')),
        'introduction_ms' => trim((string) ($identified['introduction_ms'] ?? '')),
        'habitat_ms' => trim((string) ($identified['habitat_ms'] ?? '')),
        'source' => 'online_ai',
    ],
    'message' => 'Online AI found a likely species match. Wildlife staff should verify the identification.',
]);
