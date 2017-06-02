---
layout: post
date: 2014-12-29 12:00:00
title: "PowerShell 技能连载 - 处理 %ERRORLEVEL%"
description: PowerTip of the Day - Dealing with %ERRORLEVEL%
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
_适用于 PowerShell 所有版本_

当您在脚本里运行原生的 EXE 控制台命令，这些命令通常返回一个数字型的返回值。这个值被称为“ErrorLevel”。在批处理文件里，您可以通过 `%ERRORLEVEL%` 访问这个返回值。

让我们看看 PowerShell 如何获取和存放这个数字型返回值，以及一个 PowerShell 脚本如何返回自己的“ErrorLevel”——它将被 PowerShell 脚本的调用者接收到：

    ping 1.2.3.4 -n 1 -w 500
    $result1 = $LASTEXITCODE
    
    ping 127.0.0.1 -n 1 -w 500
    $result2 = $LASTEXITCODE
    
    $result1
    $result2
    
    if ($result1 -eq 0 -and $result2 -eq 0)
    {
      exit 0
    }
    else
    {
      exit 1
    } 

在这个例子里，代码中 ping 了两个 IP 地址。第一个调用失败了，第二个调用成功了。该脚本将 `$LASTEXITCODE` 的返回值保存在两个变量里。

然后它计算出这些返回值的影响结果。在这个例子中，如果所有调用返回 0，PowerShell 脚本将 ErrorLevel 代码设置为 0，否则为 1。

当然，这只是一个简单的例子。您可以配合您自己的原生命令使用。只需要确保调用原生应用程序之后立刻保存 `$LASTEXITCODE` 值，因为它会被后续的调用覆盖。

<!--more-->
本文国际来源：[Dealing with %ERRORLEVEL%](http://community.idera.com/powershell/powertips/b/tips/posts/dealing-with-errorlevel)
