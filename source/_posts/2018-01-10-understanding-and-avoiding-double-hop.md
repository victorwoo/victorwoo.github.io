---
layout: post
date: 2018-01-10 00:00:00
title: "PowerShell 技能连载 - 理解和避免双跃点问题"
description: PowerTip of the Day - Understanding and Avoiding Double-Hop
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
当一个脚本在远程执行时，您可能会遇到“拒绝访问”的问题，这通常和双跃点 (double-hop) 问题有关。以下是一个例子，并且我们将演示如何解决它：

```powershell
$target = 'serverA'

$code = {
    # access data from another server with transparent authentication
    Get-WmiObject -Class Win32_BIOS -ComputerName serverB
}

Invoke-Command -ScriptBlock $code -ComputerName $target
```

以上脚本在 ServerA 服务器上执行 PowerShell 代码。远程执行的代码试图连接 ServerB 来获取 BIOS 信息。请不要介意这是否有现实意义，有关系的是远程执行的代码无法透明地登录 ServerB，即便执行这段代码的用户可以直接访问 ServerB。

双跃点问题发生在您的认证信息没有从一个远程计算机传递给另一台远程计算机时。对于任何非域控制计算机，双跃点缺省都是禁止的。

如果您想使用上述代码，您需要使用 CredSSP 来验证（远程桌面也使用了这项技术）。这需要一次性设置您和您直接访问的计算机（在这个例子中是 ServerA）之间的信任关系：

```powershell
#requires -RunAsAdministrator

$TargetServer = 'ServerA'

# configure the computer you directly connect to
Invoke-Command -ScriptBlock { 
    Enable-WSManCredSSP -Role Server -Force | Out-String
    } -ComputerName $TargetServer 
    
# establish CredSSP trust
Enable-WSManCredSSP -Role Client -DelegateComputer $TargetServer -Force
```

当这个信任存在时，您可以使用 CredSSP 规避双跃点问题。以下是如何在 CredSSP 启用的情况下如何远程运行代码的方法：

```powershell
Invoke-Command -ScriptBlock $code -ComputerName $target 
-Authentication Credssp -Credential mydomain\myUser
```

当您使用 CredSSP 时，您不再能使用透明的登录。取而代之的是，您必须使用 `-Credential` 来指定用户账户。

<!--more-->
本文国际来源：[Understanding and Avoiding Double-Hop](http://community.idera.com/powershell/powertips/b/tips/posts/understanding-and-avoiding-double-hop)
