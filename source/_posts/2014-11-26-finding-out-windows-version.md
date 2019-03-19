---
layout: post
date: 2014-11-26 12:00:00
title: "PowerShell 技能连载 - 查看 Windows 版本"
description: PowerTip of the Day - Finding Out Windows Version
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

您有安装 Windows 8.1 Basic 版、Pro 版，或 Enterprise 版吗？查看 Windows 版本号很容易，但查看具体是哪个子系列则不这么容易。

最好的方法是，获取 SKU 号，它能精确地体现 Windows 的版本类型，但如何将数字转化为一个有意义的名字也不太容易：

```
PS> Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty OperatingSystemSKU

48
```

一个稍好的方式是用这段代码返回您当前使用的许可类型的明确的文字描述：

```
PS> Get-WmiObject SoftwareLicensingProduct -Filter 'Name like "Windows%" and LicenseStatus=1' | Select-Object -ExpandProperty Name

Windows(R), Professional edition
```

另一种方法也可以返回 Windows 的主要版本信息：

```
PS> Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption

Microsoft Windows 8.1 Pro
```

<!--本文国际来源：[Finding Out Windows Version](http://community.idera.com/powershell/powertips/b/tips/posts/finding-out-windows-version)-->
