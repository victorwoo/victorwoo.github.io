---
layout: post
date: 2018-08-30 00:00:00
title: "PowerShell 技能连载 - 锁定工作站"
description: PowerTip of the Day - Locking Workstation
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您希望在 PowerShell 中锁定当前工作站，您可以利用 PowerShell 可以运行可执行程序的特性。以下是一个使用 `rundll32.exe` 来调用一个 Windows 内部函数来锁定工作站的快速函数：

```powershell
function Lock-Workstation
{
  rundll32.exe user32.dll,LockWorkStation
}
```

<!--本文国际来源：[Locking Workstation](http://community.idera.com/powershell/powertips/b/tips/posts/locking-workstation1)-->
