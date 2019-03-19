---
layout: post
date: 2014-12-24 12:00:00
title: "PowerShell 技能连载 - 创建一大堆测试文件"
description: PowerTip of the Day - Creating Huge Dummy Files
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

如果您需要对系统进行压力测试，或因为别的原因需要大量测试文件，以下是在瞬间创建大量文件（可以是大文件）的代码：

    $Path = "$env:temp\hugefile.txt"
    $Size = 200MB

    $stream = New-Object System.IO.FileStream($Path, [System.IO.FileMode]::CreateNew)
    $stream.Seek($Size, [System.IO.SeekOrigin]::Begin)
    $stream.WriteByte(0)
    $Stream.Close()

    explorer.exe "/select,$Path"

<!--本文国际来源：[Creating Huge Dummy Files](http://community.idera.com/powershell/powertips/b/tips/posts/creating-huge-dummy-files)-->
