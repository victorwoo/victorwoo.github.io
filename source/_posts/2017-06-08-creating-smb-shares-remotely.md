---
layout: post
date: 2017-06-08 00:00:00
title: "PowerShell 技能连载 - 远程创建 SMB 共享"
description: PowerTip of the Day - Creating SMB Shares Remotely
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下几行代码能在远程服务器上创建一个 SMB 共享：

```
#requires -Version 3.0 -Modules CimCmdlets, SmbShare -RunAsAdministrator
$computername = 'Server12'
$shareName = 'ScriptExchange'
$fullAccess = 'domain\groupName'

$session = New-CimSession -ComputerName $computername
New-SMBShare -Name $shareName -Path c:\Scripts -FullAccess $fullAccess -CimSession $session
Remove-CimSession -CimSession $session
```

您可以在客户端将该共享映射为一个网络驱动器。请注意这个网络共享是单用户的，所以如果您使用 Administrator 账户做了映射，那么无法在 Windows Explorer 中存取。

```powershell
$computername = 'Server12'
$shareName = 'ScriptExchange'
net use * "\\$computername\$shareName"
```

<!--本文国际来源：[Creating SMB Shares Remotely](http://community.idera.com/powershell/powertips/b/tips/posts/creating-smb-shares-remotely)-->
