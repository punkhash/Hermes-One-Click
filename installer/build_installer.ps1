param(
    [string]$OutputName = "CosmiusHermes-Setup.exe",
    [string]$BuildRoot = "C:\HermesInnoBuild",
    [string]$AppVersion = "1.0.0"
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$distDir = Join-Path $repoRoot "dist"
$workDir = Join-Path $BuildRoot "work"
$payloadZip = Join-Path $workDir "payload.zip"
$payloadDir = Join-Path $workDir "payload"
$outDir = Join-Path $BuildRoot "out"
$issPath = Join-Path $PSScriptRoot "CosmiusHermes.iss"
$outputBaseName = [System.IO.Path]::GetFileNameWithoutExtension($OutputName)
$compiledInstaller = Join-Path $outDir ($outputBaseName + ".exe")
$finalOutput = Join-Path $distDir $OutputName

function Get-InnoCompiler {
    $command = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    foreach ($path in @(
        (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 6\ISCC.exe"),
        (Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe")
    )) {
        if ($path -and (Test-Path -LiteralPath $path -PathType Leaf)) {
            return $path
        }
    }

    throw "Inno Setup compiler (ISCC.exe) not found."
}

function Assert-NoSensitiveLocalFiles {
    $bad = New-Object System.Collections.Generic.List[string]
    foreach ($name in @(".env", "config.local.json", "chat_history", "conversations", "user_data", "history", "data")) {
        $path = Join-Path $repoRoot $name
        if (Test-Path -LiteralPath $path) {
            $bad.Add($path)
        }
    }

    Get-ChildItem -LiteralPath $repoRoot -Force -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            -not $_.FullName.StartsWith((Join-Path $repoRoot ".git") + "\", [StringComparison]::OrdinalIgnoreCase) -and
            -not $_.FullName.StartsWith((Join-Path $repoRoot "dist") + "\", [StringComparison]::OrdinalIgnoreCase) -and
            -not $_.FullName.StartsWith((Join-Path $repoRoot "installer\work") + "\", [StringComparison]::OrdinalIgnoreCase) -and
            ($_.Name -eq ".env" -or $_.Name -eq "config.local.json" -or $_.Extension -eq ".key" -or $_.Extension -eq ".log")
        } |
        ForEach-Object { $bad.Add($_.FullName) }

    if ($bad.Count -gt 0) {
        throw "Sensitive/local files found before packaging:`n$($bad -join "`n")"
    }
}

function Assert-NoSensitivePayloadFiles {
    $bad = New-Object System.Collections.Generic.List[string]

    Get-ChildItem -LiteralPath $payloadDir -Force -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            $relative = $_.FullName.Substring($payloadDir.Length).TrimStart("\") -replace "\\", "/"
            $_.Name -eq ".env" -or
            $_.Name -eq "config.local.json" -or
            $_.Extension -eq ".key" -or
            $_.Extension -eq ".log" -or
            $relative -like "chat_history/*" -or
            $relative -like "conversations/*" -or
            $relative -like "user_data/*" -or
            $relative -like "history/*" -or
            $relative -like "data/*" -or
            $relative -like "*/.hermes/*"
        } |
        ForEach-Object { $bad.Add($_.FullName) }

    if ($bad.Count -gt 0) {
        throw "Sensitive/local files found in installer payload:`n$($bad -join "`n")"
    }
}

Set-Location $repoRoot
Assert-NoSensitiveLocalFiles

if (-not (Test-Path -LiteralPath $issPath -PathType Leaf)) {
    throw "Inno Setup script not found: $issPath"
}

if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot "app_icon.ico") -PathType Leaf)) {
    throw "Installer icon not found: installer\app_icon.ico"
}

New-Item -ItemType Directory -Path $distDir -Force | Out-Null
if (Test-Path -LiteralPath $BuildRoot) {
    $resolvedBuildRoot = (Resolve-Path -LiteralPath $BuildRoot).Path
    if ($resolvedBuildRoot -ne $BuildRoot) {
        throw "Unexpected build root: $resolvedBuildRoot"
    }
    Remove-Item -LiteralPath $resolvedBuildRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $workDir -Force | Out-Null
New-Item -ItemType Directory -Path $payloadDir -Force | Out-Null
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

git archive --format=zip --output $payloadZip HEAD
if ($LASTEXITCODE -ne 0) {
    throw "git archive failed."
}

Expand-Archive -LiteralPath $payloadZip -DestinationPath $payloadDir -Force

foreach ($path in @(
    (Join-Path $payloadDir ".gitignore"),
    (Join-Path $payloadDir "installer")
)) {
    if (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path -Recurse -Force
    }
}

Assert-NoSensitivePayloadFiles

$iscc = Get-InnoCompiler
& $iscc `
    "/DRepoRoot=$repoRoot" `
    "/DSourceDir=$payloadDir" `
    "/DOutputDir=$outDir" `
    "/DOutputBaseName=$outputBaseName" `
    "/DAppVersion=$AppVersion" `
    $issPath
if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup build failed."
}

Copy-Item -LiteralPath $compiledInstaller -Destination $finalOutput -Force

$hash = Get-FileHash -LiteralPath $finalOutput -Algorithm SHA256
[PSCustomObject]@{
    Installer = $finalOutput
    SizeMB = [Math]::Round((Get-Item -LiteralPath $finalOutput).Length / 1MB, 2)
    SHA256 = $hash.Hash
    PayloadDir = $payloadDir
    InnoCompiler = $iscc
}
