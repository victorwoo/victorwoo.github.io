---
layout: post
date: 2018-04-11 00:00:00
title: "PowerShell 技能连载 - 清除当前用户的 Kerberos 票证"
description: PowerTip of the Day - Purging Kerberos Tickets for the Current User
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
如果要应用更新的权限设置，并不需要重启系统。而只需要清除 Kerberos 票证就可以基于当前的权限获取一个新的票证。

In PowerShell, use this command to purge all cached Kerberos tickets:
在 PowerShell 中，只需要用这条命令就可以清除所有缓存的 Kerberos：

```powershell
PS> klist purge

Current LogonId is 0:0x2af9a
    Deleting all tickets:
    Ticket(s) purged!

PS>
```

<!--more-->
本文国际来源：[Purging Kerberos Tickets for the Current User](http://community.idera.com/powershell/powertips/b/tips/posts/purging-kerberos-tickets-for-the-current-user)
