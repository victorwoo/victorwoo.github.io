---
layout: post
date: 2016-12-05 00:00:00
title: "PowerShell 技能连载 - 创建文件共享"
description: PowerTip of the Day - Creating File Shares
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 Server 2012 R2 和 Windows .1 中，有许多有用的新模块，包含了许多新的 cmdlet，例如 `New-SmbShare` 可以快速地创建新的文件共享。

如果您没有这些 cmdlet，您通常可以使用 WMI。那需要更多的研究和搜索，但是一旦您有了一个代码模板，它就能很好地工作了。

例如要以管理员身份创建一个新的文件共享，试试以下代码：

```powershell
$share = [wmiclass]"Win32_Share" 
$path = 'c:\logs'
$name = 'LogShare'
$maxallowed = 10
$description = 'Place log files here'

$share.Create( $path, $name, 0, $maxallowed,$description,$null,$null)
```
<!--本文国际来源：[Creating File Shares](http://community.idera.com/powershell/powertips/b/tips/posts/creating-file-shares)-->
