---
layout: post
date: 2021-11-09 00:00:00
title: "PowerShell 技能连载 - 高级排序（第 4 部分）"
description: PowerTip of the Day - Advanced Sorting (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个部分中，我们说明了如何使用脚本块对排序进行更多的控制。例如，您可以使用 "`-as`" 运算符来转换数据以控制排序算法。

这样，您可以“修正”传入数据的数据类型。例如将某些或所有数字数据转为字符串类型，再传给 `Sort-Object`。看看第一个例子的结果，以及下方的修正结果：

```powershell
PS> 1,2,"13",4,11,3,"2" | Sort-Object
1
13
2
3
4
11
2

PS> 1,2,"13",4,11,3,"2" | Sort-Object -Property { $_ -as [double] }
1
2
2
3
4
11
13
```

同样，您可以完全随机化列表，快速地创建简单的随机密码：

```powershell
PS> -join ('abcdefghkmnrstuvwxyz23456789*+#'.ToCharArray() | Get-Random -count 5 | Sort-Object -Property { Get-Random } )
m2v6u

PS> -join ('abcdefghkmnrstuvwxyz23456789*+#'.ToCharArray() | Get-Random -count 5 | Sort-Object -Property { Get-Random } )
b+g7t
```

或者，您可以根据计算值进行排序。下面的示例按文件年龄排序，通过从创建时间中减去上次写入时间计算得出：

```powershell
Get-ChildItem -Path c:\windows -Filter *.log -Depth 1 -ErrorAction Ignore |
Sort-Object -Property { $_.LastWriteTime - $_.CreationTime } |
Select-Object -Property Name, LastWriteTime, CreationTime, @{Name='Age (Days)';Expression={ [int]($_.LastWriteTime - $_.CreationTime).TotalDays }}
```

结果看起来类似这样：

    Name                                 LastWriteTime       CreationTime        Age (Days)
    ----                                 -------------       ------------        ----------
    setupapi.upgrade.log                 28.09.2020 15:04:56 28.09.2020 15:40:12          0
    setuperr.log                         11.07.2021 14:37:51 11.07.2021 14:37:51          0
    setupact.log                         16.10.2021 12:59:17 16.10.2021 12:59:17          0
    setupapi.setup.log                   28.09.2020 17:48:22 28.09.2020 17:47:36          0
    setupapi.offline.20191207_091437.log 07.12.2019 10:14:37 07.12.2019 10:13:02          0
    setupapi.offline.log                 28.09.2020 15:40:12 28.09.2020 15:09:47          0
    setupapi.dev.20201120_180252.log     20.11.2020 18:02:52 28.09.2020 17:51:43         53
    setupapi.dev.20210514_095516.log     14.05.2021 09:55:16 27.02.2021 04:17:58         76
    setupapi.dev.20210226_041725.log     26.02.2021 04:17:25 22.11.2020 04:18:58         96
    lvcoinst.log                         23.10.2021 15:30:45 19.07.2021 08:46:48         96
    PFRO.log                             25.10.2021 13:54:27 11.07.2021 14:41:28        106
    WindowsUpdate.log                    26.10.2021 10:47:38 10.07.2021 15:05:05        108
    setupapi.dev.20210710_201855.log     10.07.2021 20:18:55 27.02.2021 04:17:58        134
    setupapi.dev.20210915_082529.log     15.09.2021 08:25:29 27.02.2021 04:17:58        200
    NetSetup.LOG                         17.04.2020 15:19:26 26.08.2019 17:23:11        235
    setupapi.dev.log                     26.10.2021 06:27:25 27.02.2021 04:17:58        241
    mrt.log                              13.10.2021 08:30:39 12.11.2020 07:16:17        335
    PASSWD.LOG                           25.10.2021 13:54:28 28.09.2020 17:47:22        392
    ReportingEvents.log                  26.10.2021 09:37:23 03.09.2019 10:42:58        784
    Gms.log                              25.10.2021 13:54:32 26.08.2019 17:27:50        791

请注意如何以非常相似的方式将哈希表与 `Select-Object` 一起使用。在示例中，通过将哈希表提交给 `Select-Object`，将“Age (Days)”属性添加到输出中。在内部，哈希表定义了新属性的名称并提供了一个脚本块来计算属性值。此脚本块的工作原理与此处讨论的脚本块基本相同：`$_` 表示整个对象，您可以使用任何 PowerShell 表达式来转换或计算该值。

<!--本文国际来源：[Advanced Sorting (Part 4)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/advanced-sorting-part-4)-->

