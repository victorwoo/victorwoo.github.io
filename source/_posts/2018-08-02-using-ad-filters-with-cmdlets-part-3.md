---
layout: post
date: 2018-08-02 00:00:00
title: "PowerShell 技能连载 - 使用 AD 过滤器配合 cmdlet（第 3 部分）"
description: PowerTip of the Day - Using AD Filters with Cmdlets (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在之前的技能中，我们开始学习 ActiveDirectory 模块（免费的 RSAT 工具）中的 cmdlet 如何过滤执行结果，并且开始以我们的方式插入快捷且完善的 LDAP 过滤器。

LDAP 过滤器有一个强制的需求。您必须使用原始的 ActiveDirectory 属性名，而不是许多 PowerShell cmdlet 中的友好名称。所以 "country" 需要改为 AD 的属性名 "co"。当您坚持使用这些名字后，创建 LDAP 过滤器十分容易。

这行代码将会从 Active Directory 中获取所有 Windows 10 计算机：

```powershell
Get-ADComputer -LDAPFilter '(operatingSystem=*10*)' -Properties operatingSystem |
Select-Object samaccountname, operatingSystem
```

如果您想合并多个过滤器，请将它们加到小括号中，然后在前面添加 "&" 进行逻辑与操作，添加 "|" 进行逻辑或操作。所以这行代码查找所有从 Wuppertal 城市，名字以 "A" 开头的用户：

```powershell
Get-ADUser -LDAPFilter '(&(l=Wuppertal)(name=a*))'
```

<!--本文国际来源：[Using AD Filters with Cmdlets (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/using-ad-filters-with-cmdlets-part-3)-->
