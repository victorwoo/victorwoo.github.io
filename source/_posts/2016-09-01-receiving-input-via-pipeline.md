layout: post
date: 2016-09-01 00:00:00
title: "PowerShell 技能连载 - 通过管道输入数据"
description: PowerTip of the Day - Receiving Input via Pipeline
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
在前一个技能里我们演示了 `Convert-Umlaut` 如何转换一个字符串中的特殊字符。这在一个函数接受管道输入的时候更有用。让我们来看看增加这种特性所需要做的改变。

在不支持管道的情况下，该函数大概长这个样子：

```powershell
#requires -Version 3

function Convert-Umlaut
{
  param
  (
    [Parameter(Mandatory)]
    $Text
  )

  $output = $Text.Replace('ö','oe').Replace('ä','ae').Replace('ü','ue').Replace('ß','ss').Replace('Ö','Oe').Replace('Ü','Ue').Replace('Ä','Ae')
  $isCapitalLetter = $Text -ceq $Text.toUpper()
  if ($isCapitalLetter) 
  { 
    $output = $output.toUpper() 
  }
  $output
}
```

可以通过这种方式执行：


```shell
PS C:\> Convert-Umlaut -Text "Mößler, Christiansön" 
Moessler, Christiansoen
```

然而，它不能像这样执行：


```shell
PS C:\> "Mößler, Christiansön" | Convert-Umlaut
```
要增加管道功能，需要做两件事：

1. 参数需要标记为支持管道数据。
2. 在迭代中对每个输入的元素进行处理的代码需要放置在 "`process`" 代码块中。

以下是改变后的代码：

```powershell
#requires -Version 3

function Convert-Umlaut
{
  param
  (
    [Parameter(Mandatory, ValueFromPipeline)]
    $Text
  )

  process
  {
    $output = $Text.Replace('ö','oe').Replace('ä','ae').Replace('ü','ue').Replace('ß','ss').Replace('Ö','Oe').Replace('Ü','Ue').Replace('Ä','Ae')
    $isCapitalLetter = $Text -ceq $Text.toUpper()
    if ($isCapitalLetter) 
    { 
      $output = $output.toUpper() 
    }
    $output
  }
}
```

现在，也可以通过管道传输数据了：

```shell
    PS C:\> "Mößler, Christiansön" | Convert-Umlaut 
    Moessler, Christiansoen
```

<!--more-->
本文国际来源：[Receiving Input via Pipeline](http://community.idera.com/powershell/powertips/b/tips/posts/receiving-input-via-pipeline)
