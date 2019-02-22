---
layout: post
title: "PowerShell 技能连载 - 启用 PowerShell 远程管理"
date: 2014-04-01 00:00:00
description: PowerTip of the Day - Enabling PowerShell Remoting
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您希望用 PowerShell 远程管理来执行另一台机器上的命令或脚本，那么您需要以完整管理员权限启用目标机器上的远程管理功能：

![](/img/2014-04-01-enabling-powershell-remoting-001.png)

在客户端，当您在同一个域中并且使用同一个域用户登录时，您不需要做任何额外的事情。

如果您希望通过非 Kerberos 验证方式连接目标计算机时（目标计算机在另一个域中，或您希望使用 IP 地址或非完整限定 DNS 名来连接），那么您需要以管理员权限运行一次以下代码：

![](/img/2014-04-01-enabling-powershell-remoting-002.png)

将信任的主机设置为“\*”之后，PowerShell 将允许您连接任何 IP 或机器名，如果无法用 Kerberos 验证身份，将使用 NTLM 验证。所以该设置不影响哪些人可以和该主机通信（通过防火墙规则设置）。它只是告诉 PowerShell 您将在 Kerberos 不可用的时候使用（更不安全一些的）NTLM 验证方式。NTLM 更不安全一些，因为它无法知道目标计算机是否真的是您想要访问的计算机。Kerberos 认证有相互认证过程，而 NTLM 没有。您的凭据直接被发送到指定的计算机中。假如当一个攻击者有机会用他的机器替换掉目标机器，并且占据了它的 IP 地址，而您使用 NTLM 的话，不会得到任何通知。

注意：如果你打开了远程并设置了信任列表后想关闭远程请运行 `Disable-PSRemoting`，不禁用远程将可能被人利用。

当远程管理打开以后，您可以通过 `Enter-PSSession` 访问远程系统，并且您可以用 `Invoke-Command` 在这些机器上运行命令或脚本。

<!--本文国际来源：[Enabling PowerShell Remoting](http://community.idera.com/powershell/powertips/b/tips/posts/enabling-powershell-remoting)-->
