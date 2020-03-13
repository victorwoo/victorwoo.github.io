---
layout: post
date: 2020-03-09 00:00:00
title: "PowerShell 技能连载 - 动态参数完成（第 1 部分）"
description: PowerTip of the Day - Dynamic Argument Completion (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前面的技巧中，我们介绍了将参数完成符添加到参数的各种方法。一种方法是使用 `[ArgumentCompleter]` 属性，如下所示：如您所见，这仅是完善补全代码的问题：当文件名包含空格时，表达式放在引号内，否则不用。如果希望完成者仅返回文件并忽略文件夹，则将 `-File` 参数添加到 `Get-ChildItem`。

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
```

本质上，运行此代码然后调用 `Get-File` 时，一旦使用 `-FileName` 参数，就可以按 TAB 或 CTRL + SPACE 自动列出 Windows 文件夹中所有文件的文件名。 PowerShell执行 `[ArgumentCompleter]` 中定义的脚本块以动态计算出自动完成的列表。

有一个反馈称，完成后，这些值需要检查特殊字符（例如空格），并在必要时用引号将它包裹起来。让我们听取这些反馈意见，看看如何改进自动完成代码：

```powershell
function Get-File {
    param(
        [Parameter(Mandatory)]
        [ArgumentCompleter({
        Get-ChildItem -Path $env:windir -Name |
            ForEach-Object {
            if ($_ -like '* *')
            {
                "'$_'"
            }
            else
            {
                $_
            }
            }

        })]
        [string]
        $FileName
    )

    "Chosen file name: $FileName"
}
```

如您所见，这完全是完善补全代码的问题：当文件名包含空格时，表达式需要放在引号内，否则就不需要。如果希望完成者仅返回文件并忽略文件夹，则将 `-File` 参数添加到 `Get-ChildItem`。

<!--本文国际来源：[Dynamic Argument Completion (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/dynamic-argument-completion-part-1)-->

