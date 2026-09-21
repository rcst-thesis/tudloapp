Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $projectRoot

try {
    flutter pub get
    flutter run -d chrome --web-hostname localhost --web-port 8080
}
finally {
    Pop-Location
}
