---
layout: post
title: "PowerShell 技能连载 - ISE 的缺陷导致调试器阻塞"
date: 2014-05-16 00:00:00
description: PowerTip of the Day - ISE Bug Locks Debugger
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 Powershell ISE 中，有一个模糊的缺陷，可能会导致调试器死锁。受影响的 PowerShell 版本有 3.0 和 4.0。

以下是一段测试脚本：

	$test = @"
        Some lines
        of text
    "@

    $test

在 ISE 编辑器中将这段代码保存为脚本，然后在第一行中设置一个断点：单击第一行的任何地方，然后按下 `F9` 键。该行将会变成红色。

当您启动脚本时，调试器将会在断点处停下，然后您可以按 `F10` 键单步跟踪代码。这可以正常工作。

现在，在变量定义之前加入一些空格：

       $test = @"
        Some lines
        of text
    "@

    $test

当您现在调用调试器的时候，它将会死锁，并且 ISE 不会恢复。您还可以保存未保存的脚本，但您再也无法停止 ISE 的运行空间。

这个缺陷在对通过 here string 定义的脚本变量缩进的时候暴露出来。

<!--本文国际来源：[ISE Bug Locks Debugger](http://community.idera.com/powershell/powertips/b/tips/posts/ise-bug-locks-debugger)-->
