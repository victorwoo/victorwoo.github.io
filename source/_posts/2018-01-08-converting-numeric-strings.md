---
layout: post
date: 2018-01-08 00:00:00
title: "PowerShell 技能连载 - 转换数字字符串"
description: PowerTip of the Day - Converting Numeric Strings
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中转换一个包含数字的字符串非常简单：

```powershell
    PS C:\> [double]"77.234"
    77,234

    PS C:\>
```

不过，如果字符串包含的不只是纯数字，那么就比较有挑战性了。例如，您需要转换一个类似 "2763MB" 的字符串，PowerShell 无法自动将它转换为一个数字。这时候您需要一个类似这样的转换函数：

```powershell
function Convert-MBToByte($MBString)
{
    $number = $MBString.Substring(0, $MBString.Length-2)
    1MB * $number
}

Convert-MBToByte -MBString '2433MB'
```

或者如果它是一个合法的 PowerShell 代码格式，您可以试着让 PowerShell 来做转换：

```powershell
    PS C:\> Invoke-Expression -Command '2615MB'
    2742026240

    PS C:\>
```

然而，不推荐使用 `Invoke-Expression`，因为它会带来安全风险。例如用户能够改变命令执行的表达式，类似 SQL 注入攻击。

<!--本文国际来源：[Converting Numeric Strings](http://community.idera.com/powershell/powertips/b/tips/posts/converting-numeric-strings)-->
