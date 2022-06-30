---
layout: post
date: 2022-06-17 00:00:00
title: "PowerShell 技能连载 - 请注意数组"
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
使用 PowerShell，您永远不知道 cmdlet 是返回数组还是单个对象。这是因为当命令返回多个项目时，PowerShell 会自动将结果包装成一个数组：

```powershell
# no array:
$test = Get-Service -Name Spooler
$test -is [Array]

# array:
$test = Get-Service -Name S*
$test -is [Array]
```

理解这一点非常重要，因为这意味着运行时条件可以确定变量的性质。这可能会导致坏的结果。这是演示该问题的一个示例：

下面的代码返回以 "C" 开头的所有服务名称，然后获取第一个服务名称。这是可能的，因为不仅有一个以 "C" 开头的服务，因此 PowerShell 返回一个数组，保存在 `$servicenames` 中，然后您可以在此数组中使用数字索引来选择特定的元素：

```powershell
$Name = 'c*'

# get service names
$servicenames = Get-Service -Name $Name | Select-Object -ExpandProperty Name

# get first service name
$servicenames[0]
```

但是，您不能假设 `$servicenames` 始终是一个数组。如果在运行时只有一项与您的请求匹配的服务，则结果不再是一个数组，而是直接是服务名称。

为什么（以及何时）这么重要？当您的代码采用特定数组功能的那一刻，它变得重要，因为在某些情况下可能不存在该功能或行为不同。

为了说明这一点，下面的代码列出了现在以 "cry" 开头的所有服务。只有一项服务与请求匹配。因此，`$servicenames` 不再是一个数组。现在是一个字符串。当您在字符串上使用索引时，您会从该字符串中获取特定字母。

现在，相同的代码返回一个字符，而不是服务名称：

```powershell
$Name = 'cry*'

# get service names
$servicenames = Get-Service -Name $Name | Select-Object -ExpandProperty Name

# get first service name
$servicenames[0]
```

这些示例似乎有点人为构造的情况。但是您可以在许多难以发现的脚本错误中找到这个问题。因此，重要的是要始终确保您在代码使用数组功能时真正获得数组。

确保您获得数组的一种简单方法是这个结构 `@()`：括号中的任何内容都以数组的形式返回。这就是为什么无论命令是否返回一个或多个结果，下面代码都有效的原因：

```powershell
$Name = 'cry*'

# get service names
$servicenames = @(Get-Service -Name $Name | Select-Object -ExpandProperty Name)

# get first service name
$servicenames[0]
```

要将数字签名添加到 PowerShell 脚本文件（或其他能够为此问题携带数字签名的文件），请使用 `Set-AuthenticodeSignature`。运行以下演示代码（根据需要调整文件和证书的路径）：

```powershell
$Name = 'cry*'

# get service names
[array]$servicenames = Get-Service -Name $Name | Select-Object -ExpandProperty Name

# get first service name
$servicenames[0]
```

运行此代码时，在 `$Path` 中指定的脚本文件将打开并显示添加到脚本底部的数字签名：

Hello World!

```powershell
$Name = 'cry*'

# get service names
[string[]]$servicenames = Get-Service -Name $Name | Select-Object -ExpandProperty Name

# get first service name
$servicenames[0]
```

但是，`[array]` 更容易使用，因为无论数据类型如何，它总是可以使用，并且 `[array]` 对不熟悉类型的用户也更友好。

<!--本文国际来源：[Careful with Arrays](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/careful-with-arrays)-->

