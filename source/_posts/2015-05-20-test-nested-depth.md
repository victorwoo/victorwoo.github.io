layout: post
date: 2015-05-20 11:00:00
title: "PowerShell 技能连载 - 测试嵌套深度"
description: PowerTip of the Day - Test Nested Depth
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
当您调用一个函数时，PowerShell 会增加嵌套的深度。当一个函数调用另一个函数，或是一段脚本时，将进一步增加嵌套的深度。以下是一个能够告诉您当前代码嵌套深度的函数：

    function Test-NestLevel
    {
      $i = 1
      $ok = $true
      do
      {
        try
        {
          $test = Get-Variable -Name Host -Scope $i
        }
        catch
        {
          $ok = $false
        }
        $i++
      } While ($ok)
    
      $i
    }

当您设计递归（调用自身的函数）函数时，这种方法十分有用。

以下是使用该技术的示例代码：

    function Test-Diving
    {
        param($Depth)
    
        if ($Depth -gt 10) { return }
    
        "Diving deeper to $Depth meters..."
    
        $currentDepth = Test-NestLevel
        "calculated depth: $currentDepth"
    
        Test-Diving -depth ($Depth+1)
    }
    
    Test-Diving -depth 1

当您运行 `Test-Diving` 时，该函数将调用自身，直到达到 10 米深。该函数使用一个参数来控制嵌套深度，而 `Test-NestLevel` 的执行结果将返回相同的数字。

请注意它们的区别：`Test-NestLevel` 返回所有（绝对的）嵌套级别，而参数告诉您函数调用自己的次数。如果 `Test-Diving` 包含在其它函数中，那么绝对的级别和相对的级别将会不同：

    PS C:\> Test-Diving -Depth 1
    diving deeper to 1 meters...
    calculated depth: 1
    diving deeper to 2 meters...
    calculated depth: 2
    diving deeper to 3 meters...
    calculated depth: 3
    diving deeper to 4 meters...
    calculated depth: 4
    diving deeper to 5 meters...
    calculated depth: 5
    diving deeper to 6 meters...
    calculated depth: 6
    diving deeper to 7 meters...
    calculated depth: 7
    diving deeper to 8 meters...
    calculated depth: 8
    diving deeper to 9 meters...
    calculated depth: 9
    diving deeper to 10 meters...
    calculated depth: 10
    
    PS C:\> & { Test-Diving -Depth 1 }
    diving deeper to 1 meters...
    calculated depth: 2
    diving deeper to 2 meters...
    calculated depth: 3
    diving deeper to 3 meters...
    calculated depth: 4
    diving deeper to 4 meters...
    calculated depth: 5
    diving deeper to 5 meters...
    calculated depth: 6
    diving deeper to 6 meters...
    calculated depth: 7
    diving deeper to 7 meters...
    calculated depth: 8
    diving deeper to 8 meters...
    calculated depth: 9
    diving deeper to 9 meters...
    calculated depth: 10
    diving deeper to 10 meters...
    calculated depth: 11
    
    PS C:\>

`Test-NestLevel` 总是从当前的代码中返回嵌套的级别到全局作用域。

<!--more-->
本文国际来源：[Test Nested Depth](http://powershell.com/cs/blogs/tips/archive/2015/05/20/test-nested-depth.aspx)
