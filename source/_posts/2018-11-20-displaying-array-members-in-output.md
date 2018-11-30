---
layout: post
date: 2018-11-20 00:00:00
title: "PowerShell 技能连载 - 在输出中显示数组成员"
description: PowerTip of the Day - Displaying Array Members in Output
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
当您输出包含数组属性的对象时，只会显示 4 个数组元素，然后用省略号截断剩余的结果：

```powershell
PS C:\> Get-Process | Select-Object -Property Name, Threads -First 6

Name       Threads
----       -------
acrotray   {3160}
AERTSr64   {1952, 1968, 1972, 8188}
AGSService {1980, 1988, 1992, 2000...}
armsvc     {1920, 1940, 1944, 7896}
audiodg    {7436, 1460, 2192, 6784}
ccSvcHst   {2584, 2644, 2656, 2400...}
```

要显示更多（或是全部）数组元素，请使用内置的 `$FormatEnumerationLimit` 变量。它的缺省值是 4，但是您可以将它改为希望显示的元素个数，或将它设置为 -1 来显示所有的元素：

```powershell
PS C:\> $FormatEnumerationLimit = 1

PS C:\> Get-Process | Select-Object -Property Name, Threads -First 6

Name       Threads
----       -------
acrotray   {3160}
AERTSr64   {1952...}
AGSService {1980...}
armsvc     {1920...}
audiodg    {7436...}
ccSvcHst   {2584...}



PS C:\> $FormatEnumerationLimit = 2

PS C:\> Get-Process | Select-Object -Property Name, Threads -First 6

Name       Threads
----       -------
acrotray   {3160}
AERTSr64   {1952, 1968...}
AGSService {1980, 1988...}
armsvc     {1920, 1940...}
audiodg    {7436, 2192...}
ccSvcHst   {2584, 2644...}



PS C:\> $FormatEnumerationLimit = -1

PS C:\> Get-Process | Select-Object -Property Name, Threads -First 6

Name       Threads
----       -------
acrotray   {3160}
AERTSr64   {1952, 1968, 1972, 8188}
AGSService {1980, 1988, 1992, 2000, 2024, 7932}
armsvc     {1920, 1940, 1944, 7896}
audiodg    {7436, 2192, 6784, 4540, 8040}
ccSvcHst   {2584, 2644, 2656, 2400, 3080, 3120, 3124, 3128, 3132, 3136, 3140,...
```

当您把值设为 -1，当一行的剩余空间用完的时候截断。如果仍要显示所有值，请显式地使用 `Format-Table` 和 `-Wrap` 参数：

```powershell
PS C:\> Get-Process | Select-Object -Property Name, Threads -First 6 | Format-Table -Wrap

Name       Threads
----       -------
acrotray   {3160}
AERTSr64   {1952, 1968, 1972, 8188}
AGSService {1980, 1988, 1992, 2000, 2024, 7932}
armsvc     {1920, 1940, 1944, 7896}
audiodg    {7436, 2192, 6784, 4540, 8040}
ccSvcHst   {2584, 2644, 2656, 2400, 3080, 3120, 3124, 3128, 3132, 3136, 3140,
            3144, 3232, 3240, 3248, 3260, 3268, 3288, 3304, 3344, 3492, 3552,
            3556, 3568, 3572, 3576, 3580, 3596, 3600, 3604, 3612, 3616, 3708,
            3712, 3716, 3724, 3732, 3736, 3760, 3764, 3768, 3776, 3780, 3796,
            3800, 3804, 3816, 3820, 3824, 3828, 3832, 3844, 3888, 3892, 4232,
            5084, 5088, 3112, 7100, 7016, 480, 3020, 3044, 4744, 7148, 1828,
            6476, 6516, 6524, 7160, 6652, 7000, 964, 6028, 4644, 4828, 6664,
            7892, 5820, 8180, 4940, 5956, 7684, 7156}



PS C:\>
```

<!--more-->
本文国际来源：[Displaying Array Members in Output](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/displaying-array-members-in-output)
