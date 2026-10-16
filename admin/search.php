<?php
session_start();
if (!isset($_SESSION['id'])) {
    header('Location: indexadmin.php');
    exit;
}

$query = trim((string)($_GET['q'] ?? ''));
if ($query === '') {
    header('Location: dashboard.php');
    exit;
}

$encodedQuery = rawurlencode($query);
$isOverviewSearch = (bool)preg_match('/\b(overview|dashboard|home)\b/i', $query);
if ($isOverviewSearch) {
    header('Location: dashboard.php');
    exit;
}

$isAnimalSearch = (bool)preg_match('/\b(animal|animals|wildlife|species|fauna)\b/i', $query);

if (!$isAnimalSearch) {
    try {
        require_once '../wildlife_api/Database/connectionDB.php';
        $like = '%' . $query . '%';
        $statement = $connection->prepare('SELECT name, scientific_name, category FROM animals WHERE name LIKE ? OR scientific_name LIKE ? OR category LIKE ?');
        if ($statement) {
            $statement->bind_param('sss', $like, $like, $like);
            $statement->execute();
            $matches = $statement->get_result();
            $isAnimalSearch = $matches && $matches->num_rows > 0;
        }

        // Catch common near-spellings such as "crocidile" when no exact match exists.
        if (!$isAnimalSearch) {
            $terms = preg_split('/[^a-z0-9]+/i', strtolower($query), -1, PREG_SPLIT_NO_EMPTY);
            if ($terms) {
                $animals = $connection->query('SELECT name, scientific_name, category FROM animals');
                if ($animals) {
                    while ($animal = $animals->fetch_assoc()) {
                        $words = preg_split('/[^a-z0-9]+/i', strtolower(implode(' ', $animal)), -1, PREG_SPLIT_NO_EMPTY);
                        foreach ($terms as $term) {
                            if (strlen($term) < 5) continue;
                            $allowedDistance = max(1, (int)floor(strlen($term) * 0.2));
                            foreach ($words as $word) {
                                if (abs(strlen($term) - strlen($word)) <= $allowedDistance && levenshtein($term, $word) <= $allowedDistance) {
                                    $isAnimalSearch = true;
                                    break 3;
                                }
                            }
                        }
                    }
                }
            }
        }
    } catch (Throwable $exception) {
        // Keep search usable for incident reports if the animal catalog is unavailable.
    }
}

header('Location: ' . ($isAnimalSearch ? 'animals.php' : 'manageuser.php') . '?q=' . $encodedQuery);
exit;
