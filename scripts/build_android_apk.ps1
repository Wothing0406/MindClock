param(
  [ValidateSet('debug', 'profile', 'release')]
  [string]$Mode = 'debug',
  [string]$ApiBaseUrl = '',
  [string]$OutDir = 'dist'
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$AppDir = Join-Path $RepoRoot 'app'
$FlutterBat = Join-Path $RepoRoot '.local-sdk\flutter\bin\flutter.bat'
if (-not (Test-Path $FlutterBat)) {
  $FlutterBat = 'flutter'
}

if ($Mode -eq 'release' -and [string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
  throw 'Build release bat buoc truyen -ApiBaseUrl (vi du: https://api.mindclock.example.com) vi dien thoai that khong ket noi duoc 10.0.2.2.'
}

$BuildArgs = @('build', 'apk', "--$Mode", '--no-pub')
if (-not [string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
  $BuildArgs += "--dart-define=MINDCLOCK_API_BASE_URL=$ApiBaseUrl"
}

$IntermediatesDir = Join-Path $AppDir "build\app\intermediates"
if (Test-Path $IntermediatesDir) {
  cmd /c "rmdir /s /q `"$IntermediatesDir`" 2>nul" | Out-Null
}

Write-Host "==> Building Android APK ($Mode)..." -ForegroundColor Cyan
Push-Location $AppDir
try {
  & $FlutterBat @BuildArgs
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
} finally {
  Pop-Location
}

$BuiltApk = Join-Path $AppDir "build\app\outputs\flutter-apk\app-$Mode.apk"
if (-not (Test-Path $BuiltApk)) {
  throw "Khong tim thay APK tai $BuiltApk"
}

$TargetDir = Join-Path $RepoRoot $OutDir
New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
$DestApk = Join-Path $TargetDir "mindclock-$Mode.apk"
Copy-Item -Path $BuiltApk -Destination $DestApk -Force

$FileInfo = Get-Item $DestApk
Write-Host ("==> APK ready: {0} ({1:N2} MB)" -f $DestApk, ($FileInfo.Length / 1MB)) -ForegroundColor Green
if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
  Write-Host "NOTE: Chua truyen -ApiBaseUrl -> mac dinh Emulator (http://10.0.2.2:8000). De dien thoai that dung AI/Sync, build voi -ApiBaseUrl https://<host-backend>." -ForegroundColor Yellow
}
