---
layout: post
date: 2018-10-03 00:00:00
title: "PowerShell 技能连载 - 快速查找 Active Directory 组成员"
description: PowerTip of the Day - Finding Active Directory Group Members Efficiently
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
经常地，AD 管理员需要查找某个 AD 组的所有成员，包括嵌套的成员。以下是一个常常出现在示例中的代码片段，用于解决这个问题：

```powershell
$groupname = 'External_Consultants'
$group = Get-ADGroup -Identity $groupname
$dn = $group.DistinguishedName
$all = Get-ADUser -filter {memberof -recursivematch $dn}
$all | Out-GridView
```

（请注意您需要来自 Microsoft 免费的 RSAT 工具来使用这些示例中的 cmdlet。） 

当您将 `$groupname` 中的组名改为您组织中存在的 AD 组名后，该代码不仅返回组中的直接用户，而且包含既在该组又在其它组中的直接用户。

然而，该代码执行起来非常慢。以下是一个更简单的实现，能达到多于五倍的速度：

```powershell
$groupname = 'External_Consultants'
$all = Get-ADGroupMember -Identity $groupname -Recursive
$all | Out-GridView
```

它的内部使用合适的 LDAP 过滤器，和以上直接的方法类似：

```powershell
$groupname = 'External_Consultants'
$group = Get-ADGroup -Identity $groupname
$dn = $group.DistinguishedName
$ldap = "(memberOf:1.2.840.113556.1.4.1941:=$dn)"
$all = Get-ADUser -LDAPFilter $ldap
$all | Out-GridView
```

<!--本文国际来源：[Finding Active Directory Group Members Efficiently](http://community.idera.com/powershell/powertips/b/tips/posts/finding-active-directory-group-members-efficiently)-->
