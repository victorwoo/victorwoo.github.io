---
layout: post
date: 2019-03-26 00:00:00
title: "PowerShell 技能连载 - 将大文件拆分成小片段（第 3 部分）"
description: PowerTip of the Day - Splitting Large Files in Smaller Parts (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们延时了如何使用 PowerShell 将文件分割成小的分片，以及如何将这些分片合并起来，重建原始文件。我们甚至进一步扩展了这些函数，将它们发布到 PowerShell Gallery。所以要分割和合并文件，只需要获取该模块并像这样安装：

```powershell
PS> Install-Module -Name FileSplitter -Repository PSGallery -Scope CurrentUser -Force
```

现在当您需要将一个大文件分割成多个小片时，只需要运行以下代码：

```powershell
PS C:\> Split-File -Path 'C:\movies\Woman tries putting gas in a Tesla.mp4' -PartSizeBytes 10MB -AddSelfExtractor -Verbose
VERBOSE: saving to C:\users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4.0.part...
VERBOSE: saving to C:\users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4.1.part...
VERBOSE: saving to C:\users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4.2.part...
VERBOSE: Adding extractor scripts...

PS C:\
```

`Split-Path` 将文件分割成不超过 `PartSizeByte` 参数指定的大小。感谢 `-AddSelfExtractor`，它还添加了一个可以将分片文件合并为原始文件的脚本，以及一个双击即可执行合并操作的快捷方式。以下是您获得的文件：：

```powershell
PS C:\users\tobwe\Downloads> dir *gas*


    Folder: C:\movies


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----       03.03.2019     18:11           2004 Extract Woman tries putting gas in a Tesla.mp4.lnk
-a----       03.03.2019     16:54       24081750 Woman tries putting gas in a Tesla.mp4
-a----       03.03.2019     18:11       10485760 Woman tries putting gas in a Tesla.mp4.0.part
-a----       03.03.2019     18:11       10485760 Woman tries putting gas in a Tesla.mp4.1.part
-a----       03.03.2019     18:11        3110230 Woman tries putting gas in a Tesla.mp4.2.part
-a----       03.03.2019     18:11           3179 Woman tries putting gas in a Tesla.mp4.3.part.ps1
```

如您所见，有许多包含 .part 扩展名的文件，以及一个扩展名为 .part.ps1 的文件。后者是合并脚本。当您运行这个脚本时，它读取这些分片文件并重建原始文件，然后将删除所有分片文件以及自身。最终，该合并脚本将打开文件管理器并选中恢复的文件。

由于对于普通用户来说可能不了解如何运行 PowerShell 脚本，所以还有一个额外的名为 "Extract..."，扩展名为 .lnk 的文件。这是一个快捷方式文件。当用户双击这个文件，它将运行 PowerShell 合并脚本并恢复原始文件。

如果您希望手工恢复原始文件，您可以手工调用 `Join-File`：

```powershell
PS> Join-File -Path 'C:\users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4' -Verbose -DeletePartFiles
VERBOSE: processing C:\users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4.0.part...
VERBOSE: processing C:\users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4.1.part...
VERBOSE: processing C:\users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4.2.part...
VERBOSE: Deleting part files...

PS>
```

<!--本文国际来源：[Splitting Large Files in Smaller Parts (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/splitting-large-files-in-smaller-parts-part-3)-->

