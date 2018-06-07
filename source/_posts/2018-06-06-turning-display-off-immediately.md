---
layout: post
date: 2018-06-06 00:00:00
title: "PowerShell 技能连载 - 立刻关闭显示器"
description: PowerTip of the Day - Turning Display Off Immediately
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
如果您想运行一个长时间执行的脚本，何不先关闭显示器，而是傻傻地等着超时以后显示屏保呢？

以下是一个简单的函数，能够立即关闭显示器。只需要移动鼠标或按任意键就可以唤醒：

```powershell
function Set-DisplayOff
{
    $code = @"
using System;
using System.Runtime.InteropServices;
public class API
{
    [DllImport("user32.dll")]
    public static extern
    int SendMessage(IntPtr hWnd, UInt32 Msg, IntPtr wParam, IntPtr lParam);
}
"@
    $t = Add-Type -TypeDefinition $code -PassThru
    $t::SendMessage(0xffff, 0x0112, 0xf170, 2)
}
```

<!--more-->
本文国际来源：[Turning Display Off Immediately](http://community.idera.com/powershell/powertips/b/tips/posts/turning-display-off-immediately)
