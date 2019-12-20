---
layout: post
date: 2019-12-18 00:00:00
title: "PowerShell 技能连载 - 退出 PowerShell 管道（第 1 部分：Select-Object）"
description: 'PowerTip of the Day - Aborting the PowerShell Pipeline (Part 1: Select-Object)'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有些时候人工退出 PowerShell 管道可以节约很多时间。例如，在开始递归搜索之前不能确切地知道一个文件所在的位置，当搜到文件的时候立刻停止。当找到文件以后没理由继续搜索其它目录。

下面是一个演示该问题的场景：假设您在 Windows 文件夹中的某个地方搜索一个名为 "ngen.log" 的文件：

```powershell
$fileToSearch = 'ngen.log'

Get-ChildItem -Path c:\Windows -Recurse -ErrorAction SilentlyContinue -Filter $fileToSearch
```

PowerShell 将会查找这个文件但是找到之后还会继续搜索目录树的其它部分，这会消耗很多时间。

如果您知道需要查找结果的个数，那么可以当搜到指定数量的结果后使用 `Select-Object` 来立刻退出管道。

```powershell
$fileToSearch = 'ngen.log'
Get-ChildItem -Path c:\Windows -Recurse -ErrorAction SilentlyContinue -Filter $fileToSearch |
Select-Object -First 1
```

在这个例子中，当找到文件时 PowerShell 立即退出。作为最佳实践，如果您事先知道需要从命令中查找多少个结果，那么在管道尾部添加 `Select-Object`，并且用 `-First` 参数来告诉 PowerShell 需要的结果个数。

<!--本文国际来源：[Aborting the PowerShell Pipeline (Part 1: Select-Object)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/aborting-the-powershell-pipeline-part-1-select-object)-->

