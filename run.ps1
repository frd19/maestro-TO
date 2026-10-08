<#
.SYNOPSIS
  Helper menjalankan test Maestro untuk workspace TMS Planner (Android).

.EXAMPLE
  # Jalankan seluruh suite (urutan: TC-01 -> TC-02 -> TC-03)
  .\run.ps1

  # Jalankan 1 flow saja
  .\run.ps1 -Flow "flows/TC-01-login.yaml"

  # Pakai kredensial lain
  .\run.ps1 -Email "qa@mail.com" -Password "Rahasia123!"
#>
param(
  [string]$Flow = ".",
  [string]$Email = "om@gmail.com",
  [string]$Password = "Password123!",
  [string]$DeviceId = "RRGL707WSTA"   # tablet Samsung Galaxy Tab A11+
)

$ErrorActionPreference = "Stop"

# Cari CLI Maestro: pakai PATH dulu, fallback ke lokasi instalasi
$maestro = Get-Command maestro -ErrorAction SilentlyContinue
if ($maestro) {
  $cmd = $maestro.Source
} elseif (Test-Path "C:\maestro\maestro\bin\maestro.bat") {
  $cmd = "C:\maestro\maestro\bin\maestro.bat"
} else {
  Write-Error "Maestro CLI tidak ditemukan. Buka terminal baru (PATH baru saja diupdate)."
  exit 1
}

# Pastikan layar tidak mati di tengah test (pencegahan kegagalan seperti run pertama)
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (Test-Path $adb) {
  & $adb shell settings put system screen_off_timeout 1800000 2>$null
  & $adb shell svc power stayon true 2>$null
}

& $cmd test $Flow `
  --device $DeviceId `
  -e "LOGIN_EMAIL=$Email" `
  -e "LOGIN_PASSWORD=$Password"

exit $LASTEXITCODE
