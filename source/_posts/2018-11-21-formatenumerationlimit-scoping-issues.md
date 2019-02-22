---
layout: post
date: 2018-11-21 00:00:00
title: "PowerShell 技能连载 - $FormatEnumerationLimit 作用域问题"
description: PowerTip of the Day - $FormatEnumerationLimit Scoping Issues
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如前一个技能所述，`$FormatEnumerationLimit` 隐藏变量决定了输出时会在多少个元素后截断。以下是再次演示该区别的例子：

```powershell
$default = $FormatEnumerationLimit

Get-Process | Select-Object -Property Name, Threads -First 5 | Out-Default
$FormatEnumerationLimit = 1
Get-Process | Select-Object -Property Name, Threads -First 5 | Out-Default
$FormatEnumerationLimit = -1
Get-Process | Select-Object -Property Name, Threads -First 5 | Out-Default

$FormatEnumerationLimit = $default
```

输出结果类似这样：

```powershell
Name       Threads
----       -------
acrotray   {3160}
AERTSr64   {1952, 1968, 1972, 8188}
AGSService {1980, 1988, 1992, 2000...}
armsvc     {1920, 1940, 1944, 7896}
ccSvcHst   {2584, 2644, 2656, 2400...}



Name       Threads
----       -------
acrotray   {3160}
AERTSr64   {1952...}
AGSService {1980...}
armsvc     {1920...}
ccSvcHst   {2584...}



Name       Threads
----       -------
acrotray   {3160}
AERTSr64   {1952, 1968, 1972, 8188}
AGSService {1980, 1988, 1992, 2000, 2024, 7932}
armsvc     {1920, 1940, 1944, 7896}
ccSvcHst   {2584, 2644, 2656, 2400, 3080, 3120, 3124, 3128, 3132, 3136, 3140,...
```

然而这在函数（或是脚本块等情况）中使用时可能会失败：

```powershell
function Test-Formatting
{
    $FormatEnumerationLimit = 1
    Get-Process | Select-Object -Property Name, Threads -First 5
}

Test-Formatting
```

虽然 `$FormatEnumerationLimit` 设置为 1，但数组仍然按缺省的显示 4 个元素。这是因为 `$FormatEnumerationLimit` 只对全局作用域有效。您需要在全局作用域中改变该变量才有效。所以需要用这种方法来写一个函数：

```powershell
function Test-Formatting
{
    # remember the current setting
    $default = $global:FormatEnumerationLimit

    # change on global scope
    $global:FormatEnumerationLimit = 1
    Get-Process | Select-Object -Property Name, Threads -First 5

    # at the end, clean up and revert to old value
    $global:FormatEnumerationLimit = $default
}

Test-Formatting
```

<!--本文国际来源：[$FormatEnumerationLimit Scoping Issues](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/formatenumerationlimit-scoping-issues)-->
