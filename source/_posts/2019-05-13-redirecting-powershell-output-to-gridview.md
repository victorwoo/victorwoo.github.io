---
layout: post
date: 2019-05-13 00:00:00
title: "PowerShell 技能连载 - 将 PowerShell 输出重定向到 GridView"
description: PowerTip of the Day - Redirecting PowerShell Output to GridView
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当在 PowerShell 中输出数据时，它会静默地通过管道输出到 `Out-Default` 并且最终以文本的方式输出到控制台。如果我们覆盖 `Out-Default`，就可以改变它的行为，例如将所有 PowerShell 的输出改到一个网格视图窗口。实际中，您甚至可以区别对待正常的输出和错误信息，并且将两者显示在不同的窗口里。

以下是两个函数：`Enable-GridOutput` 和 `Disable-GridOutput`。当您运行 `Enable-GridOutput` 时，它会覆盖 `Out-Default` 并将常规的输出显示在 "Output" 网格视图窗口，并且将错误信息转换为有用的文本，并将它输出到一个独立的 "Error" 网格视图窗口。

当运行 `Disable-GridOutput` 后，会去掉覆盖的效果，并且回到缺省的行为：

```powershell
function Enable-GridOutput
{
    function global:Out-Default
    {
        param
        (
            [Parameter(ValueFromPipeline=$true)][Object]
            $InputObject
        )

        begin
        {
            $cmd = $ExecutionContext.InvokeCommand.
                    GetCommand('Microsoft.PowerShell.Utility\Out-GridView',
                    [Management.Automation.CommandTypes]::Cmdlet)

            $p1 = {& $cmd -Title 'Output'  }.
                    GetSteppablePipeline($myInvocation.CommandOrigin)
            $p2 = {& $cmd -Title 'Error'  }.
                    GetSteppablePipeline($myInvocation.CommandOrigin)

            $p1.Begin($PSCmdlet)
            $p2.Begin($PSCmdlet)
        }

        process
        {
            if ($_ -is [Management.Automation.ErrorRecord])
            {
                $info = $_ | ForEach-Object { [PSCustomObject]@{
                        Exception = $_.Exception.Message
                        Reason    = $_.CategoryInfo.Reason
                        Target    = $_.CategoryInfo.TargetName
                        Script    = $_.InvocationInfo.ScriptName
                        Line      = $_.InvocationInfo.ScriptLineNumber
                        Column    = $_.InvocationInfo.OffsetInLine
                    }
                }
                $p2.Process($info)
            }
            else
            {
                $p1.Process($_)
            }
        }

        end
        {
            $p1.End()
            $p2.End()
        }
    }
}

function Disable-GridOutput
{
    Remove-Item -Path function:Out-Default -ErrorAction SilentlyContinue
}
```

<!--本文国际来源：[Redirecting PowerShell Output to GridView](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/redirecting-powershell-output-to-gridview)-->

