---
layout: post
date: 2024-09-09 00:00:00
title: "PowerShell 技能连载 - PowerShell 过滤器：使用 Where-Object 和 Select-Object"
description: "Powershell filter: Using where-object and select-object"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
# 概述：Where-object 和 Select-object

在学习如何使用 Where-Object 和 Select-Object 命令之前，理解前几节讨论的概念是至关重要的。首先，PowerShell 是一种面向对象的编程语言。几乎每个命令都会返回一个具有多个特征的对象，这些特征可以独立检查和过滤。

例如，Get-Process 命令将返回有关当前运行中的 Windows 进程的各种信息，如启动时间和当前内存使用情况。每个信息都保存为 Process 对象的属性。通过管道字符 | ，PowerShell 命令也可以链接在一起。当您这样做时，在管道左侧命令的结果将发送到右侧命令中。如果您将 Get-Process 管道到 Stop-Process（即 Get-Process | Stop-Process），则由 Get-Process 命令识别出来的进程将被停止。如果没有设置筛选条件，则此操作会尝试停止系统上所有正在运行中的进程。

# Where-object：语法、工作原理和示例

Where-object 命令可用于根据它们拥有任何属性来过滤对象。

```powershell
PS C:\Users\dhrub> get-command Where-Object -Syntax

Where-Object [-Property] <string> [[-Value] <Object>] [-InputObject <psobject>] [-EQ] [<CommonParameters>]

Where-Object [-FilterScript] <scriptblock> [-InputObject <psobject>] [<CommonParameters>]

Where-Object [-Property] <string> [[-Value] <Object>] -Match [-InputObject <psobject>] [<CommonParameters>]
```

最常用的语法是：

```powershell
Where-Object {$_.PropertyName -ComparisonType FilterValue}
```

“PropertyName”属性是您正在过滤其属性的对象的名称。ComparisonType是描述您执行比较类型的简短关键字。“eq”代表等于，“gt”代表大于，“lt”代表小于，“like”代表通配符搜索。最后，FilterValue是与对象属性进行比较的值。Get-Process命令示例如下所示，并附有输出。

```powershell
PS C:\Users\dhrub> get-process| Where-Object {$_.processname -eq "armsvc"}

Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
    124       8     1588       2800              4956   0 armsvc
```

# Select-object: 语法、工作原理和示例

Select-Object 命令是另一个需要熟悉的命令。该命令用于限制或修改其他命令的输出。它有许多应用程序，但其中最常见的一种是选择另一个命令的前 N 个结果。

```powershell
PS C:\Users\dhrub> Get-Command Select-Object -Syntax

Select-Object [[-Property] <Object[]>] [-InputObject <psobject>] [-ExcludeProperty <string[]>] [-ExpandProperty <string>] [-Unique] [-Last <int>] [-First <int>] [-Skip <int>] [-Wait]
 [<CommonParameters>]

Select-Object [[-Property] <Object[]>] [-InputObject <psobject>] [-ExcludeProperty <string[]>] [-ExpandProperty <string>] [-Unique] [-SkipLast <int>] [<CommonParameters>]

Select-Object [-InputObject <psobject>] [-Unique] [-Wait] [-Index <int[]>] [<CommonParameters>]
```

以下是我们可以过滤进程的一种方式。

```powershell
PS C:\Users\dhrub> get-process |select Name

Name
----
AdobeIPCBroker
amdfendrsr
AppHelperCap
ApplicationFrameHost
```

以下示例显示系统中正在运行的前五个进程。

```powershell
PS C:\Users\dhrub> get-process |Select-Object -First 5

Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
    206      13     2428      10492       0.09    836   6 AdobeIPCBroker
    110       8     2012       4612              3368   0 amdfendrsr
    334      15     5692       9724              2284   0 AppHelperCap
    394      22    15564      32088       0.30  13260   6 ApplicationFrameHost
    124       8     1588       2800              4956   0 armsvc
```

以下示例显示系统中正在运行的最后五个进程。

```powershell
PS C:\Users\dhrub> get-process |Select-Object -last 5

Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
   1064      75    55192       2556      10.11  14596   6 WinStore.App
    186      13     3380       8544              3856   0 WmiPrvSE
    189      12     3900      11268              7532   0 WmiPrvSE
    462      16     4900       8100              1288   0 WUDFHost
    767      51    30048      17588       1.89  14588   6 YourPhone
```

# 结论

在PowerShell中，您可以通过使用Where-Object和Select-Object命令轻松控制正在处理的项目。 您可以使用这些命令来过滤您查看的数据或将操作限制为与您设置的筛选器匹配的操作（例如停止服务或删除文件）。 这个系列将在下一篇文章中结束。 我们将研究如何循环遍历对象组以对一组项目执行更复杂的任务。

<!--本文国际来源：[15+ Best Active Directory Powershell Scripts](https://powershellguru.com/active-directory-powershell-scripts/)-->
