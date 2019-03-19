---
layout: post
date: 2018-07-25 00:00:00
title: "PowerShell 技能连载 - 处理文件编码和 BOM"
description: PowerTip of the Day - Dealing with File Encoding and BOM
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您将文本内容写入到文件时，PowerShell cmdlet 可以指定文件编码。编码决定了字符的存储方式，并且当某个字符显示乱码时，通常是由于编码不匹配造成的。

然而，有一些编码设置是无法通过 cmdlet 参数控制的。以下是一个例子。将一个进程列表保存到 CSV 文件：

```powershell
$Path = "$env:temp\export.csv"

Get-Process |
    Export-CSV -NoTypeInformation -UseCulture -Encoding UTF8 -Path $Path
```

您现在可以在 Excel 或任意文本编辑器中打开生成的 CSV 文件。当您使用 Notepad++ 打开文件时，状态栏显示编码格式为：UTF-8-BOM。

这段 PowerShell 代码以 UTF-8 编码生成文件，所以这段没有问题。BOM 代表“字节顺序标记” (Byte Order Mark)。当使用 BOM 时，将在文件的起始处增加一个特定的字节顺序标识，这样程序可以自动识别使用的编码格式。

不过，一些编辑器和数据处理系统无法处理 BOM。要移除 BOM 并使用纯文本编码，请使用类似这样的 PowerShell 代码：

```powershell
function Remove-BomFromFile($OldPath, $NewPath)
{
    $Content = Get-Content $OldPath -Raw
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [System.IO.File]::WriteAllLines($NewPath, $Content, $Utf8NoBomEncoding)
}
```

在上述例子中，要将 UTF-8-BOM 转化为纯 UTF-8，请运行这段代码：

```powershell
$Path = "$env:temp\export.csv"
$NewPath = "$env:temp\export_new.csv"
Remove-BomFromFile -OldPath $Path -NewPath $NewPath
```

<!--本文国际来源：[Dealing with File Encoding and BOM](http://community.idera.com/powershell/powertips/b/tips/posts/dealing-with-file-encoding-and-bom)-->
