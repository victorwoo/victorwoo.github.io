---
layout: post
date: 2018-11-16 00:00:00
title: "PowerShell 技能连载 - 删除所有指定层级下的子文件夹"
description: PowerTip of the Day - Deleting All Subfolders Below A Given Level
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
以下是另一个听起来复杂，但实际上并没有那么复杂的文件系统任务。假设您需要移除某个文件系统指定层级之下所有文件夹。以下是实现方法：

```powershell
# Task:

# remove all folders one level below the given path
Get-ChildItem -Path "c:\sample\*\" -Directory -Recurse | 
    # remove -WhatIf to actually delete
    # ATTENTION: test thoroughly before doing this!
    # you may want to add -Force to Remove-Item to forcefully delete
    Remove-Item -Recurse -WhatIf
```

只需要在路径中使用 "`*`"。要删除某个指定路径下的两层之下的目录，相应地做以下调整：

```powershell
# Task:

# remove all folders TWO levels below the given path
Get-ChildItem -Path "c:\sample\*\*\" -Directory -Recurse | 
    # remove -WhatIf to actually delete
    # ATTENTION: test thoroughly before doing this!
    # you may want to add -Force to Remove-Item to forcefully delete
    Remove-Item -Recurse -WhatIf
```

<!--more-->
本文国际来源：[Deleting All Subfolders Below A Given Level](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/deleting-all-subfolders-below-a-given-level)
