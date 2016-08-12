layout: post
date: 2016-01-08 12:00:00
title: "PowerShell 技能连载 - ___"
description: PowerTip of the Day - Creating New Objects by Hash Table Conversion
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
Beginning in PowerShell 3.0, you can create pre-initialized objects by using a hash table. Simply add the properties you want to preinitialize, then convert the hash table to the desired type.

Here is a practical example:

    #requires -Version 3
    
    $preInit = @{
      Rate = -10
      Volume = 100
    }
    
    Add-Type -AssemblyName System.Speech
    $speaker = [System.Speech.Synthesis.SpeechSynthesizer] $preInit
    $null = $Speaker.SpeakAsync(“Oh boy, that was a New Year’s party. I guess I need a little break.”)
    

When you run this code, PowerShell creates a new System.Speech object and preinitializes the values for rate and volume. When you output text to speech using the SpeakAsync() method, the text is spoken very slowly. Rate accepts values between -10 and 10.

<!--more-->
本文国际来源：[Creating New Objects by Hash Table Conversion](http://powershell.com/cs/blogs/tips/archive/2016/01/08/creating-new-objects-by-hash-table-conversion.aspx)
