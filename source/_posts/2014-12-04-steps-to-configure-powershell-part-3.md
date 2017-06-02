---
layout: post
date: 2014-12-04 12:00:00
title: "PowerShell 技能连载 - PowerShell 技能连载 - 配置 PowerShell 的步骤（第 3 部分）"
description: PowerTip of the Day - Steps to Configure PowerShell (Part 3)
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
_适用于 PowerShell 所有版本_

如果您在家中或其它不重要的场合使用 PowerShell，那么可以通过以下步骤使 PowerShell 发挥最大功能。

要在您自己的的机器上启用 PowerShell 远程操作，您需要在您的机器上启用 PowerShell 远程操作功能。实现的方式是用管理员权限启动 PowerShell，然后运行该命令：

```
PS> Enable-PSRemoting -SkipNetworkProfileCheck -Force
```

请注意 `-SkipNetworkProfileCheck` 是 PowerShell 3.0 引入的概念。如果您仍在 使用 PowerShell 2.0，请忽略这个参数。如果 PowerShell 提示公用网络连接可用，您需要手动临时禁用公用网络连接。

该命令在您的机器上启用 PowerShell 远程操作。其他人现在可以连接到您的计算机，如果他是您计算机上的 Administrators 组成员。

然而，您只能用 Kerberos 身份验证方式来连接到别的计算机。所以此时，远程操作只适用于域环境。如果您在一个简单的点对点网络环境中或是想跨域使用远程操作功能，那么需要启用 NTLM 验证。请注意：只需要在客户端设置。不是在您想连接的目标机器上设，而是在您发起远程操作的机器上设：

```
PS> Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value * -Force
```

使用“`*`”允许您通过 NTLM 验证方式连接到任何目标机器。由于 NTLM 是一种非双向认证方式，所以当您使用该方式连接到一台不受信任或可能已被入侵的机器时，会增加安全风险。所以最好不要用“`*`”，而是指定 IP 地址或 IP 地址段，例如“10.10.*”。

当设置好 PowerShell 远程操作之后，您可以开始使用。

这行代码将会在 ABC 机器上运行任意的 PowerShell 代码（需要您事先在 ABC 机器上启用远程操作功能，并且拥有 ABC 机器上的管理员权限）：

```
PS> Invoke-Command -ScriptBlock { "Hello" > c:\IwasHERE.txt } -ComputerName ABC
```

这段代码将实现同样的效果，但这里您需要显式地制定凭据。当您指定了一个账户，请确定指定了域名和用户名。如果它不是一个域账户，请指定机器名和用户名：

```
Invoke-Command -ScriptBlock { "Hello" > c:\IwasHERE.txt } -ComputerName ABC -Credential ABC\localAdminAccount
```

请注意：当您想用非 Kerberos 验证的时候，加入域的计算机需要使用 `-Credential` 参数。

<!--more-->
本文国际来源：[Steps to Configure PowerShell (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/steps-to-configure-powershell-part-3)
