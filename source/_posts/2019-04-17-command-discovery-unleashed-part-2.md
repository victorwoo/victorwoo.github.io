---
layout: post
date: 2019-04-17 00:00:00
title: "PowerShell 技能连载 - 命令发现机制揭秘（第 2 部分）"
description: PowerTip of the Day - Command Discovery Unleashed (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您在 PowerShell 中键入一条命令，引擎将触发三个事件来发现您想执行的命令。这为您提供了许多机会来拦截并改变命令的发现机制。让我们教 PowerShell 当在命令中加入 `>>` 时将命令输出结果发送到 `Out-GridView`！

一下是代码：

```powershell
$ExecutionContext.InvokeCommand.PreCommandLookupAction = {
param
(
    [string]
    $Command,

    [Management.Automation.CommandLookupEventArgs]
    $Obj
)

    # when the command ends with ">>"...
    if ($Command.EndsWith('>>'))
    {
        # ...remove the ">>" from the command...
        $RealCommand = $Command.Substring(0, $Command.Length-2)
        # ...run the original command with its original arguments,
        # and pipe the results to a grid view window
        $obj.CommandScriptBlock = {
            & $RealCommand @args | Out-GridView
            # use a new "closure" to make the $RealCommand variable available
            # inside the script block when it is later called
        }.GetNewClosure()
    }
}
```

接下来，输入两条命令：

```powershell
PS C:\> Get-Process -Id $PID
PS C:\> Get-Process>> -Id $PID
```

第一条命令只是输出当前进程。第二条命令自动将执行结果输出到 `Out-GridView`。

如果您希望取消这种行为，请重新启动 PowerShell（或将一个空脚本块赋值给该事件）。如果您希望使该行为永久生效，请将以上代码加入到您的 `profile` 脚本中。

<!--本文国际来源：[Command Discovery Unleashed (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/command-discovery-unleashed-part-2)-->

