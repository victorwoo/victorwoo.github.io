layout: post
date: 2014-11-25 12:00:00
title: "PowerShell 技能连载 - Join-Path 遇上不存在的驱动器会失败"
description: PowerTip of the Day - Join-Path Fails with Nonexistent Drives
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
_适用于 PowerShell 所有版本_

您可能已经使用 `Join-Path` 通过父文件夹和文件来创建路径名。这个 cmdlet 在合并路径元素的时候能够正确地处理反斜杠的个数：

```
$part1 = 'C:\somefolder\'
$part2 = '\myfile.txt'
$result = Join-Path -Path $part1 -ChildPath $part2

$result
```

然而，如果路径元素存在，`Join-Path` 将会失败。所以您无法为一个没有加载的驱动器创建路径：

```
$part1 = 'L:\somefolder\'
$part2 = '\myfile.txt'
$result = Join-Path -Path $part1 -ChildPath $part2

$result

Join-Path : Cannot find drive. A drive with the name 'L' does not exist.
```

其实，`Join-Path` 所做的事也可以通过手工很好地完成。这段代码将合并两段路径元素并且能处理好反斜杠：

```
$part1 = 'L:\somefolder\'
$part2 = '\myfile.txt'
$result = $part1.TrimEnd('\') + '\' +  $part2.TrimStart('\')

$result
```

如果您在 Windows 功能中启用了 Hyper-V 的 PowerShell 模块（如前一个技能中描述的一样的），您现在就可以通过 PowerShell 管理虚拟磁盘。

<!--more-->
本文国际来源：[Join-Path Fails with Nonexistent Drives](http://community.idera.com/powershell/powertips/b/tips/posts/join-path-fails-with-non-existing-drives)
