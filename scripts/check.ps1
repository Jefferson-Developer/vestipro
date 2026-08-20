[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-QualityStep {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Name,
    [Parameter(Mandatory = $true)]
    [string] $Command,
    [Parameter(Mandatory = $true)]
    [string[]] $Arguments
  )

  Write-Host "==> $Name"
  & $Command @Arguments
  $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }

  if ($exitCode -ne 0) {
    Write-Error "$Name failed with exit code $exitCode."
    exit $exitCode
  }
}

function Test-TaskMarkers {
  $roots = @('lib', 'test', 'integration_test') |
    Where-Object { Test-Path -LiteralPath $_ }

  if ($roots.Count -eq 0) {
    return
  }

  $files = foreach ($root in $roots) {
    Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.dart' |
      Where-Object { $_.Name -notmatch '\.(freezed|g|config)\.dart$' }
  }

  $violations = @()

  foreach ($file in $files) {
    $lineNumber = 0

    foreach ($line in Get-Content -LiteralPath $file.FullName) {
      $lineNumber++

      if (
        $line -match '\b(TODO|FIXME)\b' -and
        $line -notmatch '(TASK-\d+|VESTI-\d+|#\d+|https?://)'
      ) {
        $violations += [pscustomobject] @{
          Path = $file.FullName
          Line = $lineNumber
          Text = $line.Trim()
        }
      }
    }
  }

  if ($violations.Count -gt 0) {
    Write-Error 'TODO/FIXME without task context found. Reference TASK-XXX, VESTI-XXX, issue #123, or a URL on the same line.'

    foreach ($violation in $violations) {
      Write-Host (
        '{0}:{1}: {2}' -f
        (Resolve-Path -LiteralPath $violation.Path -Relative),
        $violation.Line,
        $violation.Text
      )
    }

    exit 1
  }
}

Test-TaskMarkers
Invoke-QualityStep 'Checking Dart format' 'dart' @('format', '--set-exit-if-changed', '.')
Invoke-QualityStep 'Running Flutter analyzer' 'flutter' @('analyze')
