---
layout: post
date: 2017-06-02 00:00:00
title: "PowerShell 技能连载 - 映射网络驱动器"
description: PowerTip of the Day - Mapping Network Drives
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
PowerShell 提供很多种方式来连接到 SMB 文件共享。以下是三种不同的方法：

```powershell
# adjust path to point to your file share
$UNCPath = '\\server\share'

net use * $UNCPath 
New-PSDrive -Name y -PSProvider FileSystem -Root $UNCPath -Persist
New-SmbMapping -LocalPath 'x:' -RemotePath  $UNCPath
```

Net.exe 是最多功能的方法，在 PowerShell 的所有版本中都有效。通过传入一个 "*"，它自动选择下一个有效的驱动器盘符。

`New-PSDrive` 从 PowerShell 3 起支持 SMB 共享。`New-SmbMapping` 需要 SmbShare 模块并且现在看来有点古怪：重启后才能在 Windows Explorer 中显示该驱动器。

<!--more-->
本文国际来源：[Mapping Network Drives](http://community.idera.com/powershell/powertips/b/tips/posts/mapping-network-drives)
