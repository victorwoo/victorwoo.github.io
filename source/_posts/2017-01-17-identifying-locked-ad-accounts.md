---
layout: post
date: 2017-01-17 00:00:00
title: "PowerShell 技能连载 - 定位锁定的 AD 账户"
description: PowerTip of the Day - Identifying Locked AD Accounts
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在搜索指定的 AD 账户时，您可能曾经用过 `Get-ADUser` 命令，并且用 filter 参数来过滤结果。不过这样的过滤器可能会变得非常复杂。

这就是为什么针对最常见的 AD 搜索有一个快捷方式。只需要用 `Search-ADAccount` 命令即可：

```powershell
#requires -Modules ActiveDirectory


Search-ADAccount -AccountDisabled 
Search-ADAccount -AccountExpired
Search-ADAccount -AccountInactive
```

`Search-ADAccount` 暴露一系列参数来搜索最常见的条件。

<!--本文国际来源：[Identifying Locked AD Accounts](http://community.idera.com/powershell/powertips/b/tips/posts/identifying-locked-ad-accounts)-->
