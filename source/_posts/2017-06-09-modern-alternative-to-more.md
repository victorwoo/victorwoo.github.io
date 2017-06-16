---
layout: post
date: 2017-06-09 00:00:00
title: "PowerShell 技能连载 - More 命令的现代版替代品"
description: PowerTip of the Day - Modern Alternative to More
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
在 PowerShell 控制台中，您仍然可以用 more 管道，就像在 cmd.exe 中一样一页一页查看结果。然而，more 不支持实时管道，所以所有数据需要首先收集好。这将占用很长时间和内存：

```powershell
dir c:\windows -Recurse -ea 0  | more
```

一个更好的方法是使用 PowerShell 自带的分页功能：

```powershell
dir c:\windows -Recurse -ea 0  | Out-Host -Paging
```

请注意这些都需要一个真正的控制台窗口，而在图形界面的宿主中不能工作。

<!--more-->
本文国际来源：[Modern Alternative to More](http://community.idera.com/powershell/powertips/b/tips/posts/modern-alternative-to-more)
