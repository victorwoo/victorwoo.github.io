---
layout: post
date: 2020-02-28 00:00:00
title: "PowerShell 技能连载 - 神秘的动态参数完成器"
description: PowerTip of the Day - Secret Dynamic Argument Completer
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们介绍了鲜为人知的 "`ArgumentCompletion`" 属性，该属性可以为参数提供类似 IntelliSense 的自动完成功能。但是，此属性可以做的更多。之前，我们介绍了以下代码：

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

当用户调用 `Get-Vendor` 时，通过按 TAB 或 CTRL-SHIFT 键，将显示 "`ArgumentCompleter`" 属性中列出的建议。

您可能想知道为什么将字符串列表嵌入大括号（脚本块）中。答案是：因为这段代码实际上是在用户调用完成时执行的。您也可以动态生成该自动完成文本。

这个 `Submit-Date` 函数具有一个称为 `-Date` 的参数。每当您按 TAB 键时，自动完成程序都会以引用的 ISO 格式完成当前日期和时间：

```powershell
function Submit-Date {
    param(
        [Parameter(Mandatory)]
        [ArgumentCompleter({ '"{0}"' -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss") })]
        [DateTime]
        $Date
    )

    "Chosen date: $Date"
}
```

运行代码来试验效果。接下来，输入 `Submit-Date`，以及一个空格，然后按 TAB 键。

```powershell
PS> Submit-Date -Date "2020-01-21 16:33:19"
```

同样，下一个函数实现 `-FileName` 参数，当您按 TAB 键时，它将自动完成 Windows 文件夹中的实际文件名：

```powershell
function Get-File {
    param(
        [Parameter(Mandatory)]
        [ArgumentCompleter({Get-ChildItem -Path $env:windir -Name})]
        [string]
        $FileName
    )

    "Chosen file name: $FileName"
}

Get-File -FileName
```

每当用户通过按 TAB 或 CTRL-SPACE 调用自动完成功能时，都会执行提交到 ArgumentCompleter 的脚本块中的代码，并将结果用于自动完成功能。

这可能就是为什么 `AutoCompleter` 属性不会自动弹出 IntelliSense 而是仅响应用户请求自动弹出的原因。请注意，自动完成功能可能无法在编辑器窗格中使用。它是为交互式PowerShell控制台设计的。

<!--本文国际来源：[Secret Dynamic Argument Completer](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/secret-dynamic-argument-completer)-->

