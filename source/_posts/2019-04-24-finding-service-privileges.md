---
layout: post
date: 2019-04-24 00:00:00
title: "PowerShell 技能连载 - 查找服务特权"
description: PowerTip of the Day - Finding Service Privileges
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Get-Service` 可以提供 Windows 服务的基础信息但是并不会列出所需要的特权。以下是一段简短的 PowerShell 函数，输入一个服务名并返回服务特权：

```powershell
function Get-ServicePrivilege
{

    param
    (
        [Parameter(Mandatory)]
        [string]
        $ServiceName
    )

    # find the service
    $Service = @(Get-Service -Name $ServiceName -ErrorAction Silent)
    # bail out if there is no such service
    if ($Service.Count -ne 1)
    {
        Write-Warning "$ServiceName unknown."
        return
    }

    # read the service privileges from registry
    $Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\' +  $service.Name
    $Privs = Get-ItemProperty -Path $Path -Name RequiredPrivileges

    # output in custom object
    [PSCustomObject]@{
        ServiceName = $Service.Name
        DisplayName = $Service.DisplayName
        Privileges = $privs.RequiredPrivileges
    }
}



PS C:\> Get-ServicePrivilege spooler

ServiceName DisplayName        Privileges
----------- -----------        ----------
spooler     Druckwarteschlange {SeTcbPrivilege, SeImpersonatePrivilege, SeAuditPrivilege, SeChangeNotifyPrivilege...}



PS C:\> Get-ServicePrivilege XboxGipSvc

ServiceName DisplayName                       Privileges
----------- -----------                       ----------
XboxGipSvc  Xbox Accessory Management Service {SeTcbPrivilege, SeImpersonatePrivilege, SeChangeNotifyPrivilege, SeCreateGlobalPrivilege}
```

<!--本文国际来源：[Finding Service Privileges](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-service-privileges)-->

