layout: post
date: 2017-01-25 00:00:00
title: "PowerShell 技能连载 - 增加和删除反斜杠"
description: PowerTip of the Day - Adding and Removing Backslashes
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
我们处理路径时，常常需要使路径“标准化”。例如确保所有的路径都以反斜杠结尾。一种尝试如下：

```powershell
$path = 'c:\temp'
if ($path -notmatch '\\$')
  {
    $path += '\'
  }
$path
```

这段代码用正则表达式来查找一段文本尾部的反斜杠。如果不存在，则添加一个反斜杠。

如果您想删除路径尾部的反斜杠，您可以直接使用 `-replace` 运算符：

```powershell
$path = 'c:\temp\' -replace '\\$'
$path
```

<!--more-->
本文国际来源：[Adding and Removing Backslashes](http://community.idera.com/powershell/powertips/b/tips/posts/adding-and-removing-backslashes)
