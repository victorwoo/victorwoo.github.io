---
layout: post
date: 2023-06-29 12:00:44
title: "PowerShell 技能连载 - 选择最适当的文件格式（第 1 部分）"
description: PowerTip of the Day - Choosing Best File Format (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell支持各种文本文件格式，那么保存和读取数据的最佳方法是什么呢？

这主要取决于数据的类型，下面是实际指南的第一部分：

* 一维数据：当数据只有一个维度，例如服务器名称列表时，最好将其保存为纯文本文件。首选的命令是使用“Content”名词的命令：`Get-Content` 用于读取，`Set-Content` 用于写入，`Add-Content` 用于追加。纯文本文件存储字符串数组。注意事项：在保存和读取时，需要使用相同的文本编码，因此最好使用 UTF-8 编码。注意事项＃2：如果您想将字符串数组文件内容读取到变量中，添加 `-ReadCount 0` 参数。这比默认方式快很多倍。
* 二维数据：列和行形式的数据最好保存为CSV格式。首选的命令是使用“Csv”名词的命令：`Export-Csv`，`Import-Csv`。CSV 文件存储对象数组。CSV 列名定义了对象属性。注意事项：由于 CSV 基于文本，请确保主动选择良好的文本编码，如 UTF-8。注意事项＃2：CSV 文件可以使用许多不同的分隔符，因此要么使用 -Delimiter 来始终定义分隔符，要么使用`-UseCulture`，如果您希望自动选择的分隔符与其他应用程序*在同一系统上*匹配，例如，当您计划稍后在 Microsoft Excel 中打开 CSV 文件时。
<!--本文国际来源：[Choosing Best File Format (Part 1)](https://blog.idera.com/database-tools/powershell/powertips/choosing-best-file-format-part-1/)-->

