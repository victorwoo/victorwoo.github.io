---
layout: post
title: "PowerShell 技能连载 - 传递参数给 EXE 文件"
date: 2014-03-24 00:00:00
description: PowerTip of the Day - Submitting Arguments to EXE Files
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
从 PowerShell 运行某些应用程序，例如 robocopy.exe 不是很方便。如何向 EXE 传递参数，并且确保通过 PowerShell 不会传错值呢？

方法很简单：确保所有的参数是字符串（所以如果参数不是字符串或包含其它特殊字符，那么用双引号把它们包起来）。并且，确保针对每个参数提交一个字符串，而不是单个大字符串。

以下代码将从 PowerShell 执行 robocopy.exe 并且递归地从 Windows 文件夹中拷贝所有的 JPG 图片到另一个 c:\jpegs 文件夹中，遇到错误不重试，并跳过 *winsxs* 文件夹。

    $arguments = "$env:windir\", 'c:\jpegs\','*.jpg', '/R:0', '/S', '/XD', '*winsxs*'

    Robocopy.exe $arguments

如您所见，所有的参数都是字符串，并且它们都以一个字符串数组的形式传递。

这种方法完美地运行于所有您希望通过 PowerShell 调用的 exe 程序。

<!--本文国际来源：[Submitting Arguments to EXE Files](http://community.idera.com/powershell/powertips/b/tips/posts/submitting-arguments-to-exe-files)-->
