layout: post
date: 2017-05-03 00:00:00
title: "PowerShell 技能连载 - 翻译错误记录"
description: PowerTip of the Day - Translating Error Records
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
Whenever PowerShell records an error, it wraps it in an Error Record object. Here is a function that takes such an error record and extracts the useful information:
当 PowerShell 记录一个错误时，它将错误信息包装在一个 Error Record 对象中。以下是一个处理这种错误记录并解析有用信息的函数：

```powershell
#requires -Version 3.0
function Get-ErrorDetail
{
  param
  (
    [Parameter(Mandatory,ValueFromPipeline)]
    $e
  )
  process
  {
    if ($e -is [Management.Automation.ErrorRecord])
    {
      [PSCustomObject]@{
        Reason    = $e.CategoryInfo.Reason
        Exception = $e.Exception.Message
        Target    = $e.CategoryInfo.TargetName
        Script    = $e.InvocationInfo.ScriptName
        Line      = $e.InvocationInfo.ScriptLineNumber
        Column    = $e.InvocationInfo.OffsetInLine
        Datum     = Get-Date
        User      = $env:USERNAME
      }
    }
  }
}
```

如果您想知道最后的错误信息是什么，请试试这个：

```powershell
PS C:\> $error | Get-ErrorDetail | Out-GridView

PS C:\>
```

或者，您现在可以简单地命令一个 cmdlet 缓存它的错误信息，并在晚些时候处理它们。这个例子递归地在 Windows 文件夹中搜索 PowerShell 脚本。您可以获取结果，以及搜索时发生的所有错误的详细信息：

```powershell
$files = Get-ChildItem -Path c:\Windows -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue -ErrorVariable myErrors

$myErrors| Get-ErrorDetail | Out-GridView
```

<!--more-->
本文国际来源：[Translating Error Records](http://community.idera.com/powershell/powertips/b/tips/posts/translating-error-records)
