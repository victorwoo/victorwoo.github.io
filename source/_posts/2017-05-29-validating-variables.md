---
layout: post
date: 2017-05-29 00:00:00
title: "PowerShell 技能连载 - 验证变量有效性"
description: PowerTip of the Day - Validating Variables
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
变量和函数参数可以通过验证属性自动地验证有效性。以下是一个简单的例子，确保 `$test1` 只能存储 1-10 之间的值：

```powershell
[ValidateRange(1,10)]$test1 = 10
```

当您将一个小于 1 或大于 10 的值赋给这个变量，PowerShell 将会抛出一个异常。不过通过这种方式您无法控制异常的问本。

通过使用脚本验证器，您可以选择自己希望的错误信息：

```powershell
[ValidateScript({
If ($_ -gt 10)
{ throw 'You have submitted a value greater than 10. That will not work, dummy!' }
Elseif ($_ -lt 1)
{ throw 'You have submitted a value lower than 1. That will not work, dummy!' }

$true
})]$test2 = 10
```

以下是输出结果：

```powershell
PS C:\> $test2 =  4

PS C:\> $test2 =  11
You have submitted a  value greater than 10. That will  not work, dummy!
At line:5 char:3
+ { throw 'You have submitted  a value greater than 10. That will not work, dummy ...
+    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (You have submitted  a...not work, dummy!:String
    ) [], RuntimeException
    + FullyQualifiedErrorId : You have submitted  a value greater than 10. That  will not work, dummy!



PS C:\> $test2 =  -2
You have submitted a  value lower than 1. That will  not work, dummy!
At line:7 char:3
+ { throw 'You have submitted  a value lower than 1. That will not work, dummy ...
+    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (You have submitted  a...not work, dummy!:String
    ) [], RuntimeException
    + FullyQualifiedErrorId : You have  submitted a value lower than 1. That  will not work, dummy!
```

<!--more-->
本文国际来源：[Validating Variables](http://community.idera.com/powershell/powertips/b/tips/posts/validating-variables)
