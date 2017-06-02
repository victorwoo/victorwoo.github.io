---
layout: post
date: 2015-04-10 11:00:00
title: "PowerShell 技能连载 - 批量重命名文件"
description: PowerTip of the Day - Bulk Renaming Files
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
假设您有一整个文件夹的图片文件，并希望它们的名字标准化。

这个脚本演示了如何批量重命名图片文件：

    $i = 0
    
    Get-ChildItem -Path c:\pictures -Filter *.jpg |
    ForEach-Object {
        $extension = $_.Extension
        $newName = 'pic_{0:d6}{1}' -f  $i, $extension
        $i++
        Rename-Item -Path $_.FullName -NewName $newName 
    }

文件夹中所有的 JPG 文件都被重命名了。新的文件名是“pic_”加上四位数字。

您可以很容易地修改脚本来重命名其它类型的文件，或是使用其它文件名模板。

<!--more-->
本文国际来源：[Bulk Renaming Files](http://community.idera.com/powershell/powertips/b/tips/posts/bulk-re-naming-files)
