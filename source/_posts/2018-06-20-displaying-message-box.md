---
layout: post
date: 2018-06-20 00:00:00
title: "PowerShell 技能连载 - 显示消息框"
description: PowerTip of the Day - Displaying Message Box
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您希望显示一个带有按钮，可供用户点击的消息框，请试试这个函数：

```powershell
function Show-MessageBox
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [String]
    $Text,

    [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [String]
    $Caption,

    [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [Windows.MessageBoxButton]
    $Button,

    [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [Windows.MessageBoxImage]
    $Icon

  )

  process
  {
    try
    {
      [System.Windows.MessageBox]::Show($Text, $Caption, $Button, $Icon)
    }
    catch
    {
      Write-Warning "Error occured: $_"
    }
  }
}
```

以下是它的使用方法：

```powershell
PS> Show-MessageBox -Text 'Do you want to reboot now?' -Caption Reboot -Button YesNoCancel -Icon Exclamatio
```

<!--本文国际来源：[Displaying Message Box](http://community.idera.com/powershell/powertips/b/tips/posts/displaying-message-box)-->
