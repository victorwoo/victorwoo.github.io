layout: post
date: 2017-01-23 00:00:00
title: "PowerShell 技能连载 - 在资源管理器中打开 PowerShell"
description: PowerTip of the Day - Opening PowerShell Inside Explorer
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
一个在文件资源管理器中快速启动 PowerShell 的办法是导航到您数据的文件夹，然后点击导航条。这时导航面包屑控件变成了文件夹路径。将它改为 "powershell"，并按下回车键。

这时会打开 PowerShell，并且当前文件夹会设置为您导航到的文件夹。

不过，当前路径下有一个名为 "powershell" 的子文件夹时，这个技巧会失效。在这个例子中，文件资源管理器只会导航到该目录中。

<!--more-->
本文国际来源：[Opening PowerShell Inside Explorer](http://community.idera.com/powershell/powertips/b/tips/posts/opening-powershell-inside-explorer)
