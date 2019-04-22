---
layout: post
date: 2019-04-18 00:00:00
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
PowerShell 可以通过 C# 形式的代码操作底层 API。通过这种方法，可以在内存中编译 API 函数并添加新类型。以下例子使用一个 API 函数来锁定工作站：

```powershell
Function Lock-WorkStation
{
    $signature = '[DllImport("user32.dll",SetLastError=true)]
    public static extern bool LockWorkStation();'
    $t = Add-Type -memberDefinition $signature -name api -namespace stuff -passthru
    $null = $t::LockWorkStation()
}
```

要锁定当前用户，请运行以下代码：

```powershell
PS C:\> Lock-WorkStation
```

<!--本文国际来源：[Locking Workstation](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/locking-workstation-1)-->

