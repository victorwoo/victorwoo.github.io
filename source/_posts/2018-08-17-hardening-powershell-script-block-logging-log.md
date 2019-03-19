---
layout: post
date: 2018-08-17 00:00:00
title: "PowerShell 技能连载 - 强化 PowerShell 脚本块的日志"
description: PowerTip of the Day - Hardening PowerShell Script Block Logging Log
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您启用了 `ScriptBlockLogging` 后，PowerShell 将会记录所有在您机器上执行的所有 PowerShell 代码。如果没有启用它，所有安全相关的代码仍然会记录。这样很不错。然而，该任何用户都可以读取该日志，所以任何人都可以类似这样浏览记录下的代码:

```powershell
Get-WinEvent -FilterHashtable @{ ProviderName="Microsoft-Windows-PowerShell";  Id = 4104 }
```

To harden security and limit the access to the log file, you have two choices:
要强化安全并限制日志文件的读取，您有两个选择：

* 您可以通过安装数字证书来设置加密的日志。通过这种方法，记录的数据可以被保护起来，甚至其他的管理员同事也无法读取。然而，设置和管理这些证书并不那么简单。
* 您可以增强 PowerShell 操作日志的存取安全，并且使用和传统的安全日志相同的存取方式。通过这种方法，只有管理员可以读取该日志。这是我们今天要在本技能中讨论的方案：

```powershell
#requires -RunAsAdministrator

# this is where the  PowerShell operational log stores its settings
$Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\winevt\Channels\Microsoft-Windows-PowerShell/Operational"

# get the default  SDDL security definition for the classic security log
$sddlSecurity = ((wevtutil gl security) -like 'channelAccess*').Split(' ')[-1]

# get the current  SDDL security for the PowerShell log
$sddlPowerShell = (Get-ItemProperty -Path $Path).ChannelAccess

# store the current  SDDL security (just in case you want to restore it later)
$existsBackup = Test-Path -Path $Path
if (!$existsBackup)
{
    Set-ItemProperty -Path $Path -Name ChannelAccessBackup -Value $sddlPowerShell
}

# set the hardened  security to the PowerShell operational log
Set-ItemProperty -Path $Path -Name ChannelAccess -Value $sddlSecurity

# restart the service  to take effect
Restart-Service -Name EventLog -Force
```

当您运行该脚本时，读取 PowerShell 操作日志的权限被限制为只有本地管理员。

<!--本文国际来源：[Hardening PowerShell Script Block Logging Log](http://community.idera.com/powershell/powertips/b/tips/posts/hardening-powershell-script-block-logging-log)-->
