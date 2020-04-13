---
layout: post
date: 2020-03-25 00:00:00
title: "PowerShell 技能连载 - 用 Carbon 添加新的 PowerShell 命令"
description: PowerTip of the Day - Adding New PowerShell Commands with Carbon
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Carbon 是 PowerShell Gallery 中最受欢迎的免费 PowerShell 模块之一。它类似于瑞士军刀，具有多种辅助功能。要安装它，请运行以下命令：

```powershell
PS> Install-Module -Name Carbon -Scope CurrentUser -Force
```

显然，该模块的所有者添加了有用的功能。这就是测试您的 PowerShell 当前是否处于提升状态所需的全部操作：

```powershell
PS> Test-CAdminPrivilege
False
```

要加密或解密字符串，请使用以下命令：

```powershell
PS> $secret = "Secret Text" | Protect-CString -ForUser

PS> $secret
AQAAANCMnd8BFdERjHoAwE/Cl+sBAAAAf0R6lgTIWkqgPubPNRqOXwAAAAACAAAAAAAQZgAAAAEAACAAAADiVJHgXqE+4kLGfPISsvSg+cBG4m8Q0c5W1nqzl/pHDgAAAAAOgAAAAA
IAACAAAACIF/xsRNBKG2cDnwCACA59JZaeOK/zedzmMrEMML0upxAAAABSmKyvYw4ul+jKW35NZdzmQAAAACE/4MFiRHJVhYOu65P/Vc7hVH5wuUfV0elFtwTfYdN+92h3aguob/Rq
fEANeUZfUotBOE4dxJDdr950rR4ss0I=

PS> $secret | Unprotect-CString
Secret Text
```

有很多参数可以通过其他方式进行加密，还有大量命令可以发现。显然，模块作者已将其命令名称前面添加了 "C"，也就是 "Carbon" 的意思，并且包括不带前缀的命令名称的别名。

命令的完整列表非常详尽：

