---
layout: post
date: 2021-04-09 00:00:00
title: "PowerShell 技能连载 - 使用NTFS流（第 2 部分）"
description: PowerTip of the Day - Working with NTFS Streams (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技巧中，我们解释了 NTFS 流如何存储有关文件的其他数据，这引发了一个问题，即如何删除此类流或首先发现隐藏的 NTFS 流。

要删除隐藏的命名流，请使用 `Remove-Item`——就像您要删除整个文件一样。这是一个简单的示例：

```powershell
# create a sample file
$path = "$env:temp\test.txt"
'Test' | Out-File -FilePath $Path

# attach hidden info to the file
'this is hidden' | Set-Content -Path "${path}:myHiddenStream"

# get hidden info from the file
Get-Content -Path "${path}:myHiddenStream"

# remove hidden streams
Remove-Item -Path "${path}:myHiddenStream"

# stream is gone, this raises an error:
Get-Content -Path "${path}:myHiddenStream"

# file with main stream is still there:
explorer /select,$Path
```

尽管您可以像创建单个文件一样创建和删除 NTFS 流，只需添加一个冒号和流名称即可，但没有找到流名称的简单方法。至少不是我们在这里访问流的方式。在第 3 部分中，我们最终将发现隐藏的流名称。

<!--本文国际来源：[Working with NTFS Streams (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/working-with-ntfs-streams-part-2)-->

