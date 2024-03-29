---
layout: post
date: 2021-06-30 00:00:00
title: "PowerShell 技能连载 - 排序技巧（第 3 部分）"
description: PowerTip of the Day - Sorting Tricks (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们展示了 `Sort-Object` 接受属性名称、哈希表或普通脚本块来对事物进行排序。让我们看看为什么将脚本块提交给 Sort-Object 是个好主意。

假设您有一堆表示日期的字符串数据，并且您想对它们进行排序：

```powershell
PS> 'May 12, 2020', 'Feb 1, 1999', 'June 12, 2021' | Sort-Object

Feb 1, 1999
June 12, 2021
May 12, 2020
```

结果已排序，但不按日期排序。由于输入是字符串，`Sort-Object` 使用字母数字排序算法。您现在可以将原始数据转换为另一种格式并对其进行排序。

但是，您也可以要求 `Sort-Object` 进行转换。不同之处在于原始数据格式保持不变：一系列字符串将按日期排序，但仍然是字符串：

```powershell
PS> 'May 12, 2020', 'Feb 1, 1999', 'June 12, 2021' |
        Sort-Object -Property { [DateTime]$_ }

Feb 1, 1999
May 12, 2020
June 12, 2021
```

当然，您的工作是想出一个脚本块，将 $_ 中传入的原始数据正确转换为您想要用于排序的所需类型。对于日期，您可能还想查看使用本地日期和时间格式的 `-as` 运算符，而直接转换始终使用美国格式：

```powershell
PS> 'May 12, 2020', 'Feb 1, 1999', 'June 12, 2021' | Sort-Object -Property { $_ -as [DateTime] }

Feb 1, 1999
May 12, 2020
June 12, 2021
```

<!--本文国际来源：[Sorting Tricks (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/sorting-tricks-part-3)-->

