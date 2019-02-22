---
layout: post
date: 2018-08-24 00:00:00
title: "PowerShell 技能连载 - 验证变量内容"
description: PowerTip of the Day - Validating Variable Content
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
从 PowerShell 5 开始，您可以为一个变量增加一个验证器。该验证器可以接受一个正则表达式，而且当您向该变量赋值时，该验证其检查新内容是否匹配正则表达式模式。如果不匹配，将会抛出一个异常，而该变量内容保持不变。

以下是一个存储 MAC 地址的变量示例：

```powershell
[ValidatePattern('^[a-fA-F0-9:]{17}|[a-fA-F0-9]{12}$')][string]$mac = '12:AB:02:33:12:22'
```

运行这段代码，然后尝试将一个新的 mac 地址赋值给该变量。如果新的 mac 地址不符合验证器，PowerShell 将抛出一个异常。

<!--本文国际来源：[Validating Variable Content](http://community.idera.com/powershell/powertips/b/tips/posts/validating-variable-content)-->
