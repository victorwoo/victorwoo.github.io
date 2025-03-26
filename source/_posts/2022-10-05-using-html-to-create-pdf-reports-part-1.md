---
layout: post
date: 2022-10-05 00:00:00
title: "PowerShell 技能连载 - 使用 HTML 来创建 PDF 报告（第 1 部分）"
description: PowerTip of the Day - Using HTML to create PDF Reports (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
可以通过 HTML 轻松地将格式化的数据转换成输出报告。在这个三部分的系列中，我们首先说明您如何撰写 HTML 报告，然后展示一种将这些 HTML 报告转换为 PDF 文档的简单方法。

PowerShell 中有一个 `ConvertTo-Html` cmdlet，可以轻松将输出保存到 HTML 表格：

```powershell
$path = "$env:temp\report.html"

# get data from any cmdlet you wish
$data = Get-Service | Sort-Object -Property Status, Name

# output to HTML
$data | ConvertTo-Html | Set-Content -Path $path -Encoding UTF8

Invoke-Item -Path $path
```

最终的报告可能仍然很丑陋，但是添加 HTML 样式表可以轻松美化报告并添加您的公司设计：

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

<!--本文国际来源：[Using HTML to create PDF Reports (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-html-to-create-pdf-reports-part-1)-->

