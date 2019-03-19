---
layout: post
date: 2018-09-07 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell 中使用 SSH"
description: PowerTip of the Day - Using SSH from PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---

PowerShell 6 (PowerShell Core) 终于支持 SSH 了：您可以使用 SSH 来连接非 Windows 机器来进行 PowerShell 远程操作。

如果只是需要用 SSH 连接到交换机或者其它设备，那么可以使用免费的模块。该模块为所有 PowerShell 添加了大量有用的新的 SSH 命令。以下是如何下载和安装该模块的方法：

```powershell
Install-Module -Name posh-ssh -Repository PSGallery -Scope CurrentUser
```

要列出所有新的命令，请运行以下代码：

```powershell
PS C:\> (Get-Command -Module posh-ssh).Name
Get-PoshSSHModVersion
Get-SFTPChildItem
Get-SFTPContent
Get-SFTPLocation
Get-SFTPPathAttribute
Get-SFTPSession
Get-SSHPortForward
Get-SSHSession
Get-SSHTrustedHost
Invoke-SSHCommand
Invoke-SSHCommandStream
Invoke-SSHStreamExpectAction
Invoke-SSHStreamExpectSecureAction
New-SFTPFileStream
New-SFTPItem
New-SFTPSymlink
New-SSHDynamicPortForward
New-SSHLocalPortForward
New-SSHRemotePortForward
New-SSHShellStream
New-SSHTrustedHost
Remove-SFTPItem
Remove-SFTPSession
Remove-SSHSession
Remove-SSHTrustedHost
Rename-SFTPFile
Set-SFTPContent
Set-SFTPLocation
Set-SFTPPathAttribute
Start-SSHPortForward
Stop-SSHPortForward
Test-SFTPPath
Get-SCPFile
Get-SCPFolder
Get-SFTPFile
New-SFTPSession
New-SSHSession
Set-SCPFile
Set-SCPFolder
Set-SFTPFile
```

<!--本文国际来源：[Using SSH from PowerShell](http://community.idera.com/powershell/powertips/b/tips/posts/using-ssh-from-powershell)-->
