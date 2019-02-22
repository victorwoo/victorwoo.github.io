---
layout: post
date: 2017-01-18 00:00:00
title: "PowerShell 技能连载 - 批量重命名照片"
description: PowerTip of the Day - Bulk Renaming Photos
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是一个快速批量重命名文件的方法，可以用于照片或其它文件。请看：

```powershell
#requires -Version 1.0
$Path = "$home\Pictures"
$Filter = '*.jpg'

Get-ChildItem -Path $Path -Filter $Filter | 
  Rename-Item -NewName {$_.name -replace 'DSC','TEST'}
```

只需要调整路径和过滤器，使之指向所需的文件即可。在这个例子中，照片文件夹中的所有 *.jpg 文件中，关键字 "DSC" 将被替换成 "TEST"。请在使用前将脚本的参数改为您想要的。

要递归地重命名文件，请向 `Get-ChildItem` 命令添加 `-Recurse` 参数。但是，请小心。这一小段代码可能会导致一不小心对无数文件重命名。

<!--本文国际来源：[Bulk Renaming Photos](http://community.idera.com/powershell/powertips/b/tips/posts/bulk-renaming-photos)-->
