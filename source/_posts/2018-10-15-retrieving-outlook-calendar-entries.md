---
layout: post
date: 2018-10-15 00:00:00
title: "PowerShell 技能连载 - Retrieving Outlook Calendar Entries"
description: PowerTip of the Day - Retrieving Outlook Calendar Entries
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
If you use Outlook to organize your calendar events, here is a useful PowerShell function that connects to Outlook and dumps your calendar entries:

    Function Get-OutlookCalendar
    {
        # load the required .NET types
        Add-Type -AssemblyName 'Microsoft.Office.Interop.Outlook'
        
        # access Outlook object model
        $outlook = New-Object -ComObject outlook.application
    
        # connect to the appropriate location
        $namespace = $outlook.GetNameSpace('MAPI')
        $Calendar = [Microsoft.Office.Interop.Outlook.OlDefaultFolders]::olFolderCalendar
        $folder = $namespace.getDefaultFolder($Calendar)
        # get calendar items
        $folder.items |
          Select-Object -Property Start, Categories, Subject, IsRecurring, Organizer
    }
    

Try this:

     
    PS> Get-OutlookCalendar | Out-GridView

<!--more-->
本文国际来源：[Retrieving Outlook Calendar Entries](http://community.idera.com/powershell/powertips/b/tips/posts/retrieving-outlook-calendar-entries)
