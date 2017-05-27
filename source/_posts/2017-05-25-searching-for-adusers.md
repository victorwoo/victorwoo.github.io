layout: post
date: 2017-05-25 00:00:00
title: "PowerShell 技能连载 - 搜索 AD 用户"
description: PowerTip of the Day - Searching for ADUsers
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
免费的 Microsoft RSAT 工具给我们带来了 "ActiveDirectory" PowerShell module：许多 cmdlet 可以帮助您管理 Active Directory 用户和计算机。

一个 cmdlet 特别有用。与其使用 `Get-ADUser` 和复杂得过滤器来查找 AD 用户，我们可以使用更方便的 `Search-ADAccount`。它注重于某些公共场景的查找用户功能。例如这行代码可以找出所有 120 天未活跃的用户账户：

```powershell
Search-ADAccount -AccountInactive -TimeSpan 120 -UsersOnly
```

<!--more-->
本文国际来源：[Searching for ADUsers](http://community.idera.com/powershell/powertips/b/tips/posts/searching-for-adusers)
