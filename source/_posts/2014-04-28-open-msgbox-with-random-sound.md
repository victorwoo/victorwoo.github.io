---
layout: post
title: "PowerShell 技能连载 - 弹出对话框时播放随机的音效"
date: 2014-04-28 00:00:00
description: PowerTip of the Day - Open MsgBox with Random Sound
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
您也许了解了如何用脚本打开一个 MsgBox 对话框。今天，您将学习如何用一段代码打开一个 MsgBox，同时播放一段随机的音效，吸引用户的注意力并增加趣味性。当用户操作 MsgBox 的时候，音效立即停止：

    # find random WAV file in your Windows folder
    $randomWAV = Get-ChildItem -Path C:\Windows\Media -Filter *.wav | 
      Get-Random |
      Select-Object -ExpandProperty Fullname
    
    # load Forms assembly to get a MsgBox dialog
    Add-Type -AssemblyName System.Windows.Forms
    
    # play random sound until MsgBox is closed
    $player = New-Object Media.SoundPlayer $randomWAV
    $player.Load();
    $player.PlayLooping()
    $result = [System.Windows.Forms.MessageBox]::Show("We will reboot your machine now. Ok?", "PowerShell", "YesNo", "Exclamation")
    $player.Stop()

<!--more-->
本文国际来源：[Open MsgBox with Random Sound](http://community.idera.com/powershell/powertips/b/tips/posts/open-msgbox-with-random-sound)
