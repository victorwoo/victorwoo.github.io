---
layout: post
date: 2022-10-11 00:00:00
title: "PowerShell 技能连载 - 使用 HTML 来创建 PDF 报告（第 3 部分）"
description: PowerTip of the Day - Using HTML to create PDF Reports (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
HTML 方便地将数据格式化为输出报告。在这个最后的部分中，我们将介绍如何将最终 HTML 报告转换为 PDF，以便轻松地将其传递给同事和团队成员。

以下是我们在第二部分介绍的脚本：

```powershell
$path = "$env:temp\report.html"

# get data from any cmdlet you wish
$data = Get-Service | Sort-Object -Property Status, Name

# helper function to convert arrays to string lists
function Convert-ArrayToStringList
{
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        $PipelineObject
    )
    process
    {
        $Property = $PipelineObject.psobject.Properties |
                        Where-Object { $_.Value -is [Array] } |
                        Select-Object -ExpandProperty Name

        foreach ($item in $Property)
        {
            $PipelineObject.$item = $PipelineObject.$item -join ','


        }

        return $PipelineObject
    }
}


# compose style sheet
$stylesheet = "
    <style>
    body { background-color:#AAEEEE;
    font-family:Monospace;
    font-size:10pt; }
    table,td, th { border:1px solid blue;}
    th { color:#00008B;
    background-color:#EEEEAA;
    font-size: 12pt;}
    table { margin-left:30px; }
    h2 {
    font-family:Tahoma;
    color:#6D7B8D;
    }
    h1{color:#DC143C;}
    h5{color:#DC143C;}
    </style>
"

# output to HTML
$data |
# make sure you use Select-Object to copy the objects
Select-Object -Property * |
Convert-ArrayToStringList |
ConvertTo-Html -Title Report -Head $stylesheet |
Set-Content -Path $path -Encoding UTF8

Invoke-Item -Path $path
```

结果是位于 `$Path` 中指定的文件位置中的 HTML 报告。现在，缺少的是将 HTML 文件转换为 PDF 文件的方法。

有很多方法可以实现这一目标，但最方便的方法是使用 Chrome 浏览器。但是，要进行转换，首先需要安装 Chrome 浏览器（如果尚未安装）。

这是获取现有 HTML 文件并将其转换为 PDF 的最终代码：

```powershell
# path to existing HTML file
$path = "$env:temp\report.html"

# determine installation path for Chrome
$Chrome = ${env:ProgramFiles(x86)}, $env:ProgramFiles |
ForEach-Object { "$_\Google\Chrome\Application\chrome.exe" } |
Where-Object { Test-Path -Path $_ -PathType Leaf } |
Select-Object -First 1

if ($Chrome.Count -ne 1) { throw "Chrome not installed." }

# compose destination path by changing file extension to PDF
$destinationPath =  [System.IO.Path]::ChangeExtension($Path, '.pdf')

# doing the conversion
& $Chrome --headless --print-to-pdf="$destinationPath" "$Path"

# (this is async so it may take a moment for the PDF to be created)
do
{
    Write-Host '.' -NoNewline
    Start-Sleep -Seconds 1
} Until (Test-Path -Path $destinationPath)

Invoke-Item -Path $destinationPath
```

<!--本文国际来源：[Using HTML to create PDF Reports (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-html-to-create-pdf-reports-part-3)-->

