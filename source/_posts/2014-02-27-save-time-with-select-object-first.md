layout: post
title: "PowerShell 技能连载 - 用 Select-Object -First 节省时间！"
date: 2014-02-27 00:00:00
description: PowerTip of the Day - Save Time With Select-Object -First!
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
`Select-Object` 命令有一个 `-First` 参数，接受一个数字值。它将只返回前 x 个元素。听起来挺简单的，而且它的确就这么简单。

以下代码从您的 Windows 文件夹中获取前 4 个 PowerShell 脚本：

![](/img/2014-02-27-save-time-with-select-object-first-001.png)

从 PowerShell 3.0 开始，`-First` 不仅选择指定数量的结果，而且它还通知管道的上游命令，告知它操作已完成，有效地中止管道操作。

所以如果您想得到某个命令一定数量的结果，那么您总是可以使用 `Select-Object -First x` ——在特定的场景里这可以显著地加速您的代码执行效率。

我们假设您需要在您的用户文件夹之下的某个地方找一个名为“test.txt”的文件，并且假设只有一个这个名字的文件。而您只是不知道它放在哪个位置，那么您可以使用 `Get-ChildItem` 和 `-Recurse` 来递归查找所有的文件夹：

    Get-ChildItem -Path $home -Filter test.txt -Recurse -ErrorAction SilentlyContinue
    
当您执行这段代码时，`Get-ChildItem` 最终将找到您的文件——并且继续搜索您的文件夹树，也许要持续几分钟才能找完。因为它不知道是否有其它的文件。

所以，您知道的，如果您事先确定结果的数量，那么试试以下的代码：

    Get-ChildItem -Path $home -Filter test.txt -Recurse -ErrorAction SilentlyContinue |
      Select-Object -First 1 
    
这一次，`Get-ChildItem` 将会在找到一个文件后立即停止。

<!--more-->
本文国际来源：[Save Time With Select-Object -First!](http://community.idera.com/powershell/powertips/b/tips/posts/save-time-with-select-object-first)
