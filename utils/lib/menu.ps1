Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Show-MenuSelect {
    param(
        [string]$title,
        [string[]]$items,
        [string]$helpText = ""
    )

    if ($null -eq $items -or $items.Count -eq 0) { return $null }
    $index = 0
    $readOpts = [System.Management.Automation.Host.ReadKeyOptions]"IncludeKeyDown,NoEcho,AllowCtrlC"

    while ($true) {
        try { [Console]::Clear() } catch { Clear-Host }
        Write-Host ""
        if (-not [string]::IsNullOrWhiteSpace($title)) { Write-Host $title }
        if (-not [string]::IsNullOrWhiteSpace($helpText)) { Write-Host $helpText }
        Write-Host ""

        for ($i = 0; $i -lt $items.Count; $i++) {
            $line = "  {0,2}) {1}" -f ($i + 1), $items[$i]
            if ($i -eq $index) {
                Write-Host $line -BackgroundColor White -ForegroundColor Black
            }
            else {
                Write-Host $line
            }
        }

        try {
            $key = $host.UI.RawUI.ReadKey($readOpts)
        }
        catch {
            return $null
        }

        switch ($key.VirtualKeyCode) {
            38 { $index = if ($index -le 0) { $items.Count - 1 } else { $index - 1 } }
            40 { $index = if ($index -ge $items.Count - 1) { 0 } else { $index + 1 } }
            13 { return ($index + 1) }
            27 { return $null }
        }
    }
}

function Read-HostWithEsc {
    param([string]$Prompt = "Input")

    Write-Host "${Prompt}: " -NoNewline
    $buffer = New-Object System.Text.StringBuilder
    while ($true) {
        $key = $host.UI.RawUI.ReadKey("IncludeKeyDown,NoEcho")
        if ($key.VirtualKeyCode -eq 27) {
            Write-Host ""
            return $null
        }
        if ($key.VirtualKeyCode -eq 13) {
            Write-Host ""
            return $buffer.ToString()
        }
        if ($key.VirtualKeyCode -eq 8) {
            if ($buffer.Length -gt 0) {
                $buffer.Length--
                $pos = $host.UI.RawUI.CursorPosition
                if ($pos.X -gt 0) {
                    $pos.X--
                    $host.UI.RawUI.CursorPosition = $pos
                    Write-Host " " -NoNewline
                    $host.UI.RawUI.CursorPosition = $pos
                }
            }
            continue
        }
        if ($key.Character -ne 0 -and -not [char]::IsControl($key.Character)) {
            $buffer.Append($key.Character) | Out-Null
            Write-Host $key.Character -NoNewline
        }
    }
}

function Wait-AnyKey {
    param([string]$Message = "Press any key to continue...")
    Write-Host $Message -NoNewline
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host ""
}
