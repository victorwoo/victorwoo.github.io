---
layout: post
date: 2022-03-29 00:00:00
title: "PowerShell 技能连载 - Update PowerShell’s PSReadLine"
description: "PowerTip of the Day - Update PowerShell’s PSReadLine"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Do you know the PSReadLine module? It’s included in PowerShell 5 and 7 by default, and this module is responsible for the convenient color coding in PowerShell consoles, among a number of additional benefits that makes handling code easier. PowerShell loads this module by default in console-based environments (it’s not being used in the PowerShell ISE).

To check the current version, run this:


    PS> try { (Get-Module -Name PSReadLine).Version.ToString() } catch { Write-Warning 'PSReadLine not used in this host' }
    2.1.0


The line either returns the current PSReadLine version used by your PowerShell host, or emits a warning that PSReadline isn’t used by your host (i.e. inside the PowerShell ISE host which takes care of color coding internally).

You should make sure you are using the latest version of PSReadline. This line would try and update it to the latest version:


    PS> Update-Module -Name PSReadLine


Just in case you can’t update the module because it shipped with Windows, try and freshly install it like so:


    PS> Install-Module -Name PSReadLine -Scope CurrentUser -Force



Make sure you relaunch PowerShell after you have updated PSReadLine to load the latest version.

PSReadLine comes with powerful new features such as “predictive IntelliSense” and dynamic help that are explained here: [https://devblogs.microsoft.com/powershell/psreadline-2-2-ga/](https://devblogs.microsoft.com/powershell/psreadline-2-2-ga/)





ReTweet this Tip!

<!--本文国际来源：[Update PowerShell’s PSReadLine](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/update-powershell-s-psreadline)-->

