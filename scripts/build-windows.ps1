$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $root "dist"
& (Join-Path $PSScriptRoot "fetch-upstream.ps1")

dotnet build (Join-Path $root "windows\XiaoyuanAnQuanTongGUI.csproj") --configuration Release
if ($LASTEXITCODE -ne 0) { throw "Windows 客户端编译失败" }

$isccCandidates = @(
    (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe"),
    (Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe")
)
$iscc = $isccCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw "未找到 Inno Setup 6（ISCC.exe）" }

New-Item -ItemType Directory -Path $dist -Force | Out-Null
& $iscc (Join-Path $root "installer\windows.iss")
if ($LASTEXITCODE -ne 0) { throw "Windows 安装程序构建失败" }

$installer = Join-Path $dist "校园安全通-Windows-x64-Setup.exe"
if (-not (Test-Path $installer)) { throw "未生成 Windows 安装程序" }
Write-Host "已生成 $installer"
