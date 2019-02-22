---
layout: post
date: 2018-04-25 00:00:00
title: "PowerShell 技能连载 - 转换错误记录"
description: PowerTip of the Day - Converting Error Records
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当 PowerShell 抛出错误时，会向 `$error` 写入一条错误记录，它是一个存储最后发生的错误的数组。

您可以尝试从 `ErrorRecord` 对象手工解出相关的错误信息，或者使用以下函数：

```powershell
function ConvertFrom-ErrorRecord
{
  [CmdletBinding(DefaultParameterSetName="ErrorRecord")]
  param
  (
    [Management.Automation.ErrorRecord]
    [Parameter(Mandatory,ValueFromPipeline,ParameterSetName="ErrorRecord", Position=0)]
    $Record,

    [Object]
    [Parameter(Mandatory,ValueFromPipeline,ParameterSetName="Unknown", Position=0)]
    $Alien
  )

  process
  {
    if ($PSCmdlet.ParameterSetName -eq 'ErrorRecord')
    {
      [PSCustomObject]@{
        Exception = $Record.Exception.Message
        Reason    = $Record.CategoryInfo.Reason
        Target    = $Record.CategoryInfo.TargetName
        Script    = $Record.InvocationInfo.ScriptName
        Line      = $Record.InvocationInfo.ScriptLineNumber
        Column    = $Record.InvocationInfo.OffsetInLine
      }
    }
    else
    {
      Write-Warning "$Alien"
    }
  }
}
```

这个函数有两个参数集，一个合法的 `ErrorRecord` 对象自动绑定到 `$Record` 参数。如果遇到一个不同类型的，无法被这个函数处理的对象，那么它将绑定到 `$Alien`。

要查看详细的错误信息，请试试这行代码：

```powershell
PS> $error | ConvertFrom-ErrorRecord | Out-GridView
```

<!--本文国际来源：[Converting Error Records](http://community.idera.com/powershell/powertips/b/tips/posts/converting-error-records)-->
