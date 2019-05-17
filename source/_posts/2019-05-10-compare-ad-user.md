---
layout: post
date: 2019-05-10 00:00:00
title: "PowerShell 技能连载 - 对比 AD 用户"
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
您是否曾希望对比 ADUser 的属性？假设您安装了 RSAT 工具，您可以用 `Get-ADUser` 读取每个 AD 用户，但是对比它们的属性不那么容易。

除非使用以下函数：它基本上是将 AD 用户属性分割成独立的对象，这样便可以使用 `Compare-Object`：

```powershell
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
```

以下是输出可能看起来的样子：

```powershell
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
```

还可以只输出需要的属性：

```powershell
PS C:\> Compare-User -User1 student1 -User2 administrator -Filter memberof, lastlogontime, logonCount, Name

Name                                                                                     Value
----                                                                                     -----
logonCount                                                                                 177
logonCount                                                                                   4
MemberOf   ...ise Admins,CN=Users,DC=CCIE,DC=LAN, CN=Schema Admins,CN=Users,DC=CCIE,DC=LAN...}
MemberOf   ...LAN, CN=Test1,CN=Users,DC=CCIE,DC=LAN, CN=Domain Admins,CN=Users,DC=CCIE,DC=LAN}
Name                                                                             Administrator
Name                                                                                  student1
```

<!--本文国际来源：[Compare AD User](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/compare-ad-user)-->
