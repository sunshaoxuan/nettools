param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("ja", "zh", "en")]
    [string]$Lang = "ja",

    [Parameter(Mandatory = $false)]
    [int]$Port
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
    $items = @(Get-AllowInboundRulesByPort -Port $Port)
    if ($items.Count -eq 0) {
        Write-Host (T "Fw.Check.Closed" @($Port)) -ForegroundColor Yellow
        return
    }

    Write-Host (T "Fw.Check.Opened" @($Port, $items.Count)) -ForegroundColor Green
    Write-Host ""
    $items |
        Select-Object `
            @{ Name = (T "Fw.Table.DisplayName"); Expression = { $_.DisplayName } }, `
            @{ Name = (T "Fw.Table.Protocol"); Expression = { $_.Protocol } }, `
            @{ Name = (T "Fw.Table.LocalPort"); Expression = { $_.LocalPort } }, `
            @{ Name = (T "Fw.Table.Profile"); Expression = { $_.Profile } } |
        Format-Table -AutoSize
}
catch {
    Write-Host (T "Fw.Error.OperationFailed" @($_.Exception.Message)) -ForegroundColor Red
    exit 1
}

