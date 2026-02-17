param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("ja", "zh", "en")]
    [string]$Lang = "ja",

    [Parameter(Mandatory = $false)]
    [int]$Port,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$LibDir = Join-Path $PSScriptRoot "lib"
. (Join-Path $LibDir "i18n.ps1")
. (Join-Path $LibDir "menu.ps1")
. (Join-Path $LibDir "firewall.ps1")

$__i18n = Initialize-I18n -Lang $Lang -BaseDir (Split-Path $PSScriptRoot -Parent)
function T([string]$Key, [object[]]$FormatArgs = @()) { Get-I18nText -I18n $__i18n -Key $Key -FormatArgs $FormatArgs }

function Read-PortInput([string]$Prompt) {
    $v = Read-HostWithEsc -Prompt $Prompt
    if ($null -eq $v) {
        Write-Host (T "Common.Cancelled") -ForegroundColor Yellow
        exit 99
    }
    if (-not ($v -match "^\d+$")) {
        Write-Host (T "Fw.Error.InvalidPort") -ForegroundColor Red
        exit 1
    }
    return [int]$v
}

if ($Port -le 0) {
    $Port = Read-PortInput (T "Fw.Prompt.Port")
}

try {
    $targets = @(Get-AllowInboundRulesByPort -Port $Port)
    if ($targets.Count -eq 0) {
        Write-Host (T "Fw.Remove.NotFound" @($Port)) -ForegroundColor Yellow
        return
    }

    Write-Host (T "Fw.Remove.Found" @($Port, $targets.Count)) -ForegroundColor Cyan
    $targets |
        Select-Object `
            @{ Name = (T "Fw.Table.DisplayName"); Expression = { $_.DisplayName } }, `
            @{ Name = (T "Fw.Table.Protocol"); Expression = { $_.Protocol } }, `
            @{ Name = (T "Fw.Table.LocalPort"); Expression = { $_.LocalPort } }, `
            @{ Name = (T "Fw.Table.Profile"); Expression = { $_.Profile } } |
        Format-Table -AutoSize

    if (-not $Force) {
        Write-Host ""
        $confirm = Read-HostWithEsc -Prompt (T "Fw.Remove.Confirm" @($Port))
        if ($null -eq $confirm) {
            Write-Host (T "Common.Cancelled") -ForegroundColor Yellow
            exit 99
        }
        $normalized = $confirm.Trim().ToLowerInvariant()
        if ($normalized -ne "yes" -and $normalized -ne "y") {
            Write-Host (T "Common.Cancelled") -ForegroundColor Yellow
            exit 99
        }
    }

    $removed = @(Remove-AllowInboundRulesByPort -Port $Port)
    Write-Host ""
    Write-Host (T "Fw.Remove.Success" @($Port, $removed.Count)) -ForegroundColor Green
}
catch {
    Write-Host (T "Fw.Error.OperationFailed" @($_.Exception.Message)) -ForegroundColor Red
    exit 1
}

