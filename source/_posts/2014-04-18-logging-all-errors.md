layout: post
title: "PowerShell 技能连载 - 记录所有错误"
date: 2014-04-18 00:00:00
description: PowerTip of the Day - Logging All Errors
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
在上一个技巧中您学到了只有将 cmdlet 的 `-ErrorAction` 参数设为 `"Stop"`，才可以用异常处理器捕获 cmdlet 的错误。但使用这种方式改变了 cmdlet 的行为。它将导致 cmdlet 发生第一个错误的时候停止执行。

请看下一个例子：它将在 windows 文件夹中递归地扫描 PowerShell 脚本。如果您希望捕获错误（例如存取受保护的子文件夹），这将无法工作：

    try
    {
      Get-ChildItem -Path $env:windir -Filter *.ps1 -Recurse -ErrorAction Stop
    }
    catch
    {
      Write-Warning "Error: $_"
    } 

以上代码将捕获第一个错误，但 cmdlet 将会停止执行，并且不会继续扫描剩下的子文件夹。

如果您只是需要隐藏错误提示信息，但需要完整的执行结果，而且异常处理器不会捕获到任何东西：

    try
    {
      Get-ChildItem -Path $env:windir -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue
    }
    catch
    {
      Write-Warning "Error: $_"
    } 

所以如果您希望一个 cmdlet 运行时不会中断，并且任然能获取一个您有权限的文件夹的完整列表，那么请不要使用异常处理器。相反，使用 `-ErrorVariable` 并将错误信息静默地保存到一个变量中。

当该 cmdlet 执行结束时，您可以获取该变量的值并产生一个错误报告：

    Get-ChildItem -Path $env:windir -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue -ErrorVariable myErrors
    
    Foreach ($incidence in $myErrors)
    {
        Write-Warning ("Unable to access " + $incidence.CategoryInfo.TargetName)
    }   

![](/img/2014-04-18-logging-all-errors-001.png)

<!--more-->
本文国际来源：[Logging All Errors](http://community.idera.com/powershell/powertips/b/tips/posts/logging-all-errors)
