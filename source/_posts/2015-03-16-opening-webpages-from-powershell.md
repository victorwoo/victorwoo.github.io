layout: post
date: 2015-03-16 11:00:00
title: "PowerShell 技能连载 - 用 PowerShell 打开网页"
description: PowerTip of the Day - Opening Webpages from PowerShell
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
_适用于 PowerShell 所有版本_

假设您希望每天开始时，就用浏览器打开您最喜欢的网站。PowerShell 可以简单地实现这个需求。不过，这要看您是否喜欢自动打开网页。

使用 `Start-Process` 的时候，您可以通过参数指定选用哪个浏览器，以及提交的 URL 地址：

    # starts with a specific browser
    Start-Process -FilePath iexplore -ArgumentList www.powershellmagazine.com

这将在 Internet Explorer 中打开网站，而不是选用缺省的浏览器设置。

不过，它总是打开一个新的浏览器实例。请看另一种实现方式：

    # starts with default browser and adds to open browser
    Start-Process -FilePath www.tagesschau.de

这段代码中，我们将一个 URL 当做一个“可执行程序”，Windows 就会使用缺省的浏览器。如果缺省浏览器已经打开了，将在其中打开一个新的标签页，而不是打开一个新的浏览器窗口。

要让 PowerShell 在启动时自动打开网页，请确保 `$profile` 指向的文件路径存在。下一步，打开该脚本，并添加启动命令。

<!--more-->
本文国际来源：[Opening Webpages from PowerShell](http://powershell.com/cs/blogs/tips/archive/2015/03/16/opening-webpages-from-powershell.aspx)
