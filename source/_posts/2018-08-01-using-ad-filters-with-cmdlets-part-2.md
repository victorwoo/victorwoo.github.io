---
layout: post
date: 2018-08-01 00:00:00
title: "PowerShell 技能连载 - 使用 AD 过滤器配合 cmdlet（第 2 部分）"
description: PowerTip of the Day - Using AD Filters with Cmdlets (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中，我们开始学习 ActiveDirectory 模块（免费的 RSAT 工具）中的 cmdlet 如何过滤执行结果。您学到了过滤器看起来像 PowerShell 代码，但是实际上不是。

对于简单的过滤，该过滤器工作正常。然而，当您使用操作符以外的 PowerShell 语言特性时，您很快会发现实际中使用的过滤器并不是 PowerShell 代码。

如果您想获得一个未配置文件路径的 AD 用户列表，您可能会好奇地尝试以下的代码：

```powershell
Get-ADUser -Filter { profilePath -eq $null} -ResultSetSize 5
Get-ADUser -Filter { profilePath -eq ''} -ResultSetSize 5
```

两个过滤器都会失败。PowerShell 报告 `$null` 变量是未知的。而在第二行中，报告该该搜索查询不合法。

这是为什么大多数情况下使用在 Active Directory 常见的原生 LDAPFilters 是更方便（而且更快）的。LDAP 过滤器是括号中的表达式。它们包含一个名称和一个操作符。以下代码返回前 5 个有配置文件路径的用户：

```powershell
Get-ADUser -LDAPFilter '(profilePath=*)' -ResultSetSize 5
```

加上 "!" 以后，可以将结果反转，所以以下代码将返回前 5 个**没有**配置文件路径的用户：

```powershell
Get-ADUser -LDAPFilter '(!profilePath=*)' -ResultSetSize 5
```

以下代码将返回用户和他们的配置文件路径的列表：

```powershell
Get-ADUser -LDAPFilter '(profilePath=*)' -Properties profilePath |
Select-Object samaccountName, profilePath
```

<!--本文国际来源：[Using AD Filters with Cmdlets (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/using-ad-filters-with-cmdlets-part-2)-->
