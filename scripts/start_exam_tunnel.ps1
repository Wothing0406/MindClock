<#
.SYNOPSIS
Bật Backend FastAPI + PostgreSQL (Docker) và mở Cloudflare Tunnel ra https://api.ieltsoasis.site.
Dùng khi cần treo máy cá nhân làm server ổn định (đi thi / demo, 0đ).
#>
param(
    [string]$TunnelName = "mindclock-exam",
    [string]$LocalUrl = "http://127.0.0.1:8000"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$ApiDir = Join-Path $RepoRoot "services\api"

$cloudflared = (Get-Command cloudflared -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
if (-not $cloudflared) {
    $fallbackPath = "C:\Program Files (x86)\cloudflared\cloudflared.exe"
    if (Test-Path $fallbackPath) {
        $cloudflared = $fallbackPath
    } else {
        throw "Chua cai cloudflared. Chay: winget install --id Cloudflare.cloudflared -e"
    }
}

Write-Host "[1/2] Dang khoi dong PostgreSQL + FastAPI Docker..." -ForegroundColor Cyan
Push-Location $ApiDir
try {
    docker compose up -d --build
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose up that bai. Hay kiem tra Docker Desktop da bat chua."
    }
}
finally {
    Pop-Location
}

Write-Host "[2/2] Dang mo Cloudflare Tunnel ($TunnelName -> $LocalUrl)..." -ForegroundColor Green
Write-Host "Nhan Ctrl+C de tat Tunnel khi khong dung nua." -ForegroundColor Yellow
& $cloudflared tunnel run --url $LocalUrl $TunnelName
