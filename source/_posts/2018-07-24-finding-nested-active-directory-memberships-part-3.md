---
layout: post
date: 2018-07-24 00:00:00
title: "PowerShell 技能连载 - 查找嵌套的 Active Directory 成员（第 3 部分）"
description: PowerTip of the Day - Finding Nested Active Directory Memberships (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们演示了如何使用 ActiveDirectory 模块中的 cmdlet 来查找某个 Active Directory 用户所有直接和间接的成员。如果您想知道当前用户的成员信息，还有一个更简单（而且更快）的方法：用当前用户的 access token 来获取当前有效的组成员：

```powershell
$groups = [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups.Translate([System.Security.Principal.NTAccount])

$groups

$groups.Count
```

<!--本文国际来源：[Finding Nested Active Directory Memberships (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/finding-nested-active-directory-memberships-part-3)-->
