---
layout: post
date: 2017-12-26 00:00:00
title: "PowerShell 技能连载 - 管理用户配置文件"
description: PowerTip of the Day - Managing User Profiles
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
要转储一台机子上用户配置文件的原始列表，请使用这行代码：

```powershell
Get-CimInstance -Class Win32_UserProfile | Out-GridView
```

您将会获得所有用户配置文件的所有详细信息。用户名可以在 SID 属性中找到，但它是以 SID 的格式表示。要获得真实的用户名，需要将 SID 转换。这段代码创建一个以真实用户名为字段名的哈希表：

```powershell
$userProfiles = Get-CimInstance -Class Win32_UserProfile |
    # add property "UserName" that translates SID to username
    Add-Member -MemberType ScriptProperty -Name UserName -Value {
    ([Security.Principal.SecurityIdentifier]$this.SID).Translate([Security.Principal.NTAccount]).Value
    } -PassThru |
    # create a hash table that uses "Username" as key
    Group-Object -Property UserName -AsHashTable -AsString
```

现在可以轻松地转储机器上所有带用户配置文件的用户列表了：

```powershell
PS C:\> $userProfiles.Keys | Sort-Object
MYDOMAIN\Administrator
MYDOMAIN\User01
MYDOMAIN\User02
MYDOMAIN\User03
MYDOMAIN\User12
NT AUTHORITY\LOCAL SERVICE
NT AUTHORITY\NETWORK SERVICE
NT AUTHORITY\SYSTEM
PC10\User
```

要获取某个用户配置文件的详细信息，请访问哈希表的字段：

```powershell
PS C:\> $userProfiles["MYDOMAIN\User01"]


UserName                         : MYDOMAIN\User01
AppDataRoaming                   : Win32_FolderRedirectionHealth
Contacts                         : Win32_FolderRedirectionHealth
Desktop                          : Win32_FolderRedirectionHealth
Documents                        : Win32_FolderRedirectionHealth
Downloads                        : Win32_FolderRedirectionHealth
Favorites                        : Win32_FolderRedirectionHealth
HealthStatus                     : 3
LastAttemptedProfileDownloadTime :
LastAttemptedProfileUploadTime   :
LastBackgroundRegistryUploadTime :
LastDownloadTime                 :
LastUploadTime                   :
LastUseTime                      :
Links                            : Win32_FolderRedirectionHealth
Loaded                           : False
LocalPath                        : C:\Users\User01
Music                            : Win32_FolderRedirectionHealth
Pictures                         : Win32_FolderRedirectionHealth
RefCount                         :
RoamingConfigured                : False
RoamingPath                      :
RoamingPreference                :
SavedGames                       : Win32_FolderRedirectionHealth
Searches                         : Win32_FolderRedirectionHealth
SID                              : S-1-5-21-3860347202-3037956370-3782488958-1604
Special                          : False
StartMenu                        : Win32_FolderRedirectionHealth
Status                           : 0
Videos                           : Win32_FolderRedirectionHealth
PSComputerName                   :
```

<!--本文国际来源：[Managing User Profiles](http://community.idera.com/powershell/powertips/b/tips/posts/managing-user-profiles)-->
