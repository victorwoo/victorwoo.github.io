---
layout: post
date: 2021-06-22 00:00:00
title: "PowerShell 技能连载 - 对文本做哈希"
description: PowerTip of the Day - Hashing Text
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 附带了 `Get-FileHash` 命令，它读取文件并计算唯一的哈希值。这非常适合测试文件是否具有相同的内容。但是，无法对纯文本进行哈希处理。

当然，您可以将要哈希的文本写入文件，然后使用 `Get-FileHash`。

更好的方法是 `Get-FileHash` 的一个很少人知道的功能。除了传入文件路径之外，您还可以提交所谓的 "`MemoryStream`"，当您将文本加载内存流，再调用命令，就能得到哈希值：

```powershell
$text = 'this is a test'

$memoryStream = [System.IO.MemoryStream]::new()
$streamWriter = [System.IO.StreamWriter]::new($MemoryStream)
$streamWriter.Write($text)
$streamWriter.Flush()
$memoryStream.Position = 0
$hash = Get-FileHash -InputStream $MemoryStream -Algorithm 'SHA1'
$memoryStream.Dispose()
$streamWriter.Dispose()
$hash.Hash
```

只是不要忘记在使用后处理 `MemoryStream` 和 `StreamWriter` 对象以释放内存。

<!--本文国际来源：[Hashing Text](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/hashing-text)-->

