layout: post
date: 2016-02-10 12:00:00
title: "PowerShell 技能连载 - ___"
description: PowerTip of the Day - Magic Underscore Variable
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
Here is a very special (and very underdocumented) way to use PowerShell parameters. Have a look at this function:

    #requires -Version 2
    
    function Test-DollarUnderscore
    {
      param
      (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]
        $Test
      )
    
      process
      {
        "received: $Test"
      }
    }
    

It does not seem to be very unusual at first. You can assign values to the -Test parameter, and the function returns them:

     
    PS C:\> Test-DollarUnderscore -Test 'Some Data'
    received: Some Data 
     

But now check out what happens when you pipe data into the function:

     
    PS C:\> 1..4 | Test-DollarUnderscore -Test { "I am receiving $_" }
    received: I am receiving 1
    received: I am receiving 2
    received: I am receiving 3
    received: I am receiving 4 
     

The -Test parameter suddenly and automagically accepts script blocks (although the assigned type was a string), and inside of the script block, you have access to the incoming pipeline element.

You get this very special parameter support when you set ValueFromPipelineByPropertyName=$true with a mandatory paramater, and the incoming data has no property that matches the parameter.

 

Throughout this month, we'd like to point you to two awesome community-driven global PowerShell events taking place this year: 

Europe: April 20-22: 3-day PowerShell Conference EU in Hannover, Germany, with more than 30+ speakers including Jeffrey Snover and Bruce Payette, and 60+ sessions ([www.psconf.eu](http://www.psconf.eu)). 

Asia: October 21-22: 2-day PowerShell Conference Asia in Singapore. Watch latest annoncements at [www.psconf.asia](http://www.psconf.asia/)

Both events have limited seats available so you may want to register early.

<!--more-->
本文国际来源：[Magic Underscore Variable](http://powershell.com/cs/blogs/tips/archive/2016/02/10/magic-underscore-variable.aspx)
