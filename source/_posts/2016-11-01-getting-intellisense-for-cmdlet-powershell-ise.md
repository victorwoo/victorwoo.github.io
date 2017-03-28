layout: post
date: 2016-11-01 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell ISE 中获得 Cmdlet 的 IntelliSense"
description: PowerTip of the Day - Getting IntelliSense for Cmdlet (PowerShell ISE)
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
如果您在阅读某些加载到 PowerShell ISE 中的 PowerShell 代码，要获取额外信息十分容易。只需要点击想获得详情的 cmdlet，然后按下 CTRL+SPACE 键即可（译者注：可能会和 IME 切换快捷键冲突）。

这将调出 IntelliSense 菜单，即平时按下 "-" 和 "." 触发键时显示的菜单。由于只有一个 cmdlet 匹配成功，所以该列表只有一个项目。过一小会儿，就会弹出一个显示该 cmdlet 支持的所有参数的 tooltip。

如果您想了解更多，请按 F1 键。PowerShell ISE 将把当前位置的 cmdlet 名送给 `Get-Help` 命令。该帮助将在一个独立的新窗口中显示。

<!--more-->
本文国际来源：[Getting IntelliSense for Cmdlet (PowerShell ISE)](http://community.idera.com/powershell/powertips/b/tips/posts/getting-intellisense-for-cmdlet-powershell-ise)
