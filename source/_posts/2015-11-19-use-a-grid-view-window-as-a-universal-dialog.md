layout: post
date: 2015-11-19 12:00:00
title: "PowerShell 技能连载 - 使用网格窗口作为一个通用的对话框"
description: PowerTip of the Day - Use a Grid View Window as a Universal Dialog
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
`Out-GridView` 不止可以用于显示结果。您可以将它转换为一个很有用的通用对话框。

假设您希望显示一系列运行中的程序，然后结束掉选中的程序。传统的方式大概是这样：

    Get-Process |
      Where-Object { $_.MainWindowTitle } |
      Out-GridView -OutputMode Single |
      Stop-Process -WhatIf

当您将源对象通过管道传给 `Out-GridView` 命令时，用户将能看到所有的普通对象属性。这也许没问题，但如果您希望用户体验更好一些，您可以使用一些更高级的 PowerShell 技巧：

    #requires -Version 3
    
    $prompt = 'Choose the process you want to terminate:'
    
    Get-Process |
      Where-Object { $_.MainWindowTitle } |
      ForEach-Object {
        New-Object PSObject -Property @{$prompt = $_ | Add-Member -MemberType ScriptMethod -Name ToString -Force -Value  { '{0} [{1}]' -f $this.Description, $this.Id } -PassThru }
      } |
      Out-GridView -OutputMode Single -Title $prompt |
      Select-Object -ExpandProperty $prompt |
      Stop-Process -WhatIf

请先看用户体验：该网格窗口不再让人感到疑惑。现在让我们检查一下如何实现这种用户体验。

在结果通过管道传给 `Out-GridView` 之前，它们被重新打包成一个只有单个属性的对象。该属性包含了您在 `$prompt` 中定义的名称，所以它基本上就是您想呈现给用户的信息。

当您做完这些并将包裹后的对象通过管道传给 `Out-GridView` 后，您可以看到该对象的文字呈现。要控制文字呈现的方式，我们将它的 `ToString()` 方法用一个显示您期望的值的方法来覆盖。在这个例子里，它显示进程的描述和进程的 ID。

最后，被用户选中的对象将再被拆包。通过这种方法，您可以获取源对象。

<!--more-->
本文国际来源：[Use a Grid View Window as a Universal Dialog](http://powershell.com/cs/blogs/tips/archive/2015/11/19/use-a-grid-view-window-as-a-universal-dialog.aspx)
