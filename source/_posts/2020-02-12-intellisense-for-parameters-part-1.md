---
layout: post
date: 2020-02-12 00:00:00
title: "PowerShell 技能连载 - 参数的智能感知（第 1 部分）"
description: PowerTip of the Day - IntelliSense for Parameters (Part 1)
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

您可以使用自己的 PowerShell 函数执行相同的操作，并且有多种方法可以执行此操作。今天让我们来看一下使用枚举类型的方法。

将枚举类型分配给参数时，它将自动列出可用值。下面的代码使用了 `[System.ConsoleColor]` 类型，该类型列出了所有有效的控制台颜色：

```powershell
function Set-ErrorColor
{
    param(
        [Parameter(Mandatory)]
        [System.ConsoleColor]
        $Color
    )

    $Host.PrivateData.ErrorForegroundColor = [string]$Color
}
```

当您调用 `Set-ErrorColor` 时，PowerShell 会自动向您建议有效的控制台颜色。当您选择一个时，该函数将此颜色分配给错误前景色。如果您不喜欢粗糙的红色错误颜色，请将错误消息变成绿色以使其更友好：

```powershell
PS> Set-ErrorColor -Color Green

PS> 1/0
Attempted to divide by zero.
At line:1 char:1
+ 1/0
+ ~~~
    + CategoryInfo          : NotSpecified: (:) [], RuntimeException
    + FullyQualifiedErrorId : RuntimeException
```

旁注：由您来决定对所选类型的处理方式。有时，将其转换为其他类型可能更理想。例如，在上面的示例中，选择的颜色将转换为字符串。为什么呢？

因为只有 PowerShell 控制台窗口支持 ConsoleColor 颜色。而 PowerShell ISE 编辑器等支持更多颜色，并使用 `[System.Windows.Media.Color]` 类型。

由于可以将字符串转换为这两种类型，但是 `ConsoleColor` 不能直接转换为 `Windows.Media.Color`，因此您可以将其转换为更通用的类型字符串，实现同时在控制台和 PowerShell ISE 中使用用户输入：

```powershell
# string converts to ConsoleColor
PS> [ConsoleColor]'red'
Red

# string converts to System.Windows.Media.Color
PS> [System.Windows.Media.Color]'red'


ColorContext :
A            : 255
R            : 255
G            : 0
B            : 0
ScA          : 1
ScR          : 1
ScG          : 0
ScB          : 0

# ConsoleColor DOES NOT convert to System.Windows.Media.Color
PS> [System.Windows.Media.Color][ConsoleColor]'red'
Cannot convert value "Red" to type "System.Windows.Media.Color". Error: "Invalid cast from 'System.ConsoleColor' to
'System.Windows.Media.Color'."
At line:1 char:1
+ [System.Windows.Media.Color][ConsoleColor]'red'
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidArgument: (:) [], RuntimeException
    + FullyQualifiedErrorId : InvalidCastIConvertible
```

<!--本文国际来源：[IntelliSense for Parameters (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/intellisense-for-parameters-part-1)-->

