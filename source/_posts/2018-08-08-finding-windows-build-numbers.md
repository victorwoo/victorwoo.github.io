---
layout: post
date: 2018-08-08 00:00:00
title: "PowerShell 技能连载 - 查看 Windows 生成号"
description: PowerTip of the Day - Finding Windows Build Numbers
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当运行 `winver.exe` 时，您可以方便地获取到完整的 Windows 生成号。通过 PowerShell 读取生成号并不是那么明显。并没有内置的 cmdlet。

不过，要创建这样功能的函数很简单：

```powershell
function Get-OSInfo
{
    $path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    Get-ItemProperty -Path $path -Name CurrentBuild, UBR, ReleaseID, CompositionEditionID |
        Select-Object -Property CurrentBuild, UBR, ReleaseID, CompositionEditionID
}
```

结果看起来类似这样：

```powershell
PS C:\> Get-OSInfo

CurrentBuild  UBR ReleaseId CompositionEditionID
------------  --- --------- --------------------
15063        1088 1703      Enterprise
```

<!--本文国际来源：[Finding Windows Build Numbers](http://community.idera.com/powershell/powertips/b/tips/posts/finding-windows-build-numbers)-->
