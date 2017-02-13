$folder = '..\source\_posts'
$downloadPath = '..\source\img'
$relateUrl = '/img/'

if (gmo Blog) { rmo Blog }
ipmo ./Blog.psm1

function Get-Document($text) {
    $htmlDoc= New-Object -com "HTMLFILE"
    if ($htmlDoc.IHTMLDocument2_write) {
        $htmlDoc.IHTMLDocument2_write($text)
    } else {
        $htmlDoc.write($text)
    }

    return $htmlDoc
}

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

function Convert-HtmlToMarkdown ($html) {
    $html = $html -creplace '(?sm)^<P><A href="http://twitter\.com/home/\?status=.*$', ''
    $htmlFile = [System.IO.Path]::GetTempFileName()
    $markdownFile = [System.IO.Path]::GetTempFileName()
    sc $htmlFile $html -Encoding UTF8
    node .\html2markdown\index.js $htmlFile $markdownFile
    $markdown = gc -Raw $markdownFile -Encoding UTF8
    $markdown = $markdown -replace '&quot;', '"'
    $markdown = $markdown -replace '&amp;', '&'
    $markdown = $markdown -replace '&lt;', '<'
    $markdown = $markdown -replace '&gt;', '>'
    $markdown = $markdown -replace '&nbsp;', ' '

    del $htmlFile
    del $markdownFile
    $markdown = $markdown.Trim()
    return $markdown
}

function Get-YamlObj ([System.DateTime]$date, [string]$title) {
#function Get-HexoBlog ($yamlObj, $body, $date) {
    $yamlObj = [ordered]@{
        layout = 'post';
        date = $date.ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss');
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
    $htmlDoc = Get-Document $html
    $textContent = $htmlDoc.documentElement.innerText
    $htmlContent = $htmlDoc.documentElement.innerHTML
    $htmlDoc.Close()

    $textContent = Optimize-Content $textContent
    $mdContent = Convert-HtmlToMarkdown $htmlContent
    $markdown = $template -f $mdContent, $title, $url
    return $markdown
}

function Get-Index ($year, $month, $day, $name) {
    $indexTemplate = '* [{0:D2}-{1:D2}-{2:D2} ___](/powershell/tip/{3:D2}/{4:D2}/{5:D2}/{6})'
    return $indexTemplate -f $year, $month, $day, $year, $month, $day, $name
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

    cat $file -Encoding UTF8 -Raw | % {
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

    $newContent = cat $file -Encoding UTF8 -Raw | % {
        $line = $_
        $dict.Keys | % {
            $url = $_
            $newPath = $relateUrl + $dict[$url]
            $line = [string]$line.Replace($url, $newPath)
        }
        $line
    }

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($newContent)
    sc $file $bytes -Encoding Byte
    #[IO.File]::WriteAllText($file, $newContent, [System.Text.Encoding]::UTF8)
}

function Get-PostContent ([string]$url) {
    Write-Debug $url
    $resp = Invoke-WebRequest $url
    return $resp.ParsedHtml.body.getElementsByClassName('content full text')[0].getElementsByClassName('content')[0].innerHTML
}

echo "[请求] 正在访问服务器"
$resp = Invoke-WebRequest http://community.idera.com/powershell/powertips/
echo "[响应] 收到服务器响应"
$ul = $resp.ParsedHtml.getElementById('pi874-paged-content').getElementsByClassName('content-list content margin-bottom')[0]

$newlyAdded = $false
for ($i = $ul.childNodes.length - 1; $i -ge 0; $i--) {
    $li = $ul.childNodes[$i]
    $date = Get-Date $li.getElementsByClassName('attribute-value')[0].innerText
    $name = $li.getElementsByClassName('name')[0]
    $a = $name.childNodes[1]
    $title = $a.innerText
    $url = $a.href
    $nameProp = $a.nameProp

    $fileName = '{0:yyyy-MM-dd}-{1}.md' -f $date, $nameProp
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

        sc $targetFile $content -Encoding UTF8
        Get-Picture $targetFile
        # Start-Process "C:\Program Files\Typora\Typora.exe" $targetFile
        Start-Process "code" $targetFile
        sleep 1
        
        $index = Get-Index $date.Year $date.Month $date.Day $nameProp
        $indexFile = Join-Path $folder '2013-09-09-index.md'
        ac $indexFile $index
    }
}

exit

$feed | sort { $_.id } | foreach {
    $entry = $_

    # 提取日期
    $date = Get-Date $entry.published
    
    $parts = $entry.id -split '/'
    $name = ($parts[$parts.Length - 1] -split '\.')[0]
    $fileName = '{0:yyyy-MM-dd}-{1}.md' -f $date, $name
    $targetFile = Join-Path $folder $fileName
    if (Test-Path $targetFile) {
        echo "[文件已存在] $fileName"
    } else {
        $newlyAdded = $true
        echo "[正在生成] $targetFile ..."
        $yamlObj = Get-YamlObj $entry
        $markdown = Get-Markdown $entry
        $content = Out-HexoBlog $yamlObj $markdown $date
        #$content = Get-Post $entry
        
        sc $targetFile $content -Encoding UTF8
        Get-Picture $targetFile
        Start-Process "d:\greensoft\Sublime Text 3 x32\sublime_text.exe" $targetFile
        sleep 1
        
        $index = Get-Index $date.Year $date.Month $date.Day $name
        $indexFile = Join-Path $folder '2013-09-09-index.md'
        ac $indexFile $index
    }
}

if ($newlyAdded) {
    $indexFile = Join-Path $folder '2013-09-09-index.md'
    
    Start-Process "d:\greensoft\Sublime Text 3 x32\sublime_text.exe" $indexFile
}