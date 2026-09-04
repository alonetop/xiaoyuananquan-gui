$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$destination = if ($args.Count -gt 0) { $args[0] } else { Join-Path $root "windows\vendor\XiaoyuanAnQuanTong-windows-x64.exe" }
$url = "https://github.com/hangone/study-xiaoyuananquantong/releases/download/v1.0.0/XiaoyuanAnQuanTong-windows-x64.exe"
$expected = "dbc5a84bc3c4c8ae208dfd1695b1e43db585a3a556d8da6de5c76be1ba889f88"

New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
Invoke-WebRequest -Uri $url -OutFile $destination
$actual = (Get-FileHash -Algorithm SHA256 $destination).Hash.ToLowerInvariant()
if ($actual -ne $expected) {
    throw "上游 Windows 核心校验失败：期望 $expected，实际 $actual"
}
Write-Host "上游 Windows 核心校验通过：$actual"
