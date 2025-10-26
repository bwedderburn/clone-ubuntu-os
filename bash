[22:54:33] 1/5 Ensure package main entry
[22:54:33] 2/5 Generate icons
Generating PNGs from build/icon.svg ...
Building build/icon.ico ...
Building build/icon.icns using iconutil (macOS) ...
Running npx electron-icon-maker fallback (creates icns + ico in build/) ...
The option "icns" is unknown. Here's a list of all available options: 

  Usage: electron icon-maker [options] [command]
  
  Commands:
  
    help  Display help
  
  Options:
  
    -h, --help            Output usage information
    -i, --input [value]   Input PNG file. Recommended (1024x1024) (defaults to "./icon.png")
    -o, --output [value]  Folder to output new icons folder (defaults to "./")
    -v, --version         Output the version number
  
Conversion complete. Outputs (if created):
-rw-r--r--@ 1 admin  staff  341955 Oct 25 22:54 build/icon.icns
-rw-r--r--@ 1 admin  staff  109043 Oct 25 22:54 build/icon.ico
-rw-r--r--@ 1 admin  staff    8639 Oct 25 21:12 build/icon.svg
-rw-r--r--@ 1 admin  staff   94787 Oct 25 22:54 build/png/icon-1024.png
-rw-r--r--@ 1 admin  staff   13178 Oct 25 22:54 build/png/icon-128.png
-rw-r--r--  1 admin  staff    1437 Oct 25 22:54 build/png/icon-16.png
-rw-r--r--@ 1 admin  staff   24235 Oct 25 22:54 build/png/icon-256.png
-rw-r--r--  1 admin  staff    3647 Oct 25 22:54 build/png/icon-32.png
-rw-r--r--  1 admin  staff    5383 Oct 25 22:54 build/png/icon-48.png
-rw-r--r--@ 1 admin  staff   45615 Oct 25 22:54 build/png/icon-512.png
-rw-r--r--@ 1 admin  staff    7257 Oct 25 22:54 build/png/icon-64.png
[22:54:43] 3/5 Package Electron app (darwin/x64, Electron 38.4.0)
Packaging app for platform darwin x64 using electron v38.4.0
Wrote new app to: dist/Multi Time Zone Clock-darwin-x64
[22:54:48] 4/5 Configure Git LFS and stage artifacts
[main 5087bd9] build(world-clock): package app and track dist via LFS (automated)
 2 files changed, 3 insertions(+), 3 deletions(-)
[22:54:51] 5/5 Skipping push (pass --push or set PUSH=1)
[22:54:51] Done. Output in ./dist
