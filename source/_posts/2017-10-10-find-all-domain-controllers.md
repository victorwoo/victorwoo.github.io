---
layout: post
date: 2017-10-10 00:00:00
title: "PowerShell 技能连载 - 查找所有域控制器"
description: PowerTip of the Day - Find All Domain Controllers
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
如果您安装了免费的 Microsoft RSAT tools，那么您就拥有了 ActiveDirectory 模块。以下是一个查找组织中所有域控制器的简单方法：

```powershell
#requires -Module ActiveDirectory

$filter = '(&(objectCategory=computer)(userAccountControl:1.2.840.113556.1.4.803:=8192))'
Get-ADComputer -LDAPFilter $filter
```

基本上，您可以运行任意的 LDAP 过滤器查询。只需要选择合适的 cmdlet，例如 `Get-ADComputer`、`Get-ADUser` 或最通用的 `Get-ADObject`。

<!--more-->
本文国际来源：[Find All Domain Controllers](http://community.idera.com/powershell/powertips/b/tips/posts/find-all-domain-controllers)
