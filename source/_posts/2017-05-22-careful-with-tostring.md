---
layout: post
date: 2017-05-22 00:00:00
title: "PowerShell 技能连载 - 请注意 ToString() 方法"
description: PowerTip of the Day - Careful with ToString()
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
任何 .NET 对象都有一个 `ToString()` 方法，返回的是一段文字描述。这也是当您将一个对象输出为一个字符串时所得到的内容。然而，`ToString()` 所返回的值可能会改变，所以您永远不要使用它来做一些重要的事情。

Here is an example – these lines both produce a FileInfo object which represents the exact same file. Only the way how the object was created is different. All object properties are identical. Yet, ToString() differs:
以下是一个例子——这两行代码都会创建一个 `FileInfo` 对象，来代表同一个文件。只是创建对象的方法有所不同。所有的对象属性都相同。然而，`ToString()` 的结果不同：

```powershell
PS> $file1 = Get-ChildItem $env:windir -Filter regedit.exe
PS> $file2 = Get-Item $env:windir\regedit.exe

$file1.FullName; $file2.FullName
C:\WINDOWS\regedit.exe
C:\WINDOWS\regedit.exe

PS> $file1.GetType().FullName; $file2.GetType().FullName
System.IO.FileInfo
System.IO.FileInfo

PS> $file1.ToString(); $file2.ToString()
regedit.exe
C:\WINDOWS\regedit.exe
```

<!--more-->
本文国际来源：[Careful with ToString()](http://community.idera.com/powershell/powertips/b/tips/posts/careful-with-tostring)
