---
layout: post
date: 2024-04-26 08:00:00
title: "PowerShell 技能连载 - PDF 处理技巧"
description: PowerTip of the Day - PowerShell PDF Processing Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中处理 PDF 文件是一项常见任务，本文将介绍一些实用的 PDF 处理技巧。

首先，让我们看看基本的 PDF 操作：

```powershell
# 创建 PDF 信息获取函数
function Get-PDFInfo {
    param(
        [string]$PDFPath
    )
    
    try {
        # 使用 iTextSharp 获取 PDF 信息
        Add-Type -Path "itextsharp.dll"
        $reader = [iTextSharp.text.pdf.PdfReader]::new($PDFPath)
        
        $info = [PSCustomObject]@{
            FileName = Split-Path $PDFPath -Leaf
            PageCount = $reader.NumberOfPages
            FileSize = (Get-Item $PDFPath).Length
            IsEncrypted = $reader.IsEncrypted()
            Metadata = $reader.Info
        }
        
        $reader.Close()
        return $info
    }
    catch {
        Write-Host "获取 PDF 信息失败：$_"
    }
}
```

PDF 合并：

```powershell
# 创建 PDF 合并函数
function Merge-PDFFiles {
    param(
        [string[]]$InputFiles,
        [string]$OutputPath
    )
    
    try {
        Add-Type -Path "itextsharp.dll"
        $document = [iTextSharp.text.Document]::new()
        $writer = [iTextSharp.text.pdf.PdfCopy]::new($document, [System.IO.FileStream]::new($OutputPath, [System.IO.FileMode]::Create))
        
        $document.Open()
        
        foreach ($file in $InputFiles) {
            $reader = [iTextSharp.text.pdf.PdfReader]::new($file)
            for ($i = 1; $i -le $reader.NumberOfPages; $i++) {
                $writer.AddPage($writer.GetImportedPage($reader, $i))
            }
            $reader.Close()
        }
        
        $document.Close()
        $writer.Close()
        
        Write-Host "PDF 合并完成：$OutputPath"
    }
    catch {
        Write-Host "合并失败：$_"
    }
}
```

PDF 分割：

```powershell
# 创建 PDF 分割函数
function Split-PDF {
    param(
        [string]$InputPath,
        [string]$OutputFolder,
        [int[]]$PageRanges
    )
    
    try {
        Add-Type -Path "itextsharp.dll"
        $reader = [iTextSharp.text.pdf.PdfReader]::new($InputPath)
        
        for ($i = 0; $i -lt $PageRanges.Count; $i += 2) {
            $startPage = $PageRanges[$i]
            $endPage = if ($i + 1 -lt $PageRanges.Count) { $PageRanges[$i + 1] } else { $reader.NumberOfPages }
            
            $outputPath = Join-Path $OutputFolder "split_$($startPage)_$($endPage).pdf"
            $document = [iTextSharp.text.Document]::new()
            $writer = [iTextSharp.text.pdf.PdfCopy]::new($document, [System.IO.FileStream]::new($outputPath, [System.IO.FileMode]::Create))
            
            $document.Open()
            
            for ($page = $startPage; $page -le $endPage; $page++) {
                $writer.AddPage($writer.GetImportedPage($reader, $page))
            }
            
            $document.Close()
            $writer.Close()
        }
        
        $reader.Close()
        Write-Host "PDF 分割完成"
    }
    catch {
        Write-Host "分割失败：$_"
    }
}
```

PDF 加密：

```powershell
# 创建 PDF 加密函数
function Protect-PDF {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [string]$UserPassword,
        [string]$OwnerPassword
    )
    
    try {
        Add-Type -Path "itextsharp.dll"
        $reader = [iTextSharp.text.pdf.PdfReader]::new($InputPath)
        $stamper = [iTextSharp.text.pdf.PdfStamper]::new($reader, [System.IO.FileStream]::new($OutputPath, [System.IO.FileMode]::Create))
        
        # 设置加密
        $stamper.SetEncryption(
            [System.Text.Encoding]::UTF8.GetBytes($UserPassword),
            [System.Text.Encoding]::UTF8.GetBytes($OwnerPassword),
            [iTextSharp.text.pdf.PdfWriter]::ALLOW_PRINTING -bor
            [iTextSharp.text.pdf.PdfWriter]::ALLOW_COPY -bor
            [iTextSharp.text.pdf.PdfWriter]::ALLOW_FILL_IN -bor
            [iTextSharp.text.pdf.PdfWriter]::ALLOW_SCREENREADERS,
            [iTextSharp.text.pdf.PdfWriter]::ENCRYPTION_AES_128
        )
        
        $stamper.Close()
        $reader.Close()
        
        Write-Host "PDF 加密完成：$OutputPath"
    }
    catch {
        Write-Host "加密失败：$_"
    }
}
```

这些技巧将帮助您更有效地处理 PDF 文件。记住，在处理 PDF 时，始终要注意文件的安全性和完整性。同时，建议在处理大型 PDF 文件时使用流式处理方式，以提高性能。 