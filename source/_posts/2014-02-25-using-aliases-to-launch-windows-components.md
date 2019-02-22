---
layout: post
title: "PowerShell 技能连载 - 使用别名来启动 Windows 组件"
date: 2014-02-25 00:00:00
description: PowerTip of the Day - Using Aliases to Launch Windows Components
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 不仅是一个自动化操作的语言，而且是另一个用户操作界面。如果您不喜欢图形界面，那么练习使用 PowerShell 通过简单的别名来启动您需要的工具。

例如，要打开设备管理器，您可以使用它的原始名称：

![](/img/2014-02-25-using-aliases-to-launch-windows-components-001.png)

如果您不想记忆这个名称，那么使用别名：

![](/img/2014-02-25-using-aliases-to-launch-windows-components-002.png)

如您所见，要打开设备管理器，您现在所要做的只是键入“DeviceManager”。您也可以只键入“Device”然后按下 `TAB` 键来使用自动完成功能。

当关闭 PowerShell 时，定义的别名将会消失。所以要保持您定义的别名有效，请将 `Set-Alias` 命令加入您的配置脚本。配置脚本的路径可以在 `$profile` 中找到。如果这个目录不存在，您可能需要事先创建这个文件（以及它所在的文件夹）。`Test-Path` 可以检测它是否已经存在。

![](/img/2014-02-25-using-aliases-to-launch-windows-components-003.png)

<!--本文国际来源：[Using Aliases to Launch Windows Components](http://community.idera.com/powershell/powertips/b/tips/posts/using-aliases-to-launch-windows-components)-->
