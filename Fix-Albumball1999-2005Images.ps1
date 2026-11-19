# Fix-Albumball1999-2005Images.ps1
#
# Repairs legacy Albumball image references for 1999-2005.
#
# 1999:
#   - Replaces old Amazon image URL with ../../Images/1999.jpg
#   - Uncomments the specific image tag if it is wrapped in <!-- -->
#
# 2000-2005:
#   - Replaces each year's known legacy Dropbox image URL
#     with ../../Images/YYYY.jpg
#
# Only .html and .htm files inside YEAR\dailies are examined.
# No CSS or other historical content is intentionally modified.

$Root = Join-Path $PSScriptRoot "albumball"

$Mappings = @{
    1999 = @{
        Old = "http://ecx.images-amazon.com/images/I/51a0vu-AwqL._SL500_AA280_.jpg"
        New = "../../Images/1999.jpg"
        Uncomment = $true
    }

    2000 = @{
        Old = "http://dl.dropbox.com/u/3641528/Gruntleball/Albumball/Images/shellac1000hurts.jpg"
        New = "../../Images/2000.jpg"
        Uncomment = $false
    }

    2001 = @{
        Old = "http://dl.dropbox.com/u/3641528/Dailies/2001/LSF_GF_cropped.jpg"
        New = "../../Images/2001.jpg"
        Uncomment = $false
    }

    2002 = @{
        Old = "http://dl.dropbox.com/u/3641528/Gruntleball/Albumball/Images/songsForTheDeaf.jpg"
        New = "../../Images/2002.jpg"
        Uncomment = $false
    }

    2003 = @{
        Old = "http://dl.dropbox.com/u/3641528/Gruntleball/Albumball/Images/chutes_to_narrow_flat2.jpg"
        New = "../../Images/2003.jpg"
        Uncomment = $false
    }

    2004 = @{
        Old = "http://dl.dropbox.com/u/3641528/Gruntleball/Albumball/Images/2004b.jpg"
        New = "../../Images/2004.jpg"
        Uncomment = $false
    }

    2005 = @{
        Old = "http://dl.dropbox.com/u/3641528/Gruntleball/Albumball/Images/2005.jpg"
        New = "../../Images/2005.jpg"
        Uncomment = $false
    }
}

$TotalFilesScanned = 0
$TotalFilesChanged = 0
$TotalImageChanges = 0
$TotalUncommented = 0

Write-Host ""
Write-Host "Albumball 1999-2005 image path repair" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor DarkGray

foreach ($Year in 1999..2005) {

    $Dailies = Join-Path $Root "$Year\dailies"
    $Map = $Mappings[$Year]

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
    $YearUncommented = 0

    foreach ($File in $Files) {

        $TotalFilesScanned++

        $Content = Get-Content -LiteralPath $File.FullName -Raw
        $OriginalContent = $Content

        # Count and replace the exact legacy image URL.
        $ImageCount = (
            [regex]::Matches(
                $Content,
                [regex]::Escape($Map.Old)
            )
        ).Count

        if ($ImageCount -gt 0) {
            $Content = $Content.Replace($Map.Old, $Map.New)

            $YearImageChanges += $ImageCount
            $TotalImageChanges += $ImageCount
        }

        # 1999 special case:
        # Uncomment ONLY a comment containing the new 1999 image path.
        if ($Map.Uncomment) {

            $Pattern = '<!--\s*(<img\b[^>]*' +
                       [regex]::Escape($Map.New) +
                       '[^>]*>)\s*-->'

            $Matches = [regex]::Matches(
                $Content,
                $Pattern,
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            )

            if ($Matches.Count -gt 0) {

                $Content = [regex]::Replace(
                    $Content,
                    $Pattern,
                    '$1',
                    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
                )

                $YearUncommented += $Matches.Count
                $TotalUncommented += $Matches.Count
            }
        }

        if ($Content -ne $OriginalContent) {

            Set-Content `
                -LiteralPath $File.FullName `
                -Value $Content `
                -Encoding UTF8 `
                -NoNewline

            $YearFilesChanged++
            $TotalFilesChanged++
        }
    }

    Write-Host "  Files examined:    $($Files.Count)"
    Write-Host "  Files changed:     $YearFilesChanged" -ForegroundColor Green
    Write-Host "  Image paths fixed: $YearImageChanges"

    if ($Year -eq 1999) {
        Write-Host "  Images uncommented: $YearUncommented"
    }
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor DarkGray
Write-Host "DONE" -ForegroundColor Green
Write-Host ""
Write-Host "Files scanned:        $TotalFilesScanned"
Write-Host "Files changed:        $TotalFilesChanged"
Write-Host "Image paths fixed:    $TotalImageChanges"
Write-Host "1999 images uncommented: $TotalUncommented"
Write-Host ""
