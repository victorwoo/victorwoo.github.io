---
layout: post
date: 2021-05-11 00:00:00
title: "PowerShell 技能连载 - 更好的 PowerShell 帮助（第 1 部分）"
description: PowerTip of the Day - Better PowerShell Help (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
许多 cmdlet 提供了丰富的联机帮助，您可以使用 `Get-Help` 并加上 `-Online` 参数来自动打开 cmdlet 的网页：

```powershell
PS> Get-Help -Name Get-Service -Online
```

每个 cmdlet 还支持公用参数 `-?`。不过，它仅显示了有限的内置本地帮助：

```powershell
PS> Get-Service -?

NAME
    Get-Service

SYNTAX
    Get-Service [-ComputerName <System.String[]>] [-DependentServices] -DisplayName <System.String[]> [-Exclude
    <System.String[]>] [-Include <System.String[]>] [-RequiredServices] []
...
```

但是，您可以通过一个简单的技巧告诉 PowerShell 也对内置参数 `-?` 使用丰富的联机帮助。请运行这段代码：

```powershell
PS> $PSDefaultParameterValues['Get-Help:Online'] = $true
```

此命令自动为 `Get-Help -Online` 参数设置一个新的默认值，并且因为 `-?` 内部使用 `Get-Help`，您现在只需添加 `-?` 到命令名称就可以获得大多数 PowerShell cmdlet 的丰富在线帮助。

```powershell
PS> Get-Service -?
```

真是太棒了，因此您可能需要将该命令添加到自动启动配置文件脚本中。该脚本的路径可以在 `$profile.CurrentUserAllHosts` 中找到。它可能尚不存在，所以您可能必须创建它。

但是，有一个警告：如果命令没有在线帮助，那么您现在会收到一条错误消息，提示没有在线帮助。在即将发布的技能中，我们将单独解决此问题。

<!--本文国际来源：[Better PowerShell Help (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/better-powershell-help-part-1)-->
