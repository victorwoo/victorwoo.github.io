---
layout: post
date: 2021-03-16 00:00:00
title: "PowerShell 技能连载 - 探索文件夹结构（第 1 部分）"
description: PowerTip of the Day - Exploring Folder Structures (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是一个快速示例，说明了如何发现文件夹结构。本示例采用任何根文件夹路径，并递归遍历其子文件夹。

对于每个子文件夹，将返回一个新的自定义对象，其中包含文件和子文件夹计数以及相对的子文件夹路径：

```powershell
# specify the folder that you want to discover
# $home is the root folder of your user profile
# you can use any folder: $path = 'c:\somefolder'
$path = $HOME

# find all subfolders...
Get-ChildItem $path -Directory -Recurse -ErrorAction Ignore   |
ForEach-Object {
  # return custom object with relative subfolder path and
  # file count
  [pscustomobject]@{
    # use GetFiles() to find all files in folder:
    FileCount = $_.GetFiles().Count
    FolderCount = $_.GetDirectories().Count
    FullName  = $_.Fullname.Substring($path.Length+1)
  }
}
```

<!--本文国际来源：[Exploring Folder Structures (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/exploring-folder-structures-part-1)-->

