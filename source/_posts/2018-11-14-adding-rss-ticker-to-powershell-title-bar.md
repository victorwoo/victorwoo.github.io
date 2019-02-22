---
layout: post
date: 2018-11-14 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell 标题栏显示 RSS 标题"
description: PowerTip of the Day - Adding RSS Ticker to PowerShell Title Bar
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
一个新的 PowerShell 后台线程可以在后台工作，例如每 5 秒钟在 PowerShell 窗口标题栏上显示新的 RSS 供稿。

首先，我们先看看如何获取新闻供稿内容：

```powershell
$RSSFeedUrl = 'https://www.technologyreview.com/stories.rss'
$xml = Invoke-RestMethod -Uri $RSSFeedUrl
$xml | ForEach-Object {
    "{0} {1}" -f $_.title, $_.description
}
```

可以自由调整 RSS 公告的地址。如果修改了地址，请也注意调整 "`title`" 和 "`description`" 属性名。每个 RSS 供稿可以任意命名这些属性。

以下是向标题栏添加新内容的完整解决方案：

```powershell
$Code = {
    # receive the visible PowerShell window reference
    param($UI)

    # get RSS feed messages
    $RSSFeedUrl = 'https://www.technologyreview.com/stories.rss'
    $xml = Invoke-RestMethod -Uri $RSSFeedUrl

    # show a random message every 5 seconds
    do
    {
        $message = $xml | Get-Random
        $UI.WindowTitle = "{0} {1}" -f $message.title, $message.description
        Start-Sleep -Seconds 5
    } while ($true)
}

# create a new PowerShell thread
$ps = [PowerShell]::Create()
# add the code, and a reference to the visible PowerShell window
$null = $ps.AddScript($Code).AddArgument($host.UI.RawUI)

# launch background thread
$null = $ps.BeginInvoke()
```

<!--本文国际来源：[Adding RSS Ticker to PowerShell Title Bar](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/adding-rss-ticker-to-powershell-title-bar)-->
