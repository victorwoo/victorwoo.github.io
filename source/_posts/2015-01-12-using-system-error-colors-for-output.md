layout: post
date: 2015-01-12 12:00:00
title: "PowerShell 技能连载 - 在输出中使用系统的错误颜色"
description: PowerTip of the Day - Using System Error Colors for Output
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

如果您的脚本希望输出警告或错误信息，您可以使用 `Write-Warning` 或 `Write-Error` 指令。两个 cmdlet 都会使用缺省的 PowerShell 颜色来显示警告和错误。然而，这两个 cmdlet 也会为您的输出结果套用一个文字模板：

    PS> Write-Warning -Message 'This  is a warning'
    WARNING: This is a warning
     
    PS> Write-Error -Message  'Something went wrong'
    Write-Error -Message 'Something went wrong'  : Something went wrong
        +  CategoryInfo          : NotSpecified: (:)  [Write-Error], WriteErrorException
        +  FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException

`Write-Error` 添加了一堆无意义的异常详细信息，而您所需要的只是错误文本。一个更好的方式是：

    PS>  $host.UI.WriteErrorLine('Something went wrong...')
    Something went wrong...

警告和错误的颜色可以通过这种方式配置：

      
    PS>  $host.UI.WriteErrorLine('Something went wrong...')
    Something went wrong...
    
    PS> $host.PrivateData.ErrorBackgroundColor  = 'White'
    
    PS>  $host.UI.WriteErrorLine('Something went wrong...')
    Something  went wrong...
    
    PS> $host.PrivateData
    
    (...)
    ErrorForegroundColor                      : #FFFF0000
    ErrorBackgroundColor                      : #FFFFFFFF
    WarningForegroundColor                    : #FFFF8C00
    WarningBackgroundColor                    : #00FFFFFF
    VerboseForegroundColor                    : #FF00FFFF
    VerboseBackgroundColor                    : #00FFFFFF
    DebugForegroundColor                      : #FF00FFFF
    DebugBackgroundColor                      : #00FFFFFF
    (...)

<!--more-->
本文国际来源：[Using System Error Colors for Output](http://community.idera.com/powershell/powertips/b/tips/posts/using-system-error-colors-for-output)