```powershell
PS> Get-Command -Module Carbon


CommandType Name                                     Version Source
----------- ----                                     ------- ------
Alias       Add-GroupMember                          2.9.2   Carbon
Alias       Add-GroupMembers                         2.9.2   Carbon
Alias       Add-IisDefaultDocument                   2.9.2   Carbon
Alias       Add-TrustedHost                          2.9.2   Carbon
Alias       Add-TrustedHosts                         2.9.2   Carbon
Alias       Assert-AdminPrivilege                    2.9.2   Carbon
Alias       Assert-AdminPrivileges                   2.9.2   Carbon
Alias       Assert-FirewallConfigurable              2.9.2   Carbon
Alias       Assert-Service                           2.9.2   Carbon
Alias       Clear-DscLocalResourceCache              2.9.2   Carbon
Alias       Clear-MofAuthoringMetadata               2.9.2   Carbon
Alias       Clear-TrustedHost                        2.9.2   Carbon
Alias       Clear-TrustedHosts                       2.9.2   Carbon
Alias       Complete-Job                             2.9.2   Carbon
Alias       Complete-Jobs                            2.9.2   Carbon
Alias       Compress-Item                            2.9.2   Carbon
Alias       ConvertFrom-Base64                       2.9.2   Carbon
Alias       Convert-SecureStringToString             2.9.2   Carbon
Alias       ConvertTo-Base64                         2.9.2   Carbon
Alias       ConvertTo-ContainerInheritanceFlags      2.9.2   Carbon
Alias       ConvertTo-FullPath                       2.9.2   Carbon
Alias       ConvertTo-InheritanceFlag                2.9.2   Carbon
Alias       ConvertTo-InheritanceFlags               2.9.2   Carbon
Alias       ConvertTo-PropagationFlag                2.9.2   Carbon
Alias       ConvertTo-PropagationFlags               2.9.2   Carbon
Alias       ConvertTo-SecurityIdentifier             2.9.2   Carbon
Alias       Convert-XmlFile                          2.9.2   Carbon
Alias       Copy-DscResource                         2.9.2   Carbon
Alias       Disable-AclInheritance                   2.9.2   Carbon
Alias       Disable-FirewallStatefulFtp              2.9.2   Carbon
Alias       Disable-IEEnhancedSecurityConfiguration  2.9.2   Carbon
Alias       Disable-IisSecurityAuthentication        2.9.2   Carbon
Alias       Disable-NtfsCompression                  2.9.2   Carbon
Alias       Enable-AclInheritance                    2.9.2   Carbon
Alias       Enable-FirewallStatefulFtp               2.9.2   Carbon
Alias       Enable-IEActivationPermission            2.9.2   Carbon
Alias       Enable-IEActivationPermissions           2.9.2   Carbon
Alias       Enable-IisDirectoryBrowsing              2.9.2   Carbon
Alias       Enable-IisSecurityAuthentication         2.9.2   Carbon
Alias       Enable-IisSsl                            2.9.2   Carbon
Alias       Enable-NtfsCompression                   2.9.2   Carbon
Alias       Expand-Item                              2.9.2   Carbon
Alias       Find-ADUser                              2.9.2   Carbon
Alias       Format-ADSearchFilterValue               2.9.2   Carbon
Alias       Format-ADSpecialCharacters               2.9.2   Carbon
Alias       Get-ADDomainController                   2.9.2   Carbon
Alias       Get-Certificate                          2.9.2   Carbon
Alias       Get-CertificateStore                     2.9.2   Carbon
Alias       Get-ComPermission                        2.9.2   Carbon
Alias       Get-ComPermissions                       2.9.2   Carbon
Alias       Get-ComSecurityDescriptor                2.9.2   Carbon
Alias       Get-DscError                             2.9.2   Carbon
Alias       Get-DscWinEvent                          2.9.2   Carbon
Alias       Get-FileShare                            2.9.2   Carbon
Alias       Get-FileSharePermission                  2.9.2   Carbon
Alias       Get-FirewallRule                         2.9.2   Carbon
Alias       Get-FirewallRules                        2.9.2   Carbon
Alias       Get-Group                                2.9.2   Carbon
Alias       Get-HttpUrlAcl                           2.9.2   Carbon
Alias       Get-IisApplication                       2.9.2   Carbon
Alias       Get-IisAppPool                           2.9.2   Carbon
Alias       Get-IisConfigurationSection              2.9.2   Carbon
Alias       Get-IisHttpHeader                        2.9.2   Carbon
Alias       Get-IisHttpRedirect                      2.9.2   Carbon
Alias       Get-IisMimeMap                           2.9.2   Carbon
Alias       Get-IisSecurityAuthentication            2.9.2   Carbon
Alias       Get-IisVersion                           2.9.2   Carbon
Alias       Get-IisWebsite                           2.9.2   Carbon
Alias       Get-IPAddress                            2.9.2   Carbon
Alias       Get-Msi                                  2.9.2   Carbon
Alias       Get-MsmqMessageQueue                     2.9.2   Carbon
Alias       Get-MsmqMessageQueuePath                 2.9.2   Carbon
Alias       Get-PathCanonicalCase                    2.9.2   Carbon
Alias       Get-PathProvider                         2.9.2   Carbon
Alias       Get-PathToHostsFile                      2.9.2   Carbon
Alias       Get-PerformanceCounter                   2.9.2   Carbon
Alias       Get-PerformanceCounters                  2.9.2   Carbon
Alias       Get-Permission                           2.9.2   Carbon
Alias       Get-Permissions                          2.9.2   Carbon
Alias       Get-PowerShellModuleInstallPath          2.9.2   Carbon
Alias       Get-PowershellPath                       2.9.2   Carbon
Alias       Get-Privilege                            2.9.2   Carbon
Alias       Get-Privileges                           2.9.2   Carbon
Alias       Get-ProgramInstallInfo                   2.9.2   Carbon
Alias       Get-RegistryKeyValue                     2.9.2   Carbon
Alias       Get-ScheduledTask                        2.9.2   Carbon
Alias       Get-ServiceAcl                           2.9.2   Carbon
Alias       Get-ServiceConfiguration                 2.9.2   Carbon
Alias       Get-ServicePermission                    2.9.2   Carbon
Alias       Get-ServicePermissions                   2.9.2   Carbon
Alias       Get-ServiceSecurityDescriptor            2.9.2   Carbon
Alias       Get-SslCertificateBinding                2.9.2   Carbon
Alias       Get-SslCertificateBindings               2.9.2   Carbon
Alias       Get-TrustedHost                          2.9.2   Carbon
Alias       Get-TrustedHosts                         2.9.2   Carbon
Alias       Get-User                                 2.9.2   Carbon
Alias       Get-WmiLocalUserAccount                  2.9.2   Carbon
Alias       Grant-ComPermission                      2.9.2   Carbon
Alias       Grant-ComPermissions                     2.9.2   Carbon
Alias       Grant-HttpUrlPermission                  2.9.2   Carbon
Alias       Grant-MsmqMessageQueuePermission         2.9.2   Carbon
Alias       Grant-MsmqMessageQueuePermissions        2.9.2   Carbon
Alias       Grant-Permission                         2.9.2   Carbon
Alias       Grant-Permissions                        2.9.2   Carbon
Alias       Grant-Privilege                          2.9.2   Carbon
Alias       Grant-ServiceControlPermission           2.9.2   Carbon
Alias       Grant-ServicePermission                  2.9.2   Carbon
Alias       Initialize-Lcm                           2.9.2   Carbon
Alias       Install-Certificate                      2.9.2   Carbon
Alias       Install-Directory                        2.9.2   Carbon
Alias       Install-FileShare                        2.9.2   Carbon
Alias       Install-Group                            2.9.2   Carbon
Alias       Install-IisApplication                   2.9.2   Carbon
Alias       Install-IisAppPool                       2.9.2   Carbon
Alias       Install-IisVirtualDirectory              2.9.2   Carbon
Alias       Install-IisWebsite                       2.9.2   Carbon
Alias       Install-Junction                         2.9.2   Carbon
Alias       Install-Msi                              2.9.2   Carbon
Alias       Install-Msmq                             2.9.2   Carbon
Alias       Install-MsmqMessageQueue                 2.9.2   Carbon
Alias       Install-PerformanceCounter               2.9.2   Carbon
Alias       Install-RegistryKey                      2.9.2   Carbon
Alias       Install-ScheduledTask                    2.9.2   Carbon
Alias       Install-Service                          2.9.2   Carbon
Alias       Install-SmbShare                         2.9.2   Carbon
Alias       Install-User                             2.9.2   Carbon
Alias       Invoke-AppCmd                            2.9.2   Carbon
Alias       Invoke-PowerShell                        2.9.2   Carbon
Alias       Invoke-WindowsInstaller                  2.9.2   Carbon
Alias       Join-IisVirtualPath                      2.9.2   Carbon
Alias       Lock-IisConfigurationSection             2.9.2   Carbon
Alias       New-Credential                           2.9.2   Carbon
Alias       New-Junction                             2.9.2   Carbon
Alias       New-RsaKeyPair                           2.9.2   Carbon
Alias       New-TempDir                              2.9.2   Carbon
Alias       New-TempDirectory                        2.9.2   Carbon
Alias       Protect-Acl                              2.9.2   Carbon
Alias       Protect-String                           2.9.2   Carbon
Alias       Read-File                                2.9.2   Carbon
Alias       Remove-Certificate                       2.9.2   Carbon
Alias       Remove-DotNetAppSetting                  2.9.2   Carbon
Alias       Remove-EnvironmentVariable               2.9.2   Carbon
Alias       Remove-GroupMember                       2.9.2   Carbon
Alias       Remove-HostsEntry                        2.9.2   Carbon
Alias       Remove-IisMimeMap                        2.9.2   Carbon
Alias       Remove-IniEntry                          2.9.2   Carbon
Alias       Remove-Junction                          2.9.2   Carbon
Alias       Remove-MsmqMessageQueue                  2.9.2   Carbon
Alias       Remove-RegistryKeyValue                  2.9.2   Carbon
Alias       Remove-Service                           2.9.2   Carbon
Alias       Remove-SslCertificateBinding             2.9.2   Carbon
Alias       Remove-User                              2.9.2   Carbon
Alias       Reset-HostsFile                          2.9.2   Carbon
Alias       Reset-MsmqQueueManagerID                 2.9.2   Carbon
Alias       Resolve-FullPath                         2.9.2   Carbon
Alias       Resolve-Identity                         2.9.2   Carbon
Alias       Resolve-IdentityName                     2.9.2   Carbon
Alias       Resolve-NetPath                          2.9.2   Carbon
Alias       Resolve-PathCase                         2.9.2   Carbon
Alias       Resolve-RelativePath                     2.9.2   Carbon
Alias       Restart-RemoteService                    2.9.2   Carbon
Alias       Revoke-ComPermission                     2.9.2   Carbon
Alias       Revoke-ComPermissions                    2.9.2   Carbon
Alias       Revoke-HttpUrlPermission                 2.9.2   Carbon
Alias       Revoke-Permission                        2.9.2   Carbon
Alias       Revoke-Privilege                         2.9.2   Carbon
Alias       Revoke-ServicePermission                 2.9.2   Carbon
Alias       Set-DotNetAppSetting                     2.9.2   Carbon
Alias       Set-DotNetConnectionString               2.9.2   Carbon
Alias       Set-EnvironmentVariable                  2.9.2   Carbon
Alias       Set-HostsEntry                           2.9.2   Carbon
Alias       Set-IisHttpHeader                        2.9.2   Carbon
Alias       Set-IisHttpRedirect                      2.9.2   Carbon
Alias       Set-IisMimeMap                           2.9.2   Carbon
Alias       Set-IisWebsiteID                         2.9.2   Carbon
Alias       Set-IisWebsiteSslCertificate             2.9.2   Carbon
Alias       Set-IisWindowsAuthentication             2.9.2   Carbon
Alias       Set-IniEntry                             2.9.2   Carbon
Alias       Set-RegistryKeyValue                     2.9.2   Carbon
Alias       Set-ServiceAcl                           2.9.2   Carbon
Alias       Set-SslCertificateBinding                2.9.2   Carbon
Alias       Set-TrustedHost                          2.9.2   Carbon
Alias       Set-TrustedHosts                         2.9.2   Carbon
Alias       Split-Ini                                2.9.2   Carbon
Alias       Start-DscPullConfiguration               2.9.2   Carbon
Alias       Test-AdminPrivilege                      2.9.2   Carbon
Alias       Test-AdminPrivileges                     2.9.2   Carbon
Alias       Test-DotNet                              2.9.2   Carbon
Alias       Test-DscTargetResource                   2.9.2   Carbon
Alias       Test-FileShare                           2.9.2   Carbon
Alias       Test-FirewallStatefulFtp                 2.9.2   Carbon
Alias       Test-Group                               2.9.2   Carbon
Alias       Test-GroupMember                         2.9.2   Carbon
Alias       Test-Identity                            2.9.2   Carbon
Alias       Test-IisAppPool                          2.9.2   Carbon
Alias       Test-IisConfigurationSection             2.9.2   Carbon
Alias       Test-IisSecurityAuthentication           2.9.2   Carbon
Alias       Test-IisWebsite                          2.9.2   Carbon
Alias       Test-IPAddress                           2.9.2   Carbon
Alias       Test-MsmqMessageQueue                    2.9.2   Carbon
Alias       Test-NtfsCompression                     2.9.2   Carbon
Alias       Test-OSIs32Bit                           2.9.2   Carbon
Alias       Test-OSIs64Bit                           2.9.2   Carbon
Alias       Test-PathIsJunction                      2.9.2   Carbon
Alias       Test-PerformanceCounter                  2.9.2   Carbon
Alias       Test-PerformanceCounterCategory          2.9.2   Carbon
Alias       Test-Permission                          2.9.2   Carbon
Alias       Test-PowerShellIs32Bit                   2.9.2   Carbon
Alias       Test-PowerShellIs64Bit                   2.9.2   Carbon
Alias       Test-Privilege                           2.9.2   Carbon
Alias       Test-RegistryKeyValue                    2.9.2   Carbon
Alias       Test-ScheduledTask                       2.9.2   Carbon
Alias       Test-Service                             2.9.2   Carbon
Alias       Test-SslCertificateBinding               2.9.2   Carbon
Alias       Test-TypeDataMember                      2.9.2   Carbon
Alias       Test-UncPath                             2.9.2   Carbon
Alias       Test-User                                2.9.2   Carbon
Alias       Test-WindowsFeature                      2.9.2   Carbon
Alias       Test-ZipFile                             2.9.2   Carbon
Alias       Uninstall-Certificate                    2.9.2   Carbon
Alias       Uninstall-Directory                      2.9.2   Carbon
Alias       Uninstall-FileShare                      2.9.2   Carbon
Alias       Uninstall-Group                          2.9.2   Carbon
Alias       Uninstall-IisAppPool                     2.9.2   Carbon
Alias       Uninstall-IisWebsite                     2.9.2   Carbon
Alias       Uninstall-Junction                       2.9.2   Carbon
Alias       Uninstall-MsmqMessageQueue               2.9.2   Carbon
Alias       Uninstall-PerformanceCounterCategory     2.9.2   Carbon
Alias       Uninstall-ScheduledTask                  2.9.2   Carbon
Alias       Uninstall-Service                        2.9.2   Carbon
Alias       Uninstall-User                           2.9.2   Carbon
Alias       Unlock-IisConfigurationSection           2.9.2   Carbon
Alias       Unprotect-AclAccessRules                 2.9.2   Carbon
Alias       Unprotect-String                         2.9.2   Carbon
Alias       Write-DscError                           2.9.2   Carbon
Alias       Write-File                               2.9.2   Carbon
Function    Add-CGroupMember                         2.9.2   Carbon
Function    Add-CTrustedHost                         2.9.2   Carbon
Function    Assert-CAdminPrivilege                   2.9.2   Carbon
Function    Assert-CFirewallConfigurable             2.9.2   Carbon
Function    Assert-CService                          2.9.2   Carbon
Function    Clear-CDscLocalResourceCache             2.9.2   Carbon
Function    Clear-CMofAuthoringMetadata              2.9.2   Carbon
Function    Clear-CTrustedHost                       2.9.2   Carbon
Function    Complete-CJob                            2.9.2   Carbon
Function    Compress-CItem                           2.9.2   Carbon
Function    Convert-CSecureStringToString            2.9.2   Carbon
Function    Convert-CXmlFile                         2.9.2   Carbon
Function    ConvertFrom-CBase64                      2.9.2   Carbon
Function    ConvertTo-CBase64                        2.9.2   Carbon
Function    ConvertTo-CContainerInheritanceFlags     2.9.2   Carbon
Function    ConvertTo-CInheritanceFlag               2.9.2   Carbon
Function    ConvertTo-CPropagationFlag               2.9.2   Carbon
Function    ConvertTo-CSecurityIdentifier            2.9.2   Carbon
Function    Copy-CDscResource                        2.9.2   Carbon
Function    Disable-CAclInheritance                  2.9.2   Carbon
Function    Disable-CFirewallStatefulFtp             2.9.2   Carbon
Function    Disable-CIEEnhancedSecurityConfiguration 2.9.2   Carbon
Function    Disable-CNtfsCompression                 2.9.2   Carbon
Function    Enable-CAclInheritance                   2.9.2   Carbon
Function    Enable-CFirewallStatefulFtp              2.9.2   Carbon
Function    Enable-CIEActivationPermission           2.9.2   Carbon
Function    Enable-CNtfsCompression                  2.9.2   Carbon
Function    Expand-CItem                             2.9.2   Carbon
Function    Find-CADUser                             2.9.2   Carbon
Function    Format-CADSearchFilterValue              2.9.2   Carbon
Function    Get-CADDomainController                  2.9.2   Carbon
Function    Get-CCertificate                         2.9.2   Carbon
Function    Get-CCertificateStore                    2.9.2   Carbon
Function    Get-CComPermission                       2.9.2   Carbon
Function    Get-CComSecurityDescriptor               2.9.2   Carbon
Function    Get-CDscError                            2.9.2   Carbon
Function    Get-CDscWinEvent                         2.9.2   Carbon
Function    Get-CFileShare                           2.9.2   Carbon
Function    Get-CFileSharePermission                 2.9.2   Carbon
Function    Get-CFirewallRule                        2.9.2   Carbon
Function    Get-CGroup                               2.9.2   Carbon
Function    Get-CHttpUrlAcl                          2.9.2   Carbon
Function    Get-CIPAddress                           2.9.2   Carbon
Function    Get-CMsi                                 2.9.2   Carbon
Function    Get-CMsmqMessageQueue                    2.9.2   Carbon
Function    Get-CMsmqMessageQueuePath                2.9.2   Carbon
Function    Get-CPathProvider                        2.9.2   Carbon
Function    Get-CPathToHostsFile                     2.9.2   Carbon
Function    Get-CPerformanceCounter                  2.9.2   Carbon
Function    Get-CPermission                          2.9.2   Carbon
Function    Get-CPowerShellModuleInstallPath         2.9.2   Carbon
Function    Get-CPowershellPath                      2.9.2   Carbon
Function    Get-CPrivilege                           2.9.2   Carbon
Function    Get-CProgramInstallInfo                  2.9.2   Carbon
Function    Get-CRegistryKeyValue                    2.9.2   Carbon
Function    Get-CScheduledTask                       2.9.2   Carbon
Function    Get-CServiceAcl                          2.9.2   Carbon
Function    Get-CServiceConfiguration                2.9.2   Carbon
Function    Get-CServicePermission                   2.9.2   Carbon
Function    Get-CServiceSecurityDescriptor           2.9.2   Carbon
Function    Get-CSslCertificateBinding               2.9.2   Carbon
Function    Get-CTrustedHost                         2.9.2   Carbon
Function    Get-CUser                                2.9.2   Carbon
Function    Get-CWmiLocalUserAccount                 2.9.2   Carbon
Function    Grant-CComPermission                     2.9.2   Carbon
Function    Grant-CHttpUrlPermission                 2.9.2   Carbon
Function    Grant-CMsmqMessageQueuePermission        2.9.2   Carbon
Function    Grant-CPermission                        2.9.2   Carbon
Function    Grant-CPrivilege                         2.9.2   Carbon
Function    Grant-CServiceControlPermission          2.9.2   Carbon
Function    Grant-CServicePermission                 2.9.2   Carbon
Function    Initialize-CLcm                          2.9.2   Carbon
Function    Install-CCertificate                     2.9.2   Carbon
Function    Install-CDirectory                       2.9.2   Carbon
Function    Install-CFileShare                       2.9.2   Carbon
Function    Install-CGroup                           2.9.2   Carbon
Function    Install-CJunction                        2.9.2   Carbon
Function    Install-CMsi                             2.9.2   Carbon
Function    Install-CMsmq                            2.9.2   Carbon
Function    Install-CMsmqMessageQueue                2.9.2   Carbon
Function    Install-CPerformanceCounter              2.9.2   Carbon
Function    Install-CRegistryKey                     2.9.2   Carbon
Function    Install-CScheduledTask                   2.9.2   Carbon
Function    Install-CService                         2.9.2   Carbon
Function    Install-CUser                            2.9.2   Carbon
Function    Invoke-CAppCmd                           2.9.2   Carbon
Function    Invoke-CPowerShell                       2.9.2   Carbon
Function    New-CCredential                          2.9.2   Carbon
Function    New-CJunction                            2.9.2   Carbon
Function    New-CRsaKeyPair                          2.9.2   Carbon
Function    New-CTempDirectory                       2.9.2   Carbon
Function    Read-CFile                               2.9.2   Carbon
Function    Remove-CDotNetAppSetting                 2.9.2   Carbon
Function    Remove-CEnvironmentVariable              2.9.2   Carbon
Function    Remove-CGroupMember                      2.9.2   Carbon
Function    Remove-CHostsEntry                       2.9.2   Carbon
Function    Remove-CIniEntry                         2.9.2   Carbon
Function    Remove-CJunction                         2.9.2   Carbon
Function    Remove-CRegistryKeyValue                 2.9.2   Carbon
Function    Remove-CSslCertificateBinding            2.9.2   Carbon
Function    Reset-CHostsFile                         2.9.2   Carbon
Function    Reset-CMsmqQueueManagerID                2.9.2   Carbon
Function    Resolve-CFullPath                        2.9.2   Carbon
Function    Resolve-CIdentity                        2.9.2   Carbon
Function    Resolve-CIdentityName                    2.9.2   Carbon
Function    Resolve-CNetPath                         2.9.2   Carbon
Function    Resolve-CPathCase                        2.9.2   Carbon
Function    Resolve-CRelativePath                    2.9.2   Carbon
Function    Restart-CRemoteService                   2.9.2   Carbon
Function    Revoke-CComPermission                    2.9.2   Carbon
Function    Revoke-CHttpUrlPermission                2.9.2   Carbon
Function    Revoke-CPermission                       2.9.2   Carbon
Function    Revoke-CPrivilege                        2.9.2   Carbon
Function    Revoke-CServicePermission                2.9.2   Carbon
Function    Set-CDotNetAppSetting                    2.9.2   Carbon
Function    Set-CDotNetConnectionString              2.9.2   Carbon
Function    Set-CEnvironmentVariable                 2.9.2   Carbon
Function    Set-CHostsEntry                          2.9.2   Carbon
Function    Set-CIniEntry                            2.9.2   Carbon
Function    Set-CRegistryKeyValue                    2.9.2   Carbon
Function    Set-CServiceAcl                          2.9.2   Carbon
Function    Set-CSslCertificateBinding               2.9.2   Carbon
Function    Set-CTrustedHost                         2.9.2   Carbon
Function    Split-CIni                               2.9.2   Carbon
Function    Start-CDscPullConfiguration              2.9.2   Carbon
Function    Test-CAdminPrivilege                     2.9.2   Carbon
Function    Test-CDotNet                             2.9.2   Carbon
Function    Test-CDscTargetResource                  2.9.2   Carbon
Function    Test-CFileShare                          2.9.2   Carbon
Function    Test-CFirewallStatefulFtp                2.9.2   Carbon
Function    Test-CGroup                              2.9.2   Carbon
Function    Test-CGroupMember                        2.9.2   Carbon
Function    Test-CIdentity                           2.9.2   Carbon
Function    Test-CIPAddress                          2.9.2   Carbon
Function    Test-CMsmqMessageQueue                   2.9.2   Carbon
Function    Test-CNtfsCompression                    2.9.2   Carbon
Function    Test-COSIs32Bit                          2.9.2   Carbon
Function    Test-COSIs64Bit                          2.9.2   Carbon
Function    Test-CPathIsJunction                     2.9.2   Carbon
Function    Test-CPerformanceCounter                 2.9.2   Carbon
Function    Test-CPerformanceCounterCategory         2.9.2   Carbon
Function    Test-CPermission                         2.9.2   Carbon
Function    Test-CPowerShellIs32Bit                  2.9.2   Carbon
Function    Test-CPowerShellIs64Bit                  2.9.2   Carbon
Function    Test-CPrivilege                          2.9.2   Carbon
Function    Test-CRegistryKeyValue                   2.9.2   Carbon
Function    Test-CScheduledTask                      2.9.2   Carbon
Function    Test-CService                            2.9.2   Carbon
Function    Test-CSslCertificateBinding              2.9.2   Carbon
Function    Test-CTypeDataMember                     2.9.2   Carbon
Function    Test-CUncPath                            2.9.2   Carbon
Function    Test-CUser                               2.9.2   Carbon
Function    Test-CWindowsFeature                     2.9.2   Carbon
Function    Test-CZipFile                            2.9.2   Carbon
Function    Uninstall-CCertificate                   2.9.2   Carbon
Function    Uninstall-CDirectory                     2.9.2   Carbon
Function    Uninstall-CFileShare                     2.9.2   Carbon
Function    Uninstall-CGroup                         2.9.2   Carbon
Function    Uninstall-CJunction                      2.9.2   Carbon
Function    Uninstall-CMsmqMessageQueue              2.9.2   Carbon
Function    Uninstall-CPerformanceCounterCategory    2.9.2   Carbon
Function    Uninstall-CScheduledTask                 2.9.2   Carbon
Function    Uninstall-CService                       2.9.2   Carbon
Function    Uninstall-CUser                          2.9.2   Carbon
Function    Write-CDscError                          2.9.2   Carbon
Function    Write-CFile                              2.9.2   Carbon
Filter      Protect-CString                          2.9.2   Carbon
Filter      Unprotect-CString                        2.9.2   Carbon
```

<!--本文国际来源：[Adding New PowerShell Commands with Carbon](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/adding-new-powershell-commands-with-carbon)-->

