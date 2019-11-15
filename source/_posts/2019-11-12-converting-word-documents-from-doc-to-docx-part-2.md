---
layout: post
date: 2019-11-12 00:00:00
title: "PowerShell 技能连载 - 将 Word 文档从 .doc 格式转为 .docx 格式（第 2 部分）"
description: PowerTip of the Day - Converting Word Documents from .doc to .docx (Part 2)
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

但是，要做到这一点，有许多额外的步骤。如果要遵守安全指南，您需要了解文档中是否存在宏，并相应地更改扩展名。此外，如果文档处于只读模式，则无法转换该文档，并应跳过转换。如果你批量转换很多文档，有个进度条会很好。

感谢 Wpperal 市的安全专家 Lars Köpcke，增加了只读文档的宏观检查和测试！

以下是一个修订过的函数，能够神奇地批量转换。不过这仍然是一个原型。若果您希望在生产环境下使用它，请确保您理解它并且加入了所有需要的错误处理和报告。如果您不希望该函数重写原有的文件，请增加检测环节。

```powershell
function Convert-WordDocument
{
  param
  (
    # accept path strings or items from Get-ChildItem
    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [string]
    [Alias('FullName')]
    $Path
  )

  begin
  {
    # we are collecting all paths first
    [Collections.ArrayList]$collector = @()
  }

  process
  {
    # find extension
    $extension = [System.IO.Path]::GetExtension($Path)

    # we only process .doc and .dot files
    if ($extension -eq '.doc' -or $extension -eq '.dot')
    {
        # add to list for later processing
        $null = $collector.Add($Path)

    }
  }
  end
  {
    # pipeline is done, now we can start converting!

    Write-Progress -Activity Converting -Status 'Launching Application'

    # initialize Word (must be installed)
    $word = New-Object -ComObject Word.Application

    $counter = 0
    Foreach ($Path in $collector)
    {
        # increment a counter for the progress bar
        $counter++

        # open document in Word
        $doc = $word.Documents.Open($Path)

        # determine target document type
        # if the doc has macros, use different extensions

        [string]$targetExtension = ''
        [int]$targetConversion = 0

        switch ([System.IO.Path]::GetExtension($Path))
        {
          '.doc' {
            if ($doc.HasVBProject -eq $true)
            {
              $targetExtension = '.docm'
              $targetConversion = 13
            }
            else
            {
              $targetExtension = '.docx'
              $targetConversion = 16
            }
          }
          '.dot' {
            if ($doc.HasVBProject -eq $true)
            {
              $targetExtension = '.dotm'
              $targetConversion = 15
            }
            else
            {
              $targetExtension = '.dotx'
              $targetConversion = 14
            }
          }
        }

        # conversion cannot work for read-only docs
        If (!$doc.ActiveWindow.View.ReadingLayout)
        {
            if ($targetConversion -gt 0)
            {
              $pathOut = [IO.Path]::ChangeExtension($Path, $targetExtension)

              $doc.Convert()
              $percent = $counter * 100 / $collector.Count
              Write-Progress -Activity 'Converting' -Status $pathOut -PercentComplete $percent
              $doc.SaveAs([ref]$PathOut,[ref] $targetConversion)
            }
        }

        $word.ActiveDocument.Close()
    }

    # quit Word when done
    Write-Progress -Activity Converting -Status Done.
    $word.Quit()
  }
}
```

以下是调用示例：

```powershell
PS> dir F:\documents -Include *.doc, *.dot -Recurse | Convert-WordDocument
```

<!--本文国际来源：[Converting Word Documents from .doc to .docx (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/converting-word-documents-from-doc-to-docx-part-2)-->

