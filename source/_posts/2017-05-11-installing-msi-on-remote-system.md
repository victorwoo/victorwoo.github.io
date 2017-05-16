layout: post
date: 2017-05-11 00:00:00
title: "PowerShell 技能连载 - 在远程系统中安装 MSI"
description: PowerTip of the Day - Installing MSI on Remote System
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
以下是一些或许对您有用的代码。您需要远程系统的管理员权限。

```powershell
$ComputerName = 'NameOfMachineToInstall'
$TargetPathMSI = '\\softwareserver\product\package.msi'

$class = [wmiclass]"\\$ComputerName\ROOT\cimv2:Win32_Product"
$class.Install($TargetPathMSI)
```

如果权限和网络连接允许，这段代码将在远程系统中安装一个 MSI 包。请在开始之前调整好变量。第一个是需要安装 MSI 的机器名称。第二个是需要安装的 MSI 路径。

<!--more-->
本文国际来源：[Installing MSI on Remote System](http://community.idera.com/powershell/powertips/b/tips/posts/installing-msi-on-remote-system)
