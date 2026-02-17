param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("ja", "zh", "en")]
    [string]$Lang = "ja",

    [Parameter(Mandatory = $false)]
    [string]$ListenAddress,

    [Parameter(Mandatory = $false)]
    [int]$ListenPort,

    [Parameter(Mandatory = $false)]
    [string]$ConnectAddress,

    [Parameter(Mandatory = $false)]
    [int]$ConnectPort
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$LibDir = Join-Path $PSScriptRoot "lib"
. (Join-Path $LibDir "i18n.ps1")
. (Join-Path $LibDir "menu.ps1")
. (Join-Path $LibDir "portproxy.ps1")
. (Join-Path $LibDir "firewall.ps1")

$__i18n = Initialize-I18n -Lang $Lang -BaseDir (Split-Path $PSScriptRoot -Parent)
function T([string]$Key, [object[]]$FormatArgs = @()) { Get-I18nText -I18n $__i18n -Key $Key -FormatArgs $FormatArgs }

if (-not (Test-IsAdministrator)) {
    Write-Host (T "Nat.Error.AdminRequired") -ForegroundColor Red
    exit 1
}

function Read-RequiredInput([string]$Prompt) {
    $value = Read-HostWithEsc -Prompt $Prompt
    if ($null -eq $value) {
        Write-Host (T "Common.Cancelled") -ForegroundColor Yellow
        exit 99
    }
    if ([string]::IsNullOrWhiteSpace($value)) {
        Write-Host (T "Common.Required") -ForegroundColor Red
        exit 1
    }
    return $value.Trim()
}

function Read-InputWithDefault([string]$Prompt, [string]$DefaultValue) {
    $value = Read-HostWithEsc -Prompt $Prompt
    if ($null -eq $value) {
        Write-Host (T "Common.Cancelled") -ForegroundColor Yellow
        exit 99
    }
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $DefaultValue
    }
    return $value.Trim()
}

try {
    if ([string]::IsNullOrWhiteSpace($ListenAddress)) {
        $ListenAddress = Read-InputWithDefault -Prompt (T "Nat.Prompt.ListenAddress") -DefaultValue "0.0.0.0"
    }
    if ($ListenPort -le 0) {
        $ListenPort = [int](Read-RequiredInput (T "Nat.Prompt.ListenPort"))
    }
    if ([string]::IsNullOrWhiteSpace($ConnectAddress)) {
        $ConnectAddress = Read-RequiredInput (T "Nat.Prompt.ConnectAddress")
    }
    if ($ConnectPort -le 0) {
        $ConnectPort = [int](Read-RequiredInput (T "Nat.Prompt.ConnectPort"))
    }

    $exists = Get-PortProxyMappings | Where-Object {
        $_.ListenAddress -eq $ListenAddress -and $_.ListenPort -eq $ListenPort
    }
    if ($null -ne $exists) {
        Write-Host (T "Nat.Error.AlreadyExists" @($ListenAddress, $ListenPort)) -ForegroundColor Red
        exit 1
    }

    Add-PortProxyMapping -ListenAddress $ListenAddress -ListenPort $ListenPort -ConnectAddress $ConnectAddress -ConnectPort $ConnectPort
    Write-Host (T "Nat.New.Success") -ForegroundColor Green
    Write-Host ""
    [PSCustomObject]@{
        (T "Nat.Table.ListenAddress")  = $ListenAddress
        (T "Nat.Table.ListenPort")     = $ListenPort
        (T "Nat.Table.ConnectAddress") = $ConnectAddress
        (T "Nat.Table.ConnectPort")    = $ConnectPort
        (T "Nat.Table.Protocol")       = "v4tov4"
    } | Format-Table -AutoSize

    try {
        $fwRules = @(Get-AllowInboundRulesByPort -Port $ListenPort)
        if ($fwRules.Count -gt 0) {
            Write-Host ""
            Write-Host (T "Nat.New.FwAlreadyOpen" @($ListenPort, $fwRules.Count)) -ForegroundColor DarkYellow
        }
        else {
            $fwResult = New-AllowInboundRuleForPort -Port $ListenPort -Protocol "TCP"
            Write-Host ""
            if ($fwResult.Created) {
                Write-Host (T "Nat.New.FwAutoOpened" @($ListenPort, $fwResult.RuleName)) -ForegroundColor Green
            }
            else {
                Write-Host (T "Nat.New.FwAlreadyOpenByName" @($ListenPort, $fwResult.RuleName)) -ForegroundColor DarkYellow
            }
        }
    }
    catch {
        Write-Host ""
        Write-Host (T "Nat.New.FwAutoOpenFailed" @($ListenPort, $_.Exception.Message)) -ForegroundColor Yellow
    }
}
catch {
    Write-Host (T "Nat.Error.OperationFailed" @($_.Exception.Message)) -ForegroundColor Red
    exit 1
}
