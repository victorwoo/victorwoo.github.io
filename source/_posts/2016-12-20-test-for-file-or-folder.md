---
layout: post
date: 2016-12-20 00:00:00
title: "PowerShell 技能连载 - 检测文件或文件夹"
description: PowerTip of the Day - Test for File or Folder
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Test-Path` 可以检测一个文件或文件夹是否存在。如果您添加了 `-PathType` 来指定叶子节点（文件），或 `-Container`（文件夹），结果会更具体：

```powershell
$path = 'c:\windows'

Test-Path -Path $path
Test-Path -Path $path -PathType Leaf
Test-Path -Path $path -PathType Container
````

<!--本文国际来源：[Test for File or Folder](http://community.idera.com/powershell/powertips/b/tips/posts/test-for-file-or-folder)-->
