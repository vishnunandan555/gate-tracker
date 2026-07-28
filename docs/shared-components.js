/**
 * GATEletics Shared Components (Header, Footer, Theme Manager)
 */
(function () {
  // 1. Theme Initialization
  const savedTheme = localStorage.getItem('theme');
  if (savedTheme) {
    document.documentElement.setAttribute('data-theme', savedTheme);
  } else {
    const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    document.documentElement.setAttribute('data-theme', systemPrefersDark ? 'dark' : 'light');
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

  // 3. Theme Toggle Setup
  function setupThemeToggle() {
    const themeToggleBtn = document.getElementById('theme-toggle');
    if (!themeToggleBtn) return;

    const currentTheme = document.documentElement.getAttribute('data-theme') || 'dark';
    themeToggleBtn.textContent = currentTheme === 'dark' ? '🌙 Dark' : '☀️ Light';

    themeToggleBtn.addEventListener('click', () => {
      const activeTheme = document.documentElement.getAttribute('data-theme');
      const newTheme = activeTheme === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', newTheme);
      localStorage.setItem('theme', newTheme);
      themeToggleBtn.textContent = newTheme === 'dark' ? '🌙 Dark' : '☀️ Light';
    });
  }

  document.addEventListener('DOMContentLoaded', () => {
    renderFooter();
    setupThemeToggle();
  });
})();
