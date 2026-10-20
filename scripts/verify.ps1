param([string]$FlutterRoot, [string]$JavaHome, [switch]$SkipBuild, [switch]$Release)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $taskRoot
if ($JavaHome) { $env:JAVA_HOME = $JavaHome }
if ($FlutterRoot) {
    $env:FLUTTER_ROOT = $FlutterRoot
    $taskDart = Join-Path $FlutterRoot 'bin\cache\dart-sdk\bin\dart.exe'
    $taskFlutterTool = Join-Path $FlutterRoot 'bin\cache\flutter_tools.snapshot'
}
$taskSockets = Join-Path $taskRoot '.tools\sockets'
New-Item -ItemType Directory -Force $taskSockets | Out-Null
$env:JAVA_TOOL_OPTIONS = "$($env:JAVA_TOOL_OPTIONS) -Djdk.net.unixdomain.tmpdir=$taskSockets".Trim()
function Invoke-FlutterCheck([string[]]$Arguments) {
    if ($FlutterRoot) { & $taskDart $taskFlutterTool @Arguments }
    else { & flutter @Arguments }
    if ($LASTEXITCODE -ne 0) { throw "Flutter command failed: $($Arguments -join ' ')" }
}
Invoke-FlutterCheck -Arguments @('pub', 'get')
Invoke-FlutterCheck -Arguments @('analyze')
Invoke-FlutterCheck -Arguments @('test', '--reporter', 'expanded')
if (-not $SkipBuild) {
    $taskMode = if ($Release) { 'release' } else { 'debug' }
    $taskBuildArgs = @('build', 'apk', "--$taskMode")
    if ($Release) { $taskBuildArgs += '--split-per-abi' }
    Invoke-FlutterCheck -Arguments $taskBuildArgs
    New-Item -ItemType Directory -Force 'dist' | Out-Null
    $taskVersion = ((Select-String -Path 'pubspec.yaml' -Pattern '^version:').Line -replace '^version:\s*','').Split('+')[0]
    if ($Release) {
        foreach ($taskAbi in @('arm64-v8a', 'armeabi-v7a', 'x86_64')) {
            Copy-Item -LiteralPath "build\app\outputs\flutter-apk\app-$taskAbi-release.apk" -Destination "dist\Sketluma-$taskVersion-$taskAbi-release.apk" -Force
        }
    } else {
        Copy-Item -LiteralPath "build\app\outputs\flutter-apk\app-$taskMode.apk" -Destination "dist\Sketluma-$taskVersion-$taskMode.apk" -Force
    }
}
