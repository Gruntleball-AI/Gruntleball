$root = "$env:USERPROFILE\Documents\GitHub\Gruntleball\albumball"
$encoding = [System.Text.Encoding]::GetEncoding(28591)

$changedFiles = 0
$changedReferences = 0

Get-ChildItem -LiteralPath $root -File -Recurse -Filter "*.html" -ErrorAction SilentlyContinue |
ForEach-Object {
    $path = $_.FullName
    $text = $encoding.GetString([System.IO.File]::ReadAllBytes($path))

    if ($text.Contains("../../Images/")) {
        $count = ([regex]::Matches(
            $text,
            [regex]::Escape("../../Images/")
        )).Count

        $text = $text.Replace("../../Images/", "../../images/")
        [System.IO.File]::WriteAllBytes($path, $encoding.GetBytes($text))

        $changedFiles++
        $changedReferences += $count
    }
}

Write-Host "HTML files gedFiles"
Write-Host "Image references corrected: $changedReferences"