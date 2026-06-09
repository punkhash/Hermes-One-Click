/* About modal — Cosmius Hermes intro + bundled components. */

function _aboutEsc(s) {
  const d = document.createElement('div');
  d.textContent = s == null ? '' : String(s);
  return d.innerHTML;
}

function _aboutHeroHtml() {
  return (
    '<div class="about-hero">' +
    '<div class="about-brand-row">' +
    '<img class="about-brand-logo" src="static/logo.png" width="48" height="48" alt="" decoding="async">' +
    '<span class="about-brand-name">' +
    _aboutEsc(t('about_brand_name')) +
    '</span></div>' +
    '<p class="about-community-blurb">' +
    _aboutEsc(t('about_community_blurb')) +
    '</p></div>' +
    '<div class="about-oss-divider" aria-hidden="true"></div>'
  );
}

function _aboutModalHtml() {
  return (
    _aboutHeroHtml() +
    '<div class="about-project">' +
    '<h3>' +
    _aboutEsc(t('about_agent_heading')) +
    '</h3>' +
    '<p>' +
    _aboutEsc(t('about_agent_blurb')) +
    '</p>' +
    '<p class="about-copyright">' +
    _aboutEsc(t('about_agent_copyright')) +
    '</p></div>' +
    '<div class="about-project">' +
    '<h3>' +
    _aboutEsc(t('about_webui_heading')) +
    '</h3>' +
    '<p>' +
    _aboutEsc(t('about_webui_blurb')) +
    '</p>' +
    '<p class="about-copyright">' +
    _aboutEsc(t('about_webui_copyright')) +
    '</p></div>'
  );
}

function openAboutModal() {
  const modal = document.getElementById('aboutModal');
  const body = document.getElementById('aboutModalBody');
  if (!modal || !body) return;
  body.innerHTML = _aboutModalHtml();
  modal.style.display = 'flex';
  modal.setAttribute('aria-hidden', 'false');
  if (typeof applyLocaleToDOM === 'function') applyLocaleToDOM();
}

function closeAboutModal() {
  const modal = document.getElementById('aboutModal');
  if (!modal) return;
  modal.style.display = 'none';
  modal.setAttribute('aria-hidden', 'true');
}

if (typeof window !== 'undefined') {
  window.openAboutModal = openAboutModal;
  window.closeAboutModal = closeAboutModal;
}
