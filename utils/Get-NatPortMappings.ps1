param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("ja", "zh", "en")]
    [string]$Lang = "ja"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$LibDir = Join-Path $PSScriptRoot "lib"
. (Join-Path $LibDir "i18n.ps1")
. (Join-Path $LibDir "portproxy.ps1")

$__i18n = Initialize-I18n -Lang $Lang -BaseDir (Split-Path $PSScriptRoot -Parent)
function T([string]$Key, [object[]]$FormatArgs = @()) { Get-I18nText -I18n $__i18n -Key $Key -FormatArgs $FormatArgs }

try {
    $items = @(Get-PortProxyMappings)
    if ($items.Count -eq 0) {
        Write-Host (T "Nat.List.Empty") -ForegroundColor Yellow
        return
    }

    Write-Host (T "Nat.List.Title") -ForegroundColor Cyan
    Write-Host ""
    $items |
        Select-Object `
            @{ Name = (T "Nat.Table.ListenAddress"); Expression = { $_.ListenAddress } }, `
            @{ Name = (T "Nat.Table.ListenPort"); Expression = { $_.ListenPort } }, `
            @{ Name = (T "Nat.Table.ConnectAddress"); Expression = { $_.ConnectAddress } }, `
            @{ Name = (T "Nat.Table.ConnectPort"); Expression = { $_.ConnectPort } }, `
            @{ Name = (T "Nat.Table.Protocol"); Expression = { $_.Protocol } } |
        Format-Table -AutoSize

    Write-Host ""
    Write-Host (T "Nat.List.Count" @($items.Count)) -ForegroundColor DarkGray
}
catch {
    Write-Host (T "Nat.Error.Netsh" @($_.Exception.Message)) -ForegroundColor Red
    exit 1
}
