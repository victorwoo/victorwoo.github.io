layout: post
date: 2016-11-03 16:00:00
title: "PowerShell 技能连载 - （分别）测试文件和文件夹"
description: PowerTip of the Day - Testing Files and Folders (separately)
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
`Test-Path` 在测试一个文件或文件夹是否存在时十分有用，它可以用在任何 PowerShell 驱动器上。所以它也可以测试一个变量、一个函数，或一个证书是否存在（举个例子）。

In recent PowerShell versions, Test-Path can now differentiate between containers (i.e. folders) and leafs (i.e. files), too:

在近期的 PowerShell 版本中，`Test-Path` 还可以区分容器（例如文件夹）和叶子（例如文件）：

```powershell
$path = 'c:\windows\explorer.exe'
# any item type
Test-Path -Path $path
# just files
Test-Path -Path $path -PathType Leaf
# just folders
Test-Path -Path $path -PathType Container
```

<!--more-->
本文国际来源：[Testing Files and Folders (separately)](http://community.idera.com/powershell/powertips/b/tips/posts/testing-files-and-folders-separately)
