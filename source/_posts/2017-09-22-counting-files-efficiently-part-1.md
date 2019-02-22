---
layout: post
date: 2017-09-22 00:00:00
title: "PowerShell 技能连载 - 高效统计文件数量（第一部分）"
description: PowerTip of the Day - Counting Files Efficiently (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
一个快速但浪费的统计文件数量的方法如下：

```powershell
(Get-ChildItem -Path c:\windows).Count
```

但是，这将产生一些内存负担，因为在 `Count` 属性能够获取对象数量之前，所有文件将会堆在内存里。当进行递归搜索时，这种情况更严重。

一个节约非常多资源的方法是类似这样使用 `Measure-Object`：

```powershell
(Get-ChildItem -Path c:\windows | Measure-Object).Count
```

这里使用流来获取项目的数量，所以 PowerShell 不需要在内存中存储所有文件。

<!--本文国际来源：[Counting Files Efficiently (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/counting-files-efficiently-part-1)-->
