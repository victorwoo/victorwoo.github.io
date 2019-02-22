---
layout: post
date: 2017-12-29 00:00:00
title: "PowerShell 技能连载 - 设置环境变量"
description: PowerTip of the Day - Setting Environment Variables
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有些时候您会见到一些脚本使用 `Select-Object` 向现有的对象附加信息，类似以下代码：

```powershell
Get-Process |
    Select-Object -Property *, Sender|
    ForEach-Object {
        $_.Sender = $env:COMPUTERNAME
        $_
    }
```

它可以工作，但是 `Select-Object` 创建了一个完整的对象拷贝，所以这种方法速度很慢而且改变了对象的类型。您可能注意到了 PowerShell 不再使用正常的表格方式输出进程对象，也是因为这个原因。

如果您想设置环境变量，`env:` 驱动器只能修改进程级别的环境变量。要设置用户或者机器级别的环境变量，请试试这个函数：

```powershell
function Set-EnvironmentVariable
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)][String]
        $VariableName,

        [Parameter(Mandatory)][String]
        $VariableValue,

        [Parameter(Mandatory)][EnvironmentVariableTarget]
        $Target
    )

    [Environment]::SetEnvironmentVariable($VariableName, $VariableValue, $Target)
}
```

请注意 `$Target` 变量如何使用特殊的数据类型 "EnvironmentVariableTarget" ，当您在 PowerShell ISE 或其它带有 IntelliSense 功能的编辑器中，`-Target` 参数的可选项有 "Process"、"User" 和 "Machine"。

以下是如何在用户级别创建名为 "Test"，值为 12 的环境变量的方法：

```powershell
PS C:\> Set-EnvironmentVariable -VariableName test -VariableValue 12 -Target User

PS C:\>
```

<!--本文国际来源：[Setting Environment Variables](http://community.idera.com/powershell/powertips/b/tips/posts/settingenvironmentvariables)-->
