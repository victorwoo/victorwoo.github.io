layout: post
date: 2016-10-19 16:00:00
title: "PowerShell 技能连载 - 在单侧启用 CredSSP"
description: PowerTip of the Day - Enabling CredSSP Trust from One Side
categories:
- powershell
- tip
- tags:
- powershell
- tip
- powertip
- series
- translation
---
如之前所示，CredSSP 可以用在远程代码上，避免二次连接问题。不过，要使用 CredSSP 验证方式您得在客户端和服务端分别设置，才能使它们彼此信任。

这并不意味着您必须物理接触那台服务器。如果您想在您的计算机和任何一台服务器（假设那台服务器上启用了 PowerShell 远程连接）建立一个 CredSSP 信任关系，只需要做这些：

```powershell
#requires -Version 2.0 -RunAsAdministrator  

# this is the server you want to communicate with using CredSSP
# the server needs to have PowerShell remoting enabled already
$Server = 'NameOfServer'

Enable-WSManCredSSP -Role Client -DelegateComputer $Server -Force
Invoke-Command { Enable-WSManCredSSP -Role Server } -ComputerName $Server
```

如您所见，`Enable-WSManCredSSP` 可以远程执行。

<!--more-->
本文国际来源：[Enabling CredSSP Trust from One Side](http://community.idera.com/powershell/powertips/b/tips/posts/enabling-credssp-trust-from-one-side)
