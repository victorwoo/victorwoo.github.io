---
layout: post
date: 2017-11-07 00:00:00
title: "PowerShell 技能连载 - Multipass: 安全存储多个凭据"
description: 'PowerTip of the Day - Multipass: Securely Storing Multiple Credentials'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
If you’d like to safely store credentials (usernames and password) for your personal use in a file, here is a very simple yet extremely powerful approach. Take a look at this code:

    $Path = "$home\Desktop\multipass.xml"
    
    [PSCustomObject]@{
        User1 = Get-Credential -Message User1
        User2 = Get-Credential -Message User2
        User3 = Get-Credential -Message User3
    } | Export-Clixml -Path $Path
    

When you run it, it asks for three credentials and saves them to a “multipass” file on your desktop. All passwords are safely encrypted with your identity and your machines identity (which is why the file can only be read by you, and only on the machine where it was created).

To later on use one of the credentials, this is how you read them back in:

    $multipass = Import-Clixml -Path $Path
    

You can then access the credentials via the properties “User1”, “User2”, and “User3”, and use the credentials in your scripts wherever a cmdlet asks for a credential:

     
    PS C:\> $multipass.User1
    
    UserName                     Password
    --------                     --------
    AlbertK  System.Security.SecureString

<!--本文国际来源：[Multipass: Securely Storing Multiple Credentials](http://community.idera.com/powershell/powertips/b/tips/posts/multipass-securely-storing-multiple-credentials)-->
