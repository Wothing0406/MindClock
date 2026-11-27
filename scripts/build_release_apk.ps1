<#
.SYNOPSIS
Build file MindClock Android APK bản release trỏ thẳng về Backend HTTPS thật (mặc định https://api.ieltsoasis.site).
#>
param(
    [string]$ApiBaseUrl = "https://api.ieltsoasis.site",
    [switch]$SplitPerAbi
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppDir = Join-Path $RepoRoot "app"
$OutDir = Join-Path $RepoRoot "dist\apk"

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Push-Location $AppDir
try {
    Write-Host "[1/2] Dang build Flutter Android release APK (API: $ApiBaseUrl)..." -ForegroundColor Cyan
    $args = @("build", "apk", "--release", "--dart-define=MINDCLOCK_API_BASE_URL=$ApiBaseUrl")
    if ($SplitPerAbi) {
        $args += "--split-per-abi"
    }
    flutter @args
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build apk that bai."
    }
}
finally {
    Pop-Location
}

$ApkSourceDir = Join-Path $AppDir "build\app\outputs\flutter-apk"
$BuiltApks = Get-ChildItem -Path $ApkSourceDir -Filter "*.apk" | Where-Object { $_.Name -like "*release*.apk" }
if (-not $BuiltApks) {
    throw "Khong tim thay file APK release trong $ApkSourceDir"
}

foreach ($apk in $BuiltApks) {
    $destName = if ($apk.Name -eq "app-release.apk") { "mindclock-android.apk" } else { $apk.Name }
    $destPath = Join-Path $OutDir $destName
    Copy-Item -Force $apk.FullName $destPath
    Write-Host "[2/2] Da xuat APK: $destPath" -ForegroundColor Green
}
