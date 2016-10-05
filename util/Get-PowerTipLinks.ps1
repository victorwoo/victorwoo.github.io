function Get-ShortedUrl ($originalUrl) {
    $result = Invoke-RestMethod -Method Post -Uri 'http://dwz.cn/create.php' -Body "url=$originalUrl"
    if ($result.status -ne 0) { Write-Error "$originalUrl 解析失败" }
    return $result.tinyurl
}

$ubbs = @()
$plains = @()
$prefix = 'http://blog.vichamp.com'
$items = Get-Content -Encoding UTF8 -Path ..\source\_posts\2013-09-09-index.md | Select-Object -Last 50 | ForEach-Object -Process {
    if ($_ -cmatch '\* \[(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2}) (?<title>.*)\]\((?<url>.*)\)') {
        [int]$year = $matches.year
        [int]$month = $matches.month
        [int]$day = $matches.day
        $date = New-Object System.DateTime $year, $month, $day
	    $title = $matches.title
        $url = $matches.url

        $originalUrl = "$prefix$url"
        #Write-Output -InputObject $originalUrl

        #$shortedUrl = Get-ShortedUrl $originalUrl


        <#
        $ubb = "[url=$originalUrl]$year-$month-$day $title[/url]"
        $ubbs += $ubb

        $plain = "$title`n$shortedUrl"
        $plains += $plain
        #>

        $item = [PSCustomObject][Ordered]@{
            Date = $date;
            Title = $title;
            Url = $url;
            OriginalUrl = $originalUrl;
            #ShortUrl = $shortedUrl;
        }

        echo $item
    }
}

[DateTime]$minDate = $items[0].Date
$minDate = $minDate.AddMonths(1)
$minDate = New-Object System.DateTime $minDate.Year, $minDate.Month, 1
$minDate = ($items | Where-Object { $_.Date -ge $minDate })[0].Date
$minDate = $minDate.AddDays((8 - $minDate.DayOfWeek.value__) % 7)
$items = $items | Where-Object { $_.Date -ge $minDate }

$currentDate = $minDate
$currentYear = $currentDate.Year
$currentMonth = $currentDate.Month
$currentSectionIndex = 1
$currentArticlesInSection = 0
$items | ForEach-Object {
    $item = $_
    if ($currentArticlesInSection -eq 5) {
        # 遇到新的一弹
        $currentArticlesInSection = 1
        if ($item.Date.Month -eq $currentMonth) {
            # 同一个月，弹数++
            $currentSectionIndex ++
        } else {
            # 跨月了
            $currentYear = $_.Date.Year
            $currentMonth = $_.Date.Month
            $currentSectionIndex = 1
        }
        
    } else {
        # 同一弹
        $currentArticlesInSection++
    }

    $_ | Add-Member -MemberType NoteProperty -Name SectionDate -Value (New-Object System.DateTime $currentYear, $currentMonth, 1)
    $_ | Add-Member -MemberType NoteProperty -Name Section -Value $currentSectionIndex
    $_ | Add-Member -MemberType ScriptProperty -Name FullTitle -Value {  "【PowerShell 技能连载】 - {0:yyyy 年 MM 月}第 {1} 弹" -f $this.SectionDate, $this.Section }
}
$sections = $items | group FullTitle

$sections | ForEach-Object {
    echo $_.Name
    $_.Group | ForEach-Object {
        echo ("[url={0}]PowerShell 技能连载 {1:yyyy-MM-dd} {2}[/url]" -f $_.OriginalUrl, $_.Date, $_.Title)
    }
    echo ''

    echo $_.Name
    $_.Group | ForEach-Object {
        echo $_.Title
        echo $_.OriginalUrl
    }
    echo ''
} | Tee-Object -Variable 'output'

<#
Add-Type -Assembly PresentationCore
[Windows.Clipboard]::SetText($output)
#>

$OutputEncoding = [Console]::OutputEncoding
$output | clip.exe