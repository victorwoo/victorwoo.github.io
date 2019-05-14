---
layout: post
date: 2019-05-10 00:00:00
title: "PowerShell 技能连载 - Compare AD User"
description: PowerTip of the Day - Compare AD User
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Did you ever want to compare the properties of ADUsers? Provided you have installed the RSAT tools, you can read individual AD users with Get-ADUser, but comparing their properties isn’t easy.

Except when you use below function: it basically splits up AD user properties into individual objects that can be compared using Compare-Object:

    #requires -Version 3.0 -Modules ActiveDirectory

    function Compare-User
    {
        param
        (
            [Parameter(Mandatory)][String]
            $User1,

            [Parameter(Mandatory)][String]
            $User2,

            [String[]]
            $Filter =$null
        )


        function ConvertTo-Object
        {

            process
            {
                $user = $_
                $user.PropertyNames | ForEach-Object {
                    [PSCustomObject]@{
                        Name = $_
                        Value = $user.$_
                        Identity = $user.SamAccountName
                    }
                }
            }
        }

        $l1 = Get-ADUser -Identity $User1 -Properties * | ConvertTo-Object
        $l2 = Get-ADUser -Identity $User2 -Properties * | ConvertTo-Object

        Compare-Object -Ref $l1 -Dif $l2 -Property Name, Value |
            Sort-Object -Property Name |
            Where-Object {
                $Filter -eq $null -or $_.Name -in $Filter
            }
    }


Here is what the output might look like:



    PS C:\> Compare-User -User1 student1 -User2 administrator

    Name                                                                                     Value
    ----                                                                                     -----
    accountExpires                                                                               0
    accountExpires                                                             9223372036854775807
    badPasswordTime                                                             131977150131836679
    badPasswordTime                                                             131986685447368488
    CanonicalName                                                     CCIE.LAN/Users/Administrator
    CanonicalName                                                          CCIE.LAN/Users/student1
    CN                                                                               Administrator
    CN                                                                                    student1
    Created                                                                    08.03.2019 10:31:50
    Created                                                                    02.04.2019 09:13:17
    createTimeStamp                                                            08.03.2019 10:31:50
    createTimeStamp                                                            02.04.2019 09:13:17
    Description                             Built-in account for administering the computer/domain
    Description
    DistinguishedName                                          CN=student1,CN=Users,DC=CCIE,DC=LAN
    DistinguishedName                                     CN=Administrator,CN=Users,DC=CCIE,DC=LAN
    dSCorePropagationData              ...2019 10:47:56, 08.03.2019 10:32:47, 01.01.1601 19:12:16}
    dSCorePropagationData                               {02.04.2019 09:15:28, 01.01.1601 01:00:00}
    isCriticalSystemObject                                                                    True
    LastBadPasswordAttempt                                                     22.03.2019 08:56:53
    LastBadPasswordAttempt                                                     02.04.2019 10:49:04
    lastLogon                                                                   131986622819726136
    lastLogon                                                                   131986685566131171
    LastLogonDate                                                              02.04.2019 10:34:39
    LastLogonDate                                                              02.04.2019 09:04:41
    lastLogonTimestamp                                                          131986622819726136
    lastLogonTimestamp                                                          131986676794218709
    logonCount                                                                                 177
    logonCount                                                                                   4
    logonHours                                                             {255, 255, 255, 255...}
    MemberOf                           ...CIE,DC=LAN, CN=Schema Admins,CN=Users,DC=CCIE,DC=LAN...}
    MemberOf                           ...C=CCIE,DC=LAN, CN=Domain Admins,CN=Users,DC=CCIE,DC=LAN}
    Modified                                                                   03.04.2019 11:26:30
    Modified                                                                   02.04.2019 09:04:41
    modifyTimeStamp                                                            03.04.2019 11:26:30
    modifyTimeStamp                                                            02.04.2019 09:04:41
    msDS-User-Account-Control-Computed                                                     8388608
    msDS-User-Account-Control-Computed                                                           0
    Name                                                                             Administrator
    Name                                                                                  student1
    ObjectGUID                                                6f5d7164-33cf-440a-af8c-3e973a1f381a
    ObjectGUID                                                ffe12d2d-cfdd-41f6-8268-41c493786f90
    objectSid                                        S-1-5-21-2389183542-1750168592-3050041687-500
    objectSid                                       S-1-5-21-2389183542-1750168592-3050041687-1128
    PasswordExpired                                                                           True
    PasswordExpired                                                                          False
    PasswordLastSet
    PasswordLastSet                                                            08.03.2019 09:41:25
    pwdLastSet                                                                                   0
    pwdLastSet                                                                  131965080857557947
    SamAccountName                                                                        student1
    SamAccountName                                                                   Administrator
    SID                                             S-1-5-21-2389183542-1750168592-3050041687-1128
    SID                                              S-1-5-21-2389183542-1750168592-3050041687-500
    uSNChanged                                                                               25764
    uSNChanged                                                                               24620
    uSNCreated                                                                               24653
    uSNCreated                                                                                8196
    whenChanged                                                                02.04.2019 09:04:41
    whenChanged                                                                03.04.2019 11:26:30
    whenCreated                                                                08.03.2019 10:31:50
    whenCreated                                                                02.04.2019 09:13:17


You can limit the output to only the attributes you are after, too:


    PS C:\> Compare-User -User1 student1 -User2 administrator -Filter memberof, lastlogontime, logonCount, Name

    Name                                                                                     Value
    ----                                                                                     -----
    logonCount                                                                                 177
    logonCount                                                                                   4
    MemberOf   ...ise Admins,CN=Users,DC=CCIE,DC=LAN, CN=Schema Admins,CN=Users,DC=CCIE,DC=LAN...}
    MemberOf   ...LAN, CN=Test1,CN=Users,DC=CCIE,DC=LAN, CN=Domain Admins,CN=Users,DC=CCIE,DC=LAN}
    Name                                                                             Administrator
    Name                                                                                  student1


- - -

_[psconf.eu](http://www.psconf.eu/) – PowerShell Conference EU 2019 – June 4-7, Hannover Germany – visit [www.psconf.eu](http://www.psconf.eu/) There aren’t too many trainings around for experienced PowerShell scripters where you really still learn something new. But there’s one place you don’t want to miss: PowerShell Conference EU - with 40 renown international speakers including PowerShell team members and MVPs, plus 350 professional and creative PowerShell scripters. Registration is open at www.psconf.eu, and the full 3-track 4-days agenda becomes available soon. Once a year it’s just a smart move to come together, update know-how, learn about security and mitigations, and bring home fresh ideas and authoritative guidance. We’d sure love to see and hear from you!_

[![Twitter This Tip!](/img/2019-05-10-compare-ad-user-001.gif)](http://twitter.com/home/?status=RT+%40PowerTip+%20Compare%20AD%20User%20with%20%23PowerShell+http://bit.ly/2V0UjlS)[ReTweet this Tip!](http://twitter.com/home/?status=RT+%40%20Compare%20AD%20User%20with%20%23PowerShell+http://bit.ly/2V0UjlS)

<!--本文国际来源：[Compare AD User](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/compare-ad-user)-->
