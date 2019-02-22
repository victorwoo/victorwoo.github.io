---
layout: post
date: 2019-02-05 00:00:00
title: "PowerShell 技能连载 - “危险的”比较"
description: "PowerTip of the Day - “Dangerous” Comparisons"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
假设您希望排除某个数组中所有为空字符串或者 null 元素。以下是许多人可能的做法：

```powershell
PS> 1,2,$null,"test","",9 | Where-Object { $_ -ne '' -and $_ -ne $null }

1
2
test
9

PS>
```

然而，这个对比是危险的，因为它也排除了数值 0:

```powershell
PS> 1,2,0,$null,"test","",0,9 | Where-Object { $_ -ne '' -and $_ -ne $null }

1
2
test
9

PS>
```

PowerShell 过滤掉了数值 0，因为它等同于一个空字符串：

```powershell
PS> 0 -eq ''
True

PS> 1 -eq ''
False
```

这是因为在比较时，以等号左侧的数据类型为准，而由于左侧是一个 integer 值，所以 PowerShell 将空字符串也转换成一个 integer，而转换的结果值是 0。

为了安全地进行比较，请记住一定将相关的数据类型放在等号左侧，而不是右侧：

```powershell
PS> 1,2,0,$null,"test","",0,9 | Where-Object { '' -ne $_ -and $null -ne $_ }

1
2
0
test
0
9

PS>
```

或者更好一点，使用 API 函数来确认空值：

```powershell
PS> 1,2,0,$null,"test","",0,9 | Where-Object { ![string]::IsNullOrWhiteSpace($_) }

1
2
0
test
0
9

PS>
```

<!--本文国际来源：[“Dangerous” Comparisons](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/dangerous-comparisons)-->
