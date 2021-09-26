# Install-Module -Name PowerHTML
# brew install dos2unix

# cd /Users/vichamp/temp/blog.vichamp.com/util
$ErrorActionPreference = 'Stop'

$folder = '..\source\_posts'
$downloadPath = '..\source\img'
$relateUrl = '/img/'

if (Get-Module Blog) { Remove-Module Blog }
Import-Module ./Blog.psm1

function Get-Document($text) {
    # TODO 内联
    return $text | ConvertFrom-Html
}

# 对正文内容做一些微调。
function Optimize-Content($text) {
    $text = $text.Replace('_All PowerShell Versions_', '_适用于 PowerShell 所有版本_')
    $lines = $text -split "`n"
    $lines =  $lines | where {
        !$_.Contains('ReTweet this Tip!')
    } | foreach {
        return $_.TrimEnd()
    }

    return $lines -join "`n"
}

# 调用 html2markdown 将 HTML 字符串转换为 markdown 文本。
function Convert-HtmlToMarkdown ($html) {
    $html = $html -creplace '(?sm)^<P><A href="http://twitter\.com/home/\?status=.*$', ''
    $htmlFile = [System.IO.Path]::GetTempFileName()
    $markdownFile = [System.IO.Path]::GetTempFileName()
    Set-Content $htmlFile $html -Encoding utf8NoBOM
    node html2markdown/index.js $htmlFile $markdownFile
    $markdown = Get-Content -Raw $markdownFile -Encoding utf8
    $markdown = $markdown -replace '&quot;', '"'
    $markdown = $markdown -replace '&amp;', '&'
    $markdown = $markdown -replace '&lt;', '<'
    $markdown = $markdown -replace '&gt;', '>'
    $markdown = $markdown -replace '&nbsp;', ' '

    del $htmlFile
    del $markdownFile
    $markdown = $markdown.ToString().Trim()
    if ($markdown -eq 'System.Object[]') { $markdown = '' }
    return $markdown
}

# 根据本地日期和文章标题生成 YAML 对象
function Get-YamlObj ([System.DateTime]$date, [string]$title) {
#function Get-HexoBlog ($yamlObj, $body, $date) {
    $yamlObj = [ordered]@{
        layout = 'post';
        # todo
        #date = $date.ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss');
        date = $date.ToString('yyyy-MM-dd HH:mm:ss');
        title = 'PowerShell 技能连载 - {0}' -f $title;
        description = 'PowerTip of the Day - {0}' -f $title;
        categories = @('powershell', 'tip');
        tags = @('powershell', 'tip', 'powertip', 'series', 'translation');
    }

    return $yamlObj
}

function Get-MarkDown ($html, $title, $url) {
    $template = @"
{0}

<!--more-->
本文国际来源：[{1}]({2})
"@

    $mdContent = Convert-HtmlToMarkdown $html
    $markdown = $template -f $mdContent, $title, $url
    return $markdown
}

function Get-Index ($year, $month, $day, $title) {
    $indexTemplate = '* [{0:D2}-{1:D2}-{2:D2} ___](/powershell/tip/{3:D2}/{4:D2}/{5:D2}/{6})'
    return $indexTemplate -f $year, $month, $day, $year, $month, $day, $title
}

function Download-Picture($url, $fileName) {
    echo "downloading $url to $fileName"
    $fullPath = Join-Path $downloadPath $fileName
    Invoke-WebRequest -Uri $url -OutFile $fullPath
    return $?
}

