---
layout: post
date: 2020-02-14 00:00:00
title: "PowerShell 技能连载 - 参数的智能感知（第 2 部分）"
description: PowerTip of the Day - IntelliSense for Parameters (Part 2)
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

您可以使用自己的 PowerShell 函数执行相同的操作，并且有多种方法可以执行此操作。在上一个技能中，我们研究了使用枚举类型。但是，如果没有您想要向用户建议的枚举类型定义值，该怎么办？

要么使用“`Enum`＂＂关键字定义自己的枚举类型（在 PowerShell 5 或更高版本中支持）：

```powershell
Enum MyVendors
{
    Microsoft
    Amazon
    Google
}

function Get-Vendor
{
    param(
        [Parameter(Mandatory)]
        [MyVendors]
        $Vendor
    )

    "Chosen vendor: $Vendor"
}
```

或使用 `Add-Type`（所有 PowerShell 版本都支持）使用 C# 创建自己的枚举（请参见下文）。请注意，C# 代码区分大小写，并且枚举内的值以逗号分隔。“`enum`” 关键字后面的词定义了枚举的类型名称。使用该名称作为参数的数据类型：

```powershell
$definition = 'public enum VendorList
{
    Microsoft,
    Amazon,
    Google
}'
Add-Type -TypeDefinition $definition


function Get-Vendor
{
    param(
        [Parameter(Mandatory)]
        [VendorList]
        $Vendor
    )

    "Chosen vendor: $Vendor"
}
```

还要注意，`Add-Type` 不能编辑或覆盖类型，因此，如果要在使用枚举后更改枚举，则需要重新启动 PowerShell 或重命名枚举。而使用更新的 PowerShell “`enum`” 关键字，您可以随时更改枚举。

通过这两种方式，当用户调用您的函数并使用参数时，IntelliSense 都会列出可用的值。

```powershell
PS> Get-Vendor -Vendor Amazon
Chosen vendor: Amazon
```

注意：将函数导出到模块时，请确保还将枚举也添加到模块中。必须先定义枚举类型，才能在调用使用这些枚举的函数。

<!--本文国际来源：[IntelliSense for Parameters (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/intellisense-for-parameters-part-2)-->

