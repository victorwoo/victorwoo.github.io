---
layout: post
date: 2017-06-23 00:00:00
title: "PowerShell 技能连载 - 显示文件夹树"
description: PowerTip of the Day - Displaying Folder Tree
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
PowerShell 对旧的控制台命令是十分友好的，所以要显示文件夹的树形结构，使用旧的 "tree" 命令是十分简单的。它最好工作在一个原生的 PowerShell 控制台中，因为编辑器往往使用不同的字符集。请试试这个命令：

```powershell
PS> Tree $home
```

请确保您是在一个原生的 PowerShell 控制台中或 VSCode 中运行这段代码。您还可以将结果通过管道输出到 clip.exe 并将它粘贴到一个文本文档中：

```powershell
PS> Tree $home | clip.exe
```

<!--more-->
本文国际来源：[Displaying Folder Tree](http://community.idera.com/powershell/powertips/b/tips/posts/displaying-folder-tree)
