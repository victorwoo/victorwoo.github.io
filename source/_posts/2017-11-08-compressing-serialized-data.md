---
layout: post
date: 2017-11-08 00:00:00
title: "PowerShell 技能连载 - 压缩序列化的数据"
description: PowerTip of the Day - Compressing Serialized Data
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
通过 `Export-CliXml` 命令可以很方便地将处理结果保存到文件；通过 `Import-CliXml` 命令，序列化的信息可以同样方便地恢复。然而，生成的 XML 文件可能非常大。

幸运的是，在 PowerShell 5 中有一个新的命令名叫 `Compress-Archieve`。当您创建了 XML 文件之后，您可以自动地将它转为一个 ZIP 文件。

以下是一些演示代码：它获取一个进程列表并且保存到 XML 文件。然后将 XML 文件压缩为 ZIP，并且删除原始的 XML 文件。

这么做的效率很高，因为 XML 是文本文件。您常常能看到压缩率在 3-5%（ZIP 的文件大小是原始文件的 3-5%）：

```powershell
$Path = "$env:TEMP\data1.xml"

# serialize data (results in large text files)
Get-Process | Export-Clixml -Path $Path

$length1 = (Get-Item -Path $Path).Length

$ZipPath = [IO.Path]::ChangeExtension($Path, ".zip")

Compress-Archive -Path $Path -Destination $ZipPath -CompressionLevel Optimal -Force
Remove-Item -Path $Path

$length2 = (Get-Item -Path $ZipPath).Length

$compression = $length2 * 100 / $length1
"Compression Ratio {0:n2} %" -f $compression
```

<!--本文国际来源：[Compressing Serialized Data](http://community.idera.com/powershell/powertips/b/tips/posts/compressing-serialized-data)-->
