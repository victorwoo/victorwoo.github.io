---
layout: post
date: 2018-01-19 00:00:00
title: "PowerShell 技能连载 - 快速创建逗号分隔的字符串（第 1 部分）"
description: PowerTip of the Day - Efficiently Produce Comma-Separated Strings
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是一个非常简单的创建引号包起来的字符串的列表的例子：

```powershell
& { "'$($args -join "','")'" } hello this is a test
```

以下是执行结果：

```powershell
'hello','this','is','a','test'
```

这个例子有效利用了 PowerShell 的“命令模式”，字面量被当作参数使用。您还可以将结果通过管道导出到 `Set-Clipboard` 指令执行，然后将结果贴回代码中。这比起手工为每个字符串添加引号方便多了。


```powershell
PS> & { "'$($args -join "','")'" } hello this is a test  | Set-ClipBoard

PS> Get-ClipBoard
'hello','this','is','a','test'
```

<!--本文国际来源：[Efficiently Produce Comma-Separated Strings](http://community.idera.com/powershell/powertips/b/tips/posts/efficiently-produce-comma-separated-strings)-->
