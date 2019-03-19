---
layout: post
date: 2018-12-10 00:00:00
title: "PowerShell 技能连载 - 使用 $MyInvocation 的固定替代方式"
description: PowerTip of the Day - Using Solid Alternatives for $MyInvocation
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
类似 `$MyInvocation.MyCommand.Definition` 的代码对于确定当前脚本存储的位置十分有用，例如需要存取同一个文件夹下其它资源的时候。

然而，从 PowerShell 3 开始，有一个更简单的替代方式可以查找当前脚本的名称和/或当前脚本文件夹的路径。请自己运行以下代码测试：

```powershell
$MyInvocation.MyCommand.Definition
$PSCommandPath

Split-Path -Path $MyInvocation.MyCommand.Definition
$PSScriptRoot
```

如果您交互式运行这段代码（或在一个“无标题”脚本中），它们都不会返回任何内容。但是当您将脚本保存后执行，这两行代码将返回脚本的路径，并且后两行代码将返回脚本所在文件夹的路径。

`$PSCommandPath` 和 `$PSScriptRoot` 的好处在于它们总是包含相同的信息。相比之下，`$MyInvocation` 可能会改变，而且当从一个函数中读取这个变量时，它就会发生改变。

```powershell
function test
{
    $MyInvocation.MyCommand.Definition
    $PSCommandPath

    Split-Path -Path $MyInvocation.MyCommand.Definition
    $PSScriptRoot
}

test
```

现在，`$MyInvocation` 变得没有价值，因为它重视返回调用本脚本块的调用者信息。

<!--本文国际来源：[Using Solid Alternatives for $MyInvocation](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-solid-alternatives-for-myinvocation)-->
