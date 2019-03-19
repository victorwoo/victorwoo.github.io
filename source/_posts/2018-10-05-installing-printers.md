---
layout: post
date: 2018-10-05 00:00:00
title: "PowerShell 技能连载 - 安装打印机"
description: PowerTip of the Day - Installing Printers
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
从 Windows 8 和 Server 2012 R2 起，这些操作系统附带发行了一个名为 `PrintManagement` 的 PowerShell 模块。该模块中的 cmdlet 可以实现脚本化安装和配置打印机。以下是一段帮助您起步的代码：

```powershell
$PrinterName = "MyPrint"
$ShareName = "MyShare"
$DriverName = 'HP Designjet Z Series PS Class Driver'
$portname = "${PrinterName}:"

Add-PrinterDriver -Name $DriverName
Add-PrinterPort -Name $portname
Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $portname -ShareName $ShareName

# requires Admin privileges
# Set-Printer -Name $PrinterName -Shared $true
```

它从驱动库中安装了一个新的打印机。新的打印机默认没有在网络上共享，因为需要管理员权限。作为管理员，您可以运行 `Set-Printer` 来启用共享，也可以向 `Add-Printer` 命令添加 `-Shared` 开关参数。

要探索 `PrintManagement` 模块中的其它 cmdlet，请使用这行代码：

```powershell
PS> Get-Command -Module PrintManagement
```

请注意 Windows 7 中没有包含该模块，而且无法在 Windows 7 中安装，因为 Windows 7 缺少运行该模块中 cmdlet 的某些依赖项。

<!--本文国际来源：[Installing Printers](http://community.idera.com/powershell/powertips/b/tips/posts/installing-printers)-->
