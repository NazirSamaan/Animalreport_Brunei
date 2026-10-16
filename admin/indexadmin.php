<?php
session_start();
if (isset($_SESSION['id'])) { header('Location: dashboard.php'); exit; }
$error = isset($_GET['error']) ? htmlspecialchars($_GET['error'], ENT_QUOTES, 'UTF-8') : '';
?>
<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Sign in · WildlifeCare CRM</title><link rel="stylesheet" href="crm.css?v=admin-login-polish-30"></head><body class="crm-login">
<section class="login-story"><h1>Protecting wildlife starts with better information.</h1><p>Review community reports, coordinate follow-up, and keep Brunei’s animal education library current from one workspace.</p></section>
<main class="login-card-wrap"><form class="login-card" action="loginadmin.php" method="post"><div class="login-kicker">Wildlife operations</div><h2>Welcome back</h2><p>Sign in to continue to your admin workspace.</p><?php if ($error): ?><div class="login-error"><?=$error?></div><?php endif; ?><label for="username">Username</label><input type="text" id="username" name="Username" placeholder="Your username" autocomplete="username" required><label for="password">Password</label><input type="password" id="password" name="Password" placeholder="Your password" autocomplete="current-password" required><button type="submit">Sign in for admin</button><div class="login-note">Brunei Go Online Apps · Wildlife administration</div></form></main></body></html>
