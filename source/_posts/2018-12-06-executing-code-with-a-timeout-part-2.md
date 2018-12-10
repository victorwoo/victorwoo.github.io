---
layout: post
date: 2018-12-06 00:00:00
title: "PowerShell 技能连载 - 为代码执行添加超时（第 2 部分）"
description: PowerTip of the Day - Executing Code with a Timeout (Part 2)
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
在前一个技能中我们通过 PowerShell 后台作业实现了超时机制，这样您可以设置某段代码执行的最大允许时间，超过该时间将抛出一个异常。

以下是一个更轻量级的替代，它使用进程内线程，而不是进程外执行：

```powershell
function Invoke-CodeWithTimeout
{
    param
    (
        [Parameter(Mandatory)]
        [ScriptBlock]
        $Code,

        [int]
        $Timeout = 5

    )

    $ps = [PowerShell]::Create()
    $null = $ps.AddScript($Code)
    $handle = $ps.BeginInvoke()
    $start = Get-Date
    do
    {
        $timeConsumed = (Get-Date) - $start
        if ($timeConsumed.TotalSeconds -ge $Timeout) {
            $ps.Stop()
            $ps.Dispose()
            throw "Job timed out."    
        }
        Start-Sleep -Milliseconds 300
    } until ($handle.isCompleted)
    
    $ps.EndInvoke($handle)
    $ps.Runspace.Close()
    $ps.Dispose()
}
```

以下是使用该新超时机制的方法：

```powershell
PS> Invoke-CodeWithTimeout -Code { Start-Sleep -Seconds 6; Get-Date } -Timeout 5
Job timed out.
At line:24 char:13
+       throw "Job timed out."
+       ~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (Job timed out.:String) [], RuntimeException
    + FullyQualifiedErrorId : Job timed out.
    

PS> Invoke-CodeWithTimeout -Code { Start-Sleep -Seconds 3; Get-Date } -Timeout 5

Thursday November 1, 2018 14:53:26
```

<!--more-->
本文国际来源：[Executing Code with a Timeout (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/executing-code-with-a-timeout-part-2)
