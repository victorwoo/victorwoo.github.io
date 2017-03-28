layout: post
title: "PowerShell 技能连载 - 接受多重输入"
date: 2014-07-11 00:00:00
description: PowerTip of the Day - Accepting Multiple Input
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
当您创建 PowerShell 函数时，以下是一个定义了既能够从参数中获取值，又能从管道中获取值的多功能 `InputObject` 参数的代码模板：

    function Get-Something
    {
      param
      (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Object[]]
        $InputObject 
      )
      
      process
      {
        $InputObject | ForEach-Object {
          $element = $_
          "processing $element"
        }
      }
    }
    
这是该函数的使用效果：

    PS> Get-Something -InputObject 1,2,3,4
    processing 1
    processing 2
    processing 3
    processing 4
    
    PS> 1,2,3,4 | Get-Something
    processing 1
    processing 2
    processing 3
    processing 4

请注意这个参数被定义成对象数组（所以它可以接收多个值）。然后，该参数值被送到 `ForEach-Object` 命令，将值一个一个取出来。这是针对第一个例子的调用方式。

要能够从管道中接收多个值，请确保对接收管道输入的参数设置了 `ValueFromPipeline` 属性。下一步，在函数中添加一段 `Process` 脚本块。这段代码充当循环的作用，和 `ForEach-Object` 十分相似，并且作用于管道送过来的每一个对象上。

<!--more-->
本文国际来源：[Accepting Multiple Input](http://community.idera.com/powershell/powertips/b/tips/posts/accepting-multiple-input)
