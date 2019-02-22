---
layout: post
date: 2017-09-05 00:00:00
title: "PowerShell 技能连载 - 如何正确地封装多个结果"
description: PowerTip of the Day - How to Correctly Wrap Multiple Results
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当一个 PowerShell 函数需要返回多用于一种信息时，一定要将它们打包成一个对象。只有通过这种方法，调用者才能够发现和独立存取该信息。以下是一个快速的例子。

这个函数只是输出三段数据。它以一个包含不同对象的数组形式返回：

```powershell
function test
{
    33.9
    "Hallo"
    Get-Date
}

$result = test

$result.Count
$result
```

以下是一个更好的函数，能返回相同的信息，但是这些信息被封装为一个结构化的对象。通过这种方法，用户可以容易地读取函数返回的信息：

```powershell
function test
{
    [PSCustomObject]@{
        Number = 33.9
        Text = "Hallo"
        Date = Get-Date
    }

}


$result = test
$result.Count

$result

$result.Number
```

<!--本文国际来源：[How to Correctly Wrap Multiple Results](http://community.idera.com/powershell/powertips/b/tips/posts/how-to-correctly-wrap-multiple-results)-->
