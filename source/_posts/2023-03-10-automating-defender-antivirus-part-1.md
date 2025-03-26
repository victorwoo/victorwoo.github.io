---
layout: post
date: 2023-03-10 00:00:05
title: "PowerShell 技能连载 - 自动化操作 Defender 杀毒软件（第 1 部分）"
description: PowerTip of the Day - Automating Defender Antivirus (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 Windows 上，PowerShell 带有用于自动化操作内置防病毒引擎 "Defender" 的 cmdlet。

如果您想自动更新签名，请尝试以下操作：

```powershell
PS C:\> Update-MpSignature
```

如果您在计划任务的脚本中运行此命令，则现在可以完全控制。无需管理员特权。

同样，PowerShell 可以仅使用一个命令随时启动快速扫描：

```powershell
PS C:\> Start-MpScan -ScanType QuickScan
```

扫描进度显示为 PowerShell 进度条，无需打开烦人的对话框。

如果您想知道您最近面临的最新威胁，请让 Defender 输出其威胁分析：

```powershell
PS C:\> Get-MpThreat

CategoryID       : 27
DidThreatExecute : False
IsActive         : True
Resources        :
RollupStatus     : 1
SchemaVersion    : 1.0.0.0
SeverityID       : 1
ThreatID         : 311978
ThreatName       : PUADlManager:Win32/DownloadSponsor
TypeID           : 0
PSComputerName   :
```
<!--本文国际来源：[Automating Defender Antivirus (Part 1)](https://blog.idera.com/database-tools/powershell/powertips/automating-defender-antivirus-part-1/)-->

