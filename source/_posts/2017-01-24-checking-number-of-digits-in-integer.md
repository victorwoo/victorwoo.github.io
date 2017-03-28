layout: post
date: 2017-01-24 00:00:00
title: "PowerShell 技能连载 - 检查整数的位数"
description: PowerTip of the Day - Checking Number of Digits in Integer
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
有些时候您可能会需要检查一个整数的位数，例如验证用户的输入。以下是一个非常简单的使用正则表达式的方法：

```powershell
# check the number of digits in an integer
$integer = 5721567

# is it between 4 and 6 digits?
$is4to6 = $integer -match '^\d{4,6}$'

# is it exactly 7 digits?
$is7 = $integer -match '^\d{7}$'

# is it at least 4 digits?
$isatleast4 = $integer -match '^\d{4,}$'

"4-6 digits? $is4to6"
"exactly 7 digits? $is7"
"at least 4 digits? $isatleast4"
```

这个例子演示了如何检查是否是恰好的位数，或者位数处于某个范围。请注意 "^" 代表表达式的起始，"$" 代表表达式的结尾。"\d" 表示一位数字，大括号确定位数。

<!--more-->
本文国际来源：[Checking Number of Digits in Integer](http://community.idera.com/powershell/powertips/b/tips/posts/checking-number-of-digits-in-integer)
