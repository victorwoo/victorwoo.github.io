---
layout: post
date: 2022-09-27 12:19:20
title: "PowerShell 技能连载 - 请担心 -match 运算符"
description: PowerTip of the Day - Beware of -match
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`-match` 运算符经常在脚本中使用，但是似乎并不是每个人都了解它实际的工作方式。它可能是一个非常危险的过滤器操作符。

让我们先创建一些示例数据：

```powershell
$list = 'ServerName, Location, Status
Test1, Hannover, Up
Test2, New York, Up
Test11, Sydney, Up' | ConvertFrom-Csv

$list
```

结果是假设服务器的列表：

    ServerName Location Status
    ---------- -------- ------
    Test1      Hannover Up
    Test2      New York Up
    Test11     Sydney   Up

假设您希望 PowerShell 脚本从列表中选择服务器并操作它，例如关闭电源：

```powershell
# server to work with:
$filter = 'Test2'
# pick filter from list:
$list | Where-Object ServerName -match $filter
```

一切看起来工作正常：

    ServerName Location Status
    ---------- -------- ------
    Test2      New York Up

但是， `-match` 期望的是正则表达式，而不仅仅是纯文本。另外，如果在文本中的任意位置找到了匹配的表达式，则它将返回 `$true`。将 `$filter` 改为 "Test1" 以选择服务器 "Test1" 时，以下是执行结果：

    ServerName Location Status
    ---------- -------- ------
    Test1      Hannover Up
    Test11     Sydney   Up

您会意外选择了两个服务器，因为 "Test11" 也包含了文本 "Test1"。

更糟糕的是：如果出于某种愚蠢的原因，`$filter` 是空白的，则会选择所有内容——因为“空白”能匹配任何内容。请自己尝试，并将 `$filter` 的值设为 `''`。

选择比较运算符时要非常小心，并且使用 `-match` 时要格外小心。在上面的示例中，`-eq`运算符（等于）会更合适，如果您必须使用通配符，那么 `-like` 使用起来更明确，因为它需要明确的 "*" 通配符，如果您真的只想比较数值的一部分。

<!--本文国际来源：[Beware of -match](https://blog.idera.com/database-tools/beware-of--match)-->

