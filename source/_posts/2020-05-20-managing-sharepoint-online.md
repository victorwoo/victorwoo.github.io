---
layout: post
date: 2020-05-20 00:00:00
title: "PowerShell 技能连载 - 管理 SharePoint Online"
description: PowerTip of the Day - Managing SharePoint Online
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您使用 SharePoint Online，并希望通过 PowerShell 对其进行管理，请从 PowerShell Gallery 中下载并安装 `Microsoft.Online.SharePoint.PowerShell` 模块：

```powershell
# search for the module in PowerShell Gallery (optional)
PS> Find-Module -Name Microsoft.Online.SharePoint.PowerShell

Version              Name                                Repository           Description
-------              ----                                ----------           --------
16.0.19927.12000     Microsoft.Online.SharePoint.Powe... PSGallery            Microsoft SharePoint Online

# install the module in your personal scope (no admin privileges required)
PS> Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Repository PSGallery -Scope CurrentUser
```

现在，您可以使用大量新的 PowerShell cmdlet 来管理 SharePoint Online：

```powershell
PS> Get-Command -Module Microsoft.Online.SharePoint.PowerShell | Format-Wide -Column 3


Add-SPOGeoAdministrator    Add-SPOHubSiteAssociation  Add-SPOHubToHubAssocia...
Add-SPOOrgAssetsLibrary    Add-SPOSiteCollectionAp... Add-SPOSiteDesign
Add-SPOSiteDesignTask      Add-SPOSiteScript          Add-SPOSiteScriptPackage
Add-SPOTenantCdnOrigin     Add-SPOTheme               Add-SPOUser
Approve-SPOTenantServic... Approve-SPOTenantServic... Connect-SPOService
ConvertTo-SPOMigrationE... ConvertTo-SPOMigrationT... Deny-SPOTenantServiceP...
Disable-SPOTenantServic... Disconnect-SPOService      Enable-SPOCommSite
Enable-SPOTenantService... Export-SPOQueryLogs        Export-SPOUserInfo
Export-SPOUserProfile      Get-SPOAppErrors           Get-SPOAppInfo
Get-SPOBrowserIdleSignOut  Get-SPOBuiltInDesignPac... Get-SPOCrossGeoMovedUsers
Get-SPOCrossGeoMoveReport  Get-SPOCrossGeoUsers       Get-SPODataEncryptionP...
Get-SPODeletedSite         Get-SPOExternalUser        Get-SPOGeoAdministrator
Get-SPOGeoMoveCrossComp... Get-SPOGeoStorageQuota     Get-SPOHideDefaultThemes
Get-SPOHomeSite            Get-SPOHubSite             Get-SPOKnowledgeHubSite
Get-SPOMigrationJobProg... Get-SPOMigrationJobStatus  Get-SPOMultiGeoCompany...
Get-SPOMultiGeoExperience  Get-SPOOrgAssetsLibrary    Get-SPOOrgNewsSite
Get-SPOPublicCdnOrigins    Get-SPOSite                Get-SPOSiteCollectionA...
Get-SPOSiteContentMoveS... Get-SPOSiteDataEncrypti... Get-SPOSiteDesign
Get-SPOSiteDesignRights    Get-SPOSiteDesignRun       Get-SPOSiteDesignRunSt...
Get-SPOSiteDesignTask      Get-SPOSiteGroup           Get-SPOSiteRenameState
Get-SPOSiteScript          Get-SPOSiteScriptFromList  Get-SPOSiteScriptFromWeb
Get-SPOSiteUserInvitations Get-SPOStorageEntity       Get-SPOStructuralNavig...
Get-SPOStructuralNaviga... Get-SPOTenant              Get-SPOTenantCdnEnabled
Get-SPOTenantCdnOrigins    Get-SPOTenantCdnPolicies   Get-SPOTenantContentTy...
Get-SPOTenantLogEntry      Get-SPOTenantLogLastAva... Get-SPOTenantOrgRelation
Get-SPOTenantOrgRelatio... Get-SPOTenantOrgRelatio... Get-SPOTenantServicePr...
Get-SPOTenantServicePri... Get-SPOTenantSyncClient... Get-SPOTenantTaxonomyR...
Get-SPOTheme               Get-SPOUnifiedGroup        Get-SPOUnifiedGroupMov...
Get-SPOUser                Get-SPOUserAndContentMo... Get-SPOUserOneDriveLoc...
Get-SPOWebTemplate         Grant-SPOHubSiteRights     Grant-SPOSiteDesignRights
Invoke-SPOMigrationEncr... Invoke-SPOSiteDesign       Invoke-SPOSiteSwap
New-SPOMigrationEncrypt... New-SPOMigrationPackage    New-SPOPublicCdnOrigin
New-SPOSdnProvider         New-SPOSite                New-SPOSiteGroup
New-SPOTenantOrgRelation   Register-SPODataEncrypt... Register-SPOHubSite
Remove-SPODeletedSite      Remove-SPOExternalUser     Remove-SPOGeoAdministr...
Remove-SPOHomeSite         Remove-SPOHubSiteAssoci... Remove-SPOHubToHubAsso...
Remove-SPOKnowledgeHubSite Remove-SPOMigrationJob     Remove-SPOMultiGeoComp...
Remove-SPOOrgAssetsLibrary Remove-SPOOrgNewsSite      Remove-SPOPublicCdnOrigin
Remove-SPOSdnProvider      Remove-SPOSite             Remove-SPOSiteCollecti...
Remove-SPOSiteCollectio... Remove-SPOSiteDesign       Remove-SPOSiteDesignTask
Remove-SPOSiteGroup        Remove-SPOSiteScript       Remove-SPOSiteUserInvi...
Remove-SPOStorageEntity    Remove-SPOTenantCdnOrigin  Remove-SPOTenantOrgRel...
Remove-SPOTenantSyncCli... Remove-SPOTheme            Remove-SPOUser
Remove-SPOUserInfo         Remove-SPOUserProfile      Repair-SPOSite
Request-SPOPersonalSite    Request-SPOUpgradeEvalu... Restore-SPODataEncrypt...
Restore-SPODeletedSite     Revoke-SPOHubSiteRights    Revoke-SPOSiteDesignRi...
Revoke-SPOTenantService... Revoke-SPOUserSession      Set-SPOBrowserIdleSignOut
Set-SPOBuiltInDesignPac... Set-SPOGeoStorageQuota     Set-SPOHideDefaultThemes
Set-SPOHomeSite            Set-SPOHubSite             Set-SPOKnowledgeHubSite
Set-SPOMigrationPackage... Set-SPOMultiGeoCompanyA... Set-SPOMultiGeoExperience
Set-SPOOrgAssetsLibrary    Set-SPOOrgNewsSite         Set-SPOSite
Set-SPOSiteDesign          Set-SPOSiteGroup           Set-SPOSiteOffice365Group
Set-SPOSiteScript          Set-SPOSiteScriptPackage   Set-SPOStorageEntity
Set-SPOStructuralNaviga... Set-SPOStructuralNaviga... Set-SPOTenant
Set-SPOTenantCdnEnabled    Set-SPOTenantCdnPolicy     Set-SPOTenantContentTy...
Set-SPOTenantSyncClient... Set-SPOTenantTaxonomyRe... Set-SPOUnifiedGroup
Set-SPOUser                Set-SPOWebTheme            Start-SPOSiteContentMove
Start-SPOSiteRename        Start-SPOUnifiedGroupMove  Start-SPOUserAndConten...
Stop-SPOSiteContentMove    Stop-SPOUserAndContentMove Submit-SPOMigrationJob
Test-SPOSite               Unregister-SPOHubSite      Update-SPODataEncrypti...
Update-UserType            Upgrade-SPOSite            Verify-SPOTenantOrgRel...
```

