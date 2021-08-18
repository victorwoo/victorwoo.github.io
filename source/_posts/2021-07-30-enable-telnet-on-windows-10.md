---
layout: post
date: 2021-07-30 00:00:00
title: "PowerShell 技能连载 - 在 Windows 10 上启用 Telnet"
description: PowerTip of the Day - Enable Telnet on Windows 10
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
每个 Windows 10 版本都附带一个 telnet 客户端，但它最初是隐藏的。要启用 telnet 客户端，请以完全管理员权限运行以下命令：

```powershell
PS> Enable-WindowsOptionalFeature -Online -FeatureName TelnetClient -All


Path          :
Online        : True
RestartNeeded : False
```

安装 telnet 客户端后，您可以使用它与另一台计算机的任何端口进行远程通信。由于新命令 "`telnet`" 是一个控制台应用程序，因此请确保在真正的控制台窗口中运行它，例如 `powershell.exe` 或 `pwsh.exe`，而不是 ISE 编辑器。
<!--本文国际来源：[Enable Telnet on Windows 10](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/enable-telnet-on-windows-10)-->

