---
layout: post
date: 2019-06-06 00:00:00
title: "PowerShell 技能连载 - 检查按键"
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
有些时候如果一个脚本能检测按键，而不需要干预脚本和输入，那是很棒的事情。通过这种方式，您可以增加按住 `SHIFT` 键的逻辑，例如退出脚本或者启用详细日志。在用户数据脚本中，您可以在 PowerShell 启动时根据是否按下某些键加载模块以及进行其它调整。

这归结到一个问题：最好的以及最少干预的检测按键的方式是什么？以下是解决方案：

```powershell
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName PresentationCore

1..1000 | ForEach-Object {
  "I am at $_"
  $isDown = [Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::LeftShift)
  if ($isDown)
  {
    Write-Warning "ABORTED!!"
    break
  }

  Start-Sleep -Seconds 1
}
```

增加了两个缺省的程序集之后，您的脚本可以操作 `Windows.Input.Keyboard` 类。这个类有一个 `IsKeyDown()` 方法。它可以检测键盘的按键，并且当该按键当前处于按下状态时会返回 `$true`。

以上示例代码持续运行知道用户按下左侧的 `SHIFT` 键。

<!--本文国际来源：[Detecting Key Press](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/detecting-key-press)-->

