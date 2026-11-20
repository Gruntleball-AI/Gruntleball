$folder = Join-Path $env:USERPROFILE "Documents\GitHub\Gruntleball\albumball\2015\dailies"
$encoding = New-Object System.Text.UTF8Encoding($false)

$badName = "D" + [char]0x00C3 + [char]0x00BA + "n Laoghaire Messiahs"
$goodName = "D&uacute;n Laoghaire Messiahs"

$changedFiles = 0
$changedNames = 0

Get-ChildItem -LiteralPath $folder -File -Filter "*.html" |
ForEach-Object {
    $path = $_.FullName
    $text = $encoding.GetString([System.IO.File]::ReadAllBytes($path))

    if ($text.Contains($badName)) {
        $count = $text.Split(@($badName), [System.StringSplitOptions]::None).Count - 1
        $text = $text.Replace($badName, $goodName)

        [System.IO.File]::WriteAllBytes(
            $path,
            $encoding.GetBytes($text)
        )

        $changedFiles++
        $changedNames += $count
    }
}

Write-Host "HTML files changed: $changedFiles"
Write-Host "Team-name occurrences changed: $changedNames"