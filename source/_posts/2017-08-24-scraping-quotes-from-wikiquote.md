---
layout: post
date: 2017-08-24 00:00:00
title: "PowerShell 技能连载 - 从 WikiQuote 搜集引用"
description: PowerTip of the Day - Scraping Quotes from WikiQuote
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当从 CSV 加载数据到 Excel 中时，我们无法指定格式。

```powershell
PS> Get-Quote

Text
----
If you don't know anything about computers, just remember that they are machines that do exactly w...
```

```powershell
PS> Get-Quote -Topics men

Text                                                                     Author
----                                                                     ------
But man is not made for defeat. A man can be destroyed but not defeated.  Ernest Hemingway (1899–1...
```

```powershell
PS> Get-Quote -Topics jewelry
WARNING: Topic 'jewelry'  not found. Try a different one!

PS> Get-Quote -Topics jewel

Text
----
Cynicism isn't smarter, it's only safer. There's nothing fluffy about optimism . … People have th...
```

以下脚本首先加载 HTML 内容，然后使用正则表达式来搜集 HTML 中的引用。当然这只适用于原文有规律的情况。wikiquotes 的引用模式是这样的：

```html
<li><ul>Quote<ul><li>Author</li></ul></li>
```

所以以下代码将搜索这个模式，然后清理结构中找到的文本：需要移除 HTML 标签，例如链接，多个空格需要合并为一个空格（通过嵌套函数 `Remove-Tag`）。

以下是代码：

```powershell
function Get-Quote ($Topics='Computer', $Count=1)
{
    function Remove-Tag ($Text)
    {
        $tagCount = 0
        $text = -join $Text.ToCharArray().Foreach{
            switch($_)
            {
                '<'  { $tagCount++}
                '>'  { $tagCount--; ' '}
                default { if ($tagCount -eq 0) {$_} }
            }

        }
        $text -replace '\s{2,}', ' '
    }

    $pattern = "(?im)<li>(.*?)<ul><li>(.*?)</li></ul></li>"

    Foreach ($topic in $topics)
    {
        $url = "https://en.wikiquote.org/wiki/$Topic"

        try
        {
            $content = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
        }
        catch [System.Net.WebException]
        {
            Write-Warning "Topic '$Topic' not found. Try a different one!"
            return
        }

        $html = $content.Content.Replace("`n",'').Replace("`r",'')
        [Regex]::Matches($html, $pattern) |
        ForEach-Object {
            [PSCustomObject]@{
                Text = Remove-Tag $_.Groups[1].Value
                Author = Remove-Tag $_.Groups[2].Value
                Topic = $Topic
            }
        } | Get-Random -Count $Count
    }
}



Get-Quote
Get-Quote -Topic Car
Get-Quote -Topic Jewel
Get-Quote -Topic PowerShell
```

<!--本文国际来源：[Scraping Quotes from WikiQuote](http://community.idera.com/powershell/powertips/b/tips/posts/scraping-quotes-from-wikiquote)-->
