---
layout: post
date: 2024-06-28 08:00:00
title: "PowerShell 技能连载 - PDF 自动化处理技巧"
description: PowerTip of the Day - PowerShell PDF Automation Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中处理 PDF 文件是一项常见任务，本文将介绍一些实用的 PDF 自动化处理技巧。

首先，让我们看看基本的 PDF 操作：

```powershell
# 创建 PDF 合并函数
function Merge-PDFFiles {
    param(
        [string[]]$InputFiles,
        [string]$OutputFile
    )
    
    try {
        Add-Type -AssemblyName System.Drawing
        
        $pdfDoc = New-Object iTextSharp.text.Document
        $writer = [iTextSharp.text.PdfWriter]::GetInstance($pdfDoc, [System.IO.File]::Create($OutputFile))
        $pdfDoc.Open()
        
        foreach ($file in $InputFiles) {
            $reader = New-Object iTextSharp.text.PdfReader($file)
            $pdfDoc.AddPage($reader.GetPage(1))
        }
        
        $pdfDoc.Close()
        Write-Host "PDF 文件合并成功：$OutputFile"
    }
    catch {
        Write-Host "PDF 合并失败：$_"
    }
}
```

PDF 文本提取：

```powershell
# 创建 PDF 文本提取函数
function Extract-PDFText {
    param(
        [string]$InputFile,
        [string]$OutputFile,
        [switch]$IncludeImages
    )
    
    try {
        Add-Type -AssemblyName System.Drawing
        
        $reader = New-Object iTextSharp.text.PdfReader($InputFile)
        $text = New-Object System.Text.StringBuilder
        
        for ($i = 1; $i -le $reader.NumberOfPages; $i++) {
            $page = $reader.GetPage($i)
            $text.AppendLine($page.GetText())
            
            if ($IncludeImages) {
                $images = $page.GetImages()
                foreach ($image in $images) {
                    $text.AppendLine("图片位置：$($image.GetAbsoluteX()) $($image.GetAbsoluteY())")
                }
            }
        }
        
        $text.ToString() | Out-File -FilePath $OutputFile -Encoding UTF8
        Write-Host "PDF 文本提取成功：$OutputFile"
    }
    catch {
        Write-Host "PDF 文本提取失败：$_"
    }
}
```

PDF 页面管理：

```powershell
# 创建 PDF 页面管理函数
function Manage-PDFPages {
    param(
        [string]$InputFile,
        [string]$OutputFile,
        [int[]]$PageNumbers,
        [ValidateSet('Extract', 'Delete', 'Reorder')]
        [string]$Action
    )
    
    try {
        Add-Type -AssemblyName System.Drawing
        
        $reader = New-Object iTextSharp.text.PdfReader($InputFile)
        $writer = [iTextSharp.text.PdfWriter]::GetInstance($reader, [System.IO.File]::Create($OutputFile))
        
        switch ($Action) {
            'Extract' {
                $writer.SetPageNumbers($PageNumbers)
                Write-Host "PDF 页面提取成功：$OutputFile"
            }
            'Delete' {
                $writer.SetPageNumbers((1..$reader.NumberOfPages | Where-Object { $_ -notin $PageNumbers }))
                Write-Host "PDF 页面删除成功：$OutputFile"
            }
            'Reorder' {
                $writer.SetPageNumbers($PageNumbers)
                Write-Host "PDF 页面重排序成功：$OutputFile"
            }
        }
        
        $writer.Close()
    }
    catch {
        Write-Host "PDF 页面管理失败：$_"
    }
}
```

PDF 表单处理：

```powershell
# 创建 PDF 表单处理函数
function Process-PDFForm {
    param(
        [string]$InputFile,
        [string]$OutputFile,
        [hashtable]$FormData
    )
    
    try {
        Add-Type -AssemblyName System.Drawing
        
        $reader = New-Object iTextSharp.text.PdfReader($InputFile)
        $stamper = New-Object iTextSharp.text.PdfStamper($reader, [System.IO.File]::Create($OutputFile))
        
        $form = $stamper.AcroFields
        foreach ($key in $FormData.Keys) {
            $form.SetField($key, $FormData[$key])
        }
        
        $stamper.Close()
        Write-Host "PDF 表单处理成功：$OutputFile"
    }
    catch {
        Write-Host "PDF 表单处理失败：$_"
    }
}
```

PDF 加密和权限：

```powershell
# 创建 PDF 加密函数
function Protect-PDFFile {
    param(
        [string]$InputFile,
        [string]$OutputFile,
        [string]$UserPassword,
        [string]$OwnerPassword,
        [string[]]$Permissions
    )
    
    try {
        Add-Type -AssemblyName System.Drawing
        
        $reader = New-Object iTextSharp.text.PdfReader($InputFile)
        $writer = [iTextSharp.text.PdfWriter]::GetInstance($reader, [System.IO.File]::Create($OutputFile))
        
        $writer.SetEncryption(
            [System.Text.Encoding]::UTF8.GetBytes($UserPassword),
            [System.Text.Encoding]::UTF8.GetBytes($OwnerPassword),
            [iTextSharp.text.pdf.PdfWriter]::ALLOW_PRINTING,
            [iTextSharp.text.pdf.PdfWriter]::ENCRYPTION_AES_128
        )
        
        $writer.Close()
        Write-Host "PDF 加密成功：$OutputFile"
    }
    catch {
        Write-Host "PDF 加密失败：$_"
    }
}
```

这些技巧将帮助您更有效地处理 PDF 文件。记住，在处理 PDF 时，始终要注意文件大小和内存使用。同时，建议使用适当的错误处理和日志记录机制来跟踪所有操作。 