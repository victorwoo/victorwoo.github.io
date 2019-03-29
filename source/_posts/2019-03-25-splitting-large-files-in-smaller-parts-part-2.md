---
layout: post
date: 2019-03-25 00:00:00
title: "PowerShell 技能连载 - 将大文件拆分成小片段（第 2 部分）"
description: PowerTip of the Day - Splitting Large Files in Smaller Parts (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们介绍了如何讲一个大文件分割成小块。今天，我们将完成一个函数，它能将这些小文件合并成原来的文件。

假设您已经按上一个技能用 `Split-File` 将一个大文件分割成多个小文件。现在拥有了一大堆扩展名为 ".part" 的文件。这是上一个技能的执行结果：

```powershell
PS> dir "C:\Users\tobwe\Downloads\*.part"


    Folder: C:\Users\tobwe\Downloads


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----       03.03.2019     16:25        6291456 Woman tries putting gas in a Tesla.mp4.00.part
-a----       03.03.2019     16:25        6291456 Woman tries putting gas in a Tesla.mp4.01.part
-a----       03.03.2019     16:25        6291456 Woman tries putting gas in a Tesla.mp4.02.part
-a----       03.03.2019     16:25        5207382 Woman tries putting gas in a Tesla.mp4.03.part
```

要合并这些部分，请使用我们新的 `Join-File` 函数（不要和内置的 `Join-Path` 命令混淆）。让我们先看看它是如何工作的：

```powershell
PS C:\> Join-File -Path "C:\Users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4" -DeletePartFiles -Verbose
VERBOSE: processing C:\Users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4.00.part...
VERBOSE: processing C:\Users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4.01.part...
VERBOSE: processing C:\Users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4.02.part...
VERBOSE: processing C:\Users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4.03.part...
VERBOSE: Deleting part files...

PS C:\>
```

只需要提交文件名（不需要分片编号和分片扩展名）。当您指定了 `-DeletePartFiles` 参数，函数将会在创建完原始文件之后删除分片文件。

要使用 `Join-File` 函数，需要先运行这段代码：

```powershell
function Join-File
{

    param
    (
        [Parameter(Mandatory)]
        [String]
        $Path,

        [Switch]
        $DeletePartFiles
    )

    try
    {
        # get the file parts
        $files = Get-ChildItem -Path "$Path.*.part" |
        # sort by part
        Sort-Object -Property {
            # get the part number which is the "extension" of the
            # file name without extension
            $baseName = [IO.Path]::GetFileNameWithoutExtension($_.Name)
            $part = [IO.Path]::GetExtension($baseName)
            if ($part -ne $null -and $part -ne '')
            {
                $part = $part.Substring(1)
            }
            [int]$part
        }
        # append part content to file
        $writer = [IO.File]::OpenWrite($Path)
        $files |
        ForEach-Object {
            Write-Verbose "processing $_..."
            $bytes = [IO.File]::ReadAllBytes($_)
            $writer.Write($bytes, 0, $bytes.Length)
        }
        $writer.Close()

        if ($DeletePartFiles)
        {
            Write-Verbose "Deleting part files..."
            $files | Remove-Item
        }
    }
    catch
    {
        throw "Unable to join part files: $_"
    }
}
```

今日知识点：

* 使用 `[IO.Path]` 类来分割文件路径
* 使用 `[IO.file]` 类以字节的方式存取文件内容
* 使用 `OpenWrite()` 以字节的方式写入文件

<!--本文国际来源：[Splitting Large Files in Smaller Parts (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/splitting-large-files-in-smaller-parts-part-2)-->

