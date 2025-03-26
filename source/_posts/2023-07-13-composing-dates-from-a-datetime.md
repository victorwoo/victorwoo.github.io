---
layout: post
date: 2023-07-13 08:00:04
title: "PowerShell 技能连载 - 从 DateTime 中生成日期"
description: PowerTip of the Day - Composing Dates from a DateTime
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这里有一种简单通用的方法，可以将 `DateTime`` 信息转换为你所需的 ISO 字符串数据组件。例如，如果你只需要日期和月份，而不关心年份，可以按照以下方式操作：

```powershell
PS> (Get-Date).ToString('"0000-"MM-dd')
0000-06-02
```

`(Get-Date)` 表示当前日期，但可以替换为任何 `DateTime`` 对象：

```powershell
PS> $anyDate = Get-Date -Date '2024-12-24 19:22:11'

PS> $anyDate.ToString('"0000-"MM-dd')
0000-12-24
```

假设你需要过去 48 小时内的所有错误和警告，但是从上午 8 点 45 分开始计算。以下是计算方法：

```powershell
PS> (Get-Date).AddHours(-48).ToString('yyyy-MM-dd "08:45:00"')
2023-05-31 08:45:00
```

基本上，您可以使用 `ToString()` 方法，并使用区分大小写的 .NET DateTime 占位符（例如，'yyyy' 表示以 4位数字显示的年份）来组合所需的日期和时间字符串表示形式，再加上您自己控制的固定文本。请确保将固定文本放在额外引号中。

<!--本文国际来源：[Composing Dates from a DateTime](https://blog.idera.com/database-tools/powershell/powertips/composing-dates-from-a-datetime/)-->

