layout: post
date: 2016-02-12 12:00:00
title: "PowerShell 技能连载 - ___"
description: PowerTip of the Day - Sending Objects to Notepad
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
In a previous tip we showed how you can send text to a fresh Notepad instance. Today, you get an enhanced version of Out-Notepad: you can pipe anything to Notepad now. If it is not a string, Out-Notepad uses the internal PowerShell ETS to convert it to text and show it appropriately:

    #requires -Version 2
    function Out-Notepad
    {
      param
      (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [Object]
        [AllowEmptyString()] 
        $Object,
    
        [Int]
        $Width = 150
      )
    
      begin
      {
        $al = New-Object System.Collections.ArrayList
      }
    
      process
      {
        $null = $al.Add($Object)
      }
      end
      {
        $text = $al | 
        Format-Table -AutoSize -Wrap | 
        Out-String -Width $Width
    
        $process = Start-Process notepad -PassThru
        $null = $process.WaitForInputIdle()
    
    
        $sig = '
          [DllImport("user32.dll", EntryPoint = "FindWindowEx")]public static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);
          [DllImport("User32.dll")]public static extern int SendMessage(IntPtr hWnd, int uMsg, int wParam, string lParam);
        '
    
        $type = Add-Type -MemberDefinition $sig -Name APISendMessage2 -PassThru
        $hwnd = $process.MainWindowHandle
        [IntPtr]$child = $type::FindWindowEx($hwnd, [IntPtr]::Zero, "Edit", $null)
        $null = $type::SendMessage($child, 0x000C, 0, $text)
      }
    }
    

You can pipe anything to Out-Notepad. If it is text already, it is displayed as-is:

     
    PS C:\> Get-Content $env:windir\system32\drivers\etc\hosts | Out-Notepad
     

If you pipe object results, Out-Notepad converts them to text and makes sure nothing is cut off. You may want to play with the -Width parameter to choose the page width that works best for you:

     
    PS C:\> Get-EventLog -LogName System -EntryType Error, Warning -Newest 10 | Out-Notepad -Width 130 
     

And you may want to maximize Notepad or disable word wrap to see the correct formatting.

 

Throughout this month, we'd like to point you to three awesome community-driven global PowerShell events taking place this year:

Europe: April 20-22: 3-day PowerShell Conference EU in Hannover, Germany, with more than 30+ speakers including Jeffrey Snover and Bruce Payette, and 60+ sessions: [www.psconf.eu](http://www.psconf.eu).

Asia: October 21-22: 2-day PowerShell Conference Asia in Singapore. Watch latest announcements at [www.psconf.asia](http://www.psconf.asia/)

North America: April 4-6: 3-day PowerShell and DevOps Global Summit in Bellevue, WA, USA with 20+ speakers including many PowerShell Team members: [https://eventloom.com/event/home/PSNA16](https://eventloom.com/event/home/PSNA16)

All events have limited seats available so you may want to register early.

<!--more-->
本文国际来源：[Sending Objects to Notepad](http://powershell.com/cs/blogs/tips/archive/2016/02/12/sending-objects-to-notepad.aspx)
