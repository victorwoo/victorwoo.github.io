---
layout: post
date: 2018-08-29 00:00:00
title: "PowerShell 技能连载 - 检测 WinPE"
description: PowerTip of the Day - Detecting WinPE
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
PowerShell 可以在 WinPE 环境中运行。如果您希望检测 PowerShell 脚本是否运行在 WinPE 员警中，您只需要检查某个注册表键是否存在：

```powershell
function Test-WinPE
{
  return Test-Path -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlset\Control\MiniNT
}
```

如果您在 WinPE 环境中运行，这个函数返回 `$true`。

<!--more-->
本文国际来源：[Detecting WinPE](http://community.idera.com/powershell/powertips/b/tips/posts/detecting-winpe)
