---
layout: post
date: 2018-12-05 00:00:00
title: "PowerShell 技能连载 - 为代码执行添加超时（第 1 部分）"
description: PowerTip of the Day - Executing Code with a Timeout (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果希望某些代码不会无限执行下去，您可以使用后台任务来实现超时机制。以下是一个示例函数：

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

    $j = Start-Job -ScriptBlock $Code
    $completed = Wait-Job $j -Timeout $Timeout
    if ($completed -eq $null)
    {
        throw "Job timed out."
        Stop-Job -Job $j
    }
    else
    {
        Receive-Job -Job $j
    }
    Remove-Job -Job $j
}
```

所以基本上说，要让代码执行的时间不超过 5 秒，请试试以下代码：

```powershell
PS> Invoke-CodeWithTimeout -Code { Start-Sleep -Seconds 6; Get-Date } -Timeout 5
Job timed out.
At line:18 char:7
+       throw "Job timed out."
+       ~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (Job timed out.:String) [], RuntimeException
    + FullyQualifiedErrorId : Job timed out.


PS> Invoke-CodeWithTimeout -Code { Start-Sleep -Seconds 3; Get-Date } -Timeout 5

Thursday November 1, 2018 14:53:26
```

该方法有效。但是，它所使用的作业相关的开销相当大。创建后台作业并将数据返回到前台任务的开销可能增加了额外的时间。所以我们将在明天的技能中寻求一个更好的方法。

<!--本文国际来源：[Executing Code with a Timeout (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/executing-code-with-a-timeout-part-1)-->
