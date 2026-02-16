param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("ja", "zh", "en")]
    [string]$Lang = "ja",

    [Parameter(Mandatory = $false)]
    [string]$ListenAddress,

    [Parameter(Mandatory = $false)]
    [int]$ListenPort,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$LibDir = Join-Path $PSScriptRoot "lib"
. (Join-Path $LibDir "i18n.ps1")
. (Join-Path $LibDir "menu.ps1")
. (Join-Path $LibDir "portproxy.ps1")

$__i18n = Initialize-I18n -Lang $Lang -BaseDir (Split-Path $PSScriptRoot -Parent)
function T([string]$Key, [object[]]$FormatArgs = @()) { Get-I18nText -I18n $__i18n -Key $Key -FormatArgs $FormatArgs }

if (-not (Test-IsAdministrator)) {
    Write-Host (T "Nat.Error.AdminRequired") -ForegroundColor Red
    exit 1
}

try {
    if ([string]::IsNullOrWhiteSpace($ListenAddress) -or $ListenPort -le 0) {
        $items = @(Get-PortProxyMappings)
        if ($items.Count -eq 0) {
            Write-Host (T "Nat.List.Empty") -ForegroundColor Yellow
            exit 0
        }

        $menuItems = @()
        foreach ($item in $items) {
            $menuItems += "{0}:{1} -> {2}:{3}" -f $item.ListenAddress, $item.ListenPort, $item.ConnectAddress, $item.ConnectPort
        }
        $menuItems += (T "Common.MenuCancel")

        $selected = Show-MenuSelect -title (T "Nat.Remove.SelectTitle") -items $menuItems -helpText (T "Nat.Remove.SelectHint")
        if ($null -eq $selected -or $selected -eq $menuItems.Count) {
            Write-Host (T "Common.Cancelled") -ForegroundColor Yellow
            exit 99
        }

        $target = $items[$selected - 1]
        $ListenAddress = $target.ListenAddress
        $ListenPort = $target.ListenPort
    }

    if (-not $Force) {
        $confirm = Read-HostWithEsc -Prompt (T "Nat.Remove.Confirm" @($ListenAddress, $ListenPort))
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

    Remove-PortProxyMapping -ListenAddress $ListenAddress -ListenPort $ListenPort
    Write-Host (T "Nat.Remove.Success" @($ListenAddress, $ListenPort)) -ForegroundColor Green
}
catch {
    Write-Host (T "Nat.Error.OperationFailed" @($_.Exception.Message)) -ForegroundColor Red
    exit 1
}
