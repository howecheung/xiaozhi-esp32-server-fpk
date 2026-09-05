$ErrorActionPreference = "Stop"

$ProjectRoot = $PSScriptRoot
$DistDir = Join-Path $ProjectRoot "dist"

# fnpack lookup: $env:FNPACK > PATH > local dev copy under .fpk-refs/bin
$Fnpack = $null
if ($env:FNPACK) {
  $Fnpack = $env:FNPACK
}
elseif (Get-Command fnpack.exe -ErrorAction SilentlyContinue) {
  $Fnpack = (Get-Command fnpack.exe -ErrorAction SilentlyContinue).Source
}
else {
  $LocalRef = Join-Path (Split-Path -Parent $ProjectRoot) ".fpk-refs\bin\fnpack.exe"
  if (Test-Path -LiteralPath $LocalRef) {
    $Fnpack = $LocalRef
  }
}
if (-not $Fnpack -or -not (Test-Path -LiteralPath $Fnpack)) {
  throw "fnpack not found. Put it on PATH or set the FNPACK environment variable."
}

New-Item -ItemType Directory -Force $DistDir | Out-Null

Push-Location $DistDir
try {
  & $Fnpack build -d $ProjectRoot
  if ($LASTEXITCODE -ne 0) {
    throw "fnpack build failed with exit code $LASTEXITCODE"
  }
  # Also produce a versioned artifact such as <appname>-<version>.fpk
  $ManifestText = Get-Content -LiteralPath (Join-Path $ProjectRoot "manifest") -Raw
  $AppName = [regex]::Match(
    $ManifestText,
    '(?m)^appname\s*=\s*(\S+)\s*$'
  ).Groups[1].Value
  $Version = [regex]::Match(
    $ManifestText,
    '(?m)^version\s*=\s*([0-9.]+)\s*$'
  ).Groups[1].Value
  if (-not $AppName) {
    throw "Unable to parse appname from manifest"
  }
  if (-not $Version) {
    throw "Unable to parse version from manifest"
  }
  $Named = Join-Path $ProjectRoot "$AppName-$Version.fpk"
  Copy-Item -LiteralPath (Join-Path $DistDir "$AppName.fpk") -Destination $Named -Force
  Write-Host "Versioned artifact generated: $Named"
}
finally {
  Pop-Location
}

Write-Host ""
Write-Host "FPK generated: $DistDir\$AppName.fpk"
