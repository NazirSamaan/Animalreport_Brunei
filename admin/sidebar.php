<header class="crm-topbar">
    <a class="crm-brand" href="dashboard.php" aria-label="BruneiGoOnlineApps admin home">
        <span class="brand-mark" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M19.5 4.5C12.8 4.6 7.3 6.7 5.2 11c-1.2 2.5-.4 5.4 1.8 6.5 2.6 1.2 5.4-.1 7.1-2.8 2.1-3.3 3.7-6.8 5.4-10.2Z"/><path d="M4.8 20c3.1-4.4 6.7-7.6 11.5-10.4"/></svg></span>
        <span class="brand-name">BruneiGoOnlineApps</span>
    </a>
    <form class="top-search" action="search.php" method="get"><span>⌕</span><input type="search" name="q" value="<?=htmlspecialchars($_GET['q'] ?? '', ENT_QUOTES, 'UTF-8')?>" placeholder="Search" aria-label="Search"></form>
    <?php $username = $_SESSION['username'] ?? 'Admin'; ?>
    <div class="topbar-right">
        <span class="topbar-context"><?=htmlspecialchars($username, ENT_QUOTES, 'UTF-8')?></span>
        <div class="admin-profile-menu">
            <button class="topbar-avatar" id="adminProfileButton" type="button" aria-label="Open admin account menu" aria-haspopup="true" aria-expanded="false" aria-controls="adminProfilePopover">
                <?=htmlspecialchars(strtoupper(substr($username, 0, 1)), ENT_QUOTES, 'UTF-8')?>
            </button>
            <div class="admin-profile-popover" id="adminProfilePopover" role="menu" aria-labelledby="adminProfileButton" hidden>
                <div class="admin-popover-user"><span class="admin-popover-avatar"><?=htmlspecialchars(strtoupper(substr($username, 0, 1)), ENT_QUOTES, 'UTF-8')?></span><span><strong><?=htmlspecialchars($username, ENT_QUOTES, 'UTF-8')?></strong><small>Administrator</small></span></div>
                <div class="admin-popover-divider"></div>
                <a class="admin-popover-signout" href="logoutadmin.php" role="menuitem"><span aria-hidden="true">↪</span> Sign out</a>
            </div>
        </div>
    </div>
</header>
<aside class="sidebar">
    <div class="sidebar-label">WORKSPACE</div>
    <nav class="crm-nav">
        <a class="nav-item <?=basename($_SERVER['PHP_SELF'])==='dashboard.php'?'active':''?>" href="dashboard.php"><span class="nav-icon">⌂</span><span>Overview</span></a>
        <a class="nav-item <?=basename($_SERVER['PHP_SELF'])==='manageuser.php'?'active':''?>" href="manageuser.php"><span class="nav-icon">▤</span><span>Incident reports</span></a>
        <a class="nav-item <?=basename($_SERVER['PHP_SELF'])==='animals.php'?'active':''?>" href="animals.php"><span class="nav-icon">♧</span><span>Animal library</span></a>
    </nav>
    <div class="sidebar-foot"><div class="workspace-badge"><span class="online-dot"></span><span>Wildlife operations</span></div></div>
</aside>
<script>
(() => {
    const button = document.getElementById('adminProfileButton');
    const menu = document.getElementById('adminProfilePopover');
    if (!button || !menu) return;
    const closeMenu = () => {
        menu.hidden = true;
        button.setAttribute('aria-expanded', 'false');
    };
    button.addEventListener('click', () => {
        const opening = menu.hidden;
        menu.hidden = !opening;
        button.setAttribute('aria-expanded', String(opening));
    });
    document.addEventListener('click', event => {
        if (!event.target.closest('.admin-profile-menu')) closeMenu();
    });
    document.addEventListener('keydown', event => {
        if (event.key === 'Escape' && !menu.hidden) {
            closeMenu();
            button.focus();
        }
    });
})();
</script>
