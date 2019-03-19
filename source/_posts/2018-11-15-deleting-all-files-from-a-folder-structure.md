---
layout: post
date: 2018-11-15 00:00:00
title: "PowerShell 技能连载 - 从目录结构中删除所有文件"
description: PowerTip of the Day - Deleting All Files from a Folder Structure
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有些任务听起来复杂，实际上并没有那么复杂。假设我们需要清除一个目录结构，移除所有文件，而留下空白的文件夹。我们进一步假设有一些文件位于白名单上，不应移除。如果用 PowerShell，那么实现起来很容易：

```powershell
# Task:
# remove all files from a folder structure, but keep all folders,
# and keep all files on a whitelist

$Path = "c:\sample"
$WhiteList = "important.txt", "something.csv"

Get-ChildItem -Path $Path -File -Exclude $WhiteList -Recurse -Force |
    # remove -WhatIf if you want to actually delete files
# ATTENTION: test thoroughly before doing this!
# you may want to add -Force to Remove-Item to forcefully remove files
    Remove-Item -WhatIf
```

<!--本文国际来源：[Deleting All Files from a Folder Structure](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/deleting-all-files-from-a-folder-structure)-->
