---
layout: post
date: 2021-04-07 00:00:00
title: "PowerShell 技能连载 - 使用 NTFS 流（第 1 部分）"
description: PowerTip of the Day - Working with NTFS Streams (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 NTFS 文件系统上，您可以将其他信息存储在隐藏的文件流中。传统上，PowerShell 通过冒号访问文件流，因此这会将隐藏的文本信息附加到纯文本文件：

```powershell
# create a sample file
$desktop = [Environment]::GetFolderPath('Desktop')
$path = Join-Path -Path $desktop -ChildPath 'testfile.txt'
'Test' | Out-File -FilePath $Path

# attach hidden info to the file
'this is hidden' | Set-Content -Path "${path}:myHiddenStream"

# attach even more hidden info to the file
'this is also hidden' | Set-Content -Path "${path}:myOtherHiddenStream"

# show file
explorer /select,$Path
```

该代码首先确定到您的桌面的路径，然后创建一个示例纯文本文件。

接下来，它在名为 "myHiddenStream" 和 "myOtherHiddenStream" 的两个流中添加隐藏信息。当您在资源管理器中查看文件时，这些流仍然不可见。

PowerShell 仍然可以像下面这样访问这些流：

```powershell
# get hidden info from the file
Get-Content -Path "${path}:myHiddenStream"
Get-Content -Path "${path}:myOtherHiddenStream"
```

请注意，这些流仅存在于使用 NTFS 文件系统的存储中。当您将这些文件复制到其他文件系统时，即使用 exFat 将它们复制到USB记忆棒中，Windows 将显示一个警告对话框，提示所有流将被删除。

<!--本文国际来源：[Working with NTFS Streams (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/working-with-ntfs-streams-part-1)-->

