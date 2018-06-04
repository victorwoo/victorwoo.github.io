---
layout: post
date: 2018-05-30 00:00:00
title: "PowerShell 技能连载 - 批量重命名图片"
description: PowerTip of the Day - Bulk-Renaming Pictures
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
重命名单个文件可以很容易地用 `Rename-Item` 实现，但是有些时候 cmdlet 参数可以更聪明地使用，帮您实现批量自动化。

例如，假设您的照片文件夹中有大量的照片：

```powershell
$path = [Environment]::GetFolderPath('MyPictures')
Get-ChildItem -Path $path -Filter *.png
```

如果您想对它们命名，例如在前面加一个序号，您需要设计一个循环，例如这样：

```powershell
$path = [Environment]::GetFolderPath('MyPictures')
$counter = 0
$files = Get-ChildItem -Path $path -Filter *.png
$files |
    ForEach-Object {
    $counter++
    $newname = '{0} - {1}' -f $counter, $_.Name
    Rename-Item -Path $_.FullName -NewName $newname  -WhatIf
    }
```

还有一个简单得多的解决方案：`-NewName` 参数也可以接受一个脚本块。每当一个元素通过管道传给 `Rename-Item`，脚本块就会执行一次。代码可以简化为：

```powershell
$path = [Environment]::GetFolderPath('MyPictures')
$counter = 0
$files = Get-ChildItem -Path $path -Filter *.png
$files | Rename-Item -NewName {
    $script:counter++
    '{0} - {1}' -f $counter, $_.Name
    } -WhatIf
```

还有一处重要的区别：`Rename-Item` 执行的脚本块是在它自己的作用域中运行的，所以如果您希望使用一个递增的计数器，那么需要在变量名之前增加一个 `script:`，这样变量就作用在脚本作用域上。

警告：在某些 PowerShell 版本中有一个不友好的 bug，重命名文件将改变 `Get-ChildItem` 的输出，所以如果您直接将 `Get-ChildItem` 的结果通过管道传给 `Rename-Item`，您可能会遇到无限死循环，文件会一直被重命名直到文件路径长度超过限制。要安全地使用它，请确保在将变量传给 `Rename-Item` 之前将 `Get-ChildItem` 的结果保存到变量中！

<!--more-->
本文国际来源：[Bulk-Renaming Pictures](http://community.idera.com/powershell/powertips/b/tips/posts/bulk-renaming-pictures)
