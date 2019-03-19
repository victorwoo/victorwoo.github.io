---
layout: post
date: 2017-11-10 00:00:00
title: "PowerShell 技能连载 - 从字符串中移除文本"
description: PowerTip of the Day - Removing Text from Strings
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有时候，您也许听说过 `Trim()`、`TrimStart()` 和 `TrimEnd()` 可以 移除字符串中的文本。并且它们工作起来很正常：

```powershell
PS C:\> $testvalue = "this is strange"
PS C:\> $testvalue.TrimEnd("strange")
this is

PS C:\>
```

但是这个呢：

```powershell
PS C:\> $testvalue = "this is strange"
PS C:\> $testvalue.TrimEnd(" strange")
this i

PS C:\>
```

实际情况是 `Trim()` 方法将您的参数视为一个字符的列表。所有这些字符都将被移除。

如果您只是想从字符串的任意位置移除文本，请使用 `Replace()` 来代替：

```powershell
PS C:\> $testvalue.Replace(" strange", "")
this is

PS C:\>
```

如果您需要进一步的控制，请使用正则表达式和锚定。要只从字符串的尾部移除文本，以下代码可以实现这个功能。只有结尾部分的  "strange" 字符串会被移除。

```powershell
$testvalue = "this is strange strange strange"

$searchText = [Regex]::Escape("strange")
$anchorTextEnd = "$"
$pattern = "$searchText$anchorTextEnd"

$testvalue -replace $pattern
```

<!--本文国际来源：[Removing Text from Strings](http://community.idera.com/powershell/powertips/b/tips/posts/removing-text-from-strings)-->
