---
layout: post
date: 2014-09-17 11:00:00
title: "PowerShell 技能连载 - 查找脚本中的错误"
description: PowerTip of the Day - Finding Errors in Scripts
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

没有比这种更简单的方法来查找脚本中的语法错误了。只需要用这个过滤器：

    filter Test-SyntaxError
    {
       $text = Get-Content -Path $_.FullName
       if ($text.Length -gt 0)
       {
          $err = $null
          $null = [System.Management.Automation.PSParser]::Tokenize($text, [ref] $err)
          if ($err) { $_ }
       }
    }

通过使用这个过滤器，您可以快速地扫描文件夹，甚至整台计算机，列出所有包含语法错误的 PowerShell 文件。

以下代码将在您的用户文件夹下遍历并查找所有的 PowerShell 脚本并列出包含语法错误的文件：

	PS> dir $home -Filter *.ps1 -Recurse -Exclude *.ps1xml | Test-SyntaxError

<!--本文国际来源：[Finding Errors in Scripts](http://community.idera.com/powershell/powertips/b/tips/posts/finding-errors-in-scripts)-->
