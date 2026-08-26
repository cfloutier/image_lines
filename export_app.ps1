# Exports this Processing sketch as a standalone application (no Processing/Java/
# ControlP5 install needed by end users) via the processing-java CLI, copies
# Settings/ into the export (the export does NOT include it, and LoadSettings()
# crashes on startup without a Settings/default.json to load), then zips the result
# into releases/ as a single file ready to hand out.
#
# This script is meant to be copied as-is into every project's root folder (same
# convention as the shared xLib_*.pde files): it auto-detects the sketch name/path
# from its own location, so it never needs per-project edits - only -ProcessingPath
# if the Processing install location differs on another machine.
#
# Usage (from the project folder, or anywhere via full path):
#   .\export_app.ps1
#   .\export_app.ps1 -Variant windows-amd64
#   .\export_app.ps1 -ProcessingPath "D:\tools\processing-4.3\processing-java.exe"
#   .\export_app.ps1 -Zip $false   # skip the release zip, just produce the build folder
#
# IMPORTANT (verified empirically with Processing 4.3's processing-java on Windows):
# -Variant does NOT actually cross-compile for another OS - requesting linux-amd64
# from this Windows machine silently produced the exact same Windows .exe/.dll build
# anyway. To produce a real macOS or Linux build, run this script FROM a machine
# running that OS (with its own Processing install) - there is no cross-export from
# here. -Variant is kept only for whatever same-OS sub-variants it may genuinely
# support (e.g. picking between architectures on the host platform itself).

param(
  [string]$ProcessingPath = "C:\dev\FABLAB\processing-4.3\processing-java.exe",
  [string]$Variant = "windows-amd64",
  [bool]$Force = $true,
  [bool]$Zip = $true
)

$ErrorActionPreference = "Stop"

$SketchDir  = $PSScriptRoot
$SketchName = Split-Path $SketchDir -Leaf
$OutputDir  = Join-Path $SketchDir "build_$($Variant -replace '-','_')"

if (-not (Test-Path $ProcessingPath)) {
  Write-Error "processing-java.exe introuvable a: $ProcessingPath`nPasse -ProcessingPath <chemin> vers ton installation Processing."
  exit 1
}

Write-Host "Sketch   : $SketchName ($SketchDir)"
Write-Host "Variant  : $Variant"
Write-Host "Output   : $OutputDir"
Write-Host ""

if ($Variant -notlike "windows-*" -and $env:OS -like "*Windows*") {
  Write-Warning "Ce script tourne sur Windows: -Variant $Variant sera probablement ignore et un build Windows sera produit quand meme (verifie empiriquement avec Processing 4.3). Pour un vrai build $Variant, lance ce script depuis une machine de cet OS."
}

$exportArgs = @("--sketch=$SketchDir", "--output=$OutputDir")
if ($Force) { $exportArgs += "--force" }
$exportArgs += @("--export", "--variant=$Variant")

& $ProcessingPath @exportArgs
if ($LASTEXITCODE -ne 0) {
  Write-Error "Echec de l'export Processing (code $LASTEXITCODE)."
  exit $LASTEXITCODE
}

$SettingsSrc = Join-Path $SketchDir "Settings"
$SettingsDst = Join-Path $OutputDir "Settings"
if (Test-Path $SettingsSrc) {
  Write-Host ""
  Write-Host "Copie de Settings/ vers l'export (non inclus par processing-java --export)..."
  Copy-Item -Path $SettingsSrc -Destination $SettingsDst -Recurse -Force
} else {
  Write-Warning "Aucun dossier Settings/ a la racine du sketch - si LoadSettings() en depend au demarrage, l'app plantera a l'ouverture."
}

Write-Host ""
Write-Host "Termine : $OutputDir\$SketchName.exe"

if ($Zip) {
  $ReleasesDir = Join-Path $SketchDir "releases"
  if (-not (Test-Path $ReleasesDir)) { New-Item -ItemType Directory -Path $ReleasesDir | Out-Null }

  $DateStamp = Get-Date -Format "yyyy-MM-dd"
  $ZipPath   = Join-Path $ReleasesDir "$($SketchName)_$($Variant)_$DateStamp.zip"

  Write-Host ""
  Write-Host "Creation du zip de release..."
  # -Path "$OutputDir\*" (pas $OutputDir seul) pour que le zip contienne directement
  # spiral.exe etc. a sa racine, sans dossier intermediaire a la decompression.
  # Retente en cas de verrou transitoire (l'antivirus scanne souvent les fichiers du
  # JRE juste apres leur extraction et les verrouille brievement).
  $zipAttempts = 0
  $zipDone = $false
  while (-not $zipDone -and $zipAttempts -lt 5) {
    $zipAttempts++
    try {
      Compress-Archive -Path (Join-Path $OutputDir "*") -DestinationPath $ZipPath -Force -ErrorAction Stop
      $zipDone = $true
    } catch {
      if ($zipAttempts -ge 5) { throw }
      Write-Host "  fichier verrouille, nouvel essai dans 2s... ($zipAttempts/5)"
      Start-Sleep -Seconds 2
    }
  }

  Write-Host "Release : $ZipPath"
}
