---
layout: post
date: 2019-03-04 00:00:00
title: "PowerShell 技能连载 - Creating Aligned Headers"
description: PowerTip of the Day - Creating Aligned Headers
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Reporting and writing log files is a common task in PowerShell. Here is a simple function to create nicely centered headers. Adjust $width to the desired width:

    function Show-Header($Text)
    {
      $Width=80
      $padLeft = [int]($width / 2) + ($text.Length / 2)
      $text.PadLeft($padLeft, "=").PadRight($Width, "=")
    }
    

And this is the result:

     
    PS> Show-Header Starting
    ====================================Starting====================================
    
    PS> Show-Header "Processing Input Values"
    =============================Processing Input Values============================
    
    PS> Show-Header "Calculating..."
    =================================Calculating...=================================
    
    PS> Show-Header "OK"
    =======================================OK=======================================
     

The additional learning points are:

* Use PadLeft() and PadRight() to pad (expand) a string at either end, and fill space up with the characters you want
With this learning point, you can now do many related things, i.e. create list of server names with fixed-length numbers:

- - -

    1,4,12,888 | ForEach-Object { 'Server_' + "$_".PadLeft(8, "0") }
    

- - -

     
    Server_00000001
    Server_00000004
    Server_00000012
    Server_00000888
     

- - -

_[psconf.eu](http://www.psconf.eu/) – PowerShell Conference EU 2019 – June 4-7, Hannover Germany – visit [www.psconf.eu](http://www.psconf.eu/) There aren’t too many trainings around for experienced PowerShell scripters where you really still learn something new. But there’s one place you don’t want to miss: PowerShell Conference EU - with 40 renown international speakers including PowerShell team members and MVPs, plus 350 professional and creative PowerShell scripters. Registration is open at www.psconf.eu, and the full 3-track 4-days agenda becomes available soon. Once a year it’s just a smart move to come together, update know-how, learn about security and mitigations, and bring home fresh ideas and authoritative guidance. We’d sure love to see and hear from you!_

<!--本文国际来源：[Creating Aligned Headers](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-aligned-headers)-->
