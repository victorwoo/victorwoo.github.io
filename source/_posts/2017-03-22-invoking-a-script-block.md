layout: post
date: 2017-03-22 00:00:00
title: "PowerShell 技能连载 - 调用一个脚本块"
description: PowerTip of the Day - Invoking a Script Block
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
可以通过调用操作符，例如 "`&`"、"`.`" 或调用 `Invoke()` 方法调用在一个脚本块中的代码。

一个区别是当有多于一个结果时的输出：调用操作符返回一个扁平的对象数组，而 `Invoke()` 返回一个集合：

```powershell
$code = { Get-Process }

$result1 = & $code
$result2 = $code.Invoke()

$result1.GetType().FullName
$result2.GetType().FullName
```

通过 `Invoke()` 方法返回的集合拥有额外的方法，例如 `RemoveAt()` 和 `Insert()`，它们能够帮您修改结果数据，能高效地插入或删除元素。

您可以手动将一个 cmdlet 的返回值手动转为一个 ArrayList：

```powershell
$arrayList = [Collections.ArrayList]@(Get-Process)
```

<!--more-->
本文国际来源：[Invoking a Script Block](http://community.idera.com/powershell/powertips/b/tips/posts/invoking-a-script-block)
