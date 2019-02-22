---
layout: post
date: 2019-01-01 00:00:00
title: "PowerShell 技能连载 - 首字母大写"
description: PowerTip of the Day - Title-Casing Strings (Capital Letter Starts Each Word)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
修饰一段文本并不太简单，如果您希望名字或者文本格式正确，并且每个单词都以大写开头，那么工作量通常很大。

有趣的是，每个 `CultureInfo` 对象有一个内置的 `ToTitleCase()` 方法，可以完成上述工作。如果您曾经将纯文本转换为全部消协，那么它也可以处理所有大写的单词：

```powershell
$text = "here is some TEXT that I would like to title-case (all words start with an uppercase letter)"

$textInfo = (Get-Culture).TextInfo
$textInfo.ToTitleCase($text)
$textInfo.ToTitleCase($text.ToLower())
```

以下是执行结果：

    Here Is Some TEXT That I Would Like To Title-Case (All Words Start With An Upper Letter
    Here Is Some Text That I Would Like To Title-Case (All Words Start With An Upper Letter 

This method may be especially useful for list of names.
这个方法对于姓名列表很有用。

<!--本文国际来源：[Title-Casing Strings (Capital Letter Starts Each Word)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/title-casing-strings-capital-letter-starts-each-word)-->
