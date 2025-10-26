<#
PowerShell script to convert build/icon.svg -> PNGs, icon.ico, icon.icns
Run in an elevated PowerShell if required:
  ./scripts/convert-icons.ps1
#>
param()

$ErrorActionPreference = "Stop"
$svg = "build/icon.svg"
$pngDir = "build\png"
$iconsetDir = "build\Icon.iconset"
$outIcns = "build/icon.icns"
$outIco = "build/icon.ico"

New-Item -ItemType Directory -Force -Path $pngDir | Out-Null

# sizes
$sizes = @(16,32,48,64,128,256,512,1024)

Write-Host "Attempting to produce PNGs from $svg ..."
if (Get-Command magick -ErrorAction SilentlyContinue) {
  foreach ($s in $sizes) {
    & magick convert $svg -resize "${s}x${s}" "$pngDir\icon-$s.png"
  }
} elseif (Get-Command rsvg-convert -ErrorAction SilentlyContinue) {
  foreach ($s in $sizes) {
    & rsvg-convert -w $s -h $s $svg -o "$pngDir\icon-$s.png"
  }
} else {
  Write-Warning "ImageMagick or rsvg-convert not found. You can install ImageMagick or use npx electron-icon-maker fallback."
}

# Build ICO
Write-Host "Building $outIco ..."
if (Get-Command png2ico -ErrorAction SilentlyContinue) {
  & png2ico $outIco "$pngDir\icon-16.png","$pngDir\icon-32.png","$pngDir\icon-48.png","$pngDir\icon-64.png","$pngDir\icon-128.png","$pngDir\icon-256.png"
} elseif (Get-Command magick -ErrorAction SilentlyContinue) {
  & magick convert "$pngDir\icon-16.png" "$pngDir\icon-32.png" "$pngDir\icon-48.png" "$pngDir\icon-64.png" "$pngDir\icon-128.png" "$pngDir\icon-256.png" $outIco
} else {
  Write-Warning "png2ico or ImageMagick not available. Skipping ICO creation unless you run electron-icon-maker."
}

# ICNS creation (if on mac via WSL/mac host it's better to use iconutil)
if ($IsMac -or (Get-Command iconutil -ErrorAction SilentlyContinue)) {
  New-Item -ItemType Directory -Force -Path $iconsetDir | Out-Null
  Copy-Item "$pngDir\icon-16.png" "$iconsetDir\icon_16x16.png" -Force
  Copy-Item "$pngDir\icon-32.png" "$iconsetDir\icon_16x16@2x.png" -Force
  Copy-Item "$pngDir\icon-32.png" "$iconsetDir\icon_32x32.png" -Force
  Copy-Item "$pngDir\icon-64.png" "$iconsetDir\icon_32x32@2x.png" -Force
  Copy-Item "$pngDir\icon-128.png" "$iconsetDir\icon_128x128.png" -Force
  Copy-Item "$pngDir\icon-256.png" "$iconsetDir\icon_128x128@2x.png" -Force
  Copy-Item "$pngDir\icon-256.png" "$iconsetDir\icon_256x256.png" -Force
  Copy-Item "$pngDir\icon-512.png" "$iconsetDir\icon_256x256@2x.png" -Force
  Copy-Item "$pngDir\icon-512.png" "$iconsetDir\icon_512x512.png" -Force
  Copy-Item "$pngDir\icon-1024.png" "$iconsetDir\icon_512x512@2x.png" -Force
  iconutil -c icns $iconsetDir -o $outIcns
} else {
  Write-Host "iconutil not available on Windows. Skipping iconutil step. Use electron-icon-maker fallback instead."
}

# electron-icon-maker fallback
if (Get-Command npx -ErrorAction SilentlyContinue) {
  Write-Host "Running npx electron-icon-maker fallback ..."
  if (Test-Path "$pngDir\icon-1024.png") {
    npx --yes electron-icon-maker --input "$pngDir\icon-1024.png" --output build --icns --ico
  } elseif (Test-Path $svg) {
    npx --yes electron-icon-maker --input $svg --output build --icns --ico
  }
} else {
  Write-Warning "npx not found. Install Node.js to use electron-icon-maker fallback."
}

Get-ChildItem build -Recurse | Where-Object { $_.Name -match 'icon' } | Select-Object FullName, Length
