---
layout: post
date: 2017-06-01 00:00:00
title: "PowerShell 技能连载 - 安全地删除数据"
description: PowerTip of the Day - Safely Deleting Data
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
要安全地删除文件、文件夹，或整个驱动器，PowerShell 可以使用内置的 cipher.exe 工具。这行代码可以安全地删除旧的用户配置文件：

```powershell
Cipher.exe /w:c:\Users\ObsoleteUser
```

请注意要删除的文件夹路径和参数 /w 之间需要用一个 `:` 分隔。删除数据需要消耗一定时间：Windows 要多次覆盖整个数据内容，以确保它不可恢复。

<!--本文国际来源：[Safely Deleting Data](http://community.idera.com/powershell/powertips/b/tips/posts/safely-deleting-data)-->
