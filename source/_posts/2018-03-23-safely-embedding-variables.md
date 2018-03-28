---
layout: post
date: 2018-03-23 00:00:00
title: "PowerShell 技能连载 - 安全地嵌入变量"
description: PowerTip of the Day - Safely Embedding Variables
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
当您在 PowerShell 中使用双引号时，您可以向字符串中增加变量，PowerShell 能自动将它们替换成它们的值——这并不是什么新鲜事：

```powershell
$ID = 234

"Server $ID Rack12"
```

然而，PowerShell 自动判断一个变量的结束位置，所以当您希望在一个文本中插入一个不含空格的数字时，这种写法可能会失败：

```powershell
$ID = 234

"Server$IDRack12"
```

如同语法高亮的信息，PowerShell 会将变量识别成 `$IDRack12` 因为它无法意识到变量名提前结束。

在这些情况下，只需要用大括号将变量名括起来即可：

```powershell
$ID = 234

"Server${ID}Rack12"
```

<!--more-->
本文国际来源：[Safely Embedding Variables](http://community.idera.com/powershell/powertips/b/tips/posts/safely-embedding-variables)
