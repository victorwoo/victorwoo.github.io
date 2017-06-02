---
layout: post
date: 2014-07-31 11:00:00
title: "PowerShell 技能连载 - 查找并提取注册表键的路径"
description: PowerTip of the Day - Finding and Dumping Registry Key Paths
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
_适用于所有 PowerShell 版本_

在前一个技巧中，我们演示了如何将一个 PowerShell 内部的路径格式转换为一个真实的路径。以下是一个用力。这段代码递归地搜索 _HKEY_CURRENT_USER_ 键，并且找出所有包含单词“_powershell_”的注册表键（您可以将搜索关键字换成任何别的）：

    Get-ChildItem -Path HKCU:\ -Include *PowerShell* -Recurse -ErrorAction SilentlyContinue |
      Select-Object -Property *Path* |
      Out-GridView 

这段代码输出所有名称中包含“_Path_”的属性。如您所见，注册表键中有两个属性包含该关键字：_PSPath_ 和 _PSParentPath_。两者都是 PowerShell 内置的路径格式。

要提取所有满足搜索条件的注册表键的路径，请使用以下代码：

    Get-ChildItem -Path HKCU:\ -Include *PowerShell* -Recurse -ErrorAction SilentlyContinue |
      ForEach-Object {
        Convert-Path -Path $_.PSPath
      }

<!--more-->
本文国际来源：[Finding and Dumping Registry Key Paths](http://community.idera.com/powershell/powertips/b/tips/posts/finding-and-dumping-registry-key-paths)
