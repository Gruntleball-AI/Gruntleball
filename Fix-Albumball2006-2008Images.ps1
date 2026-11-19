# Fix-Albumball2006-2008Images.ps1
#
# Replaces legacy gruntleball.com image references in Albumball
# daily files for 2006, 2007, and 2008.
#
# Historical content and embedded CSS are NOT modified.

$Root = Join-Path $PSScriptRoot "albumball"

$TotalFilesScanned = 0
$TotalFilesChanged = 0
$TotalImageChanges = 0

Write-Host ""
Write-Host "Albumball 2006-2008 image path repair" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor DarkGray

foreach ($Year in 2006..2008) {

    $Dailies = Join-Path $Root "$Year\dailies"

    $OldImage = "http://www.gruntleball.com/albumball/Images/$Year.jpg"
    $NewImage = "../../Images/$Year.jpg"

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
    $YearImageChanges = 0

    foreach ($File in $Files) {

        $TotalFilesScanned++

        $Content = Get-Content -LiteralPath $File.FullName -Raw

        $ImageCount = (
            [regex]::Matches(
                $Content,
                [regex]::Escape($OldImage)
            )
        ).Count

        if ($ImageCount -eq 0) {
            continue
        }

        $NewContent = $Content.Replace($OldImage, $NewImage)

        Set-Content `
            -LiteralPath $File.FullName `
            -Value $NewContent `
            -Encoding UTF8 `
            -NoNewline

        $YearFilesChanged++
        $TotalFilesChanged++

        $YearImageChanges += $ImageCount
        $TotalImageChanges += $ImageCount
    }

    Write-Host "  Files examined:    $($Files.Count)"
    Write-Host "  Files changed:     $YearFilesChanged" -ForegroundColor Green
    Write-Host "  Image paths fixed: $YearImageChanges"
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor DarkGray
Write-Host "DONE" -ForegroundColor Green
Write-Host ""
Write-Host "Files scanned:       $TotalFilesScanned"
Write-Host "Files changed:       $TotalFilesChanged"
Write-Host "Image paths fixed:   $TotalImageChanges"
Write-Host ""