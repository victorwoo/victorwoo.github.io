---
layout: post
date: 2023-05-31 00:00:32
title: "PowerShell 技能连载 - Invoke-RestMethod 退出错误"
description: PowerTip of the Day - Invoke-RestMethod Cancellation Issues
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
无论是 `Invoke-WebRequest` 还是 `Invoke-RestMethod`，都是简单易用的命令，用于从网络上下载信息。例如，以下简单代码可以查询任何公共 IP 地址的注册信息并返回其注册所有者：

```powershell
$IPAddress = '51.107.59.180'
Invoke-RestMethod -Uri "http://ipinfo.io/$IPAddress/json" -UseBasicParsing

ip       : 51.107.59.180
city     : Zürich
region   : Zurich
country  : CH
loc      : 47.3667,8.5500
org      : AS8075 Microsoft Corporation
postal   : 8090
timezone : Europe/Zurich
readme   : https://ipinfo.io/missingauth
```

如果在你的代码与互联网通信时出现问题，在 Windows PowerShell 中有一个硬编码的超时时间为 300 秒。因此，即使你的路由器出现故障，你的 PowerShell 脚本最终也会返回。

在 PowerShell 7 中，这两个命令的内部工作方式发生了重大改变。它们目前不再具有连接超时功能，因此如果你的连接中断，你的脚本将永远挂起。

幸运的是，这个错误目前正在解决中，并将在即将推出的 PowerShell 7 更新中修复。
<!--本文国际来源：[Invoke-RestMethod Cancellation Issues](https://blog.idera.com/database-tools/powershell/powertips/invoke-restmethod-cancellation-issues/)-->

