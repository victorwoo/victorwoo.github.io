---
layout: post
date: 2018-04-26 00:00:00
title: "PowerShell 技能连载 - 在 try/catch 中使用 ConvertFrom-ErrorRecord"
description: PowerTip of the Day - Using ConvertFrom-ErrorRecord in try/catch
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们创建了一个名为 `ConvertFrom-ErrorRecord` 的函数，它能方便地从 PowerShell 的 `ErrorRecord` 对象中方便地获取错误信息。

您也可以在 catch 块中使用这个函数。只需要先运行以下函数即可：

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

以下是如何在 catch 代码块中使用 `ConvertFrom-ErrorRecord` 的例子：

```powershell
try
{
    # this raises an error
    Get-Service -Name NonExisting -ErrorAction Stop
}
catch
{
    # pipe the errorrecord object through the new function
    # to retrieve all relevant error information
    # which you then could use to do error logging, or output
    # custom error messages
    $_ | ConvertFrom-ErrorRecord

}
```

<!--本文国际来源：[Using ConvertFrom-ErrorRecord in try/catch](http://community.idera.com/powershell/powertips/b/tips/posts/using-convertfrom-errorrecord-in-try-catch)-->
