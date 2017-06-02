---
layout: post
date: 2017-05-17 00:00:00
title: "PowerShell 技能连载 - 创建随机的 MAC 地址"
description: PowerTip of the Day - Creating Random MAC Addresses
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
如果您只是需要一系列随机生成的 MAC 地址，而不关心这些地址是否合法，以下是一行实现代码：

```powershell
PS> (0..5 | ForEach-Object { '{0:x}{1:x}' -f (Get-Random -Minimum 0 -Maximum 15),(Get-Random -Minimum 0 -Maximum 15)})  -join ':'

a5:66:07:6d:d9:18

PS> (0..5 | ForEach-Object { '{0:x}{1:x}' -f (Get-Random -Minimum 0 -Maximum 15),(Get-Random -Minimum 0 -Maximum 15)})  -join ':'

3c:c8:4e:e3:75:6c
```

将它加到一个循环中，就可以生成任意多个 MAC 地址：

```powershell
PS> 0..100 | ForEach-Object { (0..5 | Foreach-Object { '{0:x}{1:x}' -f (Get-Random -Minimum 0 -Maximum 15),(Get-Random -Minimum 0 -Maximum 15)})  -join ':' }

bc:38:3a:91:a9:79
36:55:3a:a0:3d:c4
6d:2c:91:ae:01:35
ec:01:11:42:a7:09
e7:0b:24:d3:14:1d
(...)
```

<!--more-->
本文国际来源：[Creating Random MAC Addresses](http://community.idera.com/powershell/powertips/b/tips/posts/creating-random-mac-addresses)
