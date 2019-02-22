---
layout: post
date: 2018-05-31 00:00:00
title: "PowerShell 技能连载 - 使用神奇的脚本块参数"
description: PowerTip of the Day - Using Magic Script Block Parameters
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个例子中我们演示了 `Rename-Item` 中 `NewName` 的神奇功能。它可以接受一个新的文件名，也可以接受一个脚本块。脚本块可以用来批量命名大量文件。

我们现在来看看 PowerShell 函数如何实现这种神奇的参数！以下是一个定义了两个参数的函数：

```powershell
function Test-MagicFunc
{
  [CmdletBinding()]
  param
  (

    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline)]
    [string]
    $Par1,



    [Parameter(ValueFromPipelineByPropertyName)]
    [string]
    $Par2
  )


  begin
  {
    Write-Warning "Starting..."
  }

  process
  {
    Write-Warning "Processing Par1=$Par1 and Par2=$Par2"
  }

  end
  {
    Write-Warning "Ending..."
  }
}
```

您可以把它当作一个传统的独立函数运行：

```powershell
PS>  Test-MagicFunc -Par1 100 -Par2 50
WARNING: Starting...
WARNING: Processing  Par1=100 and Par2=50
WARNING: Ending...
```

您也可以通过管道输出来运行它，并且传入一个固定的第二参数：

```powershell
PS> 1..4 |  Test-MagicFunc -Par2 99
WARNING: Starting...
WARNING: Processing Par1=1 and Par2=99
WARNING: Processing Par1=2 and Par2=99
WARNING: Processing Par1=3 and Par2=99
WARNING: Processing Par1=4 and Par2=99
WARNING: Ending...
```

但是您也可以对的第二个参数传入一个脚本块，该脚本块引用了从管道收到的对象：

```powershell
PS> 1..4 |  Test-MagicFunc -Par2 { $_ * $_ }
WARNING: Starting...
WARNING: Processing  Par1=1 and Par2=1
WARNING: Processing  Par1=2 and Par2=4
WARNING: Processing  Par1=3 and Par2=9
WARNING: Processing  Par1=4 and Par2=16
WARNING: Ending...
```

事实证明，这个魔法十分简单：`Par2` 的参数定义显示它可以接受管道输入。它不关心是由属性名输入 (ValueFromPipelineByPropertyName) 还是通过值输入 (ValueFromPipeline)。在这些例子中，当您将一个脚本块传给参数时，PowerShell 将该脚本块当作管道输入值的接口：`$_` 引用输入的对象，脚本块可以使用任何需要的代码来计算需要绑定到参数的值。

<!--本文国际来源：[Using Magic Script Block Parameters](http://community.idera.com/powershell/powertips/b/tips/posts/using-magic-script-block-parameters)-->
