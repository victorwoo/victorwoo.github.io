---
layout: post
title: "PowerShell 技能连载 - 复制命令行历史记录"
date: 2014-07-08 00:00:00
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
如果您在使用 PowerShell 的过程中突然发现刚才键入的某些代码起作用了，您接下来会想把这些代码复制并粘贴到一个脚本编辑器中，将它们保存起来，然后分享给朋友。

以下是操作方法：

	Get-History -Count  5  |  Select-Object  -ExpandProperty  CommandLine  |  clip.exe

这将会把您最后键入的 5 条命令复制到剪贴板中。

<!--more-->
本文国际来源：[Copying Command History](http://community.idera.com/powershell/powertips/b/tips/posts/copying-command-history)
