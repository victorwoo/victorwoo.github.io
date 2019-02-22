---
layout: post
date: 2019-01-09 00:00:00
title: "PowerShell 技能连载 - 重制控制台颜色"
description: PowerTip of the Day - Resetting Console Colors
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 控制台里很容易把控制台颜色搞乱。一个不经意的调用意外地改变了颜色值，或者脚本错误地设置了颜色，可能会导致意外的结果。要验证这种情况，请打开一个 PowerShell 控制台（不是编辑器！），并且运行这段代码：

```powershell
PS> [Console]::BackgroundColor = "Green"
```

要快速地清除颜色，请运行这段代码：

```powershell
PS> [Console]::ResetColor()
```

接着运行 `Clear-Host` 可以清空显示。

<!--本文国际来源：[Resetting Console Colors](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/resetting-console-colors-b)-->
