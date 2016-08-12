layout: post
date: 2015-05-07 11:00:00
title: "PowerShell 技能连载 - 向管道传递一个数组"
description: PowerTip of the Day - Passing Arrays to Pipeline
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
如果一个函数返回多于一个值，PowerShell 会将它们封装为一个数组。然而如果您通过管道将它传递至另一个函数，该管道会自动地将数组“解封”，并且一次处理一个数组元素。

如果您需要原原本本地处理一个数组而不希望解封，那么请将返回值封装在另一个数组中。通过这种方式，管道会将外层的数组解封并处理内层的数组。

以下代码演示了这个技能：

    #requires -Version 1
    
    
    function Test-ArrayAsReturnValue1
    {
      param($count)
    
      $array = 1..$count
    
      return $array
    }
    
    function Test-ArrayAsReturnValue2
    {
      param($count)
    
      $array = 1..$count
    
      return ,$array
    }
    
    'Result 1:'
    Test-ArrayAsReturnValue1 -count 10 | ForEach-Object -Process {
      $_.GetType().FullName 
    }
    
    'Result 2:'
    Test-ArrayAsReturnValue2 -count 10 | ForEach-Object -Process {
      $_.GetType().FullName 
    }

当您运行这段代码时，第一个例子将返回数组中的元素。第二个例子将会把整个数组传递给循环。

     
    PS C:\> 
    
    Result 1:
    System.Int32
    System.Int32
    System.Int32
    System.Int32
    System.Int32
    System.Int32
    System.Int32
    System.Int32
    System.Int32
    System.Int32
    
    Result 2:
    System.Object[]

<!--more-->
本文国际来源：[Passing Arrays to Pipeline](http://powershell.com/cs/blogs/tips/archive/2015/05/07/passing-arrays-to-pipeline.aspx)
