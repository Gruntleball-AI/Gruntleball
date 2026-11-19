# Generate-AlbumballDailiesIndex.ps1
#
# Generates dailies/index.html for Albumball 1990-2015.
#
# Historical files are NEVER modified.
# Existing index.html IS replaced.
#
# Daily precedence:
#   MMDD.html
#   MMDD.htm
#   MMDD.txt

$Root = Join-Path $PSScriptRoot "albumball"

$MonthNames = @{
    1="JAN"; 2="FEB"; 3="MAR"; 4="APR"; 5="MAY"; 6="JUN"
    7="JUL"; 8="AUG"; 9="SEP"; 10="OCT"; 11="NOV"; 12="DEC"
}

$FullMonthNames = @{
    1="January"; 2="February"; 3="March"; 4="April"
    5="May"; 6="June"; 7="July"; 8="August"
    9="September"; 10="October"; 11="November"; 12="December"
}

function Get-PreferredFile {
    param(
        [array]$Files,
        [string]$BaseName
    )

    foreach ($ext in @(".html", ".htm", ".txt")) {
        $f = $Files |
            Where-Object {
                $_.BaseName -ieq $BaseName -and
                $_.Extension -ieq $ext
            } |
            Select-Object -First 1

        if ($f) { return $f }
    }

    return $null
}

foreach ($Year in 1990..2015) {

    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkGray
    Write-Host "Albumball $Year" -ForegroundColor Yellow

    $Dailies = Join-Path $Root "$Year\dailies"
    $Index = Join-Path $Dailies "index.html"

    if (-not (Test-Path -LiteralPath $Dailies)) {
        Write-Host "  SKIPPED - no dailies folder" -ForegroundColor Red
        continue
    }

    $Files = @(Get-ChildItem -LiteralPath $Dailies -File)

    # ------------------------------------------------------------
    # DAILY REPORTS
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
            $Date = New-Object DateTime($Year,$Month,$Day)
        }
        catch {
            continue
        }

        $File = Get-PreferredFile -Files $Files -BaseName $Base

        if ($File) {
            $DailyByDate[$Date.ToString("yyyy-MM-dd")] = $File.Name
        }
    }

    # ------------------------------------------------------------
    # WEEKLY REPORTS
    # wMMDD
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
        $File = Get-PreferredFile -Files $Files -BaseName $Base
        if ($File) { $Weekly += $File }
    }

    $Weekly = @($Weekly | Sort-Object BaseName)

    # ------------------------------------------------------------
    # MONTHLY REPORTS
    # m04 through m12, plus m0910
    # ------------------------------------------------------------

    $MonthlyBases = @(
        $Files |
        Where-Object {
            $_.BaseName -match '^m(\d{2}|\d{4})$' -and
            $_.Extension -match '^\.(html|htm|txt)$'
        } |
        ForEach-Object { $_.BaseName.ToLower() } |
        Sort-Object -Unique
    )

    $Monthly = @()

    foreach ($Base in $MonthlyBases) {

        $File = Get-PreferredFile -Files $Files -BaseName $Base

        if (-not $File) { continue }

        if ($Base -eq "m0910") {
            $Label = "September/October"
            $Sort = 9
        }
        elseif ($Base -match '^m(\d{2})$') {
            $m = [int]$Matches[1]

            if ($m -lt 1 -or $m -gt 12) { continue }

            $Label = $FullMonthNames[$m]
            $Sort = $m
        }
        else {
            continue
        }

        $Monthly += [PSCustomObject]@{
            File  = $File
            Label = $Label
            Sort  = $Sort
        }
    }

    $Monthly = @($Monthly | Sort-Object Sort)

    # ------------------------------------------------------------
    # SPECIAL HTML REPORTS
    #
    # HTML/HTM files that aren't daily, weekly, monthly, or index.
    # ------------------------------------------------------------

    $Recognized = @{}

    foreach ($b in $DailyBases)   { $Recognized[$b.ToLower()] = $true }
    foreach ($b in $WeeklyBases)  { $Recognized[$b.ToLower()] = $true }
    foreach ($b in $MonthlyBases) { $Recognized[$b.ToLower()] = $true }

    $Recognized["index"] = $true

    $SpecialGroups = @{}

    foreach ($File in $Files) {

        if ($File.Extension -notmatch '^\.(html|htm)$') {
            continue
        }

        $key = $File.BaseName.ToLower()

        if ($Recognized.ContainsKey($key)) {
            continue
        }

        if (-not $SpecialGroups.ContainsKey($key)) {
            $SpecialGroups[$key] = @()
        }

        $SpecialGroups[$key] += $File
    }

    $Special = @()

    foreach ($key in ($SpecialGroups.Keys | Sort-Object)) {

        $group = $SpecialGroups[$key]

        $preferred = $group |
            Where-Object { $_.Extension -ieq ".html" } |
            Select-Object -First 1

        if (-not $preferred) {
            $preferred = $group |
                Where-Object { $_.Extension -ieq ".htm" } |
                Select-Object -First 1
        }

        if ($preferred) {
            $Special += $preferred
        }
    }

    # ------------------------------------------------------------
    # HTML
    # ------------------------------------------------------------

    $Html = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Albumball $Year Dailies</title>

