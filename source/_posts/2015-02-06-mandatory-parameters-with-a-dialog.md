layout: post
date: 2015-02-06 12:00:00
title: "PowerShell 技能连载 - 为必须的参数弹出一个对话框"
description: PowerTip of the Day - Mandatory Parameters with a Dialog
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

通常，但您将一个参数定义为必选的，并且用户没有传入对应的实参，PowerShell 能够处理好这种情况并提示用户输入这个值：

    function Get-Something
    {
      param
      (
        [Parameter(Mandatory = $true)]
        $Path 
      )
    
      "You entered $Path."
    }

结果类似这样（您无法控制提示信息）：

    PS> Get-Something -Path test
    You entered test.
    
    PS> Get-Something 
    Cmdlet Get-Something at command pipeline position 1
    Supply values for the following parameters:
    Path: test
    You entered test.
    
    PS>  

但是您是否知道还可以通过这种方式获取一个必选参数？

    function Get-Something
    {
      param
      (
        $Path = $(Read-Host 'Please, enter a Path value')
      )
    
      "You entered $Path."
    } 

这种方法将控制权交给您，以下是它看起来的样子：

     
    PS> Get-Something -Path test
    You entered test.
    
    PS> Get-Something 
    Please, enter a Path value: test
    You entered test.
    
    PS>

<!--more-->
本文国际来源：[Mandatory Parameters with a Dialog](http://community.idera.com/powershell/powertips/b/tips/posts/mandatory-parameters-with-a-dialog)
