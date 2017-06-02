---
layout: post
date: 2015-10-07 11:00:00
title: "PowerShell 技能连载 - 复制命令历史"
description: PowerTip of the Day - Copying Command History
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
您可以将整个命令历史拷贝到剪贴板中：

    (Get-History).CommandLine | clip.exe

该技术使用 PowerShell 3.0 带来的自动展开技术。若要在 PowerShell 2.0 中使用它，您需要像这样手工展开属性：

    Get-History | Select-Object -ExpandProperty commandline | clip.exe

要只拷贝最后五条命令，只需要为 `Get-History` 命令加上 `-Count` 参数即可：

    (Get-History -Count 5).CommandLine | clip.exe

<!--more-->
本文国际来源：[Copying Command History](http://community.idera.com/powershell/powertips/b/tips/posts/copying-command-history-0)