第一步总是从 `Connect-SPOService` 开始，连接到SharePoint Online：

```powershell
Get-Help -Name Connect-SPOService -ShowWindow
```

接下来，使用查找动词为 Get 的 cmdlet这将安全地提供大量信息，但不会更改任何设置，也不会损坏任何东西：

```powershell
PS> Get-Command -Verb Get -Module Microsoft.Online.SharePoint.PowerShell | Format-Wide -Column 3


Get-SPOAppErrors            Get-SPOAppInfo              Get-SPOBrowserIdleSignOut
Get-SPOBuiltInDesignPack... Get-SPOCrossGeoMovedUsers   Get-SPOCrossGeoMoveReport
Get-SPOCrossGeoUsers        Get-SPODataEncryptionPolicy Get-SPODeletedSite
Get-SPOExternalUser         Get-SPOGeoAdministrator     Get-SPOGeoMoveCrossComp...
Get-SPOGeoStorageQuota      Get-SPOHideDefaultThemes    Get-SPOHomeSite
Get-SPOHubSite              Get-SPOKnowledgeHubSite     Get-SPOMigrationJobProg...
Get-SPOMigrationJobStatus   Get-SPOMultiGeoCompanyAl... Get-SPOMultiGeoExperience
Get-SPOOrgAssetsLibrary     Get-SPOOrgNewsSite          Get-SPOPublicCdnOrigins
Get-SPOSite                 Get-SPOSiteCollectionApp... Get-SPOSiteContentMoveS...
Get-SPOSiteDataEncryptio... Get-SPOSiteDesign           Get-SPOSiteDesignRights
Get-SPOSiteDesignRun        Get-SPOSiteDesignRunStatus  Get-SPOSiteDesignTask
Get-SPOSiteGroup            Get-SPOSiteRenameState      Get-SPOSiteScript
Get-SPOSiteScriptFromList   Get-SPOSiteScriptFromWeb    Get-SPOSiteUserInvitations
Get-SPOStorageEntity        Get-SPOStructuralNavigat... Get-SPOStructuralNaviga...
Get-SPOTenant               Get-SPOTenantCdnEnabled     Get-SPOTenantCdnOrigins
Get-SPOTenantCdnPolicies    Get-SPOTenantContentType... Get-SPOTenantLogEntry
Get-SPOTenantLogLastAvai... Get-SPOTenantOrgRelation    Get-SPOTenantOrgRelatio...
Get-SPOTenantOrgRelation... Get-SPOTenantServicePrin... Get-SPOTenantServicePri...
Get-SPOTenantSyncClientR... Get-SPOTenantTaxonomyRep... Get-SPOTheme
Get-SPOUnifiedGroup         Get-SPOUnifiedGroupMoveS... Get-SPOUser
Get-SPOUserAndContentMov... Get-SPOUserOneDriveLocation Get-SPOWebTemplate
```

当您适应了以后，可以接着查看更改和管理 SharePoint 的其余 cmdlet：

```powershell
PS> Get-Command -Module Microsoft.Online.SharePoint.PowerShell | Group-Object Verb -NoElement | Sort-Object Count -Desc

Count Name
----- ----
    63 Get
    30 Set
    29 Remove
    12 Add
    7 New
    4 Start
    4 Revoke
    3 Export
    3 Invoke
    2 Update
    2 Stop
    2 Restore
    2 Request
    2 Register
    2 Grant
    2 Enable
    2 ConvertTo
    2 Approve
    1 Repair
    1 Disconnect
    1 Disable
    1 Deny
    1 Connect
    1 Submit
    1 Test
    1 Unregister
    1 Upgrade
    1 Verify
```

<!--本文国际来源：[Managing SharePoint Online](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-sharepoint-online)-->

