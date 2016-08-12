layout: post
date: 2015-12-31 12:00:00
title: "PowerShell 技能连载 - ___"
description: PowerTip of the Day - Managing Windows Firewall
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
Beginning in Windows 8 and Server 2012, there is a cmdlet that helps you enable the client firewall for various profiles:

    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    

In previous operating systems, you have to resort to netsh.exe:

    netsh advfirewall set allprofiles state on

<!--more-->
本文国际来源：[Managing Windows Firewall](http://powershell.com/cs/blogs/tips/archive/2015/12/31/managing-windows-firewall.aspx)
