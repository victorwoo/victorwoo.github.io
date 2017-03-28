layout: post
date: 2015-09-09 11:00:00
title: "PowerShell 技能连载 - 在 PowerShell ISE 中使用 PowerShell Tabs"
description: PowerTip of the Day - Using PowerShell Tabs in the PowerShell ISE
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
随着 PowerShell 3.0 及以上版本发行的 PowerShell ISE 实际上是一个多宿主。它可以容纳多个单独的 PowerShell 实例。

要添加一个新的 PowerShell 宿主，请按 `CTRL` + `T`。然后输入 `Enter-PSSession`，并按下 `CTRL` + `SHIFT` + `R` 就能创建一个连接到远程系统的新的 PowerShell 宿主。

每个新的 PowerShell 宿主界面在 PowerShell ISE 中体现为一个新的标签页，名字为“PowerShell1”、“PowerShell2”、“PowerShell3”等。

在 ISE 中多个独立的 PowerShell 宿主十分有用。例如，希望在一个干净的环境里测试 `test-drive` 代码。

如果您愿意的话，甚至可以对标签进行重命名，来更好地体现它所表示的内容：

    PS> $psise.CurrentPowerShellTab.DisplayName = 'Testing'

请注意只有在至少有 2 个以上 PowerShell 宿主时，才会显示 PowerShell 标签。您可能需要先按下 `CTRL` + `T` 才能够看到重命名的效果。

<!--more-->
本文国际来源：[Using PowerShell Tabs in the PowerShell ISE](http://community.idera.com/powershell/powertips/b/tips/posts/using-powershell-tabs-in-the-powershell-ise)
