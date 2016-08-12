layout: post
date: 2014-10-27 11:00:00
title: "PowerShell 技能连载 - 创建彩色的 HTML 报告"
description: PowerTip of the Day - Creating Colorful HTML Reports
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
_适用于 PowerShell 所有版本_

要将结果转换为彩色的自定义报告，只需要定义三个脚本块：一个生成 HTML 文档的头部，另一个生成尾部，还有一个对报表中的列表做循环，针对每一个列表项做处理。

然后，将这些脚本块传递给 `ForEach-Object`。它接受一个 `begin`、一个 `process` 和一个 `end` 脚本块。

以下是一个示例代码，演示了如何创建一个彩色的服务状态报表：

    $path = "$env:temp\report.hta"
    
    $beginning = {
     @'
        <html>
        <head>
        <title>Report</title>
        <STYLE type="text/css">
            h1 {font-family:SegoeUI, sans-serif; font-size:20} 
            th {font-family:SegoeUI, sans-serif; font-size:15} 
            td {font-family:Consolas, sans-serif; font-size:12} 
    
        </STYLE>
    
        </head>
        <image src="http://www.yourcompany.com/yourlogo.gif" />
        <h1>System Report</h1>
        <table>
        <tr><th>Status</th><th>Name</th></tr>
    '@
    }
    
    $process = {
        $status = $_.Status
        $name = $_.DisplayName
    
        if ($status -eq 'Running')
        {
            '<tr>'
            '<td bgcolor="#00FF00">{0}</td>' -f $status
            '<td bgcolor="#00FF00">{0}</td>' -f $name
            '</tr>'
        }
        else
        {
            '<tr>'
            '<td bgcolor="#FF0000">{0}</td>' -f $status
            '<td bgcolor="#FF0000">{0}</td>' -f $name
            '</tr>'
        }
    }
    
    
    $end = { 
    @'
        </table>
        </html>
        </body>
    '@
    
    
    }
    
    
    Get-Service | 
      ForEach-Object -Begin $beginning -Process $process -End $end |
      Out-File -FilePath $path -Encoding utf8
    
    Invoke-Item -Path $path

<!--more-->
本文国际来源：[Creating Colorful HTML Reports](http://powershell.com/cs/blogs/tips/archive/2014/10/27/creating-colorful-html-reports.aspx)
