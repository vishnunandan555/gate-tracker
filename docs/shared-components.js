/**
 * GATEletics Shared Components (Header, Footer, Theme Manager, Mobile Drawer)
 */
(function () {
  // 1. Immediate Device Theme Initialization & System Listener
  const colorSchemeQuery = window.matchMedia('(prefers-color-scheme: dark)');
  const savedTheme = localStorage.getItem('theme');

  if (savedTheme) {
    document.documentElement.setAttribute('data-theme', savedTheme);
  } else {
    document.documentElement.setAttribute('data-theme', colorSchemeQuery.matches ? 'dark' : 'light');
  }

  // Automatically adapt if user changes system OS theme preference
  const handleSystemThemeChange = (e) => {
    if (!localStorage.getItem('theme')) {
      const systemTheme = e.matches ? 'dark' : 'light';
      document.documentElement.setAttribute('data-theme', systemTheme);
      setupThemeToggle();
    }
  };

  if (colorSchemeQuery.addEventListener) {
    colorSchemeQuery.addEventListener('change', handleSystemThemeChange);
  } else if (colorSchemeQuery.addListener) {
    colorSchemeQuery.addListener(handleSystemThemeChange);
  }

  // 2. Render Shared Footer
  function renderFooter() {
    const footerContainer = document.getElementById('site-footer');
    if (!footerContainer) return;

    footerContainer.innerHTML = `
      <footer style="margin-top: 60px; padding: 28px 0; border-top: 1px solid var(--border-color); text-align: center; color: var(--text-muted); font-size: 14px;">
        <div class="container" style="padding-top: 0; padding-bottom: 0;">
          <div style="display: flex; justify-content: center; gap: 20px; flex-wrap: wrap; margin-bottom: 14px;">
            <a href="index.html">Home</a>
            <a href="features.html">Features</a>
            <a href="downloads.html">Downloads</a>
            <a href="guide.html">Guide</a>
            <a href="support.html">Support</a>
            <a href="privacy.html">Privacy</a>
            <a href="terms.html">Terms</a>
          </div>
          <p>© 2026 GATEletics. Open source under the GNU AGPLv3 License.</p>
        </div>
      </footer>
    `;
  }

  // SVG Icon Helpers for Theme & Navigation
  const icons = {
    moon: `<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display:inline-block; vertical-align:middle;"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>`,
    sun: `<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display:inline-block; vertical-align:middle;"><circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line></svg>`,
    home: `<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg>`,
    features: `<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon></svg>`,
    downloads: `<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline><line x1="12" y1="22.08" x2="12" y2="12"></line></svg>`,
    guide: `<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path></svg>`,
    support: `<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg>`,
    privacy: `<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>`,
    terms: `<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line></svg>`
  };

  // 3. Theme Toggle Setup
  function updateThemeButtonLabel(btn, theme) {
    if (!btn) return;
    const isDark = theme === 'dark';
    btn.innerHTML = `${isDark ? icons.moon : icons.sun} <span>${isDark ? 'Dark' : 'Light'}</span>`;
  }

  function setupThemeToggle() {
    const themeToggleBtn = document.getElementById('theme-toggle');
    if (!themeToggleBtn) return;

    const currentTheme = document.documentElement.getAttribute('data-theme') || 'dark';
    updateThemeButtonLabel(themeToggleBtn, currentTheme);

    themeToggleBtn.onclick = function () {
      const activeTheme = document.documentElement.getAttribute('data-theme');
      const newTheme = activeTheme === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', newTheme);
      localStorage.setItem('theme', newTheme);
      updateThemeButtonLabel(themeToggleBtn, newTheme);
    };
  }

  // 4. Mobile Side Drawer Navigation Setup
  function setupMobileDrawer() {
    const navControls = document.querySelector('.nav-controls');
    if (navControls && !document.getElementById('hamburger-toggle')) {
      const burgerBtn = document.createElement('button');
      burgerBtn.id = 'hamburger-toggle';
      burgerBtn.className = 'hamburger-btn';
      burgerBtn.setAttribute('aria-label', 'Open navigation menu');
      burgerBtn.innerHTML = '☰';
      navControls.appendChild(burgerBtn);
    }

    let backdrop = document.querySelector('.nav-backdrop');
    if (!backdrop) {
      backdrop = document.createElement('div');
      backdrop.className = 'nav-backdrop';
      document.body.appendChild(backdrop);
    }

    let drawer = document.querySelector('.nav-drawer');
    if (!drawer) {
      drawer = document.createElement('div');
      drawer.className = 'nav-drawer';

      const currentPath = window.location.pathname.split('/').pop() || 'index.html';

      const navItems = [
        { name: 'Home', href: 'index.html', icon: icons.home },
        { name: 'Features', href: 'features.html', icon: icons.features },
        { name: 'Downloads', href: 'downloads.html', icon: icons.downloads },
        { name: 'Guide', href: 'guide.html', icon: icons.guide },
        { name: 'Support', href: 'support.html', icon: icons.support },
        { name: 'Privacy', href: 'privacy.html', icon: icons.privacy },
        { name: 'Terms', href: 'terms.html', icon: icons.terms }
      ];

      const linksHtml = navItems.map(item => {
        const isActive = currentPath === item.href || (currentPath === '' && item.href === 'index.html');
        return `
          <a href="${item.href}" class="nav-drawer-link ${isActive ? 'active' : ''}">
            <span style="display: flex; align-items: center; color: var(--accent-color);">${item.icon}</span>
            <span>${item.name}</span>
          </a>
        `;
      }).join('');

      drawer.innerHTML = `
        <div class="nav-drawer-header">
          <a href="index.html" class="logo" style="box-shadow: none;">
            <img src="logo_trans_cropped.png" alt="GATEletics Logo" class="logo-img">
            <span class="logo-text"><span class="logo-gate">GATE</span><span class="logo-letics">LETICS</span></span>
          </a>
          <button id="drawer-close" class="nav-drawer-close" aria-label="Close menu">✕</button>
        </div>
        <div class="nav-drawer-links">
          ${linksHtml}
        </div>
      `;
      document.body.appendChild(drawer);
    }

    const hamburgerBtn = document.getElementById('hamburger-toggle');
    const drawerCloseBtn = document.getElementById('drawer-close');

    function openDrawer() {
      document.body.classList.add('drawer-open');
    }

    function closeDrawer() {
      document.body.classList.remove('drawer-open');
    }

    if (hamburgerBtn) hamburgerBtn.onclick = openDrawer;
    if (drawerCloseBtn) drawerCloseBtn.onclick = closeDrawer;
    if (backdrop) backdrop.onclick = closeDrawer;

    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && document.body.classList.contains('drawer-open')) {
        closeDrawer();
      }
    });
  }

  function init() {
    renderFooter();
    setupThemeToggle();
    setupMobileDrawer();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
