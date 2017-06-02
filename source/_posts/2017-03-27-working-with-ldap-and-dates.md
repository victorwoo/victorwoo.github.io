---
layout: post
date: 2017-03-27 00:00:00
title: "PowerShell 技能连载 - 处理 LDAP 和日期"
description: PowerTip of the Day - Working with LDAP and Dates
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
LDAP 过滤器是一个快速和强大的从 Active Directory 中获取信息的方法。然而，LDAP 过滤器使用的是一个很底层的日期和时间格式。它基本上是一个很大的整形数。幸运的是 PowerShell 包含多种将实际 DateTime 对象转换为这些数字，以及相反操作的方法。

以下是一个使用 ActiveDirectory 模块中 `Get-ADUser` 方法来查找所有近期更改了密码的用户的示例代码。如果您没有这个 module，请从 Microsoft 下载免费的 RSAT 工具。

```powershell
# find all AD Users who changed their password in the last 5 days
$date = (Get-Date).AddDays(-5)
$ticks = $date.ToFileTime()


$ldap = "(&(objectCategory=person)(objectClass=user)(pwdLastSet>=$ticks))"
Get-ADUser -LDAPFilter $ldap -Properties * |
  Select-Object -Property Name, PasswordLastSet
```

<!--more-->
本文国际来源：[Working with LDAP and Dates](http://community.idera.com/powershell/powertips/b/tips/posts/working-with-ldap-and-dates)
