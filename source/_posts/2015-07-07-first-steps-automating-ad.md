layout: post
date: 2015-07-07 04:00:00
title: "PowerShell 技能连载 - AD 操作自动化入门"
description: PowerTip of the Day - First Steps Automating AD
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
当 Microsoft 下载的免费的 RSAT 工具包含了 ActiveDirectory 模块。它带有一系列管理 Active Directory 账户的命令。

假设您已经连入了一个 Active Directory 环境，您可以使用以下示例代码来熟悉这些新命令：

    # find your own user account by SAMAccountName
    Get-ADUser -Identity $env:USERNAME
    
    # find user account by DN
    Get-ADUser -Identity 'CN=TWeltner,OU=Users,OU=Hannover,OU=Trainees,DC=powershell,DC=local'
    
    # find your own user account and return all available attributes
    Get-ADUser -Identity $env:USERNAME -Properties * 
    
    # find your own user account and change attributes
    Get-ADUser -Identity $env:USERNAME | Set-ADUser -Description 'My account'
    
    # find all user accounts where the SAMAccount name starts with "T"
    Get-ADUser -Filter 'SAMAccountName -like "T*"'
    
    # find user account "ThomasP" and use different logon details for AD
    
    # logon details for your AD
    $cred = Get-Credential
    $IPDC = '10.10.11.2'
    Get-ADUser -Identity ThomasP -Credential $cred -Server $IPDC
    
    # find all groups and output results to gridview
    Get-ADGroup -Filter * | Out-GridView
    
    # find all groups below a given search root
    Get-ADGroup -Filter * -SearchBase 'OU=test,DC=powershell,DC=local'
    
    # get all members of a group
    Get-ADGroupMember -Identity 'Domain Admins' 
    
    # create new user account named "Tom"
    # define password
    $secret = 'Initial$$00' | ConvertTo-SecureString -AsPlainText -Force
    $secret = Read-Host -Prompt 'Password' -AsSecureString
    New-ADUser -Name Tom -SamAccountName Tom -ChangePasswordAtLogon $true -AccountPassword $secret -Enabled $true 
    
    # delete user account "Tom"
    Remove-ADUser -Identity Tom -Confirm:$false
    
    # create an organizational unit named "NewOU1" in powershell.local
    New-ADOrganizationalUnit -Name 'NewOU1' -Path 'DC=powershell,DC=local'
    
    # all user accounts not used within last 180 days
    $FileTime = (Get-Date).AddDays(-180).ToFileTime()
    $ageLimit = "(lastLogontimestamp<=$FileTime)"
    Get-ADUser -LDAPFilter $ageLimit

<!--more-->
本文国际来源：[First Steps Automating AD](http://community.idera.com/powershell/powertips/b/tips/posts/first-steps-automating-ad)
