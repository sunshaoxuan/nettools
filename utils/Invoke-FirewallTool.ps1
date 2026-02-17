param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("ja", "zh", "en")]
    [string]$Lang = "ja"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$LibDir = Join-Path $PSScriptRoot "lib"
. (Join-Path $LibDir "menu.ps1")
. (Join-Path $LibDir "i18n.ps1")

$__i18n = Initialize-I18n -Lang $Lang -BaseDir (Split-Path $PSScriptRoot -Parent)
function T([string]$Key, [object[]]$FormatArgs = @()) { Get-I18nText -I18n $__i18n -Key $Key -FormatArgs $FormatArgs }

$tools = @(
    @{
        Name   = "Check"
        Script = "Get-FirewallPortStatus.ps1"
        DescJa = "ポートが開放済みか確認"
        DescZh = "检查端口是否已开放"
        DescEn = "Check if port is open"
    },
    @{
        Name   = "Open"
        Script = "New-FirewallPortRule.ps1"
        DescJa = "ポートを快速開放"
        DescZh = "快速开放端口"
        DescEn = "Quickly open port"
    },
    @{
        Name   = "Delete"
        Script = "Remove-FirewallPortRule.ps1"
        DescJa = "開放ルールを快速削除"
        DescZh = "快速删除开放规则"
        DescEn = "Quickly delete open rules"
    }
)

function Get-ToolDesc($tool) {
    switch ($Lang) {
        "zh" { return $tool.DescZh }
        "en" { return $tool.DescEn }
        default { return $tool.DescJa }
    }
}

while ($true) {
    $menuItems = @()
    foreach ($tool in $tools) {
        $scriptPath = Join-Path $PSScriptRoot $tool.Script
        $status = if (Test-Path -LiteralPath $scriptPath -PathType Leaf) { "" } else { " [N/A]" }
        $menuItems += "{0,-8} - {1}{2}" -f $tool.Name, (Get-ToolDesc $tool), $status
    }
    $menuItems += (T "Common.MenuCancel")

    $selection = Show-MenuSelect -title (T "Fw.Menu.Title") -items $menuItems -helpText (T "Fw.Menu.Help")
    if ($null -eq $selection -or $selection -eq $menuItems.Count) {
        exit 99
    }

    $selectedTool = $tools[$selection - 1]
    $scriptPath = Join-Path $PSScriptRoot $selectedTool.Script
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        Write-Host (T "Common.FileNotFound" @("Script", $scriptPath)) -ForegroundColor Red
        Wait-AnyKey -Message (T "Common.PressAnyKey")
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

    Write-Host ""
    Wait-AnyKey -Message (T "Common.PressAnyKey")
}

