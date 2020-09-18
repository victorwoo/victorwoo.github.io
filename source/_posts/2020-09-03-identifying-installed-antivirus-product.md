---
layout: post
date: 2020-09-03 00:00:00
title: "PowerShell 技能连载 - 检测已安装的防病毒产品"
description: PowerTip of the Day - Identifying Installed Antivirus Product
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这行 PowerShell 代码可以帮助您识别 Windows 系统中安装的防病毒产品：

```powershell
PS> Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct
```

添加 `-ComputerName` 参数以查询远程系统。

请注意，此行仅返回正确注册的防病毒产品。结果看起来类似这样，并为您提供了防病毒产品和安装位置：

```powershell
displayName              : Windows Defender
instanceGuid             : {D68DDC3A-831F-4fae-9E44-DA132C1ACF46}
pathToSignedProductExe   : windowsdefender://
pathToSignedReportingExe : %ProgramFiles%\Windows Defender\MsMpeng.exe
productState             : 397568
timestamp                : Wed, 29 Jul 2020 18:37:24 GMT
PSComputerName
```

<!--本文国际来源：[Identifying Installed Antivirus Product](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-installed-antivirus-product)-->

