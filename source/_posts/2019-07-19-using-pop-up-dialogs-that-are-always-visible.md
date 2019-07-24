---
layout: post
date: 2019-07-19 00:00:00
title: "PowerShell 技能连载 - 使用始终可见的弹出对话框"
description: PowerTip of the Day - Using Pop-up Dialogs that Are Always Visible
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们使用了一种古老的 COM 技术来显示带有内置超时的弹出框。除了对话框有时会被覆盖在 PowerShell 窗口下之外，这种方法运行得非常好。

通过一个鲜为人知的技巧，你可以确保对话框总是打开在所有其他窗口的顶部:

```powershell
$shell = New-Object -ComObject WScript.Shell
$value = $shell.Popup("You can't cover me!", 5, 'Example', 17 + 4096)

"Choice: $value"
```

关键是在参数中添加 4096 来控制按钮和图标。这将该对话框转换为模态对话框：它保证在所有现有窗口之上打开，并且永远不会被覆盖。

使用哈希表来包装所有这些幻数，这又是一个好办法:

```powershell
$timeoutSeconds = 5
$title = 'Example'
$message = "You can't cover me!"

$buttons = @{
  OK               = 0
  OkCancel         = 1
  AbortRetryIgnore = 2
  YesNoCancel      = 3
  YesNo            = 4
  RetryCancel      = 5
}

$icon = @{
  Stop        = 16
  Question    = 32
  Exclamation = 48
  Information = 64
}

$clickedButton = @{
  -1 = 'Timeout'
  1  = 'OK'
  2  = 'Cancel'
  3  = 'Abort'
  4  = 'Retry'
  5  = 'Ignore'
  6  = 'Yes'
  7  = 'No'
}

$ShowOnTop = 4096

$shell = New-Object -ComObject WScript.Shell
$value = $shell.Popup($message, $timeoutSeconds, $title, $buttons.Ok + $icon.Exclamation + $ShowOnTop)

Switch ($clickedButton.$value)
{
  'OK'    { 'you clicked OK' }
  'Timeout'{ 'you did not click anything, timeout occurred' }
}
```

<!--本文国际来源：[Using Pop-up Dialogs that Are Always Visible](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-pop-up-dialogs-that-are-always-visible)-->

