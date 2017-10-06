---
layout: post
date: 2017-10-04 00:00:00
title: "PowerShell 技能连载 - Launching Daily Tools via Alias"
description: PowerTip of the Day - Launching Daily Tools via Alias
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
您可能知道一些 PowerShell 预定义的缩写名称：例如 `dir` 和 `ls` 等别名能够节约您每天的打字时间。有许多好的原因值得扩展这些别名的列表并且增加您日常使用的工具。

例如，原先需要点击使用 SnippingTool 截屏工具，不如为它增加一个别名：

```powershell
PS> Set-Alias -Name snip -Value snippingtool.exe

PS> snip
```

下一次您需要截取窗体的一部分到 bug 报告中时，只需要在 PowerShell 中运行 `snip` 即可。

另一个可能有用的工具是 `osk.exe`，您的 Windows 10 屏幕键盘，或者 `mstsc.exe` 来创建一个远程桌面连接。

要将您的别名持久化，只需要将它们增加到 PowerShell 配置文件脚本中。它的路径可以在这里找到：

```powershell
PS> $profile.CurrentUserAllHosts
C:\Users\username\Documents\WindowsPowerShell\profile.ps1
```

这个文件默认不存在。如果您创建了它，脚本中的任何内容都会在您启动一个 PowerShell 宿主的时候执行。您只需要启用脚本执行一次即可：

```powershell
PS> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

<!--more-->
本文国际来源：[Launching Daily Tools via Alias](http://community.idera.com/powershell/powertips/b/tips/posts/launching-daily-tools-via-alias)
