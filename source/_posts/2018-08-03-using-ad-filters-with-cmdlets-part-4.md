---
layout: post
date: 2018-08-03 00:00:00
title: "PowerShell 技能连载 - 使用 AD 过滤器配合 cmdlet（第 4 部分）"
description: PowerTip of the Day - Using AD Filters with Cmdlets (Part 4)
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
在前一个技能中，我们开始学习 ActiveDirectory 模块（免费的 RSAT 工具）中的 cmdlet 如何过滤执行结果，并且学习了如何合并过滤器表达式。今天我们将学习如何处理日期和时间。

有些 AD 属性包含日期和时间信息，例如上次登录的日期。这类信息是以一串非常长的 64 位整数标识的。您可以在 LDAP 过滤器中以这种格式使用日期和时间。

例如，要查找近 4 个星期中没有修改密码的所有用户：

```powershell
$weeks = 4
# first, find out the AD time format from
# 4 weeks ago that will be used in the LDAPFilter

$today = Get-Date
# 4 weeks ago
$cutDate = $today.AddDays(-($weeks * 7))
# translate in AD time format
$cutDateAD = $cutDate.ToFileTimeUtc()

# next, find a way to convert back the AD file format
$realDate = @{
  Name = 'Date'
  Expression = { if ($_.pwdLastset -eq 0)
    {
      '[never]'
    }
    else
    {
      [DateTime]::FromFileTimeUtc($_.pwdLastset) 
    }
  }

}

Get-ADUser -LDAPFilter "(pwdLastSet<=$cutDateAD)" -Properties pwdLastSet | 
  Select-Object -Property samaccountname, $realDate
```

实际上，当调用一个 `DateTime` 对象的 `ToFileTimeUtc()` 方法之后，将返回 AD 格式的数据。类似地，当您运行 `[DateTime]::FromFileTimeUtc()` 时，将会把 AD 格式转换为一个真实的 `DateTime` 对象。

<!--more-->
本文国际来源：[Using AD Filters with Cmdlets (Part 4)](http://community.idera.com/powershell/powertips/b/tips/posts/using-ad-filters-with-cmdlets-part-4)
