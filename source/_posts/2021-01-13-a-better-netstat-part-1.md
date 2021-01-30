---
layout: post
date: 2021-01-13 00:00:00
title: "PowerShell 技能连载 - 更好的 NetStat（第 1 部分）"
description: PowerTip of the Day - A Better NetStat (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 Windows 系统上，netstat.exe 是一个有用的实用程序，用于检查打开的端口和侦听器。但是，该工具仅返回文本，具有隐式参数，并且无法跨平台使用。

在 Windows 系统上，可以使用名为 `Get-NetTCPConnection` 的新 PowerShell cmdlet，该 cmdlet 模仿 netstat.exe 中的许多功能。例如，您可以列出任何软件（浏览器）当前打开的所有 HTTPS 连接（端口443）：

```powershell
PS> Get-NetTCPConnection -RemotePort 443 -State Established

LocalAddress  LocalPort RemoteAddress  RemotePort State       AppliedSetting OwningProcess
------------  --------- -------------  ---------- -----       -------------- -------------
192.168.2.105 58640     52.114.74.221  443        Established Internet       14204
192.168.2.105 56201     52.114.75.149  443        Established Internet       9432
192.168.2.105 56200     52.114.142.145 443        Established Internet       13736
192.168.2.105 56199     13.107.42.12   443        Established Internet       12752
192.168.2.105 56198     13.107.42.12   443        Established Internet       9432
192.168.2.105 56192     40.101.81.162  443        Established Internet       9432
192.168.2.105 56188     168.62.58.130  443        Established Internet       10276
192.168.2.105 56181     168.62.58.130  443        Established Internet       10276
192.168.2.105 56103     13.107.6.171   443        Established Internet       9432
192.168.2.105 56095     13.107.42.12   443        Established Internet       9432
192.168.2.105 56094     13.107.43.12   443        Established Internet       9432
192.168.2.105 55959     140.82.112.26  443        Established Internet       21588
192.168.2.105 55568     52.113.206.137 443        Established Internet       13736
192.168.2.105 55555     51.103.5.186   443        Established Internet       12752
192.168.2.105 49638     51.103.5.186   443        Established Internet       5464
```

不幸的是，`Get-NetTCPConnection` 有严格的限制。例如，它无法解析 IP 地址或进程 ID，因此您无法轻松发现所连接的服务器名称以及维护连接的程序。并且仅在 Windows 系统上可用。

在接下来的部分中，让我们一一消除这些限制。

<!--本文国际来源：[A Better NetStat (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/a-better-netstat-part-1)-->

