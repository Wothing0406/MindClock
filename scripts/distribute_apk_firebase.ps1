param(
  [Parameter(Mandatory = $true)]
  [string]$ApiBaseUrl,

  [string]$BuildMode = 'release',

  [string]$Testers = '',

  [string]$Groups = 'thpt-testers',

  [string]$ReleaseNotes = 'MindClock Android pilot build (Auth, Profile, TKB, Báo thức, Nhóm Streak, Phòng học AI, Đấu trường)',

  [string]$AppId = '1:357973416738:android:5e09df39793b206a05a37b'
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$AppDir = Join-Path $RepoRoot 'app'

Write-Host "==> Kiểm tra đăng nhập Firebase CLI..."
$loginOut = & npx -y firebase-tools@latest login:list 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $loginOut -match 'No authorized accounts') {
  Write-Error @"
Chưa có tài khoản Firebase CLI đang đăng nhập.
Chạy lệnh sau trước khi phát hành APK:
  npx -y firebase-tools@latest login
Sau đó chạy lại script này.
"@
  exit 1
}

Push-Location $AppDir
try {
  Write-Host "==> Build Android APK ($BuildMode) trỏ API: $ApiBaseUrl"
  $flutterArgs = @('build', 'apk', "--$BuildMode", "--dart-define=MINDCLOCK_API_BASE_URL=$ApiBaseUrl")
  & flutter @flutterArgs
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}
finally {
  Pop-Location
}

$ApkPath = Join-Path $AppDir "build\app\outputs\flutter-apk\app-$BuildMode.apk"
if (-not (Test-Path $ApkPath)) {
  Write-Error "Không tìm thấy file APK tại $ApkPath"
  exit 1
}

$distArgs = @(
  '-y',
  'firebase-tools@latest',
  'appdistribution:distribute',
  $ApkPath,
  '--app', $AppId,
  '--project', 'mindclock',
  '--release-notes', $ReleaseNotes
)

if (-not [string]::IsNullOrWhiteSpace($Testers)) {
  $distArgs += @('--testers', $Testers)
}
elseif (-not [string]::IsNullOrWhiteSpace($Groups)) {
  $distArgs += @('--groups', $Groups)
}

Write-Host "==> Đẩy APK lên Firebase App Distribution..."
& npx @distArgs
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Host "Hoàn tất phát hành APK lên Firebase App Distribution!"
