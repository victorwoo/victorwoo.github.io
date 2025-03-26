---
layout: post
date: 2022-05-26 00:00:00
title: "PowerShell 技能连载 - 为 PowerShell 创建 sudo（第 1 部分）"
description: PowerTip of the Day - Creating sudo for PowerShell (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 Linux Shells 中，有一个名为 "`sudo`" 的命令，可以通过它运行具有提升特权的命令。在 Powershell 中，您必须打开一个具有更高特权的全新 shell。

让我们尝试将 sudo 命令添加到 PowerShell。 我们想要一个名为 "sudo" 的新命令，它至少需要一个命令名称，但随后还需要一个可变的空格分隔的参数。这是函数的定义：

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

`param()` 块定义输入参数。`$FilePath` 是强制性的（必须）。`$Arguments` 是可选的，但通过属性 `ValueFromRemainingArguments` 装饰，因此它是一个所谓的“参数数组”，它能接受剩下的所有未绑定到其它形参的输入参数。


运行这段代码，然后尝试一些用例。`$PSBoundParameters` 显示该函数如何接收您的输入参数：

这是我测试的内容，它似乎按预期工作：

```powershell
PS> sudo notepad c:\test

Key          Value
---          -----
FilePath     notepad
ArgumentList {c:\test}



PS> sudo ping 127.0.0.1 -n 1

Key          Value
---          -----
FilePath     ping
ArgumentList {127.0.0.1, -n, 1}
```

Now that the sudo function body works, in part 2 we look at the actual implantation of running commands elevated.
现在，sudo 函数体能正常工作，在第二部分中，我们将学习实际注入一个函数并提升权限。

<!--本文国际来源：[Creating sudo for PowerShell (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-sudo-for-powershell-part-1)-->

