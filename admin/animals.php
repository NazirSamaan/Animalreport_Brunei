<?php
session_start();
if (!isset($_SESSION['id'])) { header('Location: indexadmin.php'); exit; }
require_once '../wildlife_api/Database/connectionDB.php';
$connection->set_charset('utf8mb4');
$connection->query("CREATE TABLE IF NOT EXISTS animals (id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, name VARCHAR(120) NOT NULL, scientific_name VARCHAR(160) NULL, category VARCHAR(80) NULL, description TEXT NOT NULL, conservation_status VARCHAR(80) NULL, habitat VARCHAR(255) NULL, image_path VARCHAR(255) NULL, image_credit VARCHAR(255) NULL, poster_path VARCHAR(255) NULL, is_published TINYINT(1) NOT NULL DEFAULT 1, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)");
$creditColumn = $connection->query("SHOW COLUMNS FROM animals LIKE 'image_credit'");
if ($creditColumn && $creditColumn->num_rows === 0) $connection->query('ALTER TABLE animals ADD COLUMN image_credit VARCHAR(255) NULL AFTER image_path');
$error = '';
$formValues = [];
function uploadAnimalImage($field, $existing = '') {
    if (empty($_FILES[$field]['name'])) return $existing;
    if ($_FILES[$field]['error'] !== UPLOAD_ERR_OK || $_FILES[$field]['size'] > 8 * 1024 * 1024) throw new RuntimeException('Images must be under 8 MB.');
    $mime = (new finfo(FILEINFO_MIME_TYPE))->file($_FILES[$field]['tmp_name']);
    $extensions = ['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'];
    if (!isset($extensions[$mime])) throw new RuntimeException('Use a JPG, PNG, or WebP image.');
    $dir = __DIR__ . '/../wildlife_api/uploads/animals';
    if (!is_dir($dir) && !mkdir($dir, 0755, true)) throw new RuntimeException('Could not create the image folder.');
    $name = bin2hex(random_bytes(12)) . '.' . $extensions[$mime];
    if (!move_uploaded_file($_FILES[$field]['tmp_name'], $dir . '/' . $name)) throw new RuntimeException('Image upload failed.');
    return 'uploads/animals/' . $name;
}
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $formValues = $_POST;
    try {
        $id = (int)($_POST['id'] ?? 0);
        if (isset($_POST['delete'])) {
            $stmt = $connection->prepare('DELETE FROM animals WHERE id=?'); $stmt->bind_param('i', $id); $stmt->execute();
            header('Location: animals.php?done=deleted'); exit;
        }
        $name = trim($_POST['name'] ?? ''); $description = trim($_POST['description'] ?? '');
        if ($name === '' || $description === '') throw new RuntimeException('Name and description are required.');
        $current = ['image_path'=>'','image_credit'=>'','poster_path'=>''];
        if ($id) { $stmt=$connection->prepare('SELECT image_path, image_credit, poster_path FROM animals WHERE id=?'); $stmt->bind_param('i',$id); $stmt->execute(); $current=$stmt->get_result()->fetch_assoc() ?: $current; }
        $image = uploadAnimalImage('image', $current['image_path']); $poster = uploadAnimalImage('poster', $current['poster_path']);
        $imageCredit = trim($_POST['image_credit'] ?? '');
        if (empty($_FILES['image']['name']) && $imageCredit === '') $imageCredit = $current['image_credit'];
        $scientific=trim($_POST['scientific_name'] ?? ''); $category=trim($_POST['category'] ?? ''); $status=trim($_POST['conservation_status'] ?? ''); $habitat=trim($_POST['habitat'] ?? ''); $published=isset($_POST['is_published'])?1:0;
        if ($id) { $stmt=$connection->prepare('UPDATE animals SET name=?,scientific_name=?,category=?,description=?,conservation_status=?,habitat=?,image_path=?,image_credit=?,poster_path=?,is_published=? WHERE id=?'); $stmt->bind_param('sssssssssii',$name,$scientific,$category,$description,$status,$habitat,$image,$imageCredit,$poster,$published,$id); }
        else { $stmt=$connection->prepare('INSERT INTO animals (name,scientific_name,category,description,conservation_status,habitat,image_path,image_credit,poster_path,is_published) VALUES (?,?,?,?,?,?,?,?,?,?)'); $stmt->bind_param('sssssssssi',$name,$scientific,$category,$description,$status,$habitat,$image,$imageCredit,$poster,$published); }
        if (!$stmt->execute()) throw new RuntimeException('Could not save this animal profile.');
        header('Location: animals.php?done=saved'); exit;
    } catch (Throwable $e) { $error=$e->getMessage(); }
}
$edit = null;
if (isset($_GET['edit'])) { $id=(int)$_GET['edit']; $stmt=$connection->prepare('SELECT * FROM animals WHERE id=?'); $stmt->bind_param('i',$id); $stmt->execute(); $edit=$stmt->get_result()->fetch_assoc(); }
$animals=$connection->query('SELECT * FROM animals ORDER BY updated_at DESC')->fetch_all(MYSQLI_ASSOC);
function h($v){return htmlspecialchars((string)$v, ENT_QUOTES, 'UTF-8');}
$value = static function(string $key, string $fallback = '') use ($formValues, $edit): string {
    return (string)($formValues[$key] ?? ($edit[$key] ?? $fallback));
};
$isEditing = (int)($formValues['id'] ?? ($edit['id'] ?? 0)) > 0;
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Animal library &middot; Wildlife CRM</title>
    <link rel="stylesheet" href="admin.css">
    <link rel="stylesheet" href="crm.css?v=typography-unified-29">
    <link rel="stylesheet" href="animal-library.css?v=library-gutter-19">
