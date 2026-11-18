# Generate-HBSLDailiesIndex.ps1
#
# Generates compact calendar index pages for HBSL daily archives.
#
# IMPORTANT:
#   - Does NOT edit, rename, move or delete historical files.
#   - Does NOT alter historical CSS.
#   - If index.html already exists, that season is SKIPPED.
#
# Daily precedence:
#   1. MMDD.html
#   2. MMDD.htm
#   3. MMDD.txt
#
# Weekly precedence:
#   1. wMMDD.html
#   2. wMMDD.htm
#   3. wMMDD.txt
#
# Monthly naming has changed over the years, so several historical
# patterns are recognized.
#
# Anything HTML/HTM that isn't confidently classified is shown under
# Postseason / Special Reports.

$HbslRoot = Join-Path $PSScriptRoot "hbsl"

if (-not (Test-Path -LiteralPath $HbslRoot)) {
    Write-Host "ERROR: HBSL root not found:" -ForegroundColor Red
    Write-Host $HbslRoot
    exit 1
}

function Get-PreferredFile {
    param (
        [array]$Files,
        [string]$BaseName
    )

    # Prefer HTML, then HTM, then TXT
    foreach ($ext in @(".html", ".htm", ".txt")) {
        $candidate = $Files |
            Where-Object {
                $_.BaseName -ieq $BaseName -and
                $_.Extension -ieq $ext
            } |
            Select-Object -First 1

        if ($candidate) {
            return $candidate
        }
    }

    return $null
}

function Get-Month-Abbrev {
    param([int]$Month)

    $Names = @{
        1  = "JAN"
        2  = "FEB"
        3  = "MAR"
        4  = "APR"
        5  = "MAY"
        6  = "JUN"
        7  = "JUL"
        8  = "AUG"
        9  = "SEP"
        10 = "OCT"
        11 = "NOV"
        12 = "DEC"
    }

    return $Names[$Month]
}

function Get-Month-Name {
    param([int]$Month)

    return (Get-Culture).DateTimeFormat.GetMonthName($Month)
}

function Add-HtmlEncoded {
    param([string]$Text)

    return [System.Net.WebUtility]::HtmlEncode($Text)
}

$Years = Get-ChildItem -LiteralPath $HbslRoot -Directory |
    Where-Object { $_.Name -match '^\d{4}$' } |
    Sort-Object Name

Write-Host ""
Write-Host "HBSL DAILIES INDEX GENERATOR" -ForegroundColor Cyan
Write-Host "Root: $HbslRoot"
Write-Host ""

