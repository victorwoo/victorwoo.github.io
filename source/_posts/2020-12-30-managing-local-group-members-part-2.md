---
layout: post
date: 2020-12-30 00:00:00
title: "PowerShell 技能连载 - 管理本地组成员（第 2 部分）"
description: PowerTip of the Day - Managing Local Group Members (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技巧中，我们解释了为什么访问本地组成员并不总是与内置的 cmdlet（如 `Get-LocalGroupMember`）一起使用，以及使用旧的（但仍可正常使用）ADSI 接口解决该问题的方法。

如果您想以此为基础构建解决方案，您可能想知道如何将本地帐户添加到组或从组中删除，以及如何启用和禁用本地管理员帐户。

这是说明这些方法的几行有用的代码。您可以独立使用这些代码，也可以将它们集成到自己的脚本逻辑中。

```powershell
# these examples use the data below - adjust to your needs
# DO NOT RUN THESE LINES UNLESS YOU CAREFULLY
# REVIEWED AND YOU KNOW WHAT YOU ARE DOING!

# use local machine
$ComputerName = $env:computername
# find name of local Administrators group
$Group = ([Security.Principal.SecurityIdentifier]'S-1-5-32-544').Translate([System.Security.Principal.NTAccount]).Value.Split('\')[-1]
# find name of local Administrator user
$Admin = Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount = TRUE and SID like 'S-1-5-%-500'"
$UserName = $Admin.Name
# examples

# find all local groups
$computerObj = [ADSI]("WinNT://$ComputerName,computer")
$computerObj.psbase.children |
    Where-Object { $_.psbase.schemaClassName -eq 'group' } |
    Select-Object -Property @{N='Name';E={$_.Name[0]}},
    Path,
    @{N='Sid';E={[Security.Principal.SecurityIdentifier]::new($_.objectSid.value,0).Value}}



# find members of local admin group
$computerObj = [ADSI]("WinNT://$ComputerName,computer")
$groupObj = $computerObj.psbase.children.find($Group,  'Group')
$groupObj.psbase.Invoke('Members') |
    ForEach-Object { $_.GetType().InvokeMember('ADspath','GetProperty',$null,$_,$null) }

# add user to group/remove from group
$computerObj = [ADSI]("WinNT://$ComputerName,computer")
$groupObj = $computerObj.psbase.children.find($Group,  'Group')
# specify the user or group to add or remove
$groupObj.Add('WinNT://DOMAIN/USER,user')
$groupObj.Remove('WinNT://DOMAIN/USER,user')

# enabling/disabling accounts
$computerObj = [ADSI]("WinNT://$ComputerName,computer")
$userObj = $computerObj.psbase.children.find($UserName,  'User')
#enable
$userObj.UserFlags=$userObj.UserFlags.Value -band -bnot 512
$userObj.CommitChanges()

#disable
$userObj.UserFlags=$userObj.UserFlags.Value -bor 512
$userObj.CommitChanges()
```

<!--本文国际来源：[Managing Local Group Members (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-local-group-members-part-2)-->

