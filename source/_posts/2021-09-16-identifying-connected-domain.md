---
layout: post
date: 2021-09-16 00:00:00
title: "PowerShell 技能连载 - 识别连上的 Domain"
description: PowerTip of the Day - Identifying Connected Domain
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
确定您连上的域名称的一种快速方法是 WMI：

```powershell
PS> Get-CimInstance -ClassName Win32_NTDomain

DomainName       DnsForestName                                  DomainControllerName
----------       -------------                                  --------------------
```

如果您未连接到域，则结果是一个空对象。

<!--本文国际来源：[Identifying Connected Domain](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-connected-domain)-->

