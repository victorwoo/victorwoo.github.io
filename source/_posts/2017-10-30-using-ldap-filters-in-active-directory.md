---
layout: post
date: 2017-10-30 00:00:00
title: "PowerShell 技能连载 - 在 Active Directory 中使用 LDAP 过滤器"
description: PowerTip of the Day - Using LDAP Filters in Active Directory
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
LDAP 过滤器类似 Active Directory 中使用的查询语言。并且如果您安装了 Microsoft 的 RSAT 工具，您可以很方便地用 ActiveDirectory 模块中的 cmdlet 来用 LDAP 过滤器搜索用户、计算机，或其它资源。

以下代码将查找所有无邮箱地址的用户：

```powershell
$filter = '(&(objectCategory=person)(objectClass=user)(!mail=*))'
Get-ADUser -LDAPFilter $filter -Prop *
```

即便您没有 RSAT 工具和指定的 ActiveDirectory cmdlet 的权限，LDAP 过滤器也十分有用：

```powershell
$filter = '(&(objectCategory=person)(objectClass=user)(!mail=*))'
$searcher = [ADSISearcher]$filter
# search results only
$searcher.FindAll()
# access to directory entry objects with more details
$searcher.FindAll().GetDirectoryEntry() | Select-Object -Property *
```

<!--more-->
本文国际来源：[Using LDAP Filters in Active Directory](http://community.idera.com/powershell/powertips/b/tips/posts/using-ldap-filters-in-active-directory)
