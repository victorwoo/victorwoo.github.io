---
layout: post
date: 2017-11-29 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell ISE 中添加单行注释"
description: PowerTip of the Day - Adding Single Line Comments in PowerShell ISE
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
在前一个技能中，我们学习了针对 PowerShell ISE 的命令扩展。以下是另一个例子，增加 `CTRL`+`K` 键盘快捷键，在选中的每一行尾部添加注释 (`#`)。

```powershell
function Invoke-Comment
{
    $file = $psise.CurrentFile                              
    $comment = ($file.Editor.SelectedText -split '\n' | ForEach-Object { "#$_" }) -join "`n"                                                 
    $file.Editor.InsertText($comment)                     
}

$psise.CurrentPowerShellTab.AddOnsMenu.Submenus.Add('Comment Out', { Invoke-Comment }, 'CTRL+K')
```

<!--more-->
本文国际来源：[Adding Single Line Comments in PowerShell ISE](http://community.idera.com/powershell/powertips/b/tips/posts/adding-single-line-comments-in-powershell-ise)
