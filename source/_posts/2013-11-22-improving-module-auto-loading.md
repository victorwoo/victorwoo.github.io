---
layout: post
title: "PowerShell 技能连载 - 改进版的自动加载 Module"
date: 2013-11-22 00:00:00
description: PowerTip of the Day - Improving Module Auto-loading
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您按照[上一个技巧][Loading Modules Automatically]进行设置以后，PowerShell 3.0 便可以自动加载 Module。然而，对于某些 Module，该技术没有效果。那些 Cmdlet 仍然只能通过 `Import-Module` 的方式来导入 Module。

导致它们的原因是由于它们构建的方式。PowerShell 无法检测到这些 Module 导出了哪些 Cmdlet。

然而，有一行简单的命令可以让更多的 Module 自动变得可用：

	PS> Get-Module -ListAvailable -Refresh

该 `-Refresh` switch 参数告知 PowerShell 完整地遍历所有的 Module 并且生成或刷新内部的命令缓存。

[Loading Modules Automatically]: "/powershell/tip/2013/11/21/loading-modules-automatically"

<!--本文国际来源：[Improving Module Auto-loading](http://community.idera.com/powershell/powertips/b/tips/posts/improving-module-auto-loading)-->
