---
layout: post
date: 2017-12-22 00:00:00
title: "PowerShell 技能连载 - 通过 PowerShell 远程处理操作远程机器"
description: PowerTip of the Day - Accessing Remote Machines via PowerShell Remoting
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
当您在目标机器上启用了 PowerShell 远程处理，请试试交互式地连接它。以下是您值得尝试的例子。只需要确保将 `targetComputerName` 替换成您需要连接的目标机器名即可：

```powershell
PS C:\> Enter-PSSession -ComputerName targetComputerName

[targetComputerName]: PS C:\Users\User12\Documents> $env:COMPUTERNAME
TARGETCOMPUTERNAME

[targetComputerName]: PS C:\Users\User12\Documents> exit

PS C:\> $env:COMPUTERNAME
YOURCOMPUTERNAME
```

如果连接失败并且报 "Access Denied" 错误，您可能需要使用 `-Credential` 参数并且使用一个不同的用户账户来登录远程计算机。您可能需要本地管理员特权。

如果连接失败并且报告 RDP 错误，或者如果 WinRM 无法找到目标计算机名，请使用 `Test-WSMan` 检查连接。如果这无法连接上，请重新检查远程设置。您可能需要像之前的技能中描述的那样，先在目标机器上运行 `Enable-PSRemoting`。

请不要运行会打开窗口的命令。只能运行产生文本信息的命令。

要离开远程会话，请使用 `exit` 命令。

<!--more-->
本文国际来源：[Accessing Remote Machines via PowerShell Remoting](http://community.idera.com/powershell/powertips/b/tips/posts/accessing-remote-machines-via-powershell-remoting)
