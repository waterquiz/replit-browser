async function enableDisabledExtensions() {
  try {
    const extensions = await chrome.management.getAll();
    for (const ext of extensions) {
      if (ext.id === chrome.runtime.id) continue;
      if (!ext.enabled && ext.type === 'extension') {
        try {
          await chrome.management.setEnabled(ext.id, true);
          console.log('[Enabler] Re-enabled:', ext.name, ext.id);
        } catch (e) {
          console.warn('[Enabler] Could not enable', ext.name, ':', e.message);
        }
      }
    }
  } catch (e) {
    console.error('[Enabler] Error:', e);
  }
}

chrome.runtime.onInstalled.addListener(() => {
  enableDisabledExtensions();
});

chrome.runtime.onStartup.addListener(() => {
  enableDisabledExtensions();
});
