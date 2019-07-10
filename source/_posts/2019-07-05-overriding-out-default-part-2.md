---
layout: post
date: 2019-07-05 00:00:00
title: "PowerShell 技能连载 - 覆盖 Out-Default（第 2 部分）"
description: PowerTip of the Day - Overriding Out-Default (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您覆盖 `Out-Default` 指令，做一些有意义的事情时，您需要确保原始的行为没有丢失，而只是加入新的功能。以下是一个使用“代理函数“概念的示例。

原始输入被转发（代理）到原始的 `Out-Default` cmdlet。此外，函数打开自己的私有 `Out-GridView` 窗口并将输出回显到该窗口。

```powershell
function Out-Default
{
    param(
        [switch]
        $Transcript,

        [Parameter(ValueFromPipeline=$true)]
        [psobject]
        $InputObject
    )

    begin
    {
        $pipeline = { Microsoft.PowerShell.Core\Out-Default @PSBoundParameters }.GetSteppablePipeline($myInvocation.CommandOrigin)
        $pipeline.Begin($PSCmdlet)

        $grid = { Out-GridView -Title 'Results' }.GetSteppablePipeline()
        $grid.Begin($true)

    }

    process
    {
        $pipeline.Process($_)
        $grid.Process($_)
    }

    end
    {
        $pipeline.End()
        $grid.End()
    }

}
`

要移除覆盖函数，只需要运行：

```powershell
PS C:\> del function:Out-Default
```

<!--本文国际来源：[Overriding Out-Default (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/overriding-out-default-part-2)-->

