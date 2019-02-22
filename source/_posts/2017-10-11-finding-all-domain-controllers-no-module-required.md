---
layout: post
date: 2017-10-11 00:00:00
title: "PowerShell 技能连载 - 查找所有域控制器（不依赖于模块）"
description: PowerTip of the Day - Finding All Domain Controllers (no module required)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们解释了如何使用 `ActiveDirectory` 模块和它的 cmdlet 来查找组织中的所有域控制器，或执行任何其它 LDAP 查询。

以下使用纯 .NET 方法实现相同目的。它不需要任何其它 PowerShell 模块，而且不需要事先安装 RSAT 工具。它需要您的电脑是 Active Directory 中的一个成员。

```powershell
$ldapFilter = "(&(objectCategory=computer)(userAccountControl:1.2.840.113556.1.4.803:=8192))"
$searcher = [ADSISearcher]$ldapFilter

$searcher.FindAll()
```

这行代码返回搜索结果对象。如果您确实想查看真实的 AD 对象，请试一试：

```powershell
$searcher.FindAll() | ForEach-Object { $_.GetDirectoryEntry() }
```

<!--本文国际来源：[Finding All Domain Controllers (no module required)](http://community.idera.com/powershell/powertips/b/tips/posts/finding-all-domain-controllers-no-module-required)-->
