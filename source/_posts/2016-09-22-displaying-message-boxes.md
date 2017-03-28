layout: post
date: 2016-09-23 00:00:00
title: "PowerShell 技能连载 - 显示对话框"
description: PowerTip of the Day - Displaying Message Boxes
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
PowerShell 可以操作所有公公的 .NET 类，所以创建一个对话框真的很简单：

```powershell
$result = [System.Windows.MessageBox]::Show('Do you want to restart?','Restart','YesNo','Warning') 

$result
```

然而，您可能需要知道参数所支持的值。PowerShell 可以方便地将 .NET 调用封装成 PowerShell 函数，并提供所有参数的智能感知功能：

```powershell
#requires -Version 3.0

Add-Type -AssemblyName PresentationFramework

function Show-MessageBox
{
  param
  (
    [Parameter(Mandatory)]
    [String]
    $Prompt,

    [String]$Title = 'PowerShell',

    [Windows.MessageBoxButton]$Button = 'OK',

    [Windows.MessageBoxImage]$Icon = 'Information'    
  )

  [Windows.MessageBox]::Show($Prompt, $Title, $Button, $Icon)
}
```

当您运行这段代码后，就得到了一个超级简单的 "`Show-MessageBox`" 函数。它可以接受多个参数并且通过自动完成和智能感知为您提供正确的数据。

<!--more-->
本文国际来源：[Displaying Message Boxes](http://community.idera.com/powershell/powertips/b/tips/posts/displaying-message-boxes)
