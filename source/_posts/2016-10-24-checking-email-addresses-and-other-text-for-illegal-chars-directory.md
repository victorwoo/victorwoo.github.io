layout: post
date: 2016-10-23 16:00:00
title: "PowerShell 技能连载 - 检查电子邮件地址（或其它文本）中的非法字符"
description: PowerTip of the Day - Checking Email Addresses (and Other Text) for Illegal Chars
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
这是一个清晰的检测和验证数据的快捷方法。假设您需要验证一个电子邮件地址是否包含非法字符：

```powershell
# some email address
$mail = 'thomas.börsenberg@test.com'
# list of allowed characters
$pattern = '[^a-z0-9\.@]'

if ($mail -match $pattern)
{
    ('Invalid character in email address: {0}' -f $matches[0])
}
else
{
  'Email address is good.'
}
```

这段代码使用了正则表达式。正则表达式列出所有合法的字符（从 a 到 z，以及某些特殊字符）。在前面加上“`^`”，列表的含义发生反转，代表所有非法字符。如果找到至少一个字符，则返回第一个非法字符。

    Invalid character in email address: ö


<!--more-->
本文国际来源：[Checking Email Addresses (and Other Text) for Illegal Chars](http://community.idera.com/powershell/powertips/b/tips/posts/checking-email-addresses-and-other-text-for-illegal-chars-directory)
