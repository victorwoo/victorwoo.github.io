---
layout: post
date: 2022-10-07 00:00:00
title: "PowerShell 技能连载 - 使用 HTML 来创建 PDF 报告（第 2 部分）"
description: PowerTip of the Day - Using HTML to create PDF Reports (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
HTML 是一种将数据格式化为输出报告的简单方法。在第二部分中，我们说明了如何将包含数组的属性转换为字符串列表。数组无法正确显示为文本，因此此问题适用于 HTML 报告和将数据导出到 CSV。

请看：下面的代码将您的所有服务生成 HTML 报告，这是我们在第一部分结束时停下的地方：

```powershell
$path = "$env:temp\report.html"

# get data from any cmdlet you wish
$data = Get-Service | Sort-Object -Property Status, Name

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
$data | ConvertTo-Html -Title Report -Head $stylesheet | Set-Content -Path $path -Encoding UTF8

Invoke-Item -Path $path
```

当您查看报告时，您会注意到某些列包含数据类型而不是数据，即 `RequiredServices` 和 `DependentServices`。 原因是因为这些属性包含数组。要正确显示属性内容，您需要首先将数组转换为字符串列表。

这是一个自动检测包含数组的属性并用字符串列表代替这些属性的函数：

```powershell
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
```

为此，您首先必须通过 `Select-Object` 获取可以操纵的对象的副本。`Convert-ArrayToStringList` 也对创建 CSV 导出非常有帮助。下面的代码将服务列表创建为 CSV 文件，并确保所有属性都是可读的，然后将 CSV 文件加载到 Microsoft Excel 中：

```powershell
$Path = "$env:temp\report.csv"

Get-Service |
Select-Object -Property * |
Convert-ArrayToStringList |
Export-Csv -NoTypeInformation -Encoding UTF8 -Path $Path -UseCulture

Start-Process -FilePath excel -ArgumentList $Path
```

这是一个完整的脚本，能创建一个具有所有可读属性的服务报告：

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

<!--本文国际来源：[Using HTML to create PDF Reports (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-html-to-create-pdf-reports-part-2)-->

