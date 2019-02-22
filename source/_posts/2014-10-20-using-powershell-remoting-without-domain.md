---
layout: post
date: 2014-10-20 11:00:00
title: "PowerShell 技能连载 - 在非域环境中使用 PowerShell 远程操作"
description: PowerTip of the Day - Using PowerShell Remoting without Domain
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 3.0 及以上版本_

缺省情况下，当您通过 `Enable-PSRemoting` 来启用 PowerShell 远程操作时，只启用了 Kerberos 身份验证。这要求双方主机处于同一个域（或信任的域）中，并且仅能通过计算机名访问（很可能包括域名前缀）。它无法跨域、通过域之外的机器，或通过 IP 地址来访问。

要达到上述目的，您需要在启用远程操作的机器上做一些调整。在初始化连接的机器上以管理员权限运行 PowerShell 控制台，键入以下代码：

    PS> Set-Item WSMan:\localhost\Client\TrustedHosts -Value * -Force 

如果该路径不可用，您可能需要在该机器上（临时地）启用 PowerShell 远程操作（用 `Enable-PSRemoting –SkipNetworkProfileCheck –Force`）。

当您做了上述改动以后，就可以支持 NTLM 验证了。只需要记住从现在开始，要访问加入域的计算机，您需要通过 `-Credential` 参数提交用户名和密码。

<!--本文国际来源：[Using PowerShell Remoting without Domain](http://community.idera.com/powershell/powertips/b/tips/posts/using-powershell-remoting-without-domain)-->
