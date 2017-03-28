layout: post
date: 2015-02-23 12:00:00
title: "PowerShell 技能连载 - 使用 PowerShell ISE 调试器"
description: PowerTip of the Day - Using the PowerShell ISE Debugger
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
_适用于 PowerShell 3.0 及以上版本_

有些时候，很难找出 PowerShell 脚本为什么不按期望工作的原因。要更好地了解脚本工作的过程，请使用 PowerShell ISE 内置的调试器。

在您开始调试一个脚本之前请先保存它。无标题的脚本实际上还不算脚本，所以 PowerShell ISE 还无法调试它。

以下是调试一个脚本的简单步骤：

1. 设置断点。断点是您希望调试器在代码中停下的位置，这样您可以检查当前变量的状态。要设置一个断点，请单击某一行，然后按下 `F9` 键。该行代码将会变成红色。如果该行未变红，说明您还没有保存该脚本，或是该行代码不包含可执行的代码。

2. 运行脚本：脚本将会正常运行，但当运行到一个断点时，PowerShell ISE 将会暂停。当前行会标记成黄色。您可以将光标悬停到代码中的变量上来查看它们的值，或是在交互式窗口中执行任意代码，例如导出变量的值，甚至改变变量的值。

3. 继续：要继续执行下一条指令，请按 `F10` 或 `F11`。`F10` 将执行当前作用域内的下一条指令。`F11` 将执行下一条指令，无论是哪个作用域。所以如果当前行将要执行一个函数，而您按下 `F10`，那么将执行整个函数。如果您按下 `F11`，那么您将执行到该函数的第一行。这有点像“一小步”的概念。

4. 按下 `F5` 继续执行整个脚本。它将运行到整个脚本结束，或是遇到下一个断点。

5. 按下 `SHIFT+F5` 退出执行过程并且停止调试器。

一旦您掌握了这些步骤，调试过程会变得十分容易。并且它可以给您带来许多领悟和帮助。如果不采用调试方法的话将很难调查脚本错误。

<!--more-->
本文国际来源：[Using the PowerShell ISE Debugger](http://community.idera.com/powershell/powertips/b/tips/posts/using-the-powershell-ise-debugger)
