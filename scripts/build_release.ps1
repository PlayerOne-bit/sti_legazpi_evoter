param(
    [Parameter(Mandatory = $true)]
    [string]$ApiUrl,
    [string]$Notes = "",
    [switch]$Mandatory,
    [int]$MinBuild = 0,
    [switch]$SkipAndroid,
    [switch]$SkipWindows,
    [switch]$GitHubRelease
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$ApiUrl = $ApiUrl.TrimEnd("/")
if ($ApiUrl -notmatch "^https://") {
    throw "ApiUrl must start with https:// (for example https://sti-evoter-api.onrender.com)."
}

$version = (Select-String -Path pubspec.yaml -Pattern "^version:\s*(\S+)").Matches[0].Groups[1].Value
$name = ($version -split "\+")[0]
$build = [int](($version -split "\+")[1])
$manifest = [ordered]@{}
$files = @()

function New-Entry($path) {
    $info = Get-Item $path
    [ordered]@{
        version = $name; build = $build; file = $info.Name; notes = $Notes
        mandatory = [bool]$Mandatory; minBuild = $MinBuild
        sha256 = (Get-FileHash $path -Algorithm SHA256).Hash.ToLowerInvariant(); size = $info.Length
    }
}
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
    $manifest["android"] = New-Entry $apk
    $files += $apk
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

    # A debug run of the app while this builds can leave the debug engine in the Release folder,
    # and then the app closes at once. Check the engine is the release one.
    $flutterRoot = Split-Path -Parent (Split-Path -Parent (Get-Command flutter).Source)
    $engine = Join-Path $flutterRoot "bin\cache\artifacts\engine\windows-x64-release\flutter_windows.dll"
    if ((Test-Path $engine) -and
        (Get-FileHash $engine).Hash -ne (Get-FileHash (Join-Path $release "flutter_windows.dll")).Hash) {
        throw "The Windows build has the debug Flutter engine. Stop any running debug session of the app, then run this script again."
    }

    # Start the app once to make sure it opens.
    $proc = Start-Process (Join-Path $release "sti_legazpi_evoter.exe") -PassThru
    Start-Sleep -Seconds 8
    if ($proc.HasExited) { throw "The Windows app closed right after starting (exit code $($proc.ExitCode))." }
    Stop-Process -Id $proc.Id -Force
    Start-Sleep -Seconds 1
    $zip = Join-Path $dist "STI-eVoter-$name-windows.zip"
    if (Test-Path $zip) { Remove-Item $zip -Force }
    Compress-Archive -Path "$release\*" -DestinationPath $zip
    $manifest["windows"] = New-Entry $zip
    $files += $zip
    Write-Host "Windows: $zip"
}

$manifestPath = Join-Path $dist "version.json"
$json = $manifest | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText($manifestPath, $json, (New-Object System.Text.UTF8Encoding $false))
$files += $manifestPath
Write-Host "Update manifest: $manifestPath"
Write-Host "Done. Files are in $dist"

if ($GitHubRelease) {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw "GitHub CLI (gh) is not installed. Get it from https://cli.github.com" }
    if ($SkipAndroid -or $SkipWindows) { Write-Warning "This release only has some platforms. The latest release is what the app reads, so the skipped platform will show no update." }
    $releaseNotes = if ($Notes) { $Notes } else { "STI eVoter $name" }
    gh release create "v$name" @files --title "STI eVoter $name" --notes $releaseNotes --latest
    if ($LASTEXITCODE -ne 0) { throw "gh release create failed. If v$name already exists, raise the version in pubspec.yaml." }
    Write-Host "Published GitHub release v$name. The server picks it up within 5 minutes."
} else {
    Write-Host "To publish: copy the dist files to the server's deploy/downloads folder (DEPLOY.md), or run again with -GitHubRelease (DEPLOY-RENDER.md)."
}
Write-Host "Before the next release, raise the build number in pubspec.yaml (for example 1.0.1+2)."
