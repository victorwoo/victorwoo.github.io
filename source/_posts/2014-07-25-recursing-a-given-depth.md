---
layout: post
date: 2014-07-25 11:00:00
title: "PowerShell 技能连载 - 指定递归深度"
description: PowerTip of the Day - Recursing a Given Depth
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
_适用于 PowerShell 3.0 及更高版本_

当使用 `Get-ChildItem` 来列出文件夹内容时，可以用 `-Recurse` 参数来对子目录进行递归。然而，这导致无法控制递归深度。`Get-ChildItem` 会在所有子目录中搜索，无限地递归下去。

    Get-ChildItem -Path $env:windir -Filter *.log -Recurse -ErrorAction SilentlyContinue

有些时候，我们会见到一种类似这样的方法，来试图控制递归的深度：

    Get-ChildItem -Path $env:windir\*\*\* -Filter *.log -ErrorAction SilentlyContinue

然而，这并不能限制只递归 3 层。实际上，它的作用是搜索 3 层及 3 层以上的文件夹。它不会搜索 1 层或 2 层的文件夹。

限制递归深度的唯一办法是自己实现递归算法：

    function Get-MyChildItem
    {
      param
      (
        [Parameter(Mandatory = $true)]
        $Path,
        
        $Filter = '*',
        
        [System.Int32]
        $MaxDepth = 3,
        
        [System.Int32]
        $Depth = 0
      )
      
      $Depth++
    
      Get-ChildItem -Path $Path -Filter $Filter -File 
      
      if ($Depth -le $MaxDepth)
      {
        Get-ChildItem -Path $Path -Directory |
          ForEach-Object { Get-MyChildItem -Path $_.FullName -Filter $Filter -Depth $Depth -MaxDepth $MaxDepth}
      }
      
    }
    
    Get-MyChildItem -Path c:\windows -Filter *.log -MaxDepth 2 -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty FullName

这段代码将获取您 Windows 文件夹中深度在 2 层以内的 \*.log 文件。

<!--more-->
本文国际来源：[Recursing a Given Depth](http://community.idera.com/powershell/powertips/b/tips/posts/recursing-a-given-depth)
