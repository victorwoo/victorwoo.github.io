---
layout: post
date: 2017-07-31 00:00:00
title: "PowerShell 技能连载 - 替换命令"
description: PowerTip of the Day - Replacing Commands
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
PowerShell 有一系列“秘密”的（更好的说法是没有在文档中体现的）设置。一个是 `PreCommandLookupAction`，它有一个很强的功能：当 PowerShell 一旦准备好执行一个命令时，就会先执行这个操作。

您的事件处理器可以调整、改变，操作护原始的命令，以及提交给它的参数。

今天我们将用这个简单的特性来秘密地将一个命令替换成另一个：

```powershell
$ExecutionContext.SessionState.InvokeCommand.PreCommandLookupAction = {
    # is called whenever a command is ready to execute
    param($command, $eventArgs)

    # not executed internally by PowerShell
    if ($command -eq 'Get-Service' -and $eventArgs.CommandOrigin -eq 'Runspace')
    {
        # tell PowerShell what to do instead of
        # running the original command
        $eventArgs.CommandScriptBlock = {
            # run the original command without "*", and
            # submit original arguments if there have been any
            $command = 'dir'

            $( 
            if ($args.Count -eq 0)
            { & $command }
            else
            { & $command $args }
            ) 
        }.GetNewClosure()
    }
}
```

这个事件处理器寻找 `Get-Service` 命令，并将它替换成 `dir`。所以当您运行 `Get-Service` 时，会变成获得一个文件夹列表。当然，这是没有实际意义的，正常情况下应该使用 alias 别名。下一个技巧中，我们将演示一些更有用的例子。

<!--more-->
本文国际来源：[Replacing Commands](http://community.idera.com/powershell/powertips/b/tips/posts/replacing-commands)
