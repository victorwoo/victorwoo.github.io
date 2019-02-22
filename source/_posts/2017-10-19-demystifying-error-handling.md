---
layout: post
date: 2017-10-19 00:00:00
title: "PowerShell 技能连载 - 揭开错误处理的秘密"
description: PowerTip of the Day - Demystifying Error Handling
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 代码中所有的错误信息都包含在错误记录对象中。请看以下的函数，它可以从这样的错误记录中解析所有相关的错误信息：

```powershell
function Get-ErrorInfo
{
    param
    (
    [Parameter(ValueFrompipeline)]
    [Management.Automation.ErrorRecord]$errorRecord
    )


    process
    {
    $info = [PSCustomObject]@{
        Exception = $errorRecord.Exception.Message
        Reason    = $errorRecord.CategoryInfo.Reason
        Target    = $errorRecord.CategoryInfo.TargetName
        Script    = $errorRecord.InvocationInfo.ScriptName
        Line      = $errorRecord.InvocationInfo.ScriptLineNumber
        Column    = $errorRecord.InvocationInfo.OffsetInLine
        Date      = Get-Date
        User      = $env:username
    }

    $info
    }
}
```

这个函数使得错误处理代码更短更容易理解。如果您需要立即处理一个错误，请使用 `try/catch` 概念，并且确保使用 `-ErrorAction` 通知 cmdlet 当发生错误时立即停止：

```powershell
try
{
    Stop-Service -Name someservice -ErrorAction Stop
}
catch
{
    $_ | Get-ErrorInfo
}
```

如果您希望代码完成，并且在过后检查发生了哪些错误，请使用 `-ErrorAction SilentlyContinue` 以及 `-ErrorVariable`。同时，`Get-ErrorInfo` 函数有很大帮助：

```powershell
$result = Get-ChildItem -Path C:\Windows -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue -ErrorVariable myErrors
$myErrors | Get-ErrorInfo
```

<!--本文国际来源：[Demystifying Error Handling](http://community.idera.com/powershell/powertips/b/tips/posts/demystifying-error-handling)-->
