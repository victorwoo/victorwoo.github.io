---
layout: post
date: 2020-05-22 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell Gallery 搜索新模块"
description: PowerTip of the Day - Searching PowerShell Gallery for New Modules
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
官方的 PowerShell Gallery 是一个公共仓库，其中包含数千个免费的 PowerShell 模块。无需重新设计轮子，而是完全可以浏览 gallery 以查找可重用的代码，这些代码可按原样使用或用作自己项目的起点。让我们看一下如何从 PowerShell 库中发现和下载 PowerShell 代码。

您可以在 [https://powershellgallery.com](https://powershellgallery.com) 上使用其图形前端来搜索代码，但是 `Find-Module` cmdlet 是一种更好，更强大的方法。如果您正在寻找通过 PowerShell 管理 Office 365 的方法，可以通过下面这行代码获取包含 "Office" 关键字的所有模块：

```powershell
Name                                                  CompanyName                               PublishedDate       Description
----                                                  -----------                               -------------       -----------
OfficeOnlineServerDsc                                 {PowerShellTeam, gaelcolas, dsccommunity} 03.04.2020 22:01:30 The OfficeOnlineSe...
Office365DnsChecker                                   rhymeswithmogul                           30.03.2020 14:15:00 Checks a domain's ...
Microsoft.Graph.DevicesApps.OfficeConfiguration       msgraph-sdk-powershell                    17.03.2020 01:24:39 Microsoft Graph Po...
IntraOffice.ContentRepository.Powershell              rderegt                                   06.03.2020 14:26:35 Client library for...
Office365DSC                                          NikCharleboisPFE                          04.03.2020 23:13:30 This DSC module is...
Office365PowershellUtils                              joshn-whatcomtrans.net                    03.03.2020 00:26:59 A collection of cm...
Office365Cmdlets                                      CData                                     20.02.2020 20:13:29 CData Cmdlets for ...
MSPOffice365Tools                                     majorwitteman                             13.02.2020 20:26:15 Collection of Offi...
AdminToolbox.Office365                                {TaylorLee, Taylor_Lee}                   27.01.2020 15:26:36 Functions for work...
OfficeAddinManager                                    DarrenDK                                  17.12.2019 07:10:08 Module for managin...
PSP-Office365                                         powershellpr0mpt                          20.11.2019 10:57:08 Helper module to g...
Office365MailAliases                                  Cloudenius                                17.11.2019 11:57:07 This module contai...
Office365Toolkit                                      PatrickJD84                               03.09.2019 03:01:36 A collection of sc...
Office365.Connect                                     nicomartens                               22.08.2019 07:58:43 Uses the Windows C...
Office365TokenGet                                     junecastillote                            17.07.2019 03:21:07 Helps you acquire ...
BitTitan.Runbooks.Office365SecurityAndCompliance.Beta BT_AutomationEngineers                    14.05.2019 08:41:04 PowerShell module ...
BitTitan.Runbooks.Office365SecurityAndCompliance      BT_AutomationEngineers                    12.03.2019 07:22:10 PowerShell module ...
Office365Module                                       Giertz                                    24.01.2019 22:56:08 test for ez
ZIM.Office365                                         Mikezim                                   14.12.2018 11:53:54 Provides a set of ...
MZN.Office365                                         michael.zimmerman                         14.12.2018 08:10:26 Provides a set of ...
JumpCloud.Office365.SSO                               Scottd3v                                  14.06.2018 16:13:13 Functions to enabl...
Office365GraphAPI                                     chenxizhang                               12.06.2017 15:14:57 Office 365 Graph A...
Office365Connect                                      Gonjer                                    18.05.2017 21:13:41 Office365Connect i...
RackspaceCloudOffice                                  {mlk, paul.trampert.rackspace}            28.09.2016 14:34:25 REST client for th...
Office365                                             StevenAyers                               16.07.2016 10:53:36 For Microsoft Part...
OfficeProvider                                        abaker                                    01.03.2016 21:00:35 OfficeProvider all...
```

该列表包括发布者和模块描述，并按从新到旧的顺序对模块进行排序。`PublishedDate` 列指示模块是否是最近刚添加到 gallery中，这样您可以立即查看它是否维护良好并且值得一看。

如果您发现某个特定模块有趣，请获取其所有元数据：

```powershell
PS> Find-Module -Name Office365PowershellUtils -Repository PSGallery | Select-Object -Property *


Name                       : Office365PowershellUtils
Version                    : 1.1.5
Type                       : Module
Description                : A collection of cmdlets for managing Office365
Author                     : R. Josh Nylander
CompanyName                : joshn-whatcomtrans.net
Copyright                  : (c) 2012 WTA. All rights reserved.
PublishedDate              : 03.03.2020 00:26:59
InstalledDate              :
UpdatedDate                :
LicenseUri                 :
ProjectUri                 :
IconUri                    :
Tags                       : {PSModule}
Includes                   : {Function, RoleCapability, Command, DscResource...}
PowerShellGetFormatVersion :
ReleaseNotes               :
Dependencies               : {}
RepositorySourceLocation   : https://www.powershellgallery.com/api/v2
Repository                 : PSGallery
PackageManagementProvider  : NuGet
AdditionalMetadata         : @{summary=A collection of cmdlets for managing Office365; versionDownloadCount=33; ItemType=Module;
                                copyright=(c) 2012 WTA. All rights reserved.; PackageManagementProvider=NuGet; CompanyName=Whatcom
                                Transportation Authority; SourceName=PSGallery; tags=PSModule; created=03.03.2020 00:26:59 +01:00;
                                description=A collection of cmdlets for managing Office365; published=03.03.2020 00:26:59 +01:00;
                                developmentDependency=False; NormalizedVersion=1.1.5; downloadCount=296;
                                GUID=c6b26555-2b5f-45bc-affe-ef1c31580df3; lastUpdated=02.04.2020 16:50:22 +02:00; Authors=R. Josh
                                Nylander; updated=2020-04-02T16:50:22Z; Functions=Find-MsolUsersWithLicense
                                Update-MsolLicensedUsersFromGroup Update-MsolUserUsageLocation Change-ProxyAddress Add-ProxyAddress
                                Remove-ProxyAddress Set-ProxyAddress Sync-ProxyAddress Test-ProxyAddress Get-ProxyAddressDefault
                                Enable-SecurityGroupAsDistributionGroup Disable-SecurityGroupAsDistributionGroup Start-DirSync
                                Get-NextDirSync Suspend-UserMailbox Resume-UserMailbox Test-Mailbox Get-MailboxMemberOf
                                Clear-MailboxMemberOf Use-Office365 Export-PSCredential Import-PSCredential; isLatestVersion=True;
                                PowerShellVersion=3.0; IsPrerelease=false; isAbsoluteLatestVersion=True; packageSize=16635; FileList=Office3
                                65PowershellUtils.nuspec|Function_Connect-Office365.ps1|Office365PowershellUtils.psd1|Office365PowerShellUti
                                ls_mod.psm1|PSCredentials.psm1|README|SampleMigrationScripts\Monitor-MoveStats.ps1|SampleMigrationScripts\Re
                                sume-FirstFiveSuspended.ps1|SampleMigrationScripts\Set-MailboxTimeZone.ps1|SampleMigrationScripts\Set-Remote
                                RoutingAddress.ps1|SampleMigrationScripts\Set-RetentionPolicy.ps1|SampleMigrationScripts\Set-RoleAssignmentP
                                olicy.ps1; requireLicenseAcceptance=False}
```

如果您只对源代码感兴趣，请使用 `Save-Module` 并将模块下载到您选择的文件夹中：

```powershell
# path to source code
$path = "c:\sources"

# name of module to investigate
$moduleName = "Office365PowershellUtils"

# create folder
$null = New-Item -Path $path -ItemType Directory

# download module
Save-Module -Name $moduleName -Path $path -Repository PSGallery

# open folder with sources
explorer (Join-Path -Path $path -ChildPath $moduleName)
```

如果您想按原样实际使用该模块，请改用 `Install-Module`：

```powershell
PS> Install-Module -Name Office365PowershellUtils -Scope CurrentUser -Repository PSGallery
```

<!--本文国际来源：[Searching PowerShell Gallery for New Modules](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/searching-powershell-gallery-for-new-modules)-->

