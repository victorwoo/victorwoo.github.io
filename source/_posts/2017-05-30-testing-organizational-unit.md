---
layout: post
date: 2017-05-30 00:00:00
title: "PowerShell 技能连载 - 测试 OU"
description: PowerTip of the Day - Testing Organizational Unit
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
假设您已安装了免费的 Microsoft RSAT 工具，以下是一个简单的方法来检测一个 OU 是否存在：

```powershell
$OUPath = 'OU=TestOU,DC=train,DC=powershell,DC=local'
$exists = $(try { Get-ADOrganizationalUnit -Identity $OUPath -ErrorAction Ignore } catch{}) -ne $null
"$OUPath : $exists"
```

`$exits` 的值将是 `$true` 或 `$false`，表示是否找到该 OU。请注意使用 try/catch 处理错误的方法：`Get-ADOrganizationalUnit` 将在指定的 OU 不存在时抛出终止错误，所以需要 try/catch 来捕获这些错误。

<!--more-->
本文国际来源：[Testing Organizational Unit](http://community.idera.com/powershell/powertips/b/tips/posts/testing-organizational-unit)
