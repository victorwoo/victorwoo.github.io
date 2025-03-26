---
layout: post
date: 2024-06-07 00:00:00
title: "PowerShell 技能连载 - 管理 DNS 的 8 个最佳 Powershell 脚本"
description: "8 Best Powershell scripts to manage DNS"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Active Directory 的另一个主要部分是 DNS。如果您是 Windows 服务器管理员，那么您很清楚它的工作原理，但在没有知道命令实际操作的情况下，使用 Powershell 进行管理和自动化有时会变得困难。

DNS 在组织中扮演着至关重要的角色，因此需要一些窥视来确保其正常运行。在我们领域中，通过 GUI 为服务器或工作站创建 DNS 记录似乎很容易，但当需要同时创建多个 DNS 记录时就会变得困难起来。从创建记录到将其指向正确的 IP 地址都具有挑战性。但我已经接受了这一挑战，并编写了一些相关脚本，并对其进行了优化以便无需任何混乱即可运行。如果您喜欢这部分内容，则肯定也会喜欢 DHCP powershell 脚本以及我的 powershell 脚本库。

好的开始意味着良好的结束，在下面是一些例子。从恢复 DNS 服务器到在 DNS 中创建区域，我都做到了。以下是一些书籍供您参考，如果您打算学习关于 DNS 或 powershell 的知识，请查阅以下最佳可用 DNS Powershell 脚本列表。

### 对于DNS有用的Powershell命令

添加DNS转发器

```powershell
Add-DnsServerForwarder -IPAddress IP -PassThru
```

添加根提示服务器

```powershell
Add-DnsServerRootHint -NameServer "domain.com" -IPAddress IP
```

获取DNS服务器配置

```powershell
Get-DnsServer -ComputerName "IP"
```

获取DNS服务器转发器设置

```powershell
Get-DnsServerForwarder
```

从DNS服务器中删除转发器

```powershell
Remove-DnsServerForwarder -IPAddress IP -PassThru
```

设置DNS服务器配置

```powershell
Get-DnsServer -CimSession IP | Set-DnsServer
```

清除 DNS 缓存

```powershell
Clear-DnsServerCache -ComputerName "Name of server" -Force
```

## 恢复 DNS 区域

在 Powershell 中使用简单命令创建区域更加容易，无需转到 dnsmgmt.msc 创建新的所需区域。

### 工作原理

脚本将在备份文件夹中搜索备份，并搜索可以恢复的指定区域。

### 可能结果

如果您提供了所有正确信息，则 DNS 区域应该会通过最新备份恢复。

### 下载

您可以从以下链接下载脚本：

[恢复 DNS 区域](https://powershellguru.com/wp-content/uploads/2021/03/Restore-DNS-Zone.txt)

## 创建主/辅助/存根区域

错误地删除了 DNS 区域？别担心，只要有 dns 区域的备份。这是一个非常方便的脚本来恢复 DNS 区域。

### 工作原理

只需提供将在所需服务器上创建辅助区域的区 IP 地址即可。

### 问题结果

主 / 辅助 / 存根区将在所需服务器上创建。

### 下载

您可以从以下链接下载脚本：

* [主要区](https://powershellguru.com/wp-content/uploads/2021/03/Primary-Zone.txt)
* [次要区](https://powershellguru.com/wp-content/uploads/2021/03/Secondary-Zone.txt)
* [存根区](https://powershellguru.com/wp-content/uploads/2021/03/stub-zone.txt)

## 创建DNS转发器

在PowerShell中创建DNS转发器非常快速和简单。只需一行代码就可以摆脱繁琐的点击。

### 工作原理

提供批量或单个IP地址，并运行脚本，应该会创建DNS转发器，但请确保提供正确的IP地址。

### 可能的结果

该脚本将创建DNS转发器，应该可以ping通，并且请求应被重定向到转发器。

### 下载

您可以从以下链接下载脚本。

[DNS 转发器](https://powershellguru.com/wp-content/uploads/2021/03/DNS-Forwarders.txt)

## 修改DNS记录

在PowerShell中创建DNS转发器非常快速和简单。只需一行代码就可以摆脱繁琐的点击。

### 工作原理

提供批量或单个IP地址，并运行脚本，应该会创建DNS转发器，但请确保提供正确的IP地址。

### 可能的结果

该脚本将创建DNS转发器，应该可以ping通，并且请求应被重定向到转发器。

### 下载

您可以从以下链接下载脚本。

[修改主机记录 - 内部](https://powershellguru.com/wp-content/uploads/2021/03/Modify-Host-Record-Internal.txt)

## 创建多个 DNS 记录

是否曾经面对过搜索要更改 IP 的 DNS 记录挑战？PowerShell已经使这变得如此简便可靠。这个脚本是一个很好的例子。

### 工作原理

它将把主机名（hostname）的 IP 更改为所需 IP 地址。只需提供正确详细信息并查看其工作方式。

### 可能结果

如果一切顺利，则主机名 IP 应更换为新提供的 IP 地址。

### 下载

您可以从以下链接下载此脚本。

[create-dns-record](https://powershellguru.com/wp-content/uploads/2021/03/create-dns-record.txt)

## 检查多台主机 FQDN

假设有这样一种情况：你被要求在环境中提供多台主机 FQDN ，但你不知道其中有多少是工作组服务器“麻烦”，我专门为这种时刻编写了一个脚本, 以便不必逐个通过 nslookup 进行检查而实际上我们也能够为同样目标编写一个相同功能性质 的 脚步 。FQDN 看起来像 hostname.xyz.com 。

### 工作原理

它将使用 nslookup 并在短时间内提供多台服务器 FQDN 。

### 可能结果

如果它存在于您环境中，则会获取到 主机 FQDN ，如果不存在，则需要检查是否是工作组服务器或者列表中是否存在拼写错误。如果遇到任何问题，请随时联系我；如果需要视频演示，请告诉我. 您直接通过 Facebook 或 Gmail 联系我，在页尾都有我的邮箱.

### 下载

您可从下方链接下载此文件.

[nslookup](https://powershellguru.com/wp-content/uploads/2021/03/nslookup-1.txt)

<!--本文国际来源：[8 Best Powershell scripts to manage DNS](https://powershellguru.com/dns-powershell-scripts/)-->
