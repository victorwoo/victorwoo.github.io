---
layout: post
title: "PowerShell 技能连载 - 键盘鼠标自动化"
date: 2014-05-06 00:00:00
description: PowerTip of the Day - Automation via Keystroke and Mouse Click
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
某些时候，唯一的自动化处理办法是向 UI 组件发送按键和鼠标点击消息。一个强大且免费的 PowerShell 扩展，叫做“WASP”，地址如下：

[http://wasp.codeplex.com/](http://wasp.codeplex.com/)

一旦您装好了这个模块（解压前别忘了解除 ZIP 文件锁定。方法是右键点击，属性，解锁），WASP 模块提供以下 cmdlet：

![](/img/2014-05-06-automation-via-keystroke-and-mouse-click-001.png)

以下是一个简单的操作 Windows 计算器的例子：

    Import-Module WASP

    # launch Calculator
    $process = Start-Process -FilePath calc -PassThru
    $id = $process.Id
    Start-Sleep -Seconds 2
    $window = Select-Window | Where-Object { $_.ProcessID -eq $id }

    # send keys
    $window | Send-Keys 123
    $window | Send-Keys '{+}'
    $window | Send-Keys 999
    $window | Send-Keys =

    # send CTRL+c
    $window | Send-Keys '^c'

    # Result is now available from clipboard

以下是附加说明：

* 启动一个进程之后，要等待 1-2 秒，待窗体创建号以后才可以用 WASP 找到该窗口。
* 参考 SendKeys API 发送按键。有些字符需要通过两边加花括号的方式转义。更多细节请参见这里：[http://msdn.microsoft.com/en-us/library/system.windows.forms.sendkeys.send(v=vs.110).aspx/](http://msdn.microsoft.com/en-us/library/system.windows.forms.sendkeys.send(v=vs.110).aspx/)
* 当需要发送按键序列，例如 `CTRL`+`C` 时，请使用小写字母。“`^c`”代表发送 `CTRL`+`c`，而“`^C`”代表发送 `CTRL`+`SHIFT`+`C`。
* 只有 WinForm 窗口支持操作子控件，例如特定的文本框和按钮（`Select-ChildWindow`, `Select-Control`）。WPF 窗口也可以接收按键，但是 WPF 中在窗体的 UI 组件之上无法获得支持输入的控件。

<!--本文国际来源：[Automation via Keystroke and Mouse Click](http://community.idera.com/powershell/powertips/b/tips/posts/automation-via-keystroke-and-mouse-click)-->
