---
layout: post
date: 2019-05-20 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell 中使用 SSL/HTTPS"
description: PowerTip of the Day - Using SSL/HTTPS from PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
根据您的 PowerShell、.NET Framework 的版本和升级，WEB 连接的缺省安全协议可能仍然是 SSL3。您可以方便地查明它：

```powershell
[Net.ServicePointManager]::SecurityProtocol
```

如果返回的协议不包含 Tls12，那么您可能无法用 PowerShell 连接到安全的 Web Service 和网站。我们只需要这样操作就可以启用更多的服务：

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Ssl3 -bor [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::SecurityProtocol
```

<!--本文国际来源：[Using SSL/HTTPS from PowerShell](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-ssl-https-from-powershell)-->

