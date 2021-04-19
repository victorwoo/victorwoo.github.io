---
layout: post
date: 2021-04-13 00:00:00
title: "PowerShell 技能连载 - 使用 NTFS 流（第 3 部分）"
description: PowerTip of the Day - Working with NTFS Streams (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们解释了 NTFS 流是如何工作的。但是，不可能发现隐藏文件流的名称。在 PowerShell 5及更高版本中，大多数访问文件系统的 cmdlet 都新增了一个名为 `-Stream` 的新参数。有了它，现在访问 NTFS 流变得很简单，因此现在可以重写以前脚本中使用路径名称中的冒号表示的示例，如下所示：

```powershell
# create a sample file
$desktop = [Environment]::GetFolderPath('Desktop')
$path = Join-Path -Path $desktop -ChildPath 'testfile.txt'
'Test' | Out-File -FilePath $Path

# attach hidden info to the file
'this is hidden' | Set-Content -Path $path -Stream myHiddenStream

# get hidden info from the file
Get-Content -Path $path -Stream myHiddenStream

# remove hidden streams
Remove-Item -Path $Path -Stream myHiddenStream

# show file
explorer /select,$Path
```

现在，还可以查看（并发现）隐藏的 NTFS 流。让我们创建一个带有一堆流的示例文件：

```powershell
# create a sample file
$desktop = [Environment]::GetFolderPath('Desktop')
$path = Join-Path -Path $desktop -ChildPath 'testfile.txt'
'Test' | Out-File -FilePath $Path

# attach hidden info to the file
'this is hidden' | Set-Content -Path $path -Stream myHiddenStream
'more info' | Set-Content -Path $path -Stream additionalInfo
'anotherone' | Set-Content -Path $path -Stream 'blanks work, too'
'last' | Set-Content -Path $path -Stream finalStream

# find stream names:
Get-Item -Path $Path -Stream * | Select-Object -Property Stream, Length
```

现在，`Get-Item` 可以暴露 NTFS 流，并且输出可能如下所示：

    Stream           Length
    ------           ------
    :$DATA               14
    additionalInfo       11
    blanks work, too     12
    finalStream           6
    myHiddenStream       16

如您所见，您现在可以发现所有流的名称。流 ":$DATA" 表示文件的“可见的”主要内容。

<!--本文国际来源：[Working with NTFS Streams (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/working-with-ntfs-streams-part-3)-->

