layout: post
date: 2017-05-01 00:00:00
title: "PowerShell 技能连载 - 将 AD 用户转为哈希表"
description: PowerTip of the Day - Turning AD User into a Hash Table
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
有些时候从一个指定的 AD 用户读取所有属性到一个哈希表中十分有用。通过这种方法，您可以编辑他们，并使用 `Set-ADUser` 和它的 `-Add` 或 `-Replace` 参数将他们应用于另一个用户账户。

以下是将所有 AD 用户属性读到一个哈希表中的方法：

```powershell
#requires -Version 3.0 -Modules ActiveDirectory

$blacklist = 'SID', 'LastLogonDate', 'SAMAccountName'

$user = Get-ADUser -Identity NAMEOFUSER -Properties *
$name = $user | Get-Member -MemberType *property | Select-Object -ExpandProperty Name

$hash = [Ordered]@{}
$name |
  Sort-Object |
  Where-Object {
    $_ -notin $blacklist
  } |
  ForEach-Object {
  $hash[$_] = $user.$_
}
```

请注意 `$blacklist` 的使用：这个列表可以包含任何希望排除的属性名。

<!--more-->
本文国际来源：[Turning AD User into a Hash Table](http://community.idera.com/powershell/powertips/b/tips/posts/turning-ad-user-into-a-hash-table)
