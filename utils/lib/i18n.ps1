Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Initialize-I18n {
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("ja", "zh", "en")]
        [string]$Lang = "ja",
        [Parameter(Mandatory = $false)]
        [string]$BaseDir = ""
    )

    if ([string]::IsNullOrWhiteSpace($BaseDir)) { $BaseDir = $PSScriptRoot }
    $resDir = Join-Path $BaseDir "resources"
    $jaPath = Join-Path $resDir "strings.ja.psd1"
    $langPath = Join-Path $resDir ("strings.{0}.psd1" -f $Lang)

    if (-not (Test-Path -LiteralPath $jaPath -PathType Leaf)) {
        throw "Resource file not found: $jaPath"
    }

    $ja = Import-PowerShellDataFile -LiteralPath $jaPath
    $langTable = @{}
    if ($Lang -ne "ja" -and (Test-Path -LiteralPath $langPath -PathType Leaf)) {
        $langTable = Import-PowerShellDataFile -LiteralPath $langPath
    }

    return [PSCustomObject]@{
        Lang      = $Lang
        Ja        = $ja
        LangTable = $langTable
    }
}

function Get-I18nText {
    param(
        [Parameter(Mandatory = $true)]$I18n,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $false)][object[]]$FormatArgs = @()
    )

    $s = $null
    if ($null -ne $I18n.LangTable -and $I18n.LangTable.ContainsKey($Key)) {
        $s = $I18n.LangTable[$Key]
    }
    elseif ($null -ne $I18n.Ja -and $I18n.Ja.ContainsKey($Key)) {
        $s = $I18n.Ja[$Key]
    }

    if ([string]::IsNullOrWhiteSpace([string]$s)) { $s = $Key }
    if ($null -ne $FormatArgs -and $FormatArgs.Count -gt 0) {
        try { return ([string]$s -f $FormatArgs) } catch { }
    }
    return [string]$s
}

