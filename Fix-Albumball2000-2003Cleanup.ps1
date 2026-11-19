# Fix-Albumball2000-2003Cleanup.ps1
#
# Surgical cleanup after the 1999-2005 image migration.
#
# 2000:
#   Corrects the previously missed Dropbox image URL.
#
# 2003:
#   Changes width=100% to width="310" ONLY on the image tag
#   containing ../../Images/2003.jpg.
#
# Nothing else is intentionally changed.

$Root = Join-Path $PSScriptRoot "albumball"

$TotalFilesChanged = 0

Write-Host ""
Write-Host "Albumball surgical cleanup" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor DarkGray


# ============================================================
# 2000
# ============================================================

$Dailies2000 = Join-Path $Root "2000\dailies"

$Old2000 = "http://dl.dropbox.com/u/3641528/Dailies/2000/shellac1000hurts.jpg"
$New2000 = "../../Images/2000.jpg"

$Changed2000 = 0
$Replacements2000 = 0

Write-Host ""
Write-Host "Albumball 2000" -ForegroundColor Yellow

if (Test-Path -LiteralPath $Dailies2000) {

    $Files = @(
        Get-ChildItem -LiteralPath $Dailies2000 -File |
        Where-Object {
            $_.Extension -ieq ".html" -or
            $_.Extension -ieq ".htm"
        }
    )

    foreach ($File in $Files) {

        $Content = Get-Content -LiteralPath $File.FullName -Raw

        $Count = (
            [regex]::Matches(
                $Content,
                [regex]::Escape($Old2000)
            )
        ).Count

        if ($Count -eq 0) {
            continue
        }

        $Content = $Content.Replace($Old2000, $New2000)

        Set-Content `
            -LiteralPath $File.FullName `
            -Value $Content `
            -Encoding UTF8 `
            -NoNewline

        $Changed2000++
        $Replacements2000 += $Count
        $TotalFilesChanged++
    }

    Write-Host "  Files examined: $($Files.Count)"
    Write-Host "  Files changed:  $Changed2000" -ForegroundColor Green
    Write-Host "  URLs fixed:     $Replacements2000"
}
else {
    Write-Host "  SKIPPED - no dailies folder" -ForegroundColor Red
}


# ============================================================
# 2003
# ============================================================

$Dailies2003 = Join-Path $Root "2003\dailies"

$Changed2003 = 0
$WidthChanges2003 = 0

Write-Host ""
Write-Host "Albumball 2003" -ForegroundColor Yellow

if (Test-Path -LiteralPath $Dailies2003) {

    $Files = @(
        Get-ChildItem -LiteralPath $Dailies2003 -File |
        Where-Object {
            $_.Extension -ieq ".html" -or
            $_.Extension -ieq ".htm"
        }
    )

    foreach ($File in $Files) {

        $Content = Get-Content -LiteralPath $File.FullName -Raw
        $OriginalContent = $Content

        # Only alter width=100% inside an img tag that points
        # to the migrated 2003 image.

        $Pattern = '(<img\b[^>]*src=["''][^"'']*\.\./\.\./Images/2003\.jpg["''][^>]*?)width\s*=\s*["'']?100%["'']?([^>]*>)'

        $Matches = [regex]::Matches(
            $Content,
            $Pattern,
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        if ($Matches.Count -gt 0) {

            $Content = [regex]::Replace(
                $Content,
                $Pattern,
                '$1width="310"$2',
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            )

            $WidthChanges2003 += $Matches.Count
        }

        if ($Content -ne $OriginalContent) {

            Set-Content `
                -LiteralPath $File.FullName `
                -Value $Content `
                -Encoding UTF8 `
                -NoNewline

            $Changed2003++
            $TotalFilesChanged++
        }
    }

    Write-Host "  Files examined: $($Files.Count)"
    Write-Host "  Files changed:  $Changed2003" -ForegroundColor Green
    Write-Host "  Widths fixed:   $WidthChanges2003"
}
else {
    Write-Host "  SKIPPED - no dailies folder" -ForegroundColor Red
}


# ============================================================
# SUMMARY
# ============================================================

Write-Host ""
Write-Host "===========================" -ForegroundColor DarkGray
Write-Host "DONE" -ForegroundColor Green
Write-Host ""
Write-Host "2000 URLs fixed:   $Replacements2000"
Write-Host "2003 widths fixed: $WidthChanges2003"
Write-Host "Total files changed: $TotalFilesChanged"
Write-Host ""