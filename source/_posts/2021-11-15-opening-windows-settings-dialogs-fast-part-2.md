---
layout: post
date: 2021-11-15 00:00:00
title: "PowerShell 技能连载 - 打开 Windows 设置对话框（快速）（第 2 部分）"
description: PowerTip of the Day - Opening Windows Settings Dialogs (Fast) (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
上一个技能中，我们介绍了 `Start-Process` 支持的命令 "`ms-settings:`"，可用于打开各种 Windows 设置对话框。例如，要打开个人注册信息页面，请执行以下操作：

```powershell
PS> Start-Process ms-settings:yourinfo
```

每当您需要经常打开特定对话框时，例如检查更新，那么现在可以直接做到：

```powershell
PS> Start-Process ms-settings:windowsupdate-action
```

但是，您需要记住相当隐蔽的命令。您无法定义新的命令别名，因为这些代码不是命令，而是命令加参数。

但是，您可以为此做些什么，也就是创建简单的函数。当您需要方便地记忆命令**和**参数时，这一直是一种好方法：

```powershell
function update { Start-Process ms-settings:windowsupdate-action }
```

运行此代码后，您现在可以使用新的 "`update`" 命令快速检查 Windows 更新。如果要保留这些功能，请将它们导出为一个 module，或将功能代码放入其中一个配置文件（自动启动）脚本中。 可以在 $profile 中找到默认配置文件脚本的路径。如果尚不存在，您可能必须创建文件。如果还没有允许脚本执行，请先启用它。

<!--本文国际来源：[Opening Windows Settings Dialogs (Fast) (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/opening-windows-settings-dialogs-fast-part-2)-->

