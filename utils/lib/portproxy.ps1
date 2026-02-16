Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-PortProxyMappings {
    $output = & netsh interface portproxy show v4tov4 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ($output | Out-String)
    }

    $rows = @()
    foreach ($line in $output) {
        $trimmed = [string]$line
        if ($trimmed -match "^\s*(\S+)\s+(\d+)\s+(\S+)\s+(\d+)\s*$") {
            $rows += [PSCustomObject]@{
                ListenAddress  = $matches[1]
                ListenPort     = [int]$matches[2]
                ConnectAddress = $matches[3]
                ConnectPort    = [int]$matches[4]
                Protocol       = "v4tov4"
            }
        }
    }
    return $rows
}

function Add-PortProxyMapping {
    param(
        [Parameter(Mandatory = $true)][string]$ListenAddress,
        [Parameter(Mandatory = $true)][int]$ListenPort,
        [Parameter(Mandatory = $true)][string]$ConnectAddress,
        [Parameter(Mandatory = $true)][int]$ConnectPort
    )

    $args = @(
        "interface", "portproxy", "add", "v4tov4",
        "listenaddress=$ListenAddress",
        "listenport=$ListenPort",
        "connectaddress=$ConnectAddress",
        "connectport=$ConnectPort"
    )

    $output = & netsh @args 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ($output | Out-String)
    }
}

function Remove-PortProxyMapping {
    param(
        [Parameter(Mandatory = $true)][string]$ListenAddress,
        [Parameter(Mandatory = $true)][int]$ListenPort
    )

    $args = @(
        "interface", "portproxy", "delete", "v4tov4",
        "listenaddress=$ListenAddress",
        "listenport=$ListenPort"
    )

    $output = & netsh @args 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ($output | Out-String)
    }
}

