---
layout: post
date: 2020-02-20 00:00:00
title: "PowerShell 技能连载 - 参数的智能感知（第 4 部分）"
description: PowerTip of the Day - IntelliSense for Parameters (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果输入参数时会为用户建议有效的参数，那岂不是很棒？有时候它们会提示。当您键入以下命令并在 `-LogName` 之后按空格时，PowerShell ISE 和 Visual Studio Code 会弹出一个 IntelliSense 菜单，其中包含您可以转储的所有日志文件：

```powershell
PS> Get-EventLog -LogName
```

如果没有弹出自动 IntelliSense（换句话说在 PowerShell 控制台中），则可以按 TAB 键自动完成操作，或者按 CTRL + SPACE 手动强制显示 IntelliSense 选择项。

您可以使用自己的 PowerShell 函数执行相同的操作，并且有多种方法可以执行此操作。在上一个技能中，我们研究了 "`ValidateSet`" 属性。今天，我们来看看一个更超级隐蔽的类似属性，名为 "`ArgumentCompleter`".

通过 `ValidateSet`，您可以定义一系列用户可以选择的值。其它值都不允许输入。

如果您想向用户提供建议（例如）最常用的服务器，但又允许用户指定完全不同的服务器怎么办？这正是 "`ArgumentCompleter`" 属性起作用的时候。它定义了一个建议值的列表，但并不限制用户使用这些值：

```powershell
function Get-Vendor {
    param(
        [Parameter(Mandatory)]
        [ArgumentCompleter({'Microsoft','Amazon','Google'})]
        [string]
        $Vendor
    )

    "Chosen vendor: $Vendor"
}
```

在交互式 PowerShell 控制台中运行此命令并调用 `Get-Vendor` 时，现在可以按 TAB 或 CTRL + SPACE 自动完成或打开 IntelliSense 列表。不过，该属性不会自动为您弹出 IntelliSense 菜单，并且在 PowerShell 编辑器的编辑器窗格中可能无法使用。

尽管如此，"`ArgumentCompleter`" 属性还是有很大帮助的，特别是对于经常使用命令和制表符完成功能的高级用户而言。通过为参数添加默认选项，用户可以快速浏览这些选项，但也可以提交任何其他参数。

<!--本文国际来源：[IntelliSense for Parameters (Part 4)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/intellisense-for-parameters-part-4)-->

