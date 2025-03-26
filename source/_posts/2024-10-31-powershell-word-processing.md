---
layout: post
date: 2024-10-31 08:00:00
title: "PowerShell 技能连载 - Word 处理技巧"
description: PowerTip of the Day - PowerShell Word Processing Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中处理 Word 文档是一项常见任务，本文将介绍一些实用的 Word 处理技巧。

首先，让我们看看基本的 Word 操作：

```powershell
# 创建 Word 信息获取函数
function Get-WordInfo {
    param(
        [string]$WordPath
    )
    
    try {
        $word = New-Object -ComObject Word.Application
        $word.Visible = $false
        $document = $word.Documents.Open($WordPath)
        
        $info = [PSCustomObject]@{
            FileName = Split-Path $WordPath -Leaf
            PageCount = $document.ComputeStatistics(2)  # 2 代表页数
            WordCount = $document.ComputeStatistics(0)  # 0 代表字数
            ParagraphCount = $document.Paragraphs.Count
            SectionCount = $document.Sections.Count
        }
        
        $document.Close($false)
        $word.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word)
        
        return $info
    }
    catch {
        Write-Host "获取 Word 信息失败：$_"
    }
}
```

Word 文档合并：

```powershell
# 创建 Word 文档合并函数
function Merge-WordDocuments {
    param(
        [string[]]$InputFiles,
        [string]$OutputPath
    )
    
    try {
        $word = New-Object -ComObject Word.Application
        $word.Visible = $false
        
        # 打开第一个文档
        $mainDoc = $word.Documents.Open($InputFiles[0])
        
        # 合并其他文档
        for ($i = 1; $i -lt $InputFiles.Count; $i++) {
            $doc = $word.Documents.Open($InputFiles[$i])
            $doc.Content.Copy()
            $mainDoc.Content.InsertAfter($word.Selection.Paste())
            $doc.Close($false)
        }
        
        # 保存并关闭
        $mainDoc.SaveAs($OutputPath)
        $mainDoc.Close($true)
        $word.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word)
        
        Write-Host "文档合并完成：$OutputPath"
    }
    catch {
        Write-Host "合并失败：$_"
    }
}
```

Word 文档分割：

```powershell
# 创建 Word 文档分割函数
function Split-WordDocument {
    param(
        [string]$InputPath,
        [string]$OutputFolder,
        [int[]]$PageRanges
    )
    
    try {
        $word = New-Object -ComObject Word.Application
        $word.Visible = $false
        $doc = $word.Documents.Open($InputPath)
        
        for ($i = 0; $i -lt $PageRanges.Count; $i += 2) {
            $startPage = $PageRanges[$i]
            $endPage = if ($i + 1 -lt $PageRanges.Count) { $PageRanges[$i + 1] } else { $doc.ComputeStatistics(2) }
            
            $newDoc = $word.Documents.Add()
            
            # 复制指定页面范围
            $doc.Range(
                $doc.GoTo(What:=7, Which:=1, Count:=1, Name:=$startPage).Start,
                $doc.GoTo(What:=7, Which:=1, Count:=1, Name:=$endPage + 1).Start - 1
            ).Copy()
            
            $newDoc.Content.Paste()
            
            # 保存分割后的文档
            $outputPath = Join-Path $OutputFolder "split_$($startPage)_$($endPage).docx"
            $newDoc.SaveAs($outputPath)
            $newDoc.Close($true)
        }
        
        $doc.Close($false)
        $word.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word)
        
        Write-Host "文档分割完成"
    }
    catch {
        Write-Host "分割失败：$_"
    }
}
```

Word 文档格式转换：

```powershell
# 创建 Word 文档格式转换函数
function Convert-WordFormat {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [ValidateSet("doc", "docx", "pdf", "rtf", "txt")]
        [string]$TargetFormat
    )
    
    try {
        $word = New-Object -ComObject Word.Application
        $word.Visible = $false
        $doc = $word.Documents.Open($InputPath)
        
        switch ($TargetFormat) {
            "doc" {
                $doc.SaveAs($OutputPath, 16)  # 16 代表 doc 格式
            }
            "docx" {
                $doc.SaveAs($OutputPath, 16)  # 16 代表 docx 格式
            }
            "pdf" {
                $doc.SaveAs($OutputPath, 17)  # 17 代表 pdf 格式
            }
            "rtf" {
                $doc.SaveAs($OutputPath, 6)   # 6 代表 rtf 格式
            }
            "txt" {
                $doc.SaveAs($OutputPath, 7)   # 7 代表 txt 格式
            }
        }
        
        $doc.Close($false)
        $word.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word)
        
        Write-Host "格式转换完成：$OutputPath"
    }
    catch {
        Write-Host "转换失败：$_"
    }
}
```

这些技巧将帮助您更有效地处理 Word 文档。记住，在处理 Word 文档时，始终要注意内存管理和资源释放。同时，建议在处理大型文档时使用流式处理方式，以提高性能。 