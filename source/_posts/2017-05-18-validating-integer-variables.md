---
layout: post
date: 2017-05-18 00:00:00
title: "PowerShell 技能连载 - 验证整形变量"
description: PowerTip of the Day - Validating Integer Variables
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
您可以在一个变量前简单地加上 `[Int]` 来确保它只包含数字位。但您是否知道从 PowerShell 4.0 开始，支持正则表达式的验证器呢？

通过这种方式，您可以定义一个变量只能为 2 位至 6 位的正数，或其它指定的模式：

```powershell
PS>  [ValidatePattern('^\d{2,6}$')][int]$id = 666

PS> $id = 10000

PS> $id = 1000000
Cannot check variable id. Value 1000000 is  invalid for variable id.


PS> $id = 10

PS> $id = 1
Cannot check variable  id. Value 1 is invalid for variable id.
```

<!--more-->
本文国际来源：[Validating Integer Variables](http://community.idera.com/powershell/powertips/b/tips/posts/validating-integer-variables)
