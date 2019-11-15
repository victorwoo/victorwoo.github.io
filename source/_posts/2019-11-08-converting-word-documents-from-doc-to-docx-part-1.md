---
layout: post
date: 2019-11-08 00:00:00
title: "PowerShell 技能连载 - 将 Word 文档从 .doc 格式转为 .docx 格式（第 1 部分）"
description: PowerTip of the Day - Converting Word Documents from .doc to .docx (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
将旧式的 Word 文档转为新的 .docx 格式需要比较多工作量。多谢 PowerShell，您可以自动完成该转换工作：

```powershell
function Convert-WordDocument
{
    param
    (
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]
        [Alias('FullName')]
        $Path
    )
    begin
    {
        # launch Word
        $word = New-Object -ComObject Word.Application
    }

    process
    {
        # determine target path
        $pathOut = [System.IO.Path]::ChangeExtension($Path, '.docx')

        # open the document
        $doc = $word.Documents.Open($Path)

        Write-Progress -Activity 'Converting' -Status $PathOut

        # important: do the actual conversion
        $doc.Convert()

        # save in the appropriate format
        $doc.SaveAs([ref]$PathOut,[ref]16)

        # close document
        $word.ActiveDocument.Close()
    }
    end
    {
        # close word
        $word.Quit()
    }
}
```

<!--本文国际来源：[Converting Word Documents from .doc to .docx (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/converting-word-documents-from-doc-to-docx-part-1)-->

