---
layout: post
date: 2023-06-15 00:00:00
title: "PowerShell 技能连载 - 7个用于管理DHCP的最佳PowerShell脚本"
description: "Understanding Foreach and Foreach-object in Powershell"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
最近，Foreach 和 Foreach-object 成为讨论的焦点，我们对此有所了解。循环是任何代码或脚本的核心，我们必须确保正确执行。但你是否想过哪种更适合在多台服务器上运行特定代码呢？让我们在这篇文章中探讨一下，并获取一些有用的知识。

## 对比：Foreach-object 和 Foreach

当选择 invoke-command 和 where { } 时，Foreach 是其中一个备受关注的选项。

拥有 **foreach** 的优势在于可以将值存储在 Excel 中的一个字符串中，这是一个福音。同样，在选择 **foreach ()** 时，我们有两个不同的选项，一个是 foreach 本身，另一个是 **foreach-object**。但当你看到对象时它们看起来很相似对吧。

我进行了测试以便能够挑选出胜者。

**ForEach-Object** 在通过管道发送数据时效果最佳，因为它会继续将对象流式传输到管道中的下一条命令中去。

## Foreach-object 和 Foreach 之间的速度测试

以下是测试代码：这将测试循环完成所需的实际时间。

```powershell
$a=Get-ChildItem –File C:\users\dhrub\ -Recurse
$time = (Measure-Command {

   $a | ForEach-Object {

        $_

    }

}).TotalMilliseconds

 [pscustomobject]@{

    Type = 'ForEach-Object'

    Time_ms = $Time

 }
 $Time = (Measure-Command {

    ForEach ($i in ($a)) {

        $i

    }

}).TotalMilliseconds

  [pscustomobject]@{

    Type = 'ForEach'

    Time_ms = $Time

 }

 Output:

 Type            Time_ms
----            -------
ForEach-Object 213.3006
ForEach         64.8013
```

**输出**一定会让你大吃一惊！

## 判决：该使用哪个？

**ForEach** 语句在处理每个项目之前将所有项目提前加载到集合中。

**ForEach-Object** 预期通过管道流式传输项目，从而降低内存需求，但同时会影响性能。

**Forach** 总是比 **Foreach-Object** 更快，但这并不意味着你不能使用 **Foreach-Object。具体取决于工作的要求。
