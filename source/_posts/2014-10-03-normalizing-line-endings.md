layout: post
date: 2014-10-03 11:00:00
title: "PowerShell 技能连载 - 格式化行尾符"
description: PowerTip of the Day - Normalizing Line Endings
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
_适用于 PowerShell 所有版本_

当您从 Internet 中下载了文件之后，您也许会遇到文件无法在编辑器中正常打开的情况。最常见的是，由于非正常行尾符导致的。

以下是这个问题的一个例子。在前一个技能里我们演示了如何下载一份 MAC 地址的厂家清单。当下载完成后用记事本打开它时，换行都消失了：

    $url = 'http://standards.ieee.org/develop/regauth/oui/oui.txt'
    $outfile = "$home\vendorlist.txt"
    
    Invoke-WebRequest -Uri $url -OutFile $outfile
    
    Invoke-Item -Path $outfile 

要修复这个文件，只需要使用这段代码：

    $OldFile = "$home\vendorlist.txt"
    $NewFile = "$home\vendorlistGood.txt"
    
    Get-Content $OldFile | Set-Content -Path $NewFile
    
    notepad $NewFile 

`Get-Content` 能够检测非标准的行尾符，所以结果是各行的字符串数组。当您将这些行写入一个新文件时，一切都会变正常，因为 `Set-Content` 会使用缺省的行尾符。

<!--more-->
本文国际来源：[Normalizing Line Endings](http://community.idera.com/powershell/powertips/b/tips/posts/normalizing-line-endings)
