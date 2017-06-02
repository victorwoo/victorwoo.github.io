---
layout: post
date: 2015-03-10 11:00:00
title: "PowerShell 技能连载 - 随时获取 cmdlet 的帮助"
description: PowerTip of the Day - Getting Cmdlet Help No Matter What
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

从 PowerShell 3.0 开始，帮助文件不在随着 PowerShell 发布。相反，您需要通过 `Update-Help` 来下载它们，并且由于帮助文件是存储在（受保护的）PowerShell 文件夹中，所以一个普通用户无法实现该操作。

将来您需要某个 cmdlet 的帮助时，只需要直接使用在线版即可。以下代码将通过浏览器访问 `Get-Process` 的在线帮助（假设您有 Internet 连接）：

    PS> help Get-Process -Online

安装了帮助文件之后，在 PowerShell ISE 中获得帮助变得更容易了：只需要点击任何 cmdlet 名称，然后按 `F1` 键。


如果仔细观察，会发现当按下 `F1` 时，实际上是帮您输入了帮助命令。所以如果需要同样的操作方便性，但是显示的是在线的帮助，您以实现一个类似这样的函数：

    function Get-Help($Name) { Get-Help $Name -Online }  

然而，这可能会导致死循环，因为新创建的 `Get-Help` 会在内部调用自己。要让它正常工作，您需要您的函数内部是采用类似这样的方式调用原始的 `Get-Help` cmdlet：

    function Get-Help($Name) { Microsoft.PowerShell.Core\Get-Help $Name -Online } 

当您运行这个函数是，您可以点击 PowerShell ISE 中的任意 cmdlet 名称，然后按 `F1` 键，就能够访问该 cmdlet 的在线解释——忽略您本机安装的帮助文件。

<!--more-->
本文国际来源：[Getting Cmdlet Help No Matter What](http://community.idera.com/powershell/powertips/b/tips/posts/getting-cmdlet-help-no-matter-what)
