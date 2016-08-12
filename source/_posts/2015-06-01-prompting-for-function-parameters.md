layout: post
date: 2015-06-01 11:00:00
title: "PowerShell 技能连载 - 显示函数参数"
description: PowerTip of the Day - Prompting for Function Parameters
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
通过一个简单的技巧，您可以创建一个对话框窗口来帮助用户提供您写的函数的所需要参数。

只需要使用 `$PSBoundParameters` 来判定用户是否传入了参数。如果用户未传入参数，那么请运行 `Show-Command` 并传入您的函数名，然后返回您的函数，其它什么也不用做。

`Show-Command` 自动解决剩下的部分：它会显示一个包括所有函数参数的对话框，当用户点击“运行”时，它将以提交的参数运行该函数。

    function Show-PromptInfo
    {
      param
      (
        [string]
        $Name,
    
        [int]
        $ID
      )
      if ($PSBoundParameters.Count -eq 0)
      {
        Show-Command -Name Show-PromptInfo
        return
      }
    
      "Your name is $name, and the id is $id."
    }

当您执行 `Show-PromptInfo` 函数时传入了正确的参数，则将立即执行该函数的内容。

    PS> Show-PromptInfo -Name weltner -ID 12
    Your name is weltner, and the id is 12.
    
    PS> Show-PromptInfo
    <# Dialog opens, then runs the function with submitted parameters#>

当您执行该函数时没有传入任何参数，则将弹出一个对话框，提示您交互式地输入参数。

<!--more-->
本文国际来源：[Prompting for Function Parameters](http://powershell.com/cs/blogs/tips/archive/2015/06/01/prompting-for-function-parameters.aspx)
