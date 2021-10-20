---
layout: post
date: 2021-09-28 00:00:00
title: "PowerShell 技能连载 - Disabling Local “Guest” Account"
description: "PowerTip of the Day - Disabling Local “Guest” Account"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows comes with the built-in account called “Guest”. Since this account is seldomly used, you may want to disable it. Else, its well-known name could serve as a vector for attackers.

Since the account name is localized and can slightly vary from culture to culture, to identify the account use its SID:


    PS> Get-Localuser | Where-Object Sid -like 'S-1-5-*-501'

    Name  Enabled Description
    ----  ------- -----------
    Guest False   Built-in account for guest access to the computer/domain


If the account isn’t already disabled (see “Enabled” property), use an elevated PowerShell and the Disable-LocalUser cmdlet to disable the account.





ReTweet this Tip!

<!--本文国际来源：[Disabling Local “Guest” Account](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/disabling-local-guest-account)-->

