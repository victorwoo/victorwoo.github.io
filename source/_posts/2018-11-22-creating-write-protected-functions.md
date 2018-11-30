---
layout: post
date: 2018-11-22 00:00:00
title: "PowerShell 技能连载 - 创建写保护的函数"
description: PowerTip of the Day - Creating Write-Protected Functions
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
PowerShell 的函数缺省情况下可以在任何时候被覆盖，而且可以用 `Remove-Item` 来移除它：

```powershell
function Test-Lifespan
{
    "Hello!"
}

Test-Lifespan

Remove-Item -Path function:Test-Lifespan

Test-Lifespan
```

对于安全相关的函数，您可能希望以某种不会被删除的方式创建它们。以下是实现方法：

```powershell
$FuncName = 'Test-ConstantFunc'
$Expression = {
    param($Text)
    "Hello $Text, I cannot be removed!"
}

Set-Item -Path function:$FuncName -Value $Expression -Options Constant,AllScope
```

这个新函数是用 `Set-Item` 直接在 `function:` 驱动器内创建。通过这种方式，您可以对该函数增加新的选项，例如 `Constant` 和 `AllScope`。这个函数能够以期待的方式工作：

```powershell
PS C:\> Test-ConstantFunc -Text $env:username
Hello DemoUser, I cannot be removed!
```

"`Constant`" 确保该函数无法被覆盖或是被删除：

```powershell
PS C:\> function Test-ConstantFunc { "Got you!!" }
Cannot write to function Test-ConstantFunc because it is read-only or constant.
At line:1 char:1
+ function Test-ConstantFunc { "got you!!" }
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : WriteError: (Test-ConstantFunc:String) [], Sessio
    nStateUnauthorizedAccessException
    + FullyQualifiedErrorId : FunctionNotWritable


PS C:\> Remove-Item -Path function:Test-ConstantFunc
Remove-Item : Cannot remove function Test-ConstantFunc because it is constant.
At line:1 char:1
+ Remove-Item -Path function:Test-ConstantFunc
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : WriteError: (Test-ConstantFunc:String) [Remove-It
    em], SessionStateUnauthorizedAccessException
    + FullyQualifiedErrorId : FunctionNotRemovable,Microsoft.PowerShell.Command
    s.RemoveItemCommand
```

更重要的是，"`AllScope`" 确保该函数无法在子作用域中被掩盖。有了写保护之后，在一个常见的用独立的子作用于来定义一个同名的新函数的场景中：

```powershell
& {
    function Test-ConstantFunc { "I am the second function in a child scope!" }
    Test-ConstantFunc

}
```

结果是，因为 "`AllScope`" 的作用，将原来的保护函数覆盖的操作不再起作用：

    Cannot write to function Test-ConstantFunc because it is read-only or constant.
    At line:4 char:3
    +   function Test-ConstantFunc { "I am a second function in a child sco ...
    +   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : WriteError: (Test-ConstantFunc:String) [], Sessio
        nStateUnauthorizedAccessException
        + FullyQualifiedErrorId : FunctionNotWritable

    Hello , I cannot be removed!

<!--more-->
本文国际来源：[Creating Write-Protected Functions](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-write-protected-functions)
