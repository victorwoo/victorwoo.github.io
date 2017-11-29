---
layout: post
date: 2017-11-28 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell ISE 中切换注释"
description: PowerTip of the Day - Toggling Comments in PowerShell ISE
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
PowerShell ISE 暴露了一些可扩展的组件。例如，如果您希望按下 `CTRL`+`K` 切换选中文本的注释状态，请试试这段代码：

```powershell
function Toggle-Comment
{
    $file = $psise.CurrentFile
    $text = $file.Editor.SelectedText
    if ($text.StartsWith("<#")) {
        $comment = $text.Substring(3).TrimEnd("#>")
    }
    else
    {
        $comment = "<#" + $text + "#>"
    }
    $file.Editor.InsertText($comment)
}

$psise.CurrentPowerShellTab.AddOnsMenu.Submenus.Add('Toggle Comment', { Toggle-Comment }, 'CTRL+K')
```

它基本上是使用 `$psise` 来操作 ISE 对象模型，然后安装一个快捷键为 `CTRL`+`K` 的新的菜单命令来调用 `Toggle-Comment` 函数。

在位于 `$profile` 的用户配置文件脚本中（这个路径可能还不存在）增加这段代码，PowerShell ISE 每次启动的时候就会自动运行这段代码。

<!--more-->
本文国际来源：[Toggling Comments in PowerShell ISE](http://community.idera.com/powershell/powertips/b/tips/posts/toggling-comments-in-powershell-ise)
