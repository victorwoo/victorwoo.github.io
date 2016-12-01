layout: post
date: 2016-11-20 16:00:00
title: "PowerShell 技能连载 - 隐藏启动 PowerShell"
description: PowerTip of the Day - Launching PowerShell Hidden
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
有时候 PowerShell 脚本只是用来生成某些东西，比如说生成报告，而不需要用 Excel 或记事本打开它。这时候您不会希望执行 PowerShell 的时候显示 PowerShell 控制台窗口。

并没有很简单的方法能隐藏 PowerShell 的控制台窗口，因为即使用了 `-WindowsStyle Hidden` 参数，也会先显示控制台，然后隐藏它（一闪而过）。

一种方法是使用 Windows 快捷方式来启动脚本。右键单击桌面的空白区域，然后选择新建/快捷方式。就可以新建一个快捷方式。当提示输入地址的时候，键入这行代码：

```powershell
powershell -noprofile -executionpolicy bypass -file "c:\path\to\script.ps1"
```

点击“下一步”，然后添加脚本的名称，再点击“下一步”，就接近完成了。这个快捷方式显示蓝色的 PowerShell 图标。单击它的时候，脚本即可运行，只是还不是隐藏的。

您现在只需要右键单击新创建的快捷方式，选择“属性”，然后将“运行”的设置从“正常窗口”改为您想要的设置。您也可以设置一个快捷方式，这需要管理员权限。

一个缺点是，在 Windows 10 中，“运行”的设置不再包含隐藏程序的选项。您最多可以最小化执行。

<!--more-->
本文国际来源：[Launching PowerShell Hidden](http://community.idera.com/powershell/powertips/b/tips/posts/launching-powershell-hidden)
