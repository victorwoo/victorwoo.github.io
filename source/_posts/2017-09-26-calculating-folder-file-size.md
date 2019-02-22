---
layout: post
date: 2017-09-26 00:00:00
title: "PowerShell 技能连载 - 计算文件夹大小"
description: PowerTip of the Day - Calculating Folder File Size
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Measure-Object` 也可以计算属性值的总和。它可以用来计算文件夹大小。以下代码计算用户配置文件（可能需要一些时间，视找到的文件数量而定）。它只是将所有文件的“Length”属性相加：

```powershell
$size = (Get-ChildItem -Path $home -Force -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum

"Folder Size: $sum Bytes"
'Folder Size: {0:n2} MB' -f ($size/1MB)
```

输出的结果类似如下：

    Folder Size: 172945767402 Bytes
    Folder Size: 164.933,94 MB

您可为 `Get-ChildItem` 添加更多的参数，显式地控制哪些文件参加统计。例如这段代码添加了 `-Filter` 参数，并指定文件的扩展名，来只统计用户配置文件目录中找到的 PowerShell 脚本文件的大小。

```powershell
$size = (Get-ChildItem -Path $home -Filter *.ps1 -Force -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum

"Folder Size: $size Bytes"
'Folder Size: {0:n2} MB' -f ($size/1MB)
```

<!--本文国际来源：[Calculating Folder File Size](http://community.idera.com/powershell/powertips/b/tips/posts/calculating-folder-file-size)-->
