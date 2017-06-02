---
layout: post
date: 2015-06-29 11:00:00
title: "PowerShell 技能连载 - 打开网页"
description: PowerTip of the Day - Open Web Page
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
要快速地在 Internet Explorer 中打开新的网页，您可以像这样定义一个名为 `Show-WebPage` 的新函数：

    #requires -Version 2
    
    function Show-WebPage
    {
        param
        (
            [Parameter(Mandatory = $true, HelpMessage = 'URL to open')]
            $URL
        )
    
        Start-Process -FilePath iexplore.exe -ArgumentList $URL
    }

当您运行这段脚本并执行 `Show-WebPage` 时，该命令将询问您要打开的 URL。您也可以通过 `Show-WebPage` 的参数提交 URL。

请注意该函数使用了 `Start-Process` 命令来启动您指定的浏览器。如果您将这行代码改为：

    Start-Process -FilePath $URL

那么将会使用您的缺省浏览器来打开该 URL。

<!--more-->
本文国际来源：[Open Web Page](http://community.idera.com/powershell/powertips/b/tips/posts/open-web-page)