</head>
<body>
<div class="container">
    <?php include 'sidebar.php'; ?>
    <main class="main-content animal-library-page">
        <header class="animal-page-header">
            <div>
                <h1>Animal library</h1>
                <p>Manage the wildlife profiles and learning materials shown in the mobile app.</p>
            </div>
            <button class="animal-primary-button" type="button" data-open-animal-form>
                <span class="animal-add-icon" aria-hidden="true">+</span> Add animal profile
            </button>
        </header>

        <?php if($error): ?><div class="animal-alert" role="alert"><?=h($error)?></div><?php endif; ?>
        <?php if(isset($_GET['done'])): ?><div class="animal-success" role="status"><?=($_GET['done']==='deleted')?'Animal profile deleted.':'Animal profile saved.'?></div><?php endif; ?>

        <section class="animal-library-summary" aria-label="Library summary">
            <div><span class="summary-icon" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M4 7.5 12 3l8 4.5v9L12 21l-8-4.5z"/><path d="m8 9 4-2.3L16 9v5.8L12 17l-4-2.2z"/></svg></span><span><strong><?=count($animals)?></strong><small>Animal profiles</small></span></div>
            <div><span class="summary-icon summary-icon-green" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="m5 12.5 4.3 4.2L19 7"/></svg></span><span><strong><?=count(array_filter($animals, static fn($animal)=>(int)$animal['is_published']===1))?></strong><small>Published in app</small></span></div>
            <label class="animal-search"><svg aria-hidden="true" viewBox="0 0 24 24"><circle cx="10.8" cy="10.8" r="6.8"/><path d="m16 16 5 5"/></svg><input id="animalSearch" type="search" value="<?=h($_GET['q'] ?? '')?>" placeholder="Search profiles by name or category" aria-label="Search animal profiles"></label>
        </section>

        <?php if(!$animals): ?>
            <section class="animal-empty-state"><div aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M12 3v18M3 12h18M5.6 5.6l12.8 12.8m0-12.8L5.6 18.4"/></svg></div><h2>Your wildlife library starts here</h2><p>Add your first species profile to make it available to mobile app users.</p><button class="animal-primary-button" type="button" data-open-animal-form>Add the first profile</button></section>
        <?php else: ?>
            <section class="animal-profile-grid" id="animalProfileGrid" aria-label="Animal profiles">
                <?php foreach($animals as $animal): $searchText=strtolower($animal['name'].' '.($animal['category']??'').' '.($animal['scientific_name']??'')); ?>
                    <article class="animal-profile-card" data-search="<?=h($searchText)?>">
                        <div class="animal-profile-image">
                            <?php if($animal['image_path']): ?><img src="<?=h(preg_match('~^https?://~i', $animal['image_path']) ? $animal['image_path'] : '../wildlife_api/'.$animal['image_path'])?>" alt="<?=h($animal['name'])?>" loading="lazy"><?php else: ?><div class="animal-image-placeholder"><span aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M12 3v18M3 12h18M5.6 5.6l12.8 12.8m0-12.8L5.6 18.4"/></svg></span><small>No profile photo</small></div><?php endif; ?>
                            <span class="animal-publish-badge <?=$animal['is_published']?'is-published':'is-draft'?>"><i></i><?=$animal['is_published']?'Published':'Draft'?></span>
                        </div>
                        <div class="animal-profile-content">
                            <div class="animal-profile-meta"><span><?=h($animal['category']?:'Wildlife')?></span><span><?=h($animal['conservation_status']?:'Status not set')?></span></div>
                            <h2><?=h($animal['name'])?></h2>
                            <?php if($animal['scientific_name']): ?><p class="animal-scientific-name"><?=h($animal['scientific_name'])?></p><?php endif; ?>
                            <?php if(!empty($animal['image_credit'])): ?><p class="animal-image-credit">Photo: <?=h($animal['image_credit'])?></p><?php endif; ?>
                            <p class="animal-description"><?=h($animal['description'])?></p>
                            <?php if($animal['habitat']): ?><div class="animal-habitat"><svg aria-hidden="true" viewBox="0 0 24 24"><path d="M19 10c0 5-7 11-7 11S5 15 5 10a7 7 0 1 1 14 0Z"/><circle cx="12" cy="10" r="2.2"/></svg><span><small>Habitat</small><?=h($animal['habitat'])?></span></div><?php endif; ?>
                            <div class="animal-card-actions">
                                <a class="animal-edit-button" href="?edit=<?=(int)$animal['id']?>">Edit profile</a>
                                <form method="post" onsubmit="return confirm('Delete this animal profile? This cannot be undone.')"><input type="hidden" name="id" value="<?=(int)$animal['id']?>"><button class="animal-delete-button" name="delete" value="1" type="submit" aria-label="Delete <?=h($animal['name'])?>">Delete</button></form>
                            </div>
                        </div>
                    </article>
                <?php endforeach; ?>
            </section>
            <p class="animal-no-results" id="animalNoResults" hidden>No profiles match your search.</p>
        <?php endif; ?>
    </main>
