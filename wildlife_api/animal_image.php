<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    exit;
}

// Wikimedia-hosted catalog photos are proxied so the mobile client can use
// the same API origin as local uploads. Only Commons URLs and its upload host
// are accepted; redirects are checked before the destination is fetched.
if (isset($_GET['url'])) {
    $remoteUrl = trim((string)$_GET['url']);
    $remoteParts = parse_url($remoteUrl);
    if (($remoteParts['scheme'] ?? '') !== 'https' ||
        strtolower($remoteParts['host'] ?? '') !== 'commons.wikimedia.org') {
        http_response_code(400);
        exit;
    }
    if (!function_exists('curl_init')) {
        http_response_code(503);
        exit;
    }

    $fetch = static function (string $url, ?string &$location = null) {
        $curl = curl_init($url);
        curl_setopt_array($curl, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => false,
            CURLOPT_CONNECTTIMEOUT => 8,
            CURLOPT_TIMEOUT => 18,
            CURLOPT_PROTOCOLS => CURLPROTO_HTTPS,
            CURLOPT_USERAGENT => 'BruneiGoOnlineApps wildlife guide/1.0',
            CURLOPT_HEADERFUNCTION => static function ($curl, string $header) use (&$location) {
                if (stripos($header, 'Location:') === 0) {
                    $location = trim(substr($header, 9));
                }
                return strlen($header);
            },
        ]);
        $body = curl_exec($curl);
        $status = (int)curl_getinfo($curl, CURLINFO_HTTP_CODE);
        $mime = (string)curl_getinfo($curl, CURLINFO_CONTENT_TYPE);
        curl_close($curl);
        return [$body, $status, $mime];
    };

    $location = null;
    [$imageData, $status, $mime] = $fetch($remoteUrl, $location);
    if ($status >= 300 && $status < 400 && $location) {
        $destination = parse_url($location);
        if (($destination['scheme'] ?? '') !== 'https' ||
            strtolower($destination['host'] ?? '') !== 'upload.wikimedia.org') {
            http_response_code(502);
            exit;
        }
        $imageData = null;
        [$imageData, $status, $mime] = $fetch($location);
    }

    $allowed = ['image/jpeg', 'image/png', 'image/webp'];
    if ($status !== 200 || !is_string($imageData) || strlen($imageData) > 8 * 1024 * 1024 ||
        !in_array(strtolower(trim(explode(';', $mime)[0])), $allowed, true)) {
        http_response_code(502);
        exit;
    }
    header('Content-Type: ' . strtolower(trim(explode(';', $mime)[0])));
    header('Content-Length: ' . strlen($imageData));
    header('Cache-Control: public, max-age=86400');
    echo $imageData;
    exit;
}

$file = basename((string)($_GET['file'] ?? ''));
if (!preg_match('/^[A-Za-z0-9_-]+\.(jpg|jpeg|png|webp)$/i', $file)) {
    http_response_code(400);
    exit;
}

$imageDirectory = realpath(__DIR__ . '/uploads/animals');
$imagePath = $imageDirectory === false ? false : realpath($imageDirectory . DIRECTORY_SEPARATOR . $file);
if ($imagePath === false || !str_starts_with($imagePath, $imageDirectory . DIRECTORY_SEPARATOR) || !is_file($imagePath)) {
    http_response_code(404);
    exit;
}

$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mime = $finfo ? finfo_file($finfo, $imagePath) : false;
if ($finfo) finfo_close($finfo);
$allowed = ['image/jpeg', 'image/png', 'image/webp'];
if (!in_array($mime, $allowed, true)) {
    http_response_code(415);
    exit;
}

header('Content-Type: ' . $mime);
header('Content-Length: ' . filesize($imagePath));
header('Cache-Control: public, max-age=3600');
readfile($imagePath);
?>
