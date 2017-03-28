layout: post
date: 2016-02-03 12:00:00
title: "PowerShell 技能连载 - 处理数据（第 1 部分）"
description: PowerTip of the Day - Processing Data (Part 1)
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
这是关于 PowerShell 函数如何通过管道或参数接受数据的三个技巧中的第一个。

在第一部分中，函数实时处理输入的信息。这消耗最少的内存并且快速提供结果：

```powershell
#requires -Version 2
function Process-Data
{  
  param  (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [Object[]]
    $Object  )

  process  {
    foreach ($element in $Object)
    {
      "Processing received element $element..."    
    }
  }
}
```

请注意如何通过参数调用函数：

```shell
PS C:\> Process-Data -Object 1
Processing received element 1...

PS C:\> Process-Data -Object 1,2,3,4
Processing received element 1...
Processing received element 2...
Processing received element 3...
Processing received element 4... 
```

您也可以通过管道传送信息：

```shell
PS C:\> 1..4 | Process-Data
Processing received element 1...
Processing received element 2...
Processing received element 3...
Processing received element 4... 
```

<!--more-->
本文国际来源：[Process Data (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/processing-data-part-1)
