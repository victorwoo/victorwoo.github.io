---
layout: post
title: "PowerShell 技能连载 - 为什么目录的大小为 1"
date: 2014-07-01 00:00:00
description: PowerTip of the Day - Why Directories Have a Size of 1
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
你也许偶然注意到，文件夹的 Length 为 1 字节。这是从 PowerShell 3.0 开始的。在 PowerShell 2.0 中，Length 并没有任何值。

    $folder = Get-Item c:\Windows
    $folder.Length

这个结果是由另一个特性导致的。一个对象如果不包含“Count”或“Length”属性，它也会隐式地含有这两个属性，并且预设值为 1。

    PS> $host.length
    1

    PS> $host.Count
    1

    PS> (Get-Date).Length
    1

    PS> (Get-Date).Count
    1

    PS> $ConfirmPreference.Length
    1

    PS> $ConfirmPreference.Count
    1

在过去，通常只有数组才有 Length 或 Count 属性。所以当一个 cmdlet 或 函数仅返回 1 个对象（或 0 个对象）时，结果不会被包装成数组。而导致获取结果的数量时发生错误。

通过这个新“特性”，如果一个命令只返回一个对象，那么添加的“Count”属性总是返回“1”，意味着返回了 1 个元素。

<!--本文国际来源：[Why Directories Have a Size of 1](http://community.idera.com/powershell/powertips/b/tips/posts/why-directories-have-a-size-of-1)-->
