---
layout: post
date: 2023-02-28 00:00:39
title: "PowerShell 技能连载 - 使用合适的数据类型（第 1 部分）"
description: PowerTip of the Day - Using Appropriate DataTypes (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 是一个 API 驱动的操作系统，而 PowerShell 也是如此。与其他使用纯文本作为基础元素并让用户通过 grep 和正则表达式来结构化数据的 shell 相比，PowerShell（和底层的 .NET 框架）提供了一组丰富的数据类型，您可以从中选择最适合的来完美地存储数据。

默认情况下，PowerShell 仅使用基本数据类型，例如`[string]`（文本），`[int]`（数字），`[double]`（浮点数），`[datetime]`（日期和时间）和`[bool]`（真和假）。

You however can pick any other data type that you find more suitable:
但是，您可以选择任何其他您认为更合适的数据类型：

```powershell
PS> [System.IO.FileInfo]'c:\test\somefile.txt'

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
darhsl        01.01.1601     01:00             () somefile.txt



PS> [System.IO.FileInfo]'c:\test\somefile.txt' | Select-Object -Property *


Mode              : darhsl
VersionInfo       :
BaseName          : somefile
Target            :
LinkType          :
Name              : somefile.txt
Length            :
DirectoryName     : c:\test
Directory         : c:\test
IsReadOnly        : True
Exists            : False
FullName          : c:\test\somefile.txt
Extension         : .txt
CreationTime      : 01.01.1601 01:00:00
CreationTimeUtc   : 01.01.1601 00:00:00
LastAccessTime    : 01.01.1601 01:00:00
LastAccessTimeUtc : 01.01.1601 00:00:00
LastWriteTime     : 01.01.1601 01:00:00
LastWriteTimeUtc  : 01.01.1601 00:00:00
Attributes        : -1
```

通过将通用数据类型（如字符串）转换为更适当的数据类型，访问单个信息变得更加容易。例如，如果您想解析文件路径，通过将字符串转换为`[System.Io.FileInfo]`，您可以轻松地拆分路径并提取驱动器、父文件夹、文件名、没有扩展名的文件名或扩展名：

```powershell
PS> $path = [System.IO.FileInfo]'c:\test\somefile.txt'

PS> $path.DirectoryName
c:\test

PS> $path.FullName
c:\test\somefile.txt

PS> $path.Name
somefile.txt

PS> $path.BaseName
somefile

PS> $path.Extension
.txt

PS> $path.Directory.Parent

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d--hs-        15.02.2023     17:33                c:\



PS> $path.Directory.Parent.Name
c:\
```
<!--本文国际来源：[Using Appropriate DataTypes (Part 1)](https://blog.idera.com/database-tools/powershell/powertips/using-appropriate-datatypes-part-1/)-->

