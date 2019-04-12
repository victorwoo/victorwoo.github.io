---
layout: post
date: 2019-04-09 00:00:00
title: "PowerShell 技能连载 - 超级简单的密码生成器"
description: PowerTip of the Day - Super Simple Random Password Generator
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是一个超级简单的生成随机密码的方法。这个方法确保不会使用有歧义的字符，但不会关心其它规则，例如指定字符的最小个数。

```powershell
$Length = 12
$characters = 'abcdefghkmnprstuvwxyz23456789§$%&?*+#'
$password = -join ($characters.ToCharArray() |
Get-Random -Count $Length)

$password
```

<!--本文国际来源：[Super Simple Random Password Generator](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/super-simple-random-password-generator)-->

