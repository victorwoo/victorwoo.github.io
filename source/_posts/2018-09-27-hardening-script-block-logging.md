---
layout: post
date: 2018-09-27 00:00:00
title: "PowerShell 技能连载 - 强化脚本块日志"
description: PowerTip of the Day - Hardening Script Block Logging
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
默认情况下，脚本块日志数据对所有人都可见，不仅是管理员。当启用了脚本块日志后，所有用户都可以访问日志并读取它的内容。最简单的方式是用这行代码下载工具：

```powershell
Install-Module -Name scriptblocklogginganalyzer -Scope CurrentUser
Get-SBLEvent | Out-GridView
```

有一些方法可以强化脚本块日志，并确保只有管理员才能读取这些日志。请运行以下代码将存取权限改为仅允许管理员存取：

```powershell
#requires -RunAsAdministrator

$Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\winevt\Channels\Microsoft-Windows-PowerShell/Operational"
# get the default access permission for the standard security log...
$sddlSecurity = ((wevtutil gl security) -like 'channelAccess*').Split(' ')[-1]
# get the current permissions
$sddlPowerShell = (Get-ItemProperty -Path $Path).ChannelAccess
# make a backup of the current permissions
New-ItemProperty -Path $Path -Name ChannelAccessBackup -Value $sddlPowerShell -ErrorAction Ignore
# apply the hardened permissions
Set-ItemProperty -Path $Path -Name ChannelAccess -Value $sddlSecurity
# restart service to take effect
Restart-Service -Name EventLog -Force
```

现在，当一个普通用户尝试读取脚本块日志的记录时，什么信息也不会返回。

<!--本文国际来源：[Hardening Script Block Logging](http://community.idera.com/powershell/powertips/b/tips/posts/hardening-script-block-logging)-->
