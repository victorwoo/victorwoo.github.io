---
layout: post
date: 2015-09-30 11:00:00
title: "PowerShell 技能连载 - 复制数组（第 1 部分）"
description: PowerTip of the Day - Copying Arrays (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您复制变量内容时，您也可以只拷贝“引用”（内存地址），而不是内容。请看这个例子：

    $a = 1..10
    $b = $a
    $b[0] = 'changed'
    $b[0]
    $a[0]

虽然您改变了 `$b`，但 `$a` 也跟着改变。两个变量都引用了相同的内存地址，所以两者具有相同的内容。

要创建一个数组的全新拷贝，您需要先对它进行克隆：

    $a = 1..10
    $b = $a.Clone()
    $b[0] = 'changed'
    $b[0]
    $a[0]

<!--本文国际来源：[Copying Arrays (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/copying-arrays-part-1)-->
