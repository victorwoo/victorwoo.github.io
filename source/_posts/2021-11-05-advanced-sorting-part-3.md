---
layout: post
date: 2021-11-05 00:00:00
title: "PowerShell 技能连载 - 高级排序（第 3 部分）"
description: PowerTip of the Day - Advanced Sorting (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个提示中，您已经看到 `Sort-Object` 如何接受哈希表作为参数，对排序进行高级控制。 例如，此行代码按状态排序，然后显示名称，并为每个属性使用单独的排序方向：

```powershell
Get-Service |
Sort-Object -Property @{Expression='Status'; Descending=$true}, @{Expression='DisplayName'; Descending=$false } |
Select-Object -Property DisplayName, Status
```

但是，当您查看结果时，"Status" 属性的排序方向似乎是错的。我们已经澄清了这一点，因为 "Status" 实质上是一个数字常量，而 `Sort-Object` 排序的底层逻辑是对原始数据进行排序。所以它是根据内部的数值型常量对 "Status" 进行排序，而不是根据可见的友好名称。

要确保 `Sort-Object` 是按照用户“看见”对象的内容对它们排序，请使用哈希表的另一个功能："Expression" 键不仅能接受属性的名称，而且用支持脚本块（代码）转换为任何数据，再对该数据排序。在脚本块内，`$_` 表示完整的传入对象。

要确保 "Status" 根据文本来排序而不是根据背后的数值来排序，请将其转换为字符串，如下所示：

```powershell
Get-Service |
Sort-Object -Property @{Expression={[string]$_.Status}; Descending=$true}, @{Expression='DisplayName'; Descending=$false } |
Select-Object -Property DisplayName, Status
```

事实上，在排序之前改变数据的能力，能改变所有排序的游戏规则。

假设您有一个 HTTPS 连接列表，用于保存浏览器连接到的远程 IP 地址，并且您正在尝试通过 `Sort-Object` 来对这些 IP 地址进行排序：

```powershell
PS C:\> Get-NetTCPConnection -RemotePort 443 | Select-Object -Property RemoteAddress, RemotePort, State, OwningProcess | Sort-Object -Property RemoteAddress

RemoteAddress  RemotePort       State OwningProcess
-------------  ----------       ----- -------------
142.250.185.74        443    TimeWait             0
142.250.186.46        443    TimeWait             0
20.199.120.182        443 Established          3552
20.199.120.182        443 Established          5564
20.42.65.89           443 Established          9836
20.42.65.89           443    TimeWait             0
20.42.73.24           443    TimeWait             0
35.186.224.25         443    TimeWait             0
45.60.13.212          443 Established          7644
51.104.30.131         443 Established         10220
```

如果您将仔细查看结果，您将看到 "RemoteAddress" 未正确排序：例如 "20.199.120.182" 列在了 "20.42.65.89" 的前面。

这是因为这些 IPv4 地址被视为字符串，因此 `Sort-Object` 使用默认的字母数字排序算法。

您现在知道如何以更合适的数据类型转换数据。例如，IPv4 地址可以被视为软件版本（数据类型\[版本\]）正确排序：

```powershell
PS> Get-NetTCPConnection -RemotePort 443 | Select-Object -Property RemoteAddress, RemotePort, State, OwningProcess | Sort-Object -Property @{Expression={ $_.RemoteAddress -as [version] }}

RemoteAddress  RemotePort       State OwningProcess
-------------  ----------       ----- -------------
20.42.65.89           443 Established          9836
20.42.65.89           443    TimeWait             0
20.199.120.182        443 Established          3552
20.199.120.182        443 Established          5564
35.186.224.25         443    TimeWait             0
45.60.13.212          443 Established          7644
51.104.30.131         443 Established         10220
142.250.185.74        443    TimeWait             0
142.250.186.46        443    TimeWait             0
```

现在 IP 地址已可以正确排序。

注意：当将数据转换为其他数据类型（如此处所示）时，始终优先使用 `-as` 运算符进行直接类型转换。如果数据不能转换为所需的数据类型，则 `-as` 运算符只会返回 `$null`，而直接类型转换将会产生异常。

在前面的例子中，如果 "RemoteAddress" 会显示一个 IPv6 地址（不能转换为 \[version\]），幸亏 `-as` 操作符，这些项目不会被排序，而会放在排序数据的开头.

要缩短代码，您可以简写哈希表的键（只要它们保持唯一）：

```powershell
Get-NetTCPConnection -RemotePort 443 |
Select-Object -Property RemoteAddress, RemotePort, State, OwningProcess |
Sort-Object -Property @{E={ $_.RemoteAddress -as [version] }}
```

如果您需要的只是数据转换，则可以完全跳过哈希表并将脚本块直接传给 `-Property` 参数：

```powershell
PS> Get-NetTCPConnection -RemotePort 443 | Select-Object -Property RemoteAddress, RemotePort, State, OwningProcess | Sort-Object -Property { $_.RemoteAddress -as [version] }

RemoteAddress  RemotePort       State OwningProcess
-------------  ----------       ----- -------------
20.42.65.89           443 Established          9836
20.42.65.89           443    TimeWait             0
20.199.120.182        443 Established          3552
20.199.120.182        443 Established          5564
35.186.224.25         443    TimeWait             0
45.60.13.212          443 Established          7644
51.104.30.131         443 Established         10220
142.250.185.74        443    TimeWait             0
142.250.186.46        443    TimeWait             0
```

<!--本文国际来源：[Advanced Sorting (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/advanced-sorting-part-3)-->

