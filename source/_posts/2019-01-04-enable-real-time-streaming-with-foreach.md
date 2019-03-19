---
layout: post
date: 2019-01-04 00:00:00
title: "PowerShell 技能连载 - 用 ForEach 实现实时流"
description: PowerTip of the Day - Enable Real-Time Streaming with Foreach
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
传统的 `foreach` 循环是最快速的循环方式，但是它有一个严重的限制。`foreach` 循环不支持管道。用户只能等待整个 `foreach` 循环结束才能处理结果。

以下是一些演示这个情况的示例。在以下代码中，您需要等待一段很长的时间才能“看见”执行结果：

```powershell
$result = foreach ($item in $elements)
{
    "processing $item"
    # simulate some work and delay
    Start-Sleep -Milliseconds 50
}

$result | Out-GridView
```

您无法直接通过管道输出结果。以下代码会产生语法错误：

```powershell
$elements = 1..100

Foreach ($item in $elements)
{
    "processing $item"
    # simulate some work and delay
    Start-Sleep -Milliseconds 50
} | Out-GridView
```

可以使用 `$()` 语法来使用管道，但是仍然要等待循环结束并且将整个结果作为一个整体发送到管道：

```powershell
$elements = 1..100

$(foreach ($item in $elements)
{
    "processing $item"
    # simulate some work and delay
    Start-Sleep -Milliseconds 50
}) | Out-GridView
```

一下是一个鲜为人知的技巧，向 `foreach` 循环增加实时流功能：只需要使用一个脚本块！

```powershell
$elements = 1..100

& { foreach ($item in $elements)
{
    "processing $item"
    # simulate some work and delay
    Start-Sleep -Milliseconds 50
}} | Out-GridView
```

现在您可以“看到”它们处理的结果，并且享受实时流的效果。

让然，您可以一开始就不使用 `foreach`，而是使用 `ForEach-Object` 管道 cmdlet 来代替：

```powershell
$elements = 1..100

$elements | ForEach-Object {
    $item = $_

    "processing $item"
    # simulate some work and delay
    Start-Sleep -Milliseconds 50
} | Out-GridView
```

但是，`ForEach-Object` 比 `foreach` 关键字慢得多，并且有些场景无法使用 `ForEach-Object`。例如，在许多数据库代码中，代码需要一次次地检测结束标记，所以无法使用 `ForEach-Object`。

<!--本文国际来源：[Enable Real-Time Streaming with Foreach](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/enable-real-time-streaming-with-foreach)-->
