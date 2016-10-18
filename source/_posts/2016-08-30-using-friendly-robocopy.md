layout: post
date: 2016-08-30 00:00:00
title: "PowerShell 技能连载 - 友好地使用 Robocopy"
description: PowerTip of the Day - Using Friendly Robocopy
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
*支持 PowerShell 2.0 以上版本*

Robocopy 是一个用于拷贝文件的工具，它在 PowerShell 里的功能也是一样。然而您可以用 PowerShell 将 robocopy 封装在一个对用户友好的 PowerShell 函数中。通过这种方式，您不再需要记忆 robocopy 别扭的命令行选项。取而代之的是 PowerShell 参数和智能提示功能。

一次 robocopy 的调用可能看起来如下：


```shell
PS C:\> Invoke-Robocopy -Source $env:windir -Destination c:\logs -Filter *.log -Recurse -Open
```
以下是封装函数：

```powershell
#requires -Version 3

function Invoke-Robocopy
{
    param
    (
        [String]
        [Parameter(Mandatory)]
        $Source,

        [String]
        [Parameter(Mandatory)]
        $Destination,

        [String]
        $Filter = '*',
        
        [Switch]
        $Recurse,
        
        [Switch]
        $Open
    )

    if ($Recurse)
    {
        $DoRecurse = '/S'
    }
    else
    {
        $DoRecurse = ''
    }
  
  robocopy $Source $Destination $Filter $DoRecurse /R:0 

  if ($Open)
  {
      explorer.exe $Destination
  }    
}
```

<!--more-->
本文国际来源：[Using Friendly Robocopy](http://community.idera.com/powershell/powertips/b/tips/posts/using-friendly-robocopy)
