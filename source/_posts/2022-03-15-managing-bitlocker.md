---
layout: post
date: 2022-03-15 00:00:00
title: "PowerShell 技能连载 - 管理 Bitlocker"
description: PowerTip of the Day - Managing Bitlocker
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
最好确保笔记本上的本地驱动器已加密。这可以保护您的个人数据，以防有一天笔记本被盗或被丢入垃圾堆中。

大多数现代商务笔记本都配备 TPM 芯片并支持硬盘驱动器的实时加密。Windows 附带管理硬盘加密的 PowerShell 模块 "Bitlocker"：

```powershell
PS> Get-Command -Module bitlocker

CommandType Name                              Version Source
----------- ----                              ------- ------
Function    Add-BitLockerKeyProtector         1.0.0.0 bitlocker
Function    Backup-BitLockerKeyProtector      1.0.0.0 bitlocker
Function    BackupToAAD-BitLockerKeyProtector 1.0.0.0 bitlocker
Function    Clear-BitLockerAutoUnlock         1.0.0.0 bitlocker
Function    Disable-BitLocker                 1.0.0.0 bitlocker
Function    Disable-BitLockerAutoUnlock       1.0.0.0 bitlocker
Function    Enable-BitLocker                  1.0.0.0 bitlocker
Function    Enable-BitLockerAutoUnlock        1.0.0.0 bitlocker
Function    Get-BitLockerVolume               1.0.0.0 bitlocker
Function    Lock-BitLocker                    1.0.0.0 bitlocker
Function    Remove-BitLockerKeyProtector      1.0.0.0 bitlocker
Function    Resume-BitLocker                  1.0.0.0 bitlocker
Function    Suspend-BitLocker                 1.0.0.0 bitlocker
Function    Unlock-BitLocker                  1.0.0.0 bitlocker
```

确保在尝试任何这些命令之前启动提升权限的 PowerShell。例如，`Get-BitlockerVolume` 转储当前设置和保护状态：

```powershell
PS> Get-BitLockerVolume | Select-Object -Property *


ComputerName         : DELL7390
MountPoint           : C:
EncryptionMethod     : XtsAes128
AutoUnlockEnabled    :
AutoUnlockKeyStored  : False
MetadataVersion      : 2
VolumeStatus         : FullyEncrypted
ProtectionStatus     : On
LockStatus           : Unlocked
EncryptionPercentage : 100
WipePercentage       : 0
VolumeType           : OperatingSystem
CapacityGB           : 938,0381
KeyProtector         : {Tpm, RecoveryPassword}
```

该 cmdlet 显示当前的保护状态、采用的保护方法，`EncryptionPercentage` 指示加密是已完成还是仍在处理您的数据。

如果您的硬盘驱动器未加密，则应首先阅读有关 TPM 和加密的更多信息。虽然您可以使用 `Enable-Bitlocker` 开始加密您的硬盘驱动器，但重要的是您要完全了解所有加密原理，以免意外地把自己的电脑锁定。

<!--本文国际来源：[Managing Bitlocker](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-bitlocker)-->

