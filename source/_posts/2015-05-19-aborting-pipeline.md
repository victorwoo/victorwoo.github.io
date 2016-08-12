layout: post
date: 2015-05-19 11:00:00
title: "PowerShell 技能连载 - 跳出管道"
description: PowerTip of the Day - Aborting Pipeline
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
有些时候您可能希望当某些条件满足时跳出一个管道。

以下是一种实现该功能的创新方法。它适用于 PowerShell 2.0 以及更高版本。

以下是一段示例代码：

    filter Stop-Pipeline 
    {
         param
         (
             [scriptblock]
             $condition = {$true}
         )
    
         if (& $condition) 
         {
           continue
         }
         $_
    }
    
    do {
        Get-ChildItem c:\Windows -Recurse -ErrorAction SilentlyContinue | Stop-Pipeline { ($_.FullName.ToCharArray() -eq '\').Count -gt 3 } 
    } while ($false)

该管道方法递归扫描 Windows 文件夹。代码中有一个名为 `Stop-Pipeline` 的新命令。您可以将一个脚本块传给它，如果该脚本块的执行结果为 `$true`，该管道将会退出。

在这个例子中，您可以控制递归的深度。当路径中包含三个反斜杠（`\`）时，管道将会停止。将数字“3”改为更大的值可以在更深的文件夹中递归。

这个技巧的使用前提是管道需要放置在一个“do”循环中。因为 `Stop-Pipeline` 主要的功能是当条件满足时执行“`Continue`”语句，使 do 循环提前退出。

这听起来不太方便不过它工作得很优雅。以下是一个简单的改动。它将运行一个管道最多不超过 10 秒：

    $start = Get-Date
    $MaxSeconds = 10
    
    do {
        Get-ChildItem c:\Windows -Recurse -ErrorAction SilentlyContinue | Stop-Pipeline { ((Get-Date) - $start).TotalSeconds -gt $MaxSeconds } 
    } while ($false)

如果您希望保存管道的结果而不是输出它们，只需要在“do”语句之前放置一个变量。

    $result = do {
        Get-Chil...

<!--more-->
本文国际来源：[Aborting Pipeline](http://powershell.com/cs/blogs/tips/archive/2015/05/19/aborting-pipeline.aspx)
