---
layout: post
date: 2021-03-12 00:00:00
title: "PowerShell 技能连载 - 保存文本文件时去掉 BOM"
description: PowerTip of the Day - Saving Text Files without BOM
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 Windows上，默认情况下，许多 cmdlet 使用BOM (Byte Order Mask) 编码对文本文件进行编码。 BOM 会在文本文件的开头写入一些额外的字节，以标记用于写入文件的编码。

不幸的是，BOM 编码在 Windows 世界之外并未得到很好的采用。如今，当您在 Windows 系统上保存文本文件并将其上传到 GitHub 时，BOM 编码可能会损坏文件或使其完全不可读。

以下是一段可用于确保以与 Linux 兼容的方式，在不使用 BOM 的情况下保存文本文件：

```powershell
$outpath = "$env:temp\nobom.txt"
$text = 'This is the text to write to disk.'
$Utf8NoBomEncoding = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllLines($outpath, $text, $Utf8NoBomEncoding)
$outpath
```

<!--本文国际来源：[Saving Text Files without BOM](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/saving-text-files-without-bom)-->

