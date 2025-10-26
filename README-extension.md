# Multi Time Zone Clock — Chrome Extension

To load the extension in Chrome/Edge/Brave:

1. Put the extension files into a folder:
   - manifest.json, popup.html, popup.css, popup.js, icons/ (optional)
2. Open chrome://extensions (or edge://extensions).
3. Enable "Developer mode".
4. Click "Load unpacked" and select the folder.
5. Click the extension icon to open the popup and use the clocks.

Notes:
- Currently the popup uses localStorage. If you want sync across devices, I can switch to chrome.storage.sync.
- Popup is ephemeral; for continuous background work you'd add a service worker (manifest v3 background).