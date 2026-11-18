# Preview-HBSLDailies.ps1
# READ-ONLY inventory of HBSL dailies directories.
# This script makes NO changes to any files.

$HbslRoot = "$env:USERPROFILE\Documents\GitHub\Gruntleball\hbsl"

if (-not (Test-Path -LiteralPath $HbslRoot)) {
    Write-Host "ERROR: HBSL folder not found:" -ForegroundColor Red
    Write-Host $HbslRoot
    exit 1
}

Write-Host ""
Write-Host "HBSL DAILIES PREVIEW" -ForegroundColor Cyan
Write-Host "Root: $HbslRoot"
Write-Host "READ ONLY - no files will be changed." -ForegroundColor Green
Write-Host ""

$YearFolders = Get-ChildItem -LiteralPath $HbslRoot -Directory |
    Where-Object { $_.Name -match '^\d{4}$' } |
    Sort-Object Name

foreach ($YearFolder in $YearFolders) {

    $Year = $YearFolder.Name
    $DailiesPath = Join-Path $YearFolder.FullName "dailies"

    Write-Host "============================================================"
    Write-Host "HBSL $Year" -ForegroundColor Yellow

    if (-not (Test-Path -LiteralPath $DailiesPath)) {
        Write-Host "  NO DAILIES FOLDER" -ForegroundColor DarkYellow
        Write-Host ""
        continue
    }

    $Files = Get-ChildItem -LiteralPath $DailiesPath -File |
        Sort-Object Name

    $Daily      = @()
    $Weekly     = @()
    $Monthly    = @()
    $ExistingIndex = @()
    $Css        = @()
    $Template   = @()
    $OtherHtml  = @()
    $OtherFiles = @()

    foreach ($File in $Files) {

        $Name = $File.Name

        switch -Regex ($Name) {

            # Daily report: MMDD.html
            '^\d{4}\.html$' {
                $Daily += $File
                break
            }

            # Weekly report: wMMDD.html
            '^w\d{4}\.html$' {
                $Weekly += $File
                break
            }

            # Monthly report: mMM.html
            '^m\d{2}\.html$' {
                $Monthly += $File
                break
            }

            # Existing directory index
            '^index\.html?$' {
                $ExistingIndex += $File
                break
            }

            # HBSL stylesheet
            '^hbsl\.css$' {
                $Css += $File
                break
            }

            # Historical daily template
            '^0000\.txt$' {
                $Template += $File
                break
            }

            # HTML that does not fit known daily/weekly/monthly patterns
            '\.html?$' {
                $OtherHtml += $File
                break
            }

            # Anything else
            default {
                $OtherFiles += $File
            }
        }
    }

    Write-Host ("  Daily HTML:      {0}" -f $Daily.Count)
    Write-Host ("  Weekly HTML:     {0}" -f $Weekly.Count)
    Write-Host ("  Monthly HTML:    {0}" -f $Monthly.Count)
    Write-Host ("  Other HTML:      {0}" -f $OtherHtml.Count)
    Write-Host ("  Other files:     {0}" -f $OtherFiles.Count)

    if ($ExistingIndex.Count -gt 0) {
        Write-Host "  index.html:       EXISTS" -ForegroundColor Green
    }
    else {
        Write-Host "  index.html:       MISSING" -ForegroundColor Magenta
    }

    if ($Css.Count -gt 0) {
        Write-Host "  hbsl.css:         present" -ForegroundColor Green
    }
    else {
        Write-Host "  hbsl.css:         MISSING" -ForegroundColor Red
    }

    if ($Template.Count -gt 0) {
        Write-Host "  0000.txt:         present (template - will not be indexed)"
    }

    if ($OtherHtml.Count -gt 0) {
        Write-Host ""
        Write-Host "  UNCLASSIFIED HTML:" -ForegroundColor Magenta

        foreach ($File in $OtherHtml) {
            Write-Host ("    {0}" -f $File.Name)
        }
    }

    if ($OtherFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "  OTHER FILES:" -ForegroundColor DarkCyan

        foreach ($File in $OtherFiles) {
            Write-Host ("    {0}" -f $File.Name)
        }
    }

    Write-Host ""
}

Write-Host "============================================================"
Write-Host "PREVIEW COMPLETE - NOTHING WAS CHANGED." -ForegroundColor Green
Write-Host ""