function Get-Picture($file) {
    $index = 1
    $fileBaseName = ([System.IO.FileInfo]$file).BaseName
    [System.Collections.Generic.Dictionary[[string],[string]]] $dict = New-Object 'System.Collections.Generic.Dictionary[[string], [string]]'

    Get-Content $file -Encoding UTF8 -Raw | % {
        $regex = [regex] '!\[(?<desc>.*?)\]\((?<url>.*?)\)'
        $matches = $regex.Matches($_)
        
        if ($matches.Count) {
            $matches.ForEach({
                $fullMatch = $_.Value
                $desc = $_.Groups['desc'].Value
                $url = $_.Groups['url'].Value
                if ($url -like 'http*') {
                    $extension = [System.IO.Path]::GetExtension($url)
                    $targetPath = "$fileBaseName-{0:d3}$extension" -f $index++
                    $result = Download-Picture $url $targetPath
                    if ($result) {
                        $dict.Add($url, $targetPath)
                    }
                }
            })
        }
    }

    $newContent = Get-Content $file -Encoding UTF8 -Raw | % {
        $line = $_
        $dict.Keys | % {
            $url = $_
            $newPath = $relateUrl + $dict[$url]
            $line = [string]$line.Replace($url, $newPath)
        }
        $line
    }

    #$bytes = [System.Text.Encoding]::UTF8.GetBytes($newContent)
    #Set-Content $file $bytes -Encoding Byte
    Set-Content $file $newContent -Encoding utf8NoBOM
    #[IO.File]::WriteAllText($file, $newContent, [System.Text.Encoding]::UTF8)
}

function Get-PostContent ([string]$url) {
    Write-Debug $url
    $resp = Invoke-WebRequest $url
    $htmlDoc = $resp | ConvertFrom-Html
    $entitizedHtml = $htmlDoc.SelectSingleNode('//div[@class="content full text"]/div[@class="content"]').InnerHtml
    return [System.Net.WebUtility]::HtmlDecode($entitizedHtml)
}

###########

$DebugPreference = 'Continue'

if (!$resp) {
    echo "[请求] 正在访问服务器"
    $resp = Invoke-WebRequest https://community.idera.com/database-tools/powershell/powertips
    echo "[响应] 收到服务器响应"
}
$htmlDoc = $resp | ConvertFrom-Html
$listNode = $htmlDoc.SelectSingleNode('//*[@id="pifragment-874-paged-content"]/ul[@class="content-list list content margin-bottom"]')

$lis = [Array]$listNode.SelectNodes('li[@class="content-item list"]')
[Array]::Reverse($lis)


$newlyAdded = $false
$lis | ForEach-Object {
    $li = $PSItem
    $date = Get-Date $li.SelectSingleNode('.//span[@class="attribute-value"]').InnerText
    Write-Debug "Date: $date"
    $a = $li.SelectSingleNode('.//h3[@class="name"]/a[2]')
    $title = $a.InnerText
    Write-Debug "Title: $title"
    $url = $a.GetAttributeValue('href', '')
    Write-Debug "Link: $url"
    $name = $url -split '/' | Select-Object -Last 1 -Unique
    $fileName = '{0:yyyy-MM-dd}-{1}.md' -f $date, $name
    $targetFile = Join-Path $folder $fileName
    if (Test-Path $targetFile) {
        echo "[文件已存在] $fileName"
    } else {
        $htmlContent = Get-PostContent $url

        $newlyAdded = $true
        echo "[正在生成] $targetFile ..."
        $yamlObj = Get-YamlObj $date $title
        $markdown = Get-Markdown $htmlContent $title $url
        $content = Out-HexoBlog $yamlObj $markdown $date

        $content = $content.Split("`n") | ForEach-Object { 
            $_ -ireplace '^.*Twitter This Tip.*$', '' -ireplace '- - -', ''
        }
        
        Set-Content $targetFile $content -Encoding UTF8
        Get-Picture $targetFile
        # Start-Process "C:\Program Files\Typora\Typora.exe" $targetFile
        dos2unix $targetFile
        Start-Process "code" "`"$targetFile`""
        sleep 1
        
        $index = Get-Index $date.Year $date.Month $date.Day $title
        $indexFile = Join-Path $folder '2013-09-09-index.md'
        ac $indexFile $index
    }

}

exit

Get-PostContent 'https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/inverting-bits'