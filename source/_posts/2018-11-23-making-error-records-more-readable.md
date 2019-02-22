---
layout: post
date: 2018-11-23 00:00:00
title: "PowerShell 技能连载 - 增强错误记录的可读性"
description: PowerTip of the Day - Making Error Records More Readable
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当 PowerShell 遇到错误时，它将抛出包含关于该错误详细信息的错误记录。不幸的是，这些对象有点儿难懂，而且缺省情况下不会显示所有信息。相比之下，以下函数有着无价的帮助信息：

```powershell
function ConvertFrom-ErrorRecord
{
  param
  (
    # we receive either a legit error record...
    [Management.Automation.ErrorRecord[]]
    [Parameter(
        Mandatory,ValueFromPipeline,
        ParameterSetName='ErrorRecord')]
    $ErrorRecord,

    # ...or a special stop exception which is raised by
    # cmdlets with -ErrorAction Stop
    [Management.Automation.ActionPreferenceStopException[]]
    [Parameter(
        Mandatory,ValueFromPipeline,
        ParameterSetName='StopException')]
    $Exception
  )



  process
  {
    # if we received a stop exception in $Exception,
    # the error record is to be found inside of it
    # in all other cases, $ErrorRecord was received
    # directly
    if ($PSCmdlet.ParameterSetName -eq 'StopException')
    {
      $ErrorRecord = $Exception.ErrorRecord
    }

    # compose a new object out of the interesting properties
    # found in the error record object
    $ErrorRecord | ForEach-Object { [PSCustomObject]@{
        Exception = $_.Exception.Message
        Reason    = $_.CategoryInfo.Reason
        Target    = $_.CategoryInfo.TargetName
        Script    = $_.InvocationInfo.ScriptName
        Line      = $_.InvocationInfo.ScriptLineNumber
        Column    = $_.InvocationInfo.OffsetInLine
      }
    }
  }
}
```

您可以在 `$error` 中辨认出收集到的错误信息：

```powershell
PS C:\> $Error | ConvertFrom-ErrorRecord | Out-GridView
```

您也可以在 `try..catch` 代码快中使用它：

```powershell
try
{
  Get-Service -Name foo -ErrorAction Stop

}
catch
{
  $_ | ConvertFrom-ErrorRecord
}
```

结果类似这样：

    Exception : Cannot find any service with service name 'foo'.
    Reason    : ServiceCommandException
    Target    : foo
    Script    :
    Line      : 5
    Column    : 3

您甚至可以用 `-ErrorVariable` 通用参数来收集一个 cmdlet 运行时发生的所有错误记录：

```powershell
$r = Get-ChildItem -Path $env:windir -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue -ErrorVariable test
$test | ConvertFrom-ErrorRecord
```

相同地，结果类似这样：

    Exception : Access to the path 'C:\Windows\AppCompat\Appraiser\Telemetry' is
                denied.
    Reason    : UnauthorizedAccessException
    Target    : C:\Windows\AppCompat\Appraiser\Telemetry
    Script    :
    Line      : 3
    Column    : 6

    Exception : Access to the path 'C:\Windows\AppCompat\Programs' is denied.
    Reason    : UnauthorizedAccessException
    Target    : C:\Windows\AppCompat\Programs
    Script    :
    Line      : 3
    Column    : 6

    Exception : Access to the path 'C:\Windows\CSC\v2.0.6' is denied.
    Reason    : UnauthorizedAccessException
    Target    : C:\Windows\CSC\v2.0.6
    Script    :
    Line      : 3
    Column    : 6

    ...

<!--本文国际来源：[Making Error Records More Readable](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/making-error-records-more-readable)-->
