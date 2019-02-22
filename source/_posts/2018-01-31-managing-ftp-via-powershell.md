---
layout: post
date: 2018-01-31 00:00:00
title: "PowerShell 技能连载 - 通过 PowerShell 管理 FTP"
description: PowerTip of the Day - Managing FTP via PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中没有内置 FTP 命令，但是您可以方便地下载和安装一个免费的扩展，该扩展提供了您想要的 FTP 管理功能。只需要运行这行代码：

```powershell
PS> Install-Module -Name Posh-SSH -Scope CurrentUser
```

如果 PowerShell 无法找到 `Install-Module` 命令，那么您很有可能没有运行最新版本的 PowerShell (5.1)。请升级您的 PowerShell，或者添加 Microsoft 的 "PowerShellGet" 模块，该模块提供了 `Install-Module` 命令。

该命令会会从公共的 PowerShell Gallery 下载 `Posh-SSH` 模块。当您同意下载内容之后，便新增了以下指令：

```powershell
PS> Get-Command -Module Posh-SSH

CommandType Name                               Version Source
----------- ----                               ------- ------
Function    Get-PoshSSHModVersion              2.0.2   Posh-SSH
Function    Get-SFTPChildItem                  2.0.2   Posh-SSH
Function    Get-SFTPContent                    2.0.2   Posh-SSH
Function    Get-SFTPLocation                   2.0.2   Posh-SSH
Function    Get-SFTPPathAttribute              2.0.2   Posh-SSH
Function    Get-SFTPSession                    2.0.2   Posh-SSH
Function    Get-SSHPortForward                 2.0.2   Posh-SSH
Function    Get-SSHSession                     2.0.2   Posh-SSH
Function    Get-SSHTrustedHost                 2.0.2   Posh-SSH
Function    Invoke-SSHCommand                  2.0.2   Posh-SSH
Function    Invoke-SSHCommandStream            2.0.2   Posh-SSH
Function    Invoke-SSHStreamExpectAction       2.0.2   Posh-SSH
Function    Invoke-SSHStreamExpectSecureAction 2.0.2   Posh-SSH
Function    New-SFTPFileStream                 2.0.2   Posh-SSH
Function    New-SFTPItem                       2.0.2   Posh-SSH
Function    New-SFTPSymlink                    2.0.2   Posh-SSH
Function    New-SSHDynamicPortForward          2.0.2   Posh-SSH
Function    New-SSHLocalPortForward            2.0.2   Posh-SSH
Function    New-SSHRemotePortForward           2.0.2   Posh-SSH
Function    New-SSHShellStream                 2.0.2   Posh-SSH
Function    New-SSHTrustedHost                 2.0.2   Posh-SSH
Function    Remove-SFTPItem                    2.0.2   Posh-SSH
Function    Remove-SFTPSession                 2.0.2   Posh-SSH
Function    Remove-SSHSession                  2.0.2   Posh-SSH
Function    Remove-SSHTrustedHost              2.0.2   Posh-SSH
Function    Rename-SFTPFile                    2.0.2   Posh-SSH
Function    Set-SFTPContent                    2.0.2   Posh-SSH
Function    Set-SFTPLocation                   2.0.2   Posh-SSH
Function    Set-SFTPPathAttribute              2.0.2   Posh-SSH
Function    Start-SSHPortForward               2.0.2   Posh-SSH
Function    Stop-SSHPortForward                2.0.2   Posh-SSH
Function    Test-SFTPPath                      2.0.2   Posh-SSH
Cmdlet      Get-SCPFile                        2.0.2   Posh-SSH
Cmdlet      Get-SCPFolder                      2.0.2   Posh-SSH
Cmdlet      Get-SFTPFile                       2.0.2   Posh-SSH
Cmdlet      New-SFTPSession                    2.0.2   Posh-SSH
Cmdlet      New-SSHSession                     2.0.2   Posh-SSH
Cmdlet      Set-SCPFile                        2.0.2   Posh-SSH
Cmdlet      Set-SCPFolder                      2.0.2   Posh-SSH
Cmdlet      Set-SFTPFile                       2.0.2   Posh-SSH
```

在 [powershellmagazine.com](http://www.powershellmagazine.com/2014/07/03/posh-ssh-open-source-ssh-powershell-module/) 有一篇延伸的文章介绍如何使用这些命令：

<!--本文国际来源：[Managing FTP via PowerShell](http://community.idera.com/powershell/powertips/b/tips/posts/managing-ftp-via-powershell)-->
