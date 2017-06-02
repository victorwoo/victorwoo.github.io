---
layout: post
title: "PowerShell 技能连载 - 批量重命名文件"
date: 2014-06-11 00:00:00
description: PowerTip of the Day - Bulk File Renaming
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
假设在一个文件夹中有一大堆脚本（或照片、日志等任意文件），并且您想要重命名所有的文件。比如新文件名的格式为固定前缀 + 自增的编号。

以下是实现方法。

这个例子将重命名指定文件夹中所有扩展名为 .ps1 的 PowerShell 脚本。新文件名为 powershellscriptX.ps1，其中“X”为自增的数字。

请注意脚本禁止了真正的重命名操作。如果要真正地重命名文件，请移除 `-WhatIf` 参数，但必须非常小心！如果您敲错一个变量或使用了错误的文件夹路径，那么您的脚本将会十分开心地重命名成千上万个错误的文件。

    $Path = 'c:\temp'
    $Filter = '*.ps1'
    $Prefix = 'powershellscript'
    $Counter = 1
    
    Get-ChildItem -Path $Path -Filter $Filter -Recurse |
      Rename-Item -NewName {
        $extension = [System.IO.Path]::GetExtension($_.Name)
        '{0}{1}.{2}' -f $Prefix, $script:Counter, $extension
        $script:Counter++
       } -WhatIf

<!--more-->
本文国际来源：[Bulk File Renaming](http://community.idera.com/powershell/powertips/b/tips/posts/bulk-file-renaming)
