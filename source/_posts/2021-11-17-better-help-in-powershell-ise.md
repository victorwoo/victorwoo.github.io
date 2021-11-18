---
layout: post
date: 2021-11-17 00:00:00
title: "PowerShell 技能连载 - 改进 PowerShell ISE 的帮助"
description: PowerTip of the Day - Better Help in PowerShell ISE
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
仍有许多专业的脚本编写者使用内置 PowerShell ISE 编辑器，它仍然是一个快速可靠的脚本开发环境。如果您使用 PowerShell ISE，可能希望将它内置的帮助系统切换为在线帮助。请运行这段代码（在 PowerShell ISE 中）：

```powershell
PS> $psise.Options.UseLocalHelp = $false
```

运行此代码后，只要您在脚本窗格或控制台部分中单击命令，然后按 F1，PowerShell ISE 将对命令运行 `Get-Help` 并添加 `-Online` 开关参数，因此浏览器打开并显示复杂的、排版好的最新在线帮助。

尽管如此，您可能希望记住上面的命令：如果命令没有在线帮助，则可能仍有本地帮助文件。将 PowerShell ISE 选项恢复为 `$true` 将打开本地帮助。

<!--本文国际来源：[Better Help in PowerShell ISE](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/better-help-in-powershell-ise)-->

