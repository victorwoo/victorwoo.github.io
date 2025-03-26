---
layout: post
date: 2023-01-31 00:00:45
title: "PowerShell 技能连载 - 将 PowerShell 脚本作为命令（第 1 部分）"
description: PowerTip of the Day - Using PowerShell Scripts as Commands (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
一种扩展 PowerShell 命令的简单方法是使用脚本。要将一段脚本转换为命令，请选择一个文件夹并将 PowerShell 脚本存储在该文件夹中。脚本的名字将会转化为命令名。

例如，将以下脚本以 "New-Password" 名字保存在一个文件夹中：

```powershell
$CapitalLetter = 4
$Numeric = 1
$LowerLetter = 3
$Special = 2

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

该脚本将产生一个随机的密码，然后您可以通过顶部的变量来控制组合。

要使用该脚本作为新的命令，请确保 PowerShell 包含您在搜索命令中保存脚本的文件夹。假设您将脚本保存在名为 "c:\myPsCommands" 文件夹下。然后运行以下代码将会将该文件夹添加到命令搜索路径中：

```powershell
$env:path += ";c:\myPsCommands"
```

一旦您做了这个调整，就可以输入命令名 "`New-Password`" 轻松运行您的脚本。本质上该脚本名称转化为一个可执行的命令名。
<!--本文国际来源：[Using PowerShell Scripts as Commands (Part 1)](https://blog.idera.com/database-tools/powershell/powertips/using-powershell-scripts-as-commands-part-1/)-->

