---
layout: post
date: 2019-04-11 00:00:00
title: "PowerShell 技能连载 - Get-PSCallStack 和调试"
description: PowerTip of the Day - Get-PSCallStack and Debugging
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们使用 `Get-PSCallStack` 来确定代码的“调用深度”。今天我们来看看如何使用这个 cmdlet 来帮助调试。要演示这个功能，请将以下代码保存为一个脚本文件。将它保存为一个 ps1 文件十分重要。请在 PowerShell ISE 中执行它。

```powershell
function test1
{
    test2
}

function test2
{
Wait-Debugger
Get-Process

}

test1
```

`test1` 调用了 `test2`，并且在 `test2` 中，有一个 `Wait-Debugger` 调用。这个 cmdlet 是从 PowerShell 5 开始引入的。它会导致代码暂停并调用调试器。如果您使用的是一个早版本的 PowerShell，那么可以通过 `F9` 键设置一个断点。当您运行这段代码时，调试器会在 `Get-Process` 正要执行之前暂停，并且该行代码会以黄色高亮（如果没有效果，请检查是否已将代码保存为文件？）。

在交互式的 PowerShell 控制台中，您现在可以键入 `Get-PSCallStack` 来检查在代码块中停在哪里：

    [DBG]: PS C:\>> Get-PSCallStack

    Command Arguments Location
    ------- --------- --------
    test2   {}        a1.ps1: Line 11
    test1   {}        a1.ps1: Line 5
    a1.ps1  {}        a1.ps1: Line 14

输出结果显示您当前位于函数 `test2` 中，它是被 `test1` 调用，而 `test1` 是被 `a1.ps1` 调用。

您还可以通过 `InvocationInfo` 属性看到更多的信息：

```powershell
[DBG]: PS C:\>> Get-PSCallStack | Select-Object -ExpandProperty InvocationInfo


MyCommand             : test2
BoundParameters       : {}
UnboundArguments      : {}
ScriptLineNumber      : 5
OffsetInLine          : 5
HistoryId             : 17
ScriptName            : C:\Users\tobwe\Documents\PowerShell\a1.ps1
Line                  :     test2

PositionMessage       : In C:\Users\tobwe\Documents\PowerShell\a1.ps1:5 Line:5
                        +     test2
                        +     ~~~~~
PSScriptRoot          : C:\Users\tobwe\Documents\PowerShell
PSCommandPath         : C:\Users\tobwe\Documents\PowerShell\a1.ps1
InvocationName        : test2
PipelineLength        : 1
PipelinePosition      : 1
ExpectingInput        : False
CommandOrigin         : Internal
DisplayScriptPosition :

MyCommand             : test1
BoundParameters       : {}
UnboundArguments      : {}
ScriptLineNumber      : 14
OffsetInLine          : 1
HistoryId             : 17
ScriptName            : C:\Users\tobwe\Documents\PowerShell\a1.ps1
Line                  : test1

PositionMessage       : In C:\Users\tobwe\Documents\PowerShell\a1.ps1:14 Line:1
                        + test1
                        + ~~~~~
PSScriptRoot          : C:\Users\tobwe\Documents\PowerShell
PSCommandPath         : C:\Users\tobwe\Documents\PowerShell\a1.ps1
InvocationName        : test1
PipelineLength        : 1
PipelinePosition      : 1
ExpectingInput        : False
CommandOrigin         : Internal
DisplayScriptPosition :

MyCommand             : a1.ps1
BoundParameters       : {}
UnboundArguments      : {}
ScriptLineNumber      : 0
OffsetInLine          : 0
HistoryId             : 17
ScriptName            :
Line                  :
PositionMessage       :
PSScriptRoot          :
PSCommandPath         :
InvocationName        : C:\Users\tobwe\Documents\PowerShell\a1.ps1
PipelineLength        : 2
PipelinePosition      : 1
ExpectingInput        : False
CommandOrigin         : Internal
DisplayScriptPosition :
```

<!--本文国际来源：[Get-PSCallStack and Debugging](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/get-pscallstack-and-debugging)-->

