---
layout: post
date: 2019-10-01 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell 脚本中嵌入二进制文件（图片、DLL）"
description: PowerTip of the Day - Embedding Binaries (Pictures, DLLs) in PowerShell Scripts
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果脚本需要外部二进制资源，例如图片或者 DLL 文件，您当然可以将它们和脚本一起分发。不过，您也可以将这些二进制文件作为文本嵌入您的脚本文件：

* 以字节方式读取二进制文件
* 将字节保存为 Base64 编码的字符串

通过这种方式，您的脚本可以从一个文本变量中读取 Base64 编码的二进制，然后将数据转换回字节，并且将它们写入临时文件。

以下是两个演示该概念的函数：

```powershell
function Convert-BinaryToText
{
  param
  (
    [Parameter(Mandatory)]
    [string]
    $Path
  )

  $Bytes = [System.IO.File]::ReadAllBytes($Path)
  [System.Convert]::ToBase64String($Bytes)
}

function Convert-TextToBinary
{
  param
  (
    [Parameter(Mandatory)]
    [string]
    $Text,

    [Parameter(Mandatory)]
    [string]
    $OutputPath
  )

  $Bytes = [System.Convert]::FromBase64String($Text)
  [System.IO.File]::WriteAllBytes($OutputPath, $Bytes)
}
```

`Convert-BinaryToText` 接受一个任意文件的路径，并返回 Base64 编码的字符串。`Convert-BinaryToText` 做的是相反的操作：传入 Base64 编码的字符串以及一个目标路径，该函数将自动重建二进制文件。

请注意将二进制文件保存成 Base64 字符串并不能节省空间。您的脚本的大小可能会超过原来的二进制文件大小。但是，即使 Base64 编码的字符串很大，PowerShell也能很好地处理它们，而且从 Base64 编码的字符串中提取二进制文件非常快。

<!--本文国际来源：[Embedding Binaries (Pictures, DLLs) in PowerShell Scripts](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/embedding-binaries-pictures-dlls-in-powershell-scripts)-->

