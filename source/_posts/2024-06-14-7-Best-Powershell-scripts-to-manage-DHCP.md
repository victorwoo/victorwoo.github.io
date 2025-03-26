---
layout: post
date: 2024-06-14 00:00:00
title: "PowerShell 技能连载 - 7 个用于管理 DHCP 的最佳 PowerShell 脚本"
description: "7 Best Powershell scripts to manage DHCP"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
从DHCP范围获取IP看起来很容易，但当涉及检查每个范围的健康状况时，情况就变得非常困难了，无论是满还是是否需要创建任何超范围。如果您是服务器管理员，您真的知道我在说什么，当客户抱怨他们没有获得任何IP地址时确实很痛苦，并且你会发现在你的范围中一切都是空白。

使DHCP服务器或范围动态更新多个DHCP服务器上的DNS并不容易，并且知道它所处域中确切位置的范围更加艰难。通过Powershellguru，我的目标始终是为我在生产环境中通常遇到的问题提供简单解决方案。以下是一些关于DHCP及其工作原理以及Powershell相关书籍可以参考。希望您喜欢，并且大多数免费软件总是驻留在维基百科和微软网站上。

### DHCP有用的Powershell命令

为DHCP服务器服务添加一个对象

```powershell
Add-DhcpServerInDC -DnsName "dhcp.xyz.com"
```

备份 DHCP 数据库

```powershell
Backup-DhcpServer -ComputerName "dhcp.xyz.com" -Path "%systemroot\dhcp\backup"
```

导出所有 DHCP 设置

```powershell
Export-DhcpServer -ComputerName "dhcp.xyz.com" -File "path\config.xml"
```

获取范围内的所有活动租约

```powershell
Get-DhcpServerv4Lease -ComputerName "dhcp.xyz.com" -ScopeId IP
```

按名称获取策略的属性

```powershell
Get-DhcpServerv4Policy -ComputerName "dhcp.xyz.com" -Name "policyname"
```

## DHCP故障转移

通常创建一个故障转移是更好的选择。所有请求不会只发送到一个特定的DHCP服务器，而是由2台服务器共同管理。

### 工作原理

此脚本将在两个DHCP服务器之间创建故障转移，我们需要指定范围。稍后，脚本将在这两个DHCP服务器之间创建故障转移。

### 可能的结果

运行脚本后，请检查故障转移是否正常工作。请求应该同时发送到两台服务器上。

### 下载

您可以从以下链接下载脚本。

[DHCP Failover](https://powershellguru.com/wp-content/uploads/2021/03/DHCP_Failover.txt)

## DHCP备份

在您的环境中未配置故障转移时，备份DHCP是一个福音。您可以将备份恢复到上次备份的时间点，一切都会重新在线。

### 工作原理

路径已经设置好了，我们需要在dhcp服务器上运行脚本，这样就会创建一个dhcp的备份。

### 问题结果

该脚本减少了我们通过GUI手动操作的工作量，并在提供的位置创建了备份。

### 下载

您可以从下面下载脚本。

[备份 DHCP 服务器](https://powershellguru.com/wp-content/uploads/2021/03/Backup-DHCP-Server.txt)

## DNS 动态更新

IP地址动态分配是DHCP的角色之一，并不会自动启用，需要通过GUI手动完成。但为什么要匆忙去使用GUI呢？当你可以通过Powershell来做时。

### 工作原理

此脚本将根据需求为范围或所有范围启用DNS动态更新设置。

### 可能结果

动态更新将被启用，并且对于启用DHCP的机器主机解析将得到纠正。

### 下载

您可以通过突出显示的链接下载该脚本。

[配置 DNS 动态更新](https://powershellguru.com/wp-content/uploads/2021/03/Configure-DNS-Dynamic-Update.txt)

## 配置租约持续时间

按照微软公司规定，租约持续时间始终设定为8天。但实际情况下我们可能会针对范围进行更改，那么为什么要使用GUI进行操作呢？当我们可以编写一个脚本时。

### 工作原理

对于提供的范围，您可以使用此脚本设置租约持续时间。

### 可能的结果

将设置租约持续时间，如果需要，我们可以在任何计算机上进行测试，否则它将按预期工作。

### 下载

您可以通过突出显示的链接下载该脚本。

[配置DHCP租约持续时间](https://powershellguru.com/wp-content/uploads/2021/03/Configuring-DHCP-Lease-Duration.txt)

## DHCP健康检查

这是最实用的脚本之一，让我们了解范围、子网、是否禁用某个范围等。所有必备且可下载的独特脚本。

### 工作原理

脚本将扫描给定服务器的范围，并通过邮件发送结果。

### 可能的结果

我们将收到关于范围详情的信息，这对于了解其中任何一个即将填满的情况很重要。

### 下载

您可以通过突出显示的链接下载脚本。

[DHCP健康检查](https://e37eec5f-8071-43d6-a9d1-0b9ae629dd33.usrfiles.com/ugd/e37eec_ebf8bf501ac54693b254a5d0c4b82612.txt)

## 创建多个DHCP范围

如果需要创建多个DHCP范围，那么这个脚本就是为您量身定制的，请根据您的需求进行检查。

### 工作原理

它需要输入并且我们需要提供注释，以便快速创建范围。

### 可能的结果

所有提供的输入都将用于创建多个DHCP范围，这是一种非常方便实用的脚本。

### 下载

您可以通过突出显示的链接下载该脚本。

[create scope](https://powershellguru.com/wp-content/uploads/2021/03/create-scope.txt)

## 从多个范围获取路由器详细信息

曾经想过从多个范围中获取路由器IP详细信息吗？好吧，Powershell已经为我们创造了一个拯救生命般存在着这样一个脚本来完成此任务。

### 工作原理

使用 [Get-DhcpServerv4Scope](https://docs.microsoft.com/en-us/powershell/module/dhcpserver/get-dhcpserverv4scope?view=win10-ps) 在文本格式中提供范围ID详情，并且它会从给定范围中获取路由器IP地址。

### 可能结果

结果将以csv格式呈现，在其中包含有关路由器IP详细信息和其所属ID。

### 下载

您可以通过以下链接下载该脚本。

[router](https://powershellguru.com/wp-content/uploads/2021/03/router.txt)

<!--本文国际来源：[7 Best Powershell scripts to manage DHCP](https://powershellguru.com/dhcp-powershell-scripts/)-->
