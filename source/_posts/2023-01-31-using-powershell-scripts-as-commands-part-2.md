---
layout: post
date: 2023-01-31 05:30:19
title: "PowerShell 技能连载 - 将 PowerShell 脚本作为命令（第 2 部分）"
description: PowerTip of the Day - Using PowerShell Scripts as Commands (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们讨论了一种扩展 PowerShell 命令集的简易方法。通过将脚本保存到一个文件夹中，并且将文件夹添加到环境变量 `$env:path` 中，PowerShell 将会识别出该文件夹中的所有脚本并将它们作为新命令。

PowerShell 脚本支持和函数相同的用户参数机制。让我们看看如何将一个使用参数的新的基于脚本的命令加入 PowerShell。

将以下脚本保存到 c:\myPsCommands 目录中的 "New-Password.ps1"。您可能需要先创建该文件夹。

```powershell
[CmdletBinding()]
param
(
    $CapitalLetter = 4,
    $Numeric = 1,
    $LowerLetter = 3,
    $Special = 2
)

$characters = & {
    'ABCDEFGHKLMNPRSTUVWXYZ' -as [char[]] |
    Get-Random -Count $CapitalLetter

    '23456789'.ToCharArray() |
    Get-Random -Count $Numeric

    'abcdefghkmnprstuvwxyz'.ToCharArray() |
    Get-Random -Count $LowerLetter

    '§$%&?=#*+-'.ToCharArray() |
    Get-Random -Count $Special

} | Sort-Object -Property { Get-Random }
$characters -join ''
```

下一步，将文件夹路径添加到 PowerShell 的命令搜索路径，例如运行这段代码：

```powershell
PS> $env:path += ";c:\myPSCommands"
```

现在您可以想普通命令一样运行存储在文件夹中的任意脚本。如果脚本的开始处有 `param()` 块，那么支持传入参数。当您按示例操作后，就可以得到一个名为 `New-Password` 的命令，用来生成复杂密码，以及通过参数帮您组合密码：

```powershell
PS> New-Password -CapitalLetter 2 -Numeric 1 -LowerLetter 8 -Special 2
yx+nKfph?M8rw
```
<!--本文国际来源：[Using PowerShell Scripts as Commands (Part 2)](https://blog.idera.com/database-tools/powershell/powertips/using-powershell-scripts-as-commands-part-2/)-->

