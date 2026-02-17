Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-PortTokenMatch {
    param(
        [Parameter(Mandatory = $true)][string]$Token,
        [Parameter(Mandatory = $true)][int]$Port
    )

    $t = $Token.Trim()
    if ([string]::IsNullOrWhiteSpace($t)) { return $false }
    if ($t -eq "Any") { return $false }
    if ($t -match "^\d+$") { return ([int]$t -eq $Port) }
    if ($t -match "^(\d+)-(\d+)$") {
        $start = [int]$matches[1]
        $end = [int]$matches[2]
        return ($Port -ge $start -and $Port -le $end)
    }
    return $false
}

function Test-LocalPortMatch {
    param(
        [Parameter(Mandatory = $true)][string]$LocalPortValue,
        [Parameter(Mandatory = $true)][int]$Port
    )

    $tokens = $LocalPortValue -split ","
    foreach ($token in $tokens) {
        if (Test-PortTokenMatch -Token $token -Port $Port) { return $true }
    }
    return $false
}

function Get-AllowInboundRulesByPort {
    param(
        [Parameter(Mandatory = $true)][int]$Port
    )

    $result = @()
    $filters = @(Get-NetFirewallPortFilter -All -ErrorAction Stop)
    foreach ($filter in $filters) {
        $localPort = [string]$filter.LocalPort
        if (-not (Test-LocalPortMatch -LocalPortValue $localPort -Port $Port)) { continue }

        $rules = @(Get-NetFirewallRule -AssociatedNetFirewallPortFilter $filter -ErrorAction SilentlyContinue)
        if ($rules.Count -eq 0) { continue }

        foreach ($rule in $rules) {
            if ($rule.Enabled -ne "True") { continue }
            if ($rule.Direction -ne "Inbound") { continue }
            if ($rule.Action -ne "Allow") { continue }

            $result += [PSCustomObject]@{
                Name        = $rule.Name
                DisplayName = $rule.DisplayName
                Enabled     = $rule.Enabled
                Action      = $rule.Action
                Direction   = $rule.Direction
                Profile     = $rule.Profile
                Protocol    = $filter.Protocol
                LocalPort   = $localPort
                RemotePort  = $filter.RemotePort
            }
        }
    }

    return $result | Sort-Object DisplayName -Unique
}

function New-AllowInboundRuleForPort {
    param(
        [Parameter(Mandatory = $true)][int]$Port,
        [Parameter(Mandatory = $false)][ValidateSet("TCP", "UDP", "Any")][string]$Protocol = "TCP"
    )

    $ruleName = "NetTools-Allow-Port-$Port-$Protocol"
    $exists = @(Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)
    if ($exists.Count -gt 0) {
        return [PSCustomObject]@{
            Created  = $false
            RuleName = $ruleName
        }
    }

    $null = New-NetFirewallRule `
        -DisplayName $ruleName `
        -Direction Inbound `
        -Action Allow `
        -Enabled True `
        -Protocol $Protocol `
        -LocalPort $Port `
        -Profile Any

    return [PSCustomObject]@{
        Created  = $true
        RuleName = $ruleName
    }
}

function Remove-AllowInboundRulesByPort {
    param(
        [Parameter(Mandatory = $true)][int]$Port
    )

    $targets = @(Get-AllowInboundRulesByPort -Port $Port)
    foreach ($target in $targets) {
        Remove-NetFirewallRule -Name $target.Name -ErrorAction Stop
    }

    return $targets
}
