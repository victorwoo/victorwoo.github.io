---
layout: post
date: 2024-12-12 08:00:00
title: "PowerShell 技能连载 - PDF 文件处理技巧"
description: PowerTip of the Day - PowerShell PDF File Handling Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中处理 PDF 文件是一项常见任务，特别是在处理文档、报表时。本文将介绍一些实用的 PDF 文件处理技巧。

首先，我们需要安装必要的模块：

```powershell
# 安装 PDF 处理模块
Install-Module -Name PSWritePDF -Force
```

创建 PDF 文件：

```powershell
# 创建 PDF 文档
$pdf = New-PDFDocument -Title "员工信息报表" -Author "系统管理员"

# 添加内容
$pdf | Add-PDFText -Text "员工信息报表" -FontSize 20 -Alignment Center
$pdf | Add-PDFText -Text "生成日期：$(Get-Date -Format 'yyyy-MM-dd')" -FontSize 12

# 添加表格
$tableData = @(
    @{
        姓名 = "张三"
        部门 = "技术部"
        职位 = "高级工程师"
        入职日期 = "2020-01-15"
    },
    @{
        姓名 = "李四"
        部门 = "市场部"
        职位 = "市场经理"
        入职日期 = "2019-06-20"
    }
)

$pdf | Add-PDFTable -DataTable $tableData -AutoFit

# 保存 PDF
$pdf | Save-PDFDocument -FilePath "employee_report.pdf"
```

合并 PDF 文件：

```powershell
# 合并多个 PDF 文件
$pdfFiles = @(
    "report1.pdf",
    "report2.pdf",
    "report3.pdf"
)

$mergedPdf = New-PDFDocument -Title "合并报表"

foreach ($file in $pdfFiles) {
    if (Test-Path $file) {
        $mergedPdf | Add-PDFPage -PdfPath $file
    }
}

$mergedPdf | Save-PDFDocument -FilePath "merged_report.pdf"
```

提取 PDF 文本：

```powershell
# 提取 PDF 文本内容
function Get-PDFText {
    param(
        [string]$PdfPath
    )
    
    $reader = [iTextSharp.text.pdf.PdfReader]::new($PdfPath)
    $text = ""
    
    for ($i = 1; $i -le $reader.NumberOfPages; $i++) {
        $text += [iTextSharp.text.pdf.parser.PdfTextExtractor]::GetTextFromPage($reader, $i)
    }
    
    $reader.Close()
    return $text
}

# 使用示例
$text = Get-PDFText -PdfPath "document.pdf"
Write-Host "PDF 内容："
Write-Host $text
```

添加水印：

```powershell
# 创建带水印的 PDF
$pdf = New-PDFDocument -Title "机密文档"

# 添加正文内容
$pdf | Add-PDFText -Text "这是一份机密文档" -FontSize 16

# 添加水印
$watermark = @"
机密文件
请勿外传
"@

$pdf | Add-PDFWatermark -Text $watermark -Opacity 0.3 -Rotation 45

# 保存 PDF
$pdf | Save-PDFDocument -FilePath "confidential.pdf"
```

一些实用的 PDF 处理技巧：

1. 压缩 PDF 文件：
```powershell
function Compress-PDF {
    param(
        [string]$InputPath,
        [string]$OutputPath
    )
    
    $reader = [iTextSharp.text.pdf.PdfReader]::new($InputPath)
    $stamper = [iTextSharp.text.pdf.PdfStamper]::new($reader, [System.IO.File]::Create($OutputPath))
    
    # 设置压缩选项
    $stamper.SetFullCompressionMode(1)
    
    $stamper.Close()
    $reader.Close()
}
```

2. 添加页眉页脚：
```powershell
# 创建带页眉页脚的 PDF
$pdf = New-PDFDocument -Title "带页眉页脚的文档"

# 添加页眉
$pdf | Add-PDFHeader -Text "公司机密文档" -Alignment Center

# 添加页脚
$pdf | Add-PDFFooter -Text "第 {PAGE} 页 / 共 {PAGES} 页" -Alignment Center

# 添加正文内容
$pdf | Add-PDFText -Text "文档内容..." -FontSize 12

# 保存 PDF
$pdf | Save-PDFDocument -FilePath "document_with_header_footer.pdf"
```

3. 保护 PDF 文件：
```powershell
# 创建受保护的 PDF
$pdf = New-PDFDocument -Title "受保护的文档"

# 添加内容
$pdf | Add-PDFText -Text "这是受保护的文档内容" -FontSize 12

# 设置密码保护
$pdf | Set-PDFProtection -UserPassword "user123" -OwnerPassword "owner456"

# 保存 PDF
$pdf | Save-PDFDocument -FilePath "protected.pdf"
```

这些技巧将帮助您更有效地处理 PDF 文件。记住，在处理大型 PDF 文件时，考虑使用流式处理方法来优化内存使用。同时，始终注意文档的安全性和完整性。 