layout: post
date: 2015-12-30 12:00:00
title: "PowerShell 技能连载 - 查找递归的 AD 成员"
description: PowerTip of the Day - Finding Recursive AD Memberships
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
在 AD 中，有一个看起来很奇怪的过滤器：1.2.840.113556.1.4.1941。它被称为“链式匹配规则”，可以用来快速查找嵌套的成员。

您所需的是某个成员的 DN。然后，您可以像这样使用它：

```powershell
#requires -Version 1 -Modules ActiveDirectory 

$DN = 'place DN here!'
Get-ADGroup -LDAPFilter "(member:1.2.840.113556.1.4.1941:=$($DN))"
```

Since this is a native LDAP filter, you can even use it without the ActiveDirectory module, resorting to native .NET methods:
由于它是一个原生的 LDAP 过滤器，您甚至可以在没有 ActiveDirectory 模块的情况下以 .NET 原生的方式使用它。

```powershell
$DN = 'place DN here!'
$strFilter = "(member:1.2.840.113556.1.4.1941:=$DN)"
$objDomain = New-Object System.DirectoryServices.DirectoryEntry('LDAP://rootDSE')
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = "LDAP://$($objDomain.rootDomainNamingContext)"
$objSearcher.PageSize = 1000
$objSearcher.Filter = $strFilter
$objSearcher.SearchScope = 'Subtree'
$colProplist = 'name'
foreach ($i in $colPropList){
  $null = $objSearcher.PropertiesToLoad.Add($i)
}
$colResults = $objSearcher.FindAll()
foreach ($objResult in $colResults)
{
  $objItem = $objResult.Properties
  $objItem.name
}
```

<!--more-->
本文国际来源：[Finding Recursive AD Memberships](http://powershell.com/cs/blogs/tips/archive/2015/12/30/finding-recursive-ad-memberships.aspx)
