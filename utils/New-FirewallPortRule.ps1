param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("ja", "zh", "en")]
    [string]$Lang = "ja",

    [Parameter(Mandatory = $false)]
    [int]$Port,

    [Parameter(Mandatory = $false)]
    [ValidateSet("TCP", "UDP", "Any")]
    [string]$Protocol = "TCP"
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
    $ret = New-AllowInboundRuleForPort -Port $Port -Protocol $Protocol
    if (-not $ret.Created) {
        Write-Host (T "Fw.New.AlreadyExists" @($ret.RuleName)) -ForegroundColor Yellow
        return
    }

    Write-Host (T "Fw.New.Success" @($ret.RuleName, $Port, $Protocol)) -ForegroundColor Green
}
catch {
    Write-Host (T "Fw.Error.OperationFailed" @($_.Exception.Message)) -ForegroundColor Red
    exit 1
}

