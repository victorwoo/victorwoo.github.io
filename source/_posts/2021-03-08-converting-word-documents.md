---
layout: post
date: 2021-03-08 00:00:00
title: "PowerShell 技能连载 - 转换 Word 文档"
description: PowerTip of the Day - Converting Word Documents
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
现在仍然有许多旧文件格式（.doc 而不是 .docx）的 Microsoft Office 文档。

这是一个简单的 PowerShell 函数，它将旧的 .doc Word 文档转换为 .docx 格式并保存。如果未锁定旧的 Word 文档，则此过程是完全不可见的，并且可以在无人值守的情况下运行：

```powershell
function Convert-Doc2Docx
{
  param
  (
    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [string]
    [Alias('FullName')]
    $Path,

    [string]
    $DestinationFolder

  )
  begin
  {
    $word = New-Object -ComObject Word.Application
  }

  process
  {


    $pathOut = [System.IO.Path]::ChangeExtension($Path, '.docx')
    if ($PSBoundParameters.ContainsKey('DestinationFolder'))
    {
      $exists = Test-Path -Path $DestinationFolder -PathType Container
      if (!$exists)
      {
        throw "Folder not found: $DestinationFolder"
      }
      $name = Split-Path -Path $pathOut -Leaf
      $pathOut = Join-Path -Path $DestinationFolder -ChildPath $name
    }
    $doc = $word.Documents.Open($Path)
    $name = Split-Path -Path $Path -Leaf
    Write-Progress -Activity 'Converting' -Status $name
    $doc.Convert()
    $doc.SaveAs([ref]([string]$PathOut),[ref]16)
    $word.ActiveDocument.Close()

  }
  end
  {
    $word.Quit()
  }
}
```

<!--本文国际来源：[Converting Word Documents](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/converting-word-documents)-->
