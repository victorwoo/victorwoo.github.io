---
layout: post
date: 2022-04-08 00:00:00
title: "PowerShell 技能连载 - Managing Wi-Fi Profiles"
description: PowerTip of the Day - Managing Wi-Fi Profiles
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
On Windows, you can use old console commands to discover Wi-Fi profiles:

     
    PS> netsh wlan show profiles  
     

From here, you can even view individual profile details and get to the cached clear text passwords. Yet all of this is console based, so it is not object oriented, requires a lot of string operations and may return unexpected information when profiles use special characters or your computer uses a different locale.

A much better approach is using the native Windows API. There is a public module available on PowerShell Gallery that you can use. Install it like this:

     
    PS> Install-Module -Name WifiProfileManagement -Scope CurrentUser  
     

The rest is trivial. To dump all saved Wi-Fi profiles (including those with special characters in their name) use Get-WiFiProfile:

        PS C:\> Get-WiFiProfile 
    
    ProfileName               ConnectionMode Authentication Encryption Password
    -----------               -------------- -------------- ---------- --------
    HOTSPLOTS_WR_Muehlenberg  manual         open           none
    Zudar06_Gast              auto           WPA2PSK        AES
    management                auto           WPA3SAE        AES
    MagentaWLAN-X5HZ          auto           WPA3SAE        AES
    Alando-Whg.17             auto           WPA2PSK        AES 
    internet-cafe             auto           WPA2PSK        AES
    Training                  manual         WPA2PSK        AES
    QSC-Guest                 auto           open           none
    ibisbudget                manual         open           none
    Leonardo                  auto           open           none  
    ROOMZ-GUEST               auto           open           none 
    Freewave                  auto           open           none

![Thumbsup](https://community.idera.com/cfs-file/__key/system/emoji/1f44d.svg)

![Thumbsup](https://community.idera.com/cfs-file/__key/system/emoji/1f44d.svg)

![Thumbsup](https://community.idera.com/cfs-file/__key/system/emoji/1f44d.svg)

PS Saturday          auto           WPA2PSK        AES
    WIFIonICE                 manual         open           none
    Airport Hotel             auto           WPA2PSK        AES
     

And to see the cached Wi-Fi passwords, simply add the -ClearKey parameter. The cached passwords will now appear in clear text in the “Password” column.

Should you be interested to use this functionality directly inside your own code, simply look at the source code in the module. It is highly complex yet native PowerShell. Anyone looking for native API ways to talk directly to the Wi-Fi subsystem should dive into the code.





<!--本文国际来源：[Managing Wi-Fi Profiles](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-wi-fi-profiles)-->
