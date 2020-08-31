---
layout: post
date: 2020-08-28 00:00:00
title: "PowerShell 技能连载 - 删除多个子文件夹"
description: PowerTip of the Day - Deleting Multiple Subfolders
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有时，可能有必要删除给定文件夹中的一组子文件夹。这是一段简单的代码，可从文件夹名称列表中删除文件夹。

警告：此代码将删除 `$list` 中列出的子文件夹，而无需进一步确认。如果子文件夹没有退出，则什么也不会发生。

```powershell
# the folder that contains the subfolders to remove
# (adjust to your needs)
$parentFolder = $env:userprofile

# list of folder names to remove (adjust to your needs)
$list = 'scratch', 'temp', 'cache'

# delete the folders found in the list
Get-ChildItem $parentFolder -Directory |
  Where-Object name -in $list |
  Remove-Item -Recurse -Force -Verbose
```

如果要删除父文件夹内任何位置的子文件夹，请通过向 `Get-ChildItem` 添加 `-Recurse` 来扩展搜索以通过子文件夹进行递归。

下面的示例在父文件夹的文件夹结构内的任何位置删除 `$list` 中的子文件夹。

请注意，这样做可能有风险，因为您现在正在查找可能并不是由您所有并控制的文件夹内的子文件夹，这就是为什么我们向 `-Remove-Item` 添加 `-WhatIf` 的原因：该代码实际上不会删除子文件夹，而只是报告其内容完成了。如果您知道自己在做什么，请删除该参数：

```powershell
# the folder that contains the subfolders to remove
$parentFolder = $env:userprofile
# list of folder names to remove
$list = 'scratch', 'temp', 'cache'

# delete the folders found in the list
Get-ChildItem $parentFolder -Directory -Recurse |
  Where-Object name -in $list |
  Remove-Item -Recurse -Verbose -WhatIf
```

<!--本文国际来源：[Deleting Multiple Subfolders](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/deleting-multiple-subfolders)-->

