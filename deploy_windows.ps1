# Deployment helper for Windows (PowerShell)
# Usage: Right-click -> Run with PowerShell (or run in terminal)
# Requires: flutter, firebase-tools (npm), and logged-in firebase CLI (`firebase login`)

param(
  [string]$BuildMode = 'release',
  [switch]$SkipBuild
)

function ExitIfError($msg) {
  Write-Host $msg -ForegroundColor Red
  exit 1
}

Write-Host "Deploy script started" -ForegroundColor Cyan

# Check commands
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { ExitIfError "flutter not found in PATH. Install Flutter and ensure it's in PATH." }
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) { ExitIfError "firebase CLI not found. Install: npm i -g firebase-tools" }

# Ensure firebase login
$whoami = firebase projects:list 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "You may need to login to Firebase CLI. Running: firebase login..." -ForegroundColor Yellow
  firebase login || ExitIfError "Firebase login failed.";
}

# Build web
if (-not $SkipBuild) {
  Write-Host "Building Flutter web (mode: $BuildMode)" -ForegroundColor Green
  flutter build web --$BuildMode
  if ($LASTEXITCODE -ne 0) { ExitIfError "flutter build failed." }
}

# Ensure build output exists
$webPath = Join-Path -Path (Get-Location) -ChildPath 'build\web'
if (-not (Test-Path $webPath)) { ExitIfError "Build output not found at $webPath" }

# Initialize hosting if firebase.json missing public config (safe check)
$json = Get-Content firebase.json -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
if ($null -eq $json -or -not $json.hosting) {
  Write-Host "No hosting config found in firebase.json. Running 'firebase init hosting' interactively..." -ForegroundColor Yellow
  firebase init hosting || ExitIfError "firebase init hosting failed.";
}

# Deploy
Write-Host "Deploying to Firebase Hosting..." -ForegroundColor Green
firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) { ExitIfError "firebase deploy failed." }

Write-Host "Deploy complete." -ForegroundColor Cyan
Write-Host "Done." -ForegroundColor Green
