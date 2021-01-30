---
layout: post
date: 2020-12-28 00:00:00
title: "PowerShell 技能连载 - 管理本地组成员（第 1 部分）"
description: PowerTip of the Day - Managing Local Group Members (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
幸运的是，PowerShell 5 及更高版本附带了诸如 `Get-LocalGroupMember` 之类的 cmdlet，该 cmdlet 列出了本地组的成员。不幸的是，这些 cmdlet 有一个缺陷：如果组包含一个或多个孤立成员，则该 cmdlet 将无法列出任何组成员。

孤立的组成员可以是已添加到组中但后来在 Active Directory 中删除的用户或组。这样的孤儿显示为 SID 号，而不是对话框中的名称。

若要解决此问题并列出组成员而不考虑孤立帐户，请尝试使用 `Get-GroupMemberLocal` 函数，该函数使用 PowerShell 自带 cmdlet 之前前通常使用的，旧的 ADSI 方法：

```powershell
function Get-GroupMemberLocal
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    param
    (
        [Parameter(Mandatory,Position=0,ParameterSetName='Name')]
        [string]
        $Name,

        [Parameter(Mandatory,Position=0,ParameterSetName='Sid')]
        [System.Security.Principal.SecurityIdentifier]
        $Sid,

        [string]
        $Computer = $env:COMPUTERNAME
    )

    if ($PSCmdlet.ParameterSetName -eq 'Sid')
    {
        $Name = $sid.Translate([System.Security.Principal.NTAccount]).Value.Split('\')[-1]
    }

    $ADSIComputer = [ADSI]("WinNT://$Computer,computer")
    $group = $ADSIComputer.psbase.children.find($Name,  'Group')
    $group.psbase.invoke("members") |
        ForEach-Object {
            try
            {
                $disabled = '-'
                $disabled = $_.GetType().InvokeMember("AccountDisabled",  'GetProperty',  $null,  $_, $null)
            } catch {}
            [PSCustomObject]@{
                Name = $_.GetType().InvokeMember("Name",  'GetProperty',  $null,  $_, $null)
                SID  = [Security.Principal.SecurityIdentifier]::new($_.GetType().InvokeMember("objectSid",  'GetProperty',  $null,  $_, $null),0)
                Path = $_.GetType().InvokeMember("AdsPath",  'GetProperty',  $null,  $_, $null)
                Type = $_.GetType().InvokeMember("Class",  'GetProperty',  $null,  $_, $null)
                Disabled = $disabled
            }
        }
    }
```

下面是一个实际示例：让我们转储本地管理员组。您可以按名称或不区分文化的 SID 来访问组：

```powershell
PS> Get-GroupMemberLocal -Sid S-1-5-32-544 | Format-Table

Name          SID                                            Path                                     Type Disabled
----          ---                                            ----                                     ---- --------
Administrator S-1-5-21-2770831484-2260150476-2133527644-500  WinNT://WORKGROUP/DELL7390/Administrator User     True
Presentation  S-1-5-21-2770831484-2260150476-2133527644-1007 WinNT://WORKGROUP/DELL7390/Presentation  User    False
RemoteAdmin   S-1-5-21-2770831484-2260150476-2133527644-1013 WinNT://WORKGROUP/DELL7390/RemoteAdmin   User    False
Management    S-1-5-21-2770831484-2260150476-2133527644-1098 WinNT://WORKGROUP/DELL7390/Management    Group       -
```

<!--本文国际来源：[Managing Local Group Members (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-local-group-members-part-1)-->

