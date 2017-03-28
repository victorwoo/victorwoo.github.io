layout: post
date: 2014-12-03 12:00:00
title: "PowerShell 技能连载 - 配置 PowerShell 的步骤（第 2 部分）"
description: PowerTip of the Day - Steps to Configure PowerShell (Part 2)
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
_适用于 PowerShell 2.0 及以上版本_

如果您在家中或其它不重要的场合使用 PowerShell，那么可以通过以下步骤使 PowerShell 发挥最大功能。

要允许系统管理员远程连接到您的机器并运行 `Get-Process` 或 `Get-Service` 等 cmdlets，您也许需要启用远程管理的防火墙例外规则。请以管理员身份打开 PowerShell 并运行这段代码：

```
PS> netsh firewall set service remoteadmin enable

IMPORTANT: Command executed successfully.
However, "netsh firewall" is deprecated;
use "netsh advfirewall firewall" instead.
For more information on using "netsh advfirewall firewall" commands
instead of "netsh firewall", see KB article 947709
at http://go.microsoft.com/fwlink/?linkid=121488 .

Ok.
```

该命令返回的信息告诉我们该命令已过时，有一个更新的命令替代了它，但它任然可用并启用了防火墙例外。新的命令更难使用，因为它的参数是本地化的，并且您需要知道防火墙例外的确切名称。

要真正地用上 cmdlet 的远程功能，您还需要启用 `RemoteRegistry` 服务并将它设为自动启动：

```
PS> Start-Service RemoteRegistry

PS> Set-Service -Name Remoteregistry -StartupType Automatic
```

您现在可以使用 `Get-Process`、`Get-Service` 或其它暴露了 `-ComputerName` 参数的 cmdlet 来远程连接到您的计算机，假设运行这些 cmdlet 的用户拥有您系统上的管理员权限。

在简单的点对点家庭环境中，为每台计算机的 Administrator 账号设置相同的名字就足够了。

<!--more-->
本文国际来源：[Steps to Configure PowerShell (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/steps-to-configure-powershell-part-2)
