---
layout: post
date: 2020-06-15 00:00:00
title: "PowerShell 技能连载 - 转换十六进制数据"
description: PowerTip of the Day - Converting Hex Numbers
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您添加 "0x" 前缀时，PowerShell 可以交互地转换十六进制数字：

```powershell
PS> 0xAB0f
43791
```

如果十六进制数存储在字符串中，则可以通过将类型应用于表达式来调用转换：

```powershell
PS> $a = 'ab0f'

PS> [int]"0x$a"
43791
```

<!--本文国际来源：[Converting Hex Numbers](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/converting-hex-numbers)-->

