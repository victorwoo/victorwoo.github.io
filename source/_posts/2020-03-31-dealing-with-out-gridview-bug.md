---
layout: post
date: 2020-03-31 00:00:00
title: "PowerShell 技能连载 - 处理 Out-GridView 的 Bug"
description: PowerTip of the Day - Dealing with Out-GridView Bug
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当添加 `-PassThru` 参数时，Out-GridView 可以用作通用的选择对话框。下面的单行停止了您在网格视图窗口中选择的所有服务（嗯，不是真的停止。在删除 `-WhatIf` 参数之前，都可以安全地运行）：

```powershell
Get-Service | Out-GridView -Title 'Select Service' -PassThru | Stop-Service -WhatIf
```

但是，Out-GridView 中存在一个长期存在的错误：将信息填充到网格视图窗口中时，启用了用于选择项目的按钮，但不返回任何内容。这是一个测试用例：我用 Windows 文件夹中大于 10MB 的所有文件填充网格视图窗口：

```powershell
Get-ChildItem -Path C:\Windows -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object Length -gt 10MB |
    Out-GridView -Title 'Select a file' -PassThru
```

枚举文件可能要花费一些时间，由于优雅的实时特性，过一会儿会在网格视图窗口看到列出的文件，并且可以选择一些文件，然后单击右下角的“确定”按钮将其返回到控制台。

注意：如果在所有文件都发送到网格视图窗口之前单击“确定”按钮，则网格视图窗口将关闭但不返回任何内容。为了使确定按钮正常工作，您必须知道网格视图窗口的输出何时完成。

除此以外，您无法知道什么时候结束。您可以稍等片刻，以期获得最好的结果，但是没有任何提示告诉您网格视图窗口已完全填充完毕。

一种解决方法是先将数据存储在变量中，然后将其快速发送到网格视图窗口：

```powershell
$files = Get-ChildItem -Path C:\Windows -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object Length -gt 10MB

$files | Out-GridView -Title 'Select a file' -PassThru
```

但是，这么做失去了实时性，并且可能需要等待几秒钟才能收集数据并打开网格视图窗口。

一种更聪明的方法是利用 PowerShell 的管道体系结构并使用管道感知功能。完成所有管道处理后，将调用其 "`end`" 代码块，因此您可以在此处放置代码以提示所有数据已完成：

```powershell
function Send-PipelineEndNotification
{
    begin {
        Write-Host "Collecting Data..." -NoNewline -ForegroundColor DarkYellow
    }
    process { $_ }
    end {
        Write-Host "Completed." -ForegroundColor Green
        [Console]::Beep()
    }
}


Get-ChildItem -Path C:\Windows -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object Length -gt 10MB |
    Send-PipelineEndNotification |
    Out-GridView -Title 'Select a file' -PassThru
```

只需在 `Out-GridView` 之前调用 `Send-PipelineEndNotification`。现在，在控制台中，您会看到一条警告，告知您仍在收集信息，并在网格视图窗口完成并准备返回所选项目时显示绿色的通知文本和提示音。

<!--本文国际来源：[Dealing with Out-GridView Bug](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/dealing-with-out-gridview-bug)-->

