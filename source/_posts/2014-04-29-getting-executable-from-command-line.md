---
layout: post
title: "PowerShell 技能连载 - 从命令行中提取可执行程序名"
date: 2014-04-29 00:00:00
description: PowerTip of the Day - Getting Executable from Command Line
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有些时候我们需要从命令行提取命令名。以下是实现的方法：

![](/img/2014-04-29-getting-executable-from-command-line-001.png)

代码如下：

    function Remove-Argument
    {
      param
      (
        $CommandLine
      )
      
      $divider = ' '
      if ($CommandLine.StartsWith('"')) 
      { 
        $divider = '"'
        $CommandLine = $CommandLine.SubString(1)
      }
      
      $CommandLine.Split($divider)[0]
    } 

<!--本文国际来源：[Getting Executable from Command Line](http://community.idera.com/powershell/powertips/b/tips/posts/getting-executable-from-command-line)-->
