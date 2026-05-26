param(
  [string]$DeviceId = ""
)

$ErrorActionPreference = "Stop"

function Find-Adb {
  $adbCommand = Get-Command adb -ErrorAction SilentlyContinue
  if ($adbCommand) {
    return $adbCommand.Source
  }

  $candidates = @()
  if ($env:ANDROID_HOME) {
    $candidates += Join-Path $env:ANDROID_HOME "platform-tools\adb.exe"
  }
  if ($env:ANDROID_SDK_ROOT) {
    $candidates += Join-Path $env:ANDROID_SDK_ROOT "platform-tools\adb.exe"
  }
  if ($env:LOCALAPPDATA) {
    $candidates += Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
  }

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path $candidate)) {
      return $candidate
    }
  }

  $doctorOutput = flutter doctor -v 2>$null
  foreach ($line in $doctorOutput) {
    if ($line -match "Android SDK at (.+)$") {
      $fromDoctor = Join-Path $Matches[1].Trim() "platform-tools\adb.exe"
      if (Test-Path $fromDoctor) {
        return $fromDoctor
      }
    }
  }

  throw "Could not find adb.exe. Install Android SDK Platform Tools or add adb to PATH."
}

$adb = Find-Adb

if ([string]::IsNullOrWhiteSpace($DeviceId)) {
  & $adb reverse tcp:8080 tcp:8080
  flutter run --dart-define=USE_ADB_REVERSE=true
} else {
  & $adb -s $DeviceId reverse tcp:8080 tcp:8080
  flutter run -d $DeviceId --dart-define=USE_ADB_REVERSE=true
}
