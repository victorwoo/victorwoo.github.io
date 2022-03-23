$DebugPreference = 'Continue'
#$DebugPreference = 'SilentlyContinue'
$sourcePath = '..\source\_posts\'

if (gmo Blog) { rmo Blog }
ipmo ./Blog.psm1

function Get-Index ($year, $month, $day, $name, $title) {
    $indexTemplate = '* [{0:D2}-{1:D2}-{2:D2} {7}](/{3:D2}/{4:D2}/{5:D2}/{6})'
    return $indexTemplate -f $year, $month, $day, $year, $month, $day, $name, $title
}

$currentYear = 0
$currentMonth = 0
$sb = New-Object System.Text.StringBuilder
Get-ChildItem (Join-Path $sourcePath *.md) | Where-Object Name -ne '2013-09-09-index.md' | Sort-Object Name | ForEach-Object {
    Write-Debug $_.Name
    $original = Read-HexoBlog $_

    if ($original.Meta.categories -contains 'powershell' -and $original.Meta.categories -contains 'tip') {
        if ($original.Meta.title -cnotmatch '(?m)^PowerShell 技能连载 - (.*)$') {
            return
        }
        $title = $matches[1]

        if ($_.BaseName -cmatch '(?m)^(\d{4})-(\d{2})-(\d{2})-([\w|-]*)$') {
	        [int]$year = $matches[1]
            [int]$month = $matches[2]
            [int]$day = $matches[3]
            $name = $matches[4]
            $date = Get-Date -Year $year -Month $month -Day $day
            return [pscustomobject][ordered]@{
                Year = $year;
                Month = $month;
                Day = $day;
                Date = $date;
                Name = $name;
                Title = $title;
            }
        }
    }
} | ForEach-Object {
    if ($currentYear -ne $_.Year) {
        $currentYear = $_.Year
        $sb.AppendLine()
        $sb.AppendLine("$year 年")
        $sb.AppendLine("=======")
    }

    if ($currentMonth -ne $_.Month) {
        $currentMonth = $_.Month
        #Write-Debug "$($_.Year) - $($_.Month)"
        $sb.AppendLine()
        $sb.AppendLine(('{0:D4} 年 {1:D2} 月' -f $_.Year, $_.Month))
        $sb.AppendLine("-------------")
    }

    $line = Get-Index $_.Year $_.Month $_.Day $_.Name $_.Title
    $sb.AppendLine($line)
} | Out-Null

$body = $sb.ToString()
$indexBlog = Read-HexoBlog (Join-Path $sourcePath 2013-09-09-index.md)
$out = Out-HexoBlog $indexBlog.Meta $body
Set-Content (Join-Path $sourcePath 2013-09-09-index.md) $out -Encoding utf8NoBOM