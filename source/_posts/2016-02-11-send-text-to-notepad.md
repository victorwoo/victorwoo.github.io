layout: post
date: 2016-02-11 12:00:00
title: "PowerShell 技能连载 - ___"
description: PowerTip of the Day - Send Text to Notepad
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
Notepad can be used to display text results. Typically, you would need to save text results to file, then have Notepad open that file. There is a better way, though: launch an empty Notepad, and send the text via Windows messages directly to the untitled Notepad editor.

Here is a function called Out-Notepad. Whatever text you submit to this function: it will be shown in an untitled instance of Notepad:

    #requires -Version 2
    function Out-Notepad
    {
      param
      (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [String]
        [AllowEmptyString()] 
        $Text
      )
    
      begin
      {
        $sb = New-Object System.Text.StringBuilder
      }
    
      process
      {
        $null = $sb.AppendLine($Text)
      }
      end
      {
        $text = $sb.ToString()
    
        $process = Start-Process notepad -PassThru
        $null = $process.WaitForInputIdle()
    
    
        $sig = '
          [DllImport("user32.dll", EntryPoint = "FindWindowEx")]public static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);
          [DllImport("User32.dll")]public static extern int SendMessage(IntPtr hWnd, int uMsg, int wParam, string lParam);
        '
    
        $type = Add-Type -MemberDefinition $sig -Name APISendMessage -PassThru
        $hwnd = $process.MainWindowHandle
        [IntPtr]$child = $type::FindWindowEx($hwnd, [IntPtr]::Zero, "Edit", $null)
        $null = $type::SendMessage($child, 0x000C, 0, $text)
      }
    }
    

And here are a couple of sample calls:

     
    PS C:\> Get-Content $env:windir\system32\drivers\etc\hosts | Out-Notepad
    
    PS C:\> Get-Process | Out-String | Out-Notepad 
     

 

Throughout this month, we'd like to point you to three awesome community-driven global PowerShell events taking place this year:

Europe: April 20-22: 3-day PowerShell Conference EU in Hannover, Germany, with more than 30+ speakers including Jeffrey Snover and Bruce Payette, and 60+ sessions: [www.psconf.eu](http://www.psconf.eu).

Asia: October 21-22: 2-day PowerShell Conference Asia in Singapore. Watch latest announcements at [www.psconf.asia](http://www.psconf.asia/)

North America: April 4-6: 3-day PowerShell and DevOps Global Summit in Bellevue, WA, USA with 20+ speakers including many PowerShell Team members: [https://eventloom.com/event/home/PSNA16](https://eventloom.com/event/home/PSNA16)

All events have limited seats available so you may want to register early.

<!--more-->
本文国际来源：[Send Text to Notepad](http://powershell.com/cs/blogs/tips/archive/2016/02/11/send-text-to-notepad.aspx)
