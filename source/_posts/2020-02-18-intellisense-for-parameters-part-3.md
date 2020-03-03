---
layout: post
date: 2020-02-18 00:00:00
title: "PowerShell 技能连载 - 参数的智能感知（第 3 部分）"
description: PowerTip of the Day - IntelliSense for Parameters (Part 3)
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

您可以使用自己的 PowerShell 函数执行相同的操作，并且有多种方法可以执行此操作。在上一个技能中，我们研究了使用自定义枚举类型。今天，我们来看看更简单的方法（以及一些实现它的隐藏技巧）.

使用 IntelliSense 提供参数的最简单方法可能是使用属性 “`ValidateSet`”：您只需使用允许的值的列表来限定参数：

```powershell
function Get-Vendor
{
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Microsoft','Amazon','Google')]
        [string]
        $Vendor
    )

    "Chosen vendor: $Vendor"
}
```

`$vendor` 变量是 "`string`" 类型的，但是 PowerShell 内部会确保只能赋值为 "ValidateSet" 中列出的值。您也可以对常规变量使用相同的技巧，并为代码增加额外的安全性：

```powershell
[ValidateSet('dc1','dc2','ms01')]$servers = 'dc1'

# works
$servers = 'dc2'

# fails
$servers = 'dc3'
```

以下是另一个技巧："ValidateSet" 属性仅适用于变量和参数分配，而不适用于参数设置值。作为函数作者，您可以将一个用户不可选的值作为缺省值赋给参数：

```powershell
function Get-Vendor {
    param(
        [ValidateSet('Microsoft','Amazon','Google')]
        [string]
        $Vendor = 'Undefined'
    )

    "Chosen vendor: $Vendor"
}
```

当用户调用不带参数的 `Get-Vendor` 时，`$vendor` 将设置为 "Undefined"。用户为参数分配值后，该值将不可用，从而轻松帮助您区分用户是否进行了选择。

<!--本文国际来源：[IntelliSense for Parameters (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/intellisense-for-parameters-part-3)-->

