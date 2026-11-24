param(
    [Parameter(Mandatory = $true)]
    [string]$ApiUrl,
    [string]$Notes = "",
    [switch]$Mandatory,
    [int]$MinBuild = 0,
    [switch]$SkipAndroid,
    [switch]$SkipWindows
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$ApiUrl = $ApiUrl.TrimEnd("/")
if ($ApiUrl -notmatch "^https://") {
    throw "ApiUrl must start with https:// (for example https://your-name.duckdns.org)."
}

$version = (Select-String -Path pubspec.yaml -Pattern "^version:\s*(\S+)").Matches[0].Groups[1].Value
$name = ($version -split "\+")[0]
$build = [int](($version -split "\+")[1])
$manifest = [ordered]@{}
$dist = Join-Path $projectRoot "dist"
New-Item -ItemType Directory -Force -Path $dist | Out-Null

Write-Host "Building STI eVoter $version for $ApiUrl"
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed." }

if (-not $SkipAndroid) {
    if (-not (Test-Path "android\key.properties")) {
        throw "android\key.properties is missing. Run scripts\create_keystore.ps1 first."
    }
    flutter build apk --release --dart-define=API_URL=$ApiUrl
    if ($LASTEXITCODE -ne 0) { throw "Android build failed." }
    $apk = Join-Path $dist "STI-eVoter-$name.apk"
    Copy-Item "build\app\outputs\flutter-apk\app-release.apk" $apk -Force
    $manifest["android"] = [ordered]@{ version = $name; build = $build; file = (Split-Path $apk -Leaf); notes = $Notes; mandatory = [bool]$Mandatory; minBuild = $MinBuild }
    Write-Host "Android: $apk"
}

if (-not $SkipWindows) {
    flutter build windows --release --dart-define=API_URL=$ApiUrl
    if ($LASTEXITCODE -ne 0) { throw "Windows build failed." }
    $release = "build\windows\x64\runner\Release"
    foreach ($dll in "msvcp140.dll", "vcruntime140.dll", "vcruntime140_1.dll") {
        $src = Join-Path $env:WINDIR "System32\$dll"
        if (Test-Path $src) { Copy-Item $src $release -Force }
    }
    $zip = Join-Path $dist "STI-eVoter-$name-windows.zip"
    if (Test-Path $zip) { Remove-Item $zip -Force }
    Compress-Archive -Path "$release\*" -DestinationPath $zip
    $manifest["windows"] = [ordered]@{ version = $name; build = $build; file = (Split-Path $zip -Leaf); notes = $Notes; mandatory = [bool]$Mandatory; minBuild = $MinBuild }
    Write-Host "Windows: $zip"
}

$manifest | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $dist "version.json") -Encoding utf8
Write-Host "Update manifest: $(Join-Path $dist 'version.json')"
Write-Host "Done. Files are in $dist"
Write-Host "To publish as an in-app update, copy the dist files to the server's deploy/downloads folder (see DEPLOY.md)."
Write-Host "Before the next release, raise the build number in pubspec.yaml (for example 1.0.1+2)."
