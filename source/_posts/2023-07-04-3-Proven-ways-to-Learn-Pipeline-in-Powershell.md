---
layout: post
date: 2023-07-04 00:00:00
title: "PowerShell 技能连载 - 学习在Powershell中使用管道的3种有效方法"
description: "3 Proven ways to Learn Pipeline in Powershell"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在Powershell中，管道是一个简单但有效的概念之一。在本教程中，我们将学习如何正确使用管道，并使我们的脚本在Powershell中整洁。

## 什么是管道？

Windows Powershell通过管道运行命令。我们看到的每个命令行都是一个管道。一个管道可以包含一个或多个命令，多个命令用竖线字符“|”分隔。

命令从左到右执行，每个命令的输出被传送或传递给其后面的命令。管道中最后一个命令的输出就是显示在屏幕上的内容。

```powershell
Get-Service #it is a single commad pipeline

#Multicommand pipelines looks similar
Get-Service| out-file servicelist.txt
```

**Get-Service |out-file** **servicelist.txt** 没有显示任何输出，你知道为什么吗？

嗯，它会直接将输出存储到管道后面提到的文本文件中。如果你理解了这一点，那么你就走在正确的道路上。

## 选择、排序和测量对象

您必须已经理解了流水线的概念。现在让我们看看如何使用 **select-object**, **sort-object,** 和 **measure-object** 结合流水线。让我们通过一些示例来看看如何使用上述管道。

**根据属性对对象进行排序**

Sort-Object 可以重新对管道中的对象进行排序。

```powershell
Get-Service | Sort-Object Name Descending
```

类似地，您可以尝试在上面尝试 Ascending 并查看输出结果。

**根据属性测量对象**

Measure-Object 可以测量管道中的对象。我们需要添加 **\-Property** 来指定单个数值属性。 在 **\-Property** 后面，我们可以添加以下内容：

-  计算平均值用 **\-Average**
- 显示最大值用 **\-Maximum**
- 显示最小值用 **\-Minimum**
- 显示总和用   \-\Sum

输出将是一个可度量或测量的对象而不是我们传入的任何东西。 让我们来检查一下您可以在自己电脑上尝试的几个示例。

```powershell
Get-Service | Measure-Object

Get-process | Measure-Object

2,0,5,6 | Measure-Object -Sum

2,0,5,6 | Measure-Object -maximum
```

**选择对象的子集**

`Select-object` 完全没有智能，正如其名称所示，它用于选择。让我们看看它实际上在哪些地方使用以及如何在脚本中使用。

以下是可与 Select-Object 一起使用的一些参数。

- **-First** 用于开始。
- **-Last** 用于结束。
- **-Skip** 在选择之前跳过若干行。

我们无法指定任何选择特定行的标准。让我们看看可以尝试在计算机上运行的一些示例。

```powershell
Get-Service | select-object -first 10

Get-process | select-object -first 10
```

这是使用 **Select-Object** 或 **Select** 的一种方式，让我们看看另一种可以使用 **Select-object** 的方法。

```powershell
get-service |select-object -property Name -first 10
```

在上面的示例中，我们正在选择一个特定属性即已选取了 Name 并且还选取了前十个结果。同样地，我们可以尝试其他示例。

## 结论

在本教程中，我们了解了 Powershell 中管道是什么、为什么要使用它以及如何使用它。 我们还学习了如何选择、排序和测量对象以及可以将其与示例结合应用的位置。 您可以尝试每个示例并确保您的计算机安装有 Powershell 。 让我们很快见到您，并希望您从今天学到了点东西。
<!--本文国际来源：[Choosing Best File Format (Part 1)](https://powershellguru.com/pipeline-in-powershell/)-->
