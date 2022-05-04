---
layout: post
date: 2022-04-04 00:00:00
title: "PowerShell 技能连载 - Using Predictive IntelliSense"
description: PowerTip of the Day - Using Predictive IntelliSense
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Predictive IntelliSense is a new feature in PSReadLine 2.1 and was improved in version 2.2. As such, it is available in all PowerShell consoles starting in PowerShell version 5.1. If you are uncertain whether your PowerShell console is using the latest version of PSReadLine, try this:


    PS> Update-Module -Name PSReadLine


If you can’t update the module because it shipped with Windows, or you are missing privileges, try and freshly install it like so:


    PS> Install-Module -Name PSReadLine -Scope CurrentUser -Force


Next, restart you PowerShell console.

The reason why you may not have heard anything about “predictive IntelliSense” is that it is turned off by default. To turn it on, run this:


    PS> Set-PSReadLineOption -PredictionSource HistoryAndPlugin


In Windows PowerShell, you are limited to the option “History” only:


    PS> Set-PSReadLineOption -PredictionSource History


Immediately thereafter, when you type commands in your console, you start seeing shadowed (darker) IntelliSense suggestions while you type. These suggestions are taken primarily from your command history so PowerShell starts suggesting command parameters that you commonly use. The auto-suggestion is an individualized experience, and the actual suggestions depend on your previous PowerShell commands:


    PS> Get-Service | import-database -Database $db


If you don’t like this “real-time” IntelliSense, turn it off again like so:


    PS> Set-PSReadLineOption -PredictionSource None






<!--本文国际来源：[Using Predictive IntelliSense](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-predictive-intellisense)-->

