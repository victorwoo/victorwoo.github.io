---
layout: post
date: 2019-03-05 00:00:00
title: "PowerShell 技能连载 - 接受不带引号的参数"
description: PowerTip of the Day - Accepting Parameters without Quotes
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中，我们介绍了一个能够输入一个字符串并生成完美居中的标题的函数。以下是该函数和它的执行结果：

```powershell
function Show-Header($Text)
{
  $Width=80
  $padLeft = [int]($width / 2) + ($text.Length / 2)
  $text.PadLeft($padLeft, "=").PadRight($Width, "=")
}


PS> Show-Header Starting
====================================Starting====================================

PS> Show-Header "Processing Input Values"
=============================Processing Input Values============================
```

如您所见，这个函数工作起来很完美，但是如果该字符串包含空格或其它特殊字符，用户需要用双引号将它包起来。难道不能让这个函数接受没有双引号的字符串，并将所有的输入视为一个参数吗？

这是完全可能的，如下：

* 这个参数定义了明确的数据类型，例如 `[string]`，那么 PowerShell 就了解了应当如何处理您的参数。
* 只能使用单个参数，这样 PowerShell 便知道了所有的输入项都需要转换为该参数。

以下是修改后的函数：

```powershell
function Show-Header([Parameter(ValueFromRemainingArguments)][string]$Text)
{
  $Width=80
  $padLeft = [int]($width / 2) + ($text.Length / 2)
  $text.PadLeft($padLeft, "=").PadRight($Width, "=")
}
```

魔力是通过 `ValueFromRemainingArguments` 属性产生的，用户可以简单地输入文字并切不需要使用双引号：

```powershell
PS> Show-Header Starting
====================================Starting====================================

PS> Show-Header Processing Input Values
=============================Processing Input Values============================
```

然欧，有一点需要注意：任何特殊字符，例如圆括号和双引号仍会干扰解析。在这些情况下，您需要像之前那样将字符串用双引号包起来。

今日知识点：

* 用 `ValueFromRemainingArguments` 属性使 PowerShell 能够将所有未绑定（额外）的参数分配到该参数上。
* 使用清晰的数据类型做为参数，这样 PowerShell 知道如何转换含糊的数据。例如，没有 `[string]` 数据类型的话，如果输入值包含空格，PowerShell 将会为创建一个字符串数组。

<!--本文国际来源：[Accepting Parameters without Quotes](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/accepting-parameters-without-quotes)-->
