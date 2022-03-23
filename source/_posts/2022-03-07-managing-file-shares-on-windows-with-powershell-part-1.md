---
layout: post
date: 2022-03-07 00:00:00
title: "PowerShell 技能连载 - 在 Windows 中用 PowerShell 来管理文件共享（第 1 部分）"
description: PowerTip of the Day - Managing File Shares on Windows with PowerShell (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 附带一个名为 "SMBShare" 的模块，其中包含 42 个用于管理网络共享的 cmdlet。此模块适用于 Windows PowerShell 和 PowerShell 7：

```powershell
PS> Get-Command -Module SMBShare

CommandType Name                               Version Source
----------- ----                               ------- ------
Function    Block-SmbShareAccess               2.0.0.0 SMBShare
Function    Close-SmbOpenFile                  2.0.0.0 SMBShare
Function    Close-SmbSession                   2.0.0.0 SMBShare
Function    Disable-SmbDelegation              2.0.0.0 SMBShare
Function    Enable-SmbDelegation               2.0.0.0 SMBShare
Function    Get-SmbBandwidthLimit              2.0.0.0 SMBShare
Function    Get-SmbClientConfiguration         2.0.0.0 SMBShare
Function    Get-SmbClientNetworkInterface      2.0.0.0 SMBShare
Function    Get-SmbConnection                  2.0.0.0 SMBShare
Function    Get-SmbDelegation                  2.0.0.0 SMBShare
Function    Get-SmbGlobalMapping               2.0.0.0 SMBShare
Function    Get-SmbMapping                     2.0.0.0 SMBShare
Function    Get-SmbMultichannelConnection      2.0.0.0 SMBShare
Function    Get-SmbMultichannelConstraint      2.0.0.0 SMBShare
Function    Get-SmbOpenFile                    2.0.0.0 SMBShare
Function    Get-SmbServerCertificateMapping    2.0.0.0 SMBShare
Function    Get-SmbServerConfiguration         2.0.0.0 SMBShare
Function    Get-SmbServerNetworkInterface      2.0.0.0 SMBShare
Function    Get-SmbSession                     2.0.0.0 SMBShare
Function    Get-SmbShare                       2.0.0.0 SMBShare
Function    Get-SmbShareAccess                 2.0.0.0 SMBShare
Function    Grant-SmbShareAccess               2.0.0.0 SMBShare
Function    New-SmbGlobalMapping               2.0.0.0 SMBShare
Function    New-SmbMapping                     2.0.0.0 SMBShare
Function    New-SmbMultichannelConstraint      2.0.0.0 SMBShare
Function    New-SmbServerCertificateMapping    2.0.0.0 SMBShare
Function    New-SmbShare                       2.0.0.0 SMBShare
Function    Remove-SmbBandwidthLimit           2.0.0.0 SMBShare
Function    Remove-SmbComponent                2.0.0.0 SMBShare
Function    Remove-SmbGlobalMapping            2.0.0.0 SMBShare
Function    Remove-SmbMapping                  2.0.0.0 SMBShare
Function    Remove-SmbMultichannelConstraint   2.0.0.0 SMBShare
Function    Remove-SmbServerCertificateMapping 2.0.0.0 SMBShare
Function    Remove-SmbShare                    2.0.0.0 SMBShare
Function    Revoke-SmbShareAccess              2.0.0.0 SMBShare
Function    Set-SmbBandwidthLimit              2.0.0.0 SMBShare
Function    Set-SmbClientConfiguration         2.0.0.0 SMBShare
Function    Set-SmbPathAcl                     2.0.0.0 SMBShare
Function    Set-SmbServerConfiguration         2.0.0.0 SMBShare
Function    Set-SmbShare                       2.0.0.0 SMBShare
Function    Unblock-SmbShareAccess             2.0.0.0 SMBShare
Function    Update-SmbMultichannelConnection   2.0.0.0 SMBShare
```

要开始学习使用这些 cmdlet，请从使用动词 "Get" 的那些开始：它们读取信息并且不会意外更改系统设置。

例如，`Get-SmbShare` 列出了您机器上所有可用的网络共享：

```powershell
PS> Get-SmbShare

Name                        ScopeName Path                                 Description
----                        --------- ----                                 -----------
ADMIN$                      *         C:\WINDOWS                           Remoteadmi...
C$                          *         C:\                                  Standardfr...
HP Universal Printing PCL 6 *         S/W Laser HP,LocalsplOnly            S/W Laser HP
IPC$                        *                                              Remote-IPC
OKI PCL6 Class Driver 2     *         OKI PCL6 Class Driver 2,LocalsplOnly OKI PCL6 C...
print$                      *         C:\Windows\system32\spool\drivers    Printerdr...
```

要了解如何添加、配置或删除 SmbShares，请尝试查看带有名词 "smbshare" 的 cmdlet：

```powershell
PS> Get-Command -Module SMBShare -Noun SmbShare

CommandType Name            Version Source
----------- ----            ------- ------
Function    Get-SmbShare    2.0.0.0 SMBShare
Function    New-SmbShare    2.0.0.0 SMBShare
Function    Remove-SmbShare 2.0.0.0 SMBShare
Function    Set-SmbShare    2.0.0.0 SMBShare
```

`New-SmbShare` 允许您添加新的基本网络共享。在继续运行更改系统的命令之前，最好阅读 cmdlet 文档并查看包含的示例：

```powershell
PS> Get-Help -Name New-SmbShare -Online
```

这将在您的默认浏览器中打开文档页面。该文档解释了可用的参数，并提供了如下示例：

```powershell
PS> New-SmbShare -Name VMSFiles -Path C:\ClusterStorage\Volume1\VMFiles -FullAccess Contoso\Administrator, Contoso\Contoso-HV1$
```

它说明了创建新文件共享并使用访问权限保护它是多么简单。在运行命令之前，您必须调整示例的参数，并且至少更新您要共享的本地文件夹路径，以及应该具有完全访问权限的帐户名称。

<!--本文国际来源：[Managing File Shares on Windows with PowerShell (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-file-shares-on-windows-with-powershell-part-1)-->

