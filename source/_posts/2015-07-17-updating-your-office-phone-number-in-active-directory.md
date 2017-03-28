layout: post
date: 2015-07-17 11:00:00
title: "PowerShell 技能连载 - 更新 Active Directory 中的办公电话号码"
description: PowerTip of the Day - Updating Your Office Phone Number in Active Directory
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
如果您安装了微软免费提供的 RSAT 工具，您可以使用 PowerShell 来更新您 AD 用户账户中存储的信息，例如您的办公电话号码。

您是否有权限提交变更的信息取决于您的企业安全设置，但缺省情况下您可以修改许多（您自己账户的）信息而不需要管理员权限。

这个例子演示了用 PowerShell 脚本提示输入一个新的办公电话号码然后更新到 Active Directory 中：

    #requires -Version 1 -Modules ActiveDirectory
    $phoneNumber = Read-Host -Prompt 'Your new office phone number'
    $user = $env:USERNAME
    Set-ADUser -Identity $user -OfficePhone $phoneNumber

<!--more-->
本文国际来源：[Updating Your Office Phone Number in Active Directory](http://community.idera.com/powershell/powertips/b/tips/posts/updating-your-office-phone-number-in-active-directory)
