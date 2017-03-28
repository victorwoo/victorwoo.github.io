layout: post
date: 2015-02-12 12:00:00
title: "PowerShell 技能连载 - 获得一个干净的 PowerShell 环境"
description: 'PowerTip of the Day - Getting a Clean PowerShell Environment '
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

当您在 PowerShell ISE 中开发 PowerShell 脚本时，您可能做了很多更改和修订，并且测试运行了脚本。

这将“污染”您的环境：所有在脚本作用域内定义的变量仍然是定义过的状态，所以后续的测试不再是在一个干净的缺省环境中执行。

要确保一个脚本是在一个完全干净的测试环境中执行，您当然可以重启 PowerShell ISE。一个更便捷的方法是打开一个新的 PowerShell 选项卡：在 PowerShell ISE 中，选择文件/新建 PowerShell 选项卡。

这个操作将在脚本面板中新建一个选项卡。该选项卡代表一个全新的 PowerShell 宿主。您可以在这个新选项卡中加载您的测试脚本，并且在那儿进行测试。当测试完毕后，只需要点击关闭选项卡，即可从内存中消除掉它的所有相关内容。

请注意您可以在多个标签页中连续打开同一个脚本。当您这么操作时，ISE 会警告您该脚本已在另一个选项卡中打开了。当您编辑该脚本时，所有的编辑操作都会作用到所有打开该脚本的选项卡实例。

<!--more-->
本文国际来源：[Getting a Clean PowerShell Environment ](http://community.idera.com/powershell/powertips/b/tips/posts/getting-a-clean-powershell-environment)
