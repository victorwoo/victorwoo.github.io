layout: post
date: 2015-04-28 11:00:00
title: "PowerShell 技能连载 - 为什么“exit”将会关掉 PowerShell"
description: PowerTip of the Day - Why "exit" can kill PowerShell
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
某些时候，我们会误会“exit”语句的工作方式。以下是一个例子：

    function abc
    {
      'Start'
    
      exit 100
    
      'Done'
    }
    
    abc

当您运行这个脚本时，`abc` 函数会被调用，然后退出。您会见到“Start”提示，但见不到“Done”提示，并且 `$LASTEXITCODE` 变量的值为 100。但这是实际情况吗？

当您在交互式的 PowerShell 控制台以交互式的方式运行 `abc` 方式时，该函数仍然退出了，不过这次，PowerShell 也被关闭了。为什么呢？

“Exit”在调用者作用域中退出代码。当您运行一个脚本时，该脚本退出后 PowerShell 仍然继续运行。当您以交互式的方式执行该函数时，交互式的 PowerShell 作为全局作用域退出了，而且由于不存在更高层的作用域了，所以 PowerShell 关闭了。

要更明显一点体现这个观点，我们在上述示例脚本中增加一点内容：

    function abc
    {
      'Start'
    
      exit 100
    
      'Done'
    }
    
    'Function starts'
    abc
    'Function ends' 

如您所发现的，“exit”实际上并不是退出 `abc` 函数，而是退出整个脚本。所以您既见不到“Done”字样也见不到“Function ends”字样。

所以请慎用“exit”语句！它只能用在退出一个脚本并将控制权交还给调用者的时候。

<!--more-->
本文国际来源：[Why "exit" can kill PowerShell](http://powershell.com/cs/blogs/tips/archive/2015/04/28/why-quot-exit-quot-can-kill-powershell.aspx)
