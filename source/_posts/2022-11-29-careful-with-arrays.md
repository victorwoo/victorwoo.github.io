---
layout: post
date: 2022-11-29 13:38:40
title: "PowerShell 技能连载 - 小心使用数组"
description: PowerTip of the Day - Careful with Arrays
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
使用 PowerShell，您永远不知道 cmdlet 是返回数组还是单个对象。这是因为一旦命令返回多个项目，PowerShell 就会自动包装成数组：

```powershell
# no array:
$test = Get-Service -Name Spooler
$test -is [Array]

# array:
$test = Get-Service -Name S*
$test -is [Array]
```

理解这一点很重要，因为这意味着运行时条件可以确定变量的类型。这可能会导致意外情况。以下是说明问题的一个示例：

下面的代码返回以 "C" 开头的所有服务的名称，然后取第一个服务名称。这是有可能的，因为不仅有一个以 "C" 开头的服务，因此 PowerShell 返回 `$ServiceNames` 中的数组，然后您可以在此数组中使用数字索引来选择特定的元素：

```powershell
$Name = 'c*'

# get service names
$servicenames = Get-Service -Name $Name | Select-Object -ExpandProperty Name

# get first service name
$servicenames[0]
```

但是，您不能假设 `$servicenames` 始终是一个数组。如果在运行时只有一项与您的请求匹配的服务，则结果不再是一个数组，而是直接是服务名称。

为什么（以及何时）这有关系？当您的代码采用数组特定功能的那一刻，它就十分重要。因为在某些情况下可能不存在该功能或行为不同。

为了说明这一点，下面的代码现在列出了以 "cry" 开头的所有服务。只有一项服务与请求匹配。因此，`$servicenames` 不再是一个数组。现在是一个字符串。当您在字符串上使用索引时，您会得到该字符串中的一个字母。

现在，相同的代码返回的是一个字符，而不是服务名称：

```powershell
$Name = 'cry*'

# get service names
$servicenames = Get-Service -Name $Name | Select-Object -ExpandProperty Name

# get first service name
$servicenames[0]
```

这些示例似乎有些人为构造，但是您可以在许多难以找到的脚本错误的内部中找到潜在的问题。这就是为什么重要的是要始终确保您在代码使用数组功能时获得的真正是一个数组。

确保您获得数组的一种简单方法是构造器 `@()`：括号中的任何内容都以数组的形式返回。这就是为什么下面代码有效的原因，无论命令是否返回一个或多个结果：

```powershell

$Name = 'cry*'

# get service names
$servicenames = @(Get-Service -Name $Name | Select-Object -ExpandProperty Name)

# get first service name
$servicenames[0]
```

```powershell
$Name = 'cry*'

# get service names
[array]$servicenames = Get-Service -Name $Name | Select-Object -ExpandProperty Name

# get first service name
$servicenames[0]
```

```powershell
$Name = 'cry*'

# get service names
[string[]]$servicenames = Get-Service -Name $Name | Select-Object -ExpandProperty Name

# get first service name
$servicenames[0]
```

但是，`[array]` 更容易使用，因为无论数据类型如何，它总是可以使用，并且 `[array]` 对于不熟悉类型的用户也更容易理解。

<!--本文国际来源：[Careful with Arrays](https://blog.idera.com/database-tools/careful-with-arrays)-->