foreach ($YearFolder in $Years) {

    $Year = [int]$YearFolder.Name
    $DailiesPath = Join-Path $YearFolder.FullName "dailies"
    $OutputFile = Join-Path $DailiesPath "index.html"

    Write-Host "============================================================"
    Write-Host "HBSL $Year" -ForegroundColor Yellow

    if (-not (Test-Path -LiteralPath $DailiesPath)) {
        Write-Host "  SKIPPED: no dailies folder" -ForegroundColor DarkYellow
        continue
    }

    if (Test-Path -LiteralPath $OutputFile) {
        Write-Host "  SKIPPED: index.html already exists" -ForegroundColor DarkYellow
        continue
    }

    $Files = @(
        Get-ChildItem -LiteralPath $DailiesPath -File
    )

    # ------------------------------------------------------------
    # DAILY REPORTS
    # Find unique MMDD basenames across .html / .htm / .txt.
    # ------------------------------------------------------------

    $DailyBases = @(
        $Files |
        Where-Object {
            $_.BaseName -match '^\d{4}$' -and
            $_.Extension -match '^\.(html|htm|txt)$'
        } |
        ForEach-Object { $_.BaseName } |
        Sort-Object -Unique
    )

    $DailyByDate = @{}

    foreach ($Base in $DailyBases) {

        $Month = [int]$Base.Substring(0,2)
        $Day   = [int]$Base.Substring(2,2)

        try {
            $Date = Get-Date -Year $Year -Month $Month -Day $Day
        }
        catch {
            # e.g. 0000 template or impossible dates
            continue
        }

        $Preferred = Get-PreferredFile -Files $Files -BaseName $Base

        if ($Preferred) {
            $DailyByDate[$Date.ToString("yyyy-MM-dd")] = $Preferred.Name
        }
    }

    # ------------------------------------------------------------
    # WEEKLY REPORTS
    # ------------------------------------------------------------

    $WeeklyBases = @(
        $Files |
        Where-Object {
            $_.BaseName -match '^w\d{4}$' -and
            $_.Extension -match '^\.(html|htm|txt)$'
        } |
        ForEach-Object { $_.BaseName.ToLower() } |
        Sort-Object -Unique
    )

    $Weekly = @()

    foreach ($Base in $WeeklyBases) {

        $Preferred = Get-PreferredFile -Files $Files -BaseName $Base

        if ($Preferred) {
            $Weekly += $Preferred
        }
    }

    $Weekly = @($Weekly | Sort-Object BaseName)

    # ------------------------------------------------------------
    # MONTHLY REPORTS
    #
    # Historical patterns observed include:
    #   m04
    #   M04
    #   6905M
    #   7004M
    #   m7304
    #   m7404
    #   m0910
    # ------------------------------------------------------------

    $MonthlyCandidates = @()

    foreach ($File in $Files) {

        if ($File.Extension -notmatch '^\.(html|htm|txt)$') {
            continue
        }

        $b = $File.BaseName

        $MonthNumber = $null
        $MonthLabel = $null
        $SortValue = 999

        # Modern/simple format: m04
        if ($b -match '^[mM](\d{2})$') {
            $m = [int]$Matches[1]

            if ($m -ge 1 -and $m -le 12) {
                $MonthNumber = $m
                $MonthLabel = Get-Month-Name $m
                $SortValue = $m
            }
        }

        # Combined September/October
        elseif ($b -match '^[mM]0910$') {
            $MonthLabel = "September/October"
            $SortValue = 9
        }

        # Old format: 6905M, 7004M
        elseif ($b -match '^\d{2}(\d{2})[mM]$') {
            $m = [int]$Matches[1]

            if ($m -ge 1 -and $m -le 12) {
                $MonthNumber = $m
                $MonthLabel = Get-Month-Name $m
                $SortValue = $m
            }
        }

        # Old format: m7304, m7404
        elseif ($b -match '^[mM]\d{2}(\d{2})$') {
            $m = [int]$Matches[1]

            if ($m -ge 1 -and $m -le 12) {
                $MonthNumber = $m
                $MonthLabel = Get-Month-Name $m
                $SortValue = $m
            }
        }

        if ($MonthLabel) {
            $MonthlyCandidates += [PSCustomObject]@{
                BaseName = $b
                File     = $File
                Label    = $MonthLabel
                Sort     = $SortValue
            }
        }
    }

    # Deduplicate monthly HTML/HTM/TXT versions by basename.
    $Monthly = @()

    $MonthlyCandidates |
        Group-Object { $_.BaseName.ToLower() } |
        ForEach-Object {

            $Group = $_.Group
            $Base = $Group[0].BaseName

            $Preferred = Get-PreferredFile -Files $Files -BaseName $Base

            if ($Preferred) {
                $Info = $Group |
                    Where-Object { $_.File.Name -eq $Preferred.Name } |
                    Select-Object -First 1

                if (-not $Info) {
                    $Info = $Group[0]
                }

                $Monthly += [PSCustomObject]@{
                    File  = $Preferred
                    Label = $Info.Label
                    Sort  = $Info.Sort
                }
            }
        }

    $Monthly = @($Monthly | Sort-Object Sort, Label)

    # ------------------------------------------------------------
    # SPECIAL / POSTSEASON HTML
    #
    # Only HTML/HTM pages are included here.
    # Assets, JPG, CSS, XLSX, templates and miscellaneous TXT are ignored.
    # ------------------------------------------------------------

    $RecognizedBases = @{}

    foreach ($Base in $DailyBases) {
        $RecognizedBases[$Base.ToLower()] = $true
    }

    foreach ($Base in $WeeklyBases) {
        $RecognizedBases[$Base.ToLower()] = $true
    }

    foreach ($Item in $MonthlyCandidates) {
        $RecognizedBases[$Item.BaseName.ToLower()] = $true
    }

    $RecognizedBases["index"] = $true

    # Group remaining special files by basename so duplicate HTM/HTML
    # versions appear only once.
    $SpecialGroups = @{}

    foreach ($File in $Files) {

        if ($File.Extension -notmatch '^\.(html|htm)$') {
            continue
        }

        $BaseKey = $File.BaseName.ToLower()

        if ($RecognizedBases.ContainsKey($BaseKey)) {
            continue
        }

        if (-not $SpecialGroups.ContainsKey($BaseKey)) {
            $SpecialGroups[$BaseKey] = @()
        }

        $SpecialGroups[$BaseKey] += $File
    }

    $Special = @()

    foreach ($Key in ($SpecialGroups.Keys | Sort-Object)) {

        $Group = $SpecialGroups[$Key]

        $Preferred = $Group |
            Where-Object { $_.Extension -ieq ".html" } |
            Select-Object -First 1

        if (-not $Preferred) {
            $Preferred = $Group |
                Where-Object { $_.Extension -ieq ".htm" } |
                Select-Object -First 1
        }

        if ($Preferred) {
            $Special += $Preferred
        }
    }

    # ------------------------------------------------------------
    # HTML DOCUMENT
    # Completely self-contained styling.
    # Does not depend upon historical season CSS.
    # ------------------------------------------------------------

    $Html = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>HBSL $Year Dailies</title>

<style>
body {
    background-color: #000000;
    color: #ffeecc;
    font-family: -apple-system, BlinkMacSystemFont, Arial, sans-serif;
    font-size: 15px;
    line-height: 1.3;
}

.archive {
    max-width: 760px;
    margin-left: 12px;
}

h1 {
    color: #ff5511;
    font-size: 46px;
    font-weight: 600;
    margin-bottom: 4px;
}

h2 {
    color: #ffeecc;
    font-size: 15px;
    font-weight: 600;
    border-top: 2px solid #dd7755;
    margin-top: 24px;
    margin-bottom: 8px;
    padding-top: 3px;
}

h4 {
    color: #aabb55;
    font-size: 20px;
    font-weight: 600;
    margin-top: 0;
}

a:link,
a:visited {
    color: #ffeecc;
    text-decoration: none;
}

a:hover {
    color: #ccdd88;
    font-weight: 800;
    text-decoration: underline;
}

.month-name {
    color: #ff5511;
    font-size: 16px;
    font-weight: 600;
    margin-top: 9px;
    margin-bottom: 1px;
}

.calendar {
    border-collapse: collapse;
    margin-top: 0;
    margin-bottom: 10px;
}

.calendar th,
.calendar td {
    width: 32px;
    padding: 1px 2px;
    text-align: center;
    font-size: 14px;
}

.calendar th {
    color: #aabb55;
    font-weight: 600;
    border-bottom: 1px dotted #773322;
}

.calendar td {
    color: #ffeecc;
}

.report-links {
    line-height: 1.8;
}

.report-links a {
    display: inline-block;
    margin-right: 16px;
    margin-bottom: 2px;
}
</style>

</head>

<body>

<div class="archive">

<h1>Hot Buttered Soul</h1>
<h4>$Year Daily Archive</h4>

<p><a href="../web/index.html">Back to $Year HBSL Website</a></p>

<h2>Daily Reports</h2>
"@

    # ------------------------------------------------------------
    # DAILY CALENDARS
    # ------------------------------------------------------------

    $MonthsPresent = @(
        $DailyByDate.Keys |
        ForEach-Object { [int]$_.Substring(5,2) } |
        Sort-Object -Unique
    )

    foreach ($Month in $MonthsPresent) {

        $MonthLabel = Get-Month-Abbrev $Month

        $Html += @"

<div class="month-name">$MonthLabel</div>
<table class="calendar">
<tr>
<th>MON</th>
<th>TUE</th>
<th>WED</th>
<th>THU</th>
<th>FRI</th>
<th>SAT</th>
<th>SUN</th>
</tr>
<tr>
"@

        $First = Get-Date -Year $Year -Month $Month -Day 1
        $DaysInMonth = [System.DateTime]::DaysInMonth($Year, $Month)

        # .NET: Sunday=0 through Saturday=6.
        # Convert to Monday=0 through Sunday=6.
        $StartColumn = (([int]$First.DayOfWeek + 6) % 7)

        for ($i = 0; $i -lt $StartColumn; $i++) {
            $Html += "<td></td>`r`n"
        }

        $Column = $StartColumn

        for ($Day = 1; $Day -le $DaysInMonth; $Day++) {

            $Date = Get-Date -Year $Year -Month $Month -Day $Day
            $Key = $Date.ToString("yyyy-MM-dd")

            if ($DailyByDate.ContainsKey($Key)) {
                $FileName = Add-HtmlEncoded $DailyByDate[$Key]
                $Html += "<td><a href=`"$FileName`">$Day</a></td>`r`n"
            }
            else {
                $Html += "<td></td>`r`n"
            }

            $Column++

            if ($Column -eq 7 -and $Day -lt $DaysInMonth) {
                $Html += "</tr>`r`n<tr>`r`n"
                $Column = 0
            }
        }

        if ($Column -gt 0 -and $Column -lt 7) {
            for ($i = $Column; $i -lt 7; $i++) {
                $Html += "<td></td>`r`n"
            }
        }

        $Html += @"
</tr>
</table>
"@
    }

    # WEEKLY REPORTS
    if ($Weekly.Count -gt 0) {

        $Html += @"

<h2>Weekly Reports</h2>
<div class="report-links">
"@

        foreach ($File in $Weekly) {

            if ($File.BaseName -match '^w(\d{2})(\d{2})$') {
                $Label = "$($Matches[1])/$($Matches[2])"
            }
            else {
                $Label = $File.BaseName
            }

            $FileName = Add-HtmlEncoded $File.Name
            $Label = Add-HtmlEncoded $Label

            $Html += "<a href=`"$FileName`">$Label</a>`r`n"
        }

        $Html += "</div>`r`n"
    }

    # MONTHLY REPORTS
    if ($Monthly.Count -gt 0) {

        $Html += @"

<h2>Monthly Reports</h2>
<div class="report-links">
"@

        foreach ($Item in $Monthly) {

            $FileName = Add-HtmlEncoded $Item.File.Name
            $Label = Add-HtmlEncoded $Item.Label

            $Html += "<a href=`"$FileName`">$Label</a>`r`n"
        }

        $Html += "</div>`r`n"
    }

    # POSTSEASON / SPECIAL REPORTS
    if ($Special.Count -gt 0) {

        $Html += @"

<h2>Postseason / Special Reports</h2>
<div class="report-links">
"@

        foreach ($File in $Special) {

            $FileName = Add-HtmlEncoded $File.Name
            $Label = Add-HtmlEncoded $File.BaseName

            $Html += "<a href=`"$FileName`">$Label</a>`r`n"
        }

        $Html += "</div>`r`n"
    }

    $Html += @"

</div>
</body>
</html>
"@

    Set-Content -LiteralPath $OutputFile -Value $Html -Encoding UTF8

    Write-Host "  CREATED index.html" -ForegroundColor Green
    Write-Host "  Daily dates:      $($DailyByDate.Count)"
    Write-Host "  Weekly reports:   $($Weekly.Count)"
    Write-Host "  Monthly reports:  $($Monthly.Count)"
    Write-Host "  Special reports:  $($Special.Count)"
}

Write-Host ""
Write-Host "============================================================"
Write-Host "GENERATION COMPLETE" -ForegroundColor Green
Write-Host "Historical files were not modified." -ForegroundColor Green
Write-Host ""