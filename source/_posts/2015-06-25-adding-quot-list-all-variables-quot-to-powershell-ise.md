layout: post
date: 2015-06-25 11:00:00
title: "PowerShell 技能连载 - 将“列出所有变量”功能加入 PowerShell"
description: PowerTip of the Day - Adding "List All Variables" to PowerShell ISE
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
在前一个技能中我们展示了一个可以显示 PowerShell ISE 中所有打开的脚本的所有变量名的脚本。

以下是一个改造，能够在 PowerShell ISE 的“附加工具”菜单中新增一个“List Variables”命令：

    $code = {
      $psise.CurrentPowerShellTab.Files |
      ForEach-Object {
            $errors = $null
            [System.Management.Automation.PSParser]::Tokenize($_.Editor.Text, [ref]$errors) |
            Where-Object { $_.Type -eq 'Variable'} |
            Select-Object -Property Content |
            Add-Member -MemberType NoteProperty -Name Script -Value $_.DisplayName -PassThru
          } |
          Sort-Object -Property Content, Script -Unique |
          Out-GridView -Title 'Variables in use' -PassThru
        }
        
    $psise.CurrentPowerShellTab.AddOnsMenu.Submenus.Add('List Variables', $code, 'ALT+V')

当您运行这段代码后，您可以按下 `ALT`+`V` 打开一个网格窗口显示所有打开的脚本中用到的变量。

<!--more-->
本文国际来源：[Adding "List All Variables" to PowerShell ISE](http://community.idera.com/powershell/powertips/b/tips/posts/adding-quot-list-all-variables-quot-to-powershell-ise)
