# Multi Time Zone Clock — Electron

To run the Electron app:

1. Save the files above into a new folder (package.json, main.js, preload.js, index.html, styles.css, renderer.js).
2. In that folder run:
   - npm install
   - npm start

Notes:
- This is a minimal Electron wrapper. For production builds add electron-builder or similar.
- The renderer uses localStorage to persist zones.