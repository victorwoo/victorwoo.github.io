---
layout: post
date: 2021-02-12 00:00:00
title: "PowerShell 技能连载 - 探索 Windows 上的程序包管理器（第 1 部分）"
description: PowerTip of the Day - Discovering Package Managers on Windows (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 Linux 世界中，程序包管理器是一种下载和安装软件的既定方法。在 Windows 上，包管理器对于许多人来说仍然是新概念。

如果您是 Windows 系统管理员，并且想为所有用户下载并安装标准软件包，那么 "Chocolatey" 将是首选。该程序包管理器在拥有完全管理员权限的情况下最有效，并使用其默认安装程序包安装软件。

注意：为了能够运行脚本和下载代码，作为先决条件，您可能必须运行以下代码：

```powershell
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor
[System.Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

要安装 Chocolatey，请在 PowerShell 中运行以下行：

```powershell
Invoke-RestMethod -UseBasicParsing -Uri 'https://chocolatey.org/install.ps1' | Invoke-Expression
```

安装成功后，会有一个名为 `choco` 的新命令，您现在可以使用该命令下载和安装软件。

例如，如果您想为所有用户安装 PowerShell 7，请运行以下命令：

```powershell
choco install powershell-core
```

<!--本文国际来源：[Discovering Package Managers on Windows (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/discovering-package-managers-on-windows-part-1)-->

