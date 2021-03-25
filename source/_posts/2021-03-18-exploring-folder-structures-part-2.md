---
layout: post
date: 2021-03-18 00:00:00
title: "PowerShell 技能连载 - 探索文件夹结构（第 2 部分）"
description: PowerTip of the Day - Exploring Folder Structures (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
仅使用几个 cmdlet，您就可以检查文件夹结构，即返回文件夹树中子文件夹的大小。

这是一个返回文件夹总大小和相对大小的示例：

```powershell
# specify the folder that you want to discover
# $home is the root folder of your user profile
# you can use any folder: $path = 'c:\somefolder'
$path = $HOME

# specify the depth you want to examine (the number of levels you'd like
# to dive into the folder tree)
$Depth = 3

# find all subfolders...
Get-ChildItem $path -Directory -Recurse -ErrorAction Ignore -Depth $Depth  |
ForEach-Object {
  Write-Progress -Activity 'Calculating Folder Size' -Status $_.FullName

  # return the desired information as a new custom object
  [pscustomobject]@{
    RelativeSize = Get-ChildItem -Path $_.FullName -File -ErrorAction Ignore | & { begin { $c = 0 } process { $c += $_.Length } end { $c }}
    TotalSize = Get-ChildItem -Path $_.FullName -File -Recurse -ErrorAction Ignore | & { begin { $c = 0 } process { $c += $_.Length } end { $c }}
    FullName  = $_.Fullname.Substring($path.Length+1)
  }
}
```

注意代码是如何总结所有文件的大小的：它调用带有开始、处理和结束块的脚本块。 `begin` 块在管道启动之前执行，并将计数变量设置为零。对于每个传入的管道对象，将重复执行该 "`process`" 块，并将 "`Length`" 属性中的文件大小添加到计数器。当管道完成时，将执行 "`end`" 块并返回计算出的总和。

这种方法比使用 `ForEach-Object` 快得多，但仍比使用 `Measure-Object` 快一点。您可以通过这种方式计算各种事物。此代码计算 `Get-Service` 发出的对象数量：

```powershell
# counting number of objects
Get-Service | & { begin { $c = 0 } process { $c++ } end { $c }}
```

请注意，这是一种“流式”方法，无需将所有对象存储在内存中。对于少量对象，您也可以使用“下载”方法并将所有元素存储在内存中，然后使用 `Count` 属性：

```powershell
(Get-Service).Count
```

<!--本文国际来源：[Exploring Folder Structures (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/exploring-folder-structures-part-2)-->

