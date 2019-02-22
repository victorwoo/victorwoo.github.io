---
layout: post
date: 2017-08-01 00:00:00
title: "PowerShell 技能连载 - 自动记录命令输出"
description: PowerTip of the Day - Auto-Logging Command Output
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们介绍了自 PowerShell 3 以上版本支持的 `PreCommandLookupAction`。今天我们将介绍一个特别的实现。

当您运行一下代码时，PowerShell 将会接受所有以 "*" 开头的命令并将命令的输出记录到一个文本文件中。当命令执行完毕，将会打开该文本文件。

现在您可以运行 `*dir` 来代替 `dir`，来保存结果，或用 `*Get-Process` 代替 `Get-Process`。

```powershell
$ExecutionContext.SessionState.InvokeCommand.PreCommandLookupAction = {
    # is called whenever a command is ready to execute
    param($command, $eventArgs)

    # check commands that start with "*" and were not
    # executed internally by PowerShell
    if ($command.StartsWith('*') -and $eventArgs.CommandOrigin -eq 'Runspace')
    {
        # save command output here
        $debugPath = "$env:temp\debugOutput.txt"
        # clear text file if it exists
        $exists = Test-Path $debugPath
        if ($exists) { Remove-Item -Path $debugPath }
        # remove leading "*" from a command name
        $command = $command.Substring(1)
        # tell PowerShell what to do instead of
        # running the original command
        $eventArgs.CommandScriptBlock = {
            # run the original command without "*", and
            # submit original arguments if there have been any
            $( 
            if ($args.Count -eq 0)
            { & $command }
            else
            { & $command $args }
            ) | 
            # log output to file
            Tee-Object -FilePath $debugPath | 
            # open the file once all output has been processed 
            ForEach-Object -Process { $_ } -End {
               if (Test-Path $debugPath) { notepad $debugPath } 
            }
        }.GetNewClosure()
    }
}
```

<!--本文国际来源：[Auto-Logging Command Output](http://community.idera.com/powershell/powertips/b/tips/posts/auto-logging-command-output)-->
