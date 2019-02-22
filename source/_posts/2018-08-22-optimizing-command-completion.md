---
layout: post
date: 2018-08-22 00:00:00
title: "PowerShell 技能连载 - 优化命令自动完成"
description: PowerTip of the Day - Optimizing Command Completion
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 控制台（powershell.exe、pwsh.exe）提供了可扩展的自动完成支持。当您输入了一个空格和一个连字符，按下 `TAB` 键将循环切换可用的参数。

Windows PowerShell (powershell.exe) 与 Linux 和 macOS 的 PowerShell (pwsh.exe) 之间有一个巨大的差异。当您在后者中按下 `TAB` 键，它们将立即显示所有可用的选项，并且您可以选择一个需要的建议。

要为 powershell.exe 添加这个行为，只需要运行这行代码：

```powershell
PS C:\> Set-PSReadlineOption -EditMode Emacs  
```

下次当您输入参数的开头部分并按下 `TAB` 键时，您可以立即见到所有可用的选择。接下来，当重复输入这个命令时，您可以键入选择的首字母，按下 `TAB` 键即可完成选择。

这时候 Windows 用户可能会听到烦人的警告音。要关闭警告音，请运行：

```powershell
PS C:\> Set-PSReadlineOption -BellStyle None
```

<!--本文国际来源：[Optimizing Command Completion](http://community.idera.com/powershell/powertips/b/tips/posts/optimizing-command-completion)-->
