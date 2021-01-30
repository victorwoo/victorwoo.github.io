---
layout: post
date: 2021-01-21 00:00:00
title: "PowerShell 技能连载 - 更好的 NetStat（第 4 部分）"
description: PowerTip of the Day - A Better NetStat (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技巧中，我们介绍了 `Get-NetTCPConnection` cmdlet，它是 Windows 系统上 netstat.exe 网络实用程序的更好替代方案，但是此命令仅限于 Windows，并且需要大量其他代码才能将原始信息转化为有用的信息。解析的主机名和进程名。

netstat.exe 的最兼容替代方案是基于 .NET Core 的解决方案，无论 PowerShell 在哪里运行，它都可以跨平台使用。

只需自己获取开源的 `GetNetStat` 模块 (https://github.com/TobiasPSP/GetNetStat)，它使用 .NET Core 代码来获取连接信息：

```powershell
PS> Install-Module -Name GetNetStat -Scope CurrentUser
```

安装模块后，将有一个名为 `Get-NetStat` 的新命令。现在，列出打开的连接非常简单，现在您可以在 Windows PowerShell 和 PowerShell 7 中通过并行处理来解析主机名和进程名。

这个简单的命令列出了到 HTTPS（端口 443）的所有打开的连接，并解析主机名：

```powershell
PS> Get-NetStat -RemotePort 443 -State Established -Resolve | Select-Object -Property RemoteIp, Pid, PidName

RemoteIp                          PID PIDName
--------                          --- -------
1drv.ms                          9432 WINWORD
lb-140-82-113-26-iad.github.com 21588 chrome
1drv.ms                          9432 WINWORD
1drv.ms                          9432 WINWORD
51.103.5.186                     5464 svchost
51.103.5.186                    12752 OneDrive
52.113.206.137                  13736 Teams
51.107.59.180                   14484 pwsh
```

<!--本文国际来源：[A Better NetStat (Part 4)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/a-better-netstat-part-4)-->

