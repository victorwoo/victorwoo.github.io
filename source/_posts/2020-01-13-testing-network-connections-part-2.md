---
layout: post
date: 2020-01-13 00:00:00
title: "PowerShell 技能连载 - 测试网络连接（第 2 部分）"
description: PowerTip of the Day - Testing Network Connections (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
If you’d like to test whether a specific computer or URL is online, for decades ping requests (ICMP) have been used. In recent times, many servers and firewalls turn off ICMP to reduce attack surfaces. Test-NetConnection by default uses ICMP, so it fails on computers that do not respond to ICMP:
如果您想测试一台特定的计算机或 URL 是否在线，几十年来一直使用 ping 请求 (ICMP)。最近，许多服务器和防火墙关闭了 ICMP 以减少攻击面。默认情况下，`Test-NetConnection` 使用 ICMP，因此在不响应 ICMP 的计算机上会失败：

```powershell
PS> Test-NetConnection -ComputerName microsoft.com
WARNING: Ping to 40.76.4.15 failed with status: TimedOut
WARNING: Ping to 40.112.72.205 failed with status: TimedOut
WARNING: Ping to 13.77.161.179 failed with status: TimedOut
WARNING: Ping to 40.113.200.201 failed with status: TimedOut
WARNING: Ping to 104.215.148.63 failed with status: TimedOut


ComputerName           : microsoft.com
RemoteAddress          : 40.76.4.15
InterfaceAlias         : Ethernet 4
SourceAddress          : 192.168.2.108
PingSucceeded          : False
PingReplyDetails (RTT) : 0 ms
```

`Test-NetConnection` 内置了另一种计算机无法回避的测试：端口测试。端口提供对特定服务的访问，因此端口必须在任何公共服务可用。对于 Web 服务器，可以使用 80 端口，例如：

```powershell
PS> Test-NetConnection -ComputerName microsoft.com -Port 80


ComputerName     : microsoft.com
RemoteAddress    : 104.215.148.63
RemotePort       : 80
InterfaceAlias   : Ethernet 4
SourceAddress    : 192.168.2.108
TcpTestSucceeded : True
```

以下是常用的端口列表：

    HTTP: Port 80
    HTTPS: Port 443
    FTP: Port 21
    FTPS/SSH: Port 22
    TELNET: Port 23
    POP3: Port 110
    POP3 SSL: Port 995
    IMAP: Port 143
    IMAP SSL: Port 993
    WMI: Port 135
    RDP: Port 3389
    DNS: Port 53
    DHCP: Port 67, 68
    SMB/NetBIOS: 139
    NetBIOS over TCP: 445
    PowerShell Remoting: 5985
    PowerShell Remoting HTTPS: 5986

<!--本文国际来源：[Testing Network Connections (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/testing-network-connections-part-2)-->