</div>

<div class="animal-modal-backdrop" id="animalModalBackdrop" data-close-animal-form></div>
<section class="animal-modal" id="animalFormModal" role="dialog" aria-modal="true" aria-labelledby="animalModalTitle" aria-hidden="true">
    <div class="animal-modal-panel">
        <header class="animal-modal-header"><div><div class="animal-eyebrow">Species details</div><h2 id="animalModalTitle"><?=$isEditing?'Edit animal profile':'Add animal profile'?></h2><p>These details appear in the wildlife guide.</p></div><button type="button" class="animal-modal-close" aria-label="Close form" data-close-animal-form>x</button></header>
        <form class="animal-form" method="post" enctype="multipart/form-data">
            <input type="hidden" name="id" value="<?=h($value('id'))?>">
            <div class="animal-form-grid">
                <label class="animal-field">Animal name <span>*</span><input name="name" required maxlength="120" value="<?=h($value('name'))?>" placeholder="e.g. Bornean orangutan"></label>
                <label class="animal-field">Scientific name<input name="scientific_name" maxlength="160" value="<?=h($value('scientific_name'))?>" placeholder="e.g. Pongo pygmaeus"></label>
                <label class="animal-field">Category<input name="category" maxlength="80" value="<?=h($value('category'))?>" placeholder="Mammal, reptile, bird..."></label>
                <label class="animal-field">Conservation status<input name="conservation_status" maxlength="80" value="<?=h($value('conservation_status'))?>" placeholder="e.g. Endangered"></label>
                <label class="animal-field animal-field-wide">Description <span>*</span><textarea name="description" required rows="4" placeholder="Describe this species and what makes it unique."><?=h($value('description'))?></textarea></label>
                <label class="animal-field animal-field-wide">Habitat<input name="habitat" maxlength="255" value="<?=h($value('habitat'))?>" placeholder="Where this species lives"></label>
                <label class="animal-field">Profile photo <small>JPG, PNG or WebP &middot; up to 8 MB</small><input class="animal-file-input" type="file" name="image" accept="image/jpeg,image/png,image/webp"></label>
                <label class="animal-field">Photo credit <small>Photographer and licence/source</small><input name="image_credit" maxlength="255" value="<?=h($value('image_credit', $edit['image_credit'] ?? ''))?>" placeholder="e.g. Photographer · CC BY 4.0 · Wikimedia Commons"></label>
                <label class="animal-field">Educational poster <small>Optional &middot; up to 8 MB</small><input class="animal-file-input" type="file" name="poster" accept="image/jpeg,image/png,image/webp"></label>
            </div>
            <label class="animal-publish-toggle"><input type="checkbox" name="is_published" <?=array_key_exists('is_published',$formValues)?(isset($formValues['is_published'])?'checked':''):(!isset($edit['is_published'])||(int)$edit['is_published']===1?'checked':'')?>><span><strong>Show in the mobile app</strong><small>Published profiles are visible in the wildlife guide.</small></span></label>
            <footer class="animal-form-footer"><button class="animal-primary-button" type="submit"><?=$isEditing?'Save changes':'Save profile'?></button><a href="animals.php" class="animal-cancel-button" data-cancel-animal-form>Cancel</a></footer>
        </form>
    </div>
</section>
<script src="animal-library.js"></script>
</body>
</html>
