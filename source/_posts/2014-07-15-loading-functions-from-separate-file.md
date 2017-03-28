layout: post
date: 2014-07-15 04:00:00
title: "PowerShell 技能连载 - 从独立的文件中加载函数"
description: PowerTip of the Day - Loading Functions from Separate File
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

为了让事情简化一些，您可能希望将 PowerShell 函数存放在一个独立的文件中。要将这些函数加载到您的业务脚本中，您可以使用这个简单的方法：

请确保包含 PowerShell 函数的脚本文件和业务脚本存放在同一个文件夹下。然后，在您的业务脚本中使用这行简单的代码：

    . "$PSScriptRoot\library1.ps1"

这行代码将会从当前脚本存放的文件夹中加载一个称为“library1.ps1”的脚本。不要漏了前面的 . 和空格：“点加文件名”的方式执行一个文件，能够确保该文件中的所有变量和函数都在调用者的上下文中定义，并且当脚本执行完以后不会被清除掉。

请注意 `$PSScriptRoot` 总是指向脚本所在文件夹的路径（从 PowerShell 3.0 开始）。请确保已经保存了您的脚本，因为只有保存过的脚本才有父文件夹。

<!--more-->
本文国际来源：[Loading Functions from Separate File](http://community.idera.com/powershell/powertips/b/tips/posts/loading-functions-from-separate-file)
