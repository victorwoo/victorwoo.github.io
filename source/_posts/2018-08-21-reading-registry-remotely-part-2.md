---
layout: post
date: 2018-08-21 00:00:00
title: "PowerShell 技能连载 - 远程读取配置表（第 2 部分）"
description: PowerTip of the Day - Reading Registry Remotely (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个例子中我们演示了使用早期的 DCOM 协议从远程读取另一台机器的注册表代码。

如果您可以使用 PowerShell 远程处理，情况变得更简单。您现在可以简单地编写在本机可运行的代码，然后将它“发射”到目标机器（支持多台）：

```powershell
# adjust this to a remote computer of your choice
# (or multiple computers, comma-separated)
# PowerShell remoting needs to be enabled on that computer
# and you need to have local Admin privileges on that computer
$ComputerName = 'pc01'

# execute this code remotely on the machine(s)
$code = {
    # read the given registry value...
    Get-ItemProperty -Path hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* |
        # and show the reg values with the names below
        Select-Object DisplayName, DisplayVersion, UninstallString
}

# "beam" the code over to the target computer(s), and retrieve
# the result, then show it in a grid view window
Invoke-Command -ScriptBlock $code -ComputerName $ComputerName |
    Out-GridView
```

通过使用 PowerShell 远程处理，您只需要确保 PowerShell 远程处理的先决条件都具备。您可以用这条命令（需要本地管理员特权）：

```powershell
PS C:\> Enable-PSRemoting -SkipNetworkProfileCheck -Force
```

<!--本文国际来源：[Reading Registry Remotely (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/reading-registry-remotely-part-2)-->
