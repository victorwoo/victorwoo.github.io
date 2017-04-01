layout: post
date: 2016-10-14 00:00:00
title: "PowerShell 技能连载 - Getting List of Current Group Memberships"
description: PowerTip of the Day - Getting List of Current Group Memberships
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
当您可以通过 Active Directory 来获取一个用户的组成员，有一个简单的方法是直接通过用户的 access token 获取信息，而不需要 AD 联系人。

这行代码将取出当前用户所在的所有组的 SID：

```powershell
#requires -Version 3.0
    [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups.Value
```

这是获取翻译后的组名的方法：

```powershell
#requires -Version 3.0
    [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups.Translate( [System.Security.Principal.NTAccount])
```

如果这个列表中有重复，那么您就可以知道有多个 SID 指向同一个名字。这种情况在您曾经迁移过 AD（SID 历史）时可能会发生。只需要将结果用管道输出到 `Sort-Object -Unique` 就能移除重复。

<!--more-->
本文国际来源：[Getting List of Current Group Memberships](http://community.idera.com/powershell/powertips/b/tips/posts/getting-list-of-current-group-memberships)
