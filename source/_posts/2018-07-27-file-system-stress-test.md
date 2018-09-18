---
layout: post
date: 2018-07-27 00:00:00
title: "PowerShell 技能连载 - 文件系统压力测试"
description: PowerTip of the Day - File System Stress Test
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
如果您想生成一个超大文件来做压力测试，您不需要浪费时间写入大量数据到一个文件中，使它体积增大。相反，只需要设置一个期望的文件大小来占据磁盘空间即可。

以下是创建一个 1GB 测试文件的方法：

```powershell
# create a test file
$path = "$env:temp\dummyFile.txt"
$file = [System.IO.File]::Create($path)

# set the file size (file uses random content)
$file.SetLength(1gb)
$file.Close()

# view file properties
Get-Item $path
```

<!--more-->
本文国际来源：[File System Stress Test](http://community.idera.com/powershell/powertips/b/tips/posts/file-system-stress-test)
