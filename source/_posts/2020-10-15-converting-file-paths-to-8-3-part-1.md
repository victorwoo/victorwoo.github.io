---
layout: post
date: 2020-10-15 00:00:00
title: "PowerShell 技能连载 - 将文件路径转为 8.3 格式（第 1 部分）"
description: PowerTip of the Day - Converting File Paths to 8.3 (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
许多年前，文件和文件夹名称最多包含 8 个字符，而这些短路径名称仍然存在。它们甚至仍然有用：短路径名永远不会包含空格和其他特殊字符，因此永远不需要引号或转义。当路径变得很长时，短路径也可能会有所帮助。

但是，如何获得默认长路径名称的短路径名称呢？一种方法是使用 Windows 脚本宿主使用的旧 COM 组件：

```powershell
# take any path
# in this example, I am taking the path where Powershell 7 is installed
# this requires that PowerShell 7 in fact is installed.
# You can use any other path as well
$path = (Get-Command -Name pwsh).Source

"Long path: $path"

# convert it to 8.3 short name
$shortPath = (New-Object -ComObject Scripting.FileSystemObject).GetFile($path).ShortPath
"Short path: $shortPath"
```

结果看起来像这样：

    Long path: C:\Program Files\PowerShell\7\pwsh.exe
    Short path: C:\PROGRA~1\POWERS~1\7\pwsh.exe

<!--本文国际来源：[Converting File Paths to 8.3 (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/converting-file-paths-to-8-3-part-1)-->

