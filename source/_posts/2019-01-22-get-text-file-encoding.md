---
layout: post
date: 2019-01-22 00:00:00
title: "PowerShell 技能连载 - 获取文本文件编码"
description: PowerTip of the Day - Get Text File Encoding
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
文本文件可以以不同的编码存储。需要正确地指定编码，才能正确地读取它们。这是为什么多数读取文本文件的 cmdlet 提供 `-Encoding` 参数（例如 `Get-Content`）。如果没有指定正确的编码，您可能会看到一堆乱码。

那么如何（自动地）确认某个指定的文本文件所使用的编码？以下是一个好用的函数：

```powershell
function Get-Encoding
{
  param
  (
    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Alias('FullName')]
    [string]
    $Path
  )

  process
  {
    $bom = New-Object -TypeName System.Byte[](4)

    $file = New-Object System.IO.FileStream($Path, 'Open', 'Read')

    $null = $file.Read($bom,0,4)
    $file.Close()
    $file.Dispose()

    $enc = [Text.Encoding]::ASCII
    if ($bom[0] -eq 0x2b -and $bom[1] -eq 0x2f -and $bom[2] -eq 0x76)
      { $enc =  [Text.Encoding]::UTF7 }
    if ($bom[0] -eq 0xff -and $bom[1] -eq 0xfe)
      { $enc =  [Text.Encoding]::Unicode }
    if ($bom[0] -eq 0xfe -and $bom[1] -eq 0xff)
      { $enc =  [Text.Encoding]::BigEndianUnicode }
    if ($bom[0] -eq 0x00 -and $bom[1] -eq 0x00 -and $bom[2] -eq 0xfe -and $bom[3] -eq 0xff)
      { $enc =  [Text.Encoding]::UTF32}
    if ($bom[0] -eq 0xef -and $bom[1] -eq 0xbb -and $bom[2] -eq 0xbf)
      { $enc =  [Text.Encoding]::UTF8}

    [PSCustomObject]@{
      Encoding = $enc
      Path = $Path
    }
  }
}
```

以下是一段检查您用户配置文件中所有文本文件的测试代码：

```powershell
PS> dir $home -Filter *.txt -Recurse | Get-Encoding

Encoding                    Path
--------                    ----
System.Text.UnicodeEncoding C:\Users\tobwe\E006_psconfeu2019.txt
System.Text.UnicodeEncoding C:\Users\tobwe\E009_psconfeu2019.txt
System.Text.UnicodeEncoding C:\Users\tobwe\E027_psconfeu2019.txt
System.Text.ASCIIEncoding   C:\Users\tobwe\.nuget\packages\Aspose.Words\18.12.0\...
System.Text.ASCIIEncoding   C:\Users\tobwe\.vscode\extensions\ms-vscode.powers...
System.Text.UTF8Encoding    C:\Users\tobwe\.vscode\extensions\ms-vscode.powers...
```

<!--more-->
本文国际来源：[Get Text File Encoding](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/get-text-file-encoding)
