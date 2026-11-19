# Fix-Albumball2009Paths.ps1
#
# Fixes legacy CSS and image paths in Albumball daily files
# for 2009 through 2015.
#
# Only .html and .htm files inside each year's dailies folder
# are examined.
#
# Two exact replacements:
#
# /theme/css/2009.css
#     -> ../../../theme/css/2009.css
#
# http://www.gruntleball.com/albumball/Images/2009.jpg
#     -> ../../Images/2009.jpg
#
# No other content is modified.

$Root = Join-Path $PSScriptRoot "albumball"

$OldCss = '/theme/css/2009.css'
$NewCss = '../../../theme/css/2009.css'

$OldImage = 'http://www.gruntleball.com/albumball/Images/2009.jpg'
$NewImage = '../../Images/2009.jpg'

$TotalFilesScanned = 0
$TotalFilesChanged = 0
$TotalCssChanges = 0
$TotalImageChanges = 0

Write-Host ""
Write-Host "Albumball 2009-2015 path repair" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor DarkGray

foreach ($Year in 2009..2015) {

    $Dailies = Join-Path $Root "$Year\dailies"

    Write-Host ""
    Write-Host "Albumball $Year" -ForegroundColor Yellow

    if (-not (Test-Path -LiteralPath $Dailies)) {
        Write-Host "  SKIPPED - no dailies folder" -ForegroundColor Red
        continue
    }

    $Files = @(
        Get-ChildItem -LiteralPath $Dailies -File |
        Where-Object {
            $_.Extension -ieq ".html" -or
            $_.Extension -ieq ".htm"
        }
    )

    $YearFilesChanged = 0
    $YearCssChanges = 0
    $YearImageChanges = 0

    foreach ($File in $Files) {

        $TotalFilesScanned++

        $Content = Get-Content -LiteralPath $File.FullName -Raw

        $CssCount = (
            [regex]::Matches(
                $Content,
                [regex]::Escape($OldCss)
            )
        ).Count

        $ImageCount = (
            [regex]::Matches(
                $Content,
                [regex]::Escape($OldImage)
            )
        ).Count

        if ($CssCount -eq 0 -and $ImageCount -eq 0) {
            continue
        }

        $NewContent = $Content.Replace($OldCss, $NewCss)
        $NewContent = $NewContent.Replace($OldImage, $NewImage)

        Set-Content `
            -LiteralPath $File.FullName `
            -Value $NewContent `
            -Encoding UTF8 `
            -NoNewline

        $YearFilesChanged++
        $TotalFilesChanged++

        $YearCssChanges += $CssCount
        $TotalCssChanges += $CssCount

        $YearImageChanges += $ImageCount
        $TotalImageChanges += $ImageCount
    }

    Write-Host "  Files examined: $($Files.Count)"
    Write-Host "  Files changed:  $YearFilesChanged" -ForegroundColor Green
    Write-Host "  CSS paths fixed: $YearCssChanges"
    Write-Host "  Image paths fixed: $YearImageChanges"
}

Write-Host ""
Write-Host "================================" -ForegroundColor DarkGray
Write-Host "DONE" -ForegroundColor Green
Write-Host ""
Write-Host "Files scanned:     $TotalFilesScanned"
Write-Host "Files changed:     $TotalFilesChanged"
Write-Host "CSS paths fixed:   $TotalCssChanges"
Write-Host "Image paths fixed: $TotalImageChanges"
Write-Host ""