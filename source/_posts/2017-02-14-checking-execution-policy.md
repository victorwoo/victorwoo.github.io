layout: post
date: 2017-02-13 16:00:00
title: "PowerShell 技能连载 - Checking Execution Policy"
description: PowerTip of the Day - Checking Execution Policy
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
Execution policy determines what kind of scripts PowerShell will execute. You need to set execution policy to something other than Undefined, Restricted, or Default in order for scripts to run.

For inexperienced users, the “RemoteSigned” setting is recommended. It runs local scripts, and scripts located on fileservers inside your trusted network domain. It won’t run scripts downloaded from the internet or from other untrusted sources unless these scripts carry a valid digital signature.

Here is how you can view and set your current execution policy.

     
    PS C:\> Get-ExecutionPolicy
    Restricted
    
    PS C:\> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    
    PS C:\> Get-ExecutionPolicy
    RemoteSigned
    
    PS C:\>  
     

When you use “CurrentUser” scope, there is no need for admin privileges to change this setting. It is your personal safety belt, no corporate security boundary. The setting persists until you change it again.

If you need to ensure that you can run any script at any location unattended, you may want to use the “Bypass” setting instead of “RemoteSigned”. “Bypass” runs a script regardless of where it is located, and unlike “Unrestricted”, will not pop up confirmation dialogs.

<!--more-->
本文国际来源：[Checking Execution Policy](http://community.idera.com/powershell/powertips/b/tips/posts/checking-execution-policy)
