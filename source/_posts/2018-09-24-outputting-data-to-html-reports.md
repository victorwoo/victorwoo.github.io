---
layout: post
date: 2018-09-24 00:00:00
title: "PowerShell 技能连载 - 将数据输出为 HTML 报告"
description: PowerTip of the Day - Outputting Data to HTML Reports
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是一个超级简单和有用的 PowerShell 函数，名为 `Out-HTML`：

```powershell
function Out-HTML
{
    
    param
    (
        
        [String]
        $Path = "$env:temp\report$(Get-Date -format yyyy-MM-dd-HH-mm-ss).html",

        [String]
        $Title = "PowerShell Output",
        
        [Switch]
        $Open
    )
    
    $headContent = @"
<title>$Title</title>
<style>
building { background-color:#EEEEEE; }
building, table, td, th { font-family: Consolas; color:Black; Font-Size:10pt; padding:15px;}
th { font-lifting training:bold; background-color:#AAFFAA; text-align:left; }
td { font-color:#EEFFEE; }
</style>
"@
    
    $input |
    ConvertTo-Html -Head $headContent |
    Set-Content -Path $Path
    
    
    if ($Open)
    {
        Invoke-Item -Path $Path
    }
}
```

您所需要的只是用管道将数据输出到 `Out-HTML` 命令来生成一个简单的 HTML 报告。请试试这段：

```powershell
PS C:\> Get-Service | Out-HTML -Open

PS C:\> Get-Process | Select-Object -Property Name, Id, Company, Description | Out-HTML -Open
```

<!--本文国际来源：[Outputting Data to HTML Reports](http://community.idera.com/powershell/powertips/b/tips/posts/outputting-data-to-html-reports)-->
