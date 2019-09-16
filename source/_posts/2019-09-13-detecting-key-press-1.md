---
layout: post
date: 2019-09-13 00:00:00
title: "PowerShell 技能连载 - 检测键盘按键"
description: PowerTip of the Day - Detecting Key Press
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
通常，只有在真正的控制台窗口中才支持按键检测，因此这种方法不适用于 PowerShell ISE 和其他 PowerShell 宿主。

但是，PowerShell 可以从 Windows Presentation Foundation 中借用一种类型，这种类型可以检查任何键的状态。这样，实现在任何 PowerShell 脚本中都可以工作的“退出”键就变得很简单了，无论是在控制台、Visual Studio Code 还是 PowerShell ISE 中运行：

```powershell
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName PresentationCore

# choose the abort key
$key = [System.Windows.Input.Key]::LeftCtrl

Write-Warning "PRESS $key TO ABORT!"

do
{
  $isCtrl = [System.Windows.Input.Keyboard]::IsKeyDown($key)
  if ($isCtrl)
  {
    Write-Host
    Write-Host "You pressed $key, so I am exiting!" -ForegroundColor Green
    break
  }
  Write-Host "." -NoNewline
  Start-Sleep -Milliseconds 100
} while ($true)
```

只需要在变量 `$key` 中选择“退出”按键即可。本例使用的是左 `CTRL` 键。

<!--本文国际来源：[Detecting Key Press](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/detecting-key-press-1)-->

