param(
    [string]$KeystorePath = "$HOME\keys\sti-evoter-release.jks",
    [string]$Alias = "sti-evoter"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$propsPath = Join-Path $projectRoot "android\key.properties"

if (Test-Path $propsPath) {
    Write-Host "android\key.properties already exists. Keep using that keystore; delete the file only if you really mean to replace it."
    exit 0
}

$keytool = (Get-Command keytool -ErrorAction SilentlyContinue).Source
if (-not $keytool) {
    $candidate = "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
    if (Test-Path $candidate) { $keytool = $candidate } else { throw "keytool was not found. Install a JDK or Android Studio." }
}

$bytes = New-Object byte[] 24
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$password = -join ($bytes | ForEach-Object { $_.ToString("x2") })

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $KeystorePath) | Out-Null
& $keytool -genkeypair -v -keystore $KeystorePath -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 `
    -alias $Alias -storepass $password -keypass $password `
    -dname "CN=STI eVoter, OU=STI Legazpi, O=STI College Legazpi, L=Legazpi City, C=PH"
if ($LASTEXITCODE -ne 0) { throw "keytool failed." }

$storeFile = $KeystorePath.Replace("\", "/")
@"
storePassword=$password
keyPassword=$password
keyAlias=$Alias
storeFile=$storeFile
"@ | Set-Content -Path $propsPath -Encoding ascii

Write-Host ""
Write-Host "Keystore created: $KeystorePath"
Write-Host "Signing settings: android\key.properties (not committed to git)"
Write-Host "BACK UP BOTH FILES somewhere safe. Without them you cannot publish updates that install over this app."