<style>

:root {  --bg: #050707;  --surface: #101617;  --surface-alt: #172022;  --blue: #86b6b8;  --blue-bright: #a5ced0;  --blue-light: #c0dadb;  --blue-dark: #4d6c6e;  --text: #eef4f4;  --text-secondary: #c0dadb;  --text-muted: #aab9b9;  --border: #486466; }

body {
 background-color: var(--bg);
 color: var(--text);
 font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif;
 font-size: 15px;
 line-height: 1.35;
 }

.archive {
 max-width: 760px;
 margin-left: 12px;
 }

h1 {
 color: var(--blue-light);
 font-size: 46px;
 font-weight: 600;
 margin-bottom: 4px;
 }

h2 {
 color: var(--text);
 font-size: 15px;
 font-weight: 600;
 border-top: 2px solid var(--blue-dark);
 margin-top: 24px;
 margin-bottom: 8px;
 padding-top: 4px;
 }

h4 {
 color: var(--blue);
 font-size: 20px;
 font-weight: 600;
 margin-top: 0;
 }
 
 a:link,
 a:visited {
 color: var(--blue-bright);
 text-decoration: none;
 }

a:hover {
 color: var(--blue-light);
 font-weight: 800;
 text-decoration: underline;
 }

.month-name {
 color: var(--blue-bright);
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
 color: var(--text-secondary);
 font-weight: 600;
 border-bottom: 1px dotted var(--blue-dark);
 }
 
 .calendar td a {
 display: block;
 color: var(--blue-bright);
 border-radius: 3px;
 }

.calendar td a:hover {
 color: var(--blue-light);
 background-color: var(--surface-alt);
 }

.report-links {
 line-height: 1.8;
 }

.report-links a {
 display: inline-block;
 margin-right: 16px;
 margin-bottom: 2px;
 color: var(--blue-light);
 }
 
</style>

</head>

<body>

<div class="archive">

<h1>Albumball</h1>
<h4>$Year Daily Archive</h4>

"@

    # Back link only if that season has a web folder/index.
    $WebIndex = Join-Path $Root "$Year\web\index.html"

    if (Test-Path -LiteralPath $WebIndex) {
        $Html += "<p><a href=`"../web/index.html`">Back to $Year Website</a></p>`r`n"
    }

    $Html += "<h2>Daily Reports</h2>`r`n"

    # ------------------------------------------------------------
    # CALENDARS
    # ------------------------------------------------------------

    $Months = @(
        $DailyByDate.Keys |
        ForEach-Object { [int]$_.Substring(5,2) } |
        Sort-Object -Unique
    )

    foreach ($Month in $Months) {

        $Html += "<div class=`"month-name`">$($MonthNames[$Month])</div>`r`n"
        $Html += "<table class=`"calendar`">`r`n"
        $Html += "<tr><th>MON</th><th>TUE</th><th>WED</th><th>THU</th><th>FRI</th><th>SAT</th><th>SUN</th></tr>`r`n"
        $Html += "<tr>`r`n"

        $First = New-Object DateTime($Year,$Month,1)
        $DaysInMonth = [DateTime]::DaysInMonth($Year,$Month)

        # Monday=0 ... Sunday=6
        $Column = (([int]$First.DayOfWeek + 6) % 7)

        for ($i=0; $i -lt $Column; $i++) {
            $Html += "<td></td>`r`n"
        }

        for ($Day=1; $Day -le $DaysInMonth; $Day++) {

            $Date = New-Object DateTime($Year,$Month,$Day)
            $Key = $Date.ToString("yyyy-MM-dd")

            if ($DailyByDate.ContainsKey($Key)) {

                $Filename = [System.Net.WebUtility]::HtmlEncode(
                    $DailyByDate[$Key]
                )

                $Html += "<td><a href=`"$Filename`">$Day</a></td>`r`n"
            }
            else {
                $Html += "<td></td>`r`n"
            }

            $Column++

            if ($Column -eq 7 -and $Day -lt $DaysInMonth) {
                $Html += "</tr><tr>`r`n"
                $Column = 0
            }
        }

        if ($Column -gt 0 -and $Column -lt 7) {
            for ($i=$Column; $i -lt 7; $i++) {
                $Html += "<td></td>`r`n"
            }
        }

        $Html += "</tr></table>`r`n"
    }

    # ------------------------------------------------------------
    # WEEKLY
    # ------------------------------------------------------------

    if ($Weekly.Count -gt 0) {

        $Html += "<h2>Weekly Reports</h2>`r`n"
        $Html += "<div class=`"report-links`">`r`n"

        foreach ($File in $Weekly) {

            if ($File.BaseName -match '^w(\d{2})(\d{2})$') {
                $Label = "$($Matches[1])/$($Matches[2])"
            }
            else {
                $Label = $File.BaseName
            }

            $Html += "<a href=`"$($File.Name)`">$Label</a>`r`n"
        }

        $Html += "</div>`r`n"
    }

    # ------------------------------------------------------------
    # MONTHLY
    # ------------------------------------------------------------

    if ($Monthly.Count -gt 0) {

        $Html += "<h2>Monthly Reports</h2>`r`n"
        $Html += "<div class=`"report-links`">`r`n"

        foreach ($Item in $Monthly) {

            $Html += "<a href=`"$($Item.File.Name)`">$($Item.Label)</a>`r`n"
        }

        $Html += "</div>`r`n"
    }

    # ------------------------------------------------------------
    # SPECIAL
    # ------------------------------------------------------------

    if ($Special.Count -gt 0) {

        $Html += "<h2>Postseason / Special Reports</h2>`r`n"
        $Html += "<div class=`"report-links`">`r`n"

        foreach ($File in $Special) {

            $Label = [System.Net.WebUtility]::HtmlEncode($File.BaseName)

            $Html += "<a href=`"$($File.Name)`">$Label</a>`r`n"
        }

        $Html += "</div>`r`n"
    }

    $Html += @"

</div>

</body>
</html>
"@

    Set-Content -LiteralPath $Index -Value $Html -Encoding UTF8

    Write-Host "  index.html written" -ForegroundColor Green
    Write-Host "  Daily:   $($DailyByDate.Count)"    Write-Host "  Weekly:  $($Weekly.Count)"
    Write-Host "  Monthly: $($Monthly.Count)"
    Write-Host "  Special: $($Special.Count)"
}

Write-Host ""
Write-Host "DONE - only dailies/index.html files were written." -ForegroundColor Green