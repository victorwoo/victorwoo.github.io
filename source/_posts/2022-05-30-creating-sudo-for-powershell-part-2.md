---
layout: post
date: 2022-05-30 00:00:00
title: "PowerShell 技能连载 - 为 PowerShell 创建 sudo（第 2 部分）"
description: PowerTip of the Day - Creating sudo for PowerShell (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当我们尝试为 PowerShell 创建一个 sudo 命令——来提升单个命令的权限——在第一部分中我们创建了 sudo 函数体：

```powershell
function sudo
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $FilePath,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]
        $ArgumentList

    )

    $PSBoundParameters
}
```

现在，让我们用实际的逻辑替换 `$PSBoundParameters`，以运行提升权限的命令。`Start-Process` 可以解决这个问题。例如，这段代码将在用户 "Tobias" 下启动提升权限的记事本：

```powershell
PS> Start-Process -FilePath notepad -ArgumentList $env:windir\system32\drivers\etc\hosts -Verb runas
```

巧合的是，我们的 sudo 函数体的参数名称与 `Start-Process` 所需的参数名称匹配，因此实现很简单：使用 splatting，并且将用户在自动定义的 `$PSBoundParameters` 哈希表中传入的参数传递给 `Start-Process`——这就是所有步骤：

并传递在自动定义的哈希表$ psboundparameters中找到的用户供给参数，以启动过程 -  全部：

```powershell
function sudo
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $FilePath,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]
        $ArgumentList

    )

    Start-Process @PSBoundParameters -Verb Runas
}
```

运行代码，然后测试新的 `sudo` 命令。事实证明，您现在可以在脚本中运行提升权限的单个命令。同时，您将体会到 Windows 中的主要设计差异：所有命令都在自己的窗口中运行，并且无法从提升权限的命令中将结果重定向到您的 PowerShell。

虽然我们的 sudo 命令可能对提升权限很有用，但是当您想从提升权限的命令中获取信息时会受到限制。Windows 架构禁止该操作。

您在过程中学到了如何创建函数参数，例如接受可变数量参数的 "ArgumentList"。

<!--本文国际来源：[Creating sudo for PowerShell (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-sudo-for-powershell-part-2)-->

