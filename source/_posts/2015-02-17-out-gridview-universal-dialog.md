---
layout: post
date: 2015-02-17 12:00:00
title: "PowerShell 技能连载 - Out-GridView：通用对话框"
description: 'PowerTip of the Day - Out-GridView: Universal Dialog'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 3.0 及以上版本_

默认情况下，`Out-GridView` 是一条单行道：您可以将数据用管道输出到该命令，将结果显示在一个网格视图窗口中，但是您无法将数据再往下传递。

当您添加了 `-PassThru` 开关参数时，情况就变了。这时 `Out-GridView` 的右下角显示了两个新按钮：“确定”和“取消”。它将自己变为一个通用的对话框。

试试这行代码：

    PS> Get-Service | Where-Object CanStop | Out-GridView -Title 'Stoppable Services' -PassThru

这将打开一个标题为 "Stoppable Services" 的网格视图窗口，并列出所有可停止的服务（您可能还需要管理员权限才可以停止它们）。

您现在可以选择一个或多个项目（按住 `CTRL` 键多选），然后点击网格视图窗口右下角的“确定”按钮。

如您所见，返回了选中的对象。

要将这行代码变为一个有用的工具，您可以将 `Out-GridView` 的结果输出到 cmdlet，来执行具体的操作。这行代码将试图停止所有选中的服务：

    PS> Get-Service | Where-Object CanStop | Out-GridView -Title 'Stoppable Services' -PassThru | Stop-Service -WhatIf

请注意，出于安全考虑，我们对 `Stop-Service` 命令增加了 `-WhatIf` 参数，所以该 cmdlet 只会模拟停止服务。当您移除了这个参数，该行代码就不是模拟执行，而是真实停止服务了。

只需要坐下喝杯咖啡，然后思考一下它的原理：`Out-GridView` 接受任何类型的数据，所以您可以用它创建任何工具。例如，使用 Active Directory cmdlet `Get-ADUser` 来查找当前禁用的用户，然后让 PowerShell 为您启用所有选中的用户。

或者显示一个有主窗口的进程（桌面应用），并且杀掉所有选中的进程。

如果想达到这个目的，您可能会期望 `Out-GridView` 禁止多选。要想只允许选择单条记录，请试试以下代码：

    PS> 1..10 | Out-GridView -Title 'Pick favorite number' -OutputMode Single

<!--本文国际来源：[Out-GridView: Universal Dialog ](http://community.idera.com/powershell/powertips/b/tips/posts/out-gridview-universal-dialog)-->
