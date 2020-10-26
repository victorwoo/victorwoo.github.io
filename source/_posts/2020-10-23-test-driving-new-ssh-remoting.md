---
layout: post
date: 2020-10-23 00:00:00
title: "PowerShell 技能连载 - 试用新的 SSH 远程操作"
description: PowerTip of the Day - Test-Driving New SSH Remoting
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您想试用 SSH 而非 WinRM 的新 PowerShell 远程操作替代方案，请确保先安装了 PowerShell 7。

接下来，在 PowerShell 7 中，安装以下模块：

```powershell
PS> Install-Module -Name Microsoft.PowerShell.RemotingTools -Scope CurrentUser
```

一旦安装了模块，就可以在提升权限的 PowerShell 7 Shell 中，仅需一个调用即可启用基于 SSH 的新远程处理：

```
PS> Enable-SSHRemoting
```

安装完成后，打开提升的 PowerShell 7 Shell，然后尝试远程连接到您自己的计算机上：

```powershell
PS> Enter-PSSession -HostName $env:computername -UserName remotingUser
```

一旦能按预期运行后，就可以使用相同的技术将跨平台从任何 PowerShell 7 实例远程连接到另一个实例。

<!--本文国际来源：[Test-Driving New SSH Remoting](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/test-driving-new-ssh-remoting)-->

