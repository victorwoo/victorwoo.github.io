---
layout: post
date: 2021-07-16 00:00:00
title: "PowerShell 技能连载 - 启用 ActiveDirectory 模块"
description: PowerTip of the Day - Enabling ActiveDirectory Module
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 10 附带 `ActiveDirectory` PowerShell 模块 - 它可能尚未启用。如果您想使用 PowerShell cmdlet 进行 AD 管理 - 即 `Get-ADUser` - 只需以完全管理员权限运行以下代码：

```powershell
#requires -RunAsAdmin

$element = Get-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS*"
Add-WindowsCapability -Name $element.Name -Online
```

完成后，您现在可以访问 ActiveDirectory 模块及其 cmdlet。以下是您获得的清单：

```powershell
PS C:\> Get-Command -Module ActiveDirectory | Format-Wide -Column 4


Add-ADCentralAccessPolicyMember      Add-ADComputerServiceAccount         Add-ADDomainControllerPasswordRep... Add-ADFineGrainedPasswordPolicyS...
Add-ADGroupMember                    Add-ADPrincipalGroupMembership       Add-ADResourcePropertyListMember     Clear-ADAccountExpiration
Clear-ADClaimTransformLink           Disable-ADAccount                    Disable-ADOptionalFeature            Enable-ADAccount
Enable-ADOptionalFeature             Get-ADAccountAuthorizationGroup      Get-ADAccountResultantPasswordRep... Get-ADAuthenticationPolicy
Get-ADAuthenticationPolicySilo       Get-ADCentralAccessPolicy            Get-ADCentralAccessRule              Get-ADClaimTransformPolicy
Get-ADClaimType                      Get-ADComputer                       Get-ADComputerServiceAccount         Get-ADDCCloningExcludedApplicati...
Get-ADDefaultDomainPasswordPolicy    Get-ADDomain                         Get-ADDomainController               Get-ADDomainControllerPasswordRe...
Get-ADDomainControllerPasswordRep... Get-ADFineGrainedPasswordPolicy      Get-ADFineGrainedPasswordPolicySu... Get-ADForest
Get-ADGroup                          Get-ADGroupMember                    Get-ADObject                         Get-ADOptionalFeature
Get-ADOrganizationalUnit             Get-ADPrincipalGroupMembership       Get-ADReplicationAttributeMetadata   Get-ADReplicationConnection
Get-ADReplicationFailure             Get-ADReplicationPartnerMetadata     Get-ADReplicationQueueOperation      Get-ADReplicationSite
Get-ADReplicationSiteLink            Get-ADReplicationSiteLinkBridge      Get-ADReplicationSubnet              Get-ADReplicationUpToDatenessVec...
Get-ADResourceProperty               Get-ADResourcePropertyList           Get-ADResourcePropertyValueType      Get-ADRootDSE
Get-ADServiceAccount                 Get-ADTrust                          Get-ADUser                           Get-ADUserResultantPasswordPolicy
Grant-ADAuthenticationPolicySiloA... Install-ADServiceAccount             Move-ADDirectoryServer               Move-ADDirectoryServerOperationM...
Move-ADObject                        New-ADAuthenticationPolicy           New-ADAuthenticationPolicySilo       New-ADCentralAccessPolicy
New-ADCentralAccessRule              New-ADClaimTransformPolicy           New-ADClaimType                      New-ADComputer
New-ADDCCloneConfigFile              New-ADFineGrainedPasswordPolicy      New-ADGroup                          New-ADObject
New-ADOrganizationalUnit             New-ADReplicationSite                New-ADReplicationSiteLink            New-ADReplicationSiteLinkBridge
New-ADReplicationSubnet              New-ADResourceProperty               New-ADResourcePropertyList           New-ADServiceAccount
New-ADUser                           Remove-ADAuthenticationPolicy        Remove-ADAuthenticationPolicySilo    Remove-ADCentralAccessPolicy
Remove-ADCentralAccessPolicyMember   Remove-ADCentralAccessRule           Remove-ADClaimTransformPolicy        Remove-ADClaimType
Remove-ADComputer                    Remove-ADComputerServiceAccount      Remove-ADDomainControllerPassword... Remove-ADFineGrainedPasswordPolicy
Remove-ADFineGrainedPasswordPolic... Remove-ADGroup                       Remove-ADGroupMember                 Remove-ADObject
Remove-ADOrganizationalUnit          Remove-ADPrincipalGroupMembership    Remove-ADReplicationSite             Remove-ADReplicationSiteLink
Remove-ADReplicationSiteLinkBridge   Remove-ADReplicationSubnet           Remove-ADResourceProperty            Remove-ADResourcePropertyList
Remove-ADResourcePropertyListMember  Remove-ADServiceAccount              Remove-ADUser                        Rename-ADObject
Reset-ADServiceAccountPassword       Restore-ADObject                     Revoke-ADAuthenticationPolicySilo... Search-ADAccount
Set-ADAccountAuthenticationPolicy... Set-ADAccountControl                 Set-ADAccountExpiration              Set-ADAccountPassword
Set-ADAuthenticationPolicy           Set-ADAuthenticationPolicySilo       Set-ADCentralAccessPolicy            Set-ADCentralAccessRule
Set-ADClaimTransformLink             Set-ADClaimTransformPolicy           Set-ADClaimType                      Set-ADComputer
Set-ADDefaultDomainPasswordPolicy    Set-ADDomain                         Set-ADDomainMode                     Set-ADFineGrainedPasswordPolicy
Set-ADForest                         Set-ADForestMode                     Set-ADGroup                          Set-ADObject
Set-ADOrganizationalUnit             Set-ADReplicationConnection          Set-ADReplicationSite                Set-ADReplicationSiteLink
Set-ADReplicationSiteLinkBridge      Set-ADReplicationSubnet              Set-ADResourceProperty               Set-ADResourcePropertyList
Set-ADServiceAccount                 Set-ADUser                           Show-ADAuthenticationPolicyExpres... Sync-ADObject
Test-ADServiceAccount                Uninstall-ADServiceAccount           Unlock-ADAccount
```

<!--本文国际来源：[Enabling ActiveDirectory Module](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/enabling-activedirectory-module)-->

