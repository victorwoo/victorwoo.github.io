---
layout: post
date: 2014-09-12 11:00:00
title: "PowerShell 技能连载 - 移除非法的路径字符"
description: PowerTip of the Day - Removing Illegal Path Characters
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

在路径名中，有些字符，例如冒号和双引号，都是非法的。如果您的脚本中的路径名称来自于外部信息，那么您可能希望最终的路径名是合法的。

以下是一个将路径中所有非法字符替换成下划线的函数：

    function Get-LegalPathName($Path)
    {
      $illegalChars = [System.IO.Path]::GetInvalidFileNameChars() 
    
      foreach($illegalChar in $illegalChars) 
      { $Path = $Path.Replace($illegalChar, '_') }
    
      $Path
    }  

这是结果看起来的样子：

    PS> Get-LegalPathName 'some:"illegal"\path<chars>.txt'
    some__illegal__path_chars_.txt

<!--more-->
本文国际来源：[Removing Illegal Path Characters](http://community.idera.com/powershell/powertips/b/tips/posts/removing-illegal-pathcharacters)
