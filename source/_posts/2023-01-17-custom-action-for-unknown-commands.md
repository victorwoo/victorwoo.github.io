---
layout: post
date: 2023-01-17 15:03:09
title: "PowerShell 技能连载 - Custom Action for Unknown Commands"
description: PowerTip of the Day - Custom Action for Unknown Commands
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
每当输入一个无法被 PowerShell 搜索到的命令名时，它都可以通过您定义的自定义操作来扩展命令搜索。

以下是一个快速有趣的示例，演示这个概念：

```powershell
$ExecutionContext.InvokeCommand.CommandNotFoundAction =
    {
        # second argument is the command that was missing:
        $p = $args[1]
        # do not try and find it elsewhere
        $p.StopSearch = $true

        $command = $p.CommandName

        # output audio message (make sure your audio is turned up)
        $sapi = New-Object -ComObject Sapi.SpVoice
        $sapi.Speak("Command $command not found.")
    }
```

当运行完以上代码，然后再次运行一个肯定不存在的命令时，您将会听到一个语音提示（假设您的音量是开启的且扬声器已打开）。当 PowerShell 无法找到一个命令，它会查找所有赋值给 `CommandNotFoundAction` 的脚本块并执行它。

这个点子是用于改进命令发现。例如，您可能会花时间整理一个流行命令列表和发布这些命令的模块名称。然后，您的自定义脚本块会尝试并查找列表中缺失的命令，并让用户知道缺失的模块名——或者甚至自动下载并安装该模块。

不幸的是，自从 PowerShell 提供了该功能之后，社区中并没有人实现了该功能。现在您可能会有兴趣发明一些比上面发出语音更复杂的功能。

<!--本文国际来源：[Custom Action for Unknown Commands](https://blog.idera.com/database-tools/powershell/powertips/custom-action-for-unknown-commands/)-->

