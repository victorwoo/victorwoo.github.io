---
layout: post
date: 2020-04-28 00:00:00
title: "PowerShell 技能连载 - 管理自动重启"
description: PowerTip of the Day - Managing Automatic Reset
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当 Windows 系统崩溃时，通常会立即重新启动。这称为“自动重置功能”，使用此此行代码即可检查您的计算机是否支持此功能：

```powershell
Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property Name, AutomaticResetCapability
```

系统是否实际执行自动重启由“`AutomaticResetBootOption`”控制：

```powershell
Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property Name, AutomaticResetBootOption
```

If you own Administrator privileges, you can even change this setting. To turn off automatic reset booting, run this:
如果您拥有管理员特权，甚至可以更改此设置。要关闭自动重置启动，请运行以下命令：

```powershell
Set-CimInstance -Query 'Select * From Win32_ComputerSystem' -Property @{AutomaticResetBootOption=$false}
```

有关 WMI 类 `Win32_ComputerSystem` 的更多信息，请访问[http://powershell.one/wmi/root/cimv2/win32_computersystem](http://powershell.one/wmi/root/cimv2/win32_computersystem）。

<!--本文国际来源：[Managing Automatic Reset](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-automatic-reset)-->

