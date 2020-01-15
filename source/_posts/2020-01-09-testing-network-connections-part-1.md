---
layout: post
date: 2020-01-09 00:00:00
title: "PowerShell 技能连载 - 测试网络连接（第 1 部分）"
description: PowerTip of the Day - Testing Network Connections (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 随附了 `Test-NetConnection` 命令，它可以像复杂的 ping 工具一样工作。默认情况下，您可以这样 ping 计算机：

```powershell
PS> Test-NetConnection -ComputerName powershell.one


ComputerName           : powershell.one
RemoteAddress          : 104.18.46.88
InterfaceAlias         : Ethernet 4
SourceAddress          : 192.168.2.108
PingSucceeded          : True
PingReplyDetails (RTT) : 26 ms
```

使用 `-TraceRoute`，它包括路由跟踪，列出了用于传播到目标的所有网络节点：

```powershell
PS> Test-NetConnection -ComputerName powershell.one -TraceRoute


ComputerName           : powershell.one
RemoteAddress          : 104.18.46.88
InterfaceAlias         : Ethernet 4
SourceAddress          : 192.168.2.108
PingSucceeded          : True
PingReplyDetails (RTT) : 25 ms
TraceRoute             : 192.168.2.1
                            62.155.243.83
                            62.154.2.185
                            62.157.250.38
                            195.22.215.192
                            195.22.215.59
                            104.18.46.88
```

<!--本文国际来源：[Testing Network Connections (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/testing-network-connections-part-1)-->
