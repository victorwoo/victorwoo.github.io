---
layout: post
date: 2018-11-19 00:00:00
title: "PowerShell 技能连载 - 查找所有二级深度的文件"
description: PowerTip of the Day - Find All Files Two Levels Deep
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是另一个文件系统的任务：列出一个文件夹结构中所有 *.log 文件，但最多只包含 2 级文件夹深度：

```powershell
Get-ChildItem -Path c:\windows -Filter *.log -Recurse -Depth 2 -File -Force -ErrorAction SilentlyContinue |
  Select-Object -ExpandProperty FullName
```

幸运的是，PowerShell 5 对 `Get-ChildItem` 命令增加了好用的 `-Depth` 选项。

<!--本文国际来源：[Find All Files Two Levels Deep](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/find-all-files-two-levels-deep)-->
