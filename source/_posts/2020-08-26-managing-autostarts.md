---
layout: post
date: 2020-08-26 00:00:00
title: "PowerShell 技能连载 - 管理自启动项"
description: PowerTip of the Day - Managing Autostarts
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
要在 Windows 上管理自动启动程序，不必费心编写大量脚本。 PowerShell 可以直接打开任务管理器中包含的自动启动管理器，您只需执行以下操作即可：

```powershell
PS C:\> Taskmgr /7 /startup
```

这将打开一个窗口，并列出所有自动启动程序及其对启动时间的影响。要阻止这些程序中的任何一个自动启动，请单击列表中的一个程序，然后单击右下角的“禁用”按钮。

如果您愿意，可以将命令转换为函数，然后将其放入配置文件脚本中，以备不时之需：

```powershell
function Show-Autostart
{
    Taskmgr /7 /startup
}
```

<!--本文国际来源：[Managing Autostarts](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-autostarts)-->

