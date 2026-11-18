# Generate-HBSLDailiesIndex.ps1
# TEST VERSION: Generates HBSL 1986 dailies/index.html only.
# Existing reports and CSS are NOT modified.

$Year = "1986"
$DailiesPath = Join-Path $PSScriptRoot "hbsl\$Year\dailies"
$OutputFile = Join-Path $DailiesPath "index.html"

if (-not (Test-Path -LiteralPath $DailiesPath)) {
    Write-Host "ERROR: $DailiesPath not found." -ForegroundColor Red
    exit 1
}

$Files = Get-ChildItem -LiteralPath $DailiesPath -File

$Daily = @(
    $Files |
    Where-Object { $_.Name -match '^\d{4}\.html$' } |
    Sort-Object Name
)

$Weekly = @(
    $Files |
    Where-Object { $_.Name -match '^w\d{4}\.html$' } |
    Sort-Object Name
)

$Monthly = @(
    $Files |
    Where-Object { $_.Name -match '^m\d{2}\.html$' } |
    Sort-Object Name
)

$CombinedMonthly = @(
    $Files |
    Where-Object { $_.Name -eq 'm0910.html' }
)

$Special = @(
    $Files |
    Where-Object {
        $_.Name -match '\.html?$' -and
        $_.Name -notmatch '^\d{4}\.html$' -and
        $_.Name -notmatch '^w\d{4}\.html$' -and
        $_.Name -notmatch '^m\d{2}\.html$' -and
        $_.Name -ne 'm0910.html' -and
        $_.Name -notmatch '^index\.html?$'
    } |
    Sort-Object Name
)

$MonthNames = @{
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

# Build lookup of available daily files by actual date.
$DailyByDate = @{}

foreach ($File in $Daily) {

    $Month = [int]$File.BaseName.Substring(0,2)
    $Day   = [int]$File.BaseName.Substring(2,2)

    try {
        $Date = Get-Date -Year ([int]$Year) -Month $Month -Day $Day
        $Key = $Date.ToString("yyyy-MM-dd")
        $DailyByDate[$Key] = $File.Name
    }
    catch {
        Write-Host "WARNING: Could not interpret $($File.Name) as a date." `
            -ForegroundColor Yellow
    }
}

$Html = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>HBSL $Year Dailies</title>
<link rel="stylesheet" href="hbsl.css">

<style>

.archive {
    max-width: 760px;
    margin-left: 12px;
}

/* Calm the links down on the index only */
.archive a:link,
.archive a:visited {
    color: #ffeecc;
    text-decoration: none;
}

.archive a:hover {
    color: #ccdd88;
    font-weight: 800;
    text-decoration: underline;
}

/* Compact calendar */
.calendar {
    border-collapse: collapse;
    margin-top: 4px;
    margin-bottom: 15px;
}

.calendar th,
.calendar td {
    width: 34px;
    padding: 1px 3px;
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

.month-name {
    color: #ff5511;
    font-weight: 600;
    font-size: 17px;
    margin-top: 10px;
}

.report-links {
    line-height: 1.8;
}

.report-links a {
    display: inline-block;
    margin-right: 16px;
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

# Determine which months actually contain daily files.
$MonthsPresent = @(
    $Daily |
    ForEach-Object { [int]$_.BaseName.Substring(0,2) } |
    Sort-Object -Unique
)

foreach ($Month in $MonthsPresent) {

    $Html += @"

<div class="month-name">$($MonthNames[$Month])</div>
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

    $First = Get-Date -Year ([int]$Year) -Month $Month -Day 1
    $DaysInMonth = [DateTime]::DaysInMonth([int]$Year, $Month)

    # .NET Sunday=0, Monday=1 ... Saturday=6
    # Convert to Monday=0 ... Sunday=6.
    $StartColumn = (([int]$First.DayOfWeek + 6) % 7)

    # Blank cells before first day.
    for ($i = 0; $i -lt $StartColumn; $i++) {
        $Html += "<td></td>`r`n"
    }

    $Column = $StartColumn

    for ($Day = 1; $Day -le $DaysInMonth; $Day++) {

        $Date = Get-Date -Year ([int]$Year) -Month $Month -Day $Day
        $Key = $Date.ToString("yyyy-MM-dd")

        if ($DailyByDate.ContainsKey($Key)) {
            $FileName = $DailyByDate[$Key]
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

    # Fill remaining cells on final week.
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

# WEEKLY
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

    $Html += "<a href=`"$($File.Name)`">$Label</a>`r`n"
}

$Html += @"
</div>

<h2>Monthly Reports</h2>
<div class="report-links">
"@

foreach ($File in $Monthly) {

    $MonthNumber = [int]$File.BaseName.Substring(1,2)

    if ($MonthNames.ContainsKey($MonthNumber)) {
        $Label = $MonthNames[$MonthNumber]
    }
    else {
        $Label = $File.BaseName
    }

    $Html += "<a href=`"$($File.Name)`">$Label</a>`r`n"
}

if ($CombinedMonthly.Count -gt 0) {
    $Html += '<a href="m0910.html">SEP/OCT</a>'
}

$Html += "</div>`r`n"

# POSTSEASON / SPECIAL
if ($Special.Count -gt 0) {

    $Html += @"

<h2>Postseason / Special Reports</h2>
<div class="report-links">
"@

    foreach ($File in $Special) {
        $Html += "<a href=`"$($File.Name)`">$($File.BaseName)</a>`r`n"
    }

    $Html += "</div>`r`n"
}

$Html += @"

</div>

</body>
</html>
"@

Set-Content -LiteralPath $OutputFile -Value $Html -Encoding UTF8

Write-Host ""
Write-Host "CREATED: $OutputFile" -ForegroundColor Green
Write-Host ""
Write-Host "Daily:   $($Daily.Count)"
Write-Host "Weekly:  $($Weekly.Count)"
Write-Host "Monthly: $($Monthly.Count)"
Write-Host "Special: $($Special.Count)"
Write-Host ""
Write-Host "Historical reports and CSS were not modified." -ForegroundColor Green