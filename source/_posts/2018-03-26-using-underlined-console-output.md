---
layout: post
date: 2018-03-26 00:00:00
title: "PowerShell 技能连载 - 为控制台输出加下划线"
description: PowerTip of the Day - Using Underlined Console Output
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
从 PowerShell 5.1 开始，PowerShell 控制台支持 VT 转义序列，它可以用于对控制台文本定位和格式化。请注意它只对控制台有效，而对 PowerShell ISE 无效。另外还请注意您需要 Windows 10 或者类似 ConEmu 等模拟器。

要实验这个功能，请在 PowerShell 控制台中运行以下代码：

```powershell
$esc = [char]27
"$esc[4mOutput is now underlined!"
```

PowerShell 现在对所有的输出加下划线。输入文本并没有加下划线（由于 `PSReadLine` 处理所有输入文本的格式）。

要关闭格式化功能，请运行这段代码：

```powershell
$esc = [char]27
"$esc[0mReset"
```

我们将会在未来的技能中介绍更多的控制台文字格式化技术。以下是 VT 转义序列的更深入介绍：[https://docs.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences](https://docs.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#span-idtextformattingspanspan-idtextformattingspanspan-idtextformattingspantext-formatting).

<!--本文国际来源：[Using Underlined Console Output](http://community.idera.com/powershell/powertips/b/tips/posts/using-underlined-console-output)-->
