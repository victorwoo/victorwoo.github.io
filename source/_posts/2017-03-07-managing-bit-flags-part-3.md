layout: post
date: 2017-03-06 16:00:00
title: "PowerShell 技能连载 - 管理比特标志位（第三部分）"
description: PowerTip of the Day - Managing Bit Flags (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
对十进制数设置比特标志位不是很难，但是不够直观。以下是一个快速的新方法，演示如何设置或取消一个数字中特定的比特：

```powershell
$decimal = 6254
[Convert]::ToString($decimal, 2)

# set bit 4
$bit = 4
$decimal = $decimal -bor [Math]::Pow(2, $bit)
[Convert]::ToString($decimal, 2)

# set bit 0
$bit = 0
$decimal = $decimal -bor [Math]::Pow(2, $bit)
[Convert]::ToString($decimal, 2)

# clear bit 1
$bit = 1
$decimal = $decimal -band -bnot [Math]::Pow(2, $bit)
[Convert]::ToString($decimal, 2)
```

The result illustrates what the code does. ToString() shows bits from right to left, so bit #0 is to the far right. In line 2 and 3 below, two individual bits were set without tampering with the others. In the last line, a bit was cleared.
结果演示了代码做了什么。`ToString()` 从右到左显示比特，所以第 0 比特是在最右边。在第二行和第三行，设置了两个独立的比特位，而并不影响其它位。在最后一行中，清除了一个比特位。

    1100001101110
    1100001111110
    1100001111111
    1100001111101

<!--more-->
本文国际来源：[Managing Bit Flags (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/managing-bit-flags-part-3)
