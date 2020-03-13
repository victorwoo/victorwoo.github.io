---
layout: post
date: 2020-03-11 00:00:00
title: "PowerShell 技能连载 - 动态参数完成（第 2 部分）"
description: PowerTip of the Day - Dynamic Argument Completion (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前面的技巧中，我们研究了 `[ArgumentCompleter]` 以及此属性如何将聪明的代码添加到为参数提供自动完成值的参数。自动完成功能甚至可以做更多的事情：您可以根据实际情况生成 IntelliSense 菜单。

请看这段代码：

```powershell
function Get-OU {
    param(
        [Parameter(Mandatory)]
        [ArgumentCompleter({

        [Management.Automation.CompletionResult]::new("'OU=managers,DC=company,DC=local'", "Management", "ProviderItem", "OU where the Management lives")
        [Management.Automation.CompletionResult]::new("'OU=subtest,OU=test,DC=company,DC=local'", "Experimental", "DynamicKeyword", "Reserved")
        [Management.Automation.CompletionResult]::new("'OU=External,OU=IT,DC=company,DC=local'", "Help Desk", "ProviderItem", "OU where the Helpdesk people reside")

        })]
        [string]
        $OU
    )

    "Chosen path: $OU"
}
```

完整代码基本上只创建三个新的CompletionResult对象。每个参数都有四个参数：

* 自动完成的文字
* 显示在 IntelliSense 菜单中的文字
* IntelliSense 菜单的图标
* IntelliSense 菜单的工具提示

您甚至可以控制 IntelliSense 菜单中显示的图标。这些是预定义的图标：

```powershell
PS> [Enum]::GetNames([System.Management.Automation.CompletionResultType])
Text
History
Command
ProviderItem
ProviderContainer
Property
Method
ParameterName
ParameterValue
Variable
Namespace
Type
Keyword
DynamicKeyword
```

当您运行此代码然后调用 `Get-OU` 时，可以按 TAB 键完成 OU X500 路径，也可以按 CTRL + SPACE 打开 IntelliSense 菜单。在菜单内，您会看到所选的图标和友好的文本。选择项目后，将使用 X500 自动完成的文字。

<!--本文国际来源：[Dynamic Argument Completion (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/dynamic-argument-completion-part-2)-->

