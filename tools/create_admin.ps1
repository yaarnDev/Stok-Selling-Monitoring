<#
create_admin.ps1 - PowerShell helper to create Firebase admin user using tools/create_admin.js
Usage:
  .\tools\create_admin.ps1 -ServiceKey ..\serviceAccountKey.json -Email admin@ex.com -Password S3cret
  Add -DeployRules to deploy firestore.rules after creation
#>

param(
  [string]$ServiceKey,
  [string]$Email,
  [string]$Password,
  [switch]$DeployRules
)

function ExitWith($msg) { Write-Host $msg -ForegroundColor Red; exit 1 }

if (-not (Get-Command node -ErrorAction SilentlyContinue)) { ExitWith 'node not found in PATH. Install Node.js.' }

$toolsDir = Join-Path $PSScriptRoot 'tools'
Set-Location $toolsDir

if (-not (Test-Path -Path 'create_admin.js')) { ExitWith "create_admin.js not found in $toolsDir" }

if (-not (Test-Path -Path 'node_modules')) {
  Write-Host 'Installing node dependencies...'
  npm install
}

if (-not $ServiceKey) { $ServiceKey = Read-Host 'Path to serviceAccountKey.json' }
if (-not (Test-Path $ServiceKey)) { ExitWith "Service account file not found: $ServiceKey" }
if (-not $Email) { $Email = Read-Host 'Admin email' }
if (-not $Password) { $Password = Read-Host -AsSecureString 'Admin password'; $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)) }

Write-Host "Creating admin user $Email..."
node create_admin.js $ServiceKey $Email $Password

if ($DeployRules) {
  Write-Host 'Deploying Firestore rules from project root (firestore.rules)...'
  firebase deploy --only firestore:rules
}

Write-Host 'Done. Admin created.' -ForegroundColor Green
