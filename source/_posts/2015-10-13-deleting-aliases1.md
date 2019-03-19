---
layout: post
date: 2015-10-13 11:00:00
title: "PowerShell 技能连载 - 删除别名"
description: PowerTip of the Day - Deleting Aliases
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中创建新的别名很常见。但是如果您做错了什么，要怎么办？

    PS C:\> Set-Alias -Name ping -Value notepad

    PS C:\> ping 127.0.0.1

当创建了一个别名之后，并没有 cmdlet 可以移除它。您必须得关闭 PowerShell 并打开一个新的 PowerShell 会话来“忘记”掉自定义的别名。

或者，您可以利用 `alias:` 虚拟驱动器，并且像移除文件一样移除别名：

    PS C:\> del alias:ping

    PS C:\> ping 127.0.0.1

    Pinging 127.0.0.1 with 32 bytes of data:
    Reply from 127.0.0.1: bytes=32 time<1ms TTL=128
    Reply from 127.0.0.1: bytes=32 time<1ms TTL=128
    Reply from 127.0.0.1: bytes=32 time<1ms TTL=128
    Reply from 127.0.0.1: bytes=32 time<1ms TTL=128

    Ping statistics for 127.0.0.1:
        Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),
    Approximate round trip times in milli-seconds:
        Minimum = 0ms, Maximum = 0ms, Average = 0ms

    PS C:\>

<!--本文国际来源：[Deleting Aliases](http://community.idera.com/powershell/powertips/b/tips/posts/deleting-aliases1)-->
