---
layout: post
date: 2015-01-29 12:00:00
title: "PowerShell 技能连载 - 复制命令行历史"
description: PowerTip of the Day - Copying Command Line History
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

要将 PowerShell 会话中键入过的所有 PowerShell 命令保存下来，请试试这行代码：

    (Get-History).CommandLine | clip.exe

它将所有的命令拷贝至剪贴板。然后您就可以将它们粘贴到 PowerShell ISE 并保存为文件。

<!--more-->
本文国际来源：[Copying Command Line History](http://community.idera.com/powershell/powertips/b/tips/posts/copying-command-line-history)
