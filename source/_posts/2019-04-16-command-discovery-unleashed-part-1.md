---
layout: post
date: 2019-04-16 00:00:00
title: "PowerShell 技能连载 - 命令发现机制揭秘（第 1 部分）"
description: PowerTip of the Day - Command Discovery Unleashed (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您在 PowerShell 键入一个命令，将触发一系列事件来指定命令所在的位置。这从 `PreCommandLookupAction` 开始，您可以用它来记录日志。请看如下代码：

```powershell
$ExecutionContext.InvokeCommand.PreCommandLookupAction = {
param
(
    [string]
    $Command,

    [Management.Automation.CommandLookupEventArgs]
    $Obj
)
$whitelist = @(
'prompt',
'out-default',
'psconsolehostreadline',
'Microsoft.PowerShell.Core\Set-StrictMode'
)

    if ($Command -notin $whitelist -and $Obj.CommandOrigin -eq 'Runspace')
    {
        $host.UI.WriteLine('Yellow','White',$Command)
    }
}
```

当您运行这段代码，所有键入的命令都将回显到控制台中——除了白名单中列出命令。这演示了 `PreCommandLookupAction` 的工作方式：每当您键入一条命令时，将自动触发它，而且您也可以将命令写入一个日志文件。

<!--本文国际来源：[Command Discovery Unleashed (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/command-discovery-unleashed-part-1)-->

