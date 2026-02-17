<#
.SYNOPSIS
ネットワークツールキット - NAT ポートマッピング管理
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("ja", "zh", "en")]
    [string]$Lang = "ja"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $OutputEncoding = [Console]::OutputEncoding
}
catch { }

$ToolkitVersion = "1.0.0"
$ToolkitLastUpdated = "2026-02-16"

$ScriptsDir = Join-Path $PSScriptRoot "utils"
$LibDir = Join-Path $ScriptsDir "lib"

. (Join-Path $LibDir "menu.ps1")
. (Join-Path $LibDir "i18n.ps1")
. (Join-Path $LibDir "portproxy.ps1")

$__i18n = Initialize-I18n -Lang $Lang -BaseDir $PSScriptRoot

function T([string]$Key, [object[]]$FormatArgs = @()) {
    return Get-I18nText -I18n $__i18n -Key $Key -FormatArgs $FormatArgs
}

if (-not (Test-IsAdministrator)) {
    Write-Host ""
    Write-Host (T "Toolkit.AdminRequired") -ForegroundColor Red
    Write-Host ""
    exit 1
}

$tools = @(
    @{
        Name   = "NAT"
        Script = "utils\Invoke-NatTool.ps1"
        DescJa = "NAT ポートマッピング管理"
        DescZh = "NAT 端口映射管理"
        DescEn = "NAT port mapping manager"
        Wait   = $true
    },
    @{
        Name   = "Firewall"
        Script = "utils\Invoke-FirewallTool.ps1"
        DescJa = "ファイアウォールポート管理"
        DescZh = "防火墙端口管理"
        DescEn = "Firewall port manager"
        Wait   = $true
    }
)

function Get-ToolDesc($tool) {
    switch ($Lang) {
        "zh" { return $tool.DescZh }
        "en" { return $tool.DescEn }
        default { return $tool.DescJa }
    }
}

function Get-BannerText {
    return @"
==============================================
 $(T "Toolkit.Banner.Title")
 $(T "Toolkit.Banner.Version" @($ToolkitVersion))
==============================================
"@
}

function Show-MainMenu {
    $menuItems = @()
    foreach ($tool in $tools) {
        $scriptPath = Join-Path $PSScriptRoot $tool.Script
        $status = if (Test-Path -LiteralPath $scriptPath -PathType Leaf) { "" } else { " [N/A]" }
        $menuItems += "{0,-12} - {1}{2}" -f $tool.Name, (Get-ToolDesc $tool), $status
    }
    $menuItems += (T "Common.MenuQuit")
    return $menuItems
}

try { [Console]::CursorVisible = $false } catch { }

try {
    while ($true) {
        $menuItems = Show-MainMenu
        $titleText = "{0}`n{1}" -f (Get-BannerText), (T "Toolkit.Menu.Title")
        $selection = Show-MenuSelect -title $titleText -items $menuItems

        if ($null -eq $selection -or $selection -eq $menuItems.Count) {
            Clear-Host
            Write-Host ""
            Write-Host (T "Toolkit.Exit.Thanks") -ForegroundColor Green
            Write-Host (T "Toolkit.Exit.VersionLine" @($ToolkitVersion)) -ForegroundColor Gray
            Write-Host (T "Toolkit.Exit.UpdatedLine" @($ToolkitLastUpdated)) -ForegroundColor Gray
            Write-Host ""
            break
        }

        $selectedTool = $tools[$selection - 1]
        $scriptPath = Join-Path $PSScriptRoot $selectedTool.Script
        if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
            Write-Host (T "Common.FileNotFound" @("Script", $scriptPath)) -ForegroundColor Red
            Start-Sleep -Seconds 1
            continue
        }

        Clear-Host
        Write-Host ""
        Write-Host (T "Toolkit.StartingTool" @($selectedTool.Name)) -ForegroundColor Yellow
        Write-Host ""
        try {
            & $scriptPath -Lang $Lang
        }
        catch {
            Write-Host (T "Common.Error" @($_.Exception.Message)) -ForegroundColor Red
        }

        if ($selectedTool.Wait) {
            Write-Host ""
            Wait-AnyKey -Message (T "Common.PressAnyKey")
        }
    }
}
finally {
    try { [Console]::CursorVisible = $true } catch { }
    try { [Console]::ResetColor() } catch { }
}
