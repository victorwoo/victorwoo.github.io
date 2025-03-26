---
layout: post
date: 2024-10-07 00:00:00
title: "PowerShell 技能连载 - 批量检测服务器端口"
description: "PowerTip of the Day - Batch server port detection"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
使用 PowerShell 可以快速地检测服务器端口。以下是一个示例：

```powershell
80, 443 | % { Test-Connection -ComputerName www.microsoft.com -TcpPort $_ }
```

在 PowerShell 提示符下运行这段代码，那么它将尝试连接到一个名为 `www.microsoft.com` 的计算机，并尝试连接端口 80 和 443。如果网络连接正常，那么您将会看到类似下面的输出：

```powershell
True
True
```
