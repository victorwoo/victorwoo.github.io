---
layout: post
date: 2019-03-22 00:00:00
title: "PowerShell 技能连载 - 将大文件拆分成小片段（第 1 部分）"
description: PowerTip of the Day - Splitting Large Files in Smaller Parts (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 可以将大文件拆分成多个小片段，例如将它们做为电子邮件附件发送。今天，我们关注如何分割文件。在下一个技能中，我们将演示如何将各个部分合并在一起。

要将大文件分割成小片段，我们创建了一个名为 `Split-File` 的函数。它工作起来类似这样：

```powershell
PS> Split-File -Path "C:\Users\tobwe\Downloads\Woman putting gas in Tesla.mp4" -PartSizeBytes 6MB -Verbose
VERBOSE: saving to C:\Users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4.00.part...
VERBOSE: saving to C:\Users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4.01.part...
VERBOSE: saving to C:\Users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4.02.part...
VERBOSE: saving to C:\Users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4.03.part...

PS C:\>
```

`-PartSizeByte` 参数设置最大的分片尺寸，在我们的例子中是 6MB。当您指定了 `-Verbose` 参数，该函数将在创建分片文件时显示分片文件名。

要使用 `Split-File` 函数，您需要运行以下代码：

```powershell
function Split-File
{

    param
    (
        [Parameter(Mandatory)]
        [String]
        $Path,

        [Int32]
        $PartSizeBytes = 1MB
    )

    try
    {
        # get the path parts to construct the individual part
        # file names:
        $fullBaseName = [IO.Path]::GetFileName($Path)
        $baseName = [IO.Path]::GetFileNameWithoutExtension($Path)
        $parentFolder = [IO.Path]::GetDirectoryName($Path)
        $extension = [IO.Path]::GetExtension($Path)

        # get the original file size and calculate the
        # number of required parts:
        $originalFile = New-Object System.IO.FileInfo($Path)
        $totalChunks = [int]($originalFile.Length / $PartSizeBytes) + 1
        $digitCount = [int][Math]::Log10($totalChunks) + 1

        # read the original file and split into chunks:
        $reader = [IO.File]::OpenRead($Path)
        $count = 0
        $buffer = New-Object Byte[] $PartSizeBytes
        $moreData = $true

        # read chunks until there is no more data
        while($moreData)
        {
            # read a chunk
            $bytesRead = $reader.Read($buffer, 0, $buffer.Length)
            # create the filename for the chunk file
            $chunkFileName = "$parentFolder\$fullBaseName.{0:D$digitCount}.part" -f $count
            Write-Verbose "saving to $chunkFileName..."
            $output = $buffer

            # did we read less than the expected bytes?
            if ($bytesRead -ne $buffer.Length)
            {
                # yes, so there is no more data
                $moreData = $false
                # shrink the output array to the number of bytes
                # actually read:
                $output = New-Object Byte[] $bytesRead
                [Array]::Copy($buffer, $output, $bytesRead)
            }
            # save the read bytes in a new part file
            [IO.File]::WriteAllBytes($chunkFileName, $output)
            # increment the part counter
            ++$count
        }
        # done, close reader
        $reader.Close()
    }
    catch
    {
        throw "Unable to split file ${Path}: $_"
    }
}
```

明天我们将研究反向操作：如何将所有分片组合成原始文件。

今日知识点：

* 用 `[IO.Path]` 类来分割文件路径。
* 用 `[IO.File]` 类在字节级别处理文件内容。
* 用 `Read()` 函数将字节写入文件。

<!--本文国际来源：[Splitting Large Files in Smaller Parts (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/splitting-large-files-in-smaller-parts-part-1)-->

