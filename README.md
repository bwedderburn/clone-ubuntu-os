# Multi Time Zone Digital Clock

A tiny client-side web app that displays the current time in multiple time zones. It uses the browser's Intl.DateTimeFormat API and supports:

- Adding/removing IANA time zones (e.g. "America/New_York", "Europe/London")
- A default set of useful zones, including "local" for the system timezone
- 12/24 hour toggle
- Persistent selection via localStorage

How to use
1. Save the files (index.html, styles.css, script.js) in the same folder.
2. Open `index.html` in any modern browser (Chrome, Firefox, Edge, Safari).
3. Add time zones via the input (or pick from the suggestion list) and click "Add".
4. Toggle 24-hour mode using the checkbox. The app saves your zones and preference.

Notes
- Enter valid IANA time zone identifiers for accurate results. If you need a list, see: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
- The app runs entirely in the browser; no server required.

License: MIT (use as you like